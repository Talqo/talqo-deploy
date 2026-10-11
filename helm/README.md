# Talqo on Kubernetes (Helm)

Talqo, Postgres with pgvector (Bitnami subchart), and Docling as one chart.
Mirrors `docker-compose/` defaults.

Subchart tarballs are gitignored; fetch once after cloning:

```sh
helm dependency update ./helm
```

## Install

```sh
PGPASSWORD="$(openssl rand -base64 24 | tr -d '/+=')" && \
PGSUPER="$(openssl rand -base64 24 | tr -d '/+=')" && \
kubectl create namespace talqo && \
kubectl create secret generic talqo -n talqo \
  --from-literal=APP_SECRET="$(openssl rand -base64 32 | tr '+/' '-_' | tr -d '=')" \
  --from-literal=DATABASE_URL="postgres://talqo:${PGPASSWORD}@talqo-postgresql:5432/talqo" && \
helm install talqo ./helm -n talqo \
  --set existingSecret=talqo \
  --set postgresql.auth.password="$PGPASSWORD" \
  --set postgresql.auth.postgresPassword="$PGSUPER" \
  --set image.tag='1.2.3'
```

Only variable references land in shell history, never the values.
`auth.password` must match the password in `DATABASE_URL`. The superuser
password seeds the pgvector extension at first boot; the app connects as
the least-privilege user.

Back up `APP_SECRET` (base64url, 32+ bytes) and the postgres password;
both are effectively immutable after first start.

## Configuration

Everything is in `helm/values.yaml`. Notable overrides:

- `image.tag` pins `ghcr.io/talqo/talqo`; pin a release tag in production.
- `postgresql.*` is the Bitnami subchart (18.6.0, native value names).
  `auth.password` is the app password (must match `DATABASE_URL`);
  `auth.postgresPassword` seeds pgvector at first boot. For zero passwords
  in values, put `password` + `postgres-password` keys in the pre-created
  Secret and set `postgresql.auth.existingSecret` to the same name.
- `postgresql.enabled=false` + `externalDatabase.url` uses managed Postgres
  (the URL must include pgvector).
- `docling.enabled=false` + `docling.externalUrl` uses external Docling Serve.
- `persistence.uploads.existingClaim` reuses an uploads volume; it must be
  ReadWriteMany if `replicaCount` is above 1.
- `config.*` maps to the `TALQO_*` policy vars from the deployment docs;
  null means the app default.

## Exposing Talqo

Serve at the domain root with TLS in front. SSE requires no response
buffering and a read timeout above the generation timeout (120s default).

nginx values example:

```yaml
ingress:
  enabled: true
  className: nginx
  host: talqo.example.com
  tls:
    - secretName: talqo-tls
      hosts: [talqo.example.com]
  annotations:
    nginx.ingress.kubernetes.io/proxy-buffering: "off"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "300"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "300"
config:
  trustedProxyCidrs: 10.0.0.0/8
```

`trustedProxyCidrs` should cover the ingress controller networks so rate
limiting sees visitor addresses.

## Upgrades

Migrations run on start and are not reversible. Back up the database, then:

```sh
helm upgrade talqo ./helm -n talqo --reuse-values --set image.tag='1.2.4'
```

## Gotchas

- Changing `APP_SECRET` or the postgres password locks stored data.
- Do not delete the PVCs; they hold the database and uploaded files.
- First upload is slow while Docling loads models.
- Bundled Postgres is single-replica; use `externalDatabase.url` for HA.
