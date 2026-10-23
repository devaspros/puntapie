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
