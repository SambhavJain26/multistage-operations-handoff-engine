# Stage 1 Local Setup

This stage prepares the local runtime only. It does not create business workflows, fixture schema, the real board UI, SMS, PMS integration, or vendor automation.

## Local Services

- n8n: `http://localhost:5678`
- Postgres from host: `127.0.0.1:5432`
- Postgres from n8n: `postgres:5432`
- Board placeholder: `http://localhost:8080`

## First-Time Setup

1. Copy `.env.example` to `.env`.
2. Replace all `change-me` and placeholder values, including separate passwords for the local Postgres admin, n8n database user, and `make_ready_demo` application user.
3. Generate a durable `N8N_ENCRYPTION_KEY` before first n8n startup:

   ```powershell
   [guid]::NewGuid().ToString('N') + [guid]::NewGuid().ToString('N')
   ```

4. Start the stack:

   ```powershell
   docker compose up -d
   ```

5. Open n8n at `http://localhost:5678` and complete the owner account setup if prompted.

The local Compose file disables community packages and keeps the editor cookie compatible with local HTTP. Production auth and TLS are deferred to Stage 8.

Stop the stack with:

```powershell
docker compose down
```

Keep named volumes unless you deliberately want to wipe local n8n/Postgres state.

## Board Placeholder

Serve the placeholder board from the repo root:

```powershell
python -m http.server 8080 --directory board
```

Then open `http://localhost:8080`.

## n8n Credentials

Do not hardcode secrets in workflow JSON. The Postgres credential can be created locally by script; Telegram and OpenAI are still manual because they require external tokens.

### `Make-Ready Postgres`

- Host: `postgres`
- Port: `5432`
- Database: value of `MAKE_READY_DB`, default `make_ready_demo`
- User: value of `MAKE_READY_DB_USER`, default `make_ready_demo`
- Password: value of `MAKE_READY_DB_PASSWORD`
- SSL: disabled for local Docker

Verify with:

```sql
SELECT 1;
```

n8n itself uses a separate `n8n` database and role created during Postgres first boot. Do not reuse the n8n database credential for demo state.

Create or confirm this credential with:

```powershell
.\scripts\import-postgres-credential.ps1
```

### `Make-Ready OpenAI`

Use n8n's OpenAI API credential type:

- API key: `<OPENAI_API_KEY>`

The workflows still use HTTP Request nodes for model calls that need strict JSON schema control, exact model IDs, raw error handling, and fallback branches. The HTTP Request nodes should reference this OpenAI API credential through n8n's predefined credential authentication, rather than using the built-in OpenAI/LangChain action nodes for the workflow logic.

### Telegram Bot Credentials

Create two BotFather bots:

- Vendor bot: `<name>_vendor_bot`
- Manager bot: `<name>_manager_bot`

Store them as separate n8n Telegram credentials:

- `Make-Ready Vendor Telegram Bot`
- `Make-Ready Manager Telegram Bot`

Only one Telegram Trigger workflow may use each bot token.

## Cloudflare Tunnel For Telegram Testing

Cloudflare Tunnel is the Stage 1 default because `cloudflared` is installed locally.

Start a temporary tunnel to n8n:

```powershell
cloudflared tunnel --url http://localhost:5678
```

Copy the generated `https://...trycloudflare.com` URL. Set `WEBHOOK_URL` in `.env` to that exact HTTPS origin, then restart n8n:

```powershell
docker compose restart n8n
```

When Telegram Trigger workflows are active, production webhook URLs in n8n must show the tunnel origin, not `localhost`. If they show `localhost`, Telegram triggers will not fire.

After Telegram testing, restore:

```text
WEBHOOK_URL=http://localhost:5678
```

Then restart n8n again.

## OpenAI Model Verification

Run:

```powershell
$env:OPENAI_API_KEY = "<key>"
.\scripts\openai-model-check.ps1
```

The preferred defaults are:

- `OPENAI_MODEL_CLASSIFY=gpt-5.6-luna`
- `OPENAI_MODEL_DRAFT=gpt-5.6-luna`

If `gpt-5.6-luna` is unavailable, record the selected fallbacks in `.env` and `progress-notes.md`.

## Telegram Token Verification

Run:

```powershell
$env:TELEGRAM_VENDOR_BOT_TOKEN = "<vendor-token>"
$env:TELEGRAM_MANAGER_BOT_TOKEN = "<manager-token>"
.\scripts\telegram-getme-check.ps1
```

Record both bot usernames in `progress-notes.md`.

## Stage 1 Smoke Check

Run:

```powershell
.\scripts\check-stage-1.ps1
```

This checks Docker Compose, container status, n8n HTTP reachability, Postgres TCP reachability, and board placeholder reachability. It also reports whether manual credential environment variables are present.
