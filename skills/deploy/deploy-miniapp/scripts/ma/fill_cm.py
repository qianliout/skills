#!/usr/bin/env python3
"""Copy shared redis/pg values from sibling ConfigMaps. Print real values (approval artifact)."""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

PREFER = (
    "zymix-rent-rewards-configmap",
    "zymix-ai-news-configmap",
    "zymix-ticket-tailor-configmap",
    "zymix-minigame-ranking-configmap",
)


def yaml_scalar(text: str, keys: str) -> str | None:
    m = re.search(rf"(?im)^(?:\s*)(?:{keys})\s*:\s*(.+)$", text)
    if not m:
        return None
    val = m.group(1).strip()
    if val[:1] in ("'", '"'):
        q = val[0]
        return val[1:].split(q, 1)[0]
    return val.split("#", 1)[0].strip()


def section(text: str, name: str) -> str:
    m = re.search(rf"(?im)^({name})\s*:\s*\n((?:[ \t]+.*\n)*)", text)
    return m.group(0) if m else ""


def extract_from_yaml(body: str) -> dict[str, str]:
    found: dict[str, str] = {}
    redis = section(body, "redis")
    db = section(body, "database") or body
    if redis:
        addr = yaml_scalar(redis, "address|host")
        if addr:
            found["REDIS_ADDR"] = addr
        pw = yaml_scalar(redis, "pass|password")
        if pw:
            found["REDIS_PASS"] = pw
        dbn = yaml_scalar(redis, "db")
        if dbn:
            found["REDIS_DB"] = dbn
    link = yaml_scalar(db, "link|dsn")
    if link:
        found["PG_LINK"] = link
    return found


def sibling_cms(payload: dict, skip: str) -> list[tuple[str, dict[str, str]]]:
    items = payload.get("items") or ([payload] if payload.get("kind") == "ConfigMap" else [])
    out: list[tuple[str, dict[str, str]]] = []
    for item in items:
        name = (item.get("metadata") or {}).get("name") or ""
        if not name or name == skip:
            continue
        if "configmap" not in name.lower() and not name.startswith("zymix-"):
            continue
        data = item.get("data") or {}
        body = data.get("config.yaml") or data.get("config.yml") or ""
        if not body:
            continue
        extracted = extract_from_yaml(body)
        if extracted:
            out.append((name, extracted))
    out.sort(key=lambda x: (0 if x[0] in PREFER else 1, PREFER.index(x[0]) if x[0] in PREFER else 99, x[0]))
    return out


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--out", required=True)
    p.add_argument("--skip-cm", default="")
    args = p.parse_args()

    raw = sys.stdin.read()
    payload: dict = {}
    if raw.strip():
        payload = json.loads(raw)

    needed = ("REDIS_ADDR", "REDIS_PASS", "REDIS_DB", "PG_LINK")
    cms = sibling_cms(payload, args.skip_cm)
    picked: dict[str, tuple[str, str]] = {}
    for key in needed:
        for name, data in cms:
            if key in data and data[key]:
                picked[key] = (name, data[key])
                break

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    lines = ["# shared redis/pg values from sibling ConfigMaps (approval artifact)."]
    missing = []
    for key in needed:
        if key in picked:
            src, val = picked[key]
            lines.append(f"{key}={val}")
            print(f"FOUND\t{key}\t{src}")
            print(f"VALUE\t{key}={val}")
        else:
            missing.append(key)
            print(f"MISSING\t{key}")
    out.write_text("\n".join(lines) + "\n", encoding="utf-8")
    return 2 if missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
