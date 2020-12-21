# Change log

## master (unreleased)

### New Features

* Add log about message to send

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
