# Copy to a component repo root, then adjust the language-specific
# commands in `check`/`test`/`build` for this component (Flutter shown
# below; swap for backend equivalents once that language is decided).
# See dev-standards/DEVELOPMENT_ENVIRONMENT_STANDARDS.md §4, §10 Phase 1
#
# `check`/`test`/`build` are the single source of truth: pre-commit
# hooks and CI both call these targets, so there's no drift between
# what runs locally and what runs in CI (§4).
#
# Flutter/Dart checks below no-op with a clear message until the SDK is
# actually installed (DEVELOPMENT_PLAN.md Phase 0) — so this Makefile
# works today and needs no edits once Flutter is installed later.

GITLEAKS := $(shell command -v gitleaks 2>/dev/null || echo $(HOME)/.venvs/dev-tools/bin/gitleaks)

.PHONY: check test build all

check:
	@echo "== gitleaks secret scan =="
	@$(GITLEAKS) protect --staged --redact --verbose
	@if command -v dart >/dev/null 2>&1; then \
		echo "== dart format =="; \
		dart format --output=none --set-exit-if-changed . ; \
		echo "== flutter analyze =="; \
		flutter analyze ; \
	else \
		echo "== dart format / flutter analyze: SKIPPED (Flutter SDK not installed yet) ==" ; \
	fi

test:
	@if command -v flutter >/dev/null 2>&1; then \
		flutter test ; \
	else \
		echo "flutter test: SKIPPED (Flutter SDK not installed yet)" ; \
	fi

build:
	@if command -v flutter >/dev/null 2>&1; then \
		flutter build apk --debug ; \
	else \
		echo "flutter build: SKIPPED (Flutter SDK not installed yet)" ; \
	fi

all: check test build

# --- Backend repos (Node): swap `check`/`test`/`build` above for, e.g. ---
# check: ; @$(GITLEAKS) protect --staged --redact --verbose && npx eslint .
# test:  ; @npm test
# build: ; @npm run build

# --- Backend repos (Python): swap for, e.g. ---
# check: ; @$(GITLEAKS) protect --staged --redact --verbose && ruff check . && black --check .
# test:  ; @pytest
# build: ; @true  # no build step, or a packaging command
