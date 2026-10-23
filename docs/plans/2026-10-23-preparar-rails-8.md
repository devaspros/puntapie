# Preparar Puntapie para Rails 8.0 Plan de Implementación

> **Estado: COMPLETADO (23 oct 2026).** Etapas 0 a 9 ejecutadas en `master`, un commit por etapa (`82eea78`..`c52af3f`), sin ramas ni PRs a pedido del usuario. Las pruebas se corrieron todas juntas al final (etapa 9), no por etapa. Decisiones del usuario: 8.1 sí, 6.2 sí, 8.3 sí. Resumen: `docs/plans/rails-upgrades/resumen_ejecucion_preparar_rails_8.md`.

> **Para trabajadores agénticos:** SUB-HABILIDAD REQUERIDA: Usa superpowers:subagent-driven-development (recomendado) o superpowers:executing-plans para implementar este plan tarea por tarea. Los pasos usan casillas de verificación (`- [ ]`) para el seguimiento.

**Objetivo:** Traer a la plantilla los cambios que ya se hicieron en cashflow, coshinotes, enlacito, supermenu y postlane-backend para preparar Rails 8.0, para que las apps nuevas nazcan con ellos y el salto a 8.0 de Puntapie salga igual que en esos repos.

**Arquitectura:** Puntapie no es una app: es `template.rb` más los archivos que copia. No hay `Gemfile.lock`; cada cambio se prueba generando una app desde el archivo local y corriendo RSpec y RuboCop **en la app generada**. Una rama y un PR por etapa, desde `master`.

**Stack Tecnológico:** Rails 7.2.3.1, Ruby 3.4.8, Thor (`template.rb`), RSpec, RuboCop 1.92, Bootstrap, Sprockets, importmap, SQLite, GitHub Actions.

**Especificación:** Los resúmenes de ejecución de los repos hermanos (leerlos antes de empezar, en este orden):

- `../cashflow/docs/plans/rails-upgrades/resumen_ejecucion_preparar_rails_8.md` (el más completo: flujo, comandos, hallazgos)
- `../coshinotes/docs/plans/rails-upgrades/resumen_ejecucion_preparar_rails_8.md`
- `../enlacito/docs/plans/rails-upgrades/resumen_ejecucion_preparar_rails_8.md` (tiene la misma `landing.scss` que la plantilla)
- `../supermenu/docs/plans/rails-upgrades/resumen_ejecucion_preparar_rails_8.md`
- `../postlane-backend/docs/plans/rails-upgrades/resumen_ejecucion_preparar_rails_8.md` (el más parecido a la plantilla: API + vistas; incidente de Active Storage)

## Lo que ya está hecho en Puntapie (no repetir)

| Hallazgo de los repos | Estado en la plantilla |
|---|---|
| SQLite `retries` → `timeout: 5000` | Hecho en `config/database.yml`, con el backport `config/initializers/sqlite3_busy_handler_timeout.rb` |
| Devise 4.9.3 → 5.0.3 (blocker que el preflight no ve) | Hecho en `Gemfile.tt` |
| `rspec-rails` → 8.x (pendiente en todos los repos) | Hecho: `8.0.4` en `Gemfile.tt` (commit `0a20911`) |
| `json ~> 2.19`, `sqlite3 2.9.6` | Hecho (commit `0a20911`) |
| Font Awesome → SVG inline | No aplica: la plantilla usa Bootstrap Icons por CDN (`shared/_head.html.erb`) |
| `view_component` 3 → 4 | No aplica: la plantilla no usa `view_component` |

## Restricciones Globales

- **Nada de `docs/` entra en ningún commit** (ni este plan ni `docs/actualizacion-gemas-dependabot-2026-10.md`). Usa `git add <rutas>` explícitas, nunca `git add .` ni `git add -A`, y revisa `git show --stat HEAD` después de cada commit.
- Rama por etapa desde `master` actualizado: `refactor/preparar-rails-8-etapa-X`. La rama principal de Puntapie es `master`, pero las apps generadas despliegan desde `main` (los workflows usan `main`: no cambiarlo).
- Push y PR solo cuando el usuario lo pida, con la label `Rails Upgrades` (`gh pr create --label "Rails Upgrades" ...`; si no existe: `gh label create "Rails Upgrades" --color BE258E`). Para editar un PR existente usa la API REST (`gh pr edit` falla con el error de "Projects (classic)").
- Pedir confirmación al terminar cada etapa antes de pasar a la siguiente, con una sola pregunta directa.
- Commits atómicos en español, en imperativo. Un arreglo que funciona antes y después del cambio va en su propio commit, antes del cambio.
- Nada de comandos interactivos (`git commit -p`, `rebase -i` sin `GIT_SEQUENCE_EDITOR=true`).
- Rails de la plantilla: `7.2.3.1`. Ruby `3.4.8`. RuboCop: 130 caracteres, comillas dobles, constantes string con `.freeze`.
- Código: argumentos entre paréntesis (también en specs), línea en blanco entre bloques hermanos, specs autocontenidos dentro de cada `it` y **sin** comentarios `# Setup/# Exercise/# Verify`.
- Versiones objetivo: `bootstrap ~> 5.3.8`, `dartsass-sprockets ~> 3.2`, `annotaterb ~> 4.25`, `rubocop-rails` (sin fijar, `require: false`), `actions/checkout@v7`.

