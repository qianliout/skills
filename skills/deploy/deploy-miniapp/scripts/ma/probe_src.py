#!/usr/bin/env python3
"""Read a miniapp repo (any language) and print how to build/run it. Source is read-only."""
from __future__ import annotations

import argparse
import json
import re
import subprocess
from pathlib import Path

CONFIG_CANDIDATES = (
    "manifest/config/config.yaml",
    "config/config.yaml",
    "configs/config.yaml",
    "config/config.yml",
    "config.yaml",
    "config.yml",
    "config.json",
    "appsettings.json",
    "hack/config.yaml",
)
SQL_DIRS = (
    "docs/sql",
    "resource/sql",
    "migrations",
    "sql",
    "db/migrations",
)
CODE_GLOBS = ("*.go", "*.js", "*.ts", "*.jsx", "*.tsx", "*.py", "*.java", "*.php", "*.rb")
SKIP_DIR = {"vendor", "node_modules", ".git", "dist", "build", "target", "admin"}
PORT_RE = re.compile(
    r"""(?x)
    (?:address|port|listen|PORT|EXPOSE)\s*[:=]\s*["']?:?(\d{2,5})["']?
    |
    Listen(?:AndServe)?\(\s*["']:(\d{2,5})
    |
    containerPort:\s*(\d{2,5})
    """
)
EXPOSE_RE = re.compile(r"(?im)^EXPOSE\s+(\d{2,5})")
SECRETISH = re.compile(
    r"(?i)(password|passwd|secret|token|jwt|dsn|link|appSecret|access.?key)"
)


def git(*args: str, cwd: Path) -> str:
    p = subprocess.run(
        ["git", *args],
        cwd=cwd,
        text=True,
        capture_output=True,
        check=False,
    )
    return (p.stdout or "").strip()


def git_root(src: Path) -> Path:
    out = git("rev-parse", "--show-toplevel", cwd=src)
    return Path(out) if out else src.resolve()


def https_url(raw: str) -> str:
    raw = raw.strip()
    if raw.startswith("git@"):
        host_path = raw[4:]
        host, _, path = host_path.partition(":")
        return f"https://{host}/{path}"
    return raw


def _looks_like_app(d: Path) -> bool:
    markers = (
        "main.go",
        "go.mod",
        "package.json",
        "pyproject.toml",
        "requirements.txt",
        "pom.xml",
        "build.gradle",
        "build.gradle.kts",
        "composer.json",
        "Dockerfile",
        "cmd",
        "manifest",
    )
    return any((d / m).exists() for m in markers)


def find_app_root(src: Path) -> Path:
    for rel in ("server", "backend", "api", "app"):
        cand = src / rel
        if cand.is_dir() and _looks_like_app(cand):
            return cand
    if _looks_like_app(src):
        return src
    kids = [p for p in src.iterdir() if p.is_dir() and _looks_like_app(p)]
    return kids[0] if len(kids) == 1 else src


def detect_language(app: Path) -> str:
    if (app / "go.mod").is_file() or (app / "main.go").is_file():
        return "go"
    if (app / "package.json").is_file():
        return "node"
    if (app / "pyproject.toml").is_file() or (app / "requirements.txt").is_file():
        return "python"
    if (app / "pom.xml").is_file() or (app / "build.gradle").is_file() or (app / "build.gradle.kts").is_file():
        return "java"
    if (app / "composer.json").is_file():
        return "php"
    if (app / "Gemfile").is_file():
        return "ruby"
    if (app / "Cargo.toml").is_file():
        return "rust"
    if list(app.glob("*.csproj")) or (app / "Program.cs").is_file():
        return "dotnet"
    return "unknown"


def go_framework(app: Path) -> str:
    go_mod = app / "go.mod"
    if go_mod.is_file() and "github.com/gogf/gf" in go_mod.read_text(encoding="utf-8", errors="replace"):
        return "goframe"
    return "std"


def pick_config(app: Path) -> Path | None:
    for rel in CONFIG_CANDIDATES:
        p = app / rel
        if p.is_file():
            return p
    env_specific = sorted(app.glob("manifest/config/config.*.yaml"))
    return env_specific[0] if env_specific else None


def iter_code(root: Path):
    for pat in CODE_GLOBS:
        for f in root.rglob(pat):
            if any(part in SKIP_DIR for part in f.parts):
                continue
            if f.name.endswith("_test.go") or ".test." in f.name:
                continue
            yield f


