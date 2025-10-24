# frozen_string_literal: true

module OnlyofficeTelegramBugzillaNotifications
  # Class to filter bugs by parameter
  class AdditionalBugs
    # Initialize the BugGetter object
    # @param bugzilla_url [String] The URL of the Bugzilla instance
    def initialize(bugzilla)
      @bugzilla = bugzilla
    end

    # Fetch bugs by additional bugs
    # @param filters [Hash] The filters to apply to the bugs
    # @param start_check_time [String] The time to start checking for bugs
    # @return [Array<Integer>] The list of bug IDs
    def fetch_bugs_by_additional_bugs(filters, start_check_time)
      bugs_to_send = []

      filters.each do |filter_config|
        next unless filter_config.is_a?(Hash) && filter_config['filters']

        filters = filter_config['filters']
        filters['last_change_time'] = start_check_time

        filters_hash = convert_filters_to_hash(filter_config['filters'])

        @bugs = @bugzilla.get_bugs_by_filter(filters_hash)
        @bugs.map { |bug| bug['id'] }.uniq.each do |bug_id|
          bug_history = @bugzilla.get_bug_history(bug_id)

          next unless bug_history.any? do |history|
            history['changes'].any? do |change|
              (history['when'] > start_check_time) && (change['field_name'] == 'status') && (change['added'] == 'REOPENED')
            end
          end

          bugs_to_send << bug_id
        end
      end
      bugs_to_send
    end

    def get_last_check_time_from_bugs
      @bugs.map { |bug| bug['last_change_time'] }.max
    end

    # Get bug history
    # @param bug_id [Integer] The ID of the bug
    # @return [Array<Hash>] The list of bug history
    def get_bug_history(bug_id)
      @bugzilla.get_bug_history(bug_id)
    end

    # Get bugs
    # @return [Array<Hash>] The list of bugs
    def get_bugs_by_filters(filters)
      @bugzilla.get_bugs_result(filters)
    end

    private

    # Convert filters from YAML format (string keys) to hash rocket format (symbol keys with =>)
    # @param filters [Hash] filters hash with string keys
    # @return [Hash] filters hash with string keys and hash rocket syntax
    def convert_filters_to_hash(filters)
      return {} unless filters.is_a?(Hash)

      filters.transform_keys(&:to_s)
    end
  end
end
