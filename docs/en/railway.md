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
| `NULLCLAW_GATEWAY_HOST` | Optional override, defaults to `0.0.0.0` |
| `NULLCLAW_GATEWAY_PORT` | Optional local fallback, defaults to `3000`; Railway uses `PORT` |

`PORT` is managed by Railway. Do not set it manually unless Railway asks you to.

## Deploy

1. Open Railway and choose **New Project**.
2. Choose **Deploy from GitHub repo**.
3. Select this repository.
4. Add provider credentials in Railway variables.
5. Wait for `/health` to pass.

After deploy, use Railway's generated domain for gateway endpoints such as
`https://<your-service>.up.railway.app/health`.
