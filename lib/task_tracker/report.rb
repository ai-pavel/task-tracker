# frozen_string_literal: true

module TaskTracker
  class Report
    def initialize(database)
      @db = database
    end

    def summary
      all = @db.all_tasks
      lines = []

      lines << "=" * 50
      lines << "  TASK TRACKER REPORT"
      lines << "=" * 50
      lines << ""

      # Status breakdown
      lines << "Status Breakdown:"
      %w[todo doing done].each do |status|
        count = all.count { |t| t[:status] == status }
        lines << "  %-10s %d" % [status.upcase, count]
      end
      lines << ""

      # Priority breakdown
      lines << "Priority Breakdown:"
      %w[critical high medium low].each do |priority|
        count = all.count { |t| t[:priority] == priority }
        lines << "  %-10s %d" % [priority.capitalize, count]
      end
      lines << ""

      # Time logged
      total_minutes = all.sum { |t| t[:time_logged] }
      hours = total_minutes / 60
      mins = total_minutes % 60
      lines << "Total Time Logged: #{hours}h #{mins}m"
      lines << ""

      # Tasks with most time
      if all.any? { |t| t[:time_logged] > 0 }
        lines << "Top Tasks by Time:"
        all.select { |t| t[:time_logged] > 0 }
           .sort_by { |t| -t[:time_logged] }
           .first(5)
           .each do |t|
          task = Task.from_hash(t)
          lines << "  ##{t[:id]} #{t[:title]} - #{task.formatted_time}"
        end
        lines << ""
      end

      # Tags
      all_tags = all.flat_map { |t| t[:tags] }.uniq.sort
      unless all_tags.empty?
        lines << "Tags: #{all_tags.join(', ')}"
        lines << ""
      end

      # Overdue tasks
      today = Time.now.strftime("%Y-%m-%d")
      overdue = all.select { |t| t[:due_date] && t[:due_date] < today && t[:status] != "done" }
      unless overdue.empty?
        lines << "Overdue Tasks:"
        overdue.each do |t|
          lines << "  ##{t[:id]} #{t[:title]} (due: #{t[:due_date]})"
        end
        lines << ""
      end

      lines << "Total Tasks: #{all.length}"
      lines << "=" * 50

      lines.join("\n")
    end
  end
end
