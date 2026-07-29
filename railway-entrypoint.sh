#!/bin/sh
# Railway entrypoint for Twenty CRM.
#
# Two roles run from this one image, told apart by the start command:
#
#   node dist/main    -> the API/UI server. Upstream's entrypoint initialises the
#                        schema on a first boot and runs upgrade migrations on
#                        every boot after that, then registers the cron jobs.
#
#   yarn worker:prod  -> the background worker. It must NOT run migrations or
#                        register cron jobs -- the server already does both, and
#                        two processes racing the same migration corrupts the
#                        upgrade. Upstream's docker-compose sets
#                        DISABLE_DB_MIGRATIONS/DISABLE_CRON_JOBS_REGISTRATION on
#                        the worker for exactly this reason; we set them here so
#                        the template does not have to ship them as variables
#                        (a literal-valued template variable publishes blank).
#
# The worker also waits for the server to create the `core` schema. On Railway
# the two services boot in parallel, so without the wait the worker crash-loops
# against tables that do not exist yet.
set -e

case " $* " in
    *worker*)
        export DISABLE_DB_MIGRATIONS=true
        export DISABLE_CRON_JOBS_REGISTRATION=true

        if [ -n "${PG_DATABASE_URL}" ]; then
            echo "[railway] worker: waiting for the server to initialise the schema"
            tries=0
            while [ "$(psql -tAc "SELECT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'core')" "${PG_DATABASE_URL}" 2>/dev/null)" != "t" ]; do
                tries=$((tries + 1))
                if [ "${tries}" -gt 150 ]; then
                    echo "[railway] worker: schema still missing after 10 minutes, starting anyway" >&2
                    break
                fi
                sleep 4
            done
            echo "[railway] worker: schema is ready"
        fi
        ;;
esac

exec /app/entrypoint.sh "$@"
