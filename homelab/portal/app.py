import hmac
import hashlib
from array import array
import sys
import io
import json
import os
import re
import secrets
import tempfile
import threading
import time
import warnings
from contextlib import contextmanager
from pathlib import Path

from flask import Flask, abort, flash, jsonify, redirect, render_template, request, send_file, session, url_for
from PIL import Image, ImageOps, UnidentifiedImageError
from werkzeug.security import check_password_hash

DATA_DIR = Path(os.environ.get("DATA_DIR", "/data"))
SITE_TITLE = os.environ.get("SITE_TITLE", "Mini TV")
SITE_TAGLINE = os.environ.get("SITE_TAGLINE", "Your photos. Your picture show.")
MAX_UPLOAD_BYTES = 20 * 1024 * 1024
DEVICE_NAMES = {
    "tv-local": os.environ.get("LOCAL_DEVICE_NAME", "Display 1"),
    "tv-remote": os.environ.get("REMOTE_DEVICE_NAME", "Display 2"),
}
ONLINE_SECONDS = 90
Image.MAX_IMAGE_PIXELS = 24_000_000
app = Flask(__name__, static_url_path="/admin/static")
app.config.update(MAX_CONTENT_LENGTH=MAX_UPLOAD_BYTES,
                  SECRET_KEY=os.environ["PORTAL_SECRET_KEY"],
                  SESSION_COOKIE_HTTPONLY=True, SESSION_COOKIE_SAMESITE="Strict",
                  SESSION_COOKIE_SECURE=True)
_lock = threading.Lock()


@contextmanager
def catalogue_lock():
    """Serialize all catalogue changes across Gunicorn workers and threads."""
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    with _lock, (DATA_DIR / ".catalogue.lock").open("a+b") as lock:
        if os.name == "nt":
            import msvcrt
            lock.seek(0)
            if not lock.read(1):
                lock.write(b"0")
                lock.flush()
            lock.seek(0)
            msvcrt.locking(lock.fileno(), msvcrt.LK_LOCK, 1)
        else:
            import fcntl
            fcntl.flock(lock, fcntl.LOCK_EX)
        try:
            yield
        finally:
            if os.name == "nt":
                lock.seek(0)
                msvcrt.locking(lock.fileno(), msvcrt.LK_UNLCK, 1)
            else:
                fcntl.flock(lock, fcntl.LOCK_UN)


def atomic_write(path, data):
    with tempfile.NamedTemporaryFile(dir=DATA_DIR, prefix=".pending-", delete=False) as tmp:
        temporary = Path(tmp.name)
        try:
            tmp.write(data)
            tmp.flush()
            os.fsync(tmp.fileno())
        except BaseException:
            temporary.unlink(missing_ok=True)
            raise
    try:
        os.chmod(temporary, 0o644)
        os.replace(temporary, path)
    finally:
        temporary.unlink(missing_ok=True)


def save_catalogue(catalogue):
    catalogue["revision"] = secrets.token_hex(12)
    atomic_write(DATA_DIR / "playlist.json", json.dumps(catalogue).encode())
    # Retain the original image URL for existing clients during the firmware upgrade.
    if catalogue["photos"]:
        first = catalogue["photos"][0]["id"]
        atomic_write(DATA_DIR / "current.png", (DATA_DIR / f"{first}.png").read_bytes())
    else:
        (DATA_DIR / "current.png").unlink(missing_ok=True)


def read_catalogue():
    """Call with catalogue_lock held. Import the old single image exactly once."""
    path = DATA_DIR / "playlist.json"
    if path.exists():
        return json.loads(path.read_text())
    catalogue = {"version": 1, "interval_ms": 5000, "photos": []}
    old = DATA_DIR / "current.png"
    if old.exists():
        photo_id = secrets.token_hex(16)
        atomic_write(DATA_DIR / f"{photo_id}.png", old.read_bytes())
        catalogue["photos"].append({"id": photo_id, "name": "Our first picture",
                                     "url": f"/images/{photo_id}.png"})
    save_catalogue(catalogue)
    return catalogue


def csrf_token():
    if "csrf" not in session:
        session["csrf"] = secrets.token_urlsafe(32)
    return session["csrf"]


def authenticated():
    return session.get("authenticated") is True


@app.before_request
def protect_admin():
    if request.path.startswith("/admin/") and request.endpoint != "static":
        if request.endpoint not in {"index", "login"} and not authenticated():
            return redirect(url_for("index"))
        if request.method == "POST":
            supplied = request.form.get("csrf", "")
            expected = session.get("csrf", "")
            if not (supplied and expected and hmac.compare_digest(supplied, expected)):
                abort(400, "Your session changed. Reload the page and try again.")


@app.after_request
def private_responses(response):
    if request.path.startswith("/admin/") and request.endpoint != "static":
        response.headers["Cache-Control"] = "no-store"
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    return response


