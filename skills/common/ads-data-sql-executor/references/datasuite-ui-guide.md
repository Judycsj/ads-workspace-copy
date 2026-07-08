# DataSuite Adhoc Query UI Guide

> Originally from ads-text2sql, now maintained in ads-text2da.
> Caches UI element selectors and navigation patterns for Playwright automation.

## Adhoc Query Page

- URL: `https://datasuite.shopee.io/studio`
- SQL Editor type: Monaco (bundled as `ShopeeCDNMonacoEditor`)
- SQL Editor element: accessed via `window.ShopeeCDNMonacoEditor.editor.getEditors()[0]`
- Clear editor method: `ShopeeCDNMonacoEditor.editor.getEditors()[0].setValue('')`
- Set content method: `ShopeeCDNMonacoEditor.editor.getEditors()[0].setValue(sql)`
- Editor placeholder overlay: `.editor-placeholder.visible` — must hide with `style.display = 'none'` before interacting

## Execution Controls

- Run button: look for button with text "Run" or play icon in toolbar area
- Project selector: default project `mkplpaidads_data` — use snapshot to find dropdown
- Engine selector (Presto / SparkSQL): use snapshot to find engine toggle/dropdown

## Status Indicators

- Running state: monitor for spinner or "Running" text in status area
- Success state: result table appears below editor
- Failed state: error message appears in log/error panel

## Results Panel

- Results table element: `document.querySelectorAll('table')` — find the one with `tbody tr` rows >= expected
- Data extraction: `thead th` for headers, `tbody tr > td` for cell values
- Each row has a trailing "View Row" cell — strip it when extracting data
- Row count / stats element: shown near results table header

## Error / Log Panel

- Error message element: look for error text in panel below editor
- Log panel element: may contain execution logs, query plan info
