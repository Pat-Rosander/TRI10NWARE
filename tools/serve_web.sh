#!/usr/bin/env bash
# Serves builds/web/ over local HTTP so the web build is tested the way browsers load it, never
# from file://. Maps .wasm to application/wasm explicitly. Serves AC D-03 (spec, M0 step 10).
# Usage: tools/serve_web.sh [port]   (default 8000)
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEB="$ROOT/builds/web"
PORT="${1:-8000}"

if [[ ! -f "$WEB/index.html" ]]; then
	echo "serve_web: no web build at $WEB; run tools/export_all.sh first." >&2
	exit 1
fi

echo "Serving $WEB"
echo "  Play:        http://localhost:$PORT/"
echo "  Debug tools: http://localhost:$PORT/?debug=1"
echo "Press Ctrl+C to stop."

exec python3 - "$WEB" "$PORT" <<'PY'
import functools
import http.server
import sys

web_dir, port = sys.argv[1], int(sys.argv[2])


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {
        **http.server.SimpleHTTPRequestHandler.extensions_map,
        ".wasm": "application/wasm",
        ".pck": "application/octet-stream",
        ".js": "text/javascript",
    }

    def end_headers(self):
        # Always fetch the newest export instead of a cached one.
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


handler = functools.partial(Handler, directory=web_dir)
with http.server.ThreadingHTTPServer(("127.0.0.1", port), handler) as server:
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
PY
