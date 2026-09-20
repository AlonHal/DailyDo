#!/usr/bin/env bash
# Enforces DEVELOPMENT_ENVIRONMENT_STANDARDS.md §3's branch naming convention.
# Wired in as a pre-commit local hook (see templates/pre-commit-config.yaml).
set -euo pipefail

branch="$(git rev-parse --abbrev-ref HEAD)"

# main is handled by the no-commit-to-branch hook — don't double-fail here.
if [[ "$branch" == "main" ]]; then
  exit 0
fi

if [[ ! "$branch" =~ ^(feat|fix|chore|docs|test|refactor|ci)/[a-z0-9][a-z0-9-]*$ ]]; then
  echo "Branch name '$branch' doesn't match <type>/<slug>." >&2
  echo "Types: feat fix chore docs test refactor ci — e.g. feat/daily-session-ui" >&2
  echo "See dev-standards/DEVELOPMENT_ENVIRONMENT_STANDARDS.md §3" >&2
  exit 1
fi