## Ciclo de verificación (se usa en todas las tareas)

La app de prueba se genera **fuera del repo**, en el scratchpad de la sesión (`$S`), desde el archivo local, así que toma los cambios sin commitear:

```bash
S=<scratchpad>
APP=$S/pruebapie-etapa-X
rm -rf $APP
SKIP_GIT=1 rails _7.2.3.1_ new $APP -d sqlite3 -m ./template.rb --skip-test 2>&1 | tail -40

cd $APP
bundle exec rails db:prepare setup:run
bundle exec rspec
bundle exec rubocop
```

- Anota el número de ejemplos de cada etapa para compararlo con la línea base.
- Revisa la salida de `rails new` completa si algo falla: un `gsub_file` que no encuentra su texto solo imprime un aviso y sigue.
- `template.rb` corre `rubocop --auto-gen-config` al final, así que RuboCop siempre sale limpio en la app generada. Para ver las ofensas reales mira `.rubocop_todo.yml` de la app generada y compáralo con el de la línea base.
- Para comprobar como en producción (el deploy corre `assets:clobber`, `assets:precompile` y `db:prepare`):
  ```bash
  RAILS_ENV=production SECRET_KEY_BASE=dummy bundle exec rails assets:precompile 2>&1 | tail -20
  RAILS_ENV=production SECRET_KEY_BASE=dummy bundle exec rails assets:clobber
  ```
- Si levantas un servidor de la app generada, usa otro puerto (`bin/rails s -p 3055`) y mátalo al terminar (`lsof -ti tcp:3055 | xargs kill`).

## Enfoque de Revisión

1. **Una app generada con los flags del README sin `--skip-active-storage` sigue exponiendo `/rails/active_storage/direct_uploads`**: el spec de rutas de la tarea 8.1 tiene que fallar en esa app para que el dueño se entere.
2. **Una ruta web inexistente** debe mostrar la página 404 propia, sin el sidebar del layout `application` (que falla sin `current_user`): cubierto en la tarea 6.1.
3. **El deploy en un servidor sin `node`** debe compilar los assets: cubierto en las tareas 3.1 y 3.2 (`execjs` y `autoprefixer-rails` fuera del lock, precompilación en modo producción).
4. **Cada base de cada entorno** (`primary`, `cache`, `queue`, `cable`) debe quedar con `timeout` y sin `host` ni `encoding`, no solo la de test: cubierto en la tarea 7.1 con el `rails runner` sobre todos los entornos.
5. **La landing compilada con Dart Sass** debe pintar los mismos hovers que con libsass (Dart Sass no redondea colores): cubierto en las tareas 4.1 y 4.2 comparando canales redondeados.

---

## Etapa 0: Línea base

### Tarea 0.1: Generar la app de la línea base y registrar números

- [x] `git switch master && git pull --prune`. Compara `git rev-parse origin/master` con `git rev-parse master`.
- [x] Corre el ciclo de verificación con `APP=$S/pruebapie-base`.
- [x] Anota: ejemplos y fallos de `rspec`, contenido de `.rubocop_todo.yml` de la app generada, y versiones resueltas de `bootstrap`, `sassc`, `sass-rails`, `annotate`, `autoprefixer-rails` y `execjs` en su `Gemfile.lock`.
- [ ] **Pendiente (usuario):** Pide al usuario que corra `rails-preflight` sobre `$S/pruebapie-base` y guarde el reporte como `docs/plans/rails-upgrades/01.rails_preflight_report.html` (no se commitea).
- [ ] **No hecho:** Opcional: capturas con Playwright de `/`, `/users/sign_in`, `/dashboard` y una ruta 404 en `tmp/capturas/etapa-0/` de la app generada (ver la sección "Navegador" del resumen de cashflow; usuario `frajaquico@aol.com`, pide la contraseña de desarrollo una sola vez si no está en un `.env`).

