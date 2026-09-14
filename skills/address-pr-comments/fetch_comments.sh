#!/usr/bin/env bash
# Fetch all unresolved PR review comment threads for the current branch (or a given PR number).
# Output is structured for LLM consumption.
set -euo pipefail

PR_NUMBER="${1:-}"

if [ -z "$PR_NUMBER" ]; then
  CURRENT_BRANCH=$(git branch --show-current)
  echo "Fetching PR number for current branch: $CURRENT_BRANCH"
  PR_DATA=$(gh pr view --json number,url --jq '.number, .url' 2>/dev/null | xargs) || {
    echo "ERROR: No open PR found for the current branch. Pass a PR number as an argument." >&2
    exit 1
  }
  read -r PR_NUMBER PR_URL <<< "$PR_DATA"
else
  PR_URL=$(gh pr view "$PR_NUMBER" --json url --jq '.url')
fi

echo "Fetching comments for PR: $PR_URL"

# Fetch all review threads via GraphQL (handles pagination up to 100 threads / 100 replies)
QUERY='
query($owner: String!, $repo: String!, $pr: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $pr) {
      reviewThreads(first: 100) {
        nodes {
          id
          isResolved
          isOutdated
          line
          startLine
          path
          diffSide
          comments(first: 100) {
            nodes {
              id
              databaseId
              body
              author { login }
              createdAt
              line
              path
            }
          }
        }
      }
    }
  }
}'

read -r OWNER REPO <<< "$(gh repo view --json owner,name --jq '.owner.login, .name' | xargs)"

THREADS_JSON=$(gh api graphql \
  -f query="$QUERY" \
  -F owner="$OWNER" \
  -F repo="$REPO" \
  -F pr="$PR_NUMBER" \
  --jq '.data.repository.pullRequest.reviewThreads.nodes')

# Filter to unresolved threads only and format for the LLM
echo "$THREADS_JSON" | jq -r --arg pr_url "$PR_URL" '
  [ .[] | select(.isResolved == false) ] |
  if length == 0 then
    "No unresolved review comments"
  else
    "Unresolved comment threads: \(length)\n" +
    ( to_entries | map(
      "\n---\n## Thread \(.key + 1) | \(.value.path // "general"):\(.value.line // "N/A")" +
      (if .value.isOutdated then " [OUTDATED - code has changed since this comment]" else "" end) +
      "\n" +
      ( .value.comments.nodes | map(
        "**\(.author.login)** (\(.createdAt)):\n\(.body)\n"
      ) | join("\n") ) +
      "\nthread_id: \(.value.id)" +
      "\nreply_to_comment_id: \(.value.comments.nodes[-1].databaseId)"
    ) | join("\n") )
  end
'

# Top-level (issue) comments on the PR. These are NOT review threads — they have no
# file/line and can't be "resolved", so we surface all of them (minus obvious bots)
# for the LLM to triage. A comment is treated as a bot comment if EITHER:
#   1. its author login matches the denylist below (the `[bot]` GitHub App suffix
#      plus known CI/integration accounts that post automated status comments), OR
#   2. its body contains a known automated-comment marker (HTML comment sentinels
#      that these integrations embed). This catches bots whose login doesn't match
#      our denylist (e.g. accounts without a `[bot]` suffix that get renamed).
BOT_LOGIN_REGEX='\[bot\]$|^(diff-report|datadog(-[a-z0-9-]+)?|argos-ci|linear|linear-code|linear-app|blacksmith|blacksmith-sh|github-actions|dependabot|codecov|sonarcloud(-bot)?|vercel|netlify|coderabbitai|bugbot|cursor(\[bot\])?|sentry-io|graphite-app|socket-security|snyk-bot)$'

# Matched case-insensitively against the comment body (anchored to HTML-comment
# sentinels so we don't accidentally drop human comments that mention these words).
BOT_BODY_REGEX='<!--[[:space:]]*(linear-linkback|blacksmith|sticky pull request comment|bugbot|datadog|argos|codecov|coverage report)'

ISSUE_COMMENTS_JSON=$(gh pr view "$PR_NUMBER" --json comments --jq '.comments')

echo "$ISSUE_COMMENTS_JSON" | jq -r --arg botre "$BOT_LOGIN_REGEX" --arg bodyre "$BOT_BODY_REGEX" '
  [ .[] | select(
      ((.author.login // "") | test($botre) | not) and
      ((.body // "") | test($bodyre; "i") | not)
  ) ] |
  if length == 0 then
    "\n\n=== Top-level PR comments: none (excluding bots) ==="
  else
    "\n\n=== Top-level PR comments: \(length) (excluding bots) ===\n" +
    ( to_entries | map(
      "\n---\n## Top-level comment \(.key + 1) | **\(.value.author.login)** (\(.value.createdAt)):\n" +
      .value.body + "\n" +
      "\ncomment_url: \(.value.url)"
    ) | join("\n") )
  end
'
