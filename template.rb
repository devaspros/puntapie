require "fileutils"
require "shellwords"

# Copied from: https://github.com/mattbrictson/rails-template
#
# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
#
# In that case, use `git clone` to download them to a local temporary dir.
def add_template_repository_to_source_path
  if __FILE__ =~ %r{\Ahttps?://}
    require "tmpdir"
    source_paths.unshift(tempdir = Dir.mktmpdir("puntapie-"))
    at_exit { FileUtils.remove_entry(tempdir) }
    git clone: [
      "--quiet",
      "https://github.com/devaspros/puntapie.git",
      tempdir
    ].map(&:shellescape).join(" ")

    if (branch = __FILE__[%r{puntapie/(.+)/template.rb}, 1])
      Dir.chdir(tempdir) { git checkout: branch }
    end
  else
    source_paths.unshift(File.dirname(__FILE__))
  end
end

def set_application_name
  environment "config.application_name = Rails.application.class.module_parent_name"
end

def disable_default_generators
  file 'config/initializers/generators.rb', <<~CODE
    Rails.application.config.generators do |g|
      g.javascripts false
      g.jbuilder false
      g.stylesheets false
      g.assets false
      g.helper false
      g.view_specs false
      g.helper_specs false
    end
  CODE
end

def stop_spring
  run "spring stop"
end

def add_users
  generate "devise:install"

  generate :devise, "User", "first_name:string", "last_name:string", "admin:boolean"

  in_root do
    migration = Dir.glob("db/migrate/*").max_by{ |f| File.mtime(f) }
    gsub_file migration, /:admin/, ":admin, default: false"
  end
end

def add_authorization
  generate "pundit:install"
end

def add_sidekiq
  environment "config.active_job.queue_adapter = :sidekiq"

  copy_file "config/sidekiq.yml", force: true
  copy_file "config/initializers/sidekiq.rb", force: true
end

def set_locales
  environment "config.i18n.default_locale = :es"

  copy_file "config/locales/devise.es.yml", force: true
  copy_file "config/locales/es-CO.yml", force: true
end

def copy_templates
  remove_file "config/credentials.yml.enc"
  remove_file "config/master.key"
  remove_file "app/assets/stylesheets/application.css"

  copy_file "Procfile"
  copy_file "Procfile.dev"
  copy_file ".foreman"
  copy_file ".env.example"
  copy_file ".env"
  copy_file ".editorconfig"
  copy_file "lib/tasks/auto_annotate_models.rake"

  copy_file "gitignore", ".gitignore", force: true

  copy_file "config/routes.rb", force: true
  copy_file "config/database.yml", force: true

  # Copy initial importmap with Hotwire libs, Bootstrap and Popper
  copy_file "config/importmap.rb", force: true

  # This file contains configuration for bootstrap and popper.js
  copy_file "config/initializers/assets.rb", force: true

  copy_file "config/initializers/sentry.rb", force: true

  template "README.md.tt", force: true

  # Copy everything from app folder to generated rails_app
  directory "app", force: true

  # Copy everything from .github folder to generated rails_app
  directory ".github", force: true

  directory "scripts", force: true

  copy_file ".rubocop.yml", force: true
end

def configure_rspec
  generate "rspec:install"

  copy_file "spec/support/factory_bot.rb"
  copy_file "spec/support/database_cleaner.rb"
  copy_file "spec/support/request_spec_helper.rb"
  copy_file "spec/support/capybara_setup.rb"
  copy_file "spec/support/devise_testing_helpers.rb"
  copy_file "spec/rails_helper.rb", force: true
  copy_file "spec/spec_helper.rb", force: true

  directory "spec/requests", force: true
  directory "spec/factories", force: true

  copy_file ".simplecov"
  copy_file ".spec", force: true
end

def active_storage_setup
  copy_file "config/storage.yml", force: true
  directory "storage", force: true

  rails_command "active_storage:install"
end

def add_action_mailer_configs
  development_smtp_settings = <<~SMTP_SETTINGS
    config.action_mailer.default_url_options = { host: "localhost:3000" }

    config.action_mailer.delivery_method = :smtp

    config.action_mailer.smtp_settings = {
      address: "127.0.0.1",
      port: 1025
    }
  SMTP_SETTINGS

  environment(development_smtp_settings, env: "development")

  production_smtp_settings = <<~SMTP_SETTINGS
    config.action_mailer.delivery_method = :smtp

    config.action_mailer.smtp_settings = {
      domain: ENV["MAILGUN_DOMAIN"],
      address: ENV["MAILGUN_HOST"],
      user_name: ENV["MAILGUN_USERNAME"],
      password: ENV["MAILGUN_PASSWORD"],
      port: 587
    }
  SMTP_SETTINGS

  environment(production_smtp_settings, env: "production")
end

def setup_exception_handler
  development_exception_handler = <<~CONFIG
    config.exception_handler = {
      dev: false,
      exceptions: {
        "4xx" => { layout: "4xx" },
        "5xx" => { layout: "5xx" }
      }
    }
  CONFIG

  environment(development_exception_handler, env: "development")

  production_exception_handler = <<~CONFIG
    config.exception_handler = {
      exceptions: {
        "4xx" => { layout: "4xx" },
        "5xx" => { layout: "5xx" }
      }
    }
  CONFIG

  environment(production_exception_handler, env: "production")
end

def add_organization_migration
  # Necesario para que el siguiente timestamp no sea igual.
  sleep(1)

  say("Ejecutando add_organization_migration", :yellow)

  timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")

  create_file "db/migrate/#{timestamp}_create_organizations.rb", <<~RUBY
    class CreateOrganizations < ActiveRecord::Migration[7.1]
      def change
        create_table :organizations do |t|
          t.string :name, null: false
          t.string :slug, null: false

          t.timestamps
        end
      end
    end
  RUBY

  # Necesario para que el siguiente timestamp no sea igual.
  sleep(2)
end

def add_invitation_migration
  say("Ejecutando add_invitation_migration", :yellow)

  timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")

  create_file "db/migrate/#{timestamp}_create_invitations.rb", <<~RUBY
    class CreateInvitations < ActiveRecord::Migration[7.1]
      def change
        create_table :invitations do |t|
          t.string :email
          t.string :uuid
          t.integer :from_membership_id
          t.references :organization, null: false, foreign_key: true

          t.timestamps
        end
      end
    end
  RUBY

  # Necesario para que el siguiente timestamp no sea igual.
  sleep(2)
end

def add_current_organization_to_user
  say("Ejecutando add_current_organization_to_user", :yellow)

  timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")

  create_file "db/migrate/#{timestamp}_add_current_organization_id_to_user.rb", <<~RUBY
    class AddCurrentOrganizationIdToUser < ActiveRecord::Migration[7.1]
      def change
        add_column :users, :current_organization_id, :integer
      end
    end
  RUBY

  # Necesario para que el siguiente timestamp no sea igual.
  sleep(2)
end

def add_role_migration
  say("Ejecutando add_role_migration", :yellow)

  timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")

  create_file "db/migrate/#{timestamp}_create_roles.rb", <<~RUBY
    class CreateRoles < ActiveRecord::Migration[7.1]
      def change
        create_table :roles do |t|
          t.string :name, null: false

          t.timestamps
        end
      end
    end
  RUBY

  # Necesario para que el siguiente timestamp no sea igual.
  sleep(2)
end

def add_membership_migration
  say("Ejecutando add_membership_migration", :yellow)

  timestamp = Time.now.utc.strftime("%Y%m%d%H%M%S")

  create_file "db/migrate/#{timestamp}_create_memberships.rb", <<~RUBY
    class CreateMemberships < ActiveRecord::Migration[7.1]
      def change
        create_table :memberships do |t|
          t.references :organization, null: false, foreign_key: true
          t.references :user, null: false, foreign_key: true
          t.references :invitation, foreign_key: true
          t.references :role, null: false, foreign_key: true

          t.timestamps
        end
      end
    end
  RUBY

  # Necesario para que el siguiente timestamp no sea igual.
  sleep(2)
end

def copy_organization_models
  copy_file "app/models/organization.rb"
  copy_file "app/models/invitation.rb"
  copy_file "app/models/role.rb"
  copy_file "app/models/membership.rb"
  copy_file "app/models/user.rb", force: true
end

def copy_organization_rakes
  copy_file "lib/tasks/000_execute_all_tasks.rake"
  copy_file "lib/tasks/001_organizations.rake"
  copy_file "lib/tasks/003_users.rake"
  copy_file "lib/tasks/002_create_roles.rake"
end

def disable_sqlite_in_production_warning
  sqlite_in_prod_setting = <<~SQLITE_WARNING
    # Turn off warning about SQLite not for production
    config.active_record.sqlite3_production_warning = false

  SQLITE_WARNING

  environment(sqlite_in_prod_setting, env: "production")
end

# Main setup
add_template_repository_to_source_path

template "Gemfile.tt", force: true

after_bundle do
  set_application_name
  disable_default_generators
  stop_spring
  add_users
  add_authorization
  add_sidekiq
  set_locales

  copy_templates

  configure_rspec
  active_storage_setup
  add_action_mailer_configs
  setup_exception_handler

  add_organization_migration
  add_invitation_migration
  add_current_organization_to_user
  add_role_migration
  add_membership_migration

  copy_organization_models
  copy_organization_rakes

  disable_sqlite_in_production_warning

  run "bundle lock --add-platform x86_64-linux"

  unless ENV["SKIP_GIT"]
    git :init
    git add: "."

    # git commit will fail if user.email is not configured
    begin
      git commit: %( -m 'Initial commit' )
    rescue StandardError => e
      puts e.message
    end
  end

  say "To get started with your new app:", :green
  say "  cd #{app_name}"
  say
  say "  Update config/database.yml with your database credentials"
  say
  say "  rails db:create db:migrate"
  say "  rails users:create"
  say "  foreman start # Runs rails, sidekiq on port 3005"
end
