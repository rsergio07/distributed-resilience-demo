
from flask import Flask, render_template
import os
import socket
from datetime import datetime

app = Flask(__name__)

COLOR = os.getenv("COLOR", "#0ea5e9")  # default sky blue
REGION = os.getenv("REGION", "blue")
VERSION = os.getenv("VERSION", "v1.0.0")

@app.route("/")
def index():
    hostname = socket.gethostname()
    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M:%S UTC")
    return render_template("index.html",
                           color=COLOR,
                           region=REGION,
                           hostname=hostname,
                           version=VERSION,
                           timestamp=now)

@app.route("/healthz")
def health():
    return "ok", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
