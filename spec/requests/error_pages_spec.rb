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
