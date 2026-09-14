#!/usr/bin/env ruby
# Config CLI for the guided-dev / ai-dev session modes.
#
# Source of truth is <worktree>/.notes/guided-dev.json, which is git-ignored by
# the repo's `.notes/*` rule. Worktree-local rather than global so two worktrees
# can run different modes at once.
#
# Run this directly (./guided-dev.rb status), NOT via `rails runner` — it is a
# skill utility outside the project and must not pay the Rails boot cost.

require "json"
require "fileutils"
require "time"

MODES = %w[guided ai off].freeze
PHASES = %w[align scaffold implement review done].freeze
FINDING_STATES = %w[open fixed accepted dismissed].freeze
CONFIG_RELATIVE = File.join(".notes", "guided-dev.json")

def die(message)
  warn("guided-dev: #{message}")
  exit(1)
end

def worktree_root
  root = `git rev-parse --show-toplevel 2>/dev/null`.strip
  die("not inside a git repository") if root.empty?
  root
end

def config_path(root)
  File.join(root, CONFIG_RELATIVE)
end

def current_branch
  branch = `git rev-parse --abbrev-ref HEAD 2>/dev/null`.strip
  branch.empty? ? nil : branch
end

# alex/abc-1840 -> ABC-1840; alexdoe/xyz-442-launch -> XYZ-442
def ticket_from_branch(branch)
  return nil if branch.nil?

  match = branch.match(/([a-zA-Z]{2,10})-(\d+)/)
  return nil if match.nil?

  "#{match[1].upcase}-#{match[2]}"
end

def read_config(root)
  path = config_path(root)
  return nil unless File.exist?(path)

  JSON.parse(File.read(path, encoding: "UTF-8"))
rescue StandardError
  nil
end

def write_config(root, config)
  path = config_path(root)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, "#{JSON.pretty_generate(config)}\n")
  path
end

def now
  Time.now.utc.iso8601
end

def command_init(root, args)
  mode = args.shift || "guided"
  die("unknown mode #{mode}. one of #{MODES.join(", ")}") unless MODES.include?(mode)

  branch = current_branch
  existing = read_config(root)
  if existing && existing["mode"] != "off"
    die(
      "already in #{existing["mode"]} mode (phase #{existing["phase"]}) on " \
        "#{existing["branch"]}. run `end` first to reset.",
    )
  end

  config = {
    "mode" => mode,
    "phase" => "align",
    "branch" => branch,
    "worktree_path" => root,
    "ticket" => ticket_from_branch(branch),
    "ticket_note" => args.shift,
    "started_at" => now,
    "phase_history" => [{ "phase" => "align", "at" => now }],
    "artifacts" => { "scaffold" => [], "seeders" => [], "harnesses" => [] },
  }

  puts "guided-dev: #{mode} mode on #{branch} (phase align)"
  puts "guided-dev: config #{write_config(root, config)}"
end

def command_phase(root, args)
  phase = args.shift
  die("phase required. one of #{PHASES.join(", ")}") if phase.nil?
  die("unknown phase #{phase}. one of #{PHASES.join(", ")}") unless PHASES.include?(phase)

  config = read_config(root)
  die("no config. run `init` first.") if config.nil?

  previous = config["phase"]
  config["phase"] = phase
  config["phase_history"] = Array(config["phase_history"]) + [{ "phase" => phase, "at" => now }]
  write_config(root, config)

  puts "guided-dev: phase #{previous} -> #{phase}"
end

# Artifacts are recorded so the review skill knows which files Claude scaffolded
# versus which the user wrote. Without that split a review cannot tell whose
# code it is critiquing.
def command_track(root, args)
  kind = args.shift
  die("kind required. one of scaffold, seeders, harnesses") unless %w[scaffold seeders harnesses].include?(kind)
  die("at least one path required") if args.empty?

  config = read_config(root)
  die("no config. run `init` first.") if config.nil?

  config["artifacts"] ||= {}
  recorded = Array(config["artifacts"][kind])
  relative = args.map { |path| path.delete_prefix("#{root}/") }
  config["artifacts"][kind] = (recorded + relative).uniq
  write_config(root, config)

  puts "guided-dev: tracked #{relative.length} #{kind} path(s)"
end

# The scaffold checkpoint commit. Recording it makes the review diff exactly the
# user's own work, which is the only diff worth giving teaching feedback on.
def command_ref(root, args)
  sha = args.shift || `git rev-parse HEAD 2>/dev/null`.strip
  die("could not resolve a scaffold ref") if sha.empty?

  config = read_config(root)
  die("no config. run `init` first.") if config.nil?

  config["scaffold_ref"] = sha
  write_config(root, config)

  puts "guided-dev: scaffold ref #{sha[0, 12]}"
end

