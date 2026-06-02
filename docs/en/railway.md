# Railway Deployment

Use this fork directly from Railway with **Deploy from GitHub repo**.

Railway reads `railway.json`, builds the checked-in `Dockerfile`, injects `PORT`,
and checks `/health`. The container entrypoint maps that dynamic `PORT` to:

```bash
nullclaw gateway --host 0.0.0.0 --port "$PORT"
```

## Required variables

Set at least one provider credential before using agent endpoints or channels:

| Variable | Purpose |
|---|---|
| `OPENROUTER_API_KEY` | Recommended default provider credential |
| `NULLCLAW_PRIMARY_MODEL` | Optional provider/model ref, for example `openrouter/anthropic/claude-sonnet-4` |
| `NULLCLAW_PROVIDER` | Optional provider id, for example `openai`, `anthropic`, `groq`, `custom:https://api.example.com/v1`, or `anthropic-custom:https://api.example.com` |
| `NULLCLAW_BASE_URL` | Optional compatible-provider base URL; used when `NULLCLAW_PROVIDER` is omitted |
| `NULLCLAW_COMPAT` | Optional compatibility type for `NULLCLAW_BASE_URL`: `openai` (default) or `anthropic` |
| `NULLCLAW_API_KEY` | Optional generic provider credential for custom compatible providers |
| `NULLCLAW_MODEL` | Optional model name appended to `NULLCLAW_PROVIDER` or generated custom provider when `NULLCLAW_PRIMARY_MODEL` is omitted |
| `NULLCLAW_ALLOW_PUBLIC_BIND=true` | Optional; the image sets this automatically for Railway-style public binds |
| `NULLCLAW_GATEWAY_HOST` | Optional override, defaults to `0.0.0.0` |
| `NULLCLAW_GATEWAY_PORT` | Optional local fallback, defaults to `3000`; Railway uses `PORT` |
| `NULLCLAW_TELEGRAM_BOT_TOKEN` | Optional Telegram bot token; alias: `TELEGRAM_BOT_TOKEN` |
| `NULLCLAW_TELEGRAM_WEBHOOK_SECRET` | Optional Telegram webhook secret; alias: `TELEGRAM_WEBHOOK_SECRET` |
| `NULLCLAW_TELEGRAM_ALLOW_FROM` | Optional Telegram user allowlist as a JSON array, for example `["123456789"]`; alias: `TELEGRAM_ALLOW_FROM` |
| `NULLCLAW_TELEGRAM_GROUP_ALLOW_FROM` | Optional Telegram group sender allowlist as a JSON array; alias: `TELEGRAM_GROUP_ALLOW_FROM` |
| `NULLCLAW_TELEGRAM_REQUIRE_MENTION` | Optional Telegram group guard, `true` or `false`; alias: `TELEGRAM_REQUIRE_MENTION` |
| `NULLCLAW_TELEGRAM_GROUP_POLICY` | Optional Telegram group policy; alias: `TELEGRAM_GROUP_POLICY` |
| `NULLCLAW_TELEGRAM_ACCOUNT_ID` | Optional Telegram account id, defaults to `main`; alias: `TELEGRAM_ACCOUNT_ID` |
| `NULLCLAW_AUTONOMY_LEVEL` | Optional autonomy level, for example `supervised` or `full` |
| `NULLCLAW_ALLOWED_COMMANDS` | Optional shell command allowlist as a JSON array, for example `["grep","which","cat","sed","ls"]` |
| `NULLCLAW_ALLOWED_PATHS` | Optional path allowlist as a JSON array, for example `["/nullclaw-data"]` |
| `NULLCLAW_BLOCK_MEDIUM_RISK_COMMANDS` | Optional boolean for medium-risk shell commands |
| `NULLCLAW_REQUIRE_APPROVAL_FOR_MEDIUM_RISK` | Optional boolean for medium-risk approvals |

`PORT` is managed by Railway. Do not set it manually unless Railway asks you to.
When `NULLCLAW_PRIMARY_MODEL` is set, the entrypoint persists it to
`agents.defaults.model.primary` before starting the gateway.
For custom compatible providers, set `NULLCLAW_BASE_URL`, `NULLCLAW_API_KEY`,
`NULLCLAW_MODEL`, and optionally `NULLCLAW_COMPAT`; the entrypoint writes the
matching primary model reference while the runtime reads the API key from env.

### OpenAI-compatible endpoint

```text
NULLCLAW_COMPAT=openai
NULLCLAW_BASE_URL=https://api.example.com/v1
NULLCLAW_MODEL=qwen/qwen3-32b
NULLCLAW_API_KEY=sk-...
```

This becomes:

```text
custom:https://api.example.com/v1/qwen/qwen3-32b
```

