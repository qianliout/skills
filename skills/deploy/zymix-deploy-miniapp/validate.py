#!/usr/bin/env python3
"""校验 Scaffold 阶段生成的部署清单。只读，不修改任何文件。

用法:
    python3 validate.py --class miniapp --env test --dir rent-rewards/test
    python3 validate.py --class miniapp --env prod --dir some-svc/prod

退出码: 0 全通过或仅有 WARN；1 有 FAIL。
"""
from __future__ import annotations

import argparse
import pathlib
import re
import subprocess
import sys

# 环境 -> (namespace, kubeconfig 关键字, 跳板机)
ENV_MATRIX = {
    "miniapp": {
        "test": ("zymix-dev", "miniapp_config", "test-jenkins"),
        "prod": ("zymix-prod", "miniapp_config", "prod-jenkins"),
    },
}

# 明文密钥的启发式规则：字段名 + 一个看起来像真值的赋值
SECRET_FIELD = re.compile(
    r"""(?ix)
    ^\s*[-\s]*
    (password|passwd|pass|secret|secretkey|secret_key|access_key|accesskey
     |accesskeyid|access_key_id|secretaccesskey|secret_access_key
     |token|statictoken|apikey|api_key|appsecret|jwtkey|jwt_key|dsn|link)
    \s*:\s*(?P<val>.+?)\s*$
    """,
)
PLACEHOLDER = re.compile(r"^[\"']?(\$\{[A-Z0-9_]+\}|REPLACE_ME[A-Z0-9_]*|<[^>]*>|)[\"']?$")
# 需要加引号才安全的值（含 # : 或空格且未被引号包裹）
NEEDS_QUOTE = re.compile(r"^(?![\"']).*[#:\s].*$")

results: list[tuple[str, str, str]] = []  # (level, code, message)


def add(level: str, code: str, msg: str) -> None:
    results.append((level, code, msg))


def read(p: pathlib.Path) -> str:
    try:
        return p.read_text(encoding="utf-8")
    except Exception as exc:  # noqa: BLE001
        add("FAIL", "READ", f"{p}: 读不出来 ({exc})")
        return ""


def check_placeholders(files: list[pathlib.Path]) -> None:
    for f in files:
        for i, line in enumerate(read(f).splitlines(), 1):
            if "{{" in line and "}}" in line:
                add("FAIL", "TMPL", f"{f}:{i} 残留未填充占位符: {line.strip()[:100]}")


def check_latest(files: list[pathlib.Path]) -> None:
    for f in files:
        for i, line in enumerate(read(f).splitlines(), 1):
            if re.search(r"image:\s*\S+:latest\b", line):
                add("FAIL", "LATEST", f"{f}:{i} 镜像 tag 是 latest，会与 rollout 卡死互相放大 (P8)")


def check_quoting(files: list[pathlib.Path]) -> None:
    for f in files:
        for i, line in enumerate(read(f).splitlines(), 1):
            m = SECRET_FIELD.match(line)
            if not m:
                continue
            val = m.group("val").strip()
            if PLACEHOLDER.match(val):
                continue
            if NEEDS_QUOTE.match(val):
                add("FAIL", "QUOTE", f"{f}:{i} 值含 # : 或空格但没加引号，YAML 会截断 (P4): {line.strip()[:100]}")


def check_env_consistency(files: list[pathlib.Path], cls: str, env: str) -> None:
    ns, kubecfg, jump = ENV_MATRIX[cls][env]
    other_ns = {v[0] for e, v in ENV_MATRIX[cls].items() if e != env}
    other_cfg = {v[1] for e, v in ENV_MATRIX[cls].items() if e != env}
    for f in files:
        text = read(f)
        for i, line in enumerate(text.splitlines(), 1):
            m = re.match(r"\s*namespace:\s*(\S+)", line)
            if m and m.group(1) != ns:
                add("FAIL", "NS", f"{f}:{i} namespace 是 {m.group(1)}，{env} 环境应为 {ns} (P1)")
            for bad in other_cfg:
                if bad in line and kubecfg != bad:
                    add("FAIL", "KUBECFG", f"{f}:{i} 引用了别的环境的 kubeconfig {bad}，{env} 应为 {kubecfg} (P1)")
            if not m:  # namespace: 行已由上面的 NS 检查覆盖，不重复报
                for bad in other_ns:
                    if re.search(rf"\b{re.escape(bad)}\b", line):
                        add("WARN", "NS2", f"{f}:{i} 出现了其它环境的 namespace {bad}，确认是否笔误")
        if "jenkins" in f.name.lower() or f.name == "Jenkinsfile":
            for bad_jump in {"test-jenkins", "prod-jenkins"} - {jump}:
                if bad_jump in text:
                    add("WARN", "JUMP", f"{f} 提到了 {bad_jump}，但 {env} 环境应走 {jump} (P1)")


