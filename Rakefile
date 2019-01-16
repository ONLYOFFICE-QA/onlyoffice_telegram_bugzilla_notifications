require_relative 'lib/onlyoffice_telegram_bugzilla_notifications'

desc 'Task for parse all files in directory'
task :fetch_news_and_post do
  notifications = OnlyofficeTelegramBugzillaNotificaions::TelegramBuzillaNotificaions.new
  notifications.fetch_info_and_send
end
