<!-- SPDX-License-Identifier: CC-BY-SA-4.0 -->
<!-- SPDX-FileCopyrightText: Netresearch DTT GmbH -->

# Common TypoScript/TSconfig/Fluid Mistakes

## TypoScript Mistakes

### stdWrap Nesting Error

Wrong: property.stdWrap.wrap = |
Right: property.wrap = | (stdWrap properties apply directly)

### optionSplit Syntax

Wrong: wrap = <li>|</li> (same for all items)
Right: wrap = <li class="first">|</li> |*| <li>|</li> |*| <li class="last">|</li>

### Condition Syntax (v12+)

Wrong: [globalVar = GP:L=1]
Right: [siteLanguage("languageId") == 1]

### getTSFE() in Conditions (removed in v14)

Wrong: [getTSFE() && getTSFE().id == 42]
Right: [page["uid"] == 42] or [request?.getPageArguments()?.getPageId() == 42]
(getTSFE() was removed in v14 (#107473) — use page, request, site, siteLanguage)

### File Includes (v14)

Wrong: <INCLUDE_TYPOSCRIPT: source="FILE:EXT:my_ext/Configuration/TypoScript/setup.typoscript">
Right: @import 'EXT:my_ext/Configuration/TypoScript/setup.typoscript'
(INCLUDE_TYPOSCRIPT was removed in v14; deprecated since v13.4)

### userFunc Without Opt-In Registration (v14)

Problem: TypoScript/TSconfig callables (userFunc, postUserFunc, ...) are no longer executed unless explicitly registered (#108054)
Solution: Register the callable for TypoScript usage in the extension (opt-in allow-list); silent non-execution is the typical symptom

### Copy vs Reference

Wrong: lib.footer < lib.header (independent copy — changes to lib.header won't reflect)
When you want: lib.footer =< lib.header (reference — follows changes)
When to use copy: When you want to modify the copy without affecting original

### Reference Into a Path That No Longer Exists

Wrong: `10 =< tt_content.list.20.myext_pi1` after the plugin moved to a CType
Symptom: no error, no log entry — something entirely different renders
Why: `ContentObjectRenderer::mergeTSRef()` walks the path segment by segment and keeps the value of the **deepest segment that exists**, with the configuration of the full path (empty here). `tt_content.list` is `=< lib.contentElement`, so the reference silently becomes a FLUIDTEMPLATE and renders the site's default template
Solution: verify the **full** path resolves, not just its prefix — in the TypoScript Object Browser, or by grepping the registration that creates it

### Override Order Pitfall

Problem: TypoScript from Site Set may be overridden by sys_template records
Solution: Check sys_template include order; Site Set TypoScript loads first

### Missing stdWrap Level

Wrong: 10.wrap = <div>|</div> (may not work if 10 is a cObject)
Right: 10.stdWrap.wrap = <div>|</div>

### insertData and dataWrap on JSON

Wrong: `wrap = {"query":"{register:q}","results":[|]}` with `insertData = 1`, or the same string as `dataWrap`
Symptom: the output still sits in a `<script>` tag or a JSON response, but it is shredded — on TYPO3 14.3.7 `{"status":"ok","query":"{register:q}","results":[…]}` came out as `","results":[]}`
Why: `insertData` hands everything between `{` and `}` to `getData()`, and JSON is nothing but braces. `insertData` also runs after `wrap`, so braces added by `wrap` are affected too, and `dataWrap` runs `insertData()` on its wrap string
Right: a `###PLACEHOLDER###` in the value or wrap plus `replacement` with `replace.data = register:q`. `replacement` runs before `wrap`, so for a placeholder inside `wrap` put it under `orderedStdWrap.10.replacement` (see `recipes/ajax-endpoint.md`)

### Meta Tag Sub-Properties in page.meta

Wrong: `page.meta.og:image:width = 1200` (also `og:image:height`, `og:image:alt`) with EXT:seo installed
Symptom: every page on which no `og:image` was added before that line renders the TYPO3 exception page instead of content
Why: `RequestHandler::generateMetaTagHtml()` passes no sub-properties, so the full key reaches `AbstractMetaTagManager::addProperty()`. EXT:seo's OpenGraph manager claims the key and accepts it only when it already holds an `og:image`; otherwise it throws `UnexpectedValueException` 1524209729 (checked against 14.3.7; observed uncaught during page generation on 14.3.5). Without EXT:seo the generic manager takes any key and nothing throws
Right: let EXT:seo emit `og:image` with its sub-properties from the page's own `og_image` field; set only top-level properties in `page.meta`

### robots From the Page Record

Problem: removing `page.meta.robots` does not remove the robots tag
Why: EXT:seo's `MetaTagGenerator` adds `robots` from the page record whenever `no_index` or `no_follow` is set
Solution: check both fields on the pages in question as well as the TypoScript

### Smoke Check That Accepts the Exception Page

Wrong: `curl -s https://example.com/ | grep -qi typo3`
Why: the debug exception handler titles its page `TYPO3 Exception`, so the grep passes a site that throws on every request
Right: require HTTP 200 and a marker from the site's own template, and fail on `TYPO3 Exception` and on the production handler's `Oops, an error occurred!`

## TSconfig Mistakes

### TCEFORM Wrong Path

Wrong: TCEFORM.tt_content.header_layout =
Right: TCEFORM.tt_content.header_layout.removeItems = 1,2
(empty assignment doesn't remove items)

### Wrong Scope

Wrong: User TSconfig for page-level settings
Right: Page TSconfig for TCEFORM, mod.*, TCEMAIN

## Fluid Mistakes

### XSS via f:format.raw

Wrong: {userInput -> f:format.raw()} — XSS vulnerability
Right: {userInput} (auto-escaped) or use f:sanitize.html

### f:translate Key Format

Wrong: <f:translate key="myLabel" />
Right: <f:translate key="LLL:EXT:myext/Resources/Private/Language/locallang.xlf:myLabel" />
Or: <f:translate key="myLabel" extensionName="myext" />

### Missing Required Arguments

Wrong: <f:link.typolink parameter="{data.uid}">Link</f:link.typolink>
Right: <f:link.typolink parameter="{data.header_link}">Link</f:link.typolink>

### Logic in Templates

Wrong: Complex conditions and loops in Fluid templates
Right: Move logic to DataProcessors; template only renders data

## Inheritance Pitfalls

- Site Set settings override constants but not setup
- Extension TypoScript loads before page-specific TypoScript
- TSconfig: User TSconfig can override Page TSconfig for some settings
