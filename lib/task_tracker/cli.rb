# frozen_string_literal: true

module TaskTracker
  class CLI
    def initialize(args = ARGV, db_path: nil, output: $stdout)
      @args = args
      @output = output
      @db = Database.new(db_path)
    end

    def run
      command = @args.shift
      case command
      when "add"      then cmd_add
      when "edit"     then cmd_edit
      when "delete"   then cmd_delete
      when "move"     then cmd_move
      when "list"     then cmd_list
      when "board"    then cmd_board
      when "log"      then cmd_log
      when "report"   then cmd_report
      when "show"     then cmd_show
      when "help", nil then cmd_help
      else
        @output.puts "Unknown command: #{command}"
        @output.puts "Run 'tt help' for usage information."
      end
    ensure
      @db&.close
    end

    private

    def cmd_add
      opts = parse_options
      title = opts[:positional].join(" ")
      if title.empty?
        @output.puts "Usage: tt add <title> [--desc DESCRIPTION] [--priority PRIORITY] [--tags tag1,tag2] [--due YYYY-MM-DD]"
        return
      end

      task = Task.new(
        title: title,
        description: opts[:desc] || "",
        priority: opts[:priority] || "medium",
        tags: opts[:tags] ? opts[:tags].split(",").map(&:strip) : [],
        due_date: opts[:due]
      )

      id = @db.insert_task(task.to_h)
      @output.puts "Task ##{id} created: #{title}"
    end

    def cmd_edit
      opts = parse_options
      id = opts[:positional].first&.to_i
      unless id && id > 0
        @output.puts "Usage: tt edit <id> [--title TITLE] [--desc DESCRIPTION] [--priority PRIORITY] [--tags tag1,tag2] [--due YYYY-MM-DD]"
        return
      end

      task = @db.find_task(id)
      unless task
        @output.puts "Task ##{id} not found."
        return
      end

      updates = {}
      updates[:title] = opts[:title] if opts[:title]
      updates[:description] = opts[:desc] if opts[:desc]
      updates[:priority] = opts[:priority] if opts[:priority]
      updates[:tags] = opts[:tags].split(",").map(&:strip) if opts[:tags]
      updates[:due_date] = opts[:due] if opts[:due]

      if updates.empty?
        @output.puts "No changes specified."
        return
      end

      @db.update_task(id, updates)
      @output.puts "Task ##{id} updated."
    end

    def cmd_delete
      id = @args.first&.to_i
      unless id && id > 0
        @output.puts "Usage: tt delete <id>"
        return
      end

      task = @db.find_task(id)
      unless task
        @output.puts "Task ##{id} not found."
        return
      end

      @db.delete_task(id)
      @output.puts "Task ##{id} deleted."
    end

    def cmd_move
      id = @args.shift&.to_i
      status = @args.shift

      unless id && id > 0 && status
        @output.puts "Usage: tt move <id> <status>"
        @output.puts "Statuses: todo, doing, done"
        return
      end

      unless Task::STATUSES.include?(status)
        @output.puts "Invalid status: #{status}. Use: #{Task::STATUSES.join(', ')}"
        return
      end

      task = @db.find_task(id)
      unless task
        @output.puts "Task ##{id} not found."
        return
      end

      @db.update_task(id, status: status)
      @output.puts "Task ##{id} moved to #{status}."
    end

    def cmd_list
      opts = parse_options
      filters = {}
      filters[:status] = opts[:status] if opts[:status]
      filters[:priority] = opts[:priority] if opts[:priority]
      filters[:tag] = opts[:tag] if opts[:tag]

      tasks = @db.all_tasks(filters)
      if tasks.empty?
        @output.puts "No tasks found."
        return
      end

      tasks.each do |t|
        task = Task.from_hash(t)
        tags_str = task.tags.empty? ? "" : " [#{task.tags.join(', ')}]"
        due_str = task.due_date ? " (due: #{task.due_date})" : ""
        time_str = task.time_logged > 0 ? " #{task.formatted_time}" : ""
        @output.puts "#%-4d %-8s %s %-6s %s%s%s%s" % [
          task.id, task.status.upcase, task.priority_icon,
          task.priority, task.title, tags_str, due_str, time_str
        ]
      end
    end

    def cmd_board
      board = Board.new(@db)
      @output.puts board.render
    end

    def cmd_log
      id = @args.shift&.to_i
      minutes = @args.shift&.to_i

      unless id && id > 0 && minutes && minutes > 0
        @output.puts "Usage: tt log <id> <minutes> [note]"
        return
      end

      task = @db.find_task(id)
      unless task
        @output.puts "Task ##{id} not found."
        return
      end

      note = @args.join(" ")
      @db.add_time_entry(id, minutes, note)
      @output.puts "Logged #{minutes}m on task ##{id}."
    end

    def cmd_report
      report = Report.new(@db)
      @output.puts report.summary
    end

    def cmd_show
      id = @args.first&.to_i
      unless id && id > 0
        @output.puts "Usage: tt show <id>"
        return
      end

      data = @db.find_task(id)
      unless data
        @output.puts "Task ##{id} not found."
        return
      end

      task = Task.from_hash(data)
      @output.puts "Task ##{task.id}"
      @output.puts "  Title:       #{task.title}"
      @output.puts "  Description: #{task.description}"
      @output.puts "  Status:      #{task.status}"
      @output.puts "  Priority:    #{task.priority}"
      @output.puts "  Tags:        #{task.tags.join(', ')}"
      @output.puts "  Created:     #{task.created_at}"
      @output.puts "  Due Date:    #{task.due_date || 'none'}"
      @output.puts "  Time Logged: #{task.formatted_time}"

      entries = @db.time_entries_for(id)
      unless entries.empty?
        @output.puts "  Time Entries:"
        entries.each do |e|
          note_str = e[:note].to_s.empty? ? "" : " - #{e[:note]}"
          @output.puts "    #{e[:logged_at]} #{e[:minutes]}m#{note_str}"
        end
      end
    end

    def cmd_help
      @output.puts <<~HELP
        Task Tracker - CLI Kanban Board

        Usage: tt <command> [options]

        Commands:
          add <title> [options]       Add a new task
            --desc DESCRIPTION         Task description
            --priority PRIORITY        low, medium, high, critical (default: medium)
            --tags tag1,tag2           Comma-separated tags
            --due YYYY-MM-DD          Due date

          edit <id> [options]         Edit a task
            --title TITLE              New title
            --desc DESCRIPTION         New description
            --priority PRIORITY        New priority
            --tags tag1,tag2           New tags
            --due YYYY-MM-DD          New due date

          delete <id>                Delete a task
          move <id> <status>         Move task to status (todo/doing/done)

          list [options]             List tasks with optional filters
            --status STATUS            Filter by status
            --priority PRIORITY        Filter by priority
            --tag TAG                  Filter by tag

          board                      Show Kanban board
          log <id> <minutes> [note]  Log time on a task
          show <id>                  Show task details
          report                     Show summary report
          help                       Show this help message
      HELP
    end

    def parse_options
      opts = { positional: [] }
      i = 0
      while i < @args.length
        case @args[i]
        when "--desc"
          opts[:desc] = @args[i + 1]
          i += 2
        when "--priority"
          opts[:priority] = @args[i + 1]
          i += 2
        when "--tags"
          opts[:tags] = @args[i + 1]
          i += 2
        when "--tag"
          opts[:tag] = @args[i + 1]
          i += 2
        when "--due"
          opts[:due] = @args[i + 1]
          i += 2
        when "--title"
          opts[:title] = @args[i + 1]
          i += 2
        when "--status"
          opts[:status] = @args[i + 1]
          i += 2
        else
          opts[:positional] << @args[i]
          i += 1
        end
      end
      opts
    end
  end
end
