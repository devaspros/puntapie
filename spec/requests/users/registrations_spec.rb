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
    expect(response.body).not_to include("field_with_errors")
    expect(User.count).to eq(0)
  end

  it "muestra el ojo y la ayuda del mínimo" do
    get(new_user_registration_path)

    expect(response.body).to include('data-controller="password-visibility"')
    expect(response.body).to include("Mínimo 10 caracteres")
  end
end
