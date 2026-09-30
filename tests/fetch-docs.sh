#!/usr/bin/env bash
# SPDX-License-Identifier: MIT
# SPDX-FileCopyrightText: Netresearch DTT GmbH
#
# Behavioural tests for skills/typo3-typoscript-ref/scripts/fetch-docs.sh.
#
# A stub `gh` first on PATH answers the two GitHub API calls the script makes
# (the recursive tree listing and the per-file contents) from a fixture
# directory, so the whole pipeline runs offline: file selection, cache path
# mapping, the rst2md.py conversion, error counting and the annotation pass.
# The skill is copied into a temporary tree so the default cache directory
# (<repo>/cache) lands there too.
#
# Run from anywhere: bash tests/fetch-docs.sh

set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/repo"
mkdir -p "$REPO/skills"
cp -R "$ROOT/skills/typo3-typoscript-ref" "$REPO/skills/"
FETCH="$REPO/skills/typo3-typoscript-ref/scripts/fetch-docs.sh"

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
    printf '     stdout: %s\n' "$(head -c 600 "$TMP/stdout")"
    printf '     stderr: %s\n' "$(head -c 600 "$TMP/stderr")"
}

# --- stub gh ---------------------------------------------------------------------

UPSTREAM="$TMP/upstream"
export STUB_UPSTREAM="$UPSTREAM"
export STUB_LOG="$TMP/gh.log"
mkdir -p "$TMP/bin"
cat >"$TMP/bin/gh" <<'STUB'
#!/usr/bin/env bash
# Answers `gh api repos/<repo>/git/trees/<ref>?recursive=1 --jq ...` with the
# Documentation/ paths of $STUB_UPSTREAM, one per line (what the real --jq
# filter prints), and `gh api repos/<repo>/contents/<path>?ref=<ref> --jq
# .content` with the base64 body. A path containing "Broken" fails.
echo "$*" >>"$STUB_LOG"
[[ "${1:-}" == "api" ]] || exit 2
url="${2:-}"
case "$url" in
    */git/trees/*)
        (cd "$STUB_UPSTREAM" && find Documentation -type f 2>/dev/null | sort)
        ;;
    */contents/*)
        path="${url#*/contents/}"
        path="${path%%\?*}"
        [[ "$path" == *Broken* ]] && exit 1
        [[ -f "$STUB_UPSTREAM/$path" ]] || exit 1
        base64 "$STUB_UPSTREAM/$path"
        ;;
    *)
        exit 2
        ;;
esac
STUB
chmod +x "$TMP/bin/gh"

upstream_file() {
    mkdir -p "$(dirname "$UPSTREAM/$1")"
    cat >"$UPSTREAM/$1"
}

# run <args...> — run fetch-docs.sh with the stub gh first on PATH
run() {
    RC=0
    : >"$STUB_LOG"
    PATH="$TMP/bin:$PATH" bash "$FETCH" "$@" >"$TMP/stdout" 2>"$TMP/stderr" || RC=$?
}

expect_exit() {
    if [[ "$RC" -eq "$2" ]]; then
        ok "$1"
    else
        not_ok "$1" "expected exit $2, found ${RC}"
    fi
}

expect_file() {
    if [[ -f "$2" ]]; then ok "$1"; else not_ok "$1" "missing file: $2"; fi
}

expect_no_file() {
    if [[ ! -e "$2" ]]; then ok "$1"; else not_ok "$1" "unexpected file: $2"; fi
}

expect_grep() {
    if grep -qF -- "$3" "$2"; then ok "$1"; else not_ok "$1" "$(basename "$2") must contain '$3'"; fi
}

# --- fixture upstream repository -------------------------------------------------------

upstream_file Documentation/Index.rst <<'RST'
=================
TypoScript Manual
=================

Start page.
RST
upstream_file Documentation/ContentObjects/Pageview/Index.rst <<'RST'
PAGEVIEW
========

Renders a page with ``PAGEVIEW``.

.. code-block:: typoscript

   page.10 = PAGEVIEW
RST
upstream_file Documentation/Functions/Stdwrap.rst <<'RST'
stdWrap
=======

The stdWrap function.
RST
upstream_file Documentation/Functions/Broken.rst <<'RST'
Broken
======
RST
upstream_file Documentation/_includes/Shared.rst <<'RST'
Included
========
RST
upstream_file Documentation/Images/Caption.rst <<'RST'
Caption
=======
RST
upstream_file Documentation/Sitemap.rst <<'RST'
Sitemap
=======
RST
upstream_file Documentation/Settings.cfg <<'CFG'
[general]
CFG

# --- argument validation -------------------------------------------------------------

run
expect_exit "missing --version is rejected" 1
expect_grep "missing --version names the flag" "$TMP/stderr" "--version is required"

run --version 13 --source wiki
expect_exit "unknown --source is rejected" 1
expect_grep "unknown --source lists the valid ones" "$TMP/stderr" "must be one of: typoscript, fluid, viewhelpers, coreapi"

