#!/usr/bin/env python3
"""Install the Batho skill pack into coding-agent skill directories.

Usage:
  python install_pack.py --list                 # show known agents and paths
  python install_pack.py --all                  # install, project paths, all agents
  python install_pack.py --agent cursor         # one agent (repeatable)
  python install_pack.py --all --global         # global (~) paths instead of project
  python install_pack.py --all --remove         # uninstall pack skills
  python install_pack.py --all --copy           # copy instead of symlink

Strategy: always install into the canonical `.agents/skills` scope dir, then
mirror into native dirs only for agents that do not read `.agents/skills`
(reads_agents_dir=false in agent-paths.json). `--agent <name>` additionally
writes that agent's native dirs even if it is an `.agents` reader.
"""
from __future__ import annotations

import argparse
import json
import shutil
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]  # .../batho-skills
SKILLS_SRC = REPO_ROOT / "skills"
AGENT_PATHS_FILE = REPO_ROOT / "agent-paths.json"


def load_agent_data() -> dict:
    with AGENT_PATHS_FILE.open(encoding="utf-8") as fh:
        return json.load(fh)


def resolve_base(base: str, repo_root: Path) -> Path:
    return Path(base).expanduser() if base.startswith("~") else repo_root / base


def install_skill(src: Path, dst: Path, copy: bool) -> str:
    if dst.is_symlink():
        if dst.resolve() == src.resolve():
            return "link(ok)"
        dst.unlink()
    elif dst.is_dir():
        shutil.rmtree(dst)
    if copy:
        shutil.copytree(src, dst)
        return "copied"
    try:
        dst.symlink_to(src, target_is_directory=True)
        return "linked"
    except OSError:
        shutil.copytree(src, dst)
        return "copied"


def remove_skill(dst: Path) -> str:
    if dst.is_symlink():
        dst.unlink()
        return "removed(link)"
    if dst.is_dir():
        shutil.rmtree(dst)
        return "removed(copy)"
    return "absent"


def target_dirs(data: dict, agent: dict, kind: str, forced: bool) -> list[str]:
    """Scope dirs for an agent: canonical .agents dir plus native mirrors for
    non-readers (or any agent when explicitly forced via --agent)."""
    canonical = data["canonical"]["project" if kind == "project" else "global_posix"]
    dirs = [canonical]
    if not agent["reads_agents_dir"] or forced:
        native = agent["project_dirs"] if kind == "project" else agent["global_dirs"]
        dirs.extend(native)
    seen: set[str] = set()
    return [d for d in dirs if not (d in seen or seen.add(d))]


def main(argv: list[str]) -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    group = parser.add_mutually_exclusive_group()
    group.add_argument("--all", action="store_true", help="install for all known agents")
    group.add_argument("--agent", action="append", metavar="NAME", help="agent name (repeatable)")
    parser.add_argument("--global", dest="global_", action="store_true", help="use global (~) paths")
    parser.add_argument("--remove", action="store_true", help="uninstall pack skills")
    parser.add_argument("--copy", action="store_true", help="copy instead of symlink")
    parser.add_argument("--list", action="store_true", help="list known agents and paths")
    args = parser.parse_args(argv)

    data = load_agent_data()
    agents_table: dict[str, dict] = data["agents"]
    pack_skills: list[str] = data["pack_skills"]

    if args.list:
        for agent_id, agent in agents_table.items():
            for kind in ("project", "global"):
                for base in target_dirs(data, agent, kind, forced=True):
                    print(f"{agent_id:12s} {kind:8s} {base}/<skill>/SKILL.md")
        return 0

    if not args.all and not args.agent:
        parser.error("one of the arguments --all --agent is required")

    selected = list(agents_table) if args.all else args.agent or []
    for agent in selected:
        if agent not in agents_table:
            parser.error(f"unknown agent '{agent}' (known: {', '.join(agents_table)})")
    kind = "global" if args.global_ else "project"

    failures = 0
    for agent_id in selected:
        agent = agents_table[agent_id]
        for base in target_dirs(data, agent, kind, forced=bool(args.agent)):
            dst_root = resolve_base(base, REPO_ROOT)
            for skill in pack_skills:
                dst = dst_root / skill
                if args.remove:
                    status = remove_skill(dst)
                    if status != "absent":
                        print(f"{status:12s} {agent_id}:{dst}")
                    continue
                src = SKILLS_SRC / skill
                if not src.is_dir():
                    print(f"error: missing {src}", file=sys.stderr)
                    failures += 1
                    continue
                dst_root.mkdir(parents=True, exist_ok=True)
                status = install_skill(src, dst, args.copy)
                print(f"{status:12s} {agent_id}:{dst}")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
