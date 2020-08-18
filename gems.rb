# frozen_string_literal: true

source 'https://rubygems.org'

gem 'onlyoffice_bugzilla_helper'
gem 'telegram-bot-ruby'

group :development do
  gem 'overcommit', require: false
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
end
