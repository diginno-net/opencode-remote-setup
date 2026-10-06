#!/bin/zsh
# opencode serve từng bị treo mà KHÔNG thoát: process còn sống nên KeepAlive
# không khởi động lại, nhưng socket thì không mở — URL ngoài trả 502.
# Chạy định kỳ (LaunchAgent StartInterval 300): curl thất bại thì restart.
# bootstrap ngay sau bootout hay gặp lỗi tạm thời (I/O error 5) nên phải thử lại.
LABEL="com.user.opencode-serve"
UID_=$(id -u)
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
LOG="$HOME/.local/share/opencode/serve-watchdog.log"
mkdir -p "$(dirname "$LOG")"

health() { curl -fsS -m 5 -o /dev/null http://127.0.0.1:4096/; }

if health; then
  exit 0
fi

echo "$(date '+%F %T') health check failed, restarting $LABEL" >> "$LOG"
launchctl bootout "gui/$UID_/$LABEL" 2>/dev/null || true

for i in 1 2 3 4 5; do
  sleep 3
  launchctl bootstrap "gui/$UID_" "$PLIST" 2>/dev/null || true
  if health; then
    echo "$(date '+%F %T') recovered after attempt $i" >> "$LOG"
    exit 0
  fi
done
echo "$(date '+%F %T') FAILED to recover after 5 attempts" >> "$LOG"
exit 1
