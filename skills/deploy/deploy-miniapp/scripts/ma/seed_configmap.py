#!/usr/bin/env python3
"""Wrap a source config.yaml into a ConfigMap. Values kept as-is."""
from __future__ import annotations

import argparse
from pathlib import Path


def indent_block(text: str, prefix: str) -> str:
    lines = text.splitlines()
    return "\n".join(prefix + line if line else prefix.rstrip() for line in lines)


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
    (out / "00-configmap.yaml").write_text(local, encoding="utf-8")
    print(out / "00-configmap.yaml")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
