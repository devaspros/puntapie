# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

**Puntapie is a Rails app template generator**, not a standard Rails application. The primary artifact is `template.rb`, which uses Thor to generate new Rails 7.2.x apps pre-configured with the full stack below. The files in `app/`, `config/`, `spec/`, etc. are the template source files that get copied into generated apps.

To use the template:
```bash
rails new my_app -d sqlite3 --skip-test --skip-active-storage --skip-action-mailbox --skip-action-text -m template.rb
# or from GitHub:
rails new my_app -d sqlite3 --skip-test --skip-active-storage --skip-action-mailbox --skip-action-text -m https://raw.githubusercontent.com/.../template.rb
```

## Development Commands

```bash
# Install dependencies
bundle install

# Database setup
bundle exec rails db:prepare  # Creates primary, queue and cable DBs and loads their schemas
bundle exec rails setup:run  # Creates default org, roles, users

# Start the app (uses Procfile.dev via .foreman)
foreman start  # Runs web on port 3009 + Solid Queue (bin/jobs)

# Run tests
bundle exec rspec
bundle exec rspec spec/requests/api/v1/users/sessions_spec.rb  # single file

# Lint
bundle exec rubocop
```

## Architecture

### Multi-Tenancy
The app uses an Organization-based multi-tenant model:
- `Organization` → `Membership` (join table) → `User` + `Role`
- Users track `current_organization_id` for active tenant context
- Three roles: `admin`, `member`, `viewer` (seeded via `lib/tasks/`)

### Dual Authentication
- **Web UI**: Devise session cookies — controllers inherit from `ApplicationController`
- **API**: JWT tokens (7-day expiry) — API controllers inherit from `Api::BaseApiController`
  - JWT issuer is set to `"CHANGE-ME"` in `app/lib/json_web_token.rb` — must be updated per deployment

### API Structure
- Namespaced under `/api/v1/`
- `Api::BaseApiController` handles JWT authentication and includes `ApiExceptionHandler` concern
- Responses are always JSON

### Authorization
Pundit policies in `app/policies/`. `ApplicationController` includes Pundit.

### Background Jobs
Solid Queue (no Redis). `template.rb` runs the `solid_queue:install`, `solid_cache:install` and `solid_cable:install` generators, then overrides `config/cache.yml` and `config/cable.yml` with the files in this repo.
- Jobs run with `bin/jobs --mode async` (`Procfile.dev` locally, `scripts/puntapie.jobs.service` on the VPS)
- Mission Control at `/jobs`, admins only (`http_basic_auth_enabled = false`, Devise handles auth)
- Solid Cache is the production `cache_store`; development uses `memory_store` via `rails dev:cache`
- Solid Cable is the Action Cable adapter in development and production

### SQLite in Production
The app intentionally uses SQLite (not PostgreSQL) with WAL mode for concurrency. Configured in `config/database.yml` with pragmas: `journal_mode: WAL`, `synchronous: NORMAL`, `mmap_size: 128MB`, and `timeout: 5000` to wait for the write lock. Rails 7.2 no longer warns about SQLite in production, so no setting is needed.

`config/database.yml` is multi-database: `primary`, `queue` and `cable` in development; `primary`, `cache`, `queue` and `cable` in production; a single DB in test. The solid_* DBs have no migrations, only `db/*_schema.rb`, so use `db:prepare` (the deploy script does) instead of `db:migrate` to create them.

`config/initializers/sqlite3_busy_handler_timeout.rb` backports Rails 8 behavior: it applies `timeout` with `busy_handler_timeout` (releases the GVL) instead of `busy_timeout` (holds it, so other Puma threads freeze while waiting). Delete it when upgrading to Rails 8.

### JavaScript
Uses importmap-rails (no Node/Webpack/Vite). Hotwire stack: Turbo + Stimulus. Bootstrap 5.3 pinned in `config/importmap.rb`.

## Locale
The app is configured for Colombian Spanish (`es-CO`). Devise views and locale files are in Spanish. Generated READMEs are in Spanish.

- View texts live in `config/locales/views.es.yml` (Devise views use lazy lookups, e.g. `t(".title")` → `es.devise.sessions.new.title`); model and attribute names in `config/locales/models.es.yml`.
- `template.rb` only copies the locale files listed in `set_locales`, so every new YAML file needs its own `copy_file` there.
- Password minimum is 10 characters (`config.password_length = 10..128`, set by `add_users`). Password fields use the `password-visibility` Stimulus controller and the `devise/shared/_password_toggle` partial.

## Seeded Data (via `setup:run`)
- Organization: "DevAsPros" (slug: "dap")
- Test user: frajaquico@aol.com with admin role

## Deployment
SSH-based VPS deployment via scripts in `scripts/`. GitHub Actions runs tests then triggers `scripts/001_deploy_api.sh` via SSH on push to `main`. Notifications via ntfy.sh.

## RuboCop Config
130-character line length, double-quoted strings enforced. See `.rubocop.yml` for full config.
