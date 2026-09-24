"""Exercise the canonical workflow's scripts without calling GitHub."""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

import yaml


ROOT = Path(__file__).resolve().parents[2]
WORKFLOW = yaml.safe_load(
    (ROOT / "templates/github/workflows/plugin-ci.yml").read_text()
)


def step_script(job, name):
    return next(step["run"] for step in WORKFLOW["jobs"][job]["steps"] if step.get("name") == name)


class WorkflowTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)

    def run_script(self, script, **environment):
        return subprocess.run(
            ["bash", "-e", "-o", "pipefail", "-c", script],
            cwd=self.root,
            env={**os.environ, **environment},
            text=True,
            capture_output=True,
        )

    def manifest(self, **changes):
        plugin = dict(
            id="example", name="Example", description="Example plugin", author="example",
            version="1.2.3", component="./Widget.qml", settings="./Settings.qml",
        )
        plugin.update(changes)
        (self.root / "plugin.json").write_text(json.dumps(plugin))
        (self.root / "Widget.qml").touch()
        (self.root / "Settings.qml").touch()
        return self.run_script(step_script("test", "Validate plugin.json"))

    def test_manifest_accepts_query_references(self):
        result = self.manifest(component="./Widget.qml?rev=example")
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_manifest_rejects_invalid_metadata_and_references(self):
        for change in (
            {"name": ""}, {"version": "01.2.3"}, {"version": 123},
            {"component": "./Missing.qml"}, {"settings": "../Widget.qml"},
            {"component": "https://example.com/Widget.qml"},
        ):
            with self.subTest(change=change):
                self.assertNotEqual(self.manifest(**change).returncode, 0)

    def git(self, *arguments):
        return subprocess.check_output(
            ["git", *arguments], cwd=self.root, text=True, stderr=subprocess.PIPE,
        ).strip()

    def prepare_release(self, tag=None):
        self.git("init", "--quiet")
        self.git("config", "user.name", "CI test")
        self.git("config", "user.email", "ci@example.invalid")
        self.git("config", "commit.gpgsign", "false")
        self.git("config", "tag.gpgsign", "false")
        self.git("commit", "--allow-empty", "-m", "Initial")
        if tag == "annotated":
            self.git("tag", "-a", "v1.2.3", "-m", "Release")
        elif tag:
            self.git("tag", "v1.2.3")
        if tag == "old":
            self.git("commit", "--allow-empty", "-m", "Documentation update")
        fake_bin = self.root / "bin"
        fake_bin.mkdir()
        gh = fake_bin / "gh"
        gh.write_text(
            '#!/usr/bin/env bash\n'
            'printf "%s\\n" "$*" >> "$GH_CALLS"\n'
            'exit "${GH_EXIT:-0}"\n'
        )
        gh.chmod(0o755)
        return dict(
            PATH=f"{fake_bin}:{os.environ['PATH']}",
            GH_CALLS=str(self.root / "gh-calls"),
            GITHUB_OUTPUT=str(self.root / "output"),
            GITHUB_REPOSITORY="example/plugin", VERSION="v1.2.3",
        )

    def test_new_tag_is_created_at_tested_commit(self):
        environment = self.prepare_release()
        result = self.run_script(step_script("release", "Auto-tag release"), **environment)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn(f"sha={self.git('rev-parse', 'HEAD')}", (self.root / "gh-calls").read_text())
        self.assertIn("should_release=true", (self.root / "output").read_text())

    def test_same_commit_tags_allow_idempotent_release(self):
        for tag in ("lightweight", "annotated"):
            with self.subTest(tag=tag):
                # Each tag format needs a fresh repository.
                with tempfile.TemporaryDirectory() as directory:
                    previous_root = self.root
                    self.root = Path(directory)
                    try:
                        environment = self.prepare_release(tag)
                        result = self.run_script(step_script("release", "Auto-tag release"), **environment)
                        self.assertEqual(result.returncode, 0, result.stderr)
                        self.assertNotIn("POST", (self.root / "gh-calls").read_text())
                        self.assertIn("should_release=true", (self.root / "output").read_text())
                    finally:
                        self.root = previous_root

    def test_same_version_followup_does_not_modify_release(self):
        environment = self.prepare_release("old")
        result = self.run_script(step_script("release", "Auto-tag release"), **environment)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("should_release=false", (self.root / "output").read_text())
        self.assertFalse((self.root / "gh-calls").exists())

    def test_tag_api_failure_stops_release(self):
        environment = self.prepare_release()
        result = self.run_script(step_script("release", "Auto-tag release"), **environment, GH_EXIT="1")
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / "output").exists())


