# Deployment

Containerised stack: **Caddy TLS proxy → React web admin (nginx) + Spring Boot API → SQL Server**,
wired by [docker-compose.yml](docker-compose.yml). Secrets are read from the environment (`.env`),
never committed.

## Quick start (Docker)

```bash
cp .env.example .env          # then edit: set a strong DB_PASSWORD and a 32+ byte JWT_SECRET
docker compose up --build     # builds all images and starts the stack
```

Then browse **https://localhost** (the admin SPA). With the default self-signed cert the browser warns
once — accept it, or trust Caddy's local CA (see **HTTPS / TLS** below).

Services:

| Service   | Port     | Notes |
|-----------|----------|-------|
| `proxy`   | 80, 443  | Caddy edge — terminates TLS, redirects 80→443, routes `/api/*` → `backend`, else → `web` |
| `web`     | internal | React admin behind nginx; the SPA uses relative `/api/v1` URLs (same-origin) |
| `backend` | internal | Spring Boot API (`SPRING_PROFILES_ACTIVE=prod`); health at `/actuator/health` |
| `db`      | 1433     | SQL Server 2022 (Developer); `db-init` creates `khoga_coffee_shop` on first boot |

The backend seeds the super-admin **`ssadmin` / `Admin@123`** on first run (non-prod seeder). To
disable seeding in a real prod environment, run with the `prod` profile only and remove the seeder
data path as needed.

## Configuration (environment variables)

All secrets/config are externalised (defaults in [application.properties](backend/src/main/resources/application.properties)
are dev-only). Override in `.env` / the environment — see [.env.example](.env.example):

- `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` — datasource
- `JWT_SECRET` (≥32 bytes), `JWT_EXP_HQ_MINUTES`, `JWT_EXP_BRANCH_MINUTES`
- `COOKIE_SECURE` — `true` behind the TLS proxy (default); `false` only for plain-HTTP staging
- `CORS_ALLOWED_ORIGINS` — comma-separated FE origins (SPA + API are same-origin via the proxy)
- `SITE_ADDRESS`, `ACME_EMAIL` — TLS proxy hostname + cert mode (self-signed vs Let's Encrypt); see below
- `JPA_DDL_AUTO` — prod defaults to `validate` (Flyway owns the schema; see below); dev/test use `update`
- `MAIL_*`, `VIETQR_*` — integration credentials

The `prod` profile ([application-prod.properties](backend/src/main/resources/application-prod.properties))
enables template caching, a Secure cookie by default, disables open-in-view/SQL logging, and exposes
only `/actuator/health` + `/actuator/info`.

## Database migrations (Flyway)

Prod is **Flyway-managed**. On startup Flyway runs the versioned SQL in
[backend/src/main/resources/db/migration](backend/src/main/resources/db/migration) **before** Hibernate,
which then only **validates** the schema (`JPA_DDL_AUTO=validate`) — it never mutates it.

- **Fresh DB** → Flyway applies `V1__baseline_schema.sql` (and any later `V2+`).
- **Existing DB** built earlier by `ddl-auto` → `spring.flyway.baseline-on-migrate=true` marks it at V1
  (skips V1) and applies only `V2+`.
- **Dev/test** keep `spring.flyway.enabled=false` + `ddl-auto=update`, so the local workflow and the
  test suite are unchanged.

`V1` was generated from the live Hibernate metadata (SQL Server dialect) so it reproduces the exact
entity-driven schema; it was verified by running Flyway into a clean DB and confirming Hibernate
`validate` passes. **Never edit an applied migration** — evolve the schema with a new `V2__*.sql`.

## HTTPS / TLS (Caddy)

The `proxy` service ([Caddyfile](Caddyfile)) is the single TLS entry point: it terminates HTTPS on
`443`, redirects `80` → `443`, routes `/api/*` to `backend` and everything else to the `web` SPA. `web`
and `backend` no longer publish host ports — they're reachable only through the proxy. The backend runs
with `server.forward-headers-strategy=framework`, so it sees the real `https` scheme via `X-Forwarded-*`.

- **Local / staging (default):** `SITE_ADDRESS=localhost`, `ACME_EMAIL=internal` → Caddy issues a
  self-signed cert from its own CA. HTTPS works immediately and offline; the browser shows a one-time
  untrusted-CA warning. To remove it, trust Caddy's root CA — copy it out with
  `docker compose cp proxy:/data/caddy/pki/authorities/local/root.crt ./caddy-root.crt` and add it to
  your OS/browser trust store.
- **Production:** point DNS at the host, then set `SITE_ADDRESS=your.domain` and
  `ACME_EMAIL=you@example.com` in `.env`. Caddy fetches and auto-renews a real Let's Encrypt cert; the
  cert state persists in the `caddy-data` volume.
- Need to reach a service directly while debugging? Re-add a `ports:` mapping to `web`/`backend` in
  [docker-compose.yml](docker-compose.yml).

## Building images individually

```bash
docker build -t khoga-backend ./backend
docker build -t khoga-web ./khoga_web_admin
```

## Android release (Flutter POS app)

The POS app ([khoga_pos_app](khoga_pos_app)) signs **release** builds with a real upload key instead of
the debug key. Signing is driven by `android/key.properties` (git-ignored); if it's missing, the release
build falls back to debug signing so `flutter run --release` still works locally.

One-time setup:

1. Generate an upload keystore — keep the `.jks` and passwords secret, never commit them:
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -storetype JKS \
           -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```
   Move `upload-keystore.jks` into `khoga_pos_app/android/app/`.
2. Copy [android/key.properties.example](khoga_pos_app/android/key.properties.example) →
   `khoga_pos_app/android/key.properties` and fill in the alias + passwords + `storeFile`.

Build the signed artifacts:
```bash
cd khoga_pos_app
flutter build appbundle   # → build/app/outputs/bundle/release/app-release.aab  (Play Store)
flutter build apk         # → build/app/outputs/flutter-apk/app-release.apk      (direct install)
```

For a store/CI pipeline, inject `key.properties` + the `.jks` from secrets at build time (e.g.
base64-decode the keystore and write `key.properties`) instead of storing them in the repo.

## Deploy hardening — status

All the initially-tracked hardening items are done:

- **DB migrations** — Flyway manages the prod schema (`validate`); see above.
- **HTTPS/TLS** — Caddy edge proxy terminates TLS (self-signed by default, Let's Encrypt for a domain); see above.
- **CI** — SQL-Server-backed integration test + Flyway drift guard, and Docker image build/push.
- **Android release** — Flutter POS app signs release builds with a real upload key; see above.
