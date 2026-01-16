namespace :all_tasks do
  desc "Execute all existing rake tasks"
  task execute_all: :environment do
    puts "Starting execution of all rake tasks..."

    Rake::Task["organizations:create"].invoke
    Rake::Task["roles:create"].invoke
    Rake::Task["users:create"].invoke
    Rake::Task["users:create_user_organization_membership"].invoke

    puts "All rake tasks executed successfully!"
  end
end
