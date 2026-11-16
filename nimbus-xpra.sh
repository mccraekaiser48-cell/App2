#!/usr/bin/env bash
# nimbus-xpra.sh — replaces the KasmVNC stream with xpra's HTML5 client.
#
# Run it from Termux:
#   curl -fsSL https://raw.githubusercontent.com/mccraekaiser48-cell/App2/main/scripts/nimbus-xpra.sh | bash
#
# It never touches KasmVNC or its tunnel: if xpra fails, the old stream is still
# there. What it does:
#   1. inside Debian: installs xpra 6 from xpra.org, starts a desktop session on
#      :10 with Brave Origin in it, serving the browser client on port 10000
#   2. inside Ubuntu: opens a cloudflared tunnel to that port and prints the URL
#
# xpra is the only browser-streamable protocol that is meaningfully faster than
# KasmVNC: it sends damaged regions with an adaptive encoder instead of whole
# frames, so it survives a slow link without queueing.

set -u

step() { printf '\n=== %s ===\n' "$1"; }

step "1/2  install and start xpra inside Debian"
proot-distro login debian -- bash -c '
set -e
export DEBIAN_FRONTEND=noninteractive
grep -qi "Debian GNU/Linux 12" /etc/os-release || { echo "ERROR: this is not Debian 12 - run: proot-distro login debian"; exit 1; }

apt-get update -qq
apt-get install -y -qq curl ca-certificates gnupg
curl -fsSL https://xpra.org/xpra.asc -o /usr/share/keyrings/xpra.asc
echo "deb [signed-by=/usr/share/keyrings/xpra.asc] https://xpra.org/ bookworm main" > /etc/apt/sources.list.d/xpra.list
apt-get update -qq
apt-get install -y -qq xpra xpra-html5 xvfb x11-utils xauth xdotool openbox

command -v brave-origin >/dev/null 2>&1 || echo "WARNING: brave-origin is missing in Debian; the session will start with an empty desktop"

xpra stop :10 >/dev/null 2>&1 || true
sleep 1

# --auth=allow and --tcp-auth=allow mean no password prompt in the browser.
xpra start-desktop :10 \
  --daemon=yes \
  --start=openbox \
  --bind-tcp=0.0.0.0:10000 \
  --html=on \
  --auth=allow \
  --tcp-auth=allow \
  --encoding=h264 \
  --min-quality=30 \
  --speed=80 \
  --start-child="brave-origin --no-sandbox --disable-dev-shm-usage --no-zygote --disable-gpu --enable-low-end-device-mode --num-raster-threads=4 --window-position=0,0 --window-size=1400,800 about:blank"

sleep 6
echo "--- xpra version ---"; xpra --version | head -2
echo "--- sessions ---";     xpra list
echo "--- port 10000 ---";   (command -v ss >/dev/null && ss -ltn 2>/dev/null | grep 10000) || echo "(ss not installed)"
'

step "2/2  tunnel port 10000 from Ubuntu (KasmVNC tunnel left alone)"
proot-distro login ubuntu -- bash -c '
set -u
command -v cloudflared >/dev/null 2>&1 || { echo "ERROR: cloudflared missing in Ubuntu"; exit 1; }
nohup cloudflared tunnel --url http://localhost:10000 > /root/xpra-tunnel.log 2>&1 &
sleep 14
url=$(grep -o "https://[a-z0-9.-]*\.trycloudflare\.com" /root/xpra-tunnel.log | tail -1)
if [ -n "$url" ]; then
  echo "XPRA URL: $url"
  echo "open $url/ in the Chromebook, or add it to the Brave Origin app as a second address"
else
  echo "no URL yet - last lines of the tunnel log:"
  tail -5 /root/xpra-tunnel.log
fi
'