No hay commit en esta etapa.

---

## Etapa 1: GitHub Actions

### Tarea 1.1: `actions/checkout@v7` y pruebas sin duplicar

**Archivos:** `.github/workflows/workflow.yml`, `.github/workflows/deploy.yml`

La v4 corre en Node 20 (deprecado). `on: [push, pull_request]` corre las pruebas dos veces por cada push a una rama con PR.

`workflow.yml`:

```yaml
name: Rails tests
on:
  push:
    branches: [main]
  pull_request:
jobs:
  rspec-tests:
    name: RSpec
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v7
```

Deja el `if: github.ref == 'refs/heads/main'` del job `deploy`. En `deploy.yml`: `actions/checkout@v4` → `actions/checkout@v7`.

- [x] Haz los cambios.
- [x] Comprueba que no quede ningún `@v4`: `grep -rn "@v4" .github`.
- [x] Ciclo de verificación: `.github/workflows/*.yml` de la app generada tiene los cambios.
- [x] Commit: "Sube actions/checkout a v7 y corre las pruebas una sola vez por push".

### Tarea 1.2: Que ntfy.sh no tumbe el job de deploy

**Archivo:** `.github/workflows/deploy.yml`

En postlane el deploy funcionó pero el job salió en rojo porque el runner no llegó a `ntfy.sh` (`curl: (28)` a los 133 s). En los dos pasos de NTFY:

```yaml
      - name: Notify success via NTFY
        if: success()
        continue-on-error: true
        run: |
          curl --max-time 10 \
               -H "Title: 🚀 Despliegue Exitoso - ${{ github.repository }}" \
```

Igual para `Notify failure via NTFY` (`continue-on-error: true` y `--max-time 10`).

- [x] Haz el cambio y comprueba la sintaxis: `ruby -ryaml -e 'YAML.load_file(".github/workflows/deploy.yml")'`.
- [x] Commit: "Evita que una caída de ntfy.sh marque el deploy como fallido".

---

## Etapa 2: Pruebas y RuboCop

### Tarea 2.1: Email de la factory con secuencia

**Archivo:** `spec/factories/users.rb`

`"user#{rand(1000)}@example.com"` choca al azar cuando un ejemplo crea dos usuarios (pasó en el CI de postlane).

```ruby
    sequence(:email) { |n| "user#{n}@example.com" }
```

- [x] Haz el cambio, corre el ciclo de verificación.
- [x] Commit: "Usa una secuencia para el email de la factory de usuarios".

### Tarea 2.2: `rubocop-rails`

**Archivos:** `Gemfile.tt`, `.rubocop.yml`, y los archivos de `app/` o `spec/` con ofensas que se puedan corregir con seguridad.

`Gemfile.tt`, grupo `:development`, después de `rubocop`:

```ruby
  gem "rubocop", "~> 1.92", require: false
  gem "rubocop-rails", require: false
```

`.rubocop.yml`, al principio (con RuboCop 1.92 es `plugins:`, no `require:`), y `Metrics/BlockLength` al final:

```yaml
plugins:
  - rubocop-rails

inherit_from: .rubocop_todo.yml
```

```yaml
Metrics/BlockLength:
  Exclude:
    - "spec/**/*_spec.rb"
```

- [x] Haz los cambios y corre el ciclo de verificación.
- [x] Lee el `.rubocop_todo.yml` de la app generada y compáralo con el de la línea base. En los otros repos salieron `Rails/ApplicationController` (la API hereda de `ActionController::Base` a propósito), `HasManyOrHasOneDependent`, `InverseOf`, `UniqueValidationWithoutIndex`, `SkipsModelValidations`, `TimeZone`, `RedundantForeignKey`, `Delegate`, `Presence`. Ninguna era una deprecation de Rails 8.
- [x] Corrige en la fuente de la plantilla solo las que no cambian comportamiento (`RedundantForeignKey`, `Delegate`, `Presence`), en un commit aparte, comprobando con `bin/rails runner` en la app generada que el resultado es igual. `Rails/TimeZone` **no** es segura por defecto (ver postlane: `Time.parse` vs `Time.zone.parse` cambia la zona y el comportamiento con valores inválidos). Las que cambian comportamiento se quedan en el todo que genera `template.rb`.
- [x] No hubo autocorrecciones: ninguna ofensa de rubocop-rails era segura. Antes de mostrar los cambios, explica al usuario cada autocorrección (cashflow lo pidió así).
- [x] Commit: "Agrega rubocop-rails a la plantilla". Si hubo correcciones: "Corrige las ofensas seguras de rubocop-rails" antes.

