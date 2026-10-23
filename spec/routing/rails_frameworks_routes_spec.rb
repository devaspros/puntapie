require "rails_helper"

# La app no usa Active Storage, Action Mailbox ni Action Text. Si vuelven a cargarse, sus rutas quedan abiertas sin
# autenticación: el 18 oct 2026 un escáner subió archivos a producción por /rails/active_storage/direct_uploads.
RSpec.describe "Rutas de frameworks que no se usan", type: :routing do
  it "no expone las rutas de Active Storage" do
    expect(post: "/rails/active_storage/direct_uploads").not_to be_routable
    expect(put: "/rails/active_storage/disk/token").not_to be_routable
    expect(get: "/rails/active_storage/blobs/redirect/signed-id/archivo.png").not_to be_routable
    expect(get: "/rails/active_storage/representations/redirect/signed-id/variacion/archivo.png").not_to be_routable
  end

  it "no expone las rutas de Action Mailbox" do
    expect(post: "/rails/action_mailbox/relay/inbound_emails").not_to be_routable
    expect(get: "/rails/conductor/action_mailbox/inbound_emails").not_to be_routable
  end
end