### Anthropic-compatible endpoint

```text
NULLCLAW_COMPAT=anthropic
NULLCLAW_BASE_URL=https://anthropic-compatible.example.com
NULLCLAW_MODEL=claude-sonnet-4
NULLCLAW_API_KEY=sk-ant-...
```

This becomes:

```text
anthropic-custom:https://anthropic-compatible.example.com/claude-sonnet-4
```

You can also set the full ref directly:

```text
NULLCLAW_PRIMARY_MODEL=anthropic-custom:https://anthropic-compatible.example.com/claude-sonnet-4
NULLCLAW_API_KEY=sk-ant-...
```

## Telegram webhook

Railway runs the gateway, so Telegram should deliver updates to the gateway
webhook endpoint instead of using local long polling.

Set these Railway variables:

```text
NULLCLAW_TELEGRAM_BOT_TOKEN=123456:ABCDEF
NULLCLAW_TELEGRAM_WEBHOOK_SECRET=replace-with-random-long-secret
NULLCLAW_TELEGRAM_ALLOW_FROM=["123456789"]
NULLCLAW_TELEGRAM_REQUIRE_MENTION=true
```

`NULLCLAW_TELEGRAM_ALLOW_FROM` must be a JSON array. Use your numeric Telegram
user id, not the bot token. If this allowlist is empty, Telegram messages are
received but denied.
`NULLCLAW_TELEGRAM_WEBHOOK_SECRET` must be 16-128 printable characters with no
spaces. `NULLCLAW_TELEGRAM_REQUIRE_MENTION=true` keeps group chats quiet unless
the bot is mentioned or replied to; direct messages still work.

After Railway gives the service a public domain, register the webhook with
Telegram:

```bash
curl "https://api.telegram.org/bot$NULLCLAW_TELEGRAM_BOT_TOKEN/setWebhook" \
  -d "url=https://<your-service>.up.railway.app/telegram" \
  -d "secret_token=$NULLCLAW_TELEGRAM_WEBHOOK_SECRET"
```

For multiple bot accounts, set `NULLCLAW_TELEGRAM_ACCOUNT_ID` and register the
webhook URL with `?account_id=<id>`:

```bash
curl "https://api.telegram.org/bot$NULLCLAW_TELEGRAM_BOT_TOKEN/setWebhook" \
  -d "url=https://<your-service>.up.railway.app/telegram?account_id=main" \
  -d "secret_token=$NULLCLAW_TELEGRAM_WEBHOOK_SECRET"
```

## Agent shell permissions

If the agent needs to inspect and edit its own Railway volume config, start with
a narrow shell allowlist:

```text
NULLCLAW_AUTONOMY_LEVEL=full
NULLCLAW_ALLOWED_COMMANDS=["grep","which","cat","sed","ls","find","pwd"]
NULLCLAW_ALLOWED_PATHS=["/nullclaw-data"]
NULLCLAW_BLOCK_MEDIUM_RISK_COMMANDS=true
```

This allows basic inspection commands without opening every shell command. For
controlled private deployments only, you can widen it:

```text
NULLCLAW_ALLOWED_COMMANDS=["*"]
NULLCLAW_ALLOWED_PATHS=["/nullclaw-data"]
NULLCLAW_BLOCK_MEDIUM_RISK_COMMANDS=false
NULLCLAW_REQUIRE_APPROVAL_FOR_MEDIUM_RISK=false
```

Avoid `NULLCLAW_ALLOWED_PATHS=["*"]` on public bots unless you intentionally
want the agent to access the whole container filesystem.

## Persistent storage

Railway containers are ephemeral. Attach a Railway Volume to persist NullClaw
state across deploys and restarts.

Recommended volume mount path:

```text
/nullclaw-data
```

NullClaw stores `config.json`, workspace files, session history, and local memory
under that directory. If you mount the volume somewhere else, the entrypoint uses
Railway's `RAILWAY_VOLUME_MOUNT_PATH` runtime variable and points
`NULLCLAW_HOME`, `HOME`, and `NULLCLAW_WORKSPACE` at that volume automatically.
When the volume is empty, the entrypoint seeds a starter `config.json` before
the gateway starts.
The default Docker image runs as root so it can write to Railway's root-owned
volume mount without additional Railway variables.

## Deploy

1. Open Railway and choose **New Project**.
2. Choose **Deploy from GitHub repo**.
3. Select this repository.
4. Add a Railway Volume mounted at `/nullclaw-data`.
5. Add provider credentials in Railway variables.
6. Wait for `/health` to pass.

After deploy, use Railway's generated domain for gateway endpoints such as
`https://<your-service>.up.railway.app/health`.
