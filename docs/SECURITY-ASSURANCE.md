<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- SPDX-FileCopyrightText: Netresearch DTT GmbH -->

# Security assurance case — typo3-typoscript-ref-skill

This document states what a user can expect from this repository in terms of security, and argues why that expectation holds. Every claim names the file that implements it. Reporting a vulnerability: see the [security policy](https://github.com/netresearch/.github/blob/main/SECURITY.md). Components and data flows: [ARCHITECTURE.md](ARCHITECTURE.md).

`references/review/security.md` is different: it is advice for reviewing the TypoScript and Fluid of the user's TYPO3 project, not a statement about this repository.

## What the repository ships

| Part | Files | Runs where |
| --- | --- | --- |
| Skill instructions for an AI agent | `skills/typo3-typoscript-ref/SKILL.md`, `skills/typo3-typoscript-ref/references/**/*.md` | Read by the agent as instructions and reference text; not executed. |
| Reference data | `references/version-map.json`, `references/annotations.json` | Read by the scripts. |
| Scripts | `skills/typo3-typoscript-ref/scripts/lookup.sh`, `detect-version.sh`, `fetch-docs.sh`, `rst2md.py` | On the user's machine, started by the agent or the user, usually in the user's TYPO3 project. |
| Repository checks | `tests/*`, `.github/workflows/*` | In this repository's CI and on contributors' machines. |

The repository ships no server component, no container image and no code that runs inside a TYPO3 installation. It handles no accounts and stores no credentials; `fetch-docs.sh` uses whatever `gh` login the user already has.

## Security requirements

1. The scripts do not change the user's project. `detect-version.sh` and every `lookup.sh` mode except `--update` only read files; `fetch-docs.sh` (called by `--update`) writes only into `cache/<version>/<source>/` below the package root (`<package root>/cache`, next to `skills/`), or below the directory given with `--cache-dir`, which can be inside the project if the user points it there.
2. Only `fetch-docs.sh` uses the network: read-only `gh api` requests to the four documentation repositories listed in `references/version-map.json`.
3. A value from the command line or from a project file cannot be run as a command or as code.
4. Project files are data: `composer.lock`, `composer.json` and a TypoScript lint configuration are parsed, never executed.
5. Nothing committed to this repository contains a secret.
6. A release's tag equals the version in `.claude-plugin/plugin.json`, which CI keeps equal to the root `plugin.json` on every pull request; the tag must be signed, and the archives can be verified against the build that produced them.

## Actors and trust boundaries

- **Skill user and agent.** The agent reads `SKILL.md` and the references and runs `lookup.sh` with the user's permissions. `SKILL.md` declares no `allowed-tools`; the agent keeps whatever tools and permissions its session has.
- **The user's project.** Treated as data. `detect-version.sh` reads `composer.lock` and `composer.json` with Python's `json` module; `lookup.sh --lint-rules` reads `.typoscript-lint.yml`, `typoscript-lint.yml` or `tslint.yml` with `yaml.safe_load` (or prints it when PyYAML is missing). Both look in the working directory and up to five parent directories.
- **Upstream documentation.** The TYPO3 documentation repositories named in `version-map.json` are trusted as the source of the documentation. `fetch-docs.sh` converts their reStructuredText to Markdown and `lookup.sh` prints it to the agent, which reads it as reference text.
- **GitHub API.** `fetch-docs.sh` calls `gh api` for a tree listing and file contents, with the user's `gh` login.
- **Contributors.** Changes reach `main` through pull requests, checked by the workflows in `.github/workflows/`.
- **CI.** Workflows run on GitHub-hosted runners with `permissions: {}` at the top level and grant each job only the scopes its reusable workflow needs. `auto-merge-deps.yml` and `labeler.yml` run on `pull_request_target`; they call reusables that merge or label pull requests and do not check out pull request code, and `auto-merge-deps.yml` passes two named secrets instead of `secrets: inherit`.

## Threats and countermeasures

| Threat | Countermeasure | Evidence |
| --- | --- | --- |
| A command-line value is interpreted by the shell or by Python (CWE-78, CWE-94) | Values are quoted in the shell; values handed to Python go through environment variables (`_VERSION`, `LOCKFILE`, `JSONFILE`, `_CONFIG_FILE`, …), never into the Python source; `--version` must match `^[a-zA-Z0-9][a-zA-Z0-9._-]*$` | `lookup.sh`, `detect-version.sh`, `fetch-docs.sh`; `tests/lookup.sh` (`13;id` is rejected) |
| A version or recipe name points outside the intended directory (CWE-22) | `--version` must start with a letter or digit, so `.` and `..` are rejected before any file is written; `--recipe` accepts only `[a-zA-Z0-9_-]`; `--checklist` accepts only `typoscript`, `tsconfig`, `fluid`; `--source` accepts only the four known sources | `lookup.sh`, `fetch-docs.sh`; `tests/lookup.sh`, `tests/fetch-docs.sh` (`..`, `.`, `.hidden`, `../SKILL`) |
| A search text is read as an option by `grep` | Keywords that start with `-` are rejected as unknown options; the `--debug` message is passed after `--`; searches use fixed strings (`grep -F`) | `lookup.sh`; `tests/lookup.sh` (`-9`, `-zz-dash-message`) |
| A project file runs code on the user's machine | `composer.*` is parsed with `json.load`, the lint configuration with `yaml.safe_load`; an unparsable `composer.lock` falls through to `composer.json`, and `main` is the answer only when neither yields a version; an unparsable lint configuration yields an error message | `detect-version.sh`, `lookup.sh`; `tests/detect-version.sh` (unparsable files) |
| A failed download is taken for a complete cache | Each file is converted on its own; a failed download or conversion leaves no file and removes a copy cached by an earlier run, is named on stderr and counted in the summary | `fetch-docs.sh`; `tests/fetch-docs.sh` (a stale cached page is removed) |
| An update changes files outside the cache | `fetch-docs.sh` writes only below `cache/<version>/<source>/` or `--cache-dir`; the other modes write nothing | `fetch-docs.sh`, `lookup.sh`; `tests/fetch-docs.sh`, `tests/lookup.sh` (both run the scripts from a temporary copy of the skill) |
| A released archive is tampered with, or released from an unsigned tag | The release workflow verifies that the tag is signed and publishes a Cosign-signed `SHA256SUMS.txt` and build-provenance attestations for the archives | `.github/workflows/release.yml` (calls the skill-repo-skill release reusable) |
| A secret is committed | Betterleaks scans every push to `main` and every pull request to `main` and fails when it finds one | `.github/workflows/security.yml` |
| A vulnerable or malicious dependency is added | Dependency review fails a pull request to `main` on vulnerabilities of severity high or above; Composer Audit checks the Composer dependencies; Renovate proposes updates | `.github/workflows/security.yml`, `renovate.json` |
| Insecure code or workflow patterns | Opengrep fails on the findings the [organisation rule](https://github.com/netresearch/.github/blob/main/SECURITY.md#static-analysis-sast) names; zizmor reports workflow findings to code scanning; ShellCheck and ruff run in Skill Validation and in the pre-commit hooks | `.github/workflows/security.yml`, `.github/workflows/lint.yml`, `.pre-commit-config.yaml` |
| A change breaks a script unnoticed | The behavioural tests run on every pull request and push to `main` | `.github/workflows/tests.yml`, `tests/` |

Which of these checks must pass before a pull request can merge is set in the branch protection of `main`, not in this repository; the README section "Governance and policies" lists the current state.

## Secure design principles applied

- **Least privilege:** the scripts read the project and write only into the cache (`<package root>/cache` or `--cache-dir`); workflows start from `permissions: {}`.
- **Fail safe:** invalid arguments end the script with exit code 1 before any request or write; when neither `composer.lock` nor `composer.json` yields a version, the answer is `main` instead of a guess.
- **Economy of mechanism:** four short scripts using bash, the Python standard library and `gh`; PyYAML is optional.
- **Separation of data and code:** values reach Python through the environment, `grep` through fixed-string patterns after `--`, and project files through JSON and safe YAML parsers.

## What a user cannot expect

- The skill gives guidance; it does not enforce it. The agent writes TypoScript and runs commands with the user's permissions; review what it proposes.
- The cached documentation is only as current as the last `--update` and only as trustworthy as the upstream repositories. Pages are fetched from a branch, not pinned to a commit, and are not checked against a signature. Their text reaches the agent unfiltered.
- The curated references and annotations are written by hand and can be wrong or out of date; check a claim that matters against the official TYPO3 documentation.
- Version detection and `--lint-rules` also read files in up to five parent directories of the working directory, which can lie outside the project. For a constraint such as `^12.4 || ^13.4` the detected version is the first number, `12`.
- `fetch-docs.sh` exits 0 when single files fail; the summary line states how many.
- Security fixes follow the supported-versions rules of the organisation's security policy; older releases may not receive them.
