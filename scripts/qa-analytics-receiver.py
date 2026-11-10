import json
from http.server import BaseHTTPRequestHandler, HTTPServer

class Handler(BaseHTTPRequestHandler):
    events = []
    def do_GET(self):
        data = json.dumps(self.events).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Cache-Control", "no-store")
        self.end_headers()
        self.wfile.write(data)

    def do_POST(self):
        data = json.loads(self.rfile.read(int(self.headers["Content-Length"])))
        assert self.path == "/i/v0/e/" and data["api_key"] == "phc_watchweeks_qa"
        props = data["properties"]
        assert props["$geoip_disable"] and not props["$process_person_profile"]
        self.events.append({"event": data["event"], "id": data["distinct_id"]})
        self.send_response(200)
        self.end_headers()

HTTPServer(("127.0.0.1", 8766), Handler).serve_forever()
