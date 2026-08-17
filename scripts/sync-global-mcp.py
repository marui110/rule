#!/usr/bin/env python3
"""Sync MCP servers from canonical config to Cursor, Claude Code, Codex."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
from pathlib import Path
from typing import Any

HOME = Path(os.environ.get("HOME", str(Path.home())))
RULE_REPO = Path(__file__).resolve().parent.parent
CANONICAL_PATH = RULE_REPO / "mcp" / "canonical.json"
SECRETS_PATH = RULE_REPO / "mcp" / "secrets.local.json"

CURSOR_MCP = HOME / ".cursor" / "mcp.json"
CLAUDE_JSON = HOME / ".claude.json"
CODEX_CONFIG = HOME / ".codex" / "config.toml"

IMPORT_SOURCES = {
    "cursor": CURSOR_MCP,
}


def load_json(path: Path) -> dict[str, Any]:
    if not path.exists():
        return {}
    with path.open(encoding="utf-8") as handle:
        return json.load(handle)


def save_json(path: Path, data: dict[str, Any]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8") as handle:
        json.dump(data, handle, indent=2, ensure_ascii=False)
        handle.write("\n")


def normalize_server(name: str, server: dict[str, Any]) -> dict[str, Any]:
    if server.get("url") and not server.get("command"):
        normalized: dict[str, Any] = {
            "transport": "http",
            "url": server["url"],
        }
        if server.get("headers"):
            normalized["headers"] = server["headers"]
        if server.get("env"):
            normalized["env"] = server["env"]
        if "disabled" in server:
            normalized["disabled"] = server["disabled"]
        if "timeout" in server:
            normalized["timeout"] = server["timeout"]
        return normalized

    command = server.get("command")
    args = server.get("args") or []
    if command == "npx" and len(args) >= 2 and args[0] == "mcp-remote":
        normalized = {
            "transport": "http",
            "url": args[1],
        }
        if server.get("env"):
            normalized["env"] = server["env"]
        return normalized

    if command:
        normalized = {
            "transport": "stdio",
            "command": command,
            "args": args,
        }
        if server.get("env"):
            normalized["env"] = server["env"]
        if "disabled" in server:
            normalized["disabled"] = server["disabled"]
        if "timeout" in server:
            normalized["timeout"] = server["timeout"]
        return normalized

    raise ValueError(f"Unsupported MCP server shape for '{name}': {server}")


def normalize_document(data: dict[str, Any]) -> dict[str, Any]:
    servers = data.get("mcpServers") or {}
    normalized_servers = {
        name: normalize_server(name, server)
        for name, server in servers.items()
    }
    return {
        "version": data.get("version", 1),
        "options": data.get("options", {}),
        "mcpServers": normalized_servers,
    }


def import_sources() -> dict[str, Any]:
    canonical = load_json(CANONICAL_PATH)
    if not canonical:
        canonical = {"version": 1, "options": {}, "mcpServers": {}}

    existing = dict(canonical.get("mcpServers", {}))
    imported = 0
    for label, path in IMPORT_SOURCES.items():
        if not path.exists():
            print(f"import: skip {label} (missing {path})")
            continue
        payload = load_json(path)
        servers = payload.get("mcpServers") or {}
        if not servers:
            print(f"import: skip {label} (empty mcpServers)")
            continue
        normalized = normalize_document({"mcpServers": servers})["mcpServers"]
        new = {name: server for name, server in normalized.items() if name not in existing}
        if new:
            existing.update(new)
            imported += len(new)
            print(f"import: added {len(new)} server(s) from {label}: {', '.join(new)}")
        else:
            print(f"import: no new servers from {label}")

    canonical["mcpServers"] = existing
    if imported == 0:
        print("import: no new servers found (canonical already authoritative)")
    save_json(CANONICAL_PATH, canonical)
    return canonical


def to_cursor(server: dict[str, Any]) -> dict[str, Any]:
    if server["transport"] == "http":
        payload: dict[str, Any] = {"url": server["url"]}
    else:
        payload = {
            "command": server["command"],
            "args": server.get("args", []),
        }
    if server.get("env"):
        payload["env"] = server["env"]
    if "disabled" in server:
        payload["disabled"] = server["disabled"]
    if "timeout" in server:
        payload["timeout"] = server["timeout"]
    return payload




def to_claude(server: dict[str, Any]) -> dict[str, Any]:
    if server["transport"] == "http":
        payload: dict[str, Any] = {
            "type": "http",
            "url": server["url"],
        }
    else:
        payload = {
            "type": "stdio",
            "command": server["command"],
            "args": server.get("args", []),
        }
    if server.get("env"):
        payload["env"] = server["env"]
    if "disabled" in server:
        payload["disabled"] = server["disabled"]
    if "timeout" in server:
        payload["timeout"] = server["timeout"]
    return payload


def deploy_cursor(servers: dict[str, Any], options: dict[str, Any], version: int) -> None:
    payload = {
        "version": version,
        "options": options,
        "mcpServers": {
            name: to_cursor(server)
            for name, server in servers.items()
        }
    }
    save_json(CURSOR_MCP, payload)
    print(f"deploy: cursor -> {CURSOR_MCP} ({len(payload['mcpServers'])} server(s))")




def deploy_claude(servers: dict[str, Any]) -> None:
    if not CLAUDE_JSON.exists():
        print(f"deploy: skip claude (missing {CLAUDE_JSON})")
        return

    config = load_json(CLAUDE_JSON)
    config["mcpServers"] = {
        name: to_claude(server)
        for name, server in servers.items()
    }
    save_json(CLAUDE_JSON, config)
    print(f"deploy: claude -> {CLAUDE_JSON} ({len(config['mcpServers'])} server(s))")


def render_codex_toml_block(name: str, server: dict[str, Any]) -> str:
    lines = [f"[mcp_servers.{name}]"]
    if server["transport"] == "http":
        lines.append('type = "http"')
        lines.append(f'url = "{server["url"]}"')
    else:
        lines.append(f'command = "{server["command"]}"')
        args = server.get("args", [])
        args_literal = ", ".join(json.dumps(arg) for arg in args)
        lines.append(f"args = [{args_literal}]")
    if server.get("env"):
        for key, value in server["env"].items():
            lines.append(f'env.{key} = {json.dumps(value)}')
    return "\n".join(lines)


def strip_codex_mcp_sections(text: str) -> str:
    lines = text.splitlines()
    kept: list[str] = []
    skipping = False
    for line in lines:
        if re.match(r"^\[mcp_servers\.", line):
            skipping = True
            continue
        if skipping:
            if re.match(r"^\[", line):
                skipping = False
                kept.append(line)
            continue
        kept.append(line)
    return "\n".join(kept).rstrip() + "\n"


def deploy_codex(servers: dict[str, Any]) -> None:
    if not CODEX_CONFIG.exists():
        print(f"deploy: skip codex (missing {CODEX_CONFIG})")
        return

    base = CODEX_CONFIG.read_text(encoding="utf-8")
    base = strip_codex_mcp_sections(base)
    blocks = [render_codex_toml_block(name, server) for name, server in servers.items()]
    updated = base.rstrip() + "\n\n" + "\n\n".join(blocks) + "\n"
    CODEX_CONFIG.write_text(updated, encoding="utf-8")
    print(f"deploy: codex -> {CODEX_CONFIG} ({len(servers)} server(s))")


def apply_secrets(servers: dict[str, Any]) -> dict[str, Any]:
    secrets = load_json(SECRETS_PATH)
    if not secrets:
        return servers
    merged = {}
    for name, server in servers.items():
        extra = secrets.get(name) if isinstance(secrets, dict) else None
        if extra and isinstance(extra, dict):
            server = dict(server)
            env = dict(server.get("env", {}))
            env.update(extra)
            server["env"] = env
        merged[name] = server
    return merged


def deploy_all(canonical: dict[str, Any]) -> None:
    servers = canonical.get("mcpServers") or {}
    options = canonical.get("options") or {}
    version = canonical.get("version", 1)
    if not servers:
        print("deploy: no servers in canonical config")
        return

    servers = apply_secrets(servers)
    deploy_cursor(servers, options, version)
    deploy_claude(servers)
    deploy_codex(servers)


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--import",
        dest="do_import",
        action="store_true",
        help="Merge MCP servers from Cursor into mcp/canonical.json before deploy",
    )
    args = parser.parse_args()

    if args.do_import:
        canonical = import_sources()
    else:
        canonical = load_json(CANONICAL_PATH)
        if not canonical.get("mcpServers"):
            print(f"warning: {CANONICAL_PATH} is empty; run with --import first", file=sys.stderr)

    deploy_all(canonical)
    print(f"Done. Canonical MCP config: {CANONICAL_PATH}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
