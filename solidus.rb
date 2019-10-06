require "fileutils"
require "shellwords"

def add_gems
  gem 'bootstrap', '~> 4.3.1'
  gem 'solidus'
  gem 'solidus_auth_devise'
  gem "solidus_stripe", github: "solidusio-contrib/solidus_stripe"

  gem 'font-awesome-sass', '~> 5.9.0'
  gem 'sidekiq', '~> 5.2', '>= 5.2.5'
  gem 'sitemap_generator', '~> 6.0', '>= 6.0.1'

  gem_group :development do
    gem 'better_errors'
    gem 'binding_of_caller'
    gem 'faker'
    gem 'rack-livereload'
    gem 'guard'
    gem 'guard-livereload', '~> 2.5', require: false
    gem 'rails_db', '2.0.4'
  end

  gem_group :test do
    gem 'nyan-cat-formatter'
    gem 'shoulda-matchers'
    gem 'rails-controller-testing'
    gem 'simplecov', require: false
  end

  gem_group :development, :test do
    gem 'pry-rails'
    gem 'rspec-rails', '~> 3.8'
    gem 'factory_bot_rails'
    gem 'dotenv-rails'
  end

end

def solidus_install
  rails_command "generate spree:install --sample=false"
  rails_command "generate solidus:auth:install"
  run "rake railties:install:migrations"
end

def rspec_init
  rails_command "generate rspec:install"

  shoulda_matchers = <<-RUBY
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
  RUBY

  append_to_file "spec/rails_helper.rb", "\n#{shoulda_matchers}"
  insert_into_file "spec/rails_helper.rb", "  config.include FactoryBot::Syntax::Methods\n", after: "RSpec.configure do |config|\n"
  insert_into_file "spec/rails_helper.rb", "# ", before: 'config.fixture_path = "#{::Rails.root}/spec/fixtures"'
  append_to_file ".rspec", "--format NyanCatFormatter"

end

def add_sidekiq
  environment "config.active_job.queue_adapter = :sidekiq"

  insert_into_file "config/routes.rb",
    "require 'sidekiq/web'\n\n",
    before: "Rails.application.routes.draw do"

  content = <<-RUBY
    authenticate :user, lambda { |u| u.admin? } do
      mount Sidekiq::Web => '/sidekiq'
    end
  RUBY
  insert_into_file "config/routes.rb", "#{content}\n\n", after: "Rails.application.routes.draw do\n"
end

def add_sitemap
  rails_command "sitemap:install"
end


after_bundle do
  rails_command "db:create"
  solidus_install
  rspec_init
  add_sidekiq
  add_sitemap

  git :init
  git add: "."
  git commit: %Q{ -m 'Initial commit' }
end

add_gems
