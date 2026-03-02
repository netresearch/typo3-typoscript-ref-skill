# TYPO3 TypoScript Reference Skill

Version-aware TypoScript, TSconfig and Fluid reference lookup for Claude Code with always-on best practices.

## Features

- Version-aware documentation (TYPO3 v12, v13, v14)
- Local cache — no network dependency after initial fetch
- Always-on best practice annotations (deprecated/recommended/required)
- 14 ready-to-use recipes for common TYPO3 patterns
- Code review support with deprecation checks and migration guides
- Project-specific lint rule detection (helmich/typo3-typoscript-lint)
- Debugging reference for common TypoScript error messages

## Why This Skill?

AI coding agents frequently hallucinate TypoScript properties, invent non-existent ViewHelpers, or suggest patterns that were deprecated several TYPO3 versions ago. Generic documentation tools like Context7 provide raw library docs but lack the TYPO3-specific curation needed to produce correct, modern TypoScript.

This skill solves that by providing **structured, version-aware reference data** tailored for AI agents:

| Capability | This Skill | Context7 / Generic Docs |
|-----------|-----------|------------------------|
| Version detection | Auto-detects from `composer.json` | Manual version specification |
| Offline usage | Local cache after first fetch | API call per request |
| Best practice annotations | Injected into docs (deprecated/required/recommended) | Not available |
| Migration guides | Before/after code with step-by-step instructions (v12-v13, v13-v14) | Not available |
| Ready-to-use recipes | 14 curated patterns (page setup, menus, data processors, ...) | Raw documentation only |
| Code review mode | Deprecation checks, checklists, lint rule detection | Not available |
| Debugging support | Maps error messages to solutions | Not available |
| TypoScript lint integration | Reads project `typoscript-lint.yml` config | Not available |
| Scope | TypoScript, TSconfig, Fluid, ViewHelpers | General-purpose |

### Designed for Agent Workflows

The skill enforces correctness through **rules**: agents must look up references before writing TypoScript, follow annotation levels, and check project lint rules. This prevents the most common AI mistakes — using removed properties, mixing v12 and v13 syntax, or ignoring site-specific coding standards.

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

## Supported TYPO3 Versions

| TYPO3 | TypoScript Ref | Fluid | ViewHelpers |
|-------|---------------|-------|-------------|
| 12.4 | 12.4 | 2.12 | 12.4 |
| 13.4 | 13.4 | 4.3 | 13.4 |
| 14.x | main | 5.0 | main |

## Documentation Sources

- TypoScript Explained (TYPO3-Documentation/TYPO3CMS-Reference-Typoscript)
- Fluid Explained (TYPO3/Fluid)
- Fluid ViewHelper Reference
- TYPO3 Explained — Fluid chapter

## Requirements

- `gh` CLI (authenticated with GitHub)
- Python 3 (for rST conversion and JSON parsing)
- Bash 4+

## License

MIT — Netresearch DTT GmbH

## Credits

Developed by [Netresearch DTT GmbH](https://www.netresearch.de/) for the Claude Code ecosystem.
