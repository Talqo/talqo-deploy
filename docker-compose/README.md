# Talqo on Docker Compose

Talqo, Postgres, and Docling in one Compose project.

## Start

```sh
cp .env.example .env
```

Change `APP_SECRET` and `POSTGRES_PASSWORD` in `.env` first, then:

```sh
docker compose up -d
```

Talqo applies its own database migrations on start, so there is no separate step. The dashboard is on <http://127.0.0.1:3000>.

To stop:

```sh
docker compose stop
```

## Configuration

All settings live in `.env`. `TALQO_VERSION` pins the image tag, `TALQO_PORT` is the host port, and the two secrets are passed to the app and Postgres.

`APP_SECRET` encrypts the AI provider API keys you enter in the dashboard with AES-256-GCM. Talqo will not start until you replace the placeholder, because it must be base64url and at least 32 bytes decoded.

**Back up `APP_SECRET` somewhere safe.** It cannot be recovered from the database. If you lose it, every stored provider key is permanently unreadable and you have to enter new ones. Changing it has the same effect. Sessions keep working across a change, but rate limit counters reset.

The port binds to loopback only, so you need a reverse proxy on the same host to reach Talqo from another machine. Set `host_ip` in `compose.yaml` to change that, and do not expose it to the internet without terminating TLS in front.

## Upgrades

Change `TALQO_VERSION`, then:

```sh
docker compose pull
docker compose up -d
```

Migrations run on start and are not reversible. Take a database dump before a major version bump.

## Gotchas

- **Never `docker compose down -v`.** That deletes both named volumes: Postgres data and uploaded files. Remove the app and Postgres volumes by name if you must.
- **Talqo will not start on the placeholder `APP_SECRET`.** That is intentional. It fails with `APP_SECRET must decode to at least 32 bytes`. Generate a real one.
- **`APP_SECRET` must be base64url.** Standard base64 with `+`, `/`, or `=` padding fails the boot check.
- **Docling is CPU-only and loads models on first use.** The first document upload is slow while it warms up.
