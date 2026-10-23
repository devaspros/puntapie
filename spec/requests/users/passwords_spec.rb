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
