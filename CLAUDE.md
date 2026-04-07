# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What This Repo Is

**Puntapie is a Rails app template generator**, not a standard Rails application. The primary artifact is `template.rb`, which uses Thor to generate new Rails 7.2.x apps pre-configured with the full stack below. The files in `app/`, `config/`, `spec/`, etc. are the template source files that get copied into generated apps.

To use the template:
```bash
rails new my_app -d sqlite3 --no-action-mailbox --no-action-text -m template.rb
# or from GitHub:
rails new my_app -d sqlite3 -m https://raw.githubusercontent.com/.../template.rb
```

## Development Commands

```bash
# Install dependencies
bundle install

# Database setup
bundle exec rails db:create
bundle exec rails db:schema:load
bundle exec rails all_tasks:execute_all  # Creates default org, roles, users

# Start the app (uses Procfile.dev via .foreman)
foreman start  # Runs web on port 3005 + Sidekiq

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
Sidekiq with Redis. Queues: `default` and `mailers`. Redis URL via `ENV["REDIS_URL"]`.

### SQLite in Production
The app intentionally uses SQLite (not PostgreSQL) with WAL mode for concurrency. Configured in `config/database.yml` with pragmas: `journal_mode: WAL`, `synchronous: NORMAL`, `mmap_size: 128MB`. The production warning is suppressed in `config/application.rb`.

### JavaScript
Uses importmap-rails (no Node/Webpack/Vite). Hotwire stack: Turbo + Stimulus. Bootstrap 5.2 pinned in `config/importmap.rb`.

## Locale
The app is configured for Colombian Spanish (`es-CO`). Devise views and locale files are in Spanish. Generated READMEs are in Spanish.

## Seeded Data (via `all_tasks:execute_all`)
- Organization: "DevAsPros" (slug: "dap")
- Test user: frajaquico@aol.com with admin role

## Deployment
SSH-based VPS deployment via scripts in `scripts/`. GitHub Actions runs tests then triggers `scripts/001_deploy_api.sh` via SSH on push to `main`. Notifications via ntfy.sh.

## RuboCop Config
130-character line length, double-quoted strings enforced. See `.rubocop.yml` for full config.
