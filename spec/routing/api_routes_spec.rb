require "rails_helper"

# Con `default:` (en singular) el namespace agregaba un parámetro de ruta llamado default en vez de
# fijar el formato de la API.
RSpec.describe "Rutas de la API", type: :routing do
  it "responden en JSON por defecto" do
    route = Rails.application.routes.recognize_path("/api/v1/users/sign_in", method: :post)

    expect(route[:format]).to eq("json")
    expect(route).not_to have_key(:default)
  end
end
