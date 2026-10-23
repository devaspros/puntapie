# Actualizar las vistas de Devise Plan de Implementación

> **Estado: COMPLETADO (23 oct 2026).** Etapas 0 a 4 en `master`, un commit por etapa. Línea base 40 ejemplos → 60, 0 fallos; RuboCop sin ofensas nuevas. Desvíos: se agregó `config/initializers/field_error_proc.rb` (el `field_with_errors` de Rails rompía los form-floating) y `_password_visibility.scss` (espacio del ojo e ícono de error) en vez del `style` en línea; los textos del footer y del sidebar también pasaron a YAML. Los correos de Devise (`mailer/*`) siguen fuera del alcance. Los specs de sistema con JS no corren en las apps generadas (Capybara 3.39.2 con Rack 3: `uninitialized constant Rack::Handler`); el navegador se revisó con Selenium contra `bin/rails s`.

> **Para trabajadores agénticos:** SUB-HABILIDAD REQUERIDA: Usa superpowers:subagent-driven-development (recomendado) o superpowers:executing-plans para implementar este plan tarea por tarea. Los pasos usan casillas de verificación (`- [ ]`) para el seguimiento.

**Objetivo:** Que las apps generadas con Puntapie nazcan con las pantallas de autenticación (login, registro, reenviar confirmación, recuperar contraseña y Mi cuenta) en español, con Bootstrap 5 y al nivel de enlacito y supermenu.

**Arquitectura:** Puntapie es `template.rb` más los archivos que copia. `directory "app", force: true` copia todo `app/`, pero de `config/locales/` solo se copian los archivos que `set_locales` nombra con `copy_file`, así que cada YAML nuevo necesita su línea ahí. Las vistas toman los textos de YAML con búsqueda perezosa (`t(".title")` en `devise/sessions/new` busca `es.devise.sessions.new.title`). El botón del ojo pasa del `onclick` en línea a un controlador de Stimulus.

**Stack Tecnológico:** Rails 7.2.3.1, Ruby 3.4.8, Devise 5.0.x, Bootstrap 5.3 (Sprockets + dartsass), Bootstrap Icons por CDN, Stimulus con importmap, RSpec + FactoryBot.

**Especificación:** el reporte de `/revisa` de esta sesión más las anotaciones del usuario:

- Mínimo de contraseña: 10 caracteres.
- Traer el layout `login` (barra con la marca y el botón "Iniciar sesión" o "Regístrate", y el footer).
- Traer `login.scss`.
- `registrations/edit` con el layout de supermenu (`application` para `edit`/`update` y `login` para lo demás).
- Textos en YAML; si un texto no existe en los proyectos fuente, se adapta.
- Botón del ojo con Stimulus.
- Borrar `unlocks`.

Fuentes de las vistas: `../supermenu/app/views/devise/registrations/{new,edit}.html.erb`, `../supermenu/app/views/devise/confirmations/new.html.erb`, `../enlacito/app/views/devise/sessions/new.html.erb`, `../enlacito/app/views/layouts/login.html.erb`, `../supermenu/app/assets/stylesheets/login.scss`, `../supermenu/app/controllers/users/registrations_controller.rb` y `../supermenu/spec/requests/users/*.rb`.

## Restricciones Globales

- Todos los textos visibles de las vistas de `app/views/devise/**` y del layout `login` salen de YAML. No quedan cadenas en español fijas en el ERB.
- Los textos de las vistas van en `config/locales/views.es.yml` (nuevo). Los nombres de modelo y atributos van en `config/locales/models.es.yml` (nuevo). La raíz de los dos es `es:`, porque `default_locale` es `:es`.
- `config.password_length = 10..128`. La ayuda "Mínimo 10 caracteres" se arma con `@minimum_password_length` cuando la vista lo tiene, para que no vuelva a desalinearse de la configuración.
- La marca en el layout `login` es la clave `shared.brand: Puntapie`. `bin/setup-project-name` reemplaza "Puntapie" en el contenido de los archivos, igual que en `layouts/application` y `shared/_sidebar`.
- Nada de `onclick` ni JavaScript en línea en las vistas.
- ERB poco apiñado: línea en blanco entre elementos hermanos, sin línea en blanco justo después de abrir una etiqueta, y el `>` de cierre en su propia línea cuando los atributos ocupan varias líneas.
- Specs de request autocontenidos dentro de cada `it` (four-phase de Thoughtbot), sin comentarios `# Setup/# Exercise/# Verify`. Los argumentos van entre paréntesis.
- RuboCop: 130 caracteres y comillas dobles.
- **Nada de `docs/` entra en ningún commit.** Usa `git add <rutas>` explícitas y revisa `git show --stat HEAD`.
- Commits en `master`, uno por etapa, en español y en imperativo. Pide confirmación al terminar cada etapa, con una sola pregunta directa.

