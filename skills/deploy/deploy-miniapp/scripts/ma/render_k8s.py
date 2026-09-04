#!/usr/bin/env python3
"""Render Deployment / Service / Ingress from skill templates. No external repo."""
from __future__ import annotations

import argparse
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[2]
TMPL_DIR = SKILL_ROOT / "templates" / "k8s"

PROBES = """          livenessProbe:
            httpGet:
              path: /healthz
              port: {port}
            initialDelaySeconds: 10
            periodSeconds: 10
          readinessProbe:
            httpGet:
              path: /healthz
              port: {port}
            initialDelaySeconds: 5
            periodSeconds: 5
"""


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
    p.add_argument("--svc", required=True)
    p.add_argument("--ns", required=True)
    p.add_argument("--port", required=True, type=int)
    p.add_argument("--registry", required=True)
    p.add_argument("--ecr-repo", required=True)
    p.add_argument("--ingress-host", required=True)
    p.add_argument("--config-arg", required=True)
    p.add_argument("--config-mount", default="/app/config")
    p.add_argument("--healthz", action="store_true")
    p.add_argument("--out", required=True)
    args = p.parse_args()

    resource = f"zymix-{args.svc}"
    arg_items = [s.strip() for s in args.config_arg.split(",") if s.strip()]
    if arg_items:
        args_line = "          args: [" + ", ".join(f'"{a}"' for a in arg_items) + "]\n"
    else:
        args_line = ""
    probes = PROBES.format(port=args.port) if args.healthz else ""

    mapping = {
        "RESOURCE_NAME": resource,
        "NAMESPACE": args.ns,
        "CONTAINER_PORT": str(args.port),
        "ECR_REGISTRY": args.registry,
        "ECR_REPO": args.ecr_repo,
        "INGRESS_HOST": args.ingress_host,
        "ARGS_LINE": args_line,
        "CONFIG_MOUNT": args.config_mount,
        "PROBES": probes,
    }

    out = Path(args.out)
    out.mkdir(parents=True, exist_ok=True)
    for name in ("01-deployment.yaml", "02-service.yaml", "03-ingress.yaml"):
        tmpl = (TMPL_DIR / f"{name}.tmpl").read_text(encoding="utf-8")
        (out / name).write_text(fill(tmpl, mapping), encoding="utf-8")
    print(out)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
