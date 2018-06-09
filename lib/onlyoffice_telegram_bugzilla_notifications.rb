require 'onlyoffice_bugzilla_helper'
require 'telegram/bot'
require 'yaml'

module OnlyofficeTelegramBugzillaNotificaions
  # Class for sending notifications
  class TelegramBuzillaNotificaions
    def initialize(config_path = 'config.yml')
      @last_send_bug_storage = 'last_send_bug.info'
      @config = YAML.load_file(config_path)
      @latest_notified_bug = latest_notified_bug
      @bugzilla = OnlyofficeBugzillaHelper::BugzillaHelper.new(bugzilla_url: @config['bugzilla_user'], api_key: @config['bugzilla_key'])
    end

    def fetch_bugs_to_send
      @bugs_to_send = []
      current_bug = latest_notified_bug + 1
      while @bugzilla.bug_exists?(current_bug)
        @bugs_to_send << current_bug
        current_bug += 1
      end
    end

    def form_messages
      @messages = []
      @bugs_to_send.each do |bug|
        @messages << form_message(bug)
      end
    end

    # @param messages [Array<String>] message to send
    def send_messages(messages = @messages)
      Telegram::Bot::Client.run(@config['telegram_bot_token']) do |bot|
        messages.each do |message|
          bot.api.sendMessage(chat_id: @config['channel_id'], text: message)
        end
      end
      update_last_notified_bug(@bugs_to_send.last)
    end

    def fetch_info_and_send
      fetch_bugs_to_send
      form_messages
      send_messages
    end

    private

    # @return [Integer] id of latest bug that was notified
    def latest_notified_bug
      File.read(@last_send_bug_storage).to_i
    end

    def update_last_notified_bug(bug)
      File.write(@last_send_bug_storage, bug)
    end

    def form_message(bug_id)
      metadata = @bugzilla.bug_data(bug_id)
      "Bug #{bug_id}. #{metadata['summary']}\n"\
      "Reported by: #{metadata['creator']}\n"\
      "#{metadata['product']} -> #{metadata['component']}"
    end
  end
end