## Ciclo de verificación (se usa en todas las tareas)

Igual que en `docs/plans/2026-10-23-preparar-rails-8.md`: la app se genera desde el archivo local, en el scratchpad (`$S`).

```bash
APP=$S/pruebapie-devise-X
rm -rf $APP
SKIP_GIT=1 rails _7.2.3.1_ new $APP -d sqlite3 --skip-test --skip-active-storage --skip-action-mailbox --skip-action-text -m ./template.rb 2>&1 | tail -40

cd $APP
bundle exec rails db:prepare setup:run
bundle exec rspec
bundle exec rubocop
```

- Para iterar rápido dentro de una tarea, edita los archivos directamente en `$APP`, corre el spec y luego copia el cambio a Puntapie. Cada etapa termina regenerando la app desde cero.
- Revisión en el navegador: `bin/rails s -p 3055` en `$APP`. Mátalo al terminar con `lsof -ti tcp:3055 | xargs kill`.

## Enfoque de Revisión

1. **Registro con datos inválidos** (contraseña de 9 caracteres o correo ya usado): responde 422 (Turbo no pinta otra cosa), conserva lo escrito y muestra el error en español debajo del campo. Se cubre en la tarea 3.2.
2. **Login de un usuario sin confirmar:** recibe el aviso en español "Tienes que confirmar tu cuenta…" y ve el enlace para reenviar la confirmación. Se cubre en la tarea 3.1.
3. **Reenviar confirmación con un correo que no existe:** responde 422 con "Correo no encontrado", en español y con el nombre del atributo traducido. Se cubre en la tarea 3.3.
4. **Mi cuenta con la contraseña actual equivocada:** responde 422, muestra "Contraseña actual no es correcta" dentro del panel (con el sidebar) y la contraseña no cambia. Se cubre en la tarea 3.4.
5. **Las pantallas de autenticación cargan el JavaScript:** sin importmap no corren los toasts de los avisos ni el ojo. Cada pantalla debe incluir `<script type="importmap"` y el `data-controller="password-visibility"` donde haya contraseña. Se cubre en las tareas 1.3 y 2.1.

---

## Etapa 0: Línea base

### Tarea 0.1: Generar la app y registrar números

- [ ] `git status` limpio en `master`.
- [ ] Corre el ciclo con `APP=$S/pruebapie-devise-base`. Anota cuántos ejemplos y fallos da `rspec`.
- [ ] Confirma que hoy `GET /users/edit` falla (`avatar_path` no existe). Inicia sesión con `frajaquico@aol.com` / `clave-de-puntapie-2026` en `bin/rails s -p 3055` y abre `/users/edit`. Anota el error.

No hay commit en esta etapa.

---

## Etapa 1: Base (configuración, YAML, Stimulus)

### Tarea 1.1: Mínimo de contraseña de 10 caracteres

**Archivos:** `template.rb`, `spec/models/user_spec.rb`

En `add_users`, después del `gsub_file` de `confirm_within`:

```ruby
  gsub_file "config/initializers/devise.rb",
            "config.password_length = 6..128",
            "config.password_length = 10..128"
```

La línea sale de `devise-5.0.x/lib/generators/templates/devise.rb:184` sin comentar.

Spec nuevo en `spec/models/user_spec.rb`:

```ruby
  it "exige una contraseña de al menos 10 caracteres" do
    user = build(:user, password: "123456789")

    user.valid?

    expect(user.errors[:password]).to include("es demasiado corta (mínimo 10 caracteres)")
  end
```

El mensaje en femenino sale de `models.es.yml` (tarea 1.2). Si haces esta tarea antes que la 1.2, el spec da "es demasiado corto". Haz las dos en orden y corre el spec al final de la 1.2.

- [ ] Agrega el `gsub_file` y el spec.
- [ ] En la app generada: `grep -n "password_length" config/initializers/devise.rb` muestra `10..128`. Si sigue en `6..128`, el texto del `gsub_file` no coincidió (Thor solo imprime un aviso).
- [ ] `grep -rn "password" lib/tasks spec/factories` muestra que ninguna contraseña sembrada tiene menos de 10 caracteres (hoy: `clave-de-puntapie-2026` y `password123`).

