"""Local demo only. Never included in the production Docker image."""
import os
import secrets
import tempfile
from pathlib import Path

os.environ["PORTAL_SECRET_KEY"] = secrets.token_hex(32)
temporary = tempfile.TemporaryDirectory(prefix="mini-tv-preview-")
os.environ["DATA_DIR"] = temporary.name
from PIL import Image, ImageDraw
import app as portal

portal.app.config["SESSION_COOKIE_SECURE"] = False  # Loopback-only demo.
portal.app.config["PREVIEW_MODE"] = True
with portal.catalogue_lock():
    catalogue = portal.read_catalogue()
    for title, sky, land, sun in [
        ("Demo — Golden hour", "#eac989", "#6a7250", "#ca6b3f"),
        ("Demo — By the water", "#abc4c1", "#507274", "#f8d8a3"),
        ("Demo — Evening hills", "#d9b7a7", "#696080", "#f0d5af"),
    ]:
        photo_id = secrets.token_hex(16)
        image = Image.new("RGB", (320, 240), sky)
        draw = ImageDraw.Draw(image)
        draw.ellipse((180, 35, 248, 103), fill=sun)
        draw.polygon([(0, 155), (75, 98), (188, 172), (270, 120), (320, 150), (320, 240), (0, 240)], fill=land)
        draw.polygon([(0, 195), (115, 166), (320, 218), (320, 240), (0, 240)], fill="#3a4236")
        image.save(Path(temporary.name) / f"{photo_id}.png")
        catalogue["photos"].append({"id": photo_id, "name": title, "url": f"/images/{photo_id}.png"})
    portal.save_catalogue(catalogue)

@portal.app.before_request
def demo_session():
    # Authentication is bypassed only in this standalone demo, not app.py.
    portal.session["authenticated"] = True

# Run the demo hook before the production authentication gate.
hooks = portal.app.before_request_funcs[None]
hooks.insert(0, hooks.pop())

if __name__ == "__main__":
    portal.app.run(host="127.0.0.1", port=8765, debug=False)