def page(view="home"):
    catalogue = {"photos": [], "revision": "", "interval_ms": 5000}
    if authenticated():
        with catalogue_lock():
            catalogue = read_catalogue()
    return render_template("portal.html", logged_in=authenticated(), view=view,
                           site_title=SITE_TITLE, site_tagline=SITE_TAGLINE,
                           catalogue=catalogue, csrf=csrf_token(), devices=device_status() if authenticated() else [],
                           preview_mode=app.config.get("PREVIEW_MODE", False))


@app.get("/admin/")
def index():
    return page()


@app.get("/admin/catalogue")
def catalogue_page():
    return page("catalogue")


@app.post("/admin/login")
def login():
    try:
        valid = check_password_hash(os.environ["ADMIN_PASSWORD_HASH"], request.form.get("password", ""))
    except (ValueError, KeyError):
        app.logger.error("Portal password hash is missing or malformed")
        flash("Sign-in needs a server configuration fix. Please contact the administrator.")
        return redirect(url_for("index"))
    if valid:
        session.clear()
        session["authenticated"] = True
        csrf_token()
    else:
        flash("That password did not work. Try again.")
    return redirect(url_for("index"))


@app.post("/admin/logout")
def logout():
    session.clear()
    return redirect(url_for("index"))


@app.get("/admin/playlist")
def playlist():
    with catalogue_lock():
        return jsonify(read_catalogue())


def device_status():
    with catalogue_lock():
        path = DATA_DIR / ".devices.json"
        seen = json.loads(path.read_text()) if path.exists() else {}
    now = time.time()
    return [{"id": device_id, "name": name, "last_seen": seen.get(device_id),
             "online": device_id in seen and 0 <= now - seen[device_id] < ONLINE_SECONDS}
            for device_id, name in DEVICE_NAMES.items()]


@app.get("/admin/devices")
def devices():
    return jsonify(devices=device_status())


@app.post("/device/heartbeat")
def heartbeat():
    # Only enable after NGINX Basic Auth and the overriding identity header are configured.
    # The portal port must stay private to the Compose network (no host port mapping).
    if os.environ.get("DEVICE_HEARTBEATS_ENABLED") != "true":
        abort(503)
    device_id = request.headers.get("X-Mini-TV-User", "")
    if device_id not in DEVICE_NAMES:
        abort(403)
    with catalogue_lock():
        path = DATA_DIR / ".devices.json"
        seen = json.loads(path.read_text()) if path.exists() else {}
        seen[device_id] = time.time()
        atomic_write(path, json.dumps(seen).encode())
    return jsonify(status="ok", heartbeat_interval_seconds=30)


@app.get("/admin/photos/<photo_id>.png")
def photo(photo_id):
    if not re.fullmatch(r"[0-9a-f]{32}", photo_id):
        abort(404)
    try:
        return send_file(DATA_DIR / f"{photo_id}.png", mimetype="image/png")
    except FileNotFoundError:
        abort(404)


@app.get("/admin/current.png")
def current_image():
    if not (DATA_DIR / "current.png").exists():
        abort(404)
    return send_file(DATA_DIR / "current.png", mimetype="image/png")


