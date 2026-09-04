#!/usr/bin/env python3
"""Render Jenkinsfile + job config.xml for a new miniapp Job."""
from __future__ import annotations

import argparse
from pathlib import Path

SKILL_ROOT = Path(__file__).resolve().parents[2]
TMPL_DIR = SKILL_ROOT / "templates" / "jenkins"


def fill(tmpl: str, mapping: dict[str, str]) -> str:
    out = tmpl
    for k, v in mapping.items():
        out = out.replace("{{" + k + "}}", v)
    leftover = [p.split("}}", 1)[0] for p in out.split("{{")[1:] if "}}" in p]
    if leftover:
        raise SystemExit(f"unfilled placeholders: {leftover}")
    return out


def groovy_single_quoted(text: str) -> str:
    if "'''" not in text:
        return "'''" + text + "'''"
    return " + \"'''\" + ".join("'''" + chunk + "'''" for chunk in text.split("'''"))


def _copy_line(src_subdir: str) -> str:
    copy_src = "." if src_subdir in ("", ".") else f"./{src_subdir}"
    return "COPY . ." if copy_src == "." else f"COPY {copy_src}/ ."


def generated_dockerfile(*, language: str, port: str, binary: str, src_subdir: str) -> str:
    copy = _copy_line(src_subdir)
    if language == "go":
        copy_src = "." if src_subdir in ("", ".") else f"./{src_subdir}"
        return f"""FROM alpine:latest

RUN apk --no-cache add ca-certificates tzdata
ENV TZ=Asia/Hong_Kong

RUN addgroup -g 1000 siu && adduser -D -u 1000 -G siu siu

WORKDIR /app

COPY {copy_src}/{binary} /app/{binary}
RUN chmod +x /app/{binary} && chown -R siu:siu /app

USER siu

EXPOSE {port}

ENTRYPOINT ["/app/{binary}"]
"""
    if language == "node":
        return f"""FROM node:20-alpine
WORKDIR /app
{copy}
RUN npm ci --omit=dev || npm install --omit=dev
EXPOSE {port}
CMD ["npm", "start"]
"""
    if language == "python":
        return f"""FROM python:3.12-alpine
WORKDIR /app
{copy}
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; elif [ -f pyproject.toml ]; then pip install --no-cache-dir .; fi
EXPOSE {port}
CMD ["python", "main.py"]
"""
    if language == "java":
        return f"""FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
{copy}
EXPOSE {port}
"""
    if language == "php":
        return f"""FROM php:8.3-cli-alpine
WORKDIR /app
{copy}
EXPOSE {port}
CMD ["php", "-S", "0.0.0.0:{port}"]
"""
    return f"""FROM alpine:latest
WORKDIR /app
{copy}
EXPOSE {port}
"""


def docker_build_sh(dockerfile_rel: str) -> str:
    rel = dockerfile_rel.replace("\\", "/")
    parent = str(Path(rel).parent).replace("\\", "/")
    tag = "${ECR_REGISTRY}/${ECR_REPO}:${IMAGE_TAG}"
    if parent in (".", ""):
        cmd = f"docker build -t {tag} ."
    else:
        cmd = f"docker build -f {rel} -t {tag} {parent}"
    return (
        '                sh """#!/bin/bash\n'
        f"                {cmd}\n"
        '                """'
    )


def write_dockerfile_steps(dockerfile_rel: str, dockerfile_text: str) -> str:
    rel = dockerfile_rel.replace("\\", "/")
    parent = str(Path(rel).parent).replace("\\", "/")
    parts: list[str] = []
    if parent not in (".", ""):
        parts.append(f"                sh 'mkdir -p {parent}'")
    parts.append(
        f"                writeFile(file: '{rel}', text: {groovy_single_quoted(dockerfile_text)})"
    )
    parts.append(docker_build_sh(rel))
    return "\n\n".join(parts)


def build_steps(
    *,
    language: str,
    build_mode: str,
    dockerfile_text: str,
    dockerfile_rel: str,
    binary: str,
    src_subdir: str,
    port: str,
) -> str:
    rel = dockerfile_rel or "Dockerfile"
    cd_src = "." if src_subdir in ("", ".") else src_subdir
    use_host_go = build_mode == "host" and language == "go"
    if use_host_go:
        df = generated_dockerfile(
            language="go", port=port, binary=binary, src_subdir=src_subdir
        )
        compile_sh = f"""                sh '''#!/bin/bash
                set -e
                cd {cd_src}
                export GOMODCACHE="$GOPATH/pkg/mod"
                export GOCACHE="$GOPATH/pkg/go-build"
                export GOTOOLCHAIN=auto
                export CGO_ENABLED=0
                /opt/tools/go/bin/go mod tidy
                /opt/tools/go/bin/go build -o {binary} .
                '''"""
        return compile_sh + "\n\n" + write_dockerfile_steps(rel, df)
    text = dockerfile_text if dockerfile_text.strip() else generated_dockerfile(
        language=language, port=port, binary=binary, src_subdir=src_subdir
    )
    return write_dockerfile_steps(rel, text)


