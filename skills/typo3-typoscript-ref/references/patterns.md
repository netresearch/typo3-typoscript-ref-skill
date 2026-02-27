# TypoScript & Fluid Best Practices

General patterns and conventions. Not a tutorial — use this as a quick reference.

---

## TypoScript Organization

### Constants vs Settings

**v12:** Use `constants.typoscript` with the Constants Editor in sys_template.

```typoscript
# constants.typoscript
page.logo.file = EXT:my_ext/Resources/Public/Images/logo.svg
page.logo.alt = My Site
```

**v13+:** Prefer Site Set `settings.definitions.yaml` for typed, validated settings. Constants still work but Site Sets are the modern replacement.

```yaml
# Configuration/Sets/MySet/settings.definitions.yaml
settings:
  page.logo.file:
    label: Logo file path
    type: string
    default: EXT:my_ext/Resources/Public/Images/logo.svg
```

### File Structure

**v12 (sys_template-based):**
```
Configuration/
  TypoScript/
    setup.typoscript      # Main setup
    constants.typoscript  # Constants
    page/
      page.typoscript
    content/
      content.typoscript
```

**v13+ (Site Sets):**
```
Configuration/
  Sets/
    MySet/
      config.yaml              # Set metadata + dependencies
      setup.typoscript         # Setup TypoScript
      constants.typoscript     # Constants (backward compat)
      settings.definitions.yaml
```

### When to Split vs Single File

Split into multiple files when:
- A logical section exceeds ~100 lines
- Content types, page config, and navigation each warrant their own file
- Multiple developers work on the same extension

Keep as single file when:
- Simple site package with minimal TypoScript
- Extension plugin configuration only

### Include Order and Override Precedence

Later includes override earlier ones. Order within a sys_template or Site Set:

1. Base/framework TypoScript (e.g., `fluid_styled_content`)
2. Site package setup
3. Page-type overrides
4. Environment-specific overrides (via conditions)

```typoscript
# Explicit override — this wins over earlier definitions
page.10.variables.myVar = overridden value
```

---

## Naming Conventions

| Prefix | Purpose | Example |
|--------|---------|---------|
| `lib.*` | Reusable library objects — referenced with `=<` | `lib.breadcrumb`, `lib.navigation` |
| `temp.*` | Temporary objects — discarded after processing | `temp.menu = HMENU` |
| `plugin.tx_*` | Extbase frontend plugin configuration | `plugin.tx_news_pi1.settings.limit = 10` |
| `module.tx_*` | Backend module configuration | `module.tx_news.settings.allowedCTypes = text` |
| `tt_content.*` | Content element rendering | `tt_content.my_ctype =< lib.myRenderer` |

Use `lib.*` for anything referenced from multiple places. `temp.*` is a convention — TYPO3 does not automatically clean it, but it signals intent.

---

## Version-Specific Patterns

### v12

- Use `FLUIDTEMPLATE` for page rendering (not yet deprecated)
- Distribute TypoScript via `sys_template` static includes
- Constants via `constants.typoscript` + Constants Editor
- Conditions use Symfony Expression Language (legacy bracket syntax removed)

```typoscript
page = PAGE
page.10 = FLUIDTEMPLATE
page.10 {
    templateRootPaths.0 = EXT:my_ext/Resources/Private/Templates/
    layoutRootPaths.0 = EXT:my_ext/Resources/Private/Layouts/
    partialRootPaths.0 = EXT:my_ext/Resources/Private/Partials/
    templateName = Default
}
```

### v13

- `FLUIDTEMPLATE` is **deprecated** — migrate to `PAGEVIEW`
- Introduce Site Sets (`Configuration/Sets/*/config.yaml`)
- Use `settings.definitions.yaml` for typed settings
- `PAGEVIEW` auto-resolves templates by controller/action convention

```typoscript
page = PAGE
page.10 = PAGEVIEW
page.10 {
    paths.10 = EXT:my_ext/Resources/Private/
}
```

```yaml
# Configuration/Sets/MySet/config.yaml
name: my-vendor/my-set
label: My Site Set
dependencies:
  - typo3/fluid-styled-content
```

### v14

- Site Sets are **mandatory** for extensions providing TypoScript
- `FLUIDTEMPLATE` is **removed** — use `PAGEVIEW`
- `sys_template`-based static includes from extensions no longer supported
- All extension TypoScript must be distributed via Site Sets

---

## When to Use What

### TypoScript vs DataProcessors vs PHP Middleware

| Scenario | Use |
|----------|-----|
| Page structure and rendering configuration | TypoScript |
| Fetching and transforming data for Fluid templates | DataProcessor |
| HTTP request/response manipulation | PHP Middleware |
| Complex business logic | PHP (Controller, Service) |
| Simple value output in templates | Fluid + TypoScript data |

### COA vs COA_INT

- `COA` — cached. Use for static or rarely-changing composed output.
- `COA_INT` — uncached. Renders on every request, but only this object — the surrounding page remains cached.

