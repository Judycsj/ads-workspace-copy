<!-- ads-workspace-gdoc-sync: gdoc_id=1bNnVF-pFSK_U1bnpeX2W4boBjySa_-LlczWc-N63xys gdoc_url=https://docs.google.com/document/d/1bNnVF-pFSK_U1bnpeX2W4boBjySa_-LlczWc-N63xys/edit -->

# pas-mcn

> MCN (Multi-Channel Network) Ads Portal Module — built on the Multi-Module Framework (MMF) for Shopee Seller Portal. Module ID: **310**. Available regions: Indonesia (`id`), Vietnam (`vn`).
>
> GitLab: https://git.garena.com/shopee/isfe/ao/pas-mcn

---

## Table of Contents

- [Project Overview](#project-overview)
- [Key Features](#key-features)
- [Project Architecture](#project-architecture)
- [Directory Structure](#directory-structure)
- [Quick Start](#quick-start)
  - [Prerequisites](#prerequisites)
  - [Configuration](#configuration)
  - [Installation](#installation)
  - [Build](#build)
  - [Local Development](#local-development)
  - [Development](#development)
  - [Deployment](#deployment)
- [API Documentation](#api-documentation)
- [Local Storage](#local-storage)
- [TMS Tracking](#tms-tracking)
- [Performance Monitoring](#performance-monitoring)
- [Business Terminology Glossary](#business-terminology-glossary)
- [References](#references)
- [Frequently Asked Questions](#frequently-asked-questions)

---

## Project Overview

`pas-mcn` is a Vue 3 module that powers the Shopee MCN (Multi-Channel Network) Ads Portal. It enables MCN operators to create and manage live-stream ad campaigns for their affiliated creators, monitor aggregate and per-affiliate performance metrics, handle budget top-ups, and review transaction history — all within the Seller Portal via the Multi-Module Framework.

---

## Key Features

- **Live-stream ad campaign management** — create new campaigns, restart paused ones, edit settings (schedule, budget, bidding), and view campaign detail with performance charts and tables.
- **MCN homepage dashboard** — aggregate view across all affiliates: credit balance, core KPI metrics, ads statistics table, and per-affiliate statistics.
- **Affiliate-scoped homepage** — drill-down view for a single affiliate's campaigns and performance.
- **Target ROAS bidding strategy** — supports both max-GMV and max-views bidding modes with target ROI/ROAS configuration.
- **Mass editing** — batch-update campaign status, budget, or settings across multiple campaigns at once.
- **Performance analytics** — time-series charts, per-metric breakdowns, and data export to CSV.
- **Top-up & transaction management** — initiate top-ups via checkout flow and review full transaction history with MCN-specific export.
- **Multi-language support** — 20+ languages via the EDS Vue `i18n` system.
- **Region-aware routing** — module is whitelisted for `id` and `vn` regions; redirects from legacy Seller Center routes.

---

## Project Architecture

### Module Composition

`pas-mcn` is an MMF **module** (not a portal). It is loaded dynamically by the Seller Portal host via the Multi-Module Framework runtime. Its entry point is `src/index.ts`, which registers routes, stores, and the root Vue app via framework exports.

```
Seller Portal (host)
  └── MMF runtime
        └── pas-mcn (module 310)         ← this repo
              ├── framework (shared MMF context: router, i18n, environment, request)
              └── pas-common (remote CDN module, shared ads utilities)
```

The shared `pas-common` module is loaded from CDN by default (`config.cdnPrefix`). For local debugging, comment out `remoteAppHost = config.cdnPrefix` in `mmc.config.js` and run `pas-common` locally.

### State Management

Stores use **Vue 3 `reactive()`** directly (no Pinia or Vuex modules). Three store slices:

| Store file | Contents |
|---|---|
| `src/_shared/store/config/meta.ts` | `adsToggle`, `adsCredit`, ads metadata |
| `src/_shared/store/config/contantine.ts` | `ADS_CONFIG`, `BID_PRICE`, `CURRENCY`, `LINK`, `NUMBER_CONSTANTS`, `FEATURE_DOWNGRADE` |
| `src/_shared/store/config/meta-non-ads.ts` | External toggle, user shop info |
| `src/_shared/store/report/index.ts` | `summaryDate`, `cachedTimeRange`, `selectedMetrics`, `reportLoadStatus` |

### Router

Base path: `/portal/pas`. Routes are defined in `src/router/index.ts` using the `RouterMap` enum:

| Route name | Path | Page |
|---|---|---|
| `MCN_HOMEPAGE` | `/portal/pas` | `pages/homepage` |
| `MCN_AFFILIATE_HOMEPAGE` | `/affiliate/:affiliateId` | `pages/affiliateHomepage` |
| `MCN_LIVE_CREATE` | `/live/create` | `pages/create` |
| `MCN_LIVE_RESTART` | `/live/restart/:campaignId` | `pages/create` |
| `MCN_LIVE_DETAIL` | `/live/detail/:campaignId` | `pages/detail` |
| `MCN_TOP_UP` | `/top-up` | `pages/top-up` |
| `MCN_TRANSACTION` | `/transaction` | `pages/transaction` |

Legacy Seller Center routes (`SC_HOMEPAGE`, `SC_TOPUP`) redirect to the new paths.

### Request Layer

All API calls go through `src/_shared/api/request/index.ts`, built on `@seller-portal/request` (axios-based). Features:

- Automatic camelCase → snake_case conversion for GET parameters
- Rate-limit error handling (error code 7)
- Seller Gateway session refresh (`refresh-seller-gateway-session.ts`)
- Region-aware base URL (`*.shopee.sg`, `*.shopee.co.id`, etc.)
- `withCredentials: true`; error toasts via EDS

---

## Directory Structure

```
pas-mcn/
├── src/
│   ├── _shared/                      # Cross-page shared layer
│   │   ├── api/                      # Domain-split API modules
│   │   │   ├── affiliate/            # Affiliate search & detail
│   │   │   ├── common/               # Meta, config, banner
│   │   │   ├── homepage/             # MCN & affiliate homepage queries
│   │   │   ├── live-stream/          # Campaign CRUD & estimation
│   │   │   ├── report/               # Chart, metrics, export
│   │   │   ├── request/              # HTTP client + interceptors
│   │   │   ├── top-up/               # Top-up settings
│   │   │   └── transaction/          # Transaction history & export
│   │   ├── assets/                   # Images (PNG) and SVGs
│   │   ├── components/               # Reusable Vue components
│   │   │   ├── ads-type-selector/
│   │   │   ├── affiliate-cell.vue
│   │   │   ├── affiliate-common-header/
│   │   │   ├── affiliate-info/
│   │   │   ├── campaign-state-badge/
│   │   │   ├── conditional-search/
│   │   │   ├── custom-skeleton/
│   │   │   ├── export-button/
│   │   │   ├── info-cell/
│   │   │   ├── mass-edit-group/
│   │   │   ├── mcn-ads-table/
│   │   │   ├── status-panel.vue/
│   │   │   └── time-picker-range/
│   │   ├── composable/               # Vue 3 composables
│   │   │   ├── useCreationBudget.ts
│   │   │   ├── useDuration.ts
│   │   │   ├── usePagination.ts
│   │   │   ├── useRoute.ts
│   │   │   └── useSelectMetrics.tsx
│   │   ├── constants/                # API endpoints, campaign enums, metric config
│   │   ├── framework/                # MMF framework exports (router, i18n, request, environment)
│   │   ├── routes/                   # Shared route definitions
│   │   ├── store/                    # Reactive stores (config/, report/)
│   │   ├── styles/                   # Global SCSS (page.scss)
│   │   ├── types/                    # TypeScript types (campaign, common)
│   │   └── utils/                   # csv, currency, date, time, type utilities
│   ├── pages/
│   │   ├── index.vue                 # Root layout wrapper
│   │   ├── homepage/                 # MCN aggregate homepage
│   │   ├── affiliateHomepage/        # Single-affiliate homepage
│   │   ├── create/                   # Campaign creation & restart
│   │   ├── detail/                   # Campaign detail & editing
│   │   ├── top-up/                   # Top-up / payment
│   │   └── transaction/              # Transaction history
│   ├── router/                       # Vue Router config (index.ts)
│   ├── track/                        # TMS tracking event functions
│   └── index.ts                      # Module entry point
├── config/                           # Build helpers (babel, eslint, tsconfig)
├── mmc.config.js                     # MMC module config (ID: 310, tech: vue3)
├── .gitlab-ci.yml                    # CI/CD: lint → release_verify → auto_deploy
├── eslintrc.js                       # ESLint config (extends @shopee/pas-module-config)
├── commitlint.config.js              # Commitlint config
└── package.json
```

---

## Quick Start

### Prerequisites

| Tool | Version |
|---|---|
| Node.js | >= 16.14.0 (Node 20 recommended) |
| pnpm | >= 8.0.0 |
| yarn | any |
| MMC | latest V3.x |

### Configuration

Set the npm registry to Shopee's internal registry before installing dependencies:

```bash
npm config set registry https://npm.shopee.io/
```

### Installation

Install MMC globally (one-time, skip if already installed):

```bash
pnpm i -g @shopee/multi-module-cli
mmc setup        # sets up MMC environment
mmc -V           # verify: should show 4 version lines
```

Install project dependencies and initialize the module:

```bash
# Recommended: installs deps + runs mmc init in one step
yarn start

# Or separately:
yarn run init    # run once before first dev session
yarn dev
```

`mmc init` fetches module config from the Seller Portal test environment and writes it to `config/.remote-config.json`.

### Build

```bash
yarn build
```

This runs `mmc build` for production. The output goes to `dist/`.

### Local Development

1. Run `yarn start` (or `yarn run init` once, then `yarn dev`).
2. Open the MCN test portal: [https://mcn.affiliate.test.shopee.co.id](https://mcn.affiliate.test.shopee.co.id)
3. Log in with test credentials:
   - Username: `mcn_id.2`
   - Password: `123456`
4. Click **Shopee Ads** in the left navigation bar.
5. Open the browser DevTools console and run:
   ```js
   window.proxy.mmfDevtools.enable()
   ```
6. Reload the page — the portal connects to your local dev server. You should see `[MMF_DEVTOOLS]` and `[HMR] connected` in the console.

#### Developing with pas-common locally

By default, `pas-common` is loaded from CDN. To debug changes to `pas-common`:

1. Start `pas-common` dev server locally.
2. In `mmc.config.js`, comment out:
   ```js
   // remoteAppHost = config.cdnPrefix
   ```

### Development

```bash
yarn dev            # start dev server with concurrent type checking
yarn dev:remote     # remote development mode
yarn type:check     # TypeScript validation only
yarn lint           # ESLint + Stylelint
yarn lint:fix       # auto-fix linting issues
```

### Deployment

CI/CD is defined in `.gitlab-ci.yml`:

| Stage | Trigger | Action |
|---|---|---|
| `lint` | Every MR | `yarn lint` |
| `release_verify` | MR + push | Verify release via deploy platform API |
| `auto_deploy` | Push to `master` | Auto-deploy to test and UAT environments |

For production releases:

1. Run `yarn build` or trigger a build in the Seller Portal deploy platform.
2. After a successful build, click **Publish** in the build records table.
3. Select the portal, PFB, and target regions in the release form.
4. Submit — the Space job handles the actual deployment.

To take the module offline, toggle **Offline Mode** before building and releasing.

---

## API Documentation

All endpoints are relative to the base prefix (see `src/_shared/api/request/base.ts`). Available prefixes:

| Prefix constant | Value |
|---|---|
| `V1` | `/api/pas_mcn/v1` |
| `FREE` | *(empty — prepends nothing)* |

| Page | API Endpoint | Description |
|---|---|---|
| Common | `/meta/get/` | Get ads metadata (`adsToggle`, `adsCredit`, etc.) |
| Common | `/config/get/` | Get runtime configuration |
| Common | `/meta/get_ads_data/` | Get ads data |
| Common | `/meta/get_non_ads_data/` | Get non-ads data (external toggle, shop info) |
| Common | `/setup_helper/get_budget_data_for_edit/` | Budget data for campaign editing |
| Common | `/banner/get/` | Get banner info |
| Common | `/banner/modify/` | Modify banner |
| Common | `/setup_helper/get_recommended_roi_two_target/` | Get recommended ROI targets |
| Common | `/api/v2/pas/login/` | Login to Seller Platform (`FREE` prefix) |
| Homepage | `/homepage/query_for_mcn/` | Query MCN aggregate homepage data |
| Homepage | `/homepage/query_affiliate_for_mcn/` | Query per-affiliate data for MCN |
| Homepage | `/homepage/mass_edit/` | Mass-edit campaign statuses/budgets |
| Live Stream | `/live_stream/get_setup_status/` | Get campaign setup status |
| Live Stream | `/live_stream/publish/` | Publish (create) a new campaign |
| Live Stream | `/live_stream/edit/` | Edit an existing campaign |
| Live Stream | `/live_stream/get/` | Get campaign data |
| Live Stream | `/live_stream/get_estimated_data/` | Estimated performance for a campaign |
| Live Stream | `/live_stream/get_budget_data_for_creation/` | Budget data for new campaign |
| Live Stream | `/live_stream/check_overlapping_ads_for_roi_two/` | Check overlapping ads (target ROI mode) |
| Live Stream | `/live_stream/search_target_affiliate/` | Search affiliates to target |
| Live Stream | `/live_stream/get_affiliate/` | Get affiliate details |
| Report | `/report/get_time_graph/` | Time-series graph data |
| Report | `/report/update_time_config/` | Update time range configuration |
| Report | `/report/get_config/` | Get report configuration |
| Report | `/report/export_job/trigger/` | Trigger a CSV export job |
| Report | `/report/get/` | Get report data |
| Report | `/report/update_selected_metric_config/` | Update selected metrics config |
| Top-up | `/topup/get_setting/` | Get top-up settings |
| Transaction | `/transaction_history/get/` | Get transaction history |
| Transaction | `/transaction_history/export_for_mcn/` | Export transaction history (MCN) |

---

## Local Storage

| Key | Type | Purpose | Used in |
|---|---|---|---|
| `MCN_CHART_METRICS` | `Array<MetricItemType>` | Persists the user's selected chart metrics across sessions | `src/pages/homepage/components/core-metrics/index.vue`, `src/pages/affiliateHomepage/components/core-metrics.vue`, `src/_shared/api/report/index.ts` |

---

## TMS Tracking

Tracking is implemented in `src/track/` using `triggerReport()` from `pas-common/utils`.

### Homepage — TMS tickets [#23941](https://trafficsuite.shopee.io/tms/tms_designer/ticket-center/23941), [#23960](https://trafficsuite.shopee.io/tms/tms_designer/ticket-center/23960)

| Function | Operation | Trigger | Parameters |
|---|---|---|---|
| `reportHomePageView` | VIEW | Page mount | `sourcePage` |
| `homePageTopSessionImpression` | IMPRESSION | Top section enters viewport | `sourcePage` |
| `homePageCreateAdsClick` | CLICK | "Create Ads" button | `sourcePage` |
| `homePageTopUpClick` | CLICK | "Top-up" button | `sourcePage` |

### Affiliate Homepage — TMS ticket [#23941](https://trafficsuite.shopee.io/tms/tms_designer/ticket-center/23941)

| Function | Operation | Trigger |
|---|---|---|
| `reportAffiliateHomePageView` | VIEW | Page mount |
| `affiliateHomePageTopSessionImpression` | IMPRESSION | Top section enters viewport |
| `affiliateHomePageCreateAdsClick` | CLICK | "Create Ads" button |

### Create Ads — TMS ticket [#23941](https://trafficsuite.shopee.io/tms/tms_designer/ticket-center/23941)

| Function | Operation | Trigger | Parameters |
|---|---|---|---|
| `reportCreateAdsView` | VIEW | Page mount | `preSourcePage` |
| `createAdsCancelClick` | CLICK | Cancel button | `preSourcePage` |
| `createAdsDiscardPopupImpression` | IMPRESSION | Discard-changes popup shown | `preSourcePage` |
| `createAdsDiscardPopupConfirmClick` | CLICK | Confirm discard | `preSourcePage` |
| `createAdsDiscardPopupCancelClick` | CLICK | Cancel discard | `preSourcePage` |
| `createAdsPublishClick` | CLICK | Publish button | `preSourcePage`, `biddingStrategy` |

### Top-up — TMS ticket [#23960](https://trafficsuite.shopee.io/tms/tms_designer/ticket-center/23960)

| Function | Operation | Trigger | Parameters |
|---|---|---|---|
| `reportTopUpView` | VIEW | Page mount | `preSourcePage` |
| `topUpCheckoutClick` | CLICK | Checkout button | `preSourcePage` |
| `topUpCancelClick` | CLICK | Cancel button | `preSourcePage` |

---

## Performance Monitoring

No application-level performance monitoring (Sentry, Grafana, web vitals) is configured in this codebase. "Performance" metrics in this module refer exclusively to ad campaign performance (GMV, ROAS, impressions, clicks) — not browser/runtime metrics.

---

## Business Terminology Glossary

| Term | Full Form | Definition |
|---|---|---|
| MCN | Multi-Channel Network | Organization that manages multiple affiliate creators and their ad campaigns |
| Affiliate | — | Individual content creator/influencer associated with an MCN |
| Live Stream Ad | — | Campaign format targeting viewers during a live-stream session |
| Ads GMV | Ads Gross Merchandise Value | Total sales value generated from ad clicks within 7 days |
| ROAS | Return on Ads Spending | Ads GMV / Ads Revenue — higher is better |
| ROI | Return on Investment | Ads GMV / Ad Expenditure |
| CIR | Cost-Income Ratio | Ads Revenue / Ads GMV — lower means cheaper ads |
| CPC | Cost Per Click | Amount spent per ad click |
| CTR | Click-Through Rate | Clicks / Impressions |
| CR | Conversion Rate | Ad orders / Clicks |
| eCPM | Effective Cost per Mille | Total Ad Spend / Total Impressions × 1,000 |
| SC | Seller Center | Platform where sellers manage ads, products, and shop settings |
| PDP | Product Detail Page | Individual product listing page |
| MMC | Multi-Module CLI | CLI tool for developing and building MMF modules |
| MMF | Multi-Module Framework | Shopee's micro-frontend runtime that composes portals from modules |
| TMS | Traffic Management System | Shopee's front-end analytics/tracking system |

---

## References

- **GitLab Repository**: https://git.garena.com/shopee/isfe/ao/pas-mcn
- **MMC Documentation**: https://seller-portal.i.test.shopee.io/mmc-docs/guide/getting-started.html
- **MMC Development Guide**: https://seller-portal.i.test.shopee.io/mmc-docs/guide/basic/development.html
- **Build & Release Guide**: https://seller-portal.i.test.shopee.io/docs/pages/seller-portal/build-and-release.html
- **TMS Ticket #23941**: https://trafficsuite.shopee.io/tms/tms_designer/ticket-center/23941
- **TMS Ticket #23960**: https://trafficsuite.shopee.io/tms/tms_designer/ticket-center/23960
- **Paid Ads Glossary**: https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPAD&title=Paid+Ads+Glossary

---

## Frequently Asked Questions

**1. How do I start local development for the first time?**

Run `yarn start`. This runs `mmc init` (which fetches remote config and installs dependencies) followed by `mmc dev`. After that, open `https://mcn.affiliate.test.shopee.co.id`, log in as `mcn_id.2 / 123456`, navigate to Shopee Ads, and run `window.proxy.mmfDevtools.enable()` in the browser console.

**2. Why do I see a blank page or the production version instead of my local code?**

MMF devtools needs to be enabled each session. Run `window.proxy.mmfDevtools.enable()` in the browser console and reload. Confirm you see `[MMF_DEVTOOLS]` and `[HMR] connected` logs.

**3. How do I add a new route?**

1. Add an entry to the `RouterMap` enum in `src/router/index.ts`.
2. Create the corresponding page component under `src/pages/`.
3. Add the route definition to the route array in the same file.
4. Optionally add a redirect from any legacy Seller Center path.

**4. How do I call a new API endpoint?**

1. Add the endpoint path to `src/_shared/constants/api.ts` under the appropriate namespace constant.
2. Create or extend the API function in the relevant `src/_shared/api/<domain>/index.ts`.
3. Define request/response types in the corresponding `types.ts` file.
4. Use the appropriate `BASE_PREFIX` enum value (`V1` for all standard MCN endpoints, `FREE` for the login endpoint at `/api/v2/pas/login/`) when constructing the full path.

**5. How do I add a new TMS tracking event?**

1. Add the page/section/target types to `src/track/types.ts` if needed.
2. Create the tracker function in the relevant `src/track/*Trackers.ts` file using `triggerReport()` from `pas-common/utils`.
3. Call the function from the corresponding page or component.

**6. Why is the module not available in my region?**

`pas-mcn` is whitelisted for `id` (Indonesia) and `vn` (Vietnam) only (`WhiteList` in `src/router/index.ts`). Access from other regions is not supported.

**7. How do I debug pas-common locally instead of using the CDN version?**

Start the `pas-common` dev server, then in `mmc.config.js` comment out the line `remoteAppHost = config.cdnPrefix`. Restart `yarn dev`.

**8. How does production deployment work?**

Push to `master` triggers `auto_deploy` in GitLab CI, which deploys to test and UAT. For production, trigger a build in the Seller Portal deploy platform (`https://seller-portal.i.shopee.io/`), then click **Publish** on the successful build to start a release job.

**9. How do I persist chart metric selections across page refreshes?**

The selected metrics are serialized and stored under the `MCN_CHART_METRICS` key in `localStorage`. The retrieval logic with fallback default is in `src/_shared/api/report/index.ts`.

**10. What is the difference between MCN Homepage and Affiliate Homepage?**

The MCN Homepage (`/portal/pas`) shows an aggregate view across all affiliates the MCN manages. The Affiliate Homepage (`/affiliate/:affiliateId`) is a scoped view for a specific affiliate's campaigns and performance data.

---

<!-- Generated by ads-workspace/skills/ads-readme-generate | checked: 69aa2e04ac9e5115a4c8c80b273049ef70cf2e78 | spec: 76fce5f679f9550b -->
