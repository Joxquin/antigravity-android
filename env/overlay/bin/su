#!/system/bin/sh
# AGY su wrapper: executes Android system su with a clean environment.
# Compatible with KernelSU, Magisk, and APatch.

SU_BIN=""
for candidate in /system/bin/su /system/xbin/su /sbin/su /data/adb/ksu/bin/su /data/adb/ap/bin/su /data/adb/magisk/su; do
  if [ -x "$candidate" ]; then
    SU_BIN="$candidate"
    break
  fi
done

if [ -z "$SU_BIN" ]; then
  SU_BIN="$(command -v su 2>/dev/null || true)"
fi

if [ -z "$SU_BIN" ] || [ ! -x "$SU_BIN" ]; then
  echo "su: superuser binary not found in standard system locations" >&2
  exit 127
fi

# Unset glibc and dynamic linker variables that conflict with Android bionic
exec env -u LD_PRELOAD -u LD_LIBRARY_PATH "$SU_BIN" "$@"
