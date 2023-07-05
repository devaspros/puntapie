# Puntapie

Plantilla para empezar aplicaciones Rails con un puntazo inicial.

## Requisitos

* Rails 7
* Ruby 3.1.0
* Redis
* Bundler `gem install bundler`
* Rails `gem install rails`
* Yarn `brew install yarn` o [Instala Yarn](https://yarnpkg.com/en/docs/install)

## Modo de uso

Desde el repositorio:

```bash
rails new /path/to/app -d postgresql \
  -m https://raw.githubusercontent.com/devaspros/puntapie/master/template.rb
```

o desde archivo local:

```bash
rails new /path/to/app -d postgresql -m ~/puntapie/template.rb

rails new /path/to/app -d sqlite3 -m ~/puntapie/template.rb
```

## ¿Qué incluye?

### Configuraciones y Archivos

- Namespace de API
- .editorconfig
- Archivos .env
- Archivos Foreman (Procfile) con Release Phase para Heroku
- Vistas de Devise con Bootstrap
- RSpec configurado

### Gemas

- [annotate](https://github.com/ctran/annotate_models)
- [amazing_print](https://github.com/amazing-print/amazing_print)
- [bootstrap](https://github.com/twbs/bootstrap-rubygem)
- [blueprinter](https://github.com/procore/blueprinter)
- [database-cleaner](https://github.com/DatabaseCleaner/database_cleaner)
- [devise](https://github.com/heartcombo/devise)
- [devise-masquerade](https://github.com/oivoodoo/devise_masquerade)
- [dotenv-rails](https://github.com/bkeepers/dotenv)
- [factory-bot](https://github.com/thoughtbot/factory_bot/)
- [foreman](https://github.com/ddollar/foreman)
- [importmap-rails](https://github.com/rails/importmap-rails)
- [pundit](https://github.com/varvet/pundit)
- [puma](https://github.com/puma/puma)
- [redis](https://github.com/redis/redis-rb)
- [rspec-rails](https://github.com/rspec/rspec-rails)
- [shoulda-matchers](https://github.com/thoughtbot/shoulda-matchers)
- [sidekiq](https://github.com/mperham/sidekiq)
- [simplecov](https://github.com/simplecov-ruby/simplecov)
- [stimulus-rails](https://github.com/hotwired/stimulus-rails)
- [turbo-rails](https://github.com/hotwired/turbo-rails)
