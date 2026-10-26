#!/usr/bin/env python3
"""Serve build/web locally and proxy /api requests to the eShop API.

This local-only proxy lets Flutter Web call the API without browser CORS
headers. It binds to loopback and forwards only to the configured API host.
"""

from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import urlsplit
from urllib.request import Request, urlopen
import mimetypes
import os
import sys


ROOT = Path(__file__).resolve().parents[1]
WEB_ROOT = ROOT / "build" / "web"
API_ORIGIN = "https://accessories-eshop.runasp.net"
PORT = int(os.environ.get("AURA_WEB_PORT", "57426"))


class Handler(SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=str(WEB_ROOT), **kwargs)

    def _proxy(self):
        target = API_ORIGIN + self.path
        body = self.rfile.read(int(self.headers.get("Content-Length", "0")))
        headers = {
            key: value
            for key, value in self.headers.items()
            if key.lower() in {"accept", "authorization", "content-type", "user-agent"}
        }
        request = Request(target, data=body or None, headers=headers, method=self.command)
        try:
            response = urlopen(request, timeout=45)
            status, payload, content_type = response.status, response.read(), response.headers.get("Content-Type")
        except HTTPError as error:
            status, payload, content_type = error.code, error.read(), error.headers.get("Content-Type")
        except URLError as error:
            payload = f"API proxy connection failed: {error.reason}".encode()
            status, content_type = 502, "text/plain; charset=utf-8"

        self.send_response(status)
        if content_type:
            self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(payload)))
        self.end_headers()
        if payload:
            self.wfile.write(payload)

    def do_GET(self):
        if urlsplit(self.path).path == "/api" or urlsplit(self.path).path.startswith("/api/"):
            return self._proxy()
        return super().do_GET()

    def do_POST(self):
        return self._proxy()

    def do_PUT(self):
        return self._proxy()

    def do_DELETE(self):
        return self._proxy()

    def do_OPTIONS(self):
        return self._proxy()

    def guess_type(self, path):
        if path.endswith(".wasm"):
            return "application/wasm"
        return mimetypes.guess_type(path)[0] or "application/octet-stream"

    def log_message(self, format, *args):
        message = format % args
        if "/api/" in message:
            message = message.split(" ")[0] + " [API request]"
        super().log_message("%s", message)


if not WEB_ROOT.is_dir():
    sys.exit("Missing build/web. Run `flutter build web` first.")

server = ThreadingHTTPServer(("127.0.0.1", PORT), Handler)
print(f"AURA Web is available at http://127.0.0.1:{PORT}", flush=True)
server.serve_forever()
