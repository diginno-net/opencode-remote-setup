#!/bin/zsh
# Dựng opencode serve trên macOS: LaunchAgent tự chạy khi đăng nhập + watchdog tự chữa.
# Chạy đúng 1 lần. Yêu cầu: opencode CLI đã cài (~/.opencode/bin/opencode), Tailscale đã đăng nhập.
#
#   export OPENCODE_SERVER_PASSWORD="$(openssl rand -base64 18 | tr -d '/+=')"
#   echo "Lưu mật khẩu này lại: $OPENCODE_SERVER_PASSWORD"
#   WORKDIR="$HOME/Documents/projects" ./scripts/macos/install-serve.sh
set -euo pipefail

: "${OPENCODE_SERVER_PASSWORD:?Hãy export OPENCODE_SERVER_PASSWORD trước}"
PORT="${PORT:-4096}"
WORKDIR="${WORKDIR:-$HOME}"
OPENCODE_BIN="${OPENCODE_BIN:-$HOME/.opencode/bin/opencode}"
LABEL="com.user.opencode-serve"
UID_="$(id -u)"
AGENTS_DIR="$HOME/Library/LaunchAgents"

[ -x "$OPENCODE_BIN" ] || { echo "Không thấy $OPENCODE_BIN — cài opencode trước hoặc đặt OPENCODE_BIN."; exit 1; }

mkdir -p "$AGENTS_DIR" "$HOME/.local/bin"

cat > "$AGENTS_DIR/$LABEL.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>$OPENCODE_BIN</string>
    <string>serve</string>
    <string>--hostname</string><string>127.0.0.1</string>
    <string>--port</string><string>$PORT</string>
  </array>
  <key>WorkingDirectory</key><string>$WORKDIR</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>OPENCODE_SERVER_PASSWORD</key><string>$OPENCODE_SERVER_PASSWORD</string>
  </dict>
  <key>RunAtLoad</key><true/>
  <key>KeepAlive</key><true/>
</dict></plist>
EOF

# Watchdog 5 phút/lần: serve treo không thoát thì KeepAlive không biết.
cp "$(dirname "$0")/opencode-serve-watchdog.sh" "$HOME/.local/bin/opencode-serve-watchdog.sh"
chmod +x "$HOME/.local/bin/opencode-serve-watchdog.sh"
sed -i '' "s|^LABEL=.*|LABEL=\"$LABEL\"|" "$HOME/.local/bin/opencode-serve-watchdog.sh"

cat > "$AGENTS_DIR/com.user.opencode-serve-watchdog.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>Label</key><string>com.user.opencode-serve-watchdog</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/zsh</string>
    <string>$HOME/.local/bin/opencode-serve-watchdog.sh</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>StartInterval</key><integer>300</integer>
</dict></plist>
EOF

launchctl bootout "gui/$UID_/$LABEL" 2>/dev/null || true
launchctl bootout "gui/$UID_/com.user.opencode-serve-watchdog" 2>/dev/null || true
launchctl bootstrap "gui/$UID_" "$AGENTS_DIR/$LABEL.plist"
launchctl bootstrap "gui/$UID_" "$AGENTS_DIR/com.user.opencode-serve-watchdog.plist"

sleep 3
curl -fsS -m 5 -o /dev/null "http://127.0.0.1:$PORT/" && echo "OK: serve nghe 127.0.0.1:$PORT, thư mục làm việc $WORKDIR"
echo "Tiếp theo: tailscale serve --bg http://127.0.0.1:$PORT"
