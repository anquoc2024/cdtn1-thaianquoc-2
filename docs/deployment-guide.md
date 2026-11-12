# Deployment Guide — Smart CRM (Mekong Mobile), flow L2

Warranty request intake and classification · Track SE · Tag **`v1.0`**
Author: Thái An Quốc (2374802012635) · Repository: https://github.com/anquoc2024/cdtn1-thaianquoc-2

The system runs as two containers started by Docker Compose:

| Service | What it is | Reachable from |
|---|---|---|
| `app` | Rails 8.1 web app + JSON API (Ruby 4.0.5, Puma, `RAILS_ENV=production`) | `http://localhost:3000` (port set by `APP_PORT`) |
| `db` | PostgreSQL 18 | Internal Compose network only — no host port is published |

No Ruby, Node.js or PostgreSQL installation is needed on the host.

## 1. Requirements

- Linux, macOS, or Windows 10/11 with WSL 2. Tested on Windows + WSL 2 (Ubuntu) with Docker Engine installed inside Ubuntu.
- Docker Engine 25+ (the healthchecks use `start_interval`) with the Docker Compose plugin v2.20+.
  Check: `docker version --format '{{.Server.Version}}'` and `docker compose version`.
- Git 2.30+. Check: `git --version`.
- About 3 GB of free disk space (base images, build cache, database volume).
- Port **3000** free on the host (or choose another port with `APP_PORT`, see section 3).
- Internet access for the first build (downloads `ruby:4.0.5-slim`, `postgres:18` and Ruby gems).

## 2. Setup steps

Run each command from an empty folder, in this order.

1. Clone the release tag:
   ```bash
   git clone --branch v1.0 https://github.com/anquoc2024/cdtn1-thaianquoc-2.git && cd cdtn1-thaianquoc-2
   ```
2. Create the environment file from the template (the sample values work as-is on a test machine):
   ```bash
   cp .env.example .env
   ```
3. Build and start everything:
   ```bash
   docker compose up -d --build
   ```
   The first run takes about 5–10 minutes depending on network speed (measured: 2 min 12 s when the
   two base images were already downloaded). On the first start the app container automatically
   creates the databases, loads the schema and loads the sample data — there is no extra command
   to run. Wait about 30 seconds after the command returns, then go to section 5.

To stop: `docker compose down` (data is kept). To reset to a clean state: `docker compose down -v`
(deletes the database volume; the next `up` loads the sample data again).

## 3. Environment variables

Defined in `.env` (copied from `.env.example`). `.env` is listed in `.gitignore` and must never be committed.
**Change every value before a real deployment.**

| Name | Meaning | Sample value | Required |
|---|---|---|---|
| `APP_PORT` | Host port that serves the app | `3000` | No (default `3000`) |
| `DB_NAME` | Main database name; Rails also creates `DB_NAME_cache`, `DB_NAME_queue`, `DB_NAME_cable` | `smartcrm` | Yes |
| `DB_USER` | PostgreSQL user, created by the `db` container on first start | `smartcrm` | Yes |
| `DB_PASSWORD` | Password of `DB_USER` | `doi-mat-khau-nay` | Yes |
| `SECRET_KEY_BASE` | Key that signs session cookies. Generate a real one with `openssl rand -hex 64` | placeholder in `.env.example` | Yes |
| `RAILS_MAX_THREADS` | Puma threads = max database connections per process | `5` | No (default `5`) |
| `RAILS_LOG_LEVEL` | Log level: `debug`, `info`, `warn`, `error` | `info` | No (default `info`) |

Set by `docker-compose.yml`, not by `.env`: `RAILS_ENV=production` and `DB_HOST=db` (the service name).

## 4. Sample data

