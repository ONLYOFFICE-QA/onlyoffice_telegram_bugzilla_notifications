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

    # Form message to send via telegram
    # @param bugs_to_send [Array<Integer>] The array of bug IDs for which messages will be formed.
    # @return [void] This method does not return a value.
    def form_messages(bugs_to_send)
      @messages = []
      bugs_to_send.each do |bug|
        @messages << Message.new(@bugzilla, bug)
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

    # Fetch info about not-notified bugs and send it
    def fetch_info_and_send
      fetch_bugs_to_send
      @config.each do |chat_name, chat_config|
        next if chat_name == 'common_config'

        filtered_bugs = filter_out_bugs(chat_config)
        next if filtered_bugs.empty?

        form_messages(filtered_bugs)
        send_messages(chat_config)
      end
    end

    # Start watcher for new bugs
    # This is endless proccess
    # @return [nil]
    def start_watcher
      loop do
        fetch_info_and_send
        update_last_notified_bug(@bugs_to_send.last) unless @bugs_to_send.last.nil?
        sleep(@config.dig('common_config', 'check_period') || 60)
      end
    end

    private

    # Filters out bugs from the bugs array if they do not pass the checks
    # If the BugFilter#check_all method returns false, the bug ID is removed from the @bugs_to_send array.
    # @param chat_config [Hash] The configuration object for the chat.
    # @param bugs [Array<Integer>] The array of bug IDs to filter. Defaults to @bugs_to_send.
    # @return [Array<Integer>] The filtered array of bug IDs.
    def filter_out_bugs(chat_config, bugs = @bugs_to_send)
      bugs.select { |bug_id| BugFilter.new(@bugzilla, chat_config, bug_id).check_all }
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
