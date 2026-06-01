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

export NULLCLAW_ALLOW_PUBLIC_BIND="${NULLCLAW_ALLOW_PUBLIC_BIND:-true}"

if [ -n "${PORT:-}" ] && [ -z "${NULLCLAW_GATEWAY_PORT:-}" ]; then
  export NULLCLAW_GATEWAY_PORT="$PORT"
fi

mkdir -p "$NULLCLAW_HOME" "$NULLCLAW_WORKSPACE" 2>/dev/null || {
  echo "warning: unable to create persistent data directories; check volume permissions" >&2
}

if [ ! -f "$NULLCLAW_HOME/config.json" ] && [ -f /usr/share/nullclaw/config.json ]; then
  cp /usr/share/nullclaw/config.json "$NULLCLAW_HOME/config.json" 2>/dev/null || {
    echo "warning: unable to seed config.json; run nullclaw onboard to create one" >&2
  }
fi

if [ -n "${NULLCLAW_PRIMARY_MODEL:-}" ]; then
  nullclaw config set agents.defaults.model.primary "$NULLCLAW_PRIMARY_MODEL" >/dev/null 2>&1 || {
    echo "warning: unable to apply NULLCLAW_PRIMARY_MODEL; check config.json" >&2
  }
fi

provider="${NULLCLAW_PROVIDER:-}"
if [ -z "$provider" ] && [ -n "${NULLCLAW_BASE_URL:-}" ]; then
  compat="$(printf '%s' "${NULLCLAW_COMPAT:-${NULLCLAW_PROVIDER_TYPE:-openai}}" | tr '[:upper:]' '[:lower:]')"
  case "$compat" in
    anthropic|anthropic-compatible|anthropic_custom|anthropic-custom|claude)
      provider="anthropic-custom:${NULLCLAW_BASE_URL}"
      ;;
    openai|openai-compatible|openai_custom|openai-custom|compatible|"")
      provider="custom:${NULLCLAW_BASE_URL}"
      ;;
    *)
      echo "warning: unknown NULLCLAW_COMPAT value; defaulting NULLCLAW_BASE_URL to OpenAI-compatible custom provider" >&2
      provider="custom:${NULLCLAW_BASE_URL}"
      ;;
  esac
fi

if [ -n "$provider" ] && [ -n "${NULLCLAW_MODEL:-}" ] && [ -z "${NULLCLAW_PRIMARY_MODEL:-}" ]; then
  nullclaw config set agents.defaults.model.primary "${provider}/${NULLCLAW_MODEL}" >/dev/null 2>&1 || {
    echo "warning: unable to apply NULLCLAW_PROVIDER/NULLCLAW_MODEL; check config.json" >&2
  }
fi

telegram_account_id="${NULLCLAW_TELEGRAM_ACCOUNT_ID:-${TELEGRAM_ACCOUNT_ID:-main}}"
telegram_base_path="channels.telegram.accounts.${telegram_account_id}"
telegram_bot_token="${NULLCLAW_TELEGRAM_BOT_TOKEN:-${TELEGRAM_BOT_TOKEN:-}}"
telegram_webhook_secret="${NULLCLAW_TELEGRAM_WEBHOOK_SECRET:-${TELEGRAM_WEBHOOK_SECRET:-}}"
telegram_allow_from="${NULLCLAW_TELEGRAM_ALLOW_FROM:-${TELEGRAM_ALLOW_FROM:-}}"
telegram_group_allow_from="${NULLCLAW_TELEGRAM_GROUP_ALLOW_FROM:-${TELEGRAM_GROUP_ALLOW_FROM:-}}"

if [ -n "$telegram_bot_token" ]; then
  nullclaw config set "${telegram_base_path}.bot_token" "$telegram_bot_token" >/dev/null 2>&1 || {
    echo "warning: unable to apply Telegram bot token; check config.json" >&2
  }
fi

if [ -n "$telegram_webhook_secret" ]; then
  nullclaw config set "${telegram_base_path}.webhook_secret" "$telegram_webhook_secret" >/dev/null 2>&1 || {
    echo "warning: unable to apply Telegram webhook secret; check config.json" >&2
  }
fi

if [ -n "$telegram_allow_from" ]; then
  nullclaw config set "${telegram_base_path}.allow_from" "$telegram_allow_from" >/dev/null 2>&1 || {
    echo "warning: unable to apply Telegram allow_from; use a JSON array such as [\"123456789\"]" >&2
  }
fi

if [ -n "$telegram_group_allow_from" ]; then
  nullclaw config set "${telegram_base_path}.group_allow_from" "$telegram_group_allow_from" >/dev/null 2>&1 || {
    echo "warning: unable to apply Telegram group_allow_from; use a JSON array such as [\"123456789\"]" >&2
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
