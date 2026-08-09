# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe TaskTracker::Report do
  let(:db_path) { File.join(Dir.tmpdir, "task_tracker_report_test_#{Process.pid}_#{rand(10000)}.db") }
  let(:db) { TaskTracker::Database.new(db_path) }
  let(:report) { described_class.new(db) }

  after do
    db.close
    File.delete(db_path) if File.exist?(db_path)
  end

  describe "#summary" do
    it "shows empty report" do
      output = report.summary
      expect(output).to include("TASK TRACKER REPORT")
      expect(output).to include("Total Tasks: 0")
    end

    it "shows status and priority breakdown" do
      db.insert_task(title: "T1", status: "todo", priority: "high")
      db.insert_task(title: "T2", status: "doing", priority: "low")
      db.insert_task(title: "T3", status: "done", priority: "high")

      output = report.summary
      expect(output).to include("Total Tasks: 3")
      expect(output).to include("TODO")
      expect(output).to include("DOING")
      expect(output).to include("DONE")
      expect(output).to include("High")
    end

    it "shows time logged summary" do
      id = db.insert_task(title: "Timed", status: "todo", priority: "medium")
      db.add_time_entry(id, 90, "Work")

      output = report.summary
      expect(output).to include("1h 30m")
      expect(output).to include("Top Tasks by Time")
    end

    it "shows tags" do
      db.insert_task(title: "Tagged", status: "todo", priority: "medium", tags: %w[ruby test])

      output = report.summary
      expect(output).to include("ruby")
      expect(output).to include("test")
    end
  end
end