### Tarea 1.2: Archivos YAML de vistas y modelos

**Archivos:** `config/locales/views.es.yml` (nuevo), `config/locales/models.es.yml` (nuevo), `template.rb`, `spec/support/devise_testing_helpers.rb`

`config/locales/models.es.yml` (adaptado de `../supermenu/config/locales/models.es.yml`):

```yaml
es:
  activerecord:
    errors:
      models:
        user:
          attributes:
            password:
              too_short: es demasiado corta (mínimo %{count} caracteres)
            current_password:
              invalid: no es correcta

    models:
      user:
        one: Usuario
        other: Usuarios

    attributes:
      user:
        first_name: Nombre
        last_name: Apellido
        email: Correo
        password: Contraseña
        password_confirmation: Confirmar contraseña
        current_password: Contraseña actual
        remember_me: Recuérdame
```

`config/locales/views.es.yml` empieza solo con lo que comparten las pantallas. Cada tarea de las etapas 2 y 3 agrega sus claves bajo `devise:`.

```yaml
es:
  shared:
    brand: Puntapie

    password_visibility:
      toggle: Mostrar u ocultar la contraseña

    password_hint: "Mínimo %{count} caracteres"
```

En `set_locales` de `template.rb`:

```ruby
  copy_file "config/locales/devise.es.yml", force: true
  copy_file "config/locales/es-CO.yml", force: true
  copy_file "config/locales/models.es.yml", force: true
  copy_file "config/locales/views.es.yml", force: true
```

En `spec/support/devise_testing_helpers.rb` agrega la línea para que los specs de request puedan usar `sign_in`:

```ruby
RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :system
  config.include Devise::Test::IntegrationHelpers, type: :request
end
```

- [ ] Crea los archivos y agrega las líneas.
- [ ] Spec en `spec/models/user_spec.rb`:

  ```ruby
  it "traduce los atributos de autenticación" do
    label = User.human_attribute_name(:current_password)

    expect(label).to eq("Contraseña actual")
  end
  ```

- [ ] Ciclo de verificación: los dos YAML existen en la app generada y pasan los specs de las tareas 1.1 y 1.2.

### Tarea 1.3: Controlador Stimulus del ojo y su primer uso en recuperar contraseña

**Archivos:** `app/javascript/controllers/password_visibility_controller.js` (nuevo), `app/views/devise/shared/_password_toggle.html.erb` (nuevo), `app/views/devise/passwords/new.html.erb`, `app/views/devise/passwords/edit.html.erb`, `config/locales/views.es.yml`, `spec/requests/users/passwords_spec.rb` (nuevo)

`rails new` crea `app/javascript/controllers/index.js` con `eagerLoadControllersFrom`, y `config/importmap.rb` ya tiene `pin_all_from "app/javascript/controllers"`. El controlador se registra solo, con el mismo estilo de `toast_controller.js`:

```js
import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="password-visibility"
export default class extends Controller {
  static targets = ["input", "icon"];

  toggle() {
    const hidden = this.inputTarget.type === "password";

    this.inputTarget.type = hidden ? "text" : "password";
    this.iconTarget.classList.toggle("bi-eye", !hidden);
    this.iconTarget.classList.toggle("bi-eye-slash", hidden);
  }
}
```

Partial `devise/shared/_password_toggle.html.erb`, que es solo el botón:

```erb
<button type="button"
        class="btn position-absolute end-0 top-50 translate-middle-y me-2 border-0 bg-transparent p-0"
        aria-label="<%= t("shared.password_visibility.toggle") %>"
        data-action="password-visibility#toggle"
>
  <i class="bi bi-eye"
     data-password-visibility-target="icon"
  >
  </i>
</button>
```

Forma de cada campo de contraseña en todas las vistas. Así queda el de `passwords/edit`:

```erb
<div class="form-floating mb-3 position-relative"
     data-controller="password-visibility"
>
  <%= f.password_field :password,
      autofocus: true,
      autocomplete: "new-password",
      class: "form-control",
      placeholder: t(".password"),
      style: "padding-right: 2.5rem;",
      data: { password_visibility_target: "input" } %>

  <%= f.label :password, t(".password") %>

  <%= render "devise/shared/password_toggle" %>

  <small class="text-muted ms-1">
    <%= t("shared.password_hint", count: @minimum_password_length) %>
  </small>
</div>
```

`Devise::PasswordsController#edit` y `#update` definen `@minimum_password_length`. `RegistrationsController#new` también.

