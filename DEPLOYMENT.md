# Deployment

Containerised stack: **SQL Server + Spring Boot API + React web admin (nginx)**, wired by
[docker-compose.yml](docker-compose.yml). Secrets are read from the environment (`.env`), never
committed.

## Quick start (Docker)

```bash
cp .env.example .env          # then edit: set a strong DB_PASSWORD and a 32+ byte JWT_SECRET
docker compose up --build     # builds all images and starts the stack
```

Services:

| Service   | Port  | Notes |
|-----------|-------|-------|
| `web`     | 8081  | React admin behind nginx; proxies `/api` → `backend:8080` |
| `backend` | 8080  | Spring Boot API (`SPRING_PROFILES_ACTIVE=prod`); health at `/actuator/health` |
| `db`      | 1433  | SQL Server 2022 (Developer); `db-init` creates `khoga_coffee_shop` on first boot |

The backend seeds the super-admin **`ssadmin` / `Admin@123`** on first run (non-prod seeder). To
disable seeding in a real prod environment, run with the `prod` profile only and remove the seeder
data path as needed.

## Configuration (environment variables)

All secrets/config are externalised (defaults in [application.properties](backend/src/main/resources/application.properties)
are dev-only). Override in `.env` / the environment — see [.env.example](.env.example):

- `DB_URL`, `DB_USERNAME`, `DB_PASSWORD` — datasource
- `JWT_SECRET` (≥32 bytes), `JWT_EXP_HQ_MINUTES`, `JWT_EXP_BRANCH_MINUTES`
- `COOKIE_SECURE` — set `true` behind HTTPS
- `CORS_ALLOWED_ORIGINS` — comma-separated FE origins
- `JPA_DDL_AUTO` — `update` (entity-driven) today; switch to `validate` once Flyway lands
- `MAIL_*`, `VIETQR_*` — integration credentials

The `prod` profile ([application-prod.properties](backend/src/main/resources/application-prod.properties))
enables template caching, a Secure cookie by default, disables open-in-view/SQL logging, and exposes
only `/actuator/health` + `/actuator/info`.

## Building images individually

```bash
docker build -t khoga-backend ./backend
docker build -t khoga-web ./khoga_web_admin
```

## Still open (tracked, not blocking a first deploy)

- **DB migrations**: schema is entity-driven (`ddl-auto`); adopt Flyway before running `validate` in prod.
- **HTTPS/TLS**: terminate at a reverse proxy / load balancer in front of `web` + `backend`.
- **CI deploy**: `.github/workflows/ci.yml` builds + unit-tests only; add image build/push + the
  SQL-Server-backed integration test.
- **Flutter release**: Android currently signs with debug keys; add a release keystore + store pipeline.
