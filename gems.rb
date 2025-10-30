# frozen_string_literal: true

source 'https://rubygems.org'

ruby '>= 3.4.0'

gem 'onlyoffice_bugzilla_helper'
gem 'rake'
gem 'rspec'
gem 'telegram-bot-ruby'

group :development do
  gem 'overcommit', require: false
  gem 'rubocop', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rake', require: false
  gem 'rubocop-rspec', require: false
  gem 'yard', require: false
end