Pasa los textos de `passwords/new` y `passwords/edit` a YAML (los textos actuales, sin cambiarlos):

```yaml
  devise:
    passwords:
      new:
        title: ¿Olvidaste tu contraseña?
        subtitle: Te enviaremos un correo con las instrucciones para restablecerla.
        email: Correo
        submit: Enviar instrucciones
        back_to_sign_in: Volver a iniciar sesión

      edit:
        title: Crear nueva contraseña
        password: Nueva contraseña
        password_confirmation: Confirmar contraseña
        submit: Guardar nueva contraseña
        back_to_sign_in: Volver a iniciar sesión
```

Ojo: `devise.es.yml` ya tiene `es.devise.passwords.send_instructions`, `updated`, etc. Las claves `new:` y `edit:` conviven con esas porque I18n mezcla los hashes de los dos archivos.

- [ ] Crea el controlador y el partial, y actualiza las dos vistas de `passwords`.
- [ ] Spec `spec/requests/users/passwords_spec.rb`:

  ```ruby
  require "rails_helper"

  RSpec.describe("Recuperar contraseña", type: :request) do
    it "muestra el ojo con Stimulus en la nueva contraseña" do
      user = create(:user, :confirmed)
      token = user.send_reset_password_instructions

      get(edit_user_password_path(reset_password_token: token))

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('data-controller="password-visibility"')
      expect(response.body).to include("Mínimo 10 caracteres")
      expect(response.body).not_to include("onclick")
    end

    it "rechaza una contraseña nueva de menos de 10 caracteres" do
      user = create(:user, :confirmed, password: "clave-segura-123")
      token = user.send_reset_password_instructions

      put(
        user_password_path,
        params: {
          user: {
            reset_password_token: token,
            password: "123456789",
            password_confirmation: "123456789"
          }
        }
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("es demasiado corta (mínimo 10 caracteres)")
      expect(user.reload.valid_password?("clave-segura-123")).to be(true)
    end

    it "pide las instrucciones en español" do
      get(new_user_password_path)

      expect(response.body).to include("¿Olvidaste tu contraseña?")
      expect(response.body).to include('<script type="importmap"')
    end
  end
  ```

- [ ] En el navegador, en `/users/password/edit?reset_password_token=…`, el ojo muestra y oculta la contraseña, y el icono cambia a `bi-eye-slash`.
- [ ] Commit de la etapa: "Exige contraseñas de 10 caracteres y prepara YAML y Stimulus para las vistas de Devise".

---

## Etapa 2: Layout `login` y `login.scss`

### Tarea 2.1: Layout `login` con su propio `<head>`, barra y footer

**Archivos:** `app/views/layouts/login.html.erb`, `app/views/shared/_head.html.erb`, `app/assets/stylesheets/login.scss`, `app/assets/stylesheets/_footer.scss` (nuevo), `app/assets/stylesheets/landing.scss`, `config/locales/views.es.yml`, `spec/requests/users/login_layout_spec.rb` (nuevo)

Hoy el layout `login` renderiza `shared/_head`. Ese partial elige entre `login` y `application` con `current_page?` ("no termina de funcionar del todo"), y después el layout vuelve a cargar `login`. En la pantalla de confirmación se cargan las dos hojas. El layout pasa a tener su propio `<head>`, como en enlacito y supermenu, y `_head` queda solo para `application`, `4xx` y `5xx`.

`shared/_head.html.erb`: cambia el bloque condicional (el comentario y el `if`) por:

```erb
<%= stylesheet_link_tag "application", media: "all" %>
```

`layouts/login.html.erb` (adaptado de `../enlacito/app/views/layouts/login.html.erb`, sin Umami, sin `general_price` y sin el selector de idioma):

