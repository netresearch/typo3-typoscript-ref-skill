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
- A `composer.json` in the project for automatic TYPO3 version detection
  (falls back to the latest supported version)

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
```

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
other agent platforms are served via the Composer and npm distribution
channels (documented exception per skill-repo validation checklist).

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

## License

MIT (code) and CC-BY-SA-4.0 (documentation content) — see `LICENSE-MIT` and
`LICENSE-CC-BY-SA-4.0`. Copyright Netresearch DTT GmbH.

## Credits

Developed by [Netresearch DTT GmbH](https://www.netresearch.de/) for the
Claude Code ecosystem.
