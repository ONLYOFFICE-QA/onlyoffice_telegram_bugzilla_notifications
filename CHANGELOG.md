# Change log

## master (unreleased)

### New features

* Add configuration parameter `check_period` to configure timeout between checks
* Use `ruby-3.3` as application base

## 0.4.0 (2023-09-22)

### New Features

* Add `yamllint` check in CI
* Add CI check that Dockerfile can be built
* Mount `config.yml` as volume in docker-compose
* Build docker image in CI
* Add `hadolint` in linting CI
* Add assignee field in message

### Fixes

* Fix `markdownlint` failure because of old `nodejs` in CI
* Fix issues from `hadolint`

### Changes

* Use reporter real name in report message
* Update base image to `ruby-3.2`
* Check `dependabot` at 8:00 Moscow time daily
* Default `docker-compose.yml` uses docker hub image

## 0.3.0 (2021-04-21)

### New Features

* Add dependabot check for new docker base image version
* Use `3.0.1-alpine` as base image

## 0.2.0 (2020-12-21)

### New Features

* Add log about message to send
* Add `dependabot` support

### Fixes

* Add missing `markdownlint` config

### Changes

* Reduce `rubocop` `Layout/LineLength` metrics
* Change typo in module name `OnlyofficeTelegramBugzillaNotifications`
* Change typo in class name `TelegramBugzillaNotificaions`

## 0.1.0 (2020-08-18)

### New Features

* Initial Release
* Bug url in message
* Add `docker-compose` support
* Add bug severity to message
* Use `alpine` as base image for Docker
* Use `bundle config` to not install dev dependencies
* Remove protocol prefix from message, should read from config
* Show product version in bug message
* Add log messages to STDOUT
* Add support of GitHub Actions for code-style tasks
* Add support of `rubocop-performance`, `rubocop-rake` and `rubocop-rspec`
  extension

### Changes

* Remove support of CodeClimate
