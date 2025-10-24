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
      @start_check_time_storage = 'start_check_times.yml'
      @config = YAML.load_file(config_path)
      @bugzilla = OnlyofficeBugzillaHelper::BugzillaHelper.new(bugzilla_url: @config['common_config']['bugzilla_url'],
                                                               api_key: @config['common_config']['bugzilla_key'])
      @logger = Logger.new($stdout)
      @additional_bugs = AdditionalBugs.new(@bugzilla)
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

    # Fetch additional bugs to send
    # @param additional_bugs_config [Hash] The configuration hash for the additional bugs
    # @param chat_name [String] name of the chat configuration
    # @return [Array<Integer>] The list of bug IDs
    def fetch_additional_bugs_to_send(additional_bugs_config, chat_name)
      return [] unless additional_bugs_config

      @additional_bugs_to_send = @additional_bugs.fetch_bugs_by_additional_bugs(additional_bugs_config,
                                                                                load_start_check_time(chat_name))
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
      chat_configs.each { |chat_name, chat_config| process_chat(chat_name, chat_config) }
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

    # Process bugs for a single chat
    # @param chat_name [String] name of the chat configuration
    # @param chat_config [Hash] configuration for the chat
    def process_chat(chat_name, chat_config)
      additional_bugs = fetch_additional_bugs_to_send(chat_config['additional_bugs'], chat_name)
      chat_bugs_to_send = (@new_bugs_to_send + additional_bugs).uniq
      return if chat_bugs_to_send.empty?

      @logger.info("Processing #{chat_bugs_to_send.size} bugs for chat #{chat_config['channel_id']}")
      form_messages_for_chat(chat_config, fetch_bugs_data(chat_bugs_to_send))
      send_messages(chat_config)
      update_start_check_time(chat_name, @additional_bugs.last_check_time_from_bugs) unless additional_bugs.empty?
    end

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

    # Load start check time for specific chat and filter
    # @param chat_name [String] name of the chat configuration
    # @return [String] ISO8601 timestamp
    def load_start_check_time(chat_name)
      return Time.now.utc.iso8601 unless File.exist?(@start_check_time_storage)

      times = YAML.load_file(@start_check_time_storage) || {}
      times[chat_name] || Time.now.utc.iso8601
    rescue StandardError => e
      @logger.error("Error loading start check time for #{chat_name}: #{e.message}")
    end

    # Update start check time for specific chat and filter
    # @param chat_name [String] name of the chat configuration
    # @param time [String] ISO8601 timestamp
    def update_start_check_time(chat_name, time)
      @logger.info("Change start check time for #{chat_name} to: #{time}")

      times = File.exist?(@start_check_time_storage) ? (YAML.load_file(@start_check_time_storage) || {}) : {}
      times[chat_name] = time
      File.write(@start_check_time_storage, times.to_yaml)
    rescue StandardError => e
      @logger.error("Error updating start check time for #{chat_name}: #{e.message}")
    end
  end
end
