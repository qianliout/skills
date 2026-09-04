#!/usr/bin/env python3
"""Wrap a source config.yaml into a ConfigMap. Redact obvious secrets in example."""
from __future__ import annotations

import argparse
import re
from pathlib import Path

SECRET_LINE = re.compile(
    r"""(?ix)
    ^(?P<indent>\s*)
    (?P<key>password|passwd|pass|secret|secretkey|token|jwtkey|jwt_key
     |appsecret|accesskey|access_key|dsn|link)
    (?P<sep>\s*:\s*)
    (?P<val>.+?)
    \s*$
    """
)
PLACEHOLDER = re.compile(r"""^[\"']?(\$\{[^}]+\}|REPLACE_ME[A-Z0-9_]*|your_[a-z0-9_]+|<[^>]+>|)?[\"']?$""")


def indent_block(text: str, prefix: str) -> str:
    lines = text.splitlines()
    return "\n".join(prefix + line if line else prefix.rstrip() for line in lines)


def redact(text: str) -> str:
    out = []
    for line in text.splitlines():
        m = SECRET_LINE.match(line)
        if not m:
            out.append(line)
            continue
        val = m.group("val").strip()
        if PLACEHOLDER.match(val) or val in ("''", '""', "null", "~"):
            out.append(line)
            continue
        key = m.group("key")
        out.append(f"{m.group('indent')}{key}{m.group('sep')}\"REPLACE_ME_{key.upper()}\"")
    return "\n".join(out) + ("\n" if text.endswith("\n") else "")


def wrap(name: str, ns: str, body: str) -> str:
    data = indent_block(body.rstrip("\n") + "\n", "    ")
    return (
        "apiVersion: v1\n"
        "kind: ConfigMap\n"
        "metadata:\n"
        f"  name: {name}\n"
        f"  namespace: {ns}\n"
        "  labels:\n"
        f"    app: {name.removesuffix('-configmap')}\n"
        "data:\n"
        "  config.yaml: |\n"
        f"{data}"
    )


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--src-config", required=True)
    p.add_argument("--svc", required=True)
    p.add_argument("--ns", required=True)
    p.add_argument("--out", required=True)
    args = p.parse_args()

    src = Path(args.src_config)
    body = src.read_text(encoding="utf-8") if src.is_file() else (
        "server:\n"
        "  address: \":18080\"\n"
        "# write full config from source; image has no config file\n"
    )
    name = f"zymix-{args.svc}-configmap"
    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    local = wrap(name, args.ns, body)
    example = wrap(name, args.ns, redact(body))
    (out / "00-configmap.local.yaml").write_text(local, encoding="utf-8")
    (out / "00-configmap.example.yaml").write_text(example, encoding="utf-8")
    print(out / "00-configmap.local.yaml")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