### Tarea 2.3: Suite con deprecations como error (sin commit)

- [x] En la app generada de la tarea 2.2, cambia `config.active_support.deprecation = :stderr` por `:raise` en `config/environments/test.rb` y corre `bundle exec rspec`.
- [x] Anota el resultado. Si sale alguna deprecation, arréglala en la fuente de la plantilla en una tarea nueva de esta etapa. En los cinco repos salieron 0.

---

## Etapa 3: Bootstrap 5.2.3 → 5.3.8

### Tarea 3.1: Subir Bootstrap

**Archivo:** `Gemfile.tt`

```ruby
gem "bootstrap", "~> 5.3.8"
```

La 5.3 ya no depende de `sassc-rails` ni de `autoprefixer-rails`, así que salen `execjs` y la necesidad de `node`.

- [x] Haz el cambio y corre el ciclo de verificación.
- [x] En el `Gemfile.lock` de la app generada: `bootstrap (5.3.8)` y no aparecen `autoprefixer-rails` ni `execjs`.
- [x] Precompila en modo producción y comprueba la versión: `grep -o "Bootstrap  *v[0-9.]*" public/assets/application-*.css`.
- [ ] **No hecho (no hubo capturas):** Capturas (si se tomaron en la etapa 0) o revisión en el navegador de `/users/sign_in`, `/dashboard` y la landing. Cambios esperados que ya aprobó el usuario en los otros repos: `bg-body-tertiary` empieza a pintar `#f8f9fa` en el login (`layouts/login.html.erb`) y en el sidebar/offcanvas (`shared/_sidebar.html.erb`). No hay `<tr style="background-color">` ni modo oscuro en la plantilla, así que no aplican las regresiones de cashflow y coshinotes. Lee colores con `getComputedStyle` si algo se ve distinto.
- [ ] **No hecho:** Muestra las capturas al usuario antes del commit.
- [x] Commit: "Sube Bootstrap a 5.3.8".

### Tarea 3.2: Quitar `node` del deploy y de los requisitos

**Archivos:** `scripts/003_after_deploy.sh`, `README.md`, `README.md.tt`, `CLAUDE.md`

- [x] Borra el bloque `# CHECK node en /usr/local/bin/node` completo de `scripts/003_after_deploy.sh` (del comentario hasta `/usr/local/bin/node --version ...`).
- [x] `README.md` línea 13: borra el requisito de Node 22.14.0. `README.md.tt` línea 22: borra `- NodeJS en el servidor de producción, en /usr/local/bin/node`.
- [x] `CLAUDE.md`: "Bootstrap 5.2 pinned" → "Bootstrap 5.3".
- [x] `bash -n scripts/003_after_deploy.sh`. `grep -rni "node" README.md README.md.tt scripts/` no debe nombrar el binario de Node.
- [x] Commits: "Quita la comprobación de node del deploy" y "Quita NodeJS de los requisitos del README".

---

## Etapa 4: `sass-rails` → `dartsass-sprockets`

### Tarea 4.1: Spec de humo de las hojas de estilo (antes del cambio)

**Archivos:** `spec/assets/stylesheets_spec.rb` (nuevo), `template.rb` (`configure_rspec`)

Pasa con libsass y con Dart Sass, así que va en su propio commit antes del cambio. Los valores esperados del hover salen de enlacito, que tiene la misma `landing.scss` (`darken(#0d5ba8, 10%)` y `darken(#6b7280, 15%)`): confírmalos con la línea base antes de fijarlos.

```ruby
require "rails_helper"

RSpec.describe "Hojas de estilo" do
  it "compila Bootstrap y los estilos propios en application.css" do
    css = Rails.application.assets.find_asset("application.css").to_s

    expect(css).to include(".btn")
    expect(css).to include(".sidebar")
    expect(css).to include(".content-container")
  end

  it "compila Bootstrap y los estilos propios en login.css" do
    css = Rails.application.assets.find_asset("login.css").to_s

    expect(css).to include(".btn")
    expect(css).to include(".form-signin")
  end

  # libsass redondea los colores a hex (#094179) y Dart Sass los deja con decimales
  # (rgb(3.66%, 25.63%, 47.32%)), así que se comparan los canales redondeados a 0-255.
  it "mantiene los colores de hover de la landing" do
    css = Rails.application.assets.find_asset("landing.css").to_s

    button_hover = css[/\.btn-primary-custom:hover\s*\{[^}]*\}/]
    footer_hover = css[/\.footer-link:hover\s*\{[^}]*\}/]

    expect(rgb_channels(button_hover)).to eq([9, 65, 121])
    expect(rgb_channels(footer_hover)).to eq([72, 77, 86])
  end

  def rgb_channels(rule)
    hex = rule[/#(\h{6})\b/, 1]
    return hex.scan(/../).map { |channel| channel.to_i(16) } if hex

    rule[/rgb\(([^)]*)\)/, 1].split(/[\s,]+/).map { |channel| (channel.to_f * 255 / 100).round }
  end
end
```

