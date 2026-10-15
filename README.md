# Puntapie

Plantilla para empezar aplicaciones Rails con un puntazo inicial.

# Requisitos

* Rails 7.2.3.1
* Ruby 3.4.8
* SQLite3
* Redis
* Bundler `gem install bundler`
* Rails `gem install rails -v 7.2.3.1`
* Un servidor SMTP local en el puerto 1025 para ver los correos en desarrollo, como [Mailpit](https://mailpit.axllent.org/) o [MailCatcher](https://mailcatcher.me/)
* En el servidor de producción: Node 22.14.0 (ver `.nvmrc`) disponible en `/usr/local/bin/node`. El script de despliegue verifica que exista

# ¿Cómo uso Puntapie?

Usando la plantilla desde el repositorio en GitHub:

```bash
rails _7.2.3.1_ new ./pruebapie01 \
  -d sqlite3 \
  -m https://raw.githubusercontent.com/devaspros/puntapie/master/template.rb \
  --skip-test
```

También se puede clonar el repo y leer la plantilla desde el archivo local:

```bash
rails _7.2.3.1_ new ../pruebapie01 \
  -d sqlite3 \
  -m ./template.rb \
  --skip-test
```

> [!Important]
> El workflow de GitHub Actions de la app generada corre las pruebas en cualquier rama, pero solo despliega desde `main`. Si git creó el repo con `master`, renombra la rama con `git branch -M main` antes del primer push.

> [!Important]
> Puntapie solo soporta SQLite3. La plantilla reemplaza `config/database.yml` con una configuración de SQLite y el `Gemfile` solo incluye la gema `sqlite3`, así que usar `-d postgresql` no genera una app con PostgreSQL.

# ¿Qué incluye Puntapie?

## Usuarios y organizaciones

- Devise con `confirmable` (la confirmación vence en 24 horas), registro con nombre y apellido, y `AppMailer` como mailer
- Vistas de Devise con Bootstrap y en español
- Multi-tenancy con `Organization`, `Membership`, `Role` e `Invitation`. Al registrarse, cada usuario recibe una organización propia y queda como su dueño
- Roles `admin`, `member` y `viewer`, creados con `rails setup:run`
- Autorización con Pundit

## API

- Namespace `/api/v1` con login por JWT (`POST /api/v1/users/sign_in`, el token vence en 7 días)
- `Api::BaseApiController` valida el token y maneja los errores con el concern `ApiExceptionHandler`
- Health check en `GET /ping`

## Trabajos en segundo plano

- Sidekiq con Redis como adaptador de Active Job, con las colas `default` y `mailers`
- Sidekiq Web en `/sidekiq`, solo para usuarios admin

## Correo

- En desarrollo, SMTP en `127.0.0.1:1025` y previews en `spec/mailers/previews`
- En producción, envío con Resend

## Seguridad y errores

- Rack::Attack limita los registros por IP (5 por minuto) y por email (3 por hora)
- Sentry reporta errores fuera de los entornos locales
- Páginas propias para errores 4xx y 5xx con `exception_handler`

## Base de datos

- SQLite en modo WAL, con pragmas para producción y `timeout` para esperar el lock de escritura
- Backport de Rails 8 (`config/initializers/sqlite3_busy_handler_timeout.rb`) para esperar el lock sin bloquear los demás hilos de Puma. Se borra al actualizar a Rails 8
- Active Storage instalado

## Interfaz

- Hotwire (Turbo y Stimulus) y Bootstrap con importmap, sin bundler de JavaScript
- Layouts para landing, login, aplicación y errores; navbar, sidebar y footer
- Páginas de política de privacidad y términos de servicio
- Controller de Stimulus para mostrar toasts
- Meta tags con `meta-tags`
- Español (`es`) como idioma por defecto, con `es-CO.yml` y `devise.es.yml`

## Despliegue

- Despliegue a VPS por SSH con GitHub Actions: corre RSpec, despliega desde `main` y avisa por [ntfy.sh](https://ntfy.sh/) (ver [`scripts/README.md`](scripts/README.md))
- `scripts/set_repo_secrets.sh` para configurar los secrets del repo
- Configuración de nginx, servicios de systemd para Puma y Sidekiq, y logrotate
- Scripts para respaldar la base de datos y los logs
- Logs de producción en `log/production.log` con rotación diaria
- Dependabot para las gemas

## Desarrollo

- `bin/setup-project-name` para reemplazar `Puntapie` por el nombre del proyecto
- RSpec con FactoryBot, DatabaseCleaner, Capybara, helpers de Devise y SimpleCov
- RuboCop configurado
- Generadores de Rails sin assets, helpers, jbuilder ni specs de vistas y helpers
- `.editorconfig`, archivos `.env` y Foreman (`Procfile` y `Procfile.dev`)

## Gemas

Agrupadas igual que en [`Gemfile.tt`](Gemfile.tt), que es la referencia para las versiones exactas.

Producción:

- [blueprinter](https://github.com/procore-oss/blueprinter)
- [bootsnap](https://github.com/shopify/bootsnap)
- [bootstrap](https://github.com/twbs/bootstrap-rubygem)
- [devise](https://github.com/heartcombo/devise)
- [exception_handler](https://github.com/richpeck/exception_handler)
- [importmap-rails](https://github.com/rails/importmap-rails)
- [jwt](https://github.com/jwt/ruby-jwt)
- [meta-tags](https://github.com/kpumuk/meta-tags)
- [puma](https://github.com/puma/puma)
- [pundit](https://github.com/varvet/pundit)
- [rack-attack](https://github.com/rack/rack-attack)
- [redis](https://github.com/redis/redis-rb)
- [resend](https://github.com/resend/resend-ruby)
- [sass-rails](https://github.com/rails/sass-rails)
- [sentry-rails y sentry-ruby](https://github.com/getsentry/sentry-ruby)
- [sidekiq](https://github.com/sidekiq/sidekiq)
- [sqlite3](https://github.com/sparklemotion/sqlite3-ruby)
- [stimulus-rails](https://github.com/hotwired/stimulus-rails)
- [turbo-rails](https://github.com/hotwired/turbo-rails)

Desarrollo:

- [annotate](https://github.com/ctran/annotate_models)
- [foreman](https://github.com/ddollar/foreman)
- [rubocop](https://github.com/rubocop/rubocop)
- [solargraph](https://github.com/castwide/solargraph)
- [solargraph-rails](https://github.com/iftheshoefritz/solargraph-rails)
- [spring](https://github.com/rails/spring)
- [web-console](https://github.com/rails/web-console)

Desarrollo y Pruebas:

- [amazing_print](https://github.com/amazing-print/amazing_print)
- [byebug](https://github.com/deivid-rodriguez/byebug)
- [dotenv-rails](https://github.com/bkeepers/dotenv)
- [factory_bot_rails](https://github.com/thoughtbot/factory_bot_rails)
- [rspec-rails](https://github.com/rspec/rspec-rails)

Pruebas:

- [capybara](https://github.com/teamcapybara/capybara)
- [database_cleaner](https://github.com/DatabaseCleaner/database_cleaner)
- [selenium-webdriver](https://github.com/SeleniumHQ/selenium/tree/trunk/rb)
- [simplecov](https://github.com/simplecov-ruby/simplecov)

# Comparación con Solidus

Se analizó la compatibilidad de Puntapie con [Solidus](https://solidus.io/) (e-commerce framework para Rails). La conclusión es que **Puntapie no es compatible con Solidus sin modificaciones significativas** debido a conflictos estructurales en autenticación, framework CSS, autorización y archivos core.

El análisis completo está en [`solidus-puntapie/`](solidus-puntapie/).
