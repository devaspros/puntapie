# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

**Puntapie is a Rails app template generator**, not a standard Rails application. The primary artifact is `template.rb`, which uses Thor to generate new Rails 8.0.x apps pre-configured with the full stack below. The files in `app/`, `config/`, `spec/`, etc. are the template source files that get copied into generated apps.

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
npx --yes @herb-tools/linter@0.11.2  # HTML+ERB views; works from this repo's root too
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
Solid Queue (no Redis). `rails new` 8.0 runs the `solid_cache:install`, `solid_queue:install` and `solid_cable:install` generators before `after_bundle`; `template.rb` only overrides `config/cache.yml` and `config/cable.yml` with the files in this repo.
- Jobs run with `bin/jobs --mode async` (`Procfile.dev` locally, `scripts/puntapie.jobs.service` on the VPS)
- Mission Control at `/jobs`, admins only (`http_basic_auth_enabled = false`, Devise handles auth)
- Solid Cache is the production `cache_store`; development uses `memory_store` (Rails 8 default)
- Solid Cable is the Action Cable adapter in development and production

### SQLite in Production
The app intentionally uses SQLite (not PostgreSQL) with WAL mode for concurrency. Configured in `config/database.yml` with pragmas: `journal_mode: WAL`, `synchronous: NORMAL`, `mmap_size: 128MB`, and `timeout: 5000` to wait for the write lock. Rails 8.0 does not warn about SQLite in production, so no setting is needed.

`config/database.yml` is multi-database: `primary`, `queue` and `cable` in development; `primary`, `cache`, `queue` and `cable` in production; a single DB in test. The solid_* DBs have no migrations, only `db/*_schema.rb`, so use `db:prepare` (the deploy script does) instead of `db:migrate` to create them.

### JavaScript
Uses importmap-rails (no Node/Webpack/Vite). Assets go through Sprockets + dartsass-sprockets, not Propshaft: `rails new` 8.0 no longer accepts `-a sprockets`, so `template.rb` copies `app/assets/config/manifest.js` before bundling (importmap/turbo/stimulus installers boot the app) and restores `config.assets.compile = false` (production) and `config.assets.quiet = true` (development). Kamal is skipped in `template.rb` (`skip_kamal`): deployment is via SSH. Hotwire stack: Turbo + Stimulus. Bootstrap 5.3 pinned in `config/importmap.rb`.

## Locale
The app is configured for Colombian Spanish (`es-CO`). Devise views and locale files are in Spanish. Generated READMEs are in Spanish.

- View texts live in `config/locales/views.es.yml` (Devise views use lazy lookups, e.g. `t(".title")` → `es.devise.sessions.new.title`); model and attribute names in `config/locales/models.es.yml`.
- `template.rb` only copies the locale files listed in `set_locales`, so every new YAML file needs its own `copy_file` there.
- Password minimum is 10 characters (`config.password_length = 10..128`, set by `add_users`). Password fields use the `password-visibility` Stimulus controller and the `devise/shared/_password_toggle` partial.

## Seeded Data (via `setup:run`)
- Organization: "DevAsPros" (slug: "dap")
- Test user: frajaquico@aol.com with admin role

## Deployment
SSH-based VPS deployment via scripts in `scripts/`. GitHub Actions runs RSpec, RuboCop and Herb, then, only if all three pass, triggers `scripts/001_deploy_api.sh` via SSH on push to `main`. Notifications via ntfy.sh.

## RuboCop Config
130-character line length, double-quoted strings enforced. See `.rubocop.yml` for full config.

`.rubocop.yml` inherits from `.rubocop_todo.yml`, which is not in this repo: `template.rb` generates it with `rubocop --auto-gen-config` so the generated app starts with no offenses. `Rails/UniqueValidationWithoutIndex` is excluded by hand because `db/schema.rb` doesn't exist yet when the todo is generated.

## Herb Config
`.herb.yml` (Herb 0.11.2) lints HTML+ERB views. It fails only on error-level offenses; the formatter is disabled. It runs with `npx`, not as a gem, using the Node version in `.nvmrc`. `template.rb` copies `.rubocop.yml`, `.herb.yml` and `.nvmrc` into the generated app. Keep the template's views clean with `--log-level=hint`.

The `.rubocop.yml`, `.herb.yml` and `.github/workflows/workflow.yml` files mirror the sibling Rails projects in the parent folder (coshinotes, enlacito, postlane-backend, supermenu); keep them in sync.
