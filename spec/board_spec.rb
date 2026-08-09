# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe TaskTracker::Board do
  let(:db_path) { File.join(Dir.tmpdir, "task_tracker_board_test_#{Process.pid}_#{rand(10000)}.db") }
  let(:db) { TaskTracker::Database.new(db_path) }
  let(:board) { described_class.new(db) }

  after do
    db.close
    File.delete(db_path) if File.exist?(db_path)
  end

  describe "#render" do
    it "renders an empty board" do
      output = board.render
      expect(output).to include("TO DO")
      expect(output).to include("DOING")
      expect(output).to include("DONE")
    end

    it "renders tasks in correct columns" do
      db.insert_task(title: "Todo task", status: "todo", priority: "medium")
      db.insert_task(title: "Doing task", status: "doing", priority: "high")
      db.insert_task(title: "Done task", status: "done", priority: "low")

      output = board.render
      expect(output).to include("Todo task")
      expect(output).to include("Doing task")
      expect(output).to include("Done task")
    end
  end
end
