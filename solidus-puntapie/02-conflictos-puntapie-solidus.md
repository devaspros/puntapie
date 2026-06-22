# Conflictos entre Puntapie y Solidus

Análisis de compatibilidad entre el template Puntapie (Rails 7.2 + Bootstrap + Devise + Pundit) y la instalación de Solidus 4.7.

## Conflictos identificados

### 1. `application_controller.rb` — Sobrescrito por Solidus

Puntapie incluye Pundit, Devise `authenticate_user!`, layout dinámico (`login` vs `application`) y redirección post-login a `/dashboard`. Solidus lo sobrescribe con su propia lógica. Se pierde la integración con Pundit y el flujo de navegación.

### 2. `Procfile.dev` — Sobrescrito por Solidus

Puntapie tiene un `Procfile.dev` con web en puerto 3009 y worker de Sidekiq. Solidus crea/sobrescribe `Procfile.dev` y `bin/dev` con su propia configuración (incluyendo Tailwind build). **Conflicto directo**.

### 3. `config/initializers/devise.rb` — Dos configuraciones compitiendo

Puntapie genera y modifica este archivo (confirm_within: 24h, mailer_sender, AppMailer). Solidus también genera el archivo y lo modifica al final. **Se pisa la configuración de Puntapie**.

### 4. CSS Framework: Bootstrap vs Tailwind

Puntapie usa **Bootstrap 5.2** importado vía SCSS (`sass-rails`). Solidus Starter Frontend instala **Tailwind CSS** (`tailwindcss-rails ~> 3.0`). Los layouts de Puntapie (`application.html.erb`, `login.html.erb`, etc.) dependen de clases de Bootstrap y quedarían inservibles.

### 5. Sistema de usuarios: User vs Spree::User

Puntapie tiene modelo `User` con Devise (first_name, last_name, admin:boolean, current_organization_id, multi-tenancy). Solidus instala `solidus_auth_devise` con `Spree::User` y sus propias migraciones. **Dos sistemas de autenticación paralelos incompatibles**.

### 6. Autorización: Pundit vs permisos de Solidus

Puntapie integra Pundit en `ApplicationController` con policies. Solidus tiene su propio sistema de roles/permisos (`Spree::Role`, `Spree::PermissionSet`). No hay puente entre ambos.

### 7. `db/seeds.rb` — Append a archivo que no existe

Puntapie **no tiene** `db/seeds.rb` (usa un rake task `setup:run`). Solidus hace `append` a este archivo, lo que fallaría o requeriría crearlo manualmente.

### 8. `app/javascript/controllers/index.js` — Modificado por Solidus

Puntapie define sus propios controladores Stimulus (toast_controller). Solidus modifica este archivo.

### 9. Testing: RSpec duplicado

Ambos corren `rspec:install`. Puntapie ya configura RSpec con factory_bot, database_cleaner, request_spec_helper, etc. Solidus agrega sus propias gemas de testing. Duplicación y posible conflicto en `spec/rails_helper.rb` y `spec/spec_helper.rb`.

### 10. Gemas de testing con versiones distintas

Solidus agrega `capybara`, `database_cleaner`, `selenium-webdriver`, `rspec-rails`, `factory_bot`, `factory_bot_rails`, `ffaker` en sus versiones. Puntapie ya las tiene con versiones específicas. **Conflicto de versiones en el Gemfile**.

### 11. Rutas — Dos `devise_for`

Puntapie define `devise_for :users` para web y API. Solidus monta rutas de tienda en `/`. Sin conflicto directo de rutas, pero dos sistemas de Devise compitiendo.

## Resumen de severidad

| Conflicto | Severidad |
|-----------|-----------|
| `application_controller.rb` sobrescrito | Alta |
| Bootstrap vs Tailwind | Alta |
| User vs Spree::User | Alta |
| Pundit vs permisos Solidus | Alta |
| `Procfile.dev` sobrescrito | Alta |
| `devise.rb` pisado | Alta |
| `db/seeds.rb` inexistente | Media |
| `index.js` modificado | Media |
| RSpec duplicado | Media |
| Gemas testing duplicadas | Baja-Media |

## Conclusión

> **La plantilla Puntapie no es compatible con Solidus sin modificaciones significativas.** Los puntos de fricción son estructurales — involucran el sistema de autenticación, el framework CSS, la autorización, y archivos clave del core de Rails. No se trata de conflictos menores de configuración sino de decisiones de arquitectura incompatibles. Para que funcionaran juntos, habría que rediseñar aspectos fundamentales del template.
