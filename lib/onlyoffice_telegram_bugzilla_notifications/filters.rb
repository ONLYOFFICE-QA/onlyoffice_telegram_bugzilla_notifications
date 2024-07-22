# frozen_string_literal: true

module OnlyofficeTelegramBugzillaNotifications
  # Class to filter bugs by parameter
  class Filters
    # Initialize the Filters object
    # @param bugzilla [OnlyofficeBugzillaHelper] instance of bugzilla api
    # @param config [Hash] Configuration options for filtering
    # @param bug_id [Integer] ID of the bug to be filter
    def initialize(bugzilla, config, bug_id)
      @bugzilla = bugzilla
      @config = config
      @bug_id = bug_id
      @bug_info = @bugzilla.bug_data(@bug_id)
    end

    # Check all filters
    # @return [Boolean] Result of applying all filters
    def check_all
      by_product
    end

    # Filter bugs by product
    # @return [Boolean] True if the bug's product matches the configured products,
    #   or if the product filter is not set, or if the bug's product is not set
    def by_product
      @config['products']&.include?(@bug_info['product']) || @config['products'].nil? || @bug_info['product'].nil?
    end
  end
end
