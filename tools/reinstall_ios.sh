#!/bin/bash
# Keeps BullDozer alive on Kirill's iPhone. The free signing profile lasts
# 7 days, so the app vanishes without periodic reinstall.
#
# Runs DAILY (launchd: com.shpara.bulldozer.reinstall). Daily rather than
# weekly because any single attempt can miss — phone not connected, or Xcode
# unable to reach the Apple ID from the launchd context. With 7 chances per
# expiry window, one bad day no longer costs the whole week.
#
# Quiet when it works. Notifies only when the app is at real risk of expiring.
# Once the paid Apple Developer Program is active, none of this is needed.
set -o pipefail
export PATH="/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"
DEVICE="00008110-0004050C3633801E"          # Kirill's iPhone
APP=~/Projects/bulldozer_app
LOG=~/Library/Logs/bulldozer/reinstall_ios.log
STAMP=~/Library/Logs/bulldozer/last_success.txt
DANGER_DAYS=5                                # warn when expiry (7d) is near
ts() { date '+%Y-%m-%d %H:%M:%S'; }

days_since_success() {
  [ -f "$STAMP" ] || { echo 99; return; }
  local last now
  last=$(cat "$STAMP" 2>/dev/null || echo 0)
  now=$(date +%s)
  echo $(( (now - last) / 86400 ))
}

# Nag only when the app is actually about to die, so daily runs stay silent.
warn_if_stale() {
  local d; d=$(days_since_success)
  if [ "$d" -ge "$DANGER_DAYS" ]; then
    osascript -e "display notification \"Не обновлялось $d дн. — подключи и разблокируй iPhone (или запусти tools/reinstall_ios.sh вручную).\" with title \"BullDozer: приложение скоро протухнет\"" 2>/dev/null
    echo "$(ts) ⚠️ notified user (stale ${d}d)" >>"$LOG"
  fi
}

echo "===== $(ts) reinstall start =====" >>"$LOG"

# Device enumeration is racy — flutter can return before the iPhone appears —
# so give each probe a real timeout and retry.
connected=""
for attempt in 1 2 3; do
  if flutter devices --machine --device-timeout 20 2>/dev/null | grep -q "$DEVICE"; then
    connected=1; break
  fi
  echo "$(ts) device not seen (attempt $attempt/3), retrying…" >>"$LOG"
  sleep 10
done
if [ -z "$connected" ]; then
  echo "$(ts) iPhone not connected — skipping (stale $(days_since_success)d)" >>"$LOG"
  warn_if_stale
  exit 0
fi

cd "$APP" || { echo "$(ts) no project dir" >>"$LOG"; exit 1; }
echo "$(ts) building release…" >>"$LOG"
if flutter build ios --release >>"$LOG" 2>&1; then
  echo "$(ts) installing to device…" >>"$LOG"
  if flutter install -d "$DEVICE" --release >>"$LOG" 2>&1; then
    date +%s > "$STAMP"
    echo "$(ts) ✅ reinstall OK" >>"$LOG"
    exit 0
  fi
  echo "$(ts) ❌ install failed" >>"$LOG"
else
  # Most common cause: Xcode can't reach the Apple ID from launchd, so the
  # 7-day profile can't be reissued. Needs a manual run / Xcode sign-in.
  echo "$(ts) ❌ build failed (often: Xcode has no Apple ID in this context)" >>"$LOG"
fi
warn_if_stale
