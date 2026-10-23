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

    put(
      user_registration_path,
      params: {
        user: {
          first_name: "Capri",
          last_name: "Admin",
          current_password: "clave12345"
        }
      }
    )

    expect(response).to redirect_to(edit_user_registration_path)
    expect(user.reload.first_name).to eq("Capri")
    expect(user.last_name).to eq("Admin")
  end

  it "permite cambiar la contraseña" do
    user = create(:user, :confirmed, password: "vieja12345")
    sign_in(user)

    put(
      user_registration_path,
      params: {
        user: {
          password: "nueva12345",
          password_confirmation: "nueva12345",
          current_password: "vieja12345"
        }
      }
    )

    expect(user.reload.valid_password?("nueva12345")).to be(true)
  end

  it "no cambia nada si la contraseña actual es incorrecta" do
    user = create(:user, :confirmed, password: "clave12345")
    sign_in(user)

    put(
      user_registration_path,
      params: {
        user: {
          password: "nueva12345",
          password_confirmation: "nueva12345",
          current_password: "equivocada"
        }
      }
    )

    expect(response).to have_http_status(:unprocessable_content)
    expect(response.body).to include("Contraseña actual no es correcta")
    expect(response.body).to include("sidebarMenu")
    expect(user.reload.valid_password?("clave12345")).to be(true)
  end
end
