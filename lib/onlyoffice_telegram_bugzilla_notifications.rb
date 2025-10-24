# frozen_string_literal: true

require 'onlyoffice_bugzilla_helper'
require 'telegram/bot'
require 'yaml'
require_relative 'onlyoffice_telegram_bugzilla_notifications/message'
require_relative 'onlyoffice_telegram_bugzilla_notifications/bug_filter'
require_relative 'onlyoffice_telegram_bugzilla_notifications/additional_bugs'

# Namespace of `onlyoffice_telegram_bugzilla_notifications`
module OnlyofficeTelegramBugzillaNotifications
  # Class for sending notifications
  class TelegramBugzillaNotifications
    def initialize(config_path = 'config.yml')
      @last_send_bug_storage = 'last_send_bug.info'
      @start_check_time_storage = 'start_check_time.info'
      @config = YAML.load_file(config_path)
      @bugzilla = OnlyofficeBugzillaHelper::BugzillaHelper.new(bugzilla_url: @config['common_config']['bugzilla_url'],
                                                               api_key: @config['common_config']['bugzilla_key'])
      @logger = Logger.new($stdout)
      @additional_bugs = AdditionalBugs.new(@bugzilla)
    end

    # TODO Test additional bugs
    def test_additional_bugs
      chat_configs.each_value do |chat_config|
        if chat_config['additional_bugs']
          bugs = @additional_bugs.fetch_bugs_by_additional_bugs(chat_config['additional_bugs'], (Time.now.utc - 86400 * 10).iso8601)
          p @additional_bugs.get_last_check_time_from_bugs
        end
      end
    end

    # Fetch list of bugs need to be send
    # @return [nil]
    def fetch_new_bugs_to_send
      @new_bugs_to_send = []
      current_bug = latest_notified_bug + 1
      while @bugzilla.bug_exists?(current_bug)
        @new_bugs_to_send << current_bug
        current_bug += 1
      end
      @logger.info("List of new bugs: #{@new_bugs_to_send}")
    end

    def fetch_additional_bugs_to_send(chat_config)
      config = chat_config['additional_bugs']
      return [] unless config

      @additional_bugs_to_send = @additional_bugs.fetch_bugs_by_additional_bugs(config, load_start_check_time)
      @logger.info("List of additional bugs: #{@additional_bugs_to_send}")
      @additional_bugs_to_send
    end

    # Forms messages to be sent via Telegram based on the bug data and chat configuration.
    # Iterates through the list of bug data, applies the filters specified in the chat configuration,
    # and creates a message for each bug that passes the filters.
    # The resulting messages are stored in the instance variable `@messages`.
    # @param chat_config [Hash] The configuration hash for the chat,
    #   containing the filter criteria and other settings for the messages.
    # @param bugs_data_list [Array<Hash>] array of bug data to process
    def form_messages_for_chat(chat_config, bugs_data_list)
      @messages = []
      bugs_data_list.each do |bug_data|
        @messages << Message.new(bug_data, @bugzilla.url) if BugFilter.new(chat_config, bug_data).filtered_all?
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
          @logger.info("Send info about bug: #{@new_bugs_to_send[index]}")
        end
      end
    end

    # Fetches data for each bug in the list of bugs to send.
    # The data for each bug is retrieved using the Bugzilla API.
    # The resulting data is stored in the instance variable `@bugs_data_list`.
    def fetch_bugs_data(bug_list)
      @bugs_data_list = bug_list.map { |bug_id| @bugzilla.bug_data(bug_id) }
    end

    # Fetch info about not-notified bugs and send it
    def fetch_info_and_send
      fetch_new_bugs_to_send

      chat_configs.each_value do |chat_config|
        additional_bugs = fetch_additional_bugs_to_send(chat_config)
        chat_bugs_to_send = (@new_bugs_to_send + additional_bugs).uniq

        next if chat_bugs_to_send.empty?

        @logger.info("Processing #{chat_bugs_to_send.size} bugs for chat #{chat_config['channel_id']}")

        form_messages_for_chat(chat_config, fetch_bugs_data(chat_bugs_to_send))
        send_messages(chat_config)

        update_start_check_time(@additional_bugs.get_last_check_time_from_bugs) unless additional_bugs.empty?
      end
      update_last_notified_bug(@new_bugs_to_send.last) unless @new_bugs_to_send.empty?
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

    def load_start_check_time
      return Time.now.utc.iso8601 unless File.exist?(@start_check_time_storage)

      File.read(@start_check_time_storage).strip
    rescue StandardError => e
      @logger.error("Error loading start check time: #{e.message}")
    end

    def update_start_check_time(time)
      @logger.info("Change start check time to: #{time}")
      File.write(@start_check_time_storage, time)
    end
  end
end
