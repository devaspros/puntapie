# Resumen de instalación de Solidus

Gemas agregadas por `solidus:install`:

| Gema | Propósito |
|------|-----------|
| `solidus_core` | Núcleo de Solidus (modelos, servicios, etc.) |
| `solidus_backend` | Admin panel legacy (vía el starter frontend) |
| `solidus_api` | API REST de Solidus |
| `solidus_sample` | Datos de ejemplo (productos, órdenes, etc.) |
| `solidus_auth_devise` | Autenticación con Devise para Solidus |
| `solidus_legacy_promotions` | Sistema de promociones/cupones |
| `solidus_admin` | Nuevo panel admin (>= v0.2) |
| `solidus_starter_frontend` | Frontend de tienda con Tailwind |
| `responders` | Dependencia de Devise |
| `solidus_support` | Utilidades compartidas |
| `view_component (~> 3.0)` | Componentes de vista |
| `tailwindcss-rails (~> 3.0)` | CSS utility framework |
| `capybara`, `selenium-webdriver`, `capybara-screenshot`, `database_cleaner` | Testing (grupo :test) |
| `rspec-rails`, `rails-controller-testing`, `rspec-activemodel-mocks`, `factory_bot`, `factory_bot_rails`, `ffaker` | Testing (grupo :dev, :test) |
| `rubocop`, `rubocop-performance`, `rubocop-rails`, `rubocop-rspec` | Linting (grupo :dev, :test) |

## Archivos creados

- `config/initializers/spree.rb` — Configuración principal de Solidus
- `config/initializers/devise.rb` — Configuración de Devise
- `config/initializers/solidus_auth_devise_unauthorized_redirect.rb`
- `config/initializers/solidus_admin.rb`
- `config/initializers/assets.rb` (modificado)
- `config/routes/storefront.rb` — Rutas de la tienda
- `config/tailwind.config.js`
- `config/solidus_admin/tailwind.config.js`
- `app/assets/builds/tailwind.css`
- `app/assets/stylesheets/solidus_admin/application.tailwind.css`
- `vendor/assets/javascripts/spree/backend/all.js`
- `vendor/assets/stylesheets/spree/backend/all.css`
- `app/overrides/` — Directorio para Deface overrides
- `public/storefront_favicon.ico`, `public/storefront_favicon.svg`
- `bin/dev` — Script para levantar con Foreman
- `Procfile.dev`
- `.rspec`, `spec/spec_helper.rb`, `spec/rails_helper.rb`
- `lib/tasks/solidus_admin/tailwind.rake`
- Migraciones de Active Storage, Action Mailbox, Action Text y ~70 migraciones de Solidus (spree, spree_api, solidus_auth, legacy_promotions)

## Archivos modificados

- `app/controllers/application_controller.rb` — Sobrescrito para incluir lógica de Solidus
- `app/javascript/controllers/index.js` — Modificado para incluir estímulos de Solidus
- `app/views/layouts/application.html.erb` — Inyectados tags de Tailwind
- `app/assets/config/manifest.js` — Agregado build de Tailwind
- `app/assets/stylesheets/application.css` — Modificado para Tailwind
- `db/seeds.rb` — Se agrega llamado a seeds de Solidus (`Spree::Core::Engine.load_seed` + `solidus_auth`)
- `config/environments/test.rb` — Se agrega config para mailer y asset pipeline
- `public/robots.txt` — Se agregan reglas para storefront
- `.gitignore` — Se agrega `app/assets/builds/` y `node_modules/`
- `Gemfile` — Se inyectan todas las gemas listadas arriba

## Cosas clave que agrega

1. **Autenticación** con Devise + `solidus_auth_devise` (tabla `spree_users`, confirmable, recoverable)
2. **Admin moderno** en `/admin` vía `solidus_admin` (Tailwind, montado con constraint de cookie)
3. **Rutas de tienda** (productos, carrito, checkout, etc.) montadas en `/`
4. **Seed data**: tienda por defecto, países/estados, zonas, métodos de envío/pago, roles, categorías, y **datos de ejemplo** (~13 productos con imágenes)
5. **Admin user**: `admin@example.com` / `test123`
6. **Frontend starter** con Tailwind CSS, ViewComponent, y Hotwire (Turbo + Stimulus)
7. **Sistema de promociones** legacy (cupones, reglas, ajustes)
8. **Wallet** — billetera para métodos de pago guardados
9. **API key** en usuarios para autenticación API
10. **Store credit** — sistema de créditos en tienda
