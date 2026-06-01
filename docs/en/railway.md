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
| `RAILWAY_RUN_UID=0` | Required when using a Railway Volume with this non-root image |
| `NULLCLAW_GATEWAY_HOST` | Optional override, defaults to `0.0.0.0` |
| `NULLCLAW_GATEWAY_PORT` | Optional local fallback, defaults to `3000`; Railway uses `PORT` |

`PORT` is managed by Railway. Do not set it manually unless Railway asks you to.

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

Railway mounts volumes as `root`. The default Docker image runs as UID `65534`,
so set this Railway service variable when a volume is attached:

```text
RAILWAY_RUN_UID=0
```

## Deploy

1. Open Railway and choose **New Project**.
2. Choose **Deploy from GitHub repo**.
3. Select this repository.
4. Add a Railway Volume mounted at `/nullclaw-data`.
5. Add provider credentials and `RAILWAY_RUN_UID=0` in Railway variables.
6. Wait for `/health` to pass.

After deploy, use Railway's generated domain for gateway endpoints such as
`https://<your-service>.up.railway.app/health`.
