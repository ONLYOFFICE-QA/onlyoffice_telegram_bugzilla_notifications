# frozen_string_literal: true

module OnlyofficeTelegramBugzillaNotifications
  # Class to filter bugs by parameter
  class AdditionalBugs
    # Initialize the BugGetter object
    # @param bugzilla BugzillaHelper instance
    def initialize(bugzilla)
      @bugzilla = bugzilla
      @last_checked_bug_id = nil
      @last_checked_time = nil
    end

    # Get the last checked bug id
    # @return [Integer] The last checked bug id
    def last_checked_bug_id
      @last_checked_bug_id
    end

    # Get the last checked time
    # @return [String] The last checked time
    def last_checked_time
      @last_checked_time
    end

    # Fetch bugs by additional bugs
    # @param filters [Hash] The filters to apply to the bugs
    # @param start_check_time [String] The time to start checking for bugs
    # @return [Array<Integer>] The list of bug IDs
    def fetch_additional_bugs(filters_list, start_check_time)
      bugs_to_send = []
      filters_list.each do |filter|
        bugs_to_send.concat(process_filter_config(filter, start_check_time))
      end
      last_check_time_from_bugs
      bugs_to_send
    end

    # Get the latest check time from the bugs
    # @return [Hash] Hash with bug_id and last_change_time of the latest bug
    def last_check_time_from_bugs
      return nil if @bugs.nil? || @bugs.empty?

      latest_bug = @bugs.max_by { |bug| bug['last_change_time'] }
      @last_checked_bug_id = latest_bug['id']
      @last_checked_time = latest_bug['last_change_time']
      { bug_id: @last_checked_bug_id, last_change_time: @last_checked_time }
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
      @bugs = @bugzilla.get_bugs_by_filter(filters)
      @bugs
    end

    private

    # Process single filter configuration
    # @param filters [Hash] The filters to process
    # @param start_check_time [String] The time to start checking for bugs
    # @return [Array<Integer>] The list of bug IDs matching the filter
    def process_filter_config(filters, start_check_time)
      return [] unless filters.is_a?(Hash)

      filters['last_change_time'] = start_check_time
      filters_hash = convert_filters_to_hash(filters)
      get_bugs_by_filters(filters_hash)

      @bugs.map { |bug| bug['id'] }.uniq.select do |bug_id|
        next if bug_id == @last_checked_bug_id && start_check_time == @last_checked_time

        bug_history = @bugzilla.get_bug_history(bug_id)
        bug_matches_history_filters?(bug_history, filters)
      end
    end

    # Check if bug history matches the provided filters
    # @param bug_history [Array<Hash>] The bug history to check
    # @param filters [Hash] The filters to apply
    # @return [Boolean] True if bug matches filters
    def bug_matches_history_filters?(bug_history, filters)
      # Get filters that should be checked in history (excluding technical fields)
      history_filters = filters.except('last_change_time')
      bug_history.any? do |history|
        next unless history['when'] > filters['last_change_time']

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
