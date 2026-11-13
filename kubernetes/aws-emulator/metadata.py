"""Expose this emulator run's credentials through the IMDS API used by ZTS."""

from configparser import ConfigParser
from datetime import datetime, timedelta, timezone
from http.server import BaseHTTPRequestHandler, HTTPServer
import json


CREDENTIALS_FILE = "/var/run/aws-emulator/9297/emulator_credentials"
TOKEN = "aws-emulator-imds-token"


class Handler(BaseHTTPRequestHandler):
    def respond(self, status, body, content_type="text/plain"):
        data = body.encode()
        self.send_response(status)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_PUT(self):
        if self.path == "/latest/api/token":
            self.respond(200, TOKEN)
        else:
            self.respond(404, "not found")

    def do_GET(self):
        if self.headers.get("X-aws-ec2-metadata-token") != TOKEN:
            self.respond(401, "metadata token required")
            return
        if self.path == "/latest/meta-data/iam/security-credentials/":
            self.respond(200, "zts")
            return
        if self.path != "/latest/meta-data/iam/security-credentials/zts":
            self.respond(404, "not found")
            return

        credentials = ConfigParser()
        if not credentials.read(CREDENTIALS_FILE):
            self.respond(503, "emulator credentials are not ready")
            return
        profile = credentials["default"]
        body = {
            "Code": "Success",
            "AccessKeyId": profile["aws_access_key_id"],
            "SecretAccessKey": profile["aws_secret_access_key"],
            "Expiration": (datetime.now(timezone.utc) + timedelta(hours=1)).isoformat(),
        }
        self.respond(200, json.dumps(body), "application/json")

    def log_message(self, format, *args):
        pass  # Never write credentials or request headers to pod logs.


HTTPServer(("127.0.0.1", 1338), Handler).serve_forever()