```erb
<!DOCTYPE html>
<html lang="<%= I18n.locale %>">
  <head>
    <% title = Rails.env.development? ? "#{t('shared.brand')} - Dev" : t("shared.brand") %>
    <%= display_meta_tags(site: title, reverse: true) %>

    <meta charset="utf-8">

    <meta name="viewport" content="width=device-width, initial-scale=1, shrink-to-fit=no">

    <meta name="robots" content="noindex, follow">

    <%= csrf_meta_tags %>

    <%= csp_meta_tag %>

    <%= stylesheet_link_tag "login", media: "all" %>

    <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.12.1/font/bootstrap-icons.min.css">

    <%# Sin esto no corren los controladores toast ni password-visibility. %>
    <%= javascript_importmap_tags %>
  </head>

  <body class="d-flex flex-column min-vh-100 bg-body-tertiary">
    <nav class="navbar py-3 login-navbar">
      <div class="container">
        <span class="navbar-brand mb-0 h4 fw-bold">
          <%= link_to t("shared.brand"), root_path, class: "text-decoration-none text-body" %>
        </span>

        <% if current_page?(new_user_registration_path) %>
          <%= link_to t("layouts.login.sign_in"), new_user_session_path, class: "btn btn-outline-primary btn-sm" %>
        <% else %>
          <%= link_to t("layouts.login.sign_up"), new_user_registration_path, class: "btn btn-outline-primary btn-sm" %>
        <% end %>
      </div>
    </nav>

    <main class="form-signin w-100 m-auto">
      <%= render "shared/notices" %>

      <%= yield %>
    </main>

    <%= render "shared/footer" %>
  </body>
</html>
```

`body` es `flex-column` con `min-vh-100`, y el `m-auto` del `main` lo centra en vertical. Así el footer queda abajo en vez de flotar a mitad de pantalla.

YAML:

```yaml
  layouts:
    login:
      sign_in: Iniciar sesión
      sign_up: Regístrate
```

`shared/_footer.html.erb` usa clases (`landing-footer`, `footer-text`, `footer-link`) que hoy solo existen en `landing.scss`. Sácalas a `app/assets/stylesheets/_footer.scss`, con `@use "sass:color";` y las variables `$text-gray: #6b7280;` y `$border-gray: #e5e7eb;` locales. Impórtalo desde `landing.scss` (en el lugar del bloque `// Footer`, que se borra) y desde `login.scss`.

`login.scss` (base de `../supermenu/app/assets/stylesheets/login.scss` sin el naranja y sin el logo):

```scss
@import "bootstrap";
@import "footer";

.form-signin {
  max-width: 330px;
  padding: 1rem;
}

.form-signin .form-floating:focus-within {
  z-index: 2;
}

// Correo y contraseña pegados, solo en el login (en el registro van separados).
.form-signin-stacked {
  input[type="email"] {
    margin-bottom: -1px;
    border-bottom-right-radius: 0;
    border-bottom-left-radius: 0;
  }

  input[type="password"] {
    margin-bottom: 10px;
    border-top-left-radius: 0;
    border-top-right-radius: 0;
  }
}

.login-navbar {
  .container {
    flex-wrap: nowrap;
  }
}
```

Se va `html, body { height: 100%; }`, que ya cubre `min-vh-100`. Las reglas de bordes pegados pasan a `.form-signin-stacked`, una clase que solo pone el form de `sessions/new` (tarea 3.1). Sin ese cambio, el registro, la confirmación y la recuperación de contraseña quedan con esquinas rectas en los campos sueltos.

- [ ] Haz los cambios y agrega las claves `layouts.login.*`.
- [ ] Spec `spec/requests/users/login_layout_spec.rb`:

  ```ruby
  require "rails_helper"

  RSpec.describe("Layout de login", type: :request) do
    it "carga solo la hoja de login, el JavaScript y el footer" do
      get(new_user_session_path)

      expect(response.body).to include('<script type="importmap"')
      expect(response.body).to match(%r{/assets/login(-\h+)?\.css})
      expect(response.body).not_to match(%r{/assets/application(-\h+)?\.css})
      expect(response.body).to include(tos_path)
      expect(response.body).to include("Puntapie")
    end

    it "ofrece registrarse en el login e iniciar sesión en el registro" do
      get(new_user_session_path)
      sign_in_page = response.body

      get(new_user_registration_path)

      expect(sign_in_page).to include(%(href="#{new_user_registration_path}"))
      expect(response.body).to include(%(href="#{new_user_session_path}"))
    end
  end
  ```

- [ ] `spec/requests/error_pages_spec.rb` sigue en verde, porque `4xx`/`5xx` usan `_head`.
- [ ] Precompila en modo producción (ver el plan de Rails 8) para confirmar que `@import "footer"` resuelve en `landing` y en `login`.
- [ ] En el navegador, a 375 px y a 1280 px: la barra no se parte y el footer queda abajo.
- [ ] Commit: "Da al layout de login su propio head, barra y footer".

---

## Etapa 3: Vistas

### Tarea 3.1: Login (`sessions/new`)

**Archivos:** `app/views/devise/sessions/new.html.erb`, `config/locales/views.es.yml`, `spec/requests/users/sessions_spec.rb` (nuevo)