En `configure_rspec` de `template.rb`, junto a los demás `directory`:

```ruby
  directory "spec/assets", force: true
```

- [x] Si `landing.css` no está en la lista de precompilación de la app generada y `find_asset` devuelve `nil`, revisa cómo la carga `layouts/landing.html.erb` y ajusta el spec, no la app.
- [x] Ciclo de verificación: el spec pasa con `sass-rails`.
- [x] Commit: "Agrega spec de humo de las hojas de estilo".

### Tarea 4.2: Cambiar a `dartsass-sprockets`

**Archivos:** `Gemfile.tt`, `template.rb`, `app/assets/stylesheets/landing.scss`, `README.md`

`Gemfile.tt`: `gem "sass-rails", ">= 6"` → `gem "dartsass-sprockets", "~> 3.2"` (mantén el orden alfabético: va después de `blueprinter`/`bootstrap`... ponla donde corresponda).

`template.rb`, nuevo método llamado en `after_bundle` justo después de `set_application_name`:

```ruby
def silence_dart_sass_warnings
  # Dart Sass: no mostrar los avisos que genera Bootstrap 5.3 (@import y funciones globales)
  add_app_config "config.sass.quiet_deps = true"
  add_app_config 'config.sass.silence_deprecations = ["import"]'
end
```

`landing.scss`: primera línea `@use "sass:color";` y los dos `darken()`:

```scss
@use "sass:color";
@import "bootstrap";
```

```scss
    background-color: color.adjust($primary-blue, $lightness: -10%);
```

```scss
    color: color.adjust($text-gray, $lightness: -15%);
```

Va en el mismo commit que la gema: libsass no entiende `@use`.

- [x] Haz los cambios y corre el ciclo de verificación (el spec de la 4.1 sigue pasando).
- [x] En el `Gemfile.lock` de la app generada: están `dartsass-sprockets`, `sassc-embedded` y `sass-embedded` con variante `x86_64-linux-gnu` (`template.rb` ya hace `bundle lock --add-platform x86_64-linux`); no están `sassc`, `sassc-rails`, `sass-rails` ni `ffi`. Revisa si `sprockets`/`sprockets-rails` subieron respecto a la línea base y anótalo (en cashflow y coshinotes subieron; en los demás no).
- [x] `assets:precompile` en modo producción sale **sin avisos** de Dart Sass. Si `config.assets.css_compressor = :sass` aparece en `production.rb`, sigue funcionando.
- [x] `README.md`: en la lista de gemas, `sass-rails` → `dartsass-sprockets` (con su enlace, `https://github.com/tablecheck/dartsass-sprockets`).
- [x] Commit: "Cambia sass-rails por dartsass-sprockets".

---

## Etapa 5: `annotate` → `annotaterb`

### Tarea 5.1: Cambiar la gema y su configuración

`annotate` es el único blocker del preflight en los cinco repos.

**Archivos:** `Gemfile.tt`, `lib/tasks/auto_annotate_models.rake` (borrar), `lib/tasks/annotate_rb.rake` (nuevo), `.annotaterb.yml` (nuevo), `template.rb`, `README.md`

- [x] `Gemfile.tt`: `gem "annotate", "~> 3"` → `gem "annotaterb", "~> 4.25"`.
- [x] `git rm lib/tasks/auto_annotate_models.rake`.
- [x] Copia `../postlane-backend/lib/tasks/annotate_rb.rake` tal cual a `lib/tasks/annotate_rb.rake`.
- [x] Copia `../postlane-backend/.annotaterb.yml` a `.annotaterb.yml` y cambia `:ignore_multi_database_name: false` → `:ignore_multi_database_name: true` (la app generada tiene `primary`, `queue` y `cable` en desarrollo; sin esto agrega `# Database name: primary` a todos los modelos). Las claves llevan dos puntos (`:position_in_class: after`).
- [x] `template.rb`, en `copy_templates`: `copy_file "lib/tasks/auto_annotate_models.rake"` → 
  ```ruby
  copy_file "lib/tasks/annotate_rb.rake"
  copy_file ".annotaterb.yml"
  ```
