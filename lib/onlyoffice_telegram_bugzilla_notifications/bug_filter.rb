# frozen_string_literal: true

module OnlyofficeTelegramBugzillaNotifications
  # Class to filter bugs by parameter
  class BugFilter
    # Initialize the Filters object
    # @param config [Hash] Configuration options for filtering
    # @param bug_data [Hash] The data of the bug to be filtered
    def initialize(config, bug_data)
      @config = config
      @bug_data = bug_data
    end

    # Check all filters
    # @return [Boolean] Result of applying all filters
    def filtered_all?
      by_product
    end

    # Filter bugs by product
    # @return [Boolean] True if the bug's product matches the configured products,
    #   or if the product filter is not set, or if the bug's product is not set
    def by_product
      @config['products']&.include?(@bug_data['product']) || @config['products'].nil? || @bug_data['product'].nil?
    end
  end
end
