"""Run with: python -m unittest discover -s homelab/portal -p test_portal.py"""
import io
import json
import os
import tempfile
import unittest
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path
from unittest.mock import patch

os.environ.setdefault("PORTAL_SECRET_KEY", "test-only-secret")
from werkzeug.security import generate_password_hash
from PIL import Image
import app as portal


def image_bytes(color="red", size=(600, 400), mode="RGB"):
    buffer = io.BytesIO()
    Image.new(mode, size, color).save(buffer, "PNG")
    buffer.seek(0)
    return buffer


class PortalTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        os.environ["ADMIN_PASSWORD_HASH"] = generate_password_hash("test-password")

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        portal.DATA_DIR = Path(self.tmp.name)
        portal.app.config.update(TESTING=True)
        self.client = portal.app.test_client()

    def authorize(self, client=None):
        client = client or self.client
        with client.session_transaction() as session:
            session["authenticated"] = True
            session["csrf"] = "test-csrf"
        return client

    def post(self, path, data=None, client=None):
        return (client or self.client).post(path, data={"csrf": "test-csrf", **(data or {})}, base_url="https://localhost")

    def catalogue(self):
        return self.client.get("/admin/playlist", base_url="https://localhost").get_json()

    def add(self, color="red", name="memory.png", client=None):
        return self.post("/admin/upload", {"photo": (image_bytes(color), name)}, client)

    def test_login_rejection_success_and_malformed_hash(self):
        response = self.client.get("/admin/", base_url="https://localhost")
        self.assertIn(b"Mini TV", response.data)
        with self.client.session_transaction() as session:
            session["csrf"] = "test-csrf"
        self.post("/admin/login", {"password": "wrong"})
        with self.client.session_transaction() as session:
            self.assertNotIn("authenticated", session)
        with patch.dict(os.environ, {"ADMIN_PASSWORD_HASH": "32768$bad$hash"}):
            self.assertEqual(self.post("/admin/login", {"password": "anything"}).status_code, 302)
        response = self.post("/admin/login", {"password": "test-password"})
        self.assertIn("Secure", response.headers["Set-Cookie"])
        with self.client.session_transaction() as session:
            self.assertTrue(session["authenticated"])
            self.assertNotEqual(session["csrf"], "test-csrf")

    def test_access_and_csrf(self):
        for path in ["/admin/catalogue", "/admin/playlist", "/admin/photos/" + "a" * 32 + ".png"]:
            self.assertEqual(self.client.get(path).status_code, 302)
        self.authorize()
        self.assertEqual(self.client.post("/admin/upload").status_code, 400)
        self.assertEqual(self.client.get("/admin/logout").status_code, 405)

    def test_legacy_import_once_and_persistence(self):
        (portal.DATA_DIR / "current.png").write_bytes(image_bytes().getvalue())
        self.authorize()
        first = self.catalogue()
        self.assertEqual(len(first["photos"]), 1)
        self.assertEqual(first, self.catalogue())
        self.add("blue")
        with portal.catalogue_lock():
            persisted = portal.read_catalogue()
        self.assertEqual(len(persisted["photos"]), 2)
        self.assertEqual(persisted["interval_ms"], 5000)

    def test_upload_reorder_delete_and_compatibility(self):
        self.authorize()
        self.add("red", "first.png")
        self.add("blue", "second.png")
        catalogue = self.catalogue()
        ids = [photo["id"] for photo in catalogue["photos"]]
        self.assertEqual(len(ids), 2)
        with Image.open(portal.DATA_DIR / (ids[0] + ".png")) as result:
            self.assertEqual(result.size, (320, 240))
            self.assertEqual(result.getpixel((0, 0)), (0, 0, 0))
        self.post("/admin/reorder", {"revision": catalogue["revision"], "order": ids[::-1]})
        reordered = self.catalogue()
        self.assertEqual([p["id"] for p in reordered["photos"]], ids[::-1])
        with Image.open(portal.DATA_DIR / "current.png") as result:
            self.assertEqual(result.getpixel((160, 120)), (0, 0, 255))
        self.post("/admin/delete/" + ids[1], {"revision": reordered["revision"]})
        self.assertFalse((portal.DATA_DIR / (ids[1] + ".png")).exists())
        self.assertEqual(self.client.get(f"/admin/photos/{ids[1]}.png", base_url="https://localhost").status_code, 404)
        self.post("/admin/delete/" + ids[0], {"revision": self.catalogue()["revision"]})
        self.assertEqual(self.catalogue()["photos"], [])
        self.assertFalse((portal.DATA_DIR / "current.png").exists())
        self.assertEqual(self.client.get("/admin/", base_url="https://localhost").status_code, 200)

    def test_stale_and_invalid_order_cannot_drop_photos(self):
        self.authorize()
        self.add()
        stale = self.catalogue()
        self.add("blue")
        self.post("/admin/reorder", {"revision": stale["revision"], "order": [stale["photos"][0]["id"]]})
        self.assertEqual(len(self.catalogue()["photos"]), 2)
        current = self.catalogue()
        response = self.post("/admin/reorder", {"revision": current["revision"], "order": [p["id"] for p in current["photos"]] * 2})
        self.assertEqual(response.status_code, 400)
        self.post("/admin/delete/" + stale["photos"][0]["id"], {"revision": stale["revision"]})
        self.assertEqual(len(self.catalogue()["photos"]), 2)

    def test_invalid_upload_and_escaped_names(self):
        self.authorize()
        self.post("/admin/upload", {"photo": (io.BytesIO(b"bad image"), "bad.png")})
        self.assertEqual(len(self.catalogue()["photos"]), 0)
        self.add(name='<script>alert(1)</script>.png')
        page = self.client.get("/admin/catalogue", base_url="https://localhost")
        self.assertNotIn(b"<script>alert(1)</script>", page.data)
        self.assertEqual(page.status_code, 200)
        self.assertEqual(page.headers["Cache-Control"], "no-store")

    def test_large_dimensions_and_transparency(self):
        from werkzeug.datastructures import FileStorage
        with patch.object(Image, "MAX_IMAGE_PIXELS", 100):
            with self.assertRaises(Image.DecompressionBombWarning):
                portal.process_image(FileStorage(image_bytes(size=(15, 10))))
        data = portal.process_image(FileStorage(image_bytes((255, 0, 0, 0), (50, 50), "RGBA")))
        with Image.open(io.BytesIO(data)) as result:
            self.assertEqual(result.getpixel((160, 120)), (0, 0, 0))

    def test_mpo_is_accepted_as_jpeg_family(self):
        from werkzeug.datastructures import FileStorage
        original_open = portal.Image.open

        class MpoPrimary:
            def __init__(self, image):
                self.image = image
                self.format = "MPO"
            def __enter__(self):
                return self
            def __exit__(self, *_args):
                self.image.close()
            def verify(self):
                return self.image.verify()
            def convert(self, mode):
                return self.image.convert(mode)
            def __getattr__(self, name):
                return getattr(self.image, name)

        def open_as_mpo(stream):
            return MpoPrimary(original_open(stream))

        with patch.object(portal.Image, "open", side_effect=open_as_mpo):
            result = portal.process_image(FileStorage(image_bytes()))
        with original_open(io.BytesIO(result)) as image:
            self.assertEqual(image.size, (320, 240))

    def test_parallel_uploads_do_not_lose_photos(self):
        self.authorize()
        def work(number):
            client = self.authorize(portal.app.test_client())
            return self.add(name=f"photo-{number}.png", client=client).status_code
        with ThreadPoolExecutor(max_workers=4) as executor:
            self.assertEqual(list(executor.map(work, range(8))), [302] * 8)
        self.assertEqual(len(self.catalogue()["photos"]), 8)

    def test_queue_upload_json_and_idempotent_retry(self):
        self.authorize()
        photo_id = "a" * 32
        def send():
            return self.client.post("/admin/upload", data={"csrf": "test-csrf", "upload_id": photo_id,
                    "photo": (image_bytes(), "one.png")}, headers={"Accept": "application/json"}, base_url="https://localhost")
        self.assertEqual(send().status_code, 201)
        self.assertTrue(send().get_json()["duplicate"])
        self.assertEqual(len(self.catalogue()["photos"]), 1)
        response = self.client.post("/admin/upload", data={"csrf": "test-csrf", "photo": (io.BytesIO(b"bad"), "bad.png")},
                                    headers={"Accept": "application/json"}, base_url="https://localhost")
        self.assertEqual(response.status_code, 400)
        self.assertIn("error", response.get_json())
        self.assertEqual(len(self.catalogue()["photos"]), 1)

    def test_multiple_files_without_queue_rejected_not_silently_dropped(self):
        self.authorize()
        self.post("/admin/upload", {"photo": [(image_bytes(), "one.png"), (image_bytes(), "two.png")]})
        self.assertEqual(self.catalogue()["photos"], [])

    def test_device_heartbeat_identity_timeout_and_access(self):
        self.assertEqual(self.client.get("/admin/devices").status_code, 302)
        self.assertEqual(self.client.post("/device/heartbeat").status_code, 503)
        self.authorize()
        states = self.client.get("/admin/devices", base_url="https://localhost").get_json()["devices"]
        self.assertEqual([device["last_seen"] for device in states], [None, None])
        with patch.dict(os.environ, {"DEVICE_HEARTBEATS_ENABLED": "true"}), patch.object(portal.time, "time", return_value=1000):
            self.assertEqual(self.client.post("/device/heartbeat").status_code, 403)
            self.assertEqual(self.client.post("/device/heartbeat", headers={"X-Mini-TV-User": "admin"}).status_code, 403)
            response = self.client.post("/device/heartbeat", headers={"X-Mini-TV-User": "tv-remote"})
            self.assertEqual(response.status_code, 200)
            self.assertEqual(response.get_json()["heartbeat_interval_seconds"], 30)
        with patch.object(portal.time, "time", return_value=1089):
            self.assertEqual([device["online"] for device in portal.device_status()], [False, True])
        with patch.object(portal.time, "time", return_value=1090):
            self.assertEqual([device["online"] for device in portal.device_status()], [False, False])


if __name__ == "__main__":
    unittest.main()
