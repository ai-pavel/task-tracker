# Task Tracker

[![CI](https://github.com/pavel-genai/task-tracker/actions/workflows/ci.yml/badge.svg)](https://github.com/pavel-genai/task-tracker/actions/workflows/ci.yml)
[![codecov](https://codecov.io/gh/pavel-genai/task-tracker/branch/main/graph/badge.svg)](https://codecov.io/gh/pavel-genai/task-tracker)

A Ruby CLI task tracker with Kanban board support. Manage tasks with statuses, priorities, tags, due dates, and time tracking. Data is persisted in SQLite.

## Installation

```bash
bundle install
chmod +x bin/tt
```

## Usage

```bash
# Add tasks
bin/tt add "Implement login" --priority high --tags backend,auth --due 2026-08-01
bin/tt add "Write tests" --priority medium --tags testing

# List tasks
bin/tt list
bin/tt list --status todo
bin/tt list --priority high
bin/tt list --tag backend

# Move tasks between columns
bin/tt move 1 doing
bin/tt move 1 done

# Edit a task
bin/tt edit 1 --title "New title" --priority critical

# Delete a task
bin/tt delete 2

# View Kanban board
bin/tt board

# Log time
bin/tt log 1 30 "Worked on implementation"
bin/tt log 1 45 "Code review"

# Show task details
bin/tt show 1

# View report
bin/tt report

# Help
bin/tt help
```

## Task Properties

- **Status**: todo, doing, done
- **Priority**: low, medium, high, critical
- **Tags**: comma-separated labels
- **Due Date**: YYYY-MM-DD format
- **Time Logged**: tracked in minutes

## Development

```bash
bundle exec rspec
```

## Project Structure

```
lib/task_tracker/
  cli.rb       - Command-line interface
  database.rb  - SQLite persistence layer
  task.rb      - Task model with validation
  board.rb     - ASCII Kanban board renderer
  report.rb    - Summary statistics
bin/tt         - CLI entry point
spec/          - RSpec tests
```
