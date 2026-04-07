namespace :setup do
  desc "Configuración Inicial"
  task run: :environment do
    admin = Role.find_or_create_by(name: "admin")
    Role.find_or_create_by(name: "member")
    Role.find_or_create_by(name: "viewer")

    org = Organization.find_or_create_by(name: "DevAsPros", slug: "dap")

    user = User.find_or_create_by(email: "frajaquico@aol.com") do |u|
      u.first_name = "Francisco"
      u.last_name = "Quintero"
      u.password = "clave-de-puntapie-2026"
      u.admin = true
      u.current_organization_id = org.id
      u.confirmed_at = Time.now
    end

    Membership.create(
      organization: org,
      user: user,
      role: admin
    )
  end
end
