# frozen_string_literal: true

module TaskTracker
  class Task
    STATUSES = %w[todo doing done].freeze
    PRIORITIES = %w[low medium high critical].freeze

    attr_accessor :id, :title, :description, :status, :priority, :tags,
                  :created_at, :due_date, :time_logged

    def initialize(attrs = {})
      @id = attrs[:id]
      @title = attrs[:title]
      @description = attrs[:description] || ""
      @status = attrs[:status] || "todo"
      @priority = attrs[:priority] || "medium"
      @tags = attrs[:tags] || []
      @created_at = attrs[:created_at] || Time.now.strftime("%Y-%m-%d %H:%M:%S")
      @due_date = attrs[:due_date]
      @time_logged = attrs[:time_logged] || 0

      validate!
    end

    def validate!
      raise ArgumentError, "Title is required" if @title.nil? || @title.strip.empty?
      raise ArgumentError, "Invalid status: #{@status}" unless STATUSES.include?(@status)
      raise ArgumentError, "Invalid priority: #{@priority}" unless PRIORITIES.include?(@priority)
    end

    def to_h
      {
        id: @id,
        title: @title,
        description: @description,
        status: @status,
        priority: @priority,
        tags: @tags,
        created_at: @created_at,
        due_date: @due_date,
        time_logged: @time_logged
      }
    end

    def priority_icon
      case @priority
      when "critical" then "!!!"
      when "high"     then "!! "
      when "medium"   then "!  "
      when "low"      then ".  "
      end
    end

    def formatted_time
      return "0m" if @time_logged.zero?

      hours = @time_logged / 60
      mins = @time_logged % 60
      parts = []
      parts << "#{hours}h" if hours > 0
      parts << "#{mins}m" if mins > 0
      parts.join(" ")
    end

    def self.from_hash(hash)
      new(hash)
    end
  end
end
