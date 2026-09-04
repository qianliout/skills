#!/usr/bin/env python3
"""Jenkinsfile always embeds Dockerfile via writeFile."""
from __future__ import annotations

import tempfile
import unittest
from pathlib import Path

from render_jenkins import build_steps, render_jenkinsfile


TMPL_DIR = Path(__file__).resolve().parents[2] / "templates" / "jenkins"


class BuildStepsTest(unittest.TestCase):
    def test_copies_original_dockerfile_into_writefile(self):
        original = "FROM node:20-alpine\nWORKDIR /app\nCOPY . .\nEXPOSE 3000\n"
        steps = build_steps(
            language="node",
            build_mode="docker",
            dockerfile_text=original,
            dockerfile_rel="Dockerfile",
            binary="game",
            src_subdir=".",
            port="3000",
        )
        self.assertIn("writeFile(file: 'Dockerfile'", steps)
        self.assertIn("FROM node:20-alpine", steps)
        self.assertIn("WORKDIR /app", steps)
        self.assertIn("docker build", steps)
        self.assertNotIn("/opt/tools/go/bin/go build", steps)

    def test_copies_subdir_dockerfile_and_builds_with_file_flag(self):
        original = "FROM python:3.12-alpine\nWORKDIR /app\nCOPY . .\n"
        steps = build_steps(
            language="python",
            build_mode="docker",
            dockerfile_text=original,
            dockerfile_rel="server/Dockerfile",
            binary="api",
            src_subdir="server",
            port="8080",
        )
        self.assertIn("writeFile(file: 'server/Dockerfile'", steps)
        self.assertIn("FROM python:3.12-alpine", steps)
        self.assertIn("-f server/Dockerfile", steps)

    def test_missing_dockerfile_go_writes_alpine_after_host_compile(self):
        steps = build_steps(
            language="go",
            build_mode="host",
            dockerfile_text="",
            dockerfile_rel="Dockerfile",
            binary="ainews",
            src_subdir=".",
            port="18080",
        )
        self.assertIn("/opt/tools/go/bin/go build -o ainews .", steps)
        self.assertIn("writeFile(file: 'Dockerfile'", steps)
        self.assertIn("FROM alpine:latest", steps)
        self.assertIn('ENTRYPOINT ["/app/ainews"]', steps)
        self.assertIn("docker build", steps)

    def test_missing_dockerfile_node_writes_node_image(self):
        steps = build_steps(
            language="node",
            build_mode="docker",
            dockerfile_text="",
            dockerfile_rel="Dockerfile",
            binary="game",
            src_subdir=".",
            port="3000",
        )
        self.assertIn("writeFile(file: 'Dockerfile'", steps)
        self.assertIn("FROM node:", steps)
        self.assertIn("docker build", steps)
        self.assertNotIn("/opt/tools/go/bin/go build", steps)

    def test_docker_mode_never_builds_without_writefile(self):
        steps = build_steps(
            language="node",
            build_mode="docker",
            dockerfile_text="FROM alpine:3.19\n",
            dockerfile_rel="Dockerfile",
            binary="x",
            src_subdir=".",
            port="8080",
        )
        write_at = steps.index("writeFile")
        build_at = steps.index("docker build")
        self.assertLess(write_at, build_at)


class RenderJenkinsfileTest(unittest.TestCase):
    def test_cli_embeds_copied_dockerfile(self):
        tmpl = (TMPL_DIR / "Jenkinsfile.tmpl").read_text(encoding="utf-8")
        with tempfile.TemporaryDirectory() as tmp:
            src_df = Path(tmp) / "src.Dockerfile"
            src_df.write_text("FROM golang:1.22\nWORKDIR /src\nCOPY . .\n", encoding="utf-8")
            out = Path(tmp) / "out"
            path = render_jenkinsfile(
                tmpl=tmpl,
                out_dir=out,
                mapping_extras={
                    "JENKINS_AGENT": "dev",
                    "BRANCH": "master",
                    "WEBHOOK_TOKEN": "zymix-demo",
                    "AWS_REGION": "ap-east-1",
                    "ECR_REGISTRY": "123.dkr.ecr.ap-east-1.amazonaws.com",
                    "ECR_REPO": "zymix_mini_app/demo",
                    "RESOURCE_NAME": "zymix-demo",
                    "NAMESPACE": "zymix-dev",
                    "BINARY_NAME": "demo",
                    "GIT_URL": "https://example.com/demo.git",
                    "GIT_CREDENTIALS_ID": "git",
                    "KUBECONFIG": "miniapp_config",
                    "JOB_DESC": "miniapp demo test",
                },
                language="go",
                build_mode="docker",
                dockerfile_path=src_df,
                dockerfile_rel="Dockerfile",
                binary="demo",
                src_subdir=".",
                port="8080",
            )
            text = path.read_text(encoding="utf-8")
        self.assertIn("writeFile(file: 'Dockerfile'", text)
        self.assertIn("FROM golang:1.22", text)
        self.assertIn("WORKDIR /src", text)


if __name__ == "__main__":
    unittest.main()
