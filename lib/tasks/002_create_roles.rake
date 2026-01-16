namespace :roles do
  desc "Crea roles iniciales"
  task create: :environment do
    Role.find_or_create_by(name: "admin")
    Role.find_or_create_by(name: "member")
    Role.find_or_create_by(name: "viewer")
  end
end
