"""Build a source-only server archive, excluding device binaries and all secrets."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parents[2]
portal = root / "homelab" / "portal"
output = root / "homelab" / "releases" / "mini-tv-portal-2.2.0.zip"
files = [portal / name for name in (
    "app.py", "Dockerfile", "requirements.txt", "nginx-default.conf", "README.md", "DEVICE_PROTOCOL.md")]
for directory in ("templates", "static"):
    files.extend(path for path in (portal / directory).rglob("*") if path.is_file())
files.extend(root / "firmware" / name for name in ("DEPLOYMENT.md", "VALIDATION.md"))
output.parent.mkdir(parents=True, exist_ok=True)
with ZipFile(output, "w", ZIP_DEFLATED) as archive:
    for path in files:
        archive.write(path, path.relative_to(root))
with ZipFile(output) as archive:
    assert archive.testzip() is None
    assert all("secrets" not in name and "/keys/" not in name and not name.endswith(".bin")
               for name in archive.namelist())
print(f"Server-only archive checked: {output} ({len(files)} files)")