CHANGELOG = """# Changelog

## [Unreleased]

## [1.2.3] - 2026-09-24

- Show prepaid credit balances.
- Page reset history four at a time.

## [1.0.0] - 2026-09-01

- Initial release.
"""


class ChangelogTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        (self.root / "plugin.json").write_text(json.dumps({"version": "1.2.3"}))

    def run_script(self, script, **environment):
        return subprocess.run(
            ["bash", "-e", "-o", "pipefail", "-c", script],
            cwd=self.root,
            env={**os.environ, **environment},
            text=True,
            capture_output=True,
        )

    def validate(self, changelog):
        if changelog is not None:
            (self.root / "CHANGELOG.md").write_text(changelog)
        return self.run_script(step_script("test", "Validate CHANGELOG.md"))

    def test_changelog_with_unreleased_and_current_version_passes(self):
        result = self.validate(CHANGELOG)
        self.assertEqual(result.returncode, 0, result.stderr)

    def test_changelog_problems_fail_validation(self):
        cases = {
            "missing file": None,
            "no unreleased section": CHANGELOG.replace("## [Unreleased]\n\n", ""),
            "unreleased not first": CHANGELOG.replace("## [Unreleased]\n\n", "") + "\n## [Unreleased]\n",
            "no section for version": CHANGELOG.replace("[1.2.3]", "[1.2.4]"),
            "empty section for version": CHANGELOG.replace(
                "- Show prepaid credit balances.\n- Page reset history four at a time.\n", ""
            ),
            "released section without date": CHANGELOG.replace("[1.2.3] - 2026-09-24", "[1.2.3]"),
            "dated unreleased section": CHANGELOG.replace("[Unreleased]", "[Unreleased] - 2026-09-24"),
            "malformed heading": CHANGELOG.replace("## [1.0.0] - 2026-09-01", "## 1.0.0"),
            "duplicate section": CHANGELOG + "\n## [1.2.3] - 2026-09-25\n\n- Again.\n",
        }
        for name, changelog in cases.items():
            with self.subTest(case=name):
                result = self.validate(changelog)
                self.assertNotEqual(result.returncode, 0, result.stdout)

    def git(self, *arguments):
        return subprocess.check_output(
            ["git", *arguments], cwd=self.root, text=True, stderr=subprocess.PIPE,
        ).strip()

    def render(self, changelog=CHANGELOG, tags=("v1.0.0", "v1.2.3")):
        (self.root / "CHANGELOG.md").write_text(changelog)
        self.git("init", "--quiet")
        self.git("config", "user.name", "CI test")
        self.git("config", "user.email", "ci@example.invalid")
        self.git("config", "commit.gpgsign", "false")
        self.git("config", "tag.gpgsign", "false")
        self.git("commit", "--allow-empty", "-m", "Initial")
        for tag in tags:
            self.git("tag", tag)
        return self.run_script(
            step_script("release", "Render release notes"),
            VERSION="v1.2.3", GITHUB_REPOSITORY="example/plugin",
        )

    def test_release_notes_come_from_changelog_section(self):
        result = self.render()
        self.assertEqual(result.returncode, 0, result.stderr)
        notes = (self.root / "release-notes.md").read_text()
        self.assertTrue(notes.startswith("- Show prepaid credit balances.\n- Page reset history four at a time.\n"))
        self.assertIn("**Full changelog:** https://github.com/example/plugin/compare/v1.0.0...v1.2.3", notes)
        self.assertNotIn("Initial release", notes)

    def test_first_release_links_commit_history(self):
        result = self.render(tags=("v1.2.3",))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("https://github.com/example/plugin/commits/v1.2.3", (self.root / "release-notes.md").read_text())

    def test_render_fails_without_section_content(self):
        result = self.render(changelog=CHANGELOG.replace("[1.2.3]", "[1.2.4]"))
        self.assertNotEqual(result.returncode, 0)
        self.assertFalse((self.root / "release-notes.md").exists())

    def test_publish_script_extracts_the_same_render_step(self):
        script = subprocess.check_output(
            ["bash", str(ROOT / "scripts/publish-release-notes.sh"), "--print-render-script"], text=True,
        )
        self.assertEqual(script.strip(), step_script("release", "Render release notes").strip())
