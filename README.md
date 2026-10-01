<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- SPDX-FileCopyrightText: Netresearch DTT GmbH -->

# TYPO3 TypoScript Reference Skill

Version-aware TypoScript, TSconfig and Fluid reference lookup for Claude Code
with always-on best practices.

## What this skill solves

AI coding agents frequently hallucinate TypoScript properties, invent
non-existent ViewHelpers, or suggest patterns that were deprecated several
TYPO3 versions ago. Generic documentation tools like Context7 provide raw
library docs but lack the TYPO3-specific curation needed to produce correct,
modern TypoScript.

This skill solves that by providing **structured, version-aware reference
data** tailored for AI agents:

| Capability | This Skill | Generic Docs |
| ---------- | ---------- | ------------ |
| Version detection | Auto from `composer.json` | Manual |
| Offline usage | Local cache after first fetch | API call per request |
| Annotations | deprecated/required/recommended | Not available |
| Migration guides | Before/after code, v12-v13, v13-v14 | Not available |
| Recipes | 14 curated patterns | Raw docs only |
| Code review mode | Deprecations, checklists, lint rules | Not available |
| Debugging support | Maps error messages to solutions | Not available |
| Lint integration | Reads `typoscript-lint.yml` config | Not available |
| Scope | TypoScript, TSconfig, Fluid, ViewHelpers | General-purpose |

The skill enforces correctness through **rules**: agents must look up
references before writing TypoScript, follow annotation levels, and check
project lint rules. This prevents the most common AI mistakes — using removed
properties, mixing v12 and v13 syntax, or ignoring site-specific coding
standards.

## Use when

- Writing or editing TypoScript, TSconfig or Fluid templates in a TYPO3
  project (v12, v13 or v14)
- Reviewing TypoScript/Fluid changes for deprecations and anti-patterns
- Migrating a TYPO3 site between major versions (v12 to v13, v13 to v14)
- Debugging TypoScript errors such as "The page is not configured" or
  "No TypoScript template found"
- Looking up cObjects, stdWrap functions, DataProcessors, conditions or
  ViewHelpers without guessing property names

## Expected outputs

- Reference excerpts from the official TYPO3 documentation for the detected
  TYPO3 version, prefixed with best-practice annotations
  (required/recommended/deprecated/tip)
- Ready-to-use recipes (page setup, menus, Extbase plugins, Site Sets, ...)
- Code review findings with deprecation tables, checklists and project lint
  rules
- Migration guidance with before/after TypoScript snippets
- Debugging hints mapping error messages to causes and fixes

## Context requirements

- `gh` CLI (authenticated with GitHub) for fetching the documentation cache
- Python 3 (for rST conversion and JSON parsing)
- Bash 4+
- Network access on first run (`scripts/lookup.sh --update`); all lookups are
  served from the local cache afterwards
- A `composer.json` or `composer.lock` in the project for automatic TYPO3
  version detection from `typo3/cms-core` (without it, the lookup uses
  `main`, the development branch of the upstream documentation)

## Features

- Version-aware documentation (TYPO3 v12, v13, v14)
- Local cache — no network dependency after initial fetch
- Always-on best practice annotations (deprecated/recommended/required)
- 14 ready-to-use recipes for common TYPO3 patterns
- Code review support with deprecation checks and migration guides
- Project-specific lint rule detection (helmich/typo3-typoscript-lint)
- Debugging reference for common TypoScript error messages

## Installation

### Claude Code Marketplace

```bash
/plugin marketplace add netresearch/claude-code-marketplace
/plugin install typo3-typoscript-ref@netresearch-claude-code-marketplace
```

### Without a marketplace

Since Claude Code 2.1.157 a plugin directory under your personal skills directory loads on its own:

```bash
mkdir -p ~/.claude/skills
git clone https://github.com/netresearch/typo3-typoscript-ref-skill.git \
  ~/.claude/skills/typo3-typoscript-ref
```

It loads as `typo3-typoscript-ref@skills-dir` on the next session. Update with `git -C ~/.claude/skills/typo3-typoscript-ref pull` and start a new session; remove it by deleting the directory. This route has no `claude plugin update`.

Then install the skill via `/plugin`.

### Composer

```bash
composer require netresearch/typo3-typoscript-ref-skill
```

### Manual

Download the latest release and extract to `~/.claude/skills/typo3-typoscript-ref/`

## Usage

### First Run

Populate the local cache for your TYPO3 version:

```bash
scripts/lookup.sh --update
```

### Reference Lookup

```bash
scripts/lookup.sh "stdWrap wrap"
scripts/lookup.sh "PAGEVIEW" --with-fluid
```

### Recipes

```bash
scripts/lookup.sh --recipe page-setup
scripts/lookup.sh --recipe menu-setup
```

### Code Review

