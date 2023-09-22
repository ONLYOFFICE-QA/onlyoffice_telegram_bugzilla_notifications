# frozen_string_literal: true

module OnlyofficeTelegramBugzillaNotifications
  # Class with info about message
  class Message
    # Initialize message
    # @param bugzilla [OnlyofficeBugzillaHelper] instance of bugzilla api
    # @param bug_id [Integer] message for bug to make
    def initialize(bugzilla, bug_id)
      metadata = bugzilla.bug_data(bug_id)
      @string = "Bug #{bug_id}. #{metadata['summary']}\n" \
                "Reported by: #{metadata['creator_detail']['real_name']}\n" \
                "Assigned to: #{metadata['assigned_to_detail']['real_name']}\n" \
                "Severity: #{metadata['severity']}\n" \
                "Version: #{metadata['version']}\n" \
                "#{metadata['product']} -> #{metadata['component']}\n" \
                "#{bugzilla.url}/show_bug.cgi?id=#{bug_id}"
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