- [x] `README.md`: en la lista de gemas, `annotate` → `annotaterb` (`https://github.com/drwl/annotaterb`).
- [x] Ciclo de verificación. Luego, en la app generada:
  - `bundle exec annotaterb models --frozen` → "Model files unchanged." con exit 0. Si falla, corre `annotaterb models`, mira `git diff app/models` (inicializa git en la app con `git init && git add . && git commit -qm base` antes) y corrige las anotaciones de `app/models/*.rb` **de la plantilla** en un commit aparte, antes de este (en supermenu y postlane falló por el orden de `role_id` en `membership.rb` y `owner_id` en `organization.rb`).
  - `RAILS_ENV=production SECRET_KEY_BASE=dummy bundle exec rake -T` arranca sin la gema.
- [x] Commit (todo junto, porque el rake viejo hace `require "annotate"`): "Cambia annotate por annotaterb".

---

## Etapa 6: Páginas de error

### Tarea 6.1: `exception_handler` en test y spec de las páginas de error

**Archivos:** `template.rb` (`setup_exception_handler`), `spec/requests/error_pages_spec.rb` (nuevo)

En test, `exception_handler` no tiene configuración y renderiza el layout `application` (pasó en coshinotes, enlacito y supermenu). En `setup_exception_handler`, después del bloque de producción:

```ruby
  environment(production_exception_handler, env: "test")
```

Spec (lo copia `directory "spec/requests"`, que ya existe en `configure_rspec`):

```ruby
require "rails_helper"

RSpec.describe "Páginas de error", type: :request do
  # En test las excepciones no se muestran como página de error: se activan solo en este ejemplo.
  it "muestra la página 404 propia para una ruta inexistente" do
    env_config = Rails.application.env_config
    original = env_config.slice("action_dispatch.show_exceptions", "action_dispatch.show_detailed_exceptions")
    env_config["action_dispatch.show_exceptions"] = :all
    env_config["action_dispatch.show_detailed_exceptions"] = false

    get("/ruta/que/no/existe")

    expect(response).to have_http_status(:not_found)
    expect(response.body).to include("La página que buscas, no existe")
    expect(response.body).not_to include("sidebarMenu")
  ensure
    env_config.merge!(original)
  end

  it "renderiza el layout 5xx sin errores" do
    html = ApplicationController.render(html: "", layout: "5xx")

    expect(html).to include("Pasó algo que no se supone que pasara.")
  end
end
```

- [x] Ciclo de verificación: `config/environments/test.rb` de la app generada tiene `config.exception_handler` y el spec pasa. (No se hizo la comprobación inversa de quitar la línea de `env: "test"`.)
- [x] Para probar el 404 en desarrollo hace falta `dev: true` en `config.exception_handler` además de `consider_all_requests_local = false` (coshinotes). No lo cambies en la plantilla; es solo para probar a mano.
- [x] Commit: "Configura exception_handler en test y agrega spec de las páginas de error".

### Tarea 6.2: Borrar `shared/_navbar.html.erb`

Nadie la renderiza (`grep -rn "shared/navbar" app` no da nada), usa clases de Bootstrap 4 (`data-toggle`, `mr-auto`, `dropdown-menu-right`) y llama a `avatar_path`, que no existe.

- [x] Confirma con el usuario antes de borrarla.
- [x] `git rm app/views/shared/_navbar.html.erb`. Revisa que `README.md` ("navbar, sidebar y footer") siga siendo cierto: la navbar de la app está en `layouts/application.html.erb`; si no hay navbar, ajusta la frase.
- [x] Ciclo de verificación.
- [x] Commit: "Borra shared/_navbar.html.erb".

---

## Etapa 7: SQLite sin `host` ni `encoding`

### Tarea 7.1: Limpiar `database.yml` y fijarlo con un spec

`host: localhost` y `encoding: unicode` son de PostgreSQL; el adaptador de SQLite los ignora. supermenu y postlane los quitaron.

**Archivos:** `config/database.yml`, `spec/config/database_config_spec.rb` (nuevo), `template.rb`

