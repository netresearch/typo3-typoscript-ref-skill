#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
#
# Behavioural tests for skills/typo3-typoscript-ref/scripts/lookup.sh, every
# mode against the references shipped in this repository and a fixture cache.
#
# lookup.sh derives its cache directory from its own location
# (<repo>/cache), so the tests copy the skill into a temporary tree and run
# that copy; nothing is written into the working tree. --update is run with a
# stub `gh` that always fails, so no network request is made.
#
# Run from anywhere: bash tests/lookup.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/repo"
mkdir -p "$REPO/skills"
cp -R "$ROOT/skills/typo3-typoscript-ref" "$REPO/skills/"
LOOKUP="$REPO/skills/typo3-typoscript-ref/scripts/lookup.sh"
CACHE="$REPO/cache"

# A project directory with no composer file and no lint config above it
# inside $TMP; commands run from here unless a case says otherwise.
WORK="$TMP/work"
mkdir -p "$WORK"

PASS=0
FAIL=0
RC=0

ok() {
    PASS=$((PASS + 1))
    echo "ok   $1"
}

not_ok() {
    FAIL=$((FAIL + 1))
    echo "FAIL $1"
    shift
    printf '     %s\n' "$@"
    printf '     stdout: %s\n' "$(head -c 400 "$TMP/stdout")"
    printf '     stderr: %s\n' "$(head -c 400 "$TMP/stderr")"
}

# run <args...> — run lookup.sh from $WORK, capture stdout/stderr and exit code
run() {
    RC=0
    (cd "$WORK" && bash "$LOOKUP" "$@") >"$TMP/stdout" 2>"$TMP/stderr" || RC=$?
}

