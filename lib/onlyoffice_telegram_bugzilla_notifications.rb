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
      @bugzilla = OnlyofficeBugzillaHelper::BugzillaHelper.new(bugzilla_url: @config['common_config']['bugzilla_url'],
                                                               api_key: @config['common_config']['bugzilla_key'])
      @logger = Logger.new($stdout)
    end

    # Fetch list of bugs need to be send
    # @return [nil]
    def fetch_bugs_to_send
      @bugs_to_send = []
      current_bug = latest_notified_bug + 1
      while @bugzilla.bug_exists?(current_bug)
        @bugs_to_send << current_bug
        current_bug += 1
      end
      @logger.info("List of not notified bugs: #{@bugs_to_send}")
    end

    # Forms messages to be sent via Telegram based on the bug data and chat configuration.
    # Iterates through the list of bug data, applies the filters specified in the chat configuration,
    # and creates a message for each bug that passes the filters.
    # The resulting messages are stored in the instance variable `@messages`.
    # @param chat_config [Hash] The configuration hash for the chat,
    #   containing the filter criteria and other settings for the messages.
    def form_messages(chat_config)
      @messages = []
      @bugs_data_list.each do |bug_data|
        @messages << Message.new(bug_data, @bugzilla.url) if BugFilter.new(chat_config, bug_data).check_all
      end
    end

    # Sends messages via Telegram.
    # @param chat_config [Hash] The configuration hash for the chat, containing the bot token and channel ID.
    # @param messages [Array<String>] The array of messages to send. Defaults to @messages.
    # @return [void] This method does not return a value.
    def send_messages(chat_config, messages = @messages)
      Telegram::Bot::Client.run(chat_config['telegram_bot_token']) do |bot|
        messages.each_with_index do |message, index|
          @logger.info("Sending info `#{message.for_logger} to chat #{chat_config['channel_id']}")
          bot.api.sendMessage(chat_id: chat_config['channel_id'], text: message)
          @logger.info("Send info about bug: #{@bugs_to_send[index]}")
        end
      end
    end

    # Fetches data for each bug in the list of bugs to send.
    # The data for each bug is retrieved using the Bugzilla API.
    # The resulting data is stored in the instance variable `@bugs_data_list`.
    def fetch_bugs_data
      @bugs_data_list = @bugs_to_send.map { |bug_id| @bugzilla.bug_data(bug_id) }
    end

    # Fetch info about not-notified bugs and send it
    def fetch_info_and_send
      fetch_bugs_to_send
      return if @bugs_to_send.empty?

      fetch_bugs_data
      chat_configs.each_value do |chat_config|
        form_messages(chat_config)
        send_messages(chat_config)
      end
      update_last_notified_bug(@bugs_to_send.last)
    end

    # Start watcher for new bugs
    # This is endless proccess
    # @return [nil]
    def start_watcher
      loop do
        fetch_info_and_send
        sleep(@config.dig('common_config', 'check_period') || 60)
      end
    end

    private

    # Retrieves chat configurations, excluding the common configuration.
    # @return [Hash] A hash of chat configurations.
    def chat_configs
      @config.except('common_config')
    end

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
