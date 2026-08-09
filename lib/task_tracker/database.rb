# frozen_string_literal: true

require "sqlite3"
require "json"

module TaskTracker
  class Database
    DEFAULT_DB_PATH = File.join(Dir.home, ".task_tracker.db")

    attr_reader :db

    def initialize(db_path = nil)
      @db_path = db_path || DEFAULT_DB_PATH
      @db = SQLite3::Database.new(@db_path)
      @db.results_as_hash = true
      create_tables
    end

    def create_tables
      @db.execute <<-SQL
        CREATE TABLE IF NOT EXISTS tasks (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          title TEXT NOT NULL,
          description TEXT DEFAULT '',
          status TEXT NOT NULL DEFAULT 'todo',
          priority TEXT NOT NULL DEFAULT 'medium',
          tags TEXT DEFAULT '[]',
          created_at TEXT NOT NULL,
          due_date TEXT,
          time_logged INTEGER DEFAULT 0
        );
      SQL

      @db.execute <<-SQL
        CREATE TABLE IF NOT EXISTS time_entries (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          task_id INTEGER NOT NULL,
          minutes INTEGER NOT NULL,
          note TEXT DEFAULT '',
          logged_at TEXT NOT NULL,
          FOREIGN KEY (task_id) REFERENCES tasks(id) ON DELETE CASCADE
        );
      SQL
    end

    def insert_task(attrs)
      @db.execute(
        "INSERT INTO tasks (title, description, status, priority, tags, created_at, due_date, time_logged) VALUES (?, ?, ?, ?, ?, ?, ?, ?)",
        [
          attrs[:title],
          attrs[:description] || "",
          attrs[:status] || "todo",
          attrs[:priority] || "medium",
          (attrs[:tags] || []).to_json,
          attrs[:created_at] || Time.now.strftime("%Y-%m-%d %H:%M:%S"),
          attrs[:due_date],
          attrs[:time_logged] || 0
        ]
      )
      @db.last_insert_row_id
    end

    def update_task(id, attrs)
      sets = []
      values = []
      attrs.each do |key, value|
        case key
        when :tags
          sets << "tags = ?"
          values << value.to_json
        else
          sets << "#{key} = ?"
          values << value
        end
      end
      values << id
      @db.execute("UPDATE tasks SET #{sets.join(', ')} WHERE id = ?", values)
    end

    def delete_task(id)
      @db.execute("DELETE FROM time_entries WHERE task_id = ?", [id])
      @db.execute("DELETE FROM tasks WHERE id = ?", [id])
    end

    def find_task(id)
      row = @db.get_first_row("SELECT * FROM tasks WHERE id = ?", [id])
      return nil unless row

      row_to_hash(row)
    end

    def all_tasks(filters = {})
      conditions = []
      values = []

      if filters[:status]
        conditions << "status = ?"
        values << filters[:status]
      end

      if filters[:priority]
        conditions << "priority = ?"
        values << filters[:priority]
      end

      if filters[:tag]
        conditions << "tags LIKE ?"
        values << "%\"#{filters[:tag]}\"%"
      end

      sql = "SELECT * FROM tasks"
      sql += " WHERE #{conditions.join(' AND ')}" unless conditions.empty?
      sql += " ORDER BY id ASC"

      @db.execute(sql, values).map { |row| row_to_hash(row) }
    end

    def add_time_entry(task_id, minutes, note = "")
      @db.execute(
        "INSERT INTO time_entries (task_id, minutes, note, logged_at) VALUES (?, ?, ?, ?)",
        [task_id, minutes, note, Time.now.strftime("%Y-%m-%d %H:%M:%S")]
      )
      @db.execute(
        "UPDATE tasks SET time_logged = time_logged + ? WHERE id = ?",
        [minutes, task_id]
      )
    end

    def time_entries_for(task_id)
      @db.execute("SELECT * FROM time_entries WHERE task_id = ? ORDER BY logged_at ASC", [task_id]).map do |row|
        {
          id: row["id"],
          task_id: row["task_id"],
          minutes: row["minutes"],
          note: row["note"],
          logged_at: row["logged_at"]
        }
      end
    end

    def close
      @db.close
    end

    private

    def row_to_hash(row)
      {
        id: row["id"],
        title: row["title"],
        description: row["description"],
        status: row["status"],
        priority: row["priority"],
        tags: JSON.parse(row["tags"] || "[]"),
        created_at: row["created_at"],
        due_date: row["due_date"],
        time_logged: row["time_logged"] || 0
      }
    end
  end
end
