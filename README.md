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

## Installation

### Claude Code Marketplace
(upcoming)

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