```bash
scripts/lookup.sh "FLUIDTEMPLATE" --review
scripts/lookup.sh --deprecations
scripts/lookup.sh --checklist typoscript
```

### Debugging

```bash
scripts/lookup.sh --debug "The page is not configured"
```

## Example prompts

- "Look up how `stdWrap.wrap` works in TYPO3 v13 TypoScript."
- "Review this TypoScript file for deprecated syntax before our v14 upgrade."
- "Show me the recipe for a PAGEVIEW-based page setup with Site Sets."
- "Why does my `[getTSFE() && getTSFE().id == 42]` condition fail after
  upgrading to TYPO3 v14?"

## Supported TYPO3 Versions

| TYPO3 | TypoScript Ref | Fluid | ViewHelpers |
| ----- | -------------- | ----- | ----------- |
| 12.4 | 12.4 | 2.12 | 12.4 |
| 13.4 | 13.4 | 4.6 | 13.4 |
| 14.3 | 14.3 | 5.3 | 14.3 |

## Documentation Sources

- TypoScript Explained (TYPO3-Documentation/TYPO3CMS-Reference-Typoscript)
- Fluid Explained (TYPO3/Fluid)
- Fluid ViewHelper Reference
- TYPO3 Explained — Fluid chapter

## Skill metadata

| Field | Value |
| ----- | ----- |
| action_level | read-only (lookups and local cache writes under `cache/`) |
| risk_level | low |

`agents/openai.yaml` is intentionally absent: the skill targets Claude Code;
other agent platforms are served via the Composer distribution channel
(documented exception per skill-repo validation checklist).

When discovery-relevant fields change (description, topics, summary), update
the marketplace entry in `netresearch/claude-code-marketplace` as well.

## Related skills

