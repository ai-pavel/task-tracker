# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe TaskTracker::Database do
  let(:db_path) { File.join(Dir.tmpdir, "task_tracker_test_#{Process.pid}_#{rand(10000)}.db") }
  let(:db) { described_class.new(db_path) }

  after do
    db.close
    File.delete(db_path) if File.exist?(db_path)
  end

  describe "#insert_task" do
    it "inserts a task and returns its id" do
      id = db.insert_task(title: "New task", status: "todo", priority: "medium")
      expect(id).to be_a(Integer)
      expect(id).to be > 0
    end
  end

  describe "#find_task" do
    it "finds a task by id" do
      id = db.insert_task(title: "Find me", status: "todo", priority: "high", tags: %w[test])
      task = db.find_task(id)
      expect(task[:title]).to eq("Find me")
      expect(task[:priority]).to eq("high")
      expect(task[:tags]).to eq(["test"])
    end

    it "returns nil for nonexistent task" do
      expect(db.find_task(9999)).to be_nil
    end
  end

  describe "#update_task" do
    it "updates task attributes" do
      id = db.insert_task(title: "Original", status: "todo", priority: "low")
      db.update_task(id, title: "Updated", priority: "high")
      task = db.find_task(id)
      expect(task[:title]).to eq("Updated")
      expect(task[:priority]).to eq("high")
    end

    it "updates tags" do
      id = db.insert_task(title: "Tagged", tags: %w[a b])
      db.update_task(id, tags: %w[c d e])
      task = db.find_task(id)
      expect(task[:tags]).to eq(%w[c d e])
    end
  end

  describe "#delete_task" do
    it "removes a task" do
      id = db.insert_task(title: "Delete me")
      db.delete_task(id)
      expect(db.find_task(id)).to be_nil
    end
  end

  describe "#all_tasks" do
    before do
      db.insert_task(title: "Task 1", status: "todo", priority: "high", tags: %w[work])
      db.insert_task(title: "Task 2", status: "doing", priority: "low", tags: %w[personal])
      db.insert_task(title: "Task 3", status: "done", priority: "high", tags: %w[work urgent])
    end

    it "returns all tasks without filters" do
      expect(db.all_tasks.length).to eq(3)
    end

    it "filters by status" do
      tasks = db.all_tasks(status: "todo")
      expect(tasks.length).to eq(1)
      expect(tasks.first[:title]).to eq("Task 1")
    end

    it "filters by priority" do
      tasks = db.all_tasks(priority: "high")
      expect(tasks.length).to eq(2)
    end

    it "filters by tag" do
      tasks = db.all_tasks(tag: "work")
      expect(tasks.length).to eq(2)
    end
  end

  describe "#add_time_entry" do
    it "logs time and updates task total" do
      id = db.insert_task(title: "Timed task")
      db.add_time_entry(id, 30, "First session")
      db.add_time_entry(id, 45, "Second session")

      task = db.find_task(id)
      expect(task[:time_logged]).to eq(75)

      entries = db.time_entries_for(id)
      expect(entries.length).to eq(2)
      expect(entries.first[:minutes]).to eq(30)
      expect(entries.first[:note]).to eq("First session")
    end
  end
end
