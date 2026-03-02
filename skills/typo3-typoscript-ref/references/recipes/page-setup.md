# Recipe: Basic Page Rendering Setup

> Version: v12+ / v13+

## What this builds
A complete page rendering setup with HTML5 output, asset inclusion, and Fluid template rendering using either FLUIDTEMPLATE (v12) or PAGEVIEW (v13+).

## TypoScript (v12 — FLUIDTEMPLATE approach)

```typoscript
page = PAGE
page {
    typeNum = 0

    # HTML5 doctype
    config {
        doctype = html5
        htmlTag_setParams = class="no-js" lang="en" dir="ltr"
        metaCharset = utf-8
        pageTitleFirst = 1
        pageTitleSeparator = |
        pageTitleSeparator.noTrimWrap = | | |
        absRefPrefix = auto
        prefixLocalAnchors = all
        removeDefaultJS = external
        # Note: compressJs/compressCss/concatenateJs/concatenateCss removed in v13+.
        # Use external build tools (Vite, Webpack) for asset optimization instead.
        compressJs = 1
        compressCss = 1
        concatenateJs = 1
        concatenateCss = 1
    }

    # Include CSS
    includeCSS {
        main = EXT:site_package/Resources/Public/Css/main.css
    }

    # Include JavaScript
    includeJSFooter {
        main = EXT:site_package/Resources/Public/JavaScript/main.js
    }

    # Header data
    headerData {
        10 = TEXT
        10.value = <link rel="icon" href="/favicon.ico" type="image/x-icon">

        20 = TEXT
        20.value = <meta name="viewport" content="width=device-width, initial-scale=1">
    }

    # Body tag
    bodyTagCObject = COA
    bodyTagCObject {
        10 = TEXT
        10.data = pagelayout
        10.wrap = <body class="layout-|">
    }

    # Main content rendering with FLUIDTEMPLATE
    10 = FLUIDTEMPLATE
    10 {
        templateName = Default
        templateRootPaths {
            10 = EXT:site_package/Resources/Private/Templates/Page/
        }
        partialRootPaths {
            10 = EXT:site_package/Resources/Private/Partials/Page/
        }
        layoutRootPaths {
            10 = EXT:site_package/Resources/Private/Layouts/Page/
        }

        dataProcessing {
            10 = TYPO3\CMS\Frontend\DataProcessing\MenuProcessor
            10 {
                levels = 2
                includeSpacer = 1
                as = mainNavigation
            }

            20 = TYPO3\CMS\Frontend\DataProcessing\LanguageMenuProcessor
            20 {
                languages = auto
                as = languageNavigation
            }
        }

        variables {
            pageTitle = TEXT
            pageTitle.data = page:title

            rootPageId = TEXT
            rootPageId.data = leveluid:0

            copyrightYear = TEXT
            copyrightYear.data = date:U
            copyrightYear.strftime = %Y
        }
    }
}

# Global configuration
config {
    no_cache = 0
    sendCacheHeaders = 1
    # contentObjectExceptionHandler = 0  # DEV ONLY — shows exceptions. Remove in production!
    linkVars = L
    sys_language_uid = 0
    language = en
    locale_all = en_US.UTF-8
}
```

## TypoScript (v13+ — PAGEVIEW approach)

