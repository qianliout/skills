#!/usr/bin/env python3
"""Add one IM service to pulled Jenkinsfiles. Idempotent. No external repo."""
from __future__ import annotations

import argparse
import re
from pathlib import Path

IMAGE_NS = {"test": "siu", "stage": "zymix", "prod": "zymix"}
KUBE_VAR = {"test": "kubedev", "stage": "kubestage", "prod": "kubeprod"}


def normalize_svc(raw: str) -> str:
    raw = raw.removeprefix("cloud-").strip().rstrip("/")
    if not raw:
        raise SystemExit("empty service name")
    if raw.endswith("-svc") or raw.endswith("-gateway"):
        return raw
    return f"{raw}-svc"


def last_uncommented(lines: list[str], pred) -> int:
    idx = -1
    for i, line in enumerate(lines):
        s = line.lstrip()
        if s.startswith("#"):
            continue
        if pred(s):
            idx = i
    return idx


def insert_after(lines: list[str], idx: int, new_line: str) -> None:
    if idx < 0:
        raise SystemExit(f"cannot find insertion point for: {new_line.strip()}")
    if new_line in lines:
        return
    lines.insert(idx + 1, new_line)


def patch_main(text: str, svc: str, env: str, port: int) -> str:
    ns = IMAGE_NS[env]
    kube = KUBE_VAR[env]
    if f"build/output/{svc} " in text or f"build/output/{svc}\n" in text:
        return text
    lines = text.splitlines(keepends=True)
    use_port = port < 9000 or port > 9010

    insert_after(
        lines,
        last_uncommented(lines, lambda s: "go build -o build/output/" in s),
        f"                CGO_ENABLED=0 /opt/tools/go/bin/go build -o build/output/{svc} ./app/{svc}/cmd/{svc}\n",
    )
    df_idx = last_uncommented(
        lines,
        lambda s: s.startswith("generateDockerfile(") or s.startswith("generateDockerfileWithport("),
    )
    df_line = (
        f'               generateDockerfileWithport("{svc}","{port}")\n'
        if use_port
        else f'               generateDockerfile("{svc}")\n'
    )
    insert_after(lines, df_idx, df_line)
    insert_after(
        lines,
        last_uncommented(lines, lambda s: "docker build -f ./" in s),
        f"                docker build -f ./{svc}.Dockerfile -t ${{ECR_REGISTRY}}/{ns}/{svc}:${{IMAGE_TAG}} .\n",
    )
    insert_after(
        lines,
        last_uncommented(lines, lambda s: "docker push ${ECR_REGISTRY}/" in s or "docker push ${{ECR_REGISTRY}}/" in s),
        f"                docker push ${{ECR_REGISTRY}}/{ns}/{svc}:${{IMAGE_TAG}}\n",
    )
    insert_after(
        lines,
        last_uncommented(lines, lambda s: "set image deployment/" in s),
        f"                    ${{{kube}}} set image deployment/cloud-{svc} -n ${{DEPLOY_ENV}} {svc}=${{ECR_REGISTRY}}/{ns}/{svc}:${{IMAGE_TAG}}\n",
    )
    return "".join(lines)


def patch_selective(text: str, svc: str) -> str:
    if re.search(rf"name:\s*'{re.escape(svc)}'", text):
        return text
    table = "goose_db_version_" + svc.replace("-", "_")
    entry = (
        f"    [name: '{svc}',   deployment: 'cloud-{svc}',   container: '{svc}',   "
        f"gooseDir: 'app/{svc}/ddl/migrations',   gooseTable: '{table}',   gooseEnabled: false],\n"
    )
    m = re.search(r"(\n\])", text)
    if not m:
        raise SystemExit("ALL_SERVICES closing ] not found")
    text = text[: m.start()] + "\n" + entry + text[m.start() :]

    if "SELECTED_SERVICES" not in text:
        param = """
        string(
            name: 'SELECTED_SERVICES',
            defaultValue: '',
            description: '逗号分隔服务名，空则全量'
        )
"""
        text = re.sub(
            r"(parameters\s*\{\s*string\(\s*name:\s*'BRANCH'[\s\S]*?\n\s*\)\s*)",
            r"\1" + param,
            text,
            count=1,
        )
    return text


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--env", required=True, choices=("test", "stage", "prod"))
    p.add_argument("--svc", required=True)
    p.add_argument("--port", required=True, type=int)
    p.add_argument("--dir", required=True, help=".../jenkins-piplines directory")
    args = p.parse_args()
    args.svc = normalize_svc(args.svc)

    base = Path(args.dir)
    main_jf = base / "cloud-im-go-server" / "Jenkinsfile"
    sel_jf = base / "cloud-im-go-server-selective" / "Jenkinsfile"
    if not main_jf.is_file() or not sel_jf.is_file():
        raise SystemExit(f"missing Jenkinsfile under {base}")

    main_jf.write_text(patch_main(main_jf.read_text(encoding="utf-8"), args.svc, args.env, args.port), encoding="utf-8")
    sel_jf.write_text(patch_selective(sel_jf.read_text(encoding="utf-8"), args.svc), encoding="utf-8")
    print(f"patched {main_jf}")
    print(f"patched {sel_jf}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