- [typo3-docs-skill](https://github.com/netresearch/typo3-docs-skill) —
  TYPO3 documentation authoring
- [typo3-conformance-skill](https://github.com/netresearch/typo3-conformance-skill)
  — extension conformance checks
- [typo3-testing-skill](https://github.com/netresearch/typo3-testing-skill) —
  unit and functional tests for TYPO3 extensions
- [typo3-upgrade-effort-model-skill](https://github.com/netresearch/typo3-upgrade-effort-model-skill)
  — upgrade effort estimation
- [typo3-vite-skill](https://github.com/netresearch/typo3-vite-skill) — Vite
  frontend pipeline for TYPO3

## Contributing

Contributions are welcome via pull request. CI validates the repository via
the reusable workflows from
[skill-repo-skill](https://github.com/netresearch/skill-repo-skill); to run
the same validation locally, execute `validate-skill.sh` from a checkout of
that repository against this repo root.

Content changes (references, recipes, annotations) must be verified against
the official TYPO3 documentation for the affected version.

The components, actors and data flows are described in
[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md); what the skill does and does not
guarantee in terms of security is in
[docs/SECURITY-ASSURANCE.md](docs/SECURITY-ASSURANCE.md).

## Tests

The tests under `tests/` run the shipped scripts and check what they print, write and return. They need `bash`, `python3` and the usual coreutils; they make no network request and write only to temporary directories.

- `tests/detect-version.sh`: `composer.lock` before `composer.json`, `packages-dev` and `require-dev`, the constraint forms (`v13.4.2`, `^13.4`, `~12.4`, `>=12.4,<13`, `dev-main`), unparsable files, the five-parent search limit, and rejected arguments.
- `tests/lookup.sh`: every mode (`--recipe`, `--checklist`, `--deprecations`, `--debug`, `--lint-rules`, keyword lookup with `--with-fluid` and `--review`, `--update`) against the shipped references and a fixture cache, run from a temporary copy of the skill; `--update` runs with a stub `gh` that always fails.
- `tests/fetch-docs.sh`: the whole download pipeline with a stub `gh` that serves a fixture `Documentation/` tree: which files are selected, the cache paths, the conversion, error counting, annotations, `--cache-dir`, and rejected arguments.
- `tests/rst2md.py`: headings, code blocks, admonitions, roles, `confval`, dropped directives, whitespace clean-up, and the stdin-to-stdout call.

The curated references, `evals/evals.json` and the prose of `SKILL.md` have no behavioural test; CI checks their structure.

Run the tests and the hooks from the repository root:

```bash
for t in tests/*.sh; do bash "$t"; done
python3 tests/rst2md.py
pre-commit run --all-files
```

Each case prints `ok <case>`, or `FAIL <case>` followed by what was expected and what was found; the last line counts passed and failed cases, and the file exits 1 when a case failed. The pre-commit hooks in `.pre-commit-config.yaml` run the skill validator, the version-parity check, markdownlint, yamllint, actionlint, JSON and YAML syntax, ruff and ShellCheck.

In CI, `tests.yml` (Skill Tests) runs every `tests/**/*.sh` and `tests/**/*.py` on each pull request and push to `main`, marks a failing file with an error annotation, and fails when the scripts under `skills/*/scripts/` have no test at all. A change to a script comes with a test that fails without the change; new functionality comes with tests.

## Dependencies

- **Scripts:** `bash` 4+, `python3` (standard library only) and coreutils (`base64`, `find`, `grep`, `sed`, `tr`). `fetch-docs.sh`, and so `lookup.sh --update`, also needs the GitHub CLI `gh` with a login. `lookup.sh --lint-rules` uses PyYAML when it is installed and prints the raw file otherwise. The scripts install nothing.
- **Documentation sources:** the four upstream repositories and the branch per TYPO3 version are listed in `skills/typo3-typoscript-ref/references/version-map.json`; the downloaded pages live in the untracked `cache/` directory.
- **Composer:** `composer.json` requires `netresearch/composer-agent-skill-plugin` (constraint `*`), the Composer plugin that installs packages of type `ai-agent-skill`. No lock file is committed (the skill validator rejects `composer.lock` in skill repositories): the package is installed as a dependency of other projects, whose lock files pin it.
- **Tests:** `bash`, `python3` and coreutils; `gh` is replaced by a stub.
- **Pre-commit hooks:** each hook repository in `.pre-commit-config.yaml` is pinned by `rev:`.
- **CI:** the workflows call reusable workflows of `netresearch/skill-repo-skill`, `netresearch/.github` and `netresearch/typo3-ci-workflows` at `@main`; those pin their third-party actions by commit SHA.
- **Updates:** Renovate (`renovate.json`, preset `github>netresearch/renovate-config`) opens pull requests for new versions, including the pre-commit hook revisions; `auto-merge-deps.yml` enables auto-merge for Renovate and Dependabot pull requests, which GitHub merges once the required checks pass. Composer Audit and dependency review check dependency changes on pull requests.
- **Selection:** a new dependency is added only when a script or the tooling needs it, from its upstream source (Packagist, PyPI, the tool's own repository), under a licence the organisation's [findings policy](https://github.com/netresearch/.github/blob/main/SECURITY.md#handling-of-dependency-and-code-analysis-findings) accepts.

## Governance and policies

This repository follows the Netresearch organisation policies:

- [Governance](https://github.com/netresearch/.github/blob/main/GOVERNANCE.md): ownership, roles, how decisions are made and disputes resolved.
- [Roadmap](https://github.com/netresearch/.github/blob/main/ROADMAP.md): planned and explicitly excluded work for the coming year.
- [Handling of dependency and code analysis findings](https://github.com/netresearch/.github/blob/main/SECURITY.md#handling-of-dependency-and-code-analysis-findings): thresholds, deadlines and the exception process for dependency (SCA) and static analysis (SAST) findings.
- [Secret management](https://github.com/netresearch/.github/blob/main/SECURITY.md#secret-management): how CI and release credentials are stored, accessed and rotated.
- [Access roster](https://github.com/netresearch/.github/blob/main/docs/access-roster.md): who holds administrative access to this repository and the organisation.

Checks that run on pull requests in this repository:

- Every pull request: Skill Validation (`lint.yml`: skill structure, manifest sync, markdownlint, yamllint, actionlint, JSON syntax, ShellCheck, ruff, checkpoint schemas), Eval Validation (`eval-validate.yml`), Skill Tests (`tests.yml`), the Labeler (`labeler.yml`) and Auto-merge dependency PRs (`auto-merge-deps.yml`, which acts only on Renovate and Dependabot pull requests); configured outside the workflows: CodeQL through GitHub's default setup (Actions and Python), SonarCloud, the CodeRabbit review and the Copilot code review that the repository ruleset requests.
- Pull requests to `main`: `security.yml` with Composer Audit, SAST (Opengrep, `--config auto`; which findings fail the check is set by the [organisation rule](https://github.com/netresearch/.github/blob/main/SECURITY.md#static-analysis-sast)), Betterleaks secret scanning, zizmor and dependency review (`fail-on-severity: high`); Harness Verification (`harness-verify.yml`); Template Drift (`check-template-drift.yml`); and the DCO sign-off check.
- Secret detection: Betterleaks in `security.yml`, and GitHub secret scanning with push protection, which is enabled for the repository.
- Required for merging into `main`: Skill Validation, Eval Validation, Skill Tests, Composer Audit, SAST (Opengrep), Secret Scanning (Betterleaks) and DCO; commits must be signed.

## License

MIT (code) and CC-BY-SA-4.0 (documentation content) — see `LICENSE-MIT` and
`LICENSE-CC-BY-SA-4.0`. Copyright Netresearch DTT GmbH.

## Credits

Developed by [Netresearch DTT GmbH](https://www.netresearch.de/) for the
Claude Code ecosystem.
