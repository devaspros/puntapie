require "fileutils"
require "shellwords"

def rails_version
  @rails_version ||= Gem::Version.new(Rails::VERSION::STRING)
end

def rails_5?
  Gem::Requirement.new(">= 5.2.0", "< 6.0.0.beta1").satisfied_by? rails_version
end

def rails_6?
  Gem::Requirement.new(">= 6.0.0.beta1", "< 7").satisfied_by? rails_version
end

# Copied from: https://github.com/mattbrictson/rails-template
# Add this template directory to source_paths so that Thor actions like
# copy_file and template resolve against our source files. If this file was
# invoked remotely via HTTP, that means the files are not present locally.
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

def add_gems
  gem 'bootstrap', '~> 4.5'
  gem 'devise', '~> 4.7', '>= 4.7.1'
  gem 'devise-bootstrapped', github: 'excid3/devise-bootstrapped', branch: 'bootstrap4'
  gem 'devise_masquerade', '~> 1.2'
  gem 'font-awesome-sass', '~> 5.13'
  gem 'name_of_person', '~> 1.1'
  gem 'pundit', '~> 2.1'
  gem 'redis', '~> 4.2', '>= 4.2.2'
  gem 'sidekiq', '~> 6.1'
  gem 'whenever', require: false

  gem_group :development do
    gem 'foreman'
  end

  gem_group :development, :test do
    gem 'dotenv-rails'
  end

  if rails_5?
    gsub_file "Gemfile", /gem 'sqlite3'/, "gem 'sqlite3', '~> 1.3.0'"
    gem 'webpacker', '~> 5.1', '>= 5.1.1'
  end
end

def set_application_name
  # Add Application Name to Config
  if rails_5?
    environment "config.application_name = Rails.application.class.parent_name"
  else
    environment "config.application_name = Rails.application.class.module_parent_name"
  end

  # Announce the user where they can change the application name in the future.
  puts "You can change application name inside: ./config/application.rb"
end

def stop_spring
  run "spring stop"
end

def add_users
  # Install Devise
  generate "devise:install"

  # Configure Devise
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
              env: 'development'
  route "root to: 'home#index'"

  # Devise notices are installed via Bootstrap
  generate "devise:views:bootstrapped"

  # Create Devise User
  generate :devise, "User",
           "first_name",
           "last_name",
           "admin:boolean"

  # Set admin default to false
  in_root do
    migration = Dir.glob("db/migrate/*").max_by{ |f| File.mtime(f) }
    gsub_file migration, /:admin/, ":admin, default: false"
  end

  if Gem::Requirement.new("> 5.2").satisfied_by? rails_version
    gsub_file "config/initializers/devise.rb",
      /  # config.secret_key = .+/,
      "  config.secret_key = Rails.application.credentials.secret_key_base"
  end
end

def add_authorization
  generate 'pundit:install'
end

def add_webpack
  rails_command 'webpacker:install'
end

def add_javascript
  run "yarn add expose-loader jquery popper.js bootstrap data-confirm-modal local-time"

  if rails_5?
    run "yarn add turbolinks @rails/actioncable@pre @rails/actiontext@pre @rails/activestorage@pre @rails/ujs@pre"
  end

content = <<-JS
const webpack = require('webpack')
environment.plugins.append('Provide', new webpack.ProvidePlugin({
  $: 'jquery',
  jQuery: 'jquery',
  Rails: '@rails/ujs'
}))
JS

  insert_into_file 'config/webpack/environment.js', content + "\n", before: "module.exports = environment"
end

def add_sidekiq
  environment "config.active_job.queue_adapter = :sidekiq"

  insert_into_file "config/routes.rb",
    "require 'sidekiq/web'\n\n",
    before: "Rails.application.routes.draw do"

  content = <<~RUBY
              authenticate :user, lambda { |u| u.admin? } do
                mount Sidekiq::Web => '/sidekiq'

                namespace :admin do
                end
              end
            RUBY
  insert_into_file "config/routes.rb", "#{content}\n", after: "Rails.application.routes.draw do\n"
end

def copy_templates
  remove_file "app/assets/stylesheets/application.css"

  copy_file "Procfile"
  copy_file "Procfile.dev"
  copy_file ".foreman"
  copy_file ".env.example"
  copy_file ".env"

  copy_file "gitignore", ".gitignore", force: true

  directory "app", force: true
end

def add_whenever
  run "wheneverize ."
end

# Main setup
add_template_repository_to_source_path

add_gems

after_bundle do
  set_application_name
  stop_spring
  add_users
  add_authorization
  add_webpack
  add_javascript
  add_sidekiq

  copy_templates
  add_whenever

  # Commit everything to git
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
  say "  # Update config/database.yml with your database credentials"
  say
  say "  rails db:create db:migrate"
  say "  foreman start # Run Rails, sidekiq, and webpack-dev-server"
end
