#!/usr/bin/env python3
"""Extract / inject inline Jenkinsfile from Job config.xml. Self-contained."""
from __future__ import annotations

import argparse
import html
import re
import sys
from pathlib import Path


def extract_script(xml_text: str) -> str:
    try:
        import xml.etree.ElementTree as ET

        root = ET.fromstring(xml_text)
        el = root.find(".//definition/script")
        if el is not None and el.text:
            return el.text
    except Exception:
        pass
    m = re.search(r"<script>([\s\S]*?)</script>", xml_text)
    if not m:
        raise SystemExit("no <definition>/<script> in config.xml")
    return html.unescape(m.group(1))


def xml_escape_text(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace("'", "&apos;")
        .replace('"', "&quot;")
    )


def inject_script(xml_text: str, jenkinsfile: str) -> str:
    if not re.search(r"<definition[^>]*>\s*<script>", xml_text):
        raise SystemExit("config.xml has no <definition>/<script>")
    escaped = xml_escape_text(jenkinsfile)
    return re.sub(
        r"(<definition[^>]*>\s*<script>)([\s\S]*?)(</script>)",
        lambda m: m.group(1) + escaped + m.group(3),
        xml_text,
        count=1,
    )


def main() -> int:
    p = argparse.ArgumentParser()
    sub = p.add_subparsers(dest="cmd", required=True)

    e = sub.add_parser("extract")
    e.add_argument("config")

    i = sub.add_parser("inject")
    i.add_argument("config")
    i.add_argument("jenkinsfile")
    i.add_argument("-o", "--output", required=True)

    args = p.parse_args()
    xml_text = Path(args.config).read_text(encoding="utf-8")
    if args.cmd == "extract":
        sys.stdout.write(extract_script(xml_text))
        return 0
    out = inject_script(xml_text, Path(args.jenkinsfile).read_text(encoding="utf-8"))
    Path(args.output).write_text(out, encoding="utf-8")
    print(args.output)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