def git_head
  sha = `git rev-parse HEAD 2>/dev/null`.strip
  sha.empty? ? nil : sha
end

def git_dirty?
  !`git status --porcelain 2>/dev/null`.strip.empty?
end

def open_findings(config)
  Array(config["findings"]).reject do |finding|
    %w[fixed dismissed].include?(finding["state"])
  end
end

# Opens a review round. Each round records the ref it starts from so the next one
# can diff incrementally — re-reading unchanged code is what produces repeated
# comments, so the range is the primary repetition control.
def command_review_start(root, _args)
  config = read_config(root)
  die("no config. run `init` first.") if config.nil?

  round = (config["review_round"] || 0) + 1
  previous = Array(config["reviews"]).last
  base_ref = (previous && previous["head_ref"]) || config["scaffold_ref"]
  head = git_head
  at = now

  entry = {
    "round" => round,
    "at" => at,
    "base_ref" => base_ref,
    "head_ref" => head,
    "dirty" => git_dirty?,
  }

  config["review_round"] = round
  config["reviews"] = Array(config["reviews"]) + [entry]

  # The phase follows the round so the guard hook's messaging matches. Rounds
  # after the first re-enter review from implement, which the append-only
  # phase_history records as the loop it is.
  unless config["phase"] == "review"
    config["phase"] = "review"
    config["phase_history"] = Array(config["phase_history"]) + [{ "phase" => "review", "at" => at }]
  end

  write_config(root, config)

  puts JSON.pretty_generate(
         {
           "round" => round,
           "base_ref" => base_ref,
           "head_ref" => head,
           "dirty" => entry["dirty"],
           "incremental_range" => base_ref ? "#{base_ref}..#{head || "HEAD"}" : nil,
           "carried_findings" => open_findings(config),
         },
       )
end

def command_findings(root, args)
  subcommand = args.shift || "list"
  case subcommand
  when "sync" then findings_sync(root)
  when "list" then findings_list(root, args)
  when "state" then findings_state(root, args)
  else die("unknown findings subcommand #{subcommand}. one of sync, list, state")
  end
end

def findings_sync(root)
  config = read_config(root)
  die("no config. run `init` first.") if config.nil?

  payload = JSON.parse($stdin.read)
  incoming = Array(payload["findings"])
  die("no findings in payload") if incoming.empty?

  round = config["review_round"] || 0
  index = {}
  Array(config["findings"]).each { |finding| index[finding["id"]] = finding }

  added = 0
  carried = 0

  incoming.each do |item|
    id = item["id"].to_s
    die("every finding needs a stable id") if id.empty?

    state = item["state"] || "open"
    die("unknown state #{state}. one of #{FINDING_STATES.join(", ")}") unless FINDING_STATES.include?(state)

    current = index[id]
    if current.nil?
      index[id] = {
        "id" => id,
        "severity" => item["severity"],
        "path" => item["path"],
        "anchor" => item["anchor"],
        "summary" => item["summary"],
        "state" => state,
        "raised_round" => round,
        "last_seen_round" => round,
        "restated" => 0,
      }
      added += 1
    else
      # Counts only rounds where it was still open. That count is what drives the
      # escalation ladder, so a fixed finding must not inflate it.
      if state == "open" && current["last_seen_round"] != round
        current["restated"] = current["restated"].to_i + 1
      end
      current["state"] = state
      current["last_seen_round"] = round
      current["summary"] = item["summary"] if item["summary"]
      carried += 1
    end
  end

  config["findings"] = index.values
  write_config(root, config)
  puts "guided-dev: round #{round} — #{added} new, #{carried} carried"
end

def findings_list(root, args)
  config = read_config(root)
  die("no config. run `init` first.") if config.nil?

  findings = args.include?("--open") ? open_findings(config) : Array(config["findings"])

  if args.include?("--json")
    puts JSON.pretty_generate(findings)
    return
  end

  if findings.empty?
    puts "guided-dev: no findings"
    return
  end

  findings.each do |finding|
    restated = finding["restated"].to_i
    tail = restated.positive? ? " [restated #{restated}x]" : ""
    anchor = finding["anchor"] ? " #{finding["anchor"]}" : ""
    puts "#{finding["state"].to_s.ljust(10)}#{finding["severity"].to_s.ljust(8)}#{finding["id"]}#{tail}"
    puts "  #{finding["path"]}#{anchor}"
    puts "  #{finding["summary"]}"
  end
end

def findings_state(root, args)
  id = args.shift
  state = args.shift
  die("usage: findings state <id> <#{FINDING_STATES.join("|")}>") if id.nil? || state.nil?
  die("unknown state #{state}") unless FINDING_STATES.include?(state)

  config = read_config(root)
  die("no config. run `init` first.") if config.nil?

  finding = Array(config["findings"]).find { |candidate| candidate["id"] == id }
  die("no finding with id #{id}") if finding.nil?

  finding["state"] = state
  write_config(root, config)
  puts "guided-dev: #{id} -> #{state}"
