import sys, tempfile, unittest, json
from pathlib import Path
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import backup_manifest as bm

class ManifestTests(unittest.TestCase):
    def test_clean_verification(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d, "data"); root.mkdir()
            (root/"a.dump").write_bytes(b"abc")
            manifest = Path(d, "manifest.json")
            manifest.write_text(json.dumps(bm.build(root)), encoding="utf-8")
            self.assertEqual(bm.verify(root, manifest), [])

    def test_changed_file_detected(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d, "data"); root.mkdir()
            p = root/"a.dump"; p.write_bytes(b"abc")
            manifest = Path(d, "manifest.json")
            manifest.write_text(json.dumps(bm.build(root)), encoding="utf-8")
            p.write_bytes(b"abcd")
            self.assertTrue(any(x.startswith("changed:") for x in bm.verify(root, manifest)))

if __name__ == "__main__":
    unittest.main()
