source "https://rubygems.org"

gem "rails", "~> 8.1.3"

# App
gem "bootsnap"
gem "importmap-rails"
gem "postmark-rails"
gem "propshaft"
gem "puma", ">= 5.0"
gem "ruby_llm"
gem "solid_queue"
gem "sqlite3", ">= 2.1"
gem "stimulus-rails"
gem "turbo-rails"

# Deploy
gem "kamal", require: false
gem "thruster", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-minitest"
end

group :development do
  gem "letter_opener"
  gem "letter_opener_web"
  gem "web-console"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem 'simplecov', require: false
  gem "simplecov-console", require: false
end

gem "minitest-mock", "~> 5.27", groups: [:test, :development]
