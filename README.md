# Puntapie

Plantilla para empezar aplicaciones Rails.

## Requisitos

* Ruby 2.5+
* Redis
* bundler - `gem install bundler`
* rails - `gem install rails`
* Yarn - `brew install yarn` o [Install Yarn](https://yarnpkg.com/en/docs/install)

## Modo de uso

Desde el repositorio:

```bash
rails new myapp -d postgresql -m https://raw.githubusercontent.com/devaspros/puntapie/master/template.rb
```

o desde archivo local:

```bash
rails new myapp -d postgresql -m template.rb
```

## ¿Qué incluye?

- Namespace de API
- .editorconfig
- Archivos .env
- Archivos Foreman (Procfile)
- Vistas de Devise con Bootstrap

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