def process_image(uploaded):
    raw = uploaded.read(MAX_UPLOAD_BYTES + 1)
    if len(raw) > MAX_UPLOAD_BYTES:
        raise ValueError("Choose a picture smaller than 20 MB.")
    with warnings.catch_warnings():
        warnings.simplefilter("error", Image.DecompressionBombWarning)
        with Image.open(io.BytesIO(raw)) as source:
            # Phones may store a primary JPEG with extra depth/HDR frames. Pillow
            # identifies that JPEG-family container as MPO.
            if source.format not in {"JPEG", "MPO", "PNG", "WEBP"}:
                detected = source.format or "unknown"
                raise ValueError(f"This file is internally {detected}, not JPG, PNG, or WebP.")
            source.verify()
    with Image.open(io.BytesIO(raw)) as source:
        oriented = ImageOps.exif_transpose(source)
        fitted = ImageOps.contain(oriented.convert("RGBA"), (320, 240), Image.Resampling.LANCZOS)
        canvas = Image.new("RGB", (320, 240), "black")
        canvas.paste(fitted, ((320 - fitted.width) // 2, (240 - fitted.height) // 2), fitted)
        buffer = io.BytesIO()
        canvas.save(buffer, "PNG", optimize=True)
        return buffer.getvalue()


@app.post("/admin/upload")
def upload():
    wants_json = request.accept_mimetypes.best == "application/json"
    def failure(message, status=400):
        if wants_json:
            return jsonify(error=message), status
        flash(message)
        return redirect(url_for("catalogue_page"))
    if len(request.files.getlist("photo")) > 1:
        return failure("Enable JavaScript to upload multiple pictures, or choose one picture at a time.")
    uploaded = request.files.get("photo")
    if not uploaded or not uploaded.filename:
        return failure("Choose a picture first.")
    upload_id = request.form.get("upload_id", "")
    if upload_id and not re.fullmatch(r"[0-9a-f]{32}", upload_id):
        return failure("Invalid upload identifier. Choose the picture again.")
    try:
        data = process_image(uploaded)
    except (UnidentifiedImageError, OSError, ValueError, Image.DecompressionBombError, Image.DecompressionBombWarning):
        return failure("Use a JPG, PNG, or WebP under 20 MB and 24 megapixels.")
    with catalogue_lock():
        catalogue = read_catalogue()
        photo_id = upload_id or secrets.token_hex(16)
        # Retrying a request after a lost response must not add a duplicate picture.
        if upload_id and any(p["id"] == upload_id for p in catalogue["photos"]):
            return jsonify(status="ok", id=upload_id, duplicate=True)
        atomic_write(DATA_DIR / f"{photo_id}.png", data)
        name = uploaded.filename.replace("\\", "/").split("/")[-1][:160]
        catalogue["photos"].append({"id": photo_id, "name": name, "url": f"/images/{photo_id}.png"})
        save_catalogue(catalogue)
    if wants_json:
        return jsonify(status="ok", id=photo_id), 201
    flash("Picture added to our show.")
    return redirect(url_for("catalogue_page"))


def check_revision(catalogue):
    if request.form.get("revision") != catalogue["revision"]:
        flash("The catalogue changed in another window. Review the refreshed order and try again.")
        return False
    return True


@app.post("/admin/reorder")
def reorder():
    with catalogue_lock():
        catalogue = read_catalogue()
        if not check_revision(catalogue):
            return redirect(url_for("catalogue_page"))
        order = request.form.getlist("order")
        photos = {p["id"]: p for p in catalogue["photos"]}
        if len(order) != len(photos) or set(order) != set(photos):
            abort(400, "Invalid photo order")
        catalogue["photos"] = [photos[photo_id] for photo_id in order]
        save_catalogue(catalogue)
    flash("Slideshow order saved.")
    return redirect(url_for("catalogue_page"))


@app.post("/admin/delete/<photo_id>")
def delete(photo_id):
    with catalogue_lock():
        catalogue = read_catalogue()
        if not check_revision(catalogue):
            return redirect(url_for("catalogue_page"))
        if photo_id not in {p["id"] for p in catalogue["photos"]}:
            abort(404)
        catalogue["photos"] = [p for p in catalogue["photos"] if p["id"] != photo_id]
        save_catalogue(catalogue)
        (DATA_DIR / f"{photo_id}.png").unlink(missing_ok=True)
    flash("Picture deleted from our show.")
    return redirect(url_for("catalogue_page"))


@app.get("/health")
def health():
    return {"status": "ok"}


def device_identity():
    # Only the private Docker network may reach this app; NGINX replaces this header.
    if os.environ.get("DEVICE_HEARTBEATS_ENABLED", "").lower() != "true":
        abort(503)
    identity = request.headers.get("X-Mini-TV-User", "")
    if identity not in DEVICE_NAMES:
        abort(403)
    return identity


@app.get("/device/next")
def device_next():
    device_identity()
    after = request.args.get("after", "")
    if after and not re.fullmatch(r"[0-9a-f]{32}", after):
        abort(400)
    with catalogue_lock():
        catalogue = read_catalogue()
        photos = catalogue["photos"]
        if not photos:
            return "", 204
        ids = [photo["id"] for photo in photos]
        index = (ids.index(after) + 1) % len(ids) if after in ids else 0
        photo_id = ids[index]
        # Avoid retransmitting the sole unchanged image on every poll.
        if len(ids) == 1 and photo_id == after:
            return "", 204
        with Image.open(DATA_DIR / f"{photo_id}.png") as image:
            image = ImageOps.pad(image.convert("RGB"), (320, 240), color="black")
            pixels = array("H", (((r >> 3) << 11) | ((g >> 2) << 5) | (b >> 3)
                                 for r, g, b in image.getdata()))
    if sys.byteorder == "little":
        pixels.byteswap()
    data = pixels.tobytes()
    return app.response_class(data, mimetype="application/octet-stream", headers={
        "Cache-Control": "no-store", "X-Photo-ID": photo_id,
        "X-Frame-SHA256": hashlib.sha256(data).hexdigest()})


@app.get("/device/firmware/<name>")
def device_firmware(name):
    identity = device_identity()
    # Immutable, digest-named binaries prevent a publishing race with manifest reads.
    if name != "manifest.txt" and not re.fullmatch(r"[0-9a-f]{64}\.bin", name):
        abort(404)
    directory = Path(os.environ.get("FIRMWARE_DIR", "/firmware")) / identity
    path = directory / name
    if not path.is_file():
        abort(404)
    return send_file(path, mimetype="application/octet-stream", max_age=0)


@app.errorhandler(413)
def too_large(_error):
    if request.accept_mimetypes.best == "application/json":
        return jsonify(error="Choose a picture smaller than 20 MB."), 413
    flash("Choose a picture smaller than 20 MB.")
    return redirect(url_for("index"))
