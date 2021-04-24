# Puntapie

Plantilla para empezar aplicaciones Rails con un puntazo inicial.

## Requisitos

* Ruby 2.5+
* Redis
* Bundler - `gem install bundler`
* Rails - `gem install rails`
* Yarn - `brew install yarn` o [Install Yarn](https://yarnpkg.com/en/docs/install)

## Modo de uso

Desde el repositorio:

```bash
rails new /path/to/app -d postgresql \
  -m https://raw.githubusercontent.com/devaspros/puntapie/master/template.rb
```

o desde archivo local:

```bash
rails new /path/to/app -d postgresql -m ~/puntapie/template.rb
```

## ¿Qué incluye?

- Namespace de API
- .editorconfig
- Archivos .env
- Archivos Foreman (Procfile)
- Vistas de Devise con Bootstrap
- RSpec y configuración general

Gemas:

- Puma
- Webpacker
- Turbolinks
- Devise
- Blueprinter
- Bootstrap
- Devise Masquerade
- Pundit
- Redis
- Sidekiq
- Annotate
- Foreman
- Amazing Print
- Dotenv Rails
- RSpec Rails
- Factory Bot
- Shoulda Matchers
- Databse Cleaner
- Simplecov