Base de `../enlacito/app/views/devise/sessions/new.html.erb` más el enlace de confirmación de supermenu. El form lleva `html: { class: "form-signin-stacked" }`. La contraseña usa el patrón de la tarea 1.3, sin la ayuda de mínimo. El `email_field` lleva `autocomplete: "email"` y el `password_field` lleva `autocomplete: "current-password"` (hoy dice `"off"`). Debajo del botón van tres párrafos `text-center`:

```erb
<p class="text-center mt-3 mb-1">
  <%= link_to t(".forgot_password"), new_user_password_path, class: "text-muted small" %>
</p>

<p class="text-center mb-1">
  <%= link_to t(".resend_confirmation"), new_user_confirmation_path, class: "text-muted small" %>
</p>

<p class="text-center mt-2">
  <%= t(".no_account") %>

  <%= link_to t(".sign_up"), new_user_registration_path, class: "text-muted small" %>
</p>
```

```yaml
    sessions:
      new:
        title: Iniciar sesión
        email: Correo
        password: Contraseña
        remember_me: Recuérdame
        submit: Iniciar sesión
        forgot_password: ¿Olvidaste tu contraseña?
        resend_confirmation: ¿No recibiste el correo de confirmación?
        no_account: ¿No tienes cuenta?
        sign_up: Regístrate
```

- [ ] Reescribe la vista.
- [ ] Spec `spec/requests/users/sessions_spec.rb`:

  ```ruby
  require "rails_helper"

  RSpec.describe("Inicio de sesión", type: :request) do
    it "inicia sesión con correo y contraseña" do
      user = create(:user, :confirmed, password: "clave-segura-123")

      post(user_session_path, params: { user: { email: user.email, password: "clave-segura-123" } })

      expect(response).to have_http_status(:see_other)
      expect(controller.current_user).to eq(user)
    end

    it "avisa en español al usuario sin confirmar y le ofrece reenviar la confirmación" do
      user = create(:user, password: "clave-segura-123")

      post(user_session_path, params: { user: { email: user.email, password: "clave-segura-123" } })
      follow_redirect!

      expect(response.body).to include("Tienes que confirmar tu cuenta antes de continuar.")
      expect(response.body).to include(%(href="#{new_user_confirmation_path}"))
    end

    it "muestra el ojo en la contraseña" do
      get(new_user_session_path)

      expect(response.body).to include('data-controller="password-visibility"')
      expect(response.body).to include("Recuérdame")
    end
  end
  ```

### Tarea 3.2: Registro (`registrations/new`)

**Archivos:** `app/views/devise/registrations/new.html.erb`, `config/locales/views.es.yml`, `spec/requests/users/registrations_spec.rb` (nuevo)

Copia `../supermenu/app/views/devise/registrations/new.html.erb` y cambia tres cosas: textos a `t(".…")`, el `onclick` por el patrón de la tarea 1.3 (con la ayuda `t("shared.password_hint", count: @minimum_password_length)`) y `autocomplete` con valores reales (`given-name`, `family-name`, `email`, `new-password`). Conserva los errores por campo (`is-invalid` + `invalid-feedback d-block`) y el `maxlength: 16` de nombre y apellido. No renderiza `_error_messages` ni `_links`.

```yaml
    registrations:
      new:
        title: Crear cuenta
        first_name: Nombre
        last_name: Apellido
        email: Correo
        password: Contraseña
        submit: Registrarme
        has_account: ¿Ya tienes cuenta?
        sign_in: Inicia sesión
```

- [ ] Reescribe la vista.
- [ ] Spec `spec/requests/users/registrations_spec.rb` (adaptado de `../supermenu/spec/requests/users/sign_up_spec.rb`):

  ```ruby
  require "rails_helper"

  RSpec.describe("Registro", type: :request) do
    it "manda a iniciar sesión con el aviso de revisar el correo" do
      post(
        user_registration_path,
        params: {
          user: {
            first_name: "Ana",
            last_name: "Prueba",
            email: "ana@example.com",
            password: "clavesegura123"
          }
        }
      )
      follow_redirect!

      expect(response.body).to include('data-controller="toast"')
      expect(response.body).to include("Te hemos enviado un email con instrucciones para que confirmes tu cuenta.")
    end

    it "muestra el error bajo el campo y conserva lo escrito si la contraseña es corta" do
      post(
        user_registration_path,
        params: {
          user: {
            first_name: "Ana",
            last_name: "Prueba",
            email: "ana@example.com",
            password: "123456789"
          }
        }
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("es demasiado corta (mínimo 10 caracteres)")
      expect(response.body).to include("is-invalid")
      expect(response.body).to include('value="ana@example.com"')
      expect(User.count).to eq(0)
    end

    it "muestra el ojo y la ayuda del mínimo" do
      get(new_user_registration_path)

      expect(response.body).to include('data-controller="password-visibility"')
      expect(response.body).to include("Mínimo 10 caracteres")
    end
  end
  ```