```typoscript
# Good: scoped uncached rendering
lib.currentTime = COA_INT
lib.currentTime.10 = TEXT
lib.currentTime.10.data = date:U
lib.currentTime.10.strftime = %H:%M

# Avoid: makes entire page uncacheable
page.10 = USER_INT
```

Prefer `COA_INT` over `USER_INT`. `USER_INT` makes the **whole page** uncacheable.

### CONTENT cObject vs DatabaseQueryProcessor

| | `CONTENT` | `DatabaseQueryProcessor` |
|-|-----------|--------------------------|
| Output | Rendered TypoScript | Data array in Fluid variable |
| Use with | TypoScript rendering pipeline | Fluid templates |
| Flexibility | Limited to TypoScript rendering | Full Fluid template control |

Use `CONTENT` for TypoScript-only rendering pipelines. Use `DatabaseQueryProcessor` in Fluid-based setups.

```typoscript
# DatabaseQueryProcessor — preferred in Fluid setups
page.10.dataProcessing.10 = TYPO3\CMS\Frontend\DataProcessing\DatabaseQueryProcessor
page.10.dataProcessing.10 {
    table = tx_news_domain_model_news
    orderBy = datetime DESC
    max = 5
    as = latestNews
}
```

### stdWrap vs Fluid ViewHelpers

- Use `stdWrap` when transforming values within a TypoScript rendering pipeline
- Use Fluid ViewHelpers when the value is already in a template variable

```typoscript
# stdWrap — appropriate in TypoScript context
lib.pageTitle = TEXT
lib.pageTitle.data = page:title
lib.pageTitle.wrap = <h1>|</h1>
lib.pageTitle.htmlSpecialChars = 1
```

```html
<!-- Fluid — appropriate in templates -->
<h1>{data.title -> f:format.htmlspecialchars()}</h1>
```

---

## Fluid Best Practices

### No Logic in Templates

Move conditions and data transformation to DataProcessors or ViewHelpers. Templates should only render, not compute.

```html
<!-- Bad: logic in template -->
<f:if condition="{item.items -> f:count()} > 3">...</f:if>

<!-- Good: pre-computed in DataProcessor -->
<f:if condition="{hasEnoughItems}">...</f:if>
```

### Labels

Always use `f:translate` for user-facing strings. Never hardcode strings.

```html
<f:translate key="LLL:EXT:my_ext/Resources/Private/Language/locallang.xlf:my.label" />

<!-- With arguments -->
<f:translate key="LLL:EXT:my_ext/Resources/Private/Language/locallang.xlf:items.count"
             arguments="{0: items -> f:count()}" />
```

### Layouts and Partials

- **Layouts:** Define the outer HTML structure (header, footer, main). One layout per page type.
- **Partials:** Reusable fragments (cards, navigation items, form fields).
- **Templates:** The entry point — extends a layout, calls partials.

```html
<!-- Template -->
<f:layout name="Default" />
<f:section name="Main">
    <f:render partial="Card" arguments="{item: item}" />
</f:section>
```

Avoid duplicating markup — extract partials aggressively.

### Escaping

Fluid escapes output by default. Only bypass escaping when you have verified the content is safe (e.g., sanitized HTML from RTE).

```html
<!-- Auto-escaped — safe by default -->
{item.title}

<!-- Raw output — only for trusted, pre-sanitized HTML -->
<f:format.raw>{item.bodytext}</f:format.raw>
```

Never use `f:format.raw` for user-generated content without prior sanitization.

### Components (v13+)

Fluid Components (introduced in TYPO3 v13 via `typo3fluid/fluid` 4.x) provide self-contained, reusable UI elements with explicit parameter declarations.

```html
<!-- Component definition: Resources/Private/Components/Card.html -->
<fc:component>
    <fc:param name="title" type="string" />
    <fc:param name="image" type="TYPO3\CMS\Extbase\Domain\Model\FileReference" optional="true" />
    <fc:renderer>
        <article class="card">
            <h2>{title}</h2>
        </article>
    </fc:renderer>
</fc:component>

<!-- Usage -->
<fc:render component="EXT:my_ext/Resources/Private/Components/Card"
           title="{item.title}" />
```

Use Components (v13+) for new self-contained UI elements. Use traditional Partials for simpler fragments or when targeting v12 compatibility.

---

## Copy vs Reference

| Operator | Behaviour |
|----------|-----------|
| `<` | **Copy** — independent copy at the time of assignment. Changes to the original after this point do not affect the copy. |
| `=<` | **Reference** — linked to the original object. Always reflects the current state of the referenced object. |
| `>` | **Unset** — removes the property or object entirely. |

```typoscript
# Copy — independent from lib.myObject after this line
page.10 < lib.myObject

# Reference — always uses the current state of lib.navigation
page.5 =< lib.navigation

# Unset — removes the property
page.10.wrap >
```

Use `=<` (reference) for `lib.*` objects to ensure a single source of truth. Use `<` (copy) when you need an independent variant that you will modify separately.
