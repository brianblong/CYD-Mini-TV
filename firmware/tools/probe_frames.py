"""Read-only server probe. Never print credentials or picture contents."""
import base64
import hashlib
import http.client
import json
from pathlib import Path
import re
import ssl
import time

source = (Path(__file__).resolve().parents[1] / "include" / "secrets.h").read_text()
def setting(name):
    match = re.search(r'\b' + re.escape(name) + r'\s*\[\s*\]\s*=\s*("(?:[^"\\]|\\.)*")\s*;', source)
    if not match:
        raise SystemExit("Required local setting could not be parsed; no values printed.")
    return json.loads(match.group(1))

host = setting("TV_SERVER_HOST")
if not host or host == "photos.example.com":
    raise SystemExit("Set a real TV_SERVER_HOST in the ignored secrets.h file first.")
authorization = "Basic " + base64.b64encode((setting("TV_SERVER_USER") + ":" + setting("TV_SERVER_PASSWORD")).encode()).decode()
class HTTP10(http.client.HTTPSConnection):
    _http_vsn = 10
    _http_vsn_str = "HTTP/1.0"

cursor = ""
for number in range(3):
    connection = HTTP10(host, timeout=30, context=ssl.create_default_context())
    started = time.monotonic()
    try:
        connection.request("GET", "/device/next?after=" + cursor,
                           headers={"Host": host, "Authorization": authorization})
        response = connection.getresponse()
        body = response.read(153601)
        identifier = response.getheader("X-Photo-ID", "")
        print(json.dumps({"request": number + 1, "status": response.status,
              "content_length": response.getheader("Content-Length"),
              "transfer_encoding": response.getheader("Transfer-Encoding"),
              "bytes": len(body), "valid_id": bool(re.fullmatch("[0-9a-f]{32}", identifier)),
              "next_id_changed": bool(identifier and identifier != cursor),
              "digest_valid": hashlib.sha256(body).hexdigest() == response.getheader("X-Frame-SHA256"),
              "seconds": round(time.monotonic() - started, 2)}))
        if response.status != 200 or not re.fullmatch("[0-9a-f]{32}", identifier):
            break
        cursor = identifier
    except Exception as error:
        print("Probe failed: " + type(error).__name__)
        break
    finally:
        connection.close()
