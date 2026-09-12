# Mini TV photo portal

This Flask application stores an ordered photo catalogue, prepares 320 × 240
RGB565 frames for Mini TV devices, accepts authenticated device check-ins, and
serves signed firmware releases through an NGINX reverse proxy.

Personal photos and credentials belong in deployment storage, not in this source
directory or its Git history.

## Configuration

Copy `portal.env.example` to a private deployment location named `portal.env`.
Fill in the two secret values and optionally change the branding fields. The
`.gitignore` rule for `*.env` prevents the resulting file from being committed.

Generate values rather than inventing short secrets:

```powershell
# Random Flask session key
python -c "import secrets; print(secrets.token_hex(32))"

# Password hash for the website login
python -c "from werkzeug.security import generate_password_hash; print(generate_password_hash(input('Password: ')))"
```

Do not paste the resulting values into source code, screenshots, issues, or
commits.

## Run locally

Create a Python virtual environment, install `requirements.txt`, set the required
environment variables from your private configuration, and run Flask or Gunicorn.
The included `preview.py` creates temporary sample images and serves a loopback-only
design preview at `http://127.0.0.1:8765/admin/`.

## Production outline

1. Build the included Dockerfile.
2. Mount persistent photo storage at `/data`.
3. Mount private firmware releases at `/firmware` as read-only.
4. Load the private environment file into the container.
5. Put the container behind the provided NGINX configuration and HTTPS.
6. Create Basic Auth users matching the configured firmware device identities.
7. Keep the Flask container private to the container network; do not publish port
   8000 directly.

The NGINX configuration overwrites `X-Mini-TV-User` with the authenticated user
before proxying a device request. Do not expose the Flask device routes directly,
because they trust that verified identity header.

## Tests

From the repository root, with the dependencies installed:

```powershell
python -m unittest discover -s homelab/portal -p "test_*.py"
node --check homelab/portal/static/portal.js
```

Tests cover authentication, CSRF protection, uploads, catalogue persistence,
ordering, deletion, device status, and frame delivery.
