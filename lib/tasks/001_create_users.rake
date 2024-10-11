namespace :users do
  task create: :environment do
    User.find_or_create_by(email: 'frajaquico@aol.com') do |u|
      u.first_name = 'Francisco'
      u.last_name = 'Quintero'
      u.password = 'clavesegura'
      u.admin = true
    end
  end
end
