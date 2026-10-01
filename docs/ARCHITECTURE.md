<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- SPDX-FileCopyrightText: Netresearch DTT GmbH -->

# Architecture — typo3-typoscript-ref-skill

This document describes the components the repository ships, the actors that use them, and how data flows between them. It describes the code at the commit it is part of; a change that adds, removes or rewires a script, a reference file or an external source updates this document in the same pull request. Security properties: [SECURITY-ASSURANCE.md](SECURITY-ASSURANCE.md).

## Actors

- **Skill user**: installs the skill (Claude Code marketplace, a clone under `~/.claude/skills/`, Composer or a release archive) and works in a TYPO3 project.
- **AI agent**: loads `skills/typo3-typoscript-ref/SKILL.md` when a task involves TypoScript, TSconfig or Fluid, runs `scripts/lookup.sh` in the user's project directory with the user's permissions, and reads the reference files.
- **Upstream documentation**: four GitHub repositories named in `references/version-map.json` (`github_repos`): TYPO3-Documentation/TYPO3CMS-Reference-Typoscript, TYPO3/Fluid, TYPO3-Documentation/TYPO3CMS-Reference-ViewHelper and TYPO3-Documentation/TYPO3CMS-Reference-CoreApi.
- **GitHub API**: reached only through the user's `gh` CLI login, by `fetch-docs.sh`.
- **Maintainers and contributors**: change the repository through pull requests checked by the workflows in `.github/workflows/`.

## Components

| Component | Files | Role |
| --- | --- | --- |
| Skill definition | `skills/typo3-typoscript-ref/SKILL.md` | Trigger description, the rules the agent follows, and the `lookup.sh` commands to run. |
| Curated references | `skills/typo3-typoscript-ref/references/**/*.md` | Recipes, review checklists, deprecations, migration guides, debugging and security notes, written for this skill. `topic-index.md` maps keywords to pages of the upstream documentation cache. |
| Reference data | `references/version-map.json`, `references/annotations.json` | TYPO3 major version to documentation branch per source, the upstream repositories, the fallback version (`main`); best-practice annotations per version and page. |
| `lookup.sh` | `skills/typo3-typoscript-ref/scripts/lookup.sh` | Single entry point for the agent. Modes: keyword lookup, `--recipe`, `--deprecations`, `--checklist`, `--lint-rules`, `--debug`, `--update`. |
| `detect-version.sh` | `skills/typo3-typoscript-ref/scripts/detect-version.sh` | Prints the project's TYPO3 major version, or `main`. |
| `fetch-docs.sh` | `skills/typo3-typoscript-ref/scripts/fetch-docs.sh` | Downloads one upstream source for one version and writes it as Markdown into the cache; optionally applies annotations. |
| `rst2md.py` | `skills/typo3-typoscript-ref/scripts/rst2md.py` | Converts reStructuredText on stdin to Markdown on stdout (Python standard library only). |
| Documentation cache | `<package root>/cache/<version>/<source>/` | Created by `fetch-docs.sh`; not in git (`.gitignore`). `<package root>` is the directory that holds `skills/`: the clone, the plugin directory or the Composer package. |
| Tests | `tests/*.sh`, `tests/rst2md.py` | Behavioural tests for the four scripts, run offline (see README "Tests"). |
| Packaging | `plugin.json`, `.claude-plugin/plugin.json`, `composer.json` | Plugin manifest (root file is the source, the other is generated) and the Composer package of type `ai-agent-skill`. |

## Data flows

### Version detection

`detect-version.sh [--path <dir>]` looks for `composer.lock` in the start directory (default: the working directory) and up to five parent directories, and reads the version of `typo3/cms-core` from `packages` or `packages-dev`. Without a result it does the same for `composer.json` and reads the constraint from `require` or `require-dev`. It prints the first number of the version (`v13.4.2` → `13`, `^12.4` → `12`), or `main` for `dev-main` or `dev-master`, and when neither file yields a usable version: an unparsable `composer.lock` falls through to `composer.json`, and only when that gives nothing either is the answer `main`. The JSON is parsed by `python3`; the file path is passed in an environment variable.

### Filling the cache

`lookup.sh --update [--version <v>]` resolves the version (the flag, else `detect-version.sh`) and runs `fetch-docs.sh --version <v> --source <s> --annotate` for `typoscript`, `fluid`, `viewhelpers` and `coreapi`. A failed source is reported as a warning; the update continues.

`fetch-docs.sh`:

1. validates `--version` (letters, digits, `.`, `_`, `-`, starting with a letter or digit) and `--source`, and requires `gh`;
2. maps the version to a branch or tag with `version-map.json` (`typo3_to_docs`); a value not in the map is used as the branch;
3. lists the repository tree with `gh api repos/<repo>/git/trees/<branch>?recursive=1` and keeps `.rst` files under `Documentation/` (for `coreapi` only `Documentation/ApiOverview/Fluid/`), skipping `_includes/`, `_snippets/`, `CodeSnippets/`, `Images/`, `_ext/` and the meta pages `Sitemap`, `genindex`, `search`, `Targets`, `404`;
4. downloads each file with `gh api repos/<repo>/contents/<path>?ref=<branch>`, five at a time, base64-decodes it, pipes it through `rst2md.py` and writes `cache/<version>/<source>/<lowercased path>.md` (`Dir/Name/Index.rst` becomes `dir/name.md`); a failed download or conversion leaves no file, removes a copy cached by an earlier run, and counts as an error; the script still exits 0 and prints the counts;
5. with `--annotate`, prepends the `annotations.json` entry for the version as a blockquote to the mapped cache pages, replacing an earlier annotation.

`--cache-dir <path>` replaces the default cache directory.

### Answering a lookup

- **Keyword** (`lookup.sh <keywords> [--version <v>]`): resolves the version, finds rows in `references/topic-index.md` containing a keyword, resolves each row's path in `cache/<v>/typoscript/` (or the older `cache/<docs branch>/typoscript/` layout) (exact path, then known renames, then by file name) and prints the pages. Without an index match it searches the cached pages for the keyword. `--with-fluid` adds matching pages from `cache/<v>/fluid/`; `--review` appends matching lines of `references/review/deprecations.md`.
- **Reference modes** read only files shipped in `references/`: `--recipe <name>` prints `recipes/<name>.md`; `--checklist <typoscript|tsconfig|fluid>` prints that section of `review/review-checklist.md`; `--deprecations [--version <v>]` prints the `## v<major> …` sections of `review/deprecations.md`, or the whole file; `--debug <message>` prints the sections of `debugging.md` whose heading contains the message, else matching lines, else general advice.
- **`--lint-rules`** looks for `.typoscript-lint.yml`, `typoscript-lint.yml` or `tslint.yml` in the working directory and up to five parents, lists the configured sniffs (with PyYAML; without it, prints the file), then prints `review/linting.md`.

All output goes to stdout for the agent to read; diagnostics go to stderr. Only `--update` writes files, and only into the cache.

## Continuous integration

`lint.yml` (Skill Validation), `eval-validate.yml`, `tests.yml` (Skill Tests), `security.yml`, `harness-verify.yml`, `check-template-drift.yml`, `scorecard.yml`, `labeler.yml`, `auto-merge-deps.yml` and `release.yml` call reusable workflows of netresearch/skill-repo-skill, netresearch/.github and netresearch/typo3-ci-workflows. All but `tests.yml` are managed by the organisation's skill template. The checks each workflow runs are listed in the README section "Governance and policies".
