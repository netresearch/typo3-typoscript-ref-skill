#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
#
# Behavioural tests for skills/typo3-typoscript-ref/scripts/detect-version.sh:
# which composer file wins, how constraints map to a major version, how far up
# the tree the search goes, and how bad arguments are rejected.
#
# Run from anywhere: bash tests/detect-version.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="${ROOT}/skills/typo3-typoscript-ref/scripts/detect-version.sh"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

PASS=0
FAIL=0

ok() {
    PASS=$((PASS + 1))
    echo "ok   $1"
}

not_ok() {
    FAIL=$((FAIL + 1))
    echo "FAIL $1"
    shift
    printf '     %s\n' "$@"
}

# expect_version <name> <expected output> <args...>
expect_version() {
    local name="$1" expected="$2"
    shift 2
    local out rc=0
    out="$(bash "$SCRIPT" "$@" 2>"$TMP/stderr")" || rc=$?
    if [[ "$rc" -eq 0 && "$out" == "$expected" ]]; then
        ok "$name"
    else
        not_ok "$name" "expected: exit 0, '${expected}'" "found:    exit ${rc}, '${out}'" "stderr:   $(cat "$TMP/stderr")"
    fi
}

# expect_error <name> <stderr substring> <args...>
expect_error() {
    local name="$1" message="$2"
    shift 2
    local rc=0
    bash "$SCRIPT" "$@" >"$TMP/stdout" 2>"$TMP/stderr" || rc=$?
    if [[ "$rc" -ne 0 ]] && grep -qF -- "$message" "$TMP/stderr"; then
        ok "$name"
    else
        not_ok "$name" "expected: non-zero exit, stderr containing '${message}'" \
            "found:    exit ${rc}, stderr '$(cat "$TMP/stderr")'"
    fi
}

# project <dir> — create an empty project directory
project() {
    mkdir -p "$TMP/$1"
    echo "$TMP/$1"
}

lock_with() {
    printf '{"packages": [{"name": "typo3/cms-core", "version": "%s"}], "packages-dev": []}\n' "$2" >"$1/composer.lock"
}

json_with() {
    printf '{"require": {"php": "^8.2", "typo3/cms-core": "%s"}}\n' "$2" >"$1/composer.json"
}

# --- composer.lock ---------------------------------------------------------

p="$(project lock-tag)"
lock_with "$p" "v13.4.2"
expect_version "lock: tag with v prefix" "13" --path "$p"

p="$(project lock-plain)"
lock_with "$p" "12.4.42"
expect_version "lock: plain version" "12" --path "$p"

p="$(project lock-dev)"
printf '{"packages": [], "packages-dev": [{"name": "typo3/cms-core", "version": "v14.3.1"}]}\n' >"$p/composer.lock"
expect_version "lock: typo3/cms-core in packages-dev" "14" --path "$p"

p="$(project lock-wins)"
lock_with "$p" "v13.4.2"
json_with "$p" "^12.4"
expect_version "lock takes precedence over composer.json" "13" --path "$p"

p="$(project lock-without-core)"
printf '{"packages": [{"name": "psr/log", "version": "3.0.0"}]}\n' >"$p/composer.lock"
json_with "$p" "^14.3"
expect_version "lock without typo3/cms-core falls back to composer.json" "14" --path "$p"

p="$(project lock-broken)"
echo '{ not json' >"$p/composer.lock"
json_with "$p" "^13.4"
expect_version "unparsable lock falls back to composer.json" "13" --path "$p"

# --- composer.json constraints ----------------------------------------------

p="$(project caret)"
json_with "$p" "^13.4"
expect_version "json: caret constraint" "13" --path "$p"

p="$(project tilde)"
json_with "$p" "~12.4"
expect_version "json: tilde constraint" "12" --path "$p"

p="$(project range)"
json_with "$p" ">=12.4,<13"
expect_version "json: range takes the lower bound" "12" --path "$p"

p="$(project require-dev)"
printf '{"require-dev": {"typo3/cms-core": "^14.3"}}\n' >"$p/composer.json"
expect_version "json: typo3/cms-core in require-dev" "14" --path "$p"

p="$(project dev-main)"
json_with "$p" "dev-main"
expect_version "json: dev-main maps to main" "main" --path "$p"

p="$(project dev-master)"
json_with "$p" "dev-master as 13.4.x-dev"
expect_version "json: dev-master maps to main" "main" --path "$p"

p="$(project no-digits)"
json_with "$p" "*"
expect_version "json: constraint without a digit maps to main" "main" --path "$p"

p="$(project no-core)"
printf '{"require": {"php": "^8.2"}}\n' >"$p/composer.json"
expect_version "json without typo3/cms-core maps to main" "main" --path "$p"

p="$(project json-broken)"
echo 'not json' >"$p/composer.json"
expect_version "unparsable composer.json maps to main" "main" --path "$p"

# --- directory walk ------------------------------------------------------------

# The search checks the start directory and at most five parents.
p="$(project walk5)"
json_with "$p" "^13.4"
mkdir -p "$p/a/b/c/d/e"
expect_version "composer.json five levels up is found" "13" --path "$p/a/b/c/d/e"

p="$(project walk6)"
json_with "$p" "^13.4"
mkdir -p "$p/a/b/c/d/e/f"
expect_version "composer.json six levels up is not found" "main" --path "$p/a/b/c/d/e/f"

p="$(project cwd)"
json_with "$p" "^12.4"
out="$(cd "$p" && bash "$SCRIPT")"
if [[ "$out" == "12" ]]; then ok "without --path the working directory is searched"; else not_ok "without --path the working directory is searched" "found: '${out}'"; fi

# --- arguments -------------------------------------------------------------------

expect_error "--path without a value" "--path requires a value" --path
expect_error "--path followed by another option" "--path requires a value" --path --other
expect_error "positional argument is rejected" "Unknown option: ${TMP}" "$TMP"
expect_error "unknown option is rejected" "Unknown option: --verbose" --verbose

echo
echo "detect-version.sh: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
