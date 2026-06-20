# This is our tiny web server. It reads an environment variable (dev vs prod) to prove we can handle configurations.

import os
from http.server import BaseHTTPRequestHandler, HTTPServer

# This grabs the environment variable, defaulting to 'dev'
env = os.getenv("ENVIRONMENT", "dev")

class MyHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-type", "text/plain")
        self.end_headers()
        self.wfile.write(f"Hello from the {env} environment!".encode("utf-8"))

if __name__ == "__main__":
    print("Starting server on port 8080...")
    HTTPServer(("0.0.0.0", 8080), MyHandler).serve_forever()
