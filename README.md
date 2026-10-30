# twenty-railway

[![Deploy on Railway](https://railway.com/button.svg)](https://railway.com/deploy/twenty-crm-or-salesforce-alternative-ver?referralCode=Z1xivh&utm_medium=integration&utm_source=template&utm_campaign=generic)

**Deploy on Railway:** [Twenty CRM template](https://railway.com/deploy/twenty-crm-or-salesforce-alternative-ver?referralCode=Z1xivh&utm_medium=integration&utm_source=template&utm_campaign=generic)

Railway-tuned [Twenty CRM](https://twenty.com) image — `ghcr.io/bon5co/twenty-railway`.

Thin wrapper over `twentycrm/twenty:v2.25.1`. It changes nothing about the
application; it only bakes in the settings a Railway deployer would otherwise be
asked to type, and teaches one image to run both the server and the worker role.

## What it adds

| | |
|---|---|
| **Pinned upstream** | `twentycrm/twenty:v2.25.1`, not `latest`. Server and worker therefore always run the same version — on Railway each service redeploys independently, so `latest` lets one of them drift onto a newer build against a database the other has not migrated for. |
| **Role detection** | The start command decides the role. `yarn worker:prod` sets `DISABLE_DB_MIGRATIONS=true` and `DISABLE_CRON_JOBS_REGISTRATION=true`, matching upstream's `docker-compose.yml`, so the worker never races the server's migration. |
| **Worker waits for the schema** | The worker blocks until the server has created the `core` schema instead of crash-looping against tables that do not exist yet. |
| **`NODE_PORT=8080`** | Twenty listens on Railway's injected `$PORT` instead of its own default 3000. |
| **`ENABLE_ALPINE_PRIVATE_NETWORKING=true`** | The upstream image is Alpine-based; Railway's private network needs this to resolve `*.railway.internal`. |
| **S3 storage defaults** | `STORAGE_TYPE=S_3`, bucket `twenty`, region `us-east-1`. Server and worker must share file storage — a Railway volume cannot be mounted into two services, so local storage would leave attachments written by one process invisible to the other. |
| **Code execution off** | `LOGIC_FUNCTION_TYPE=DISABLED` and `CODE_INTERPRETER_TYPE=DISABLED` set explicitly. These are already the upstream defaults when `NODE_ENV=production`; pinning them means a future change to that default cannot quietly turn unsandboxed in-container code execution on. |

## Why bake anything at all

Railway's `templateGenerate` keeps a template variable's `defaultValue` only when
the live value is a Railway *expression* (`${{secret(32)}}`,
`${{RAILWAY_PUBLIC_DOMAIN}}`, `${{svc.VAR}}`). Literals are dropped, and the
variable publishes as **required with no value** — so the deploy form opens
asking the user for settings the image already knows.

Everything left on the template is therefore an expression, and the published
deploy form asks for nothing.

## What the template still supplies

Set by the Railway template, not here, because they are per-deployment:

- `PG_DATABASE_URL`, `REDIS_URL` — the stack's own Postgres and Redis
- `SERVER_URL` — `https://${{RAILWAY_PUBLIC_DOMAIN}}`
- `APP_SECRET`, `ENCRYPTION_KEY` — generated per deploy via `${{secret(32)}}`
- `STORAGE_S3_ENDPOINT`, `STORAGE_S3_ACCESS_KEY_ID`, `STORAGE_S3_SECRET_ACCESS_KEY` — the stack's own MinIO

`ENCRYPTION_KEY` is worth calling out: since v2.5 Twenty encrypts at-rest secrets
(OAuth tokens, TOTP secrets, sensitive config) under it, and falls back to
`APP_SECRET` when it is unset. Upstream's guidance is that new installs should
always set a dedicated key, so this template does.

## Building

GitHub Actions builds and pushes `ghcr.io/bon5co/twenty-railway:latest` on every
push to `main`, and weekly so the wrapper picks up base-image patches.

## Upstream

- Twenty: https://github.com/twentyhq/twenty
- Self-hosting docs: https://docs.twenty.com/developers/self-hosting/setup