### Tarea 3.3: Reenviar confirmación (`confirmations/new`)

**Archivos:** `app/views/devise/confirmations/new.html.erb`, `config/locales/views.es.yml`, `spec/requests/users/confirmations_spec.rb` (nuevo)

Copia `../supermenu/app/views/devise/confirmations/new.html.erb` con los textos en `t(".…")`. Conserva el `value:` del gem en el campo de correo (`resource.pending_reconfirmation? ? resource.unconfirmed_email : resource.email`), que supermenu perdió.

```yaml
    confirmations:
      new:
        title: Reenviar instrucciones de confirmación
        subtitle: Te enviaremos un correo con las instrucciones para confirmar tu cuenta.
        email: Correo
        submit: Reenviar instrucciones
        back_to_sign_in: Volver a iniciar sesión
```

- [ ] Reescribe la vista.
- [ ] Spec `spec/requests/users/confirmations_spec.rb`:

  ```ruby
  require "rails_helper"

  RSpec.describe("Reenviar confirmación", type: :request) do
    it "reenvía las instrucciones a un usuario sin confirmar" do
      user = create(:user)

      post(user_confirmation_path, params: { user: { email: user.email } })
      follow_redirect!

      expect(response.body).to include("Recibirás un email con las instrucciones para confirmar")
    end

    it "explica en español que el correo no existe" do
      post(user_confirmation_path, params: { user: { email: "nadie@example.com" } })

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Correo no encontrado")
    end

    it "muestra la pantalla en español" do
      get(new_user_confirmation_path)

      expect(response.body).to include("Reenviar instrucciones de confirmación")
      expect(response.body).not_to include("Resend")
    end
  end
  ```

### Tarea 3.4: Mi cuenta (`registrations/edit`) dentro del panel

**Archivos:** `app/views/devise/registrations/edit.html.erb`, `app/controllers/users/registrations_controller.rb`, `app/views/shared/_sidebar.html.erb`, `config/locales/views.es.yml`, `spec/requests/users/account_spec.rb` (nuevo)

La vista de hoy falla: usa `:avatar` y `avatar_path`, y las apps se generan con `--skip-active-storage`. Copia `../supermenu/app/views/devise/registrations/edit.html.erb` con dos cambios: `render "shared/form_errors", record: resource` pasa a `render "devise/shared/error_messages", resource: resource` (Puntapie no tiene `shared/_form_errors`), y los tres campos de contraseña usan el patrón de la tarea 1.3 sin `form-floating` (wrapper `mb-3 position-relative`). Los `f.label` sin texto toman el nombre de `models.es.yml`.

`Users::RegistrationsController` (base de supermenu, manteniendo el `after_inactive_sign_up_path_for` de Puntapie):

```ruby
# frozen_string_literal: true

class Users::RegistrationsController < Devise::RegistrationsController
  layout :resolve_layout

  before_action :configure_sign_up_params, only: [:create]
  before_action :configure_account_update_params, only: [:update]

  private

  def configure_sign_up_params
    devise_parameter_sanitizer.permit(:sign_up, keys: [:first_name, :last_name])
  end

  def configure_account_update_params
    devise_parameter_sanitizer.permit(:account_update, keys: [:first_name, :last_name])
  end

  # La página "Mi cuenta" se muestra dentro del panel; el registro, con el layout de login.
  def resolve_layout
    %w[edit update].include?(action_name) ? "application" : "login"
  end

  def after_update_path_for(_resource)
    edit_user_registration_path
  end

  def after_inactive_sign_up_path_for(_resource)
    new_user_session_path
  end
end
```

En `shared/_sidebar.html.erb`, en la lista de abajo y antes de "Cerrar sesión", agrega el enlace a Mi cuenta. Pasa los dos textos del sidebar a YAML (`shared.sidebar.my_account`, `shared.sidebar.sign_out` y `shared.sidebar.sign_in`):

```erb
<% if user_signed_in? %>
  <li class="nav-item">
    <%= link_to edit_user_registration_path, class: "nav-link d-flex align-items-center gap-2" do %>
      <i class="bi bi-person"></i>

      <%= t("shared.sidebar.my_account") %>
    <% end %>
  </li>
<% end %>
```

