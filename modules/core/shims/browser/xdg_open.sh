#!/system/bin/sh
# AGY URL & File Opener Shim (xdg-open / open / sensible-browser / termux-open).
# Dispatches URLs & Files via Antigravity System Gateway, Root Shell, or Broadcasts.

unset LD_PRELOAD
unset LD_LIBRARY_PATH

URL=""

# 1. Search for first argument starting with http://, https://, or file://
for arg in "$@"; do
  case "$arg" in
    http://*|https://*|file://*)
      URL="$arg"
      break
      ;;
  esac
done

# 2. Fallback: search for first argument not starting with hyphen '-'
if [ -z "$URL" ]; then
  for arg in "$@"; do
    case "$arg" in
      -*|"")
        ;;
      *)
        if [ -f "$arg" ] || [ -d "$arg" ]; then
          URL=$(realpath "$arg" 2>/dev/null || echo "$PWD/$arg")
        else
          URL="$arg"
        fi
        break
        ;;
    esac
  done
fi

[ -z "$URL" ] && exit 0

# Emit stdout markers captured by CoreProcessSupervisor / OpenUrlWatcher
echo "AGY_OPEN_URL=$URL"
echo "ANTIGRAVITY_OPEN_URL: $URL"

# 1. Attempt dispatch via Antigravity System Gateway HTTP API (Zero Root required)
PORT=""
if [ -n "$PREFIX" ] && [ -f "$PREFIX/../logs/gateway.port" ]; then
  PORT=$(cat "$PREFIX/../logs/gateway.port" 2>/dev/null)
elif [ -f "/data/user/0/com.agy/files/logs/gateway.port" ]; then
  PORT=$(cat "/data/user/0/com.agy/files/logs/gateway.port" 2>/dev/null)
elif [ -f "/data/data/com.agy/files/logs/gateway.port" ]; then
  PORT=$(cat "/data/data/com.agy/files/logs/gateway.port" 2>/dev/null)
elif [ -d "/data/user/0/com.agy" ] || [ -d "/data/data/com.agy" ]; then
  PORT=45160
fi

case "$PORT" in
  ''|*[!0-9]*) PORT="" ;;
esac

if [ -n "$PORT" ]; then
  JSON_URL=$(printf '%s' "$URL" | sed 's/\\/\\\\/g; s/"/\\"/g')
  PAYLOAD="{\"command\":\"open_url\",\"payload\":{\"url\":\"$JSON_URL\"}}"

  CURL_BIN=""
  if [ -n "$PREFIX" ] && [ -x "$PREFIX/bin/curl" ]; then
    CURL_BIN="$PREFIX/bin/curl"
  elif [ -x /data/user/0/com.agy/files/usr/bin/curl ]; then
    CURL_BIN="/data/user/0/com.agy/files/usr/bin/curl"
  fi

  if [ -n "$CURL_BIN" ]; then
    LIB_DIR=""
    [ -n "$PREFIX" ] && [ -d "$PREFIX/lib" ] && LIB_DIR="$PREFIX/lib"
    [ -z "$LIB_DIR" ] && [ -d "/data/user/0/com.agy/files/usr/lib" ] && LIB_DIR="/data/user/0/com.agy/files/usr/lib"

    RESP=$(LD_LIBRARY_PATH="$LIB_DIR" "$CURL_BIN" -s --connect-timeout 1 -m 2 -X POST "http://127.0.0.1:$PORT/gateway" \
      -H "Content-Type: application/json" \
      -d "$PAYLOAD" 2>/dev/null || true)
    case "$RESP" in
      *'"ok":true'*|*'"ok": true'*)
        exit 0
        ;;
    esac
  fi
fi

# 2. Fallback: Root dispatch via su (KernelSU / Magisk / APatch) on Android
if [ -x /system/bin/sh ]; then
  SU_BIN=""
  if [ -n "$PREFIX" ] && [ -x "$PREFIX/bin/su" ]; then
    SU_BIN="$PREFIX/bin/su"
  elif [ -x /data/user/0/com.agy/files/usr/bin/su ]; then
    SU_BIN="/data/user/0/com.agy/files/usr/bin/su"
  elif [ -x /system/bin/su ]; then
    SU_BIN="/system/bin/su"
  elif [ -x /system/xbin/su ]; then
    SU_BIN="/system/xbin/su"
  fi

  if [ -n "$SU_BIN" ]; then
    if "$SU_BIN" -c "/system/bin/am start -a android.intent.action.VIEW -d \"$URL\"" >/dev/null 2>&1; then
      exit 0
    fi
  fi
fi

# 3. Fallback: Direct broadcast / am start for shell or older Android versions
if [ -x /system/bin/am ]; then
  /system/bin/am broadcast -a com.agy.ACTION_OPEN_URL -p com.agy --es url "$URL" >/dev/null 2>&1 || true
  /system/bin/am broadcast -a com.agy.ACTION_OPEN_URL -p com.agy.dev --es url "$URL" >/dev/null 2>&1 || true
  /system/bin/am start -a android.intent.action.VIEW -d "$URL" >/dev/null 2>&1 || true
fi

exit 0
