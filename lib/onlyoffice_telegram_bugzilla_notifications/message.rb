# frozen_string_literal: true

module OnlyofficeTelegramBugzillaNotifications
  # Class with info about message
  class Message
    # Initialize message
    # @param bug_data [Hash] The data of the bug.
    # @param bugzilla_url [String] The base URL of the Bugzilla instance, used to create a link to the bug.
    def initialize(bug_data, bugzilla_url)
      @string = "Bug #{bug_data['id']}. #{bug_data['summary']}\n" \
                "Status: #{bug_data['status']}\n" \
                "Reported by: #{bug_data['creator_detail']['real_name']}\n" \
                "Assigned to: #{bug_data['assigned_to_detail']['real_name']}\n" \
                "Severity: #{bug_data['severity']}\n" \
                "Version: #{bug_data['version']}\n" \
                "#{bug_data['product']} -> #{bug_data['component']}\n" \
                "#{bugzilla_url}/show_bug.cgi?id=#{bug_data['id']}"
    end

    # @return [String] default string formatter
    def to_s
      @string
    end

    # @return [String] for logger purposes, single line
    def for_logger
      to_s.gsub("\n", '\\n')
    end
  end
end
