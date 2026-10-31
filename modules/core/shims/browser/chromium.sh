#!/system/bin/sh
# AGY browser delegator: delegates to xdg-open in the same directory.
TARGET="$(dirname "$0")/xdg-open"
if [ -x /system/bin/sh ]; then
  exec "$TARGET" "$@"
else
  exec sh "$TARGET" "$@"
fi
