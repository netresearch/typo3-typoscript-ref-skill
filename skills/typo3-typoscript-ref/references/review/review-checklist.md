# Code Review Checklists

## TypoScript Checklist
- [ ] No config.no_cache = 1 in production
- [ ] No hardcoded page UIDs (use constants/settings)
- [ ] No deprecated cObjects (FLUIDTEMPLATE in v13+, EDITPANEL)
- [ ] COA_INT/USER_INT used sparingly (each disables page cache)
- [ ] stdWrap.override / stdWrap.ifEmpty used correctly (not both)
- [ ] Conditions use Symfony Expression Language (no legacy bracket syntax)
- [ ] Copy (<) vs reference (=<) used correctly
- [ ] No duplicate path assignments
- [ ] Constants/settings used for configurable values (paths, UIDs)
- [ ] Plugin configuration under correct scope (plugin.tx_* not lib.*)
- [ ] CONTENT.select has reasonable limits (no unlimited queries)
- [ ] imgResource uses proper crop settings
- [ ] File paths are relative, not absolute
- [ ] No debug/verbose flags left enabled

## TSconfig Checklist
- [ ] TCEFORM changes target correct table.field
- [ ] TCEMAIN permissions are restrictive (principle of least privilege)
- [ ] RTE configuration matches project CKEditor preset
- [ ] TCAdefaults set sensible default values
- [ ] Page TSconfig is in correct scope (page-level, not user-level)
- [ ] No deprecated TSconfig options used
- [ ] mod.web_layout options are appropriate for editors

## Fluid Checklist
- [ ] No raw PHP or logic in templates (use ViewHelpers/DataProcessors)
- [ ] All user-visible strings use f:translate
- [ ] f:format.raw only used for known-safe content (never user input)
- [ ] f:link.typolink used instead of manual <a> tags
- [ ] Layouts and Partials used for repeated markup (DRY)
- [ ] No inline styles (use CSS classes)
- [ ] f:image/f:media used with proper crop/size settings
- [ ] Variables are type-checked before use (f:if / f:condition)
- [ ] Namespaces properly declared (xmlns:f)
- [ ] No hardcoded URLs (use f:uri.* ViewHelpers)
