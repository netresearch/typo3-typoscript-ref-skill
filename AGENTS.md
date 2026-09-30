<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- SPDX-FileCopyrightText: Netresearch DTT GmbH -->

# AGENTS.md — TYPO3 TypoScript Reference Skill

Reference lookup for **TypoScript, TSconfig and Fluid** when writing, reviewing
or migrating TYPO3 configuration. Current target is v14.3 LTS; the reference
set also carries the v12 and v13 migration paths.

## Repo Structure

```
├── skills/typo3-typoscript-ref/
│   ├── SKILL.md                          # Skill definition and triggers
│   ├── evals/evals.json                  # Behavioural evals
│   ├── references/
│   │   ├── topic-index.md                # Entry point — start lookups here
│   │   ├── version-map.json              # Feature → version availability
│   │   ├── annotations.json              # Machine-readable annotations
│   │   ├── patterns.md                   # Recurring TypoScript patterns
│   │   ├── debugging.md                  # Diagnosing TypoScript at runtime
│   │   ├── recipes/                      # 14 task-shaped guides
│   │   │   ├── page-setup.md, menu-setup.md, image-rendering.md
│   │   │   ├── custom-content-element.md, extbase-plugin.md, ajax-endpoint.md
│   │   │   ├── multi-language.md, site-sets.md, rte-config.md
│   │   │   └── breadcrumb.md, sitemap.md, structured-data.md, error-pages.md
│   │   └── review/                       # 8 review-time references
│   │       ├── review-checklist.md, common-mistakes.md, deprecations.md
│   │       ├── migration-v12-to-v13.md, migration-v13-to-v14.md
│   │       └── linting.md, performance.md, security.md
│   └── scripts/
│       ├── lookup.sh                     # Query the reference set
│       ├── detect-version.sh             # Determine the project's TYPO3 version
│       ├── fetch-docs.sh                 # Pull upstream docs
│       └── rst2md.py                     # Convert fetched RST to Markdown
├── tests/                                # Behavioural tests for the scripts (tests.yml)
├── docs/
│   ├── ARCHITECTURE.md                   # Components, actors, data flows
│   └── SECURITY-ASSURANCE.md             # Security requirements, threats, limits
├── .claude-plugin/plugin.json            # Plugin manifest
├── composer.json                         # Packagist distribution
└── README.md
```

## Commands

- `bash skills/typo3-typoscript-ref/scripts/lookup.sh <term>` — search the reference set
- `bash skills/typo3-typoscript-ref/scripts/detect-version.sh --path <project>` — read the project's TYPO3 version (default: the working directory)
- `bash skills/typo3-typoscript-ref/scripts/fetch-docs.sh --version <major>` — refresh one source from upstream docs (`lookup.sh --update` fetches all four)
- `for t in tests/*.sh; do bash "$t"; done; python3 tests/rst2md.py` — the behavioural tests (offline; see README "Tests")
- `pre-commit run --all-files` — the local hooks (skill validation, version parity, markdownlint, yamllint, actionlint, JSON/YAML syntax, ruff, ShellCheck)

## Conventions

- `SKILL.md` body must stay under **500 lines** (the validator counts the lines
  after the frontmatter). Detail belongs in `references/`.
- `references/topic-index.md` is the routing table. A new reference that is not
  listed there is effectively invisible — add the entry in the same commit.
- The version lives in the root `plugin.json`; `.claude-plugin/plugin.json` is
  generated from it and must match, and a `SKILL.md` `metadata.version`, if
  present, must match too. `composer.json` carries no version (the release
  derives it from the git tag). CI and the pre-commit hook fail on drift.
- Split licensing: MIT for code, CC-BY-SA-4.0 for prose.
- Shared workflows come from `netresearch/.github/templates/skill` and are
  byte-governed by `check-template-drift`. Fix them upstream, not here; record
  a deliberate exception in `.github/template.yaml` under `intentional-drift:`.
- Every commit is signed off (`git commit -s`) — DCO is enforced in CI.

## Domain facts that keep biting

- **v14.3 is the current LTS** (released 2026-04-21); bugfixes are 14.3.1,
  14.3.2. There is no "v14.4 LTS".
- v14 removed `INCLUDE_TYPOSCRIPT` in favour of `@import`, made `userFunc`
  opt-in, and dropped the `getTSFE()` condition. Fluid 5 enforces strict
  ViewHelper argument handling.
- Version-specific claims belong in `references/version-map.json` rather than
  scattered through prose, so a lookup can answer "since when".

## Where to look first

- What the skill does and when it triggers → `skills/typo3-typoscript-ref/SKILL.md`
- Any lookup → `skills/typo3-typoscript-ref/references/topic-index.md`
- Reviewing someone's TypoScript → `skills/typo3-typoscript-ref/references/review/review-checklist.md`
- How the scripts work together → [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- Security guarantees and limits of the scripts → [docs/SECURITY-ASSURANCE.md](docs/SECURITY-ASSURANCE.md)
