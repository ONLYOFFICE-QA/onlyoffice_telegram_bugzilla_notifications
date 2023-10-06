# frozen_string_literal: true

require_relative 'lib/onlyoffice_telegram_bugzilla_notifications'

desc 'Task for parse all files in directory'
task :fetch_news_and_post do
  notifications = OnlyofficeTelegramBugzillaNotifications::TelegramBugzillaNotifications.new
  notifications.start_watcher
end