run --version '13 14'
expect_exit "--version with a space is rejected" 1

run --version 13 --bogus
expect_exit "unknown option is rejected" 1
expect_grep "unknown option prints the usage" "$TMP/stderr" "Usage: fetch-docs.sh"

run --version
expect_exit "--version without a value is rejected" 1

mkdir -p "$TMP/nogh"
ln -s "$(command -v dirname)" "$TMP/nogh/dirname"
RC=0
PATH="$TMP/nogh" "$BASH" "$FETCH" --version 13 >"$TMP/stdout" 2>"$TMP/stderr" || RC=$?
expect_exit "missing gh is reported" 1
expect_grep "missing gh names the tool" "$TMP/stderr" "'gh' (GitHub CLI) is required"

# --- download and convert ------------------------------------------------------------------

run --version 13 --source typoscript
OUT="$REPO/cache/13/typoscript"
expect_exit "fetch with one failing file exits 0" 0
expect_grep "the TYPO3 major version maps to the docs branch" "$STUB_LOG" "api repos/TYPO3-Documentation/TYPO3CMS-Reference-Typoscript/git/trees/13.4?recursive=1"
expect_grep "summary counts successes and errors" "$TMP/stdout" "Downloaded 3 files, 1 errors"
expect_grep "the failing file is named" "$TMP/stderr" "failed to process Documentation/Functions/Broken.rst"
expect_file "top-level Index.rst becomes index.md" "$OUT/index.md"
expect_file "Dir/Name/Index.rst becomes dir/name.md" "$OUT/contentobjects/pageview.md"
expect_file "Dir/Name.rst becomes dir/name.md" "$OUT/functions/stdwrap.md"
expect_no_file "a failed download leaves no file" "$OUT/functions/broken.md"
expect_no_file "_includes/ is skipped" "$OUT/_includes"
expect_no_file "Images/ is skipped" "$OUT/images"
expect_no_file "Sitemap.rst is skipped" "$OUT/sitemap.md"
expect_no_file "non-rst files are skipped" "$OUT/settings.md"
expect_grep "content is converted to Markdown" "$OUT/contentobjects/pageview.md" '```typoscript'
if grep -qF "Settings.cfg" "$STUB_LOG"; then
    not_ok "only selected files are downloaded" "Settings.cfg was requested"
else
    ok "only selected files are downloaded"
fi

# --- annotations -----------------------------------------------------------------------

run --version 13 --source typoscript --annotate
expect_exit "fetch with --annotate exits 0" 0
# annotations.json has v13 entries for pageview and stdwrap among the fetched
# pages; the other v13 entries have no cache file and are skipped.
expect_grep "annotations are applied where the cache file exists" "$TMP/stdout" "Applied 2 annotations"
expect_grep "an annotation without a cache file is reported" "$TMP/stderr" "cache file not found"
first="$(head -1 "$OUT/contentobjects/pageview.md")"
if [[ "$first" == '> **'*'(v13):**'* ]]; then
    ok "the annotation is the first line of the file"
else
    not_ok "the annotation is the first line of the file" "found: ${first}"
fi
run --version 13 --source typoscript --annotate
count="$(grep -c '(v13):\*\*' "$OUT/contentobjects/pageview.md")"
if [[ "$count" -eq 1 ]]; then
    ok "annotating twice keeps one annotation"
else
    not_ok "annotating twice keeps one annotation" "found ${count} annotation lines"
fi

# --- sources, branches and cache directory --------------------------------------------------

upstream_file Documentation/ApiOverview/Fluid/Index.rst <<'RST'
Fluid
=====
RST
run --version 14 --source coreapi --cache-dir "$TMP/custom"
expect_exit "coreapi fetch exits 0" 0
expect_grep "coreapi uses the Core API repository and branch" "$STUB_LOG" "api repos/TYPO3-Documentation/TYPO3CMS-Reference-CoreApi/git/trees/14.3?recursive=1"
expect_file "coreapi keeps the Fluid chapter" "$TMP/custom/14/coreapi/apioverview/fluid.md"
expect_no_file "coreapi skips everything outside the Fluid chapter" "$TMP/custom/14/coreapi/index.md"
expect_no_file "--cache-dir replaces the default cache directory" "$REPO/cache/14"

run --version main --source fluid --cache-dir "$TMP/custom"
expect_grep "a version outside the map is used as the branch" "$STUB_LOG" "api repos/TYPO3/Fluid/git/trees/main?recursive=1"

rm -rf "$UPSTREAM/Documentation"
run --version 13 --source typoscript --cache-dir "$TMP/empty"
expect_exit "an empty Documentation/ tree is an error" 1
expect_grep "an empty tree is reported" "$TMP/stderr" "no files found in Documentation/ directory"

echo
echo "fetch-docs.sh: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
