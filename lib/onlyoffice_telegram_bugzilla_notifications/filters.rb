# frozen_string_literal: true

module OnlyofficeTelegramBugzillaNotifications
  # Class to filter bugs by parameter
  class Filters
    def initialize(bugzilla, config, bug_id)
      @bugzilla = bugzilla
      @config = config
      @bug_id = bug_id
      @bug_info = @bugzilla.bug_data(@bug_id)
    end

    def check_all
      by_product
    end

    def by_product
      @config['products']&.include?(@bug_info['product']) || @config['products'].nil? || @bug_info['product'].nil?
    end
  end
end
