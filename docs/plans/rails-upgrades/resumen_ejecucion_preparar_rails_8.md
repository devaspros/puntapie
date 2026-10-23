# Resumen de ejecución: preparar Rails 8.0 en Puntapie

Ejecución de `docs/plans/2026-10-23-preparar-rails-8.md` (23 oct 2026). Todo en `master`, un commit por etapa, sin
ramas ni PRs. Las pruebas se corrieron todas juntas al final sobre una app generada con la plantilla.

## Qué se hizo

| Etapa | Commit | Cambio |
|---|---|---|
| 1 | `82eea78` | `actions/checkout@v7`; pruebas en push a `main` y en PR; avisos de ntfy.sh con `--max-time 10` y `continue-on-error` |
| 2 | `9eb2e5c` | `rubocop-rails` (`plugins:`); factory de usuarios con `sequence(:email)`; `Metrics/BlockLength` fuera de los specs |
| 3 | `4aa9e0e` | Bootstrap 5.3.8; el deploy ya no comprueba `node`; los READMEs no piden NodeJS |
| 4 | `b375fe9` | `sass-rails` → `dartsass-sprockets`; `template.rb` silencia los avisos de Dart Sass; `darken()` → `color.adjust()` en `landing.scss`; spec de humo `spec/assets/stylesheets_spec.rb` |
| 5 | `d85bdb9` | `annotate` → `annotaterb` (`.annotaterb.yml` con `:ignore_multi_database_name: true` y `lib/tasks/annotate_rb.rake`) |
| 6 | `458ab96` | `exception_handler` configurado también en test; spec de las páginas 404/5xx; borrado `shared/_navbar.html.erb` |
| 7 | `9d467c3` | `database.yml` sin `host` ni `encoding`; spec `spec/config/database_config_spec.rb` |
| 8 | `a5b9dd4` | Sin Active Storage, Action Mailbox ni Action Text (flags `--skip-*` en los comandos de `rails new`, spec de rutas); Sentry lee `SENTRY_DSN`; `namespace "api", defaults:` en vez de `default:` (con spec de rutas) |
| 9 | `c52af3f` | Arreglos que salieron al probar: anotaciones de `Membership` y `Organization` en el orden de la base; `Rails/UniqueValidationWithoutIndex` excluido en los tres modelos |

La tarea 6.2 original (errores de la API en JSON) se quitó del plan a pedido del usuario.

## Resultado de las pruebas (app generada con los flags nuevos)

- RSpec: **40 ejemplos, 0 fallos** (línea base: 31). Con `deprecation = :raise`: 0 deprecations de Rails.
- RuboCop: 50 archivos, sin ofensas. `annotaterb models --frozen`: sin cambios.
- `assets:precompile` en producción: Bootstrap v5.3.8, sin avisos de Dart Sass.
- `RAILS_ENV=production rake -T` arranca sin `annotaterb`. `bin/jobs` arranca. Sentry toma el DSN de `SENTRY_DSN`.
- `timeout=5000` y sin `host`/`encoding`/`retries` en todas las bases de todos los entornos.
- Lock: entran `dartsass-sprockets 3.2.1`, `sass-embedded` (con `x86_64-linux-gnu`), `annotaterb 4.25.0` y
  `rubocop-rails 2.38.0`. Salen `sassc`, `sass-rails`, `ffi`, `annotate`, `autoprefixer-rails` y `execjs`.
  `sprockets 4.4.1` y `sprockets-rails 3.5.2` no cambian.
- Una app generada **sin** `--skip-active-storage` hace fallar `spec/routing/rails_frameworks_routes_spec.rb` (2 fallos), como se buscaba.
- Prueba de resolución con `rails ~> 8.0.0`: resuelve con **Rails 8.0.5.1**. Fuera de las gemas de Rails, solo sale `cgi` y entra `uri 1.1.2`.

## Pendiente

**Lo corre el usuario**
- Reportes `01` y `02.rails_preflight_report.html` (en `pruebapie-base` y `pruebapie-final` del scratchpad, o en una app generada de nuevo).
- Revisión visual de Bootstrap 5.3 (no se tomaron capturas). Se espera que `bg-body-tertiary` pinte `#f8f9fa` en el login y en el sidebar.

**Para el salto a Rails 8.0**
- `gem "rails", "~> 8.0"`, `Migration[8.0]` en `template.rb`, `rails _8.0.x_ new` en el README. Revisar qué genera `rails new` 8.0 que choque con lo que copia la plantilla.
- Borrar `config/initializers/sqlite3_busy_handler_timeout.rb` y su `copy_file`.
- `exception_handler 0.8.0.2`: correr `error_pages_spec.rb`. Plan B: `config.exceptions_app = routes` y un `ErrorsController` propio.
- `selenium-webdriver 4.16.0` y `capybara 3.39.2`: subirlas o quitarlas (no hay system specs).
- Comentario sobre `json ~> 2.19` en `Gemfile.tt`: ver si sigue aplicando en 8.0.

**Encontrado, sin tocar**
- `ApiExceptionHandler`: errores de la API en JSON (404 de ruta, 500 y JSON malformado) y `:unprocessable_entity` → `:unprocessable_content`. Se sacó del plan.
- `base_api_url` en `spec/support/request_spec_helper.rb` devuelve `http://example.com/v1`, sin `/api`.
- Índices únicos para `invitations`, `memberships` (`user_id` + `organization_id`) y `roles.name`. Con ellos se podría quitar la exclusión de `Rails/UniqueValidationWithoutIndex`.
- SimpleCov avisa dos deprecations: `add_group` → `group`, y `SimpleCov.start` dentro de `.simplecov`.
- Puma corre como root: `puntapie.puma.service` no tiene `User=`.
- El deploy y `puntapie.jobs.service` usan `.PUNTAPIE.envs`, y `puntapie.puma.service` y el README `.puntapie.envs`.
