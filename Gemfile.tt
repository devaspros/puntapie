source 'https://rubygems.org'

git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby '2.7.1'

gem 'bootstrap', '~> 4.5'
gem 'blueprinter'
gem 'devise', '~> 4.7', '>= 4.7.1'
gem 'devise-bootstrapped', github: 'excid3/devise-bootstrapped', branch: 'bootstrap4'
gem 'devise_masquerade', '~> 1.2'
gem 'exception_handler', '~> 0.8.0.0'
gem 'font-awesome-sass', '~> 5.13'
gem 'name_of_person', '~> 1.1'
gem 'pg', '~> 1.2'
gem 'puma', '~> 4.1'
gem 'pundit', '~> 2.1'
gem 'rails', '6.1.3.2'
gem 'redis', '~> 4.2', '>= 4.2.2'
gem 'sass-rails', '>= 6'
gem 'sidekiq'
gem 'sqlite3', '~> 1.4'
gem 'webpacker', '~> 4.0'
gem 'whenever', require: false

group :development do
  gem 'annotate', '~> 3'
  gem 'foreman'
  gem 'spring'
  gem 'web-console', '>= 3.3.0'
end

group :development, :test do
  gem 'amazing_print', '1.2.2'
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  gem 'dotenv-rails'
  gem 'factory_bot_rails'
  gem 'rspec-rails', '4.0.1'
end

group :test do
  gem 'database_cleaner'
  gem 'shoulda-matchers', '~> 4.4'
  gem 'simplecov', require: false
end
