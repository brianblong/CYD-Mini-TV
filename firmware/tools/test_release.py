import contextlib
import hashlib
import io
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from cryptography.exceptions import InvalidSignature
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec
import release


class ReleaseTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        (self.root / "include").mkdir()
        for name, value in (("ROOT", self.root), ("KEY", self.root / "keys" / "private.pem"),
                            ("PUBLIC", self.root / "include" / "public.h")):
            patcher = patch.object(release, name, value)
            patcher.start()
            self.addCleanup(patcher.stop)
        with contextlib.redirect_stdout(io.StringIO()):
            release.initialize()
        self.binary = self.root / "firmware.bin"
        self.binary.write_bytes(b"\xe9" + b"MINITV:cyd-st7789-4m-v1:10001\0" +
                               b"MINITVDEVICE:tv-remote\0" + b"test payload")

    def test_sign_and_reject_tampering(self):
        with contextlib.redirect_stdout(io.StringIO()):
            release.package(self.binary, "tv-remote", 10001)
        folder = self.root / "releases" / "tv-remote-10001"
        fields = (folder / "manifest.txt").read_bytes().splitlines(keepends=True)
        message = b"".join(fields[:6])
        signature = bytes.fromhex(fields[6].decode().strip())
        key = serialization.load_pem_private_key(release.KEY.read_bytes(), password=None).public_key()
        key.verify(signature, message, ec.ECDSA(hashes.SHA256()))
        for altered in (message.replace(b"tv-remote", b"tv-local"),
                        message.replace(b"10001", b"10002"), message.replace(b"st7789", b"ili9341")):
            with self.assertRaises(InvalidSignature):
                key.verify(signature, altered, ec.ECDSA(hashes.SHA256()))
        digest = fields[5].strip().decode()
        self.assertEqual(hashlib.sha256((folder / (digest + ".bin")).read_bytes()).hexdigest(), digest)

    def test_wrong_device_version_and_example_are_rejected(self):
        for device, version in (("tv-local", 10001), ("tv-remote", 10002)):
            with self.assertRaises(SystemExit):
                release.package(self.binary, device, version)
        self.binary.write_bytes(self.binary.read_bytes() + b"MINITV_CHECK_BUILD_DO_NOT_RELEASE")
        with self.assertRaises(SystemExit):
            release.package(self.binary, "tv-remote", 10001)

    def test_key_cannot_be_overwritten(self):
        before = release.KEY.read_bytes()
        with self.assertRaises(SystemExit):
            release.initialize()
        self.assertEqual(before, release.KEY.read_bytes())

    def test_partition_layout_fits_four_megabytes(self):
        path = Path(__file__).resolve().parents[1] / "partitions.csv"
        end = 0x9000
        slots = []
        for line in path.read_text().splitlines():
            if not line or line.startswith("#"):
                continue
            name, kind, subtype, offset, size, *_ = [part.strip() for part in line.split(",")]
            offset, size = int(offset, 16), int(size, 16)
            self.assertGreaterEqual(offset, end)
            end = offset + size
            if kind == "app":
                self.assertEqual(offset % 0x10000, 0)
                slots.append(size)
            if name == "tvcache":
                self.assertGreaterEqual(size, 2 * 0x27000)
        self.assertEqual(slots, [0x1B0000, 0x1B0000])
        self.assertEqual(end, 4 * 1024 * 1024)