def check_miniapp(d: pathlib.Path, env: str) -> None:
    k8s = d / "k8s"
    real = k8s / "00-configmap.local.yaml"
    example = k8s / "00-configmap.example.yaml"
    bare = k8s / "00-configmap.yaml"

    if not example.exists():
        add("FAIL", "CM-EX", f"缺 {example}（入库的占位符版本）")
    if bare.exists():
        add("FAIL", "CM-BARE", f"{bare} 不该存在：真值用 00-configmap.local.yaml，入库版用 .example.yaml (P13)")
    if not real.exists():
        add("WARN", "CM-REAL", f"没有 {real}；若还没渲染真值 CM 可忽略")
    else:
        # 真值 CM 必须被 gitignore 覆盖 (P13)
        # --no-index 不能省：文件一旦被 git 跟踪，check-ignore 会静默返回非零，
        # 让「已入库的明文」看起来像「规则没配好」，两种情况必须分开报。
        try:
            tracked = subprocess.run(
                ["git", "ls-files", "--error-unmatch", str(real)],
                capture_output=True, check=False,
            ).returncode == 0
            ignored = subprocess.run(
                ["git", "check-ignore", "-q", "--no-index", str(real)],
                capture_output=True, check=False,
            ).returncode == 0
            if tracked:
                add("FAIL", "TRACKED", f"{real} 已被 git 跟踪，gitignore 对它无效；需 git rm --cached (P13)")
            elif not ignored:
                add("FAIL", "GITIGNORE", f"{real} 未被 .gitignore 覆盖，明文会入库 (P13)")
        except FileNotFoundError:
            add("WARN", "GIT", "找不到 git，跳过 gitignore 检查")

    if example.exists():
        for i, line in enumerate(read(example).splitlines(), 1):
            m = SECRET_FIELD.match(line)
            if m:
                val = m.group("val").strip().strip("\"'")
                if val and not re.match(r"^(REPLACE_ME|<.*>)", val):
                    add("FAIL", "EX-LEAK", f"{example}:{i} example 版里出现疑似真值，必须换成 REPLACE_ME_* ")

    if not (d / "Jenkinsfile").exists():
        add("WARN", "JF", f"缺 {d/'Jenkinsfile'}")

    for name in ("01-deployment.yaml", "02-service.yaml"):
        if not (k8s / name).exists():
            add("FAIL", "MISSING", f"缺 {k8s/name}")

    dep_cm_ref = k8s / "01-deployment.yaml"
    if dep_cm_ref.exists() and "configMap:" not in read(dep_cm_ref):
        add("FAIL", "NO-CM", f"{dep_cm_ref} 没有挂载 ConfigMap；镜像里不带配置文件，进程起不来")

    dep = k8s / "01-deployment.yaml"
    if dep.exists():
        t = read(dep)
        if "Recreate" not in t:
            add("WARN", "STRATEGY", f"{dep} 未使用 Recreate；1 副本 + RollingUpdate 容易卡死 (P8)")
        if "healthz" not in t and ("livenessProbe" in t or "readinessProbe" in t):
            add("WARN", "PROBE", f"{dep} 配了探针但路径不是 healthz，确认是真探活而非路由兜底 (P11)")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--class", dest="cls", required=True, choices=["miniapp"])
    ap.add_argument("--env", required=True)
    ap.add_argument("--dir", required=True)
    args = ap.parse_args()

    if args.env not in ENV_MATRIX[args.cls]:
        print(f"FAIL ENV  {args.cls} 类没有 {args.env} 环境，可选: {list(ENV_MATRIX[args.cls])}")
        return 1

    d = pathlib.Path(args.dir)
    if not d.is_dir():
        print(f"FAIL DIR  目录不存在: {d}")
        return 1

    files = sorted(p for p in d.rglob("*")
                   if p.is_file() and (p.suffix in {".yaml", ".yml"} or p.name == "Jenkinsfile"))
    if not files:
        add("FAIL", "EMPTY", f"{d} 下没有清单文件")

    check_placeholders(files)
    check_latest(files)
    check_quoting(files)
    check_env_consistency(files, args.cls, args.env)
    check_miniapp(d, args.env)

    fails = [r for r in results if r[0] == "FAIL"]
    warns = [r for r in results if r[0] == "WARN"]
    for level, code, msg in results:
        print(f"{level:4} {code:11} {msg}")
    print(f"\n--- {len(fails)} FAIL, {len(warns)} WARN, 检查了 {len(files)} 个文件 ---")
    if fails:
        print("有 FAIL，禁止进入执行阶段。")
        return 1
    print("通过。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
