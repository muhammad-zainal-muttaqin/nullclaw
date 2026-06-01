#!/bin/sh
set -eu

data_root="${RAILWAY_VOLUME_MOUNT_PATH:-${NULLCLAW_DATA_DIR:-/nullclaw-data}}"

if [ "${NULLCLAW_HOME:-/nullclaw-data}" = "/nullclaw-data" ]; then
  export NULLCLAW_HOME="$data_root"
fi

if [ "${HOME:-/nullclaw-data}" = "/nullclaw-data" ]; then
  export HOME="$data_root"
fi

if [ "${NULLCLAW_WORKSPACE:-/nullclaw-data/workspace}" = "/nullclaw-data/workspace" ]; then
  export NULLCLAW_WORKSPACE="$data_root/workspace"
fi

mkdir -p "$NULLCLAW_HOME" "$NULLCLAW_WORKSPACE" 2>/dev/null || {
  echo "warning: unable to create persistent data directories; check volume permissions" >&2
}

if [ ! -f "$NULLCLAW_HOME/config.json" ] && [ -f /usr/share/nullclaw/config.json ]; then
  cp /usr/share/nullclaw/config.json "$NULLCLAW_HOME/config.json" 2>/dev/null || {
    echo "warning: unable to seed config.json; run nullclaw onboard to create one" >&2
  }
fi

if [ "$#" -eq 0 ]; then
  set -- gateway
fi

if [ "$1" = "gateway" ]; then
  shift

  has_port=0
  has_host=0
  for arg in "$@"; do
    case "$arg" in
      --port|-p) has_port=1 ;;
      --host) has_host=1 ;;
    esac
  done

  if [ "$has_host" -eq 0 ]; then
    set -- --host "${NULLCLAW_GATEWAY_HOST:-0.0.0.0}" "$@"
  fi

  if [ "$has_port" -eq 0 ]; then
    # Railway injects PORT at runtime; fall back to the local Docker default.
    set -- --port "${PORT:-${NULLCLAW_GATEWAY_PORT:-3000}}" "$@"
  fi

  exec nullclaw gateway "$@"
fi

exec nullclaw "$@"
