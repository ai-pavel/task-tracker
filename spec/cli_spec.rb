# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "stringio"

RSpec.describe TaskTracker::CLI do
  let(:db_path) { File.join(Dir.tmpdir, "task_tracker_cli_test_#{Process.pid}_#{rand(10000)}.db") }
  let(:output) { StringIO.new }

  def run_cli(*args)
    cli = described_class.new(args.flatten, db_path: db_path, output: output)
    cli.run
    output.string
  end

  after do
    File.delete(db_path) if File.exist?(db_path)
  end

  describe "add" do
    it "creates a new task" do
      result = run_cli("add", "My new task")
      expect(result).to include("Task #1 created")
      expect(result).to include("My new task")
    end

    it "creates a task with options" do
      result = run_cli("add", "Priority task", "--priority", "critical", "--tags", "urgent,bug", "--due", "2026-12-31")
      expect(result).to include("Task #1 created")
    end

    it "shows usage when no title given" do
      result = run_cli("add")
      expect(result).to include("Usage")
    end
  end

  describe "list" do
    before do
      run_cli("add", "Task one", "--priority", "high", "--tags", "work")
      output.truncate(0)
      output.rewind
      run_cli("add", "Task two", "--priority", "low", "--tags", "personal")
      output.truncate(0)
      output.rewind
    end

    it "lists all tasks" do
      result = run_cli("list")
      expect(result).to include("Task one")
      expect(result).to include("Task two")
    end

    it "filters by priority" do
      result = run_cli("list", "--priority", "high")
      expect(result).to include("Task one")
      expect(result).not_to include("Task two")
    end

    it "filters by tag" do
      result = run_cli("list", "--tag", "personal")
      expect(result).not_to include("Task one")
      expect(result).to include("Task two")
    end
  end

  describe "move" do
    before do
      run_cli("add", "Movable task")
      output.truncate(0)
      output.rewind
    end

    it "moves a task to a new status" do
      result = run_cli("move", "1", "doing")
      expect(result).to include("moved to doing")
    end

    it "rejects invalid status" do
      result = run_cli("move", "1", "invalid")
      expect(result).to include("Invalid status")
    end

    it "reports missing task" do
      result = run_cli("move", "999", "done")
      expect(result).to include("not found")
    end
  end

  describe "delete" do
    before do
      run_cli("add", "Deletable task")
      output.truncate(0)
      output.rewind
    end

    it "deletes a task" do
      result = run_cli("delete", "1")
      expect(result).to include("deleted")
    end

    it "reports missing task" do
      result = run_cli("delete", "999")
      expect(result).to include("not found")
    end
  end

  describe "edit" do
    before do
      run_cli("add", "Editable task")
      output.truncate(0)
      output.rewind
    end

    it "edits a task" do
      result = run_cli("edit", "1", "--title", "New title", "--priority", "critical")
      expect(result).to include("updated")
    end

    it "reports no changes" do
      result = run_cli("edit", "1")
      expect(result).to include("No changes")
    end
  end

  describe "log" do
    before do
      run_cli("add", "Loggable task")
      output.truncate(0)
      output.rewind
    end

    it "logs time on a task" do
      result = run_cli("log", "1", "30", "Worked on it")
      expect(result).to include("Logged 30m")
    end
  end

  describe "board" do
    it "displays the kanban board" do
      run_cli("add", "Board task")
      output.truncate(0)
      output.rewind
      result = run_cli("board")
      expect(result).to include("TO DO")
      expect(result).to include("Board task")
    end
  end

  describe "report" do
    it "displays a summary report" do
      run_cli("add", "Report task", "--priority", "high")
      output.truncate(0)
      output.rewind
      result = run_cli("report")
      expect(result).to include("TASK TRACKER REPORT")
      expect(result).to include("Total Tasks: 1")
    end
  end

  describe "help" do
    it "shows help text" do
      result = run_cli("help")
      expect(result).to include("Task Tracker")
      expect(result).to include("Commands")
    end

    it "shows help for no command" do
      result = run_cli
      expect(result).to include("Task Tracker")
    end
  end

  describe "unknown command" do
    it "shows error for unknown command" do
      result = run_cli("unknown")
      expect(result).to include("Unknown command")
    end
  end
end