def detect_port(text: str, app: Path, dockerfile: Path | None) -> int | None:
    if dockerfile and dockerfile.is_file():
        m = EXPOSE_RE.search(dockerfile.read_text(encoding="utf-8", errors="replace"))
        if m:
            return int(m.group(1))
    m = PORT_RE.search(text)
    if m:
        for g in m.groups():
            if g:
                return int(g)
    for f in iter_code(app):
        try:
            body = f.read_text(encoding="utf-8", errors="replace")
        except OSError:
            continue
        m = PORT_RE.search(body)
        if m:
            for g in m.groups():
                if g:
                    return int(g)
    return None


def list_sql(app: Path, repo: Path) -> list[str]:
    out: list[str] = []
    for rel in SQL_DIRS:
        d = app / rel
        if not d.is_dir():
            continue
        for f in sorted(d.glob("*.sql")):
            try:
                out.append(str(f.relative_to(repo)))
            except ValueError:
                out.append(str(f))
    return out


def grep_code(app: Path, pattern: re.Pattern[str]) -> bool:
    for f in iter_code(app):
        try:
            if pattern.search(f.read_text(encoding="utf-8", errors="replace")):
                return True
        except OSError:
            continue
    return False


def dockerfile_usable(path: Path) -> bool:
    if not path.is_file():
        return False
    text = path.read_text(encoding="utf-8", errors="replace")
    if "temp/linux_amd64" in text or "gf docker" in text:
        return False
    return True


def pick_dockerfile(repo: Path, app: Path) -> Path | None:
    for cand in (repo / "Dockerfile", app / "Dockerfile"):
        if dockerfile_usable(cand):
            return cand
    return None


def config_arg_for(language: str, framework: str, app: Path) -> str:
    if language != "go":
        return ""
    if framework == "goframe":
        return "-gf.gcfg.file,/app/config/config.yaml"
    if grep_code(app, re.compile(r'flag\.String\(\s*"conf"')):
        return "-conf,/app/config/config.yaml"
    return "-conf,/app/config/config.yaml"


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--src", required=True, help="path to the service repo (read-only)")
    p.add_argument("--svc", default="")
    args = p.parse_args()

    src = Path(args.src).expanduser().resolve()
    if not src.is_dir():
        raise SystemExit(f"src not a directory: {src}")

    repo = git_root(src)
    app = find_app_root(src)
    language = detect_language(app)
    framework = go_framework(app) if language == "go" else language
    try:
        src_subdir = str(app.relative_to(repo))
    except ValueError:
        src_subdir = "."
    if src_subdir in ("", "."):
        src_subdir = "."

    cfg = pick_config(app)
    cfg_text = cfg.read_text(encoding="utf-8", errors="replace") if cfg else ""
    df = pick_dockerfile(repo, app)
    port = detect_port(cfg_text, app, df)
    if port is None:
        port = 18080 if framework == "goframe" else 8080

    if df:
        build_mode = "docker"
        needs_dockerfile = False
    elif language == "go":
        build_mode = "host"
        needs_dockerfile = False
    else:
        build_mode = "docker"
        needs_dockerfile = True

    remote = git("remote", "get-url", "origin", cwd=repo)
    git_url = https_url(remote) if remote else ""
    repo_name = Path(git_url.rstrip("/").removesuffix(".git")).name if git_url else repo.name
    binary = repo_name
    svc = args.svc or repo_name.removeprefix("zymix-").removeprefix("go-")

    sql_files = list_sql(app, repo)
    needs_db = bool(sql_files) or bool(
        re.search(r"(?i)(database|postgres|pgsql|mysql|dsn|mongodb)\s*:", cfg_text)
    )
    needs_redis = bool(re.search(r"(?i)^redis\s*:", cfg_text, re.M))
    has_healthz = grep_code(app, re.compile(r'["\']/healthz["\']'))
    has_migrate = grep_code(app, re.compile(r"AutoMigrate|golang-migrate|migrate\.New|alembic|flyway|liquibase|knex\.migrate|prisma\s+migrate"))
    secret_fields = sorted(set(SECRETISH.findall(cfg_text))) if cfg_text else []

    payload = {
        "src": str(src),
        "git_root": str(repo),
        "git_url": git_url,
        "svc": svc,
        "language": language,
        "framework": framework,
        "binary": binary,
        "src_subdir": src_subdir,
        "port": port,
        "config_file": str(cfg) if cfg else "",
        "config_mount": "/app/config",
        "config_arg": config_arg_for(language, framework, app),
        "build_mode": build_mode,
        "needs_dockerfile": needs_dockerfile,
        "dockerfile": str(df) if df else "",
        "has_healthz": has_healthz,
        "has_migrate": has_migrate,
        "needs_db": needs_db,
        "needs_redis": needs_redis,
        "sql_files": sql_files,
        "ecr_repo": f"zymix_mini_app/{repo_name}",
        "secret_hints": secret_fields,
    }
    print(json.dumps(payload, indent=2, ensure_ascii=False))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