```typoscript
page = PAGE
page {
    typeNum = 0

    # HTML5 doctype
    config {
        doctype = html5
        htmlTag_setParams = class="no-js" lang="en" dir="ltr"
        metaCharset = utf-8
        pageTitleFirst = 1
        pageTitleSeparator = |
        pageTitleSeparator.noTrimWrap = | | |
        absRefPrefix = auto
    }

    # Include CSS via asset collector (preferred in v13+)
    includeCSSLibs {
        main = EXT:site_package/Resources/Public/Css/main.css
        main.disableCompression = 1
    }

    # Include JavaScript via asset collector
    includeJSFooterlibs {
        main = EXT:site_package/Resources/Public/JavaScript/main.js
        main.defer = 1
    }

    # Header data
    headerData {
        10 = TEXT
        10.value = <meta name="viewport" content="width=device-width, initial-scale=1">
    }

    # PAGEVIEW rendering (v13+)
    10 = PAGEVIEW
    10 {
        paths {
            10 = EXT:site_package/Resources/Private/Templates/
        }

        dataProcessing {
            10 = TYPO3\CMS\Frontend\DataProcessing\MenuProcessor
            10 {
                levels = 2
                includeSpacer = 1
                as = mainNavigation
            }

            20 = TYPO3\CMS\Frontend\DataProcessing\LanguageMenuProcessor
            20 {
                languages = auto
                as = languageNavigation
            }
        }

        variables {
            copyrightYear = TEXT
            copyrightYear.data = date:U
            copyrightYear.strftime = %Y
        }
    }
}

config {
    no_cache = 0
    sendCacheHeaders = 1
    # contentObjectExceptionHandler = 0  # DEV ONLY — shows exceptions. Remove in production!
}
```

## Fluid Template (v12 — FLUIDTEMPLATE)

File: `EXT:site_package/Resources/Private/Layouts/Page/Default.html`
```html
<f:layout name="Default" />

<f:section name="Main">
    <header class="site-header">
        <nav class="main-navigation">
            <f:render partial="Navigation/Main" arguments="{mainNavigation: mainNavigation}" />
        </nav>
        <f:render partial="Navigation/Language" arguments="{languageNavigation: languageNavigation}" />
    </header>

    <main class="site-content" id="content">
        <f:render section="Content" />
    </main>

    <footer class="site-footer">
        <p>&copy; {copyrightYear} My Company</p>
    </footer>
</f:section>
```

File: `EXT:site_package/Resources/Private/Templates/Page/Default.html`
```html
<f:layout name="Default" />

<f:section name="Content">
    <f:cObject typoscriptObjectPath="lib.dynamicContent" data="{pageUid: '{data.uid}', colPos: 0}" />
</f:section>
```

## Fluid Template (v13+ — PAGEVIEW)

With PAGEVIEW, the template is resolved automatically based on the backend layout. The directory structure matters:

```
Resources/Private/Templates/
  pages/
    Default.html          ← fallback
    Layout1.html          ← for backendLayout "Layout1"
    layouts/
      Default.html        ← layout file
    partials/
      Navigation/
        Main.html
```

File: `EXT:site_package/Resources/Private/Templates/pages/Default.html`
```html
<f:layout name="Default" />

<f:section name="Main">
    <header class="site-header">
        <nav class="main-navigation">
            <f:render partial="Navigation/Main" arguments="{mainNavigation: mainNavigation}" />
        </nav>
    </header>

    <main class="site-content" id="content">
        <f:cObject typoscriptObjectPath="lib.dynamicContent" data="{pageUid: '{data.uid}', colPos: 0}" />
    </main>

    <footer class="site-footer">
        <p>&copy; {copyrightYear} My Company</p>
    </footer>
</f:section>
```

## Dynamic Content Library (both versions)

```typoscript
lib.dynamicContent = COA
lib.dynamicContent {
    10 = CONTENT
    10 {
        table = tt_content
        select {
            orderBy = sorting
            where = {#colPos}=0
        }
    }
}
```

## Notes
- v12 uses `FLUIDTEMPLATE` with explicit `templateRootPaths`, `partialRootPaths`, and `layoutRootPaths`.
- v13+ introduces `PAGEVIEW` which uses a convention-based directory structure under `pages/` and resolves templates based on the backend layout identifier.
- In v13+, `compressJs`, `compressCss`, `concatenateJs`, `concatenateCss` have been removed. Use external build tools instead.
- `absRefPrefix = auto` is essential for subfolder installations and CLI-generated URLs.
- `contentObjectExceptionHandler = 0` is commented out by default. Only enable in development for debugging. In production, keep `1` (the default) to prevent broken pages.
- The `lib.dynamicContent` helper is commonly used to render content columns from within Fluid templates.
