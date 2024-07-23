# frozen_string_literal: true

require 'onlyoffice_bugzilla_helper'
require 'telegram/bot'
require 'yaml'
require_relative 'onlyoffice_telegram_bugzilla_notifications/message'
require_relative 'onlyoffice_telegram_bugzilla_notifications/bug_filter'

# Namespace of `onlyoffice_telegram_bugzilla_notifications`
module OnlyofficeTelegramBugzillaNotifications
  # Class for sending notifications
  class TelegramBugzillaNotifications
    def initialize(config_path = 'config.yml')
      @last_send_bug_storage = 'last_send_bug.info'
      @config = YAML.load_file(config_path)
      @latest_notified_bug = latest_notified_bug
      @bugzilla = OnlyofficeBugzillaHelper::BugzillaHelper.new(bugzilla_url: @config['bugzilla_url'],
                                                               api_key: @config['bugzilla_key'])
      @logger = Logger.new($stdout)
    end

    # Fetch list of bugs need to be send
    # @return [nil]
    def fetch_bugs_to_send
      @bugs_to_send = []
      current_bug = latest_notified_bug + 1
      while @bugzilla.bug_exists?(current_bug)
        @bugs_to_send << current_bug if BugFilter.new(@bugzilla, @config, current_bug).check_all
        current_bug += 1
      end
      @logger.info("List of not notified bugs: #{@bugs_to_send}")
    end

    # Form message to send via telegram
    def form_messages
      @messages = []
      @bugs_to_send.each do |bug|
        @messages << Message.new(@bugzilla, bug)
      end
    end

    # @param messages [Array<String>] message to send
    def send_messages(messages = @messages)
      Telegram::Bot::Client.run(@config['telegram_bot_token']) do |bot|
        messages.each_with_index do |message, index|
          @logger.info("Sending info `#{message.for_logger} to chat #{@config['channel_id']}")
          bot.api.sendMessage(chat_id: @config['channel_id'], text: message)
          @logger.info("Send info about bug: #{@bugs_to_send[index]}")
        end
      end
      update_last_notified_bug(@bugs_to_send.last)
    end

    # Fetch info about not-notified bugs and send it
    def fetch_info_and_send
      fetch_bugs_to_send
      return if @bugs_to_send.empty?

      form_messages
      send_messages
    end

    # Start watcher for new bugs
    # This is endless proccess
    # @return [nil]
    def start_watcher
      loop do
        fetch_info_and_send
        sleep(@config.fetch('check_period', 60))
      end
    end

    private

    # @return [Integer] id of latest bug that was notified
    def latest_notified_bug
      File.read(@last_send_bug_storage).to_i
    end

    def update_last_notified_bug(bug)
      @logger.info("Change last notified bug to: #{bug}")
      File.write(@last_send_bug_storage, bug)
    end
  end
end
