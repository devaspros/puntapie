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
