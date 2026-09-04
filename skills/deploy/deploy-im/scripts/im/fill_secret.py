#!/usr/bin/env python3
"""Fill secret.env from sibling Secret JSON. Real values are written and echoed."""
from __future__ import annotations

import argparse
import base64
import json
import re
import sys
from pathlib import Path

SUFFIX_ALIASES = (
    "_DATABASE_DSN",
    "_REDIS_PASSWORD",
    "_REDIS_PASS",
)
EXACT_ALIASES = {
    "INTERNAL_AUTH_SECRET",
    "APP_SERVER_INTERNAL__AUTH_SECRET",
}

PREFER = (
    "cloud-user-svc-secret",
    "cloud-activity-svc-secret",
    "cloud-im-svc-secret",
)


def needed_keys(cm_text: str, extra: list[str]) -> list[str]:
    keys = list(dict.fromkeys(re.findall(r"\$\{([A-Z][A-Z0-9_]+)\}", cm_text)))
    for k in extra:
        k = k.strip()
        if k and k not in keys:
            keys.append(k)
    return keys


def decode_secrets(payload: dict, skip_name: str) -> list[tuple[str, dict[str, str]]]:
    items = payload.get("items") or ([payload] if payload.get("kind") == "Secret" else [])
    out: list[tuple[str, dict[str, str]]] = []
    for item in items:
        name = (item.get("metadata") or {}).get("name") or ""
        if not name or name == skip_name:
            continue
        if not re.match(r"^cloud-.+-secret$", name):
            continue
        raw = item.get("data") or {}
        decoded: dict[str, str] = {}
        for k, v in raw.items():
            if not v:
                continue
            try:
                decoded[k] = base64.b64decode(v).decode()
            except Exception:
                continue
        if decoded:
            out.append((name, decoded))
    out.sort(key=lambda x: (0 if x[0] in PREFER else 1, PREFER.index(x[0]) if x[0] in PREFER else 99, x[0]))
    return out


def pick(key: str, secrets: list[tuple[str, dict[str, str]]]) -> tuple[str, str] | None:
    for name, data in secrets:
        if key in data and data[key]:
            return name, data[key]
    if key in EXACT_ALIASES:
        for name, data in secrets:
            if key in data and data[key]:
                return name, data[key]
    for suffix in SUFFIX_ALIASES:
        if key.endswith(suffix):
            for name, data in secrets:
                for k, v in data.items():
                    if k.endswith(suffix) and v:
                        return name, v
    return None


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--cm", required=True)
    p.add_argument("--out", required=True)
    p.add_argument("--skip-secret", required=True)
    p.add_argument("--extra-key", action="append", default=[])
    args = p.parse_args()

    keys = needed_keys(Path(args.cm).read_text(encoding="utf-8"), args.extra_key)
    if not keys:
        print("no ${VAR} keys in configmap", file=sys.stderr)
        return 1

    raw_in = sys.stdin.read()
    if not raw_in.strip():
        print("empty secret list from cluster", file=sys.stderr)
        return 1
    payload = json.loads(raw_in)
    secrets = decode_secrets(payload, args.skip_secret)

    found: dict[str, str] = {}
    report: list[tuple[str, str, str]] = []
    missing: list[str] = []
    for key in keys:
        hit = pick(key, secrets)
        if hit:
            src, val = hit
            found[key] = val
            report.append((key, "FOUND", src))
        else:
            missing.append(key)
            report.append((key, "MISSING", "-"))

    dest = Path(args.out)
    dest.parent.mkdir(parents=True, exist_ok=True)
    lines = [f"{k}={found[k]}" for k in keys if k in found]
    dest.write_text("\n".join(lines) + ("\n" if lines else ""), encoding="utf-8")
    dest.chmod(0o600)

    for key, status, src in report:
        if status == "FOUND":
            print(f"FOUND\t{key}\t{src}")
            print(f"VALUE\t{key}={found[key]}")
        else:
            print(f"MISSING\t{key}")
    return 2 if missing else 0


if __name__ == "__main__":
    raise SystemExit(main())
