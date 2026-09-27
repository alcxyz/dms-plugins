"""Keep linked upstream forks outside aggregate workflow maintenance."""

from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


SOURCE_ROOT = Path(__file__).resolve().parents[2]


class LinkedForkTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        base = Path(self.temporary.name)
        self.aggregate = base / "dms-plugins"
        self.aggregate.mkdir()
        (self.aggregate / "scripts").mkdir()
        (self.aggregate / "templates/github/workflows").mkdir(parents=True)
        shutil.copy2(
            SOURCE_ROOT / "scripts/check-plugin-ci.sh",
            self.aggregate / "scripts/check-plugin-ci.sh",
        )
        shutil.copy2(
            SOURCE_ROOT / "scripts/check-build-identity.sh",
            self.aggregate / "scripts/check-build-identity.sh",
        )
        shutil.copy2(
            SOURCE_ROOT / "templates/github/workflows/plugin-ci.yml",
            self.aggregate / "templates/github/workflows/plugin-ci.yml",
        )

        owned = self.aggregate / "DankVault"
        (owned / ".github/workflows").mkdir(parents=True)
        (owned / ".git").mkdir()
        (owned / "plugin.json").write_text("{}")
        shutil.copy2(
            self.aggregate / "templates/github/workflows/plugin-ci.yml",
            owned / ".github/workflows/ci.yml",
        )

        self.fork = base / "forks/DankDisplayControl"
        (self.fork / ".github/workflows").mkdir(parents=True)
        (self.fork / ".git").mkdir()
        (self.fork / "plugin.json").write_text("{}")
        (self.fork / ".github/workflows/ci.yml").write_text("upstream workflow\n")
        (self.aggregate / "DankDisplayControl").symlink_to(
            self.fork, target_is_directory=True
        )

        physical_fork = self.aggregate / "WorldClock"
        (physical_fork / ".github/workflows").mkdir(parents=True)
        (physical_fork / ".git").mkdir()
        (physical_fork / "plugin.json").write_text("{}")
        (physical_fork / ".github/workflows/ci.yml").write_text("upstream workflow\n")

    def check(self, *args):
        return subprocess.run(
            ["bash", str(self.aggregate / "scripts/check-plugin-ci.sh"), *args],
            text=True,
            capture_output=True,
        )

    def test_automatic_discovery_skips_linked_fork(self):
        result = self.check()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("ok DankVault", result.stdout)
        self.assertNotIn("DankDisplayControl", result.stdout)
        self.assertNotIn("WorldClock", result.stdout)

    def test_fix_refuses_explicit_fork_paths(self):
        for path in (self.aggregate / "DankDisplayControl", self.fork):
            with self.subTest(path=path):
                result = self.check("--fix", str(path))
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("Excluded upstream fork", result.stderr)
                self.assertEqual(
                    (self.fork / ".github/workflows/ci.yml").read_text(),
                    "upstream workflow\n",
                )

    def test_build_identity_excludes_explicit_fork(self):
        result = subprocess.run(
            ["bash", str(self.aggregate / "scripts/check-build-identity.sh"),
             str(self.aggregate / "DankDisplayControl")],
            text=True,
            capture_output=True,
        )
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("Excluded upstream fork", result.stderr)


if __name__ == "__main__":
    unittest.main()
