from __future__ import annotations

import unittest

from scripts.check_relative_links import normalize_target
from scripts.run_all_tests import TEST_COUNT_RE
from scripts.validate_repository import SEMVER


class RelativeLinkToolTests(unittest.TestCase):
    def test_strips_fragment(self):
        self.assertEqual("docs/README.md", normalize_target("docs/README.md#testing"))

    def test_strips_query(self):
        self.assertEqual("file.md", normalize_target("file.md?raw=1"))

    def test_decodes_url_encoded_path(self):
        self.assertEqual("docs/My Guide.md", normalize_target("docs/My%20Guide.md"))


class TestRunnerContractTests(unittest.TestCase):
    def test_unittest_count_parser(self):
        match = TEST_COUNT_RE.search("Ran 30 tests in 0.010s")
        self.assertIsNotNone(match)
        self.assertEqual("30", match.group(1))

    def test_singular_test_parser(self):
        match = TEST_COUNT_RE.search("Ran 1 test in 0.001s")
        self.assertIsNotNone(match)
        self.assertEqual("1", match.group(1))


class VersionContractTests(unittest.TestCase):
    def test_release_semver(self):
        self.assertIsNotNone(SEMVER.fullmatch("1.0.0"))

    def test_prerelease_semver(self):
        self.assertIsNotNone(SEMVER.fullmatch("1.1.0-rc.1"))

    def test_invalid_version_rejected(self):
        self.assertIsNone(SEMVER.fullmatch("v1"))


if __name__ == "__main__":
    unittest.main()