Loaded **automatically** on the first start, while the database volume is still empty:
`bin/docker-entrypoint` runs `bin/rails db:prepare`, which creates the databases, loads the schema
and runs `db/seeds.rb`. The seed reads the CSV files in `data/mau/` (copied into the image at `/data/mau`).
Later restarts only apply pending migrations and do not load the data again.
To load the sample data **again on purpose** (re-run test — it must not create duplicates):
`docker compose exec app bin/rails import:l2` → every count is "mới 0" (0 new) and the totals stay the same
(see step 7 in section 5).

Expected records after loading:

| Data | Count | Source |
|---|---|---|
| Users (demo accounts) | 2 | `db/seeds.rb` |
| Priorities (SLA 72 h / 48 h / 24 h / 8 h) | 4 | `db/seeds.rb` |
| Issue categories | 6 | `data/mau/issue_categories.csv` |
| Customers | 310 | 279 from `customers_mau.csv` (first 300 rows: 1 duplicate phone merged, 20 invalid rows rejected) + 31 from `customers.csv` |
| Devices | 31 | `data/mau/devices.csv` |
| Warranty requests | 30 (18 overdue right after loading; the number grows as time passes) | `data/mau/tickets.csv` (7 invalid rows in the L2 files rejected) |

Demo accounts (sample data, not real secrets — passwords are stored as bcrypt hashes):

| Email | Password | Role |
|---|---|---|
| `quoc@mekong.vn` | `Mekong@2026` | Receptionist (Nhân viên tiếp nhận) |
| `phu@mekong.vn` | `Mekong@2026` | Service centre manager (Quản lý trung tâm) |

## 5. Verify it works

| # | Command / action | Expected result |
|---|---|---|
| 1 | `docker compose ps` | `smartcrm-l2-app-1` and `smartcrm-l2-db-1` both `Up … (healthy)`; the `db` PORTS column shows only `5432/tcp` (not published) |
| 2 | `curl http://localhost:3000/api/health` | `{"status":"ok","db":"ok"}` |
| 3 | `docker compose exec app bin/rails runner 'puts "users=#{User.count} customers=#{Customer.count} devices=#{Device.count} requests=#{WarrantyRequest.count}"'` | `users=2 customers=310 devices=31 requests=30` |
| 4 | `curl -s -X POST http://localhost:3000/api/session -H "Content-Type: application/json" -d '{"email_address":"quoc@mekong.vn","password":"Mekong@2026"}'` | HTTP 200, JSON with `"token"`, `"role":"receptionist"` and the permission list |
| 5 | Open `http://localhost:3000`, sign in as `quoc@mekong.vn` | Redirected to **Tra cứu khách hàng**; searching `0843145885` shows customer **Bùi Tuấn Huy, KH-114121** |
| 6 | `docker compose exec -e RAILS_ENV=test app bin/rails db:test:prepare test` | `131 runs, 591 assertions, 0 failures, 0 errors, 0 skips` |
| 7 | `docker compose exec app bin/rails import:l2`, then the command of step 3 again | `Bộ dữ liệu L2: nhóm sự cố mới 0 (đã có 6) · khách hàng mới 0 (đã có 31) · thiết bị mới 0 (đã có 31) · yêu cầu mới 0 (đã có 30) · loại 7 dòng`; step 3 still prints `users=2 customers=310 devices=31 requests=30` |

Step 6 runs the whole automated test suite inside the container against a separate test database;
it does not touch the sample data. Step 7 loads the sample data a second time to show that loading is repeatable without duplicates.

## Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `env file …/.env not found` | Step 2 was skipped | `cp .env.example .env`, then `docker compose up -d --build` |
| `Bind for 0.0.0.0:3000 failed: port is already allocated` | Another program uses port 3000 | Set `APP_PORT=3001` in `.env`, run `docker compose up -d`, open `http://localhost:3001` |
| `app` stays `starting` / `unhealthy`, or exits | Error during start-up | `docker compose logs app --tail 50` (every request line carries a request id) |
| `password authentication failed` or `role … does not exist` after editing `DB_USER` / `DB_PASSWORD` | The database volume was created with the old values | `docker compose down -v`, then `docker compose up -d` (sample data is reloaded) |
| Pages show old data or no data | Volume from an earlier run | `docker compose down -v`, then `docker compose up -d` |
| `permission denied … /var/run/docker.sock` (Linux / WSL) | User is not in the `docker` group | `sudo usermod -aG docker $USER`, then open a new terminal |
| `docker: command not found` in WSL | Docker is not available in the WSL distro | Enable WSL integration in Docker Desktop, or install Docker Engine inside the distro |
| `app` exits with `/bin/bash: -: invalid option` | Scripts were checked out with Windows line endings (CRLF) by a Git client that ignores `.gitattributes` | Clone again with `git clone --config core.autocrlf=false --branch v1.0 …` (the repo's `.gitattributes` forces LF since BUG-09) |

## 6. Trial deployment on Render (optional)

A public copy of the same Docker image runs at **https://smartcrm-app.onrender.com**, on Render's free plan.
It is only for viewing; the reference way to run the system is sections 2–5 above.

| Item | Setting |
|---|---|
| Platform | Render (render.com) · region Singapore · Free plan |
| Database | Render Postgres 18 `smartcrm-db` (database `smartcrm`, user `smartcrm`) |
| Web service | `smartcrm-app` · language Docker · branch `main` · root directory empty · Dockerfile path `./Dockerfile` (the same image as section 2) |
| Health check path | `/api/health` |

Steps taken:

1. Render dashboard → **New → Postgres**: name `smartcrm-db`, database `smartcrm`, user `smartcrm`, PostgreSQL 18, region Singapore, plan Free. Wait for **Available**, then copy the internal hostname and the password from **Connections**.
2. Generate the session key on the local machine: `openssl rand -hex 64`.
3. **New → Web Service** → connect the GitHub repository `anquoc2024/cdtn1-thaianquoc-2`: language Docker, branch `main`, region Singapore, instance type Free.
4. In **Environment**, add the variables in the table below; in **Advanced**, set Health Check Path to `/api/health`; click **Deploy Web Service**.
5. The first deploy builds the image (5–10 minutes). `bin/docker-entrypoint` runs `bin/rails db:prepare`, which creates `smartcrm` plus `smartcrm_cache`, `smartcrm_queue` and `smartcrm_cable`, and loads the sample data. The log ends with `Listening on http://0.0.0.0:3000` and the service turns **Live**.
6. Check: `curl -s https://smartcrm-app.onrender.com/api/health` → `{"status":"ok","db":"ok"}`; sign in with a demo account from section 4; searching `0843145885` shows **Bùi Tuấn Huy, KH-114121**.

| Variable | Value on Render |
|---|---|
| `DB_HOST` | Internal hostname of `smartcrm-db` (`dpg-…-a`) |
| `DB_NAME` | `smartcrm` |
| `DB_USER` | `smartcrm` |
| `DB_PASSWORD` | Password of `smartcrm-db` (secret) |
| `SECRET_KEY_BASE` | Output of `openssl rand -hex 64` (secret) |
| `PORT` | `3000` — Puma listens on port 3000 (see `Dockerfile`) |
| `RAILS_MAX_THREADS` | `3` — lower than the local default to fit the memory of the free instance |
| `RAILS_LOG_LEVEL` | `info` |

`RAILS_ENV=production` comes from the `Dockerfile`. The two secrets are entered only in Render's Environment tab and are not in the repository.

Notes:

- The service uses separate `DB_*` variables, as in `docker-compose.yml`, so that `db:prepare` creates the cache, queue and cable databases with their own schemas. Pointing all four connections to one database leaves out the Solid Cache table, and sign-in (rate-limited through Solid Cache) then fails with 500.
- On the free plan the web service sleeps when it receives no traffic for a while; the first request after that can take about a minute.
- A free Render Postgres database expires 30 days after it is created. If it expires, create a new one, update `DB_HOST` and `DB_PASSWORD`, and redeploy — `db:prepare` loads the sample data again.
