#!/usr/bin/env python3
"""Render Deployment + Service from skill templates. No external repo."""
from __future__ import annotations

import argparse
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[2]
TMPL_DIR = SKILL_ROOT / "templates" / "k8s"

PULL_SECRETS = """      imagePullSecrets:
        - name: tcr-secret
        - name: ecr-secret-apeast1
"""

SA = {
    "test": "test-msk-client",
    "stage": "msk-client",
    "prod": "msk-client",
}


def fill(tmpl: str, mapping: dict[str, str]) -> str:
    out = tmpl
    for k, v in mapping.items():
        out = out.replace("{{" + k + "}}", v)
    leftover = [p for p in out.split("{{")[1:] if "}}" in p]
    if leftover:
        raise SystemExit(f"unfilled placeholders: {leftover}")
    return out


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--env", required=True, choices=("test", "stage", "prod"))
    p.add_argument("--svc", required=True)
    p.add_argument("--port", required=True, type=int)
    p.add_argument("--ns", required=True)
    p.add_argument("--registry", required=True)
    p.add_argument("--image-ns", required=True)
    p.add_argument("--kafka", action="store_true")
    p.add_argument("--out", required=True)
    args = p.parse_args()

    pull = "" if args.env == "test" else PULL_SECRETS
    sa = ""
    if args.kafka:
        name = SA[args.env]
        sa = f"      serviceAccount: {name}\n      serviceAccountName: {name}\n"

    mapping = {
        "SVC_NAME": args.svc,
        "NAMESPACE": args.ns,
        "ECR_REGISTRY": args.registry,
        "IMAGE_NS": args.image_ns,
        "APP_ENV": args.env,
        "PORT": str(args.port),
        "IMAGE_PULL_SECRETS": pull,
        "SERVICE_ACCOUNT": sa,
    }

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    for name in ("01-deployment.yaml", "02-service.yaml"):
        tmpl = (TMPL_DIR / f"{name}.tmpl").read_text(encoding="utf-8")
        (out / name).write_text(fill(tmpl, mapping), encoding="utf-8")
    print(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
