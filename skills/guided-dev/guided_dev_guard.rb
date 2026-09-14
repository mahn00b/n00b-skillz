#!/usr/bin/env ruby
# PreToolUse hook for Edit|Write. Keeps the guided-dev boundary in context on
# every single edit, because a boundary stated once at the top of a long session
# is a boundary the agent drifts across by turn forty.
#
# Advisory only. It never emits permissionDecision, so it cannot approve or deny
# an edit — it only reminds. Fails open: any error exits 0 with no output.

require "json"

CONFIG_RELATIVE = File.join(".notes", "guided-dev.json")
MAX_ASCENT = 8

def read_json(path)
  JSON.parse(File.read(path, encoding: "UTF-8"))
end

# Walks up from cwd rather than trusting CLAUDE_PROJECT_DIR, which is unset for
# user-scoped hooks.
def find_config(start_dir)
  dir = File.expand_path(start_dir)
  MAX_ASCENT.times do
    candidate = File.join(dir, CONFIG_RELATIVE)
    return [candidate, File.dirname(File.dirname(candidate))] if File.exist?(candidate)

    parent = File.dirname(dir)
    break if parent == dir

    dir = parent
  end
  nil
end

def support_path?(relative_path)
  relative_path.start_with?(".notes/") ||
    File.basename(relative_path).start_with?("tmp_")
end

def test_path?(relative_path)
  relative_path.start_with?("test/") ||
    relative_path.match?(/_test\.rb\z/) ||
    relative_path.match?(/\.(test|spec)\.[jt]sx?\z/)
end

def guidance_for(phase, relative_path)
  return nil unless %w[align scaffold implement review].include?(phase)

  # Prose is not implementation. Notes, docs and specs get written throughout, so
  # nagging about them is pure noise.
  return nil if relative_path.end_with?(".md")

  # Seeders and harnesses are Claude's to write end to end in every phase. They
  # are scaffolding for the user's reps, not the reps themselves.
  if support_path?(relative_path)
    return "This is guided-dev support code (seeder / harness / scratch). Write it " \
             "fully and make it work. The scaffold-only rule does not apply here."
  end

  case phase
  when "align"
    "Phase is ALIGN. The solution is not agreed yet, so no production code should " \
      "be written at all. Go back to the user, settle the approach and the test " \
      "coverage, then run `guided-dev.rb phase scaffold`."
  when "scaffold"
    if test_path?(relative_path)
      "Phase is SCAFFOLD, and this is a test file. Write describe/it structure, " \
        "descriptions, `let` blocks and fixture setup ONLY. Every example body is " \
        "`flunk \"TODO\"` (Ruby) or `expect(true).toBe(false) // TODO` (Jest). Do " \
        "NOT write assertions — those are the user's reps."
    else
      "Phase is SCAFFOLD. Signatures, class/module structure, type annotations, " \
        "imports and wiring ONLY. Method and function bodies are " \
        "`raise NotImplementedError` (Ruby) or `throw new Error(\"TODO\")` (TS). Do " \
        "NOT implement logic. See references/scaffold-rules.md."
    end
  when "implement"
    "Phase is IMPLEMENT. The USER is writing this code, not you. Do not add, " \
      "complete or 'fix' logic here. Answer questions, point at examples, explain " \
      "the failure — but leave the typing to them. If they explicitly asked you to " \
      "take this file over, say so out loud first and record it."
  when "review"
    "Phase is REVIEW. Leave findings as review comments, not " \
      "as edits. Only edit when the user picks a finding and asks for the fix."
  end
end

begin
  $stdin.set_encoding("UTF-8")
  payload = JSON.parse($stdin.read)

  file_path = payload.dig("tool_input", "file_path").to_s
  exit(0) if file_path.empty?

  found = find_config(payload["cwd"] || Dir.pwd)
  exit(0) if found.nil?

  config_path, root = found
  config = read_json(config_path)

  # Only guided mode nags. `ai` and `off` deliberately fall through to normal
  # behavior so the future ai-dev skill needs no change here.
  exit(0) unless config["mode"] == "guided"

  phase = config["phase"].to_s
  relative_path = file_path.delete_prefix("#{root}/")

  # Still absolute means the file lives outside the worktree — a scratchpad, a
  # notes vault, another repo. None of that is the work under guidance.
  exit(0) if relative_path.start_with?("/")

  guidance = guidance_for(phase, relative_path)
  exit(0) if guidance.nil?

  ticket = config["ticket"]
  header = ["guided-dev is ACTIVE", ticket && "on #{ticket}"].compact.join(" ")

  context = <<~CONTEXT
    #{header}. Editing #{relative_path}.

    #{guidance}
  CONTEXT

  # No permissionDecision. Emitting "allow" here would auto-approve every edit in
  # the session and bypass the user's permission settings entirely.
  puts JSON.generate(
         {
           hookSpecificOutput: {
             hookEventName: "PreToolUse",
             additionalContext: context,
           },
         },
       )
rescue StandardError
  exit(0)
end
