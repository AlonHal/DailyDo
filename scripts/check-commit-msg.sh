#!/usr/bin/env bash
# Enforces DEVELOPMENT_ENVIRONMENT_STANDARDS.md §3's Conventional Commits
# format. Wired in as a pre-commit commit-msg hook (see
# templates/pre-commit-config.yaml); pre-commit passes the commit
# message file path as $1.
set -euo pipefail

msg_file="$1"
first_line="$(head -1 "$msg_file")"

pattern='^(feat|fix|chore|docs|test|refactor|ci)(\([a-z0-9-]+\))?: .+'
if [[ ! "$first_line" =~ $pattern ]]; then
  echo "Commit message doesn't follow Conventional Commits: '<type>(optional-scope): subject'" >&2
  echo "Types: feat fix chore docs test refactor ci" >&2
  echo "Got: $first_line" >&2
  echo "See dev-standards/DEVELOPMENT_ENVIRONMENT_STANDARDS.md §3" >&2
  exit 1
fi