- [x] Borra `host: localhost` y `encoding: unicode` de `&default`.
- [x] Spec:
  ```ruby
  require "rails_helper"

  RSpec.describe "config/database.yml" do
    it "usa timeout y no retries para el lock de SQLite" do
      config = ActiveRecord::Base.connection_db_config.configuration_hash

      expect(config[:timeout]).to eq(5000)
      expect(config).not_to have_key(:retries)
      expect(config).not_to have_key(:host)
      expect(config).not_to have_key(:encoding)
    end
  end
  ```
- [x] `configure_rspec`: `directory "spec/config", force: true`.
- [x] Ciclo de verificación. Además, para todos los entornos y bases:
  ```bash
  bin/rails runner 'Rails.application.config.database_configuration.each { |env, cfg| cfg = { "default" => cfg } if cfg.key?("adapter"); cfg.each { |name, h| puts "#{env} #{name}: timeout=#{h["timeout"].inspect} host=#{h["host"].inspect} encoding=#{h["encoding"].inspect}" } }'
  ```
- [x] `bin/jobs start --mode async` arranca en la app generada (Ctrl+C / `kill` después de ver el supervisor).
- [x] Commit (spec y cambio juntos, porque el spec falla sin el cambio): "Quita host y encoding de la configuración de SQLite".

---

## Etapa 8: Hallazgos de seguridad y configuración

### Tarea 8.1: Generar las apps sin Active Storage, Action Mailbox ni Action Text

El 18 oct 2026 un escáner subió un exploit a postlane por `POST /rails/active_storage/direct_uploads`, abierto sin autenticación (detalle en `../docs/incidente-2026-10-18-postlane-active-storage.md`). cashflow y enlacito tienen el mismo hueco. Las apps de la plantilla no usan Active Storage, pero `template.rb` lo instala (`active_storage_setup`).

**Archivos:** `template.rb`, `config/storage.yml` (borrar), `README.md`, `CLAUDE.md`, `spec/routing/rails_frameworks_routes_spec.rb` (nuevo)

- [x] Confirma con el usuario que la plantilla deja de instalar Active Storage (una app que lo necesite lo instala y protege `direct_uploads` con sesión, como coshinotes y supermenu).
- [x] `template.rb`: borra `active_storage_setup` y su llamada en `after_bundle`. Agrega `directory "spec/routing", force: true` en `configure_rspec`.
- [x] `git rm config/storage.yml`. Deja `storage/.keep` solo si algo lo usa (`grep -rn "storage/" scripts config template.rb`); si no, bórralo también.
- [x] `README.md` y `README.md.tt`: todos los `rails _7.2.3.1_ new ...` llevan `--skip-active-storage --skip-action-mailbox --skip-action-text` (Action Mailbox y Action Text dependen de Active Storage). Cambia "Active Storage instalado" por una línea que diga que no se instala y por qué. `CLAUDE.md`: el comando de uso con los mismos flags.
- [x] Spec de postlane (`../postlane-backend/spec/routing/rails_frameworks_routes_spec.rb`) copiado tal cual, con el comentario del incidente.
- [x] Ciclo de verificación con los flags nuevos: el spec pasa y `config/environments/*.rb` no tiene `config.active_storage.service`.
- [x] **Enfoque de revisión 1:** genera otra app **sin** los flags y comprueba que el spec de rutas falla. Anota el resultado en el PR.
- [x] Commit: "Genera las apps sin Active Storage, Action Mailbox ni Action Text".

### Tarea 8.2: Sentry lee `SENTRY_DSN`

**Archivo:** `config/initializers/sentry.rb`, `README.md`

`config.dsn = ""` pisa la variable `SENTRY_DSN`, así que Sentry no recibe nada en producción (postlane).

```ruby
  config.dsn = ENV.fetch("SENTRY_DSN", nil)
```

- [x] Cambia el initializer. `README.md`: quita la fila de `sentry.rb` de "Valores que debes cambiar" y agrega `SENTRY_DSN` a "Variables de entorno". Agrégala también a `scripts/.puntapie.envs` con valor `CHANGEME`.
- [x] En la app generada: `SENTRY_DSN=https://k@o0.ingest.sentry.io/0 RAILS_ENV=production SECRET_KEY_BASE=dummy bin/rails runner 'puts Sentry.configuration.dsn.to_s'` imprime el DSN.
- [x] Commit: "Lee el DSN de Sentry de SENTRY_DSN".

### Tarea 8.3: `namespace "api", defaults:` (opcional, confirmar con el usuario)

`namespace "api", default: { format: "json" }` agrega un parámetro de ruta llamado `default`, no un formato por defecto. Lo que se quiso fue `defaults:`. Cambiarlo puede alterar cómo responden Devise y los controladores de la API (por ejemplo, la failure app de Devise con `format: json`).