```yaml
    registrations:
      edit:
        title: Mi cuenta
        waiting_confirmation: "Esperando confirmación de: %{email}"
        password: Nueva contraseña
        password_hint: Déjala en blanco si no quieres cambiarla.
        password_confirmation: Confirmar nueva contraseña
        current_password_hint: La necesitamos para confirmar cualquier cambio.
        submit: Guardar cambios
```

(`registrations.new` y `registrations.edit` van bajo el mismo `registrations:`.)

- [ ] Haz los cambios.
- [ ] Spec `spec/requests/users/account_spec.rb` (adaptado de `../supermenu/spec/requests/users/registrations_spec.rb`):

  ```ruby
  require "rails_helper"

  RSpec.describe("Mi cuenta", type: :request) do
    it "se muestra dentro del panel y en español" do
      user = create(:user, :confirmed)
      sign_in(user)

      get(edit_user_registration_path)

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Mi cuenta")
      expect(response.body).to include("Contraseña actual")
      expect(response.body).to include("sidebarMenu")
      expect(response.body).not_to include("Deactivate")
    end

    it "cambia nombre y apellido y vuelve a Mi cuenta" do
      user = create(:user, :confirmed, password: "clave12345")
      sign_in(user)

      put(user_registration_path, params: { user: { first_name: "Capri", last_name: "Admin", current_password: "clave12345" } })

      expect(response).to redirect_to(edit_user_registration_path)
      expect(user.reload.first_name).to eq("Capri")
      expect(user.last_name).to eq("Admin")
    end

    it "permite cambiar la contraseña" do
      user = create(:user, :confirmed, password: "vieja12345")
      sign_in(user)

      put(
        user_registration_path,
        params: { user: { password: "nueva12345", password_confirmation: "nueva12345", current_password: "vieja12345" } }
      )

      expect(user.reload.valid_password?("nueva12345")).to be(true)
    end

    it "no cambia nada si la contraseña actual es incorrecta" do
      user = create(:user, :confirmed, password: "clave12345")
      sign_in(user)

      put(
        user_registration_path,
        params: { user: { password: "nueva12345", password_confirmation: "nueva12345", current_password: "equivocada" } }
      )

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Contraseña actual no es correcta")
      expect(response.body).to include("sidebarMenu")
      expect(user.reload.valid_password?("clave12345")).to be(true)
    end
  end
  ```

### Tarea 3.5: Borrar `unlocks` y `_links`, y ajustar `_error_messages`

**Archivos:** `app/views/devise/unlocks/new.html.erb` (borrar), `app/views/devise/mailer/unlock_instructions.html.erb` (borrar), `app/views/devise/shared/_links.html.erb` (borrar), `app/views/devise/shared/_error_messages.html.erb`

`:lockable` no está activo en `User`. Después de las tareas 3.1 a 3.4, ninguna vista renderiza `devise/shared/links`.

En `_error_messages`, el título pasa de `<h2>` a `<h5>`, como en enlacito.

Hay un riesgo: si alguien activa `:lockable` en una app generada, Devise usará las vistas del gem (en inglés). Esto se avisa en el resumen de la etapa, no se resuelve.

- [ ] `grep -rn "devise/shared/links\|unlock" app/` no da resultados después de borrar.
- [ ] Ciclo de verificación completo: todos los specs nuevos más la línea base.
- [ ] En el navegador recorre login, registro (con error), reenviar confirmación, olvidé mi contraseña, nueva contraseña y Mi cuenta, a 375 px y a 1280 px. En cada una, el ojo funciona y no aparece ningún texto en inglés.
- [ ] Commit de la etapa: "Actualiza las vistas de Devise al estilo de enlacito y supermenu".

---

## Etapa 4: Cierre

### Tarea 4.1: Documentación y verificación final

**Archivos:** `CLAUDE.md`, `README.md.tt` (si menciona las vistas o los locales)

- [ ] En `CLAUDE.md`, sección "Locale": agrega que los textos de las vistas viven en `config/locales/views.es.yml` y los nombres de atributos en `models.es.yml`, y que cada YAML nuevo necesita su `copy_file` en `set_locales`.
- [ ] Regenera la app desde cero. `rspec` da la línea base más los ejemplos nuevos, con 0 fallos, y `.rubocop_todo.yml` no tiene ofensas nuevas comparado con la línea base.
- [ ] Commit: "Documenta dónde viven los textos de las vistas".
