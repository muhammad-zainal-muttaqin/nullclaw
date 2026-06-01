#!/bin/sh
set -eu

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