- [x] Pregunta al usuario si lo incluye en este plan. Si no, anótalo en el resumen como pendiente.
- [x] Si sí: cambia a `defaults: { format: "json" }`, corre `spec/requests/api/v1/users/sessions_spec.rb` y agrega un routing spec que compruebe `Rails.application.routes.recognize_path("/api/v1/users/sign_in", method: :post)[:format] == "json"`.
- [x] Commit: "Usa defaults en vez de default en el namespace de la API".

---

## Etapa 9: Cierre

### Tarea 9.1: Prueba de resolución con Rails 8.0 y documentación

- [x] Genera la app final (`$S/pruebapie-final`) y corre el ciclo de verificación completo, incluida la suite con `deprecation = :raise`.
- [x] Prueba de resolución en una copia, sin tocar la app:
  ```bash
  D=$S/rails8-dryrun && rm -rf $D && mkdir -p $D && cp $S/pruebapie-final/Gemfile $S/pruebapie-final/Gemfile.lock $D/
  sed -i "" "s/^gem \"rails\", .*/gem \"rails\", \"~> 8.0.0\"/" $D/Gemfile
  (cd $D && BUNDLE_GEMFILE=$D/Gemfile bundle lock --conservative --update rails)
  diff <(grep -E "^    [a-z]" $S/pruebapie-final/Gemfile.lock) <(grep -E "^    [a-z]" $D/Gemfile.lock)
  ```
  En los cinco repos resolvió con Rails 8.0.5.1 y solo salió `cgi` y entró `uri`. Anota lo que salga aquí.
- [ ] **Pendiente (usuario):** Pide al usuario el reporte `02.rails_preflight_report.html` sobre `$S/pruebapie-final` (no se commitea).
- [x] Revisa que `README.md`, `README.md.tt` y `CLAUDE.md` no nombren `sass-rails`, `annotate`, `auto_annotate_models`, Node ni Active Storage instalado. Ajusta en un commit si hace falta.
- [x] Escribe `docs/plans/rails-upgrades/resumen_ejecucion_preparar_rails_8.md` con el mismo formato que los de los repos hermanos (estado por etapa, lo que salió distinto, pendientes). **No se commitea.**

---

## Pendientes para el plan del salto a Rails 8.0 (no van en este plan)

- `gem "rails", "~> 8.0"` en `Gemfile.tt`; `ActiveRecord::Migration[7.2]` → `[8.0]` en las migraciones de `template.rb`; `rails _8.0.x_ new` en README; revisar qué genera `rails new` en 8.0 que choque con lo que copia la plantilla (`config/database.yml`, `cache.yml`, `cable.yml`, `queue.yml`, `bin/jobs`, `puma.rb`, el `solid_*:install` que en 8.0 ya viene hecho).
- Borrar `config/initializers/sqlite3_busy_handler_timeout.rb` y su `copy_file` (Rails 8 ya usa `busy_handler_timeout`).
- `exception_handler 0.8.0.2` (sin release desde 8.0): correr `error_pages_spec.rb`. Plan B: `config.exceptions_app = routes` + `ErrorsController` propio.
- `config.responder.error_status`: comprobar que el `devise.rb` que genera Devise 5 ya trae `:unprocessable_content` (postlane lo tiene).
- `selenium-webdriver 4.16.0` (2023) y `capybara 3.39.2`: subir o quitar. La plantilla no tiene system specs; `spec/support/capybara_setup.rb` es lo único que los usa.
- Comentario de `json ~> 2.19` en `Gemfile.tt` ("json 3.x rompe Rails 7.2"): revisar si sigue aplicando en 8.0.
- `sprockets-rails` y `stimulus-rails`: sin cambio. Propshaft queda fuera.

## Encontrado fuera del plan (sin tocar)

- **Puma corre como root** en los cinco repos: `scripts/puntapie.puma.service` no tiene `User=` y es un servicio de sistema (`multi-user.target`). Cambiarlo afecta al deploy (`004_application_start.sh`) y a los permisos de `log/` y `db/`; necesita su propio plan probado en un servidor.
- `scripts/puntapie.jobs.service` usa `/home/ubuntu/PUNTAPIE/app` y `.PUNTAPIE.envs` en mayúsculas, y `003_after_deploy.sh` y `004_application_start.sh` leen `/home/ubuntu/.PUNTAPIE.envs`, mientras `puntapie.puma.service` y el README usan `.puntapie.envs`. Revisar si `bin/setup-project-name` lo normaliza.
