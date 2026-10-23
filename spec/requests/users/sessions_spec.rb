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