end

def parse_time(value)
  value && Time.iso8601(value)
rescue StandardError
  nil
end

def format_duration(seconds)
  total = seconds.round
  hours = total / 3600
  minutes = (total % 3600) / 60
  return "#{hours}h #{minutes.to_s.rjust(2, "0")}m" if hours.positive?

  "#{minutes}m"
end

# Each entry's duration is the gap to the next transition, so the phase you are
# in reads as "current" rather than showing a span that has not closed yet.
def print_timeline(config)
  history = Array(config["phase_history"])
  return if history.empty?

  puts "timeline:"
  history.each_with_index do |entry, index|
    successor = history[index + 1]
    started = parse_time(entry["at"])
    finished = parse_time(successor ? successor["at"] : config["ended_at"])

    span =
      if successor.nil? && entry["phase"] == "done"
        "" # terminal marker, not a phase with a span
      elsif started && finished
        " (#{format_duration(finished - started)})"
      elsif successor.nil?
        " (current)"
      else
        ""
      end

    puts "  #{entry["phase"].to_s.ljust(10)}#{entry["at"]}#{span}"
  end
end

def command_status(root, _args)
  config = read_config(root)
  if config.nil?
    puts "guided-dev: inactive (no config at #{CONFIG_RELATIVE})"
    exit(3)
  end

  branch = current_branch
  puts "mode:     #{config["mode"]}"
  puts "phase:    #{config["phase"]}"
  puts "branch:   #{config["branch"]}"
  puts "ticket:   #{config["ticket"] || "(none)"}"
  puts "note:     #{config["ticket_note"] || "(none)"}"
  puts "pr:       #{config["pr_url"] || "(none)"}"
  puts "started:  #{config["started_at"]}"
  puts "ref:      #{config["scaffold_ref"] ? config["scaffold_ref"][0, 12] : "(scaffold not committed)"}"
  print_timeline(config)

  rounds = Array(config["reviews"])
  unless rounds.empty?
    puts "reviews:"
    rounds.each do |entry|
      dirty = entry["dirty"] ? " +dirty" : ""
      puts "  round #{entry["round"]}   #{entry["at"]}   #{entry["base_ref"] ? entry["base_ref"][0, 12] : "(no base)"}..#{entry["head_ref"] ? entry["head_ref"][0, 12] : "?"}#{dirty}"
    end
  end

  findings = Array(config["findings"])
  unless findings.empty?
    counts = findings.group_by { |finding| finding["state"] }.map { |state, group| "#{group.length} #{state}" }
    puts "findings: #{counts.join(", ")}"
  end
  Array(config["artifacts"]&.keys).each do |kind|
    paths = Array(config["artifacts"][kind])
    next if paths.empty?

    puts "#{kind}:\n#{paths.map { |path| "  - #{path}" }.join("\n")}"
  end

  if branch && config["branch"] && branch != config["branch"]
    puts "\nSTALE: config was written on #{config["branch"]} but HEAD is #{branch}."
    exit(4)
  end
end

def command_end(root, args)
  config = read_config(root)

  # Idempotent. Opening a second PR on the same branch must not append another
  # terminal entry to the timeline.
  if config.nil? || config["mode"] == "off"
    puts "guided-dev: already inactive"
    return
  end

  previous = "#{config["mode"]}/#{config["phase"]}"
  rounds = Array(config["reviews"]).length
  still_open = open_findings(config).length
  ended_at = now
  pr_url = args.shift

  config["mode"] = "off"
  config["phase"] = "done"
  config["ended_at"] = ended_at
  config["pr_url"] = pr_url if pr_url
  config["phase_history"] = Array(config["phase_history"]) + [{ "phase" => "done", "at" => ended_at }]
  write_config(root, config)

  puts "guided-dev: ended (was #{previous})"
  puts "guided-dev: pr #{pr_url}" if pr_url
  if rounds.zero?
    puts "guided-dev: NOTE no review rounds ran on this one."
  else
    puts "guided-dev: #{rounds} review round(s), #{still_open} finding(s) still open"
  end
end

COMMANDS = {
  "init" => method(:command_init),
  "phase" => method(:command_phase),
  "track" => method(:command_track),
  "ref" => method(:command_ref),
  "review-start" => method(:command_review_start),
  "findings" => method(:command_findings),
  "status" => method(:command_status),
  "end" => method(:command_end),
}.freeze

args = ARGV.dup
command = args.shift || "status"
handler = COMMANDS[command]
die("unknown command #{command}. one of #{COMMANDS.keys.join(", ")}") if handler.nil?

handler.call(worktree_root, args)
