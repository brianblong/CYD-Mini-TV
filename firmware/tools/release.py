"""Offline signing. Never copy keys/ to the server or share firmware binaries."""
import argparse
import hashlib
import re
from pathlib import Path
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import ec

ROOT = Path(__file__).resolve().parents[1]
KEY = ROOT / "keys" / "ota-private.pem"
PUBLIC = ROOT / "include" / "ota_public_key.h"


def initialize():
    if KEY.exists() or PUBLIC.exists():
        raise SystemExit("Signing identity already exists; refusing to replace it.")
    key = ec.generate_private_key(ec.SECP256R1())
    KEY.parent.mkdir(exist_ok=True)
    with KEY.open("xb") as file:
        file.write(key.private_bytes(serialization.Encoding.PEM,
            serialization.PrivateFormat.PKCS8, serialization.NoEncryption()))
    KEY.chmod(0o600)
    pem = key.public_key().public_bytes(serialization.Encoding.PEM,
                                      serialization.PublicFormat.SubjectPublicKeyInfo).decode()
    PUBLIC.write_text('#pragma once\nconstexpr char kOtaPublicKey[] = R"KEY(' + pem + ')KEY";\n')
    print("Signing identity created. Back up keys/ privately; only the public key is compiled.")


def package(binary, device, version):
    data = binary.read_bytes()
    if not data or data[0] != 0xE9 or len(data) > 0x1B0000:
        raise SystemExit("Not a supported ESP32 application image or exceeds OTA slot.")
    if not 1 <= version <= 2147483647:
        raise SystemExit("Version must be a positive 31-bit integer.")
    # This marker is embedded alongside the compiled numeric version in main.cpp.
    marker = f"MINITV:cyd-st7789-4m-v1:{version}".encode() + b"\0"
    if marker not in data:
        raise SystemExit("Binary does not match the requested firmware version/hardware.")
    if b"MINITV_CHECK_BUILD_DO_NOT_RELEASE" in data:
        raise SystemExit("Example-credentials check builds cannot be published.")
    if b"MINITVDEVICE:" + device.encode() + b"\0" not in data:
        raise SystemExit("Binary device account does not match the selected destination.")
    digest = hashlib.sha256(data).hexdigest()
    message = f"MINITV1\n{device}\ncyd-st7789-4m-v1\n{version}\n{len(data)}\n{digest}\n".encode()
    key = serialization.load_pem_private_key(KEY.read_bytes(), password=None)
    signature = key.sign(message, ec.ECDSA(hashes.SHA256()))
    folder = ROOT / "releases" / f"{device}-{version}"
    folder.mkdir(parents=True, exist_ok=False)
    (folder / f"{digest}.bin").write_bytes(data)
    (folder / "manifest.txt").write_bytes(message + signature.hex().encode() + b"\n")
    print(f"Signed release saved to {folder}. Upload the binary first, manifest last.")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="action", required=True)
    sub.add_parser("init")
    release = sub.add_parser("package")
    release.add_argument("--binary", type=Path, required=True)
    release.add_argument("--device", choices=["tv-local", "tv-remote"], required=True)
    release.add_argument("--version", type=int, required=True)
    args = parser.parse_args()
    if args.action == "init":
        initialize()
    else:
        package(args.binary, args.device, args.version)
