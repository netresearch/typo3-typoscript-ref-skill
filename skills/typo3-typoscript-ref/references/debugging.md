# TypoScript Debugging Reference

## Common Error Messages

| Error Message | Cause | Solution |
|--------------|-------|----------|
| "The page is not configured" | No PAGE object defined or wrong typeNum | Add `page = PAGE` with `page.typeNum = 0` |
| "No TypoScript template found" | Missing sys_template record / Site Set | Create sys_template record with root flag OR configure Site Set |
| "Content Object ... not found" | Typo in cObject name or missing extension | Check spelling (TEXT, IMAGE, COA — case-sensitive) |
| "The TypoScript object path ... is not valid" | Wrong nesting or missing parent object | Check path hierarchy and ensure parent exists |
| "stdWrap ... is not a valid function" | Using stdWrap property on wrong level | Check stdWrap nesting level |
| "Could not find template file" | Wrong templateRootPaths or file name | Verify paths and file naming convention |
| "Fluid template ... not found" | FLUIDTEMPLATE/PAGEVIEW template path wrong | Check templateName and templateRootPaths |
| "No layout found with name ..." | Layout file missing or wrong layoutRootPaths | Create layout file or fix path |
| "Rendering the Content-Object ... returned ..." | Exception in content rendering | Check inner cObject configuration |
| "Page not found (404)" | No page record or wrong domain/language | Check site configuration and page visibility |
| "Access denied (403)" | Frontend user permissions | Check fe_group settings on page/content |
| "TypoScript condition parse error" | Invalid Symfony Expression Language | Check condition syntax, use expression builder |

---

## Debugging Tools

### Development Mode

```typoscript
# Show full errors instead of custom error pages (DEV ONLY)
config.contentObjectExceptionHandler = 0
```

### stdWrap Debugging

```typoscript
lib.myObject = TEXT
lib.myObject {
    value = Hello
    # Shows stdWrap processing state at this point
    debug = 1
    # Shows detailed debug output (1 = var_dump, 2 = debug())
    debugFunc = 2
    # Outputs current data array
    debugData = 1
}
```

### Admin Panel

```typoscript
# Enable Admin Panel for backend users in frontend
config.admPanel = 1
```

The Admin Panel provides tabs for:
- Preview (page, time, workspace)
- Cache (info and flush)
- TypoScript (object browser, conditions)
- Info (GET/POST data, page info)

### TypoScript Object Browser

Located in Backend > Template module > TypoScript Object Browser.

Use to:
- Inspect the compiled TypoScript tree
- Search for specific object paths
- Verify that includes and conditions are applied

### System Log

Backend > System > Log module shows TypoScript-related errors and warnings, including template loading failures.

### TYPO3 Debug Console

In Development context, exceptions include a stack trace in the browser. Set `TYPO3_CONTEXT=Development` in your `.env` or server config.

---

## Common Debugging Patterns

### "Why is my TypoScript not applied?"

1. **Check include order** — TypoScript is processed top-to-bottom. A later include overwrites earlier definitions.
2. **Check conditions** — Use the Admin Panel > TypoScript tab to see which conditions evaluate to true/false.
3. **Clear all caches** — Backend > Flush all caches (lightning bolt). TypoScript is cached; changes require a cache flush.
4. **Check template hierarchy** — Sys_template records inherit from parent pages. Verify the root template has the "Root" flag set.
5. **Check context** — `[context("..")]` conditions depend on application context (Production, Development).

```typoscript
# Verify a value is set by outputting it directly
page.10 = TEXT
page.10.value = DEBUG: check if this renders
```

### "Why is my Fluid template empty?"

1. **Check variable passing** — Use `stdWrap.debug = 1` on the DATA source or add a temporary `{f:debug(value: myVar)}` in the template.
2. **Check DataProcessor output** — Add a temporary debug viewhelper to inspect processor results.

```html
<!-- Temporary debug output in Fluid template -->
<f:debug title="All variables">{_all}</f:debug>
<f:debug title="My processor result">{myProcessorVariable}</f:debug>
```

3. **Check templateRootPaths** — The path must resolve to an existing file. Use absolute EXT: paths or verified filesystem paths.
4. **Check templateName** — The file name must match exactly (case-sensitive on Linux).

```typoscript
10 = FLUIDTEMPLATE
10 {
    templateRootPaths.0 = EXT:my_ext/Resources/Private/Templates/
    # templateName resolves to .../Templates/MyTemplate.html
    templateName = MyTemplate
}
```

### "Why is my page cached incorrectly?"

1. **Use COA_INT for dynamic content** — `COA_INT` (and `USER_INT`) bypasses the page cache for that object.

```typoscript
# This content is excluded from page cache
lib.dynamic = COA_INT
lib.dynamic {
    10 = TEXT
    10.data = date:U
    10.strftime = %H:%M:%S
}
```

2. **Check no_cache** — `config.no_cache = 1` disables caching for the entire page. Use sparingly.
3. **Check cache tags** — Extensions may set cache tags. Flushing tagged caches via the Admin Panel or CLI can resolve stale content.
4. **Check condition-dependent content** — Conditions evaluated at cache-build time are baked in. Use `_INT` objects for content that must vary per request.

### "Why does my condition not work?"

Conditions use Symfony Expression Language since TYPO3 v10. Legacy TypoScript syntax (`[browser = ...]`) is no longer supported.

```typoscript
# Correct: Symfony Expression Language
[request.getNormalizedParams().isHttps()]
    config.forceAbsoluteUrls = 1
[end]

[traverse(request.getQueryParams(), 'type') == 2]
    page.typeNum = 2
[end]

# Page UID condition
[page["uid"] == 42]
    # Applied only on page 42
[end]

# Backend user logged in
[backend.user.isLoggedIn]
    config.admPanel = 1
[end]

# Site set / application context
[applicationContext == "Development"]
    config.contentObjectExceptionHandler = 0
[end]
```

Available condition variables:
- `page` — current page record fields
- `request` — PSR-7 request object
- `site` — current site configuration
- `siteLanguage` — current site language
- `frontend.user` — frontend user data
- `backend.user` — backend user data
- `applicationContext` — TYPO3 application context string
- `tree` — page tree info (rootLine, level)
