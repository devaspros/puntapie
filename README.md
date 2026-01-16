# Puntapie

Plantilla para empezar aplicaciones Rails con un puntazo inicial.

# Requisitos

* Rails 7.1.5.2
* Ruby 3.2.5
* Redis
* Bundler `gem install bundler`
* Rails `gem install rails -v 7.1.5.2`

# ¿Cómo uso Puntapie?

Usando la plantilla desde el repositorio en GitHub.

Con base de datos SQLite3:

```bash
rails _7.1.5.2_ new ./pruebapie01 \
  -d sqlite3 \
  -m https://raw.githubusercontent.com/devaspros/puntapie/master/template.rb \
  --skip-test
```

O base de datos PostgreSQL:

```bash
rails _7.1.5.2_ new ./pruebapie01 \
  -d postgresql \
  -m https://raw.githubusercontent.com/devaspros/puntapie/master/template.rb \
  --skip-test
```

También se puede clonar el repo y leer la plantilla desde el archivo local.

Para una BD SQLite3:

```bash
rails _7.1.5.2_ new ../pruebapie01 \
  -d sqlite3 \
  -m ./template.rb \
  --skip-test
```

Para una BD en PostgreSQL:

```bash
rails _7.1.5.2_ new ../pruebapie01 \
  -d postgresql \
  -m ./template.rb \
  --skip-test
```

# ¿Qué incluye Puntapie?

## Configuraciones y Archivos

- Namespace de API
- .editorconfig
- Archivos .env
- Archivos Foreman (Procfile) con Release Phase para Heroku
- Vistas de Devise con Bootstrap
- RSpec configurado

## Gemas

Producción:

- [bootsnap](https://github.com/shopify/bootsnap)
- [bootstrap](https://github.com/twbs/bootstrap-rubygem)
- [blueprinter](https://github.com/procore/blueprinter)
- [devise](https://github.com/heartcombo/devise)
- [importmap-rails](https://github.com/rails/importmap-rails)
- [pundit](https://github.com/varvet/pundit)
- [puma](https://github.com/puma/puma)
- [redis](https://github.com/redis/redis-rb)
- [sidekiq](https://github.com/mperham/sidekiq)
- [stimulus-rails](https://github.com/hotwired/stimulus-rails)
- [turbo-rails](https://github.com/hotwired/turbo-rails)

Desarrollo y Pruebas:

- [annotate](https://github.com/ctran/annotate_models)
- [amazing_print](https://github.com/amazing-print/amazing_print)
- [database-cleaner](https://github.com/DatabaseCleaner/database_cleaner)
- [dotenv-rails](https://github.com/bkeepers/dotenv)
- [factory-bot](https://github.com/thoughtbot/factory_bot/)
- [foreman](https://github.com/ddollar/foreman)
- [rspec-rails](https://github.com/rspec/rspec-rails)
- [simplecov](https://github.com/simplecov-ruby/simplecov)
