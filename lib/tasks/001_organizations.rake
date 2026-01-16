namespace :organizations do
  desc "Crea Organization Inicial"
  task create: :environment do
    Organization.find_or_create_by(name: "DevAsPros", slug: "dap")
  end
end
