namespace :users do
  desc "Crea usuario de pruebas"
  task create: :environment do
    User.find_or_create_by(email: "frajaquico@aol.com") do |u|
      u.first_name = "Francisco"
      u.last_name = "Quintero"
      u.password = "clavesegura2024"
      u.admin = true
      u.current_organization_id = Organization.find_by(name: "DevAsPros").id
    end
  end

  desc "Crea Membresia para el 1er usuario"
  task create_user_organization_membership: :environment do
    Membership.create(
      organization: Organization.find_by(name: "DevAsPros"),
      user: User.find_by(email: "frajaquico@aol.com"),
      role: Role.find_by(name: "admin")
    )
  end
end
