---
name: typo3-typoscript-ref
description: "Use when writing, editing, reviewing or debugging TypoScript, TSconfig or Fluid templates in TYPO3 projects. Also use for code reviews of .typoscript, .tsconfig and Fluid .html files, and when suggesting improvements or checking for deprecated patterns"
---

# TYPO3 TypoScript, TSconfig and Fluid Reference

Version-aware local lookup with always-on best practices.

## Usage

```bash
# Reference lookup
scripts/lookup.sh "stdWrap wrap"

# With Fluid context
scripts/lookup.sh "PAGEVIEW" --with-fluid

# Recipe for common tasks
scripts/lookup.sh --recipe page-setup

# Code review mode (adds deprecation warnings)
scripts/lookup.sh "FLUIDTEMPLATE" --review

# Deprecation list
scripts/lookup.sh --deprecations

# Review checklist
scripts/lookup.sh --checklist typoscript

# Project lint rules
scripts/lookup.sh --lint-rules

# Debug error message
scripts/lookup.sh --debug "The page is not configured"

# Update cache
scripts/lookup.sh --update

# Override version
scripts/lookup.sh "TEXT" --version 12
```

## Rules

1. ALWAYS run lookup.sh before writing TypoScript/TSconfig/Fluid code
2. ALWAYS follow best practice annotations (required/deprecated/recommended/tip levels)
3. ALWAYS check project lint rules before writing TypoScript (--lint-rules)
4. When writing NEW code: use the most modern approach for the detected version
5. When reviewing EXISTING code: flag deprecated and required-level annotation violations
6. For combined TypoScript+Fluid tasks: use --with-fluid flag
7. Never generate `config.no_cache = 1` in production setups
8. Prefer DataProcessors over CONTENT cObject in Fluid-based templates

## First Run

```bash
scripts/lookup.sh --update
```
