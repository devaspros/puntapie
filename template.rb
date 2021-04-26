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

def disable_default_generators
file 'config/initializers/generators.rb', <<-CODE
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

  # Configure Devise
  environment "config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }",
              env: 'development'

  # Devise notices are installed via Bootstrap
  generate "devise:views:bootstrapped"

  generate :devise, "User",
           "first_name",
           "last_name",
           "admin:boolean"

  in_root do
    migration = Dir.glob("db/migrate/*").max_by{ |f| File.mtime(f) }
    gsub_file migration, /:admin/, ":admin, default: false"
  end

  if Gem::Requirement.new("> 5.2").satisfied_by? rails_version
    gsub_file "config/initializers/devise.rb",
      /  # config.secret_key = .+/,
      "  config.secret_key = Rails.application.credentials.secret_key_base"
  end

  inject_into_file("app/models/user.rb", " :masqueradable, ", after: "devise")
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
end

def add_api_namespace
  content = <<~RUBY
              namespace 'api', default: { format: 'json' }, path: '/' do
                namespace :v1 do
                end
              end
            RUBY
  insert_into_file "config/routes.rb", "#{content}\n", after: "Rails.application.routes.draw do\n"
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

  directory "app", force: true
end

def add_whenever
  run "wheneverize ."
end

def configure_rspec
  generate 'rspec:install'

  copy_file "spec/support/factory_bot.rb"
  copy_file "spec/support/shoulda_matchers.rb"
  copy_file "spec/support/database_cleaner.rb"
  copy_file "spec/support/request_spec_helper.rb"
  copy_file "spec/rails_helper.rb", force: true
  copy_file "spec/spec_helper.rb", force: true

  copy_file ".simplecov"
  copy_file ".spec"
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
  add_webpack
  add_javascript
  add_sidekiq

  copy_templates
  add_whenever

  configure_rspec

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
  say "  Update config/database.yml with your database credentials"
  say
  say "  rails db:create db:migrate"
  say "  foreman start # Run Rails, sidekiq, and webpack-dev-server"
end
