source 'https://rubygems.org'

gem 'onlyoffice_bugzilla_helper'
gem 'telegram-bot-ruby'

group :development do
  gem 'overcommit', require: false
  gem 'rubocop', require: false
end

group :test do
  gem 'codecov', require: false
  gem 'rspec'
end