# expect <name> <exit code> <stream> <substring> [<stream> <substring> ...]
# A substring prefixed with "!" must NOT appear in the stream.
expect() {
    local name="$1" code="$2"
    shift 2
    if [[ "$RC" -ne "$code" ]]; then
        not_ok "$name" "expected exit ${code}, found ${RC}"
        return
    fi
    while [[ $# -gt 0 ]]; do
        local stream="$TMP/$1" needle="$2"
        shift 2
        if [[ "$needle" == '!'* ]]; then
            if grep -qF -- "${needle#!}" "$stream"; then
                not_ok "$name" "$(basename "$stream") must not contain '${needle#!}'"
                return
            fi
        elif ! grep -qF -- "$needle" "$stream"; then
            not_ok "$name" "$(basename "$stream") must contain '${needle}'"
            return
        fi
    done
    ok "$name"
}

# --- help and arguments -----------------------------------------------------------

run --help
expect "--help prints usage" 0 stdout "Usage: lookup.sh"

run --frobnicate
expect "unknown option is rejected" 1 stderr "Unknown option: --frobnicate"

run --recipe
expect "--recipe without a value" 1 stderr "--recipe requires a value"

run --checklist --review
expect "--checklist followed by another option" 1 stderr "--checklist requires a value"

run --version 13
expect "keyword mode without keywords" 1 stderr "no search keywords provided"

run "TEXT" --version '13;id'
expect "--version with a shell metacharacter is rejected" 1 stderr "invalid version string"

run "TEXT" --version ..
expect "--version .. is rejected" 1 stderr "invalid version string: .."

run --deprecations --version .
expect "--deprecations --version . is rejected" 1 stderr "invalid version string: ."

# --- recipe ----------------------------------------------------------------------

run --recipe page-setup
expect "--recipe prints the recipe" 0 stdout "# Recipe: Basic Page Rendering Setup"

run --recipe no-such-recipe
expect "unknown recipe lists the available ones" 1 stderr "Recipe not found: no-such-recipe" stderr "  - page-setup"

run --recipe ../SKILL
expect "recipe name with a path is rejected" 1 stderr "invalid recipe name" stdout "!name: typo3-typoscript-ref"

# --- checklist -------------------------------------------------------------------

run --checklist fluid
expect "--checklist fluid prints only the Fluid section" 0 stdout "## Fluid Checklist" stdout "!## TypoScript Checklist"

run --checklist typoscript
expect "--checklist typoscript prints only the TypoScript section" 0 stdout "## TypoScript Checklist" stdout "!## Fluid Checklist"

run --checklist php
expect "--checklist with an unknown type" 1 stderr "checklist type must be one of"

# --- deprecations ----------------------------------------------------------------

run --deprecations
expect "--deprecations without a version prints the whole file" 0 stdout "## v12 Removals" stdout "## v14 Removals"

run --deprecations --version 13
expect "--deprecations --version 13 prints the v13 sections" 0 stdout "## v13 Removals" stdout "## v13 New Deprecations" stdout "!## v12 Removals" stdout "!## v14 Removals"

# "## v13 New Deprecations (... to be removed in v14)" precedes the v14
# sections and names v14 in its text; it must not end the v14 output.
run --deprecations --version 14
expect "--deprecations --version 14 prints every v14 section" 0 stdout "## v14 Removals" stdout "## v14 New Deprecations" stdout "## v14 Breaking Behavior Changes" stdout "## v14 New Features Replacing Older Patterns" stdout "!## v13 New Deprecations"

run --deprecations --version 12
expect "--deprecations --version 12 stops at the v13 sections" 0 stdout "## v12 Removals" stdout "### v12 Breaking Syntax Changes" stdout "!## v13 Removals"

run --deprecations --version 13.4
expect "--deprecations accepts a minor version" 0 stdout "## v13 Removals" stdout "!## v14 Removals"

run --deprecations --version 99
expect "--deprecations for a version without a section falls back to the whole file" 0 stderr "No deprecations section found for version 99" stdout "## v12 Removals"

# --- debug -----------------------------------------------------------------------

run --debug "Debugging Tools"
expect "--debug prints the matching section" 0 stdout "## Debugging Tools"

run --debug "zz-no-such-error-zz"
expect "--debug without a match prints the suggestions" 0 stdout "No matching error found for: zz-no-such-error-zz"

# A message that starts with a dash is searched for, not parsed by grep as an
# option (which made grep take the file name as the pattern and read stdin).
printf 'stdin-marker %s\n' "$REPO/skills/typo3-typoscript-ref/references/debugging.md" >"$TMP/stdin"
RC=0
(cd "$WORK" && bash "$LOOKUP" --debug "-zz-dash-message" <"$TMP/stdin") >"$TMP/stdout" 2>"$TMP/stderr" || RC=$?
expect "--debug with a message starting with a dash" 0 stdout "No matching error found for: -zz-dash-message" stdout "!stdin-marker" stderr "!grep:"
RC=0
(cd "$WORK" && bash "$LOOKUP" --debug "-9" <"$TMP/stdin") >"$TMP/stdout" 2>"$TMP/stderr" || RC=$?
expect "--debug with a dash-digit message does not read stdin" 0 stdout "No matching error found for: -9" stdout "!stdin-marker"

# --- lint rules --------------------------------------------------------------------

run --lint-rules
expect "--lint-rules without a project config" 0 stdout "No project lint config found" stdout "=== Default Lint Rules Reference ==="

mkdir -p "$TMP/linted/sub"
cat >"$TMP/linted/.typoscript-lint.yml" <<'YAML'
sniffs:
  - class: Indentation
  - class: DeadCode
    disabled: true
YAML
RC=0
(cd "$TMP/linted/sub" && bash "$LOOKUP" --lint-rules) >"$TMP/stdout" 2>"$TMP/stderr" || RC=$?
expect "--lint-rules finds the config in a parent directory" 0 stdout "Found lint config: ${TMP}/linted/.typoscript-lint.yml" stdout "DeadCode"

# --- keyword lookup ------------------------------------------------------------------

run "PAGEVIEW" --version 13
expect "keyword lookup without a cache" 1 stderr "Run 'lookup.sh --update' to fetch documentation."

mkdir -p "$CACHE/13/typoscript/contentobjects" "$CACHE/13/typoscript/elsewhere" "$CACHE/13/fluid"
echo "pageview fixture body" >"$CACHE/13/typoscript/contentobjects/pageview.md"
echo "loadregister fixture body" >"$CACHE/13/typoscript/elsewhere/loadregister.md"
echo "zz-cache-only-token fixture body" >"$CACHE/13/typoscript/notindexed.md"
echo "PAGEVIEW in the Fluid docs" >"$CACHE/13/fluid/pageview-fluid.md"

run "PAGEVIEW" --version 13
expect "keyword found through the topic index" 0 stdout "--- contentobjects/pageview.md ---" stdout "pageview fixture body" stderr "TYPO3 version: 13"

run "LOAD_REGISTER" --version 13
expect "index entry resolved by file name when the path differs" 0 stdout "--- elsewhere/loadregister.md ---"

run "zz-cache-only-token" --version 13
expect "keyword outside the index falls back to a cache search" 0 stdout "--- notindexed.md (grep match) ---"

run "zz-nowhere-zz" --version 13
expect "keyword found nowhere" 1 stderr "No results found for: zz-nowhere-zz"

run "PAGEVIEW" --version 13 --with-fluid
expect "--with-fluid adds matching Fluid docs" 0 stdout "--- fluid/pageview-fluid.md ---"

run "PAGEVIEW" --version 13 --review
expect "--review appends deprecation notes" 0 stdout "=== Deprecation / Migration Notes ==="

mkdir -p "$TMP/v13project"
printf '{"require": {"typo3/cms-core": "^13.4"}}\n' >"$TMP/v13project/composer.json"
RC=0
(cd "$TMP/v13project" && bash "$LOOKUP" "PAGEVIEW") >"$TMP/stdout" 2>"$TMP/stderr" || RC=$?
expect "version is detected from the project's composer.json" 0 stderr "TYPO3 version: 13" stdout "pageview fixture body"

# --- update ------------------------------------------------------------------------

mkdir -p "$TMP/bin"
printf '#!/usr/bin/env bash\necho "stub gh: offline" >&2\nexit 1\n' >"$TMP/bin/gh"
chmod +x "$TMP/bin/gh"
RC=0
(cd "$WORK" && PATH="$TMP/bin:$PATH" bash "$LOOKUP" --update --version 13) >"$TMP/stdout" 2>"$TMP/stderr" || RC=$?
expect "--update reports a failed source and completes" 0 stdout "stub gh: offline" stderr "Warning: failed to fetch typoscript docs." stderr "=== Fetching coreapi ===" stderr "Update complete."

RC=0
(cd "$WORK" && PATH="$TMP/bin:$PATH" bash "$LOOKUP" --update --version ..) >"$TMP/stdout" 2>"$TMP/stderr" || RC=$?
expect "--update --version .. is rejected before anything is fetched" 1 stderr "invalid version string: .." stdout "!stub gh"

echo
echo "lookup.sh: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
