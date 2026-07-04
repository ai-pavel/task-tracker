# frozen_string_literal: true

module TaskTracker
  class Board
    COLUMN_WIDTH = 30
    STATUSES = %w[todo doing done].freeze
    STATUS_LABELS = { "todo" => "TO DO", "doing" => "DOING", "done" => "DONE" }.freeze

    def initialize(database)
      @db = database
    end

    def render
      tasks_by_status = {}
      STATUSES.each do |status|
        tasks_by_status[status] = @db.all_tasks(status: status)
      end

      lines = []
      separator = "+" + ("-" * (COLUMN_WIDTH + 2)) + "+" + ("-" * (COLUMN_WIDTH + 2)) + "+" + ("-" * (COLUMN_WIDTH + 2)) + "+"

      # Header
      lines << separator
      header = STATUSES.map { |s| " %-#{COLUMN_WIDTH}s " % STATUS_LABELS[s] }.join("|")
      lines << "|#{header}|"
      lines << separator

      # Find max rows needed
      max_rows = tasks_by_status.values.map(&:length).max || 0

      max_rows.times do |i|
        row_parts = STATUSES.map do |status|
          task = tasks_by_status[status][i]
          if task
            t = Task.from_hash(task)
            label = "##{t.id} #{t.priority_icon} #{t.title}"
            label = label[0, COLUMN_WIDTH] if label.length > COLUMN_WIDTH
            " %-#{COLUMN_WIDTH}s " % label
          else
            " " * (COLUMN_WIDTH + 2)
          end
        end
        lines << "|#{row_parts.join('|')}|"
      end

      lines << separator if max_rows > 0
      lines << separator if max_rows == 0

      lines.join("\n")
    end
  end
end
