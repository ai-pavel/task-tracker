# frozen_string_literal: true

require "spec_helper"

RSpec.describe TaskTracker::Task do
  describe "#initialize" do
    it "creates a task with default values" do
      task = described_class.new(title: "Test task")
      expect(task.title).to eq("Test task")
      expect(task.status).to eq("todo")
      expect(task.priority).to eq("medium")
      expect(task.tags).to eq([])
      expect(task.description).to eq("")
      expect(task.time_logged).to eq(0)
    end

    it "creates a task with all attributes" do
      task = described_class.new(
        title: "Full task",
        description: "A description",
        status: "doing",
        priority: "high",
        tags: %w[ruby dev],
        due_date: "2026-12-31"
      )
      expect(task.title).to eq("Full task")
      expect(task.status).to eq("doing")
      expect(task.priority).to eq("high")
      expect(task.tags).to eq(%w[ruby dev])
      expect(task.due_date).to eq("2026-12-31")
    end

    it "raises error for missing title" do
      expect { described_class.new(title: "") }.to raise_error(ArgumentError, /Title is required/)
    end

    it "raises error for nil title" do
      expect { described_class.new }.to raise_error(ArgumentError, /Title is required/)
    end

    it "raises error for invalid status" do
      expect { described_class.new(title: "Test", status: "invalid") }.to raise_error(ArgumentError, /Invalid status/)
    end

    it "raises error for invalid priority" do
      expect { described_class.new(title: "Test", priority: "urgent") }.to raise_error(ArgumentError, /Invalid priority/)
    end
  end

  describe "#priority_icon" do
    it "returns correct icons" do
      expect(described_class.new(title: "t", priority: "critical").priority_icon).to eq("!!!")
      expect(described_class.new(title: "t", priority: "high").priority_icon).to eq("!! ")
      expect(described_class.new(title: "t", priority: "medium").priority_icon).to eq("!  ")
      expect(described_class.new(title: "t", priority: "low").priority_icon).to eq(".  ")
    end
  end

  describe "#formatted_time" do
    it "returns 0m when no time logged" do
      task = described_class.new(title: "t")
      expect(task.formatted_time).to eq("0m")
    end

    it "formats minutes only" do
      task = described_class.new(title: "t", time_logged: 45)
      expect(task.formatted_time).to eq("45m")
    end

    it "formats hours and minutes" do
      task = described_class.new(title: "t", time_logged: 90)
      expect(task.formatted_time).to eq("1h 30m")
    end

    it "formats hours only" do
      task = described_class.new(title: "t", time_logged: 120)
      expect(task.formatted_time).to eq("2h")
    end
  end

  describe "#to_h" do
    it "returns a hash of task attributes" do
      task = described_class.new(title: "Test", priority: "high")
      h = task.to_h
      expect(h[:title]).to eq("Test")
      expect(h[:priority]).to eq("high")
      expect(h).to have_key(:id)
      expect(h).to have_key(:created_at)
    end
  end

  describe ".from_hash" do
    it "creates a task from a hash" do
      task = described_class.from_hash(title: "From hash", status: "done", priority: "low")
      expect(task.title).to eq("From hash")
      expect(task.status).to eq("done")
    end
  end
end
