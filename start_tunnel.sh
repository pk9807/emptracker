#!/usr/bin/env bash
# ==============================================================================
# Cloudflare Tunnel Launcher for EmpTracker Platform
# Exposes Laravel API, Admin Web Portal & Employee Web Portal to Public HTTPS
# ==============================================================================

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BIN="$DIR/bin/cloudflared"

if [ ! -f "$BIN" ]; then
    echo "❌ cloudflared binary not found in $BIN. Downloading..."
    mkdir -p "$DIR/bin"
    wget -q -O "$BIN" https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64
    chmod +x "$BIN"
fi

echo "🚀 Starting Cloudflare Public Tunnel for EmpTracker..."
echo "📡 Local Target: http://127.0.0.1:80 (Apache/Nginx)"
echo "--------------------------------------------------------"

"$BIN" tunnel --url http://127.0.0.1:80 --http-host-header localhost --protocol http2