def dockerfile_relpath(path: Path | None, git_root: Path | None) -> str:
    if path is None:
        return "Dockerfile"
    if git_root is not None:
        try:
            return str(path.resolve().relative_to(git_root.resolve())).replace("\\", "/")
        except ValueError:
            return "Dockerfile"
    return path.name or "Dockerfile"


def render_jenkinsfile(
    *,
    tmpl: str,
    out_dir: Path,
    mapping_extras: dict[str, str],
    language: str,
    build_mode: str,
    dockerfile_path: Path | None,
    dockerfile_rel: str,
    binary: str,
    src_subdir: str,
    port: str,
    config_tmpl: str | None = None,
) -> Path:
    dockerfile_text = ""
    if dockerfile_path is not None:
        dockerfile_text = Path(dockerfile_path).read_text(encoding="utf-8")
    steps = build_steps(
        language=language,
        build_mode=build_mode,
        dockerfile_text=dockerfile_text,
        dockerfile_rel=dockerfile_rel,
        binary=binary,
        src_subdir=src_subdir,
        port=port,
    )
    mapping = dict(mapping_extras)
    mapping["BUILD_STEPS"] = steps
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    jenkins = out / "Jenkinsfile"
    jenkins.write_text(fill(tmpl, mapping), encoding="utf-8")
    if config_tmpl is not None:
        (out / "config.xml").write_text(fill(config_tmpl, mapping), encoding="utf-8")
    return jenkins


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--svc", required=True)
    p.add_argument("--env", required=True, choices=("test", "prod"))
    p.add_argument("--ns", required=True)
    p.add_argument("--agent", required=True)
    p.add_argument("--branch", required=True)
    p.add_argument("--git-url", required=True)
    p.add_argument("--git-credentials", required=True)
    p.add_argument("--registry", required=True)
    p.add_argument("--aws-region", required=True)
    p.add_argument("--ecr-repo", required=True)
    p.add_argument("--kubeconfig", required=True)
    p.add_argument("--binary", required=True)
    p.add_argument("--src-subdir", default=".")
    p.add_argument("--port", required=True)
    p.add_argument("--language", default="unknown")
    p.add_argument("--build-mode", default="docker", choices=("host", "docker"))
    p.add_argument("--dockerfile", default="", help="absolute path to source Dockerfile to copy")
    p.add_argument("--git-root", default="", help="repo root, used to keep Dockerfile relative path")
    p.add_argument("--out", required=True)
    args = p.parse_args()

    resource = f"zymix-{args.svc}"
    webhook = f"zymix-{args.svc}"
    df_path = Path(args.dockerfile) if args.dockerfile else None
    git_root = Path(args.git_root) if args.git_root else None
    df_rel = dockerfile_relpath(df_path, git_root)

    mapping = {
        "JENKINS_AGENT": args.agent,
        "BRANCH": args.branch,
        "WEBHOOK_TOKEN": webhook,
        "AWS_REGION": args.aws_region,
        "ECR_REGISTRY": args.registry,
        "ECR_REPO": args.ecr_repo,
        "RESOURCE_NAME": resource,
        "NAMESPACE": args.ns,
        "BINARY_NAME": args.binary,
        "GIT_URL": args.git_url,
        "GIT_CREDENTIALS_ID": args.git_credentials,
        "KUBECONFIG": args.kubeconfig,
        "JOB_DESC": f"miniapp {args.svc} {args.env}",
    }
    out = render_jenkinsfile(
        tmpl=(TMPL_DIR / "Jenkinsfile.tmpl").read_text(encoding="utf-8"),
        out_dir=Path(args.out),
        mapping_extras=mapping,
        language=args.language,
        build_mode=args.build_mode,
        dockerfile_path=df_path,
        dockerfile_rel=df_rel,
        binary=args.binary,
        src_subdir=args.src_subdir,
        port=args.port,
        config_tmpl=(TMPL_DIR / "config.xml.tmpl").read_text(encoding="utf-8"),
    )
    print(out.parent)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
