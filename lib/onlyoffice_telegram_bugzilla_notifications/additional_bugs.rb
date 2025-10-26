# frozen_string_literal: true

module OnlyofficeTelegramBugzillaNotifications
  # Class to filter bugs by parameter
  class AdditionalBugs
    # Initialize the BugGetter object
    # @param bugzilla BugzillaHelper instance
    def initialize(bugzilla)
      @bugzilla = bugzilla
    end

    # Fetch bugs by additional bugs
    # @param filters [Hash] The filters to apply to the bugs
    # @param start_check_time [String] The time to start checking for bugs
    # @return [Array<Integer>] The list of bug IDs
    def fetch_additional_bugs(filters, start_check_time)
      bugs_to_send = []
      filters.each do |filter_config|
        bugs_to_send.concat(process_filter_config(filter_config, start_check_time))
      end
      bugs_to_send
    end

    # Get the latest check time from the bugs
    # @return [String] The latest check time
    def last_check_time_from_bugs
      @bugs.map { |bug| bug['last_change_time'] }.max
    end

    # Get bug history
    # @param bug_id [Integer] The ID of the bug
    # @return [Array<Hash>] The list of bug history
    def get_bug_history(bug_id)
      @bugzilla.get_bug_history(bug_id)
    end

    # Get bugs
    # @param filters [Hash] The filters to apply to the bugs
    # @return [Array<Hash>] The list of bugs
    def get_bugs_by_filters(filters)
      @bugzilla.get_bugs_by_filter(filters)
    end

    private

    # Process single filter configuration
    # @param filter_config [Hash] The filter configuration to process
    # @param start_check_time [String] The time to start checking for bugs
    # @return [Array<Integer>] The list of bug IDs matching the filter
    def process_filter_config(filter_config, start_check_time)
      return [] unless filter_config.is_a?(Hash) && filter_config['filters']

      filters = filter_config['filters']
      filters['last_change_time'] = start_check_time
      filters_hash = convert_filters_to_hash(filters)
      @bugs = get_bugs_by_filters(filters_hash)

      @bugs.map { |bug| bug['id'] }.uniq.select do |bug_id|
        bug_history = @bugzilla.get_bug_history(bug_id)
        bug_matches_history_filters?(bug_history, filters, start_check_time)
      end
    end

    # Check if bug history matches the provided filters
    # @param bug_history [Array<Hash>] The bug history to check
    # @param filters [Hash] The filters to apply
    # @param start_check_time [String] The time to start checking for bugs
    # @return [Boolean] True if bug matches filters
    def bug_matches_history_filters?(bug_history, filters, start_check_time)
      # Get filters that should be checked in history (excluding technical fields)
      history_filters = filters.except('last_change_time')

      bug_history.any? do |history|
        next unless history['when'] > start_check_time

        history['changes'].any? do |change|
          match_change_with_filters?(change, history_filters)
        end
      end
    end

    # Check if a single change matches any of the filters
    # @param change [Hash] The change to check
    # @param filters [Hash] The filters to apply
    # @return [Boolean] True if change matches filters
    def match_change_with_filters?(change, filters)
      filters.any? do |field, value|
        change['field_name'] == field && change['added'] == value
      end
    end

    # Convert filters from YAML format (string keys) to hash rocket format (symbol keys with =>)
    # @param filters [Hash] filters hash with string keys
    # @return [Hash] filters hash with string keys and hash rocket syntax
    def convert_filters_to_hash(filters)
      return {} unless filters.is_a?(Hash)

      filters.transform_keys(&:to_s)
    end
  end
end
