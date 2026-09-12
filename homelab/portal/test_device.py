"""Protocol and firmware access checks; no production secrets or server required."""
import hashlib
import os
from pathlib import Path
import unittest
from unittest.mock import patch
import test_portal


class DeviceTest(unittest.TestCase):
    authorize = test_portal.PortalTest.authorize
    add = test_portal.PortalTest.add
    post = test_portal.PortalTest.post
    catalogue = test_portal.PortalTest.catalogue

    def setUp(self):
        test_portal.PortalTest.setUp(self)
        self.enable = patch.dict(os.environ, {"DEVICE_HEARTBEATS_ENABLED": "true"})
        self.enable.start()
        self.addCleanup(self.enable.stop)
        self.headers = {"X-Mini-TV-User": "tv-remote"}

    def get_frame(self, after=""):
        return self.client.get("/device/next", query_string={"after": after}, headers=self.headers)

    def test_device_requires_proxy_identity_and_enablement(self):
        self.assertEqual(self.client.get("/device/next").status_code, 403)
        with patch.dict(os.environ, {"DEVICE_HEARTBEATS_ENABLED": "false"}):
            self.assertEqual(self.get_frame().status_code, 503)
        self.assertEqual(self.get_frame("../secret").status_code, 400)

    def test_empty_single_and_byte_order(self):
        self.assertEqual(self.get_frame().status_code, 204)
        self.authorize()
        self.add("red")
        frame = self.get_frame()
        self.assertEqual(frame.status_code, 200)
        self.assertEqual(len(frame.data), 320 * 240 * 2)
        middle = (120 * 320 + 160) * 2
        self.assertEqual(frame.data[middle:middle+2], b"\xf8\x00")
        self.assertEqual(hashlib.sha256(frame.data).hexdigest(), frame.headers["X-Frame-SHA256"])
        self.assertEqual(self.get_frame(frame.headers["X-Photo-ID"]).status_code, 204)

    def test_order_wrap_and_removed_cursor(self):
        self.authorize()
        for color in ("red", "blue", "green"):
            self.add(color)
        catalogue = self.catalogue()
        ids = [p["id"] for p in catalogue["photos"]]
        self.assertEqual(self.get_frame(ids[0]).headers["X-Photo-ID"], ids[1])
        self.assertEqual(self.get_frame(ids[-1]).headers["X-Photo-ID"], ids[0])
        self.post("/admin/reorder", {"revision": catalogue["revision"], "order": ids[::-1]})
        self.assertEqual(self.get_frame(ids[2]).headers["X-Photo-ID"], ids[1])
        self.post("/admin/delete/" + ids[1], {"revision": self.catalogue()["revision"]})
        self.assertEqual(self.get_frame(ids[1]).headers["X-Photo-ID"], ids[2])

    def test_firmware_is_device_scoped_and_paths_restricted(self):
        directory = Path(self.tmp.name) / "firmware"
        for device in ("tv-local", "tv-remote"):
            (directory / device).mkdir(parents=True)
            (directory / device / "manifest.txt").write_text(device)
        with patch.dict(os.environ, {"FIRMWARE_DIR": str(directory)}):
            response = self.client.get("/device/firmware/manifest.txt", headers=self.headers)
            self.assertEqual(response.data, b"tv-remote")
            response.close()
            self.assertEqual(self.client.get("/device/firmware/manifest.txt").status_code, 403)
            self.assertEqual(self.client.get("/device/firmware/private.pem", headers=self.headers).status_code, 404)
            self.assertEqual(self.client.get("/device/firmware/" + "a" * 64 + ".bin", headers=self.headers).status_code, 404)
