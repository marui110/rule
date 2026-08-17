#!/usr/bin/env python3
"""Sync Python/Node toolchain env to all agents."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path
from typing import Any

HOME = Path.home()
RULE_REPO = Path(__file__).resolve().parent.parent
CANONICAL_PATH = RULE_REPO / "env" / "canonical.json"

CURSOR_SETTINGS = HOME / "Library/Application Support/Cursor/User/settings.json"
CLAUDE_SETTINGS = HOME / ".claude/settings.json"
CODEX_CONFIG = HOME / ".codex/config.toml"
ZPROFILE = HOME / ".zprofile"


def strip_jsonc(text: str) -> str:
    without_block = re.sub(r"/\*.*?\*/", "", text, flags=re.S)
    lines: list[str] = []
    for line in without_block.splitlines():
        stripped = line.lstrip()
        if stripped.startswith("//"):
            continue
        if "//" in line:
            in_string = False
            escaped = False
            cut = len(line)
            for index, char in enumerate(line):
                if escaped:
                    escaped = False
                    continue
                if char == "\\":
                    escaped = True
                    continue
                if char == '"':
                    in_string = not in_string
                    continue
                if not in_string and char == "/" and index + 1 < len(line) and line[index + 1] == "/":
                    cut = index
                    break
            line = line[:cut].rstrip()
        lines.append(line)
    cleaned = "\n".join(lines)
    cleaned = re.sub(r",(\s*[}\]])", r"\1", cleaned)
    return cleaned


def load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    text = path.read_text(encoding="utf-8")
    try:
        return json.loads(text)
    except json.JSONDecodeError:
        return json.loads(strip_jsonc(text))


def save_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2, ensure_ascii=False)
        handle.write("\n")


def deep_merge(base: dict[str, Any], patch: dict[str, Any]) -> dict[str, Any]:
    merged = dict(base)
    for key, value in patch.items():
        if isinstance(value, dict) and isinstance(merged.get(key), dict):
            merged[key] = deep_merge(merged[key], value)
        else:
            merged[key] = value
    return merged


def deploy_vscode_settings(path: Path, canonical: dict[str, Any], label: str) -> None:
    settings = load_json(path)
    settings["terminal.integrated.env.osx"] = dict(canonical["terminalEnvOsx"])
    settings.update(canonical["vscodeKeys"])
    save_json(path, settings)
    print(f"deploy: {label} -> {path}")


def deploy_claude(canonical: dict[str, Any]) -> None:
    settings = load_json(CLAUDE_SETTINGS)
    env = settings.get("env", {})
    env.update(canonical.get("claudeEnv", {"PATH": canonical["path"]}))
    settings["env"] = env
    save_json(CLAUDE_SETTINGS, settings)
    print(f"deploy: claude -> {CLAUDE_SETTINGS} (toolchain env)")


def strip_shell_environment_policy(text: str) -> str:
    lines = text.splitlines()
    kept: list[str] = []
    skipping = False
    for line in lines:
        if line.strip() == "[shell_environment_policy]":
            skipping = True
            continue
        if skipping:
            if re.match(r"^\[", line):
                skipping = False
                kept.append(line)
            continue
        kept.append(line)
    return "\n".join(kept).rstrip() + "\n"


def deploy_codex(canonical: dict[str, Any]) -> None:
    if not CODEX_CONFIG.exists():
        print(f"deploy: skip codex (missing {CODEX_CONFIG})")
        return

    base = strip_shell_environment_policy(CODEX_CONFIG.read_text(encoding="utf-8"))
    block = (
        "[shell_environment_policy]\n"
        'inherit = "core"\n'
        "experimental_use_profile = true\n"
        f'set = {{ PATH = "{canonical["path"]}" }}\n'
    )
    CODEX_CONFIG.write_text(base.rstrip() + "\n\n" + block, encoding="utf-8")
    print(f"deploy: codex -> {CODEX_CONFIG} (shell_environment_policy)")


def deploy_zprofile(canonical: dict[str, Any]) -> None:
    marker_start = "# >>> agent-standards PATH >>>"
    marker_end = "# <<< agent-standards PATH <<<"
    block = (
        f"{marker_start}\n"
        f'export PATH="{canonical["path"]}"\n'
        f"{marker_end}"
    )
    text = ZPROFILE.read_text(encoding="utf-8") if ZPROFILE.exists() else ""

    # Drop the previous managed block (marker-wrapped or legacy comment+export).
    if marker_start in text:
        pattern = re.compile(
            re.escape(marker_start) + r".*?" + re.escape(marker_end), re.S
        )
        text = pattern.sub("", text)
    else:
        legacy = re.compile(
            r"^# Unified agent toolchain PATH.*$\n^export PATH=.*$\n?", re.M
        )
        text = legacy.sub("", text)

    text = text.rstrip()
    text = f"{text}\n\n{block}\n" if text else f"{block}\n"
    ZPROFILE.write_text(text, encoding="utf-8")
    print(f"deploy: login shell -> {ZPROFILE}")


def verify(canonical: dict[str, Any]) -> None:
    py = Path(canonical["python"]["interpreter"])
    node = Path(canonical["node"]["binary"])
    missing = [str(p) for p in (py, node) if not p.exists()]
    if missing:
        raise SystemExit(f"error: missing toolchain binaries: {', '.join(missing)}")


def main() -> int:
    canonical = load_json(CANONICAL_PATH)
    if not canonical.get("path"):
        print(f"error: invalid canonical env config: {CANONICAL_PATH}", file=sys.stderr)
        return 1

    verify(canonical)

    deploy_vscode_settings(CURSOR_SETTINGS, canonical, "cursor")
    deploy_claude(canonical)
    deploy_codex(canonical)
    deploy_zprofile(canonical)

    print("Done.")
    print(f"  python : {canonical['python']['interpreter']}")
    print(f"  node   : {canonical['node']['binary']}")
    print(f"  canonical: {CANONICAL_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
