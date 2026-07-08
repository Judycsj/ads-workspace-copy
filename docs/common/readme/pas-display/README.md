<!-- ads-workspace-gdoc-sync: gdoc_id=1HDr6DYvYfJbaj0V61sWRzB2lk3Kykjt-OleTG52aDJU gdoc_url=https://docs.google.com/document/d/1HDr6DYvYfJbaj0V61sWRzB2lk3Kykjt-OleTG52aDJU/edit -->

# pas-display

> Display Ads, Search-Brand Ads, and Brand Consideration Ads management module for Shopee Ads Platform

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

`pas-display` is a Vue 3 + TypeScript micro-frontend module for Shopee Ads that manages Display Ads, Search-Brand Ads, and Brand Consideration Ads campaigns. It runs on both Seller Center (SC) and BD Centre (BDC), sharing components and utilities with other Paid Ads modules via `pas-common` through Webpack Module Federation.

---

## Key Features

- **Display Ads Creation & Management** — Full creation flow with reservation calendar, audience group targeting (including custom audience and audience expansion), creative upload (PC/RN/DD placements), billing option selection, and campaign detail view with admin message history
- **Display Ads Sunset Support** — Graceful sunset of Homepage Carousel (Display Ads) placement managed via `enableDisplayAdsSunset.displayAdsSunset` toggle; shows a sunset notice alert during the notice period (`displayAdsSunsetNoticePeriod`), and gates the Display Ads option when sunset is active
- **Search-Brand Ads Creation & Management** — Brand search ad creation with keyword management (grouped by core/alias/market/package/others), landing page selection, brand creative upload (image and video), estimated result forecasting, and premium benefits display
- **Brand Consideration Ads** — Consideration campaign creation/editing with audience movement analytics, multi-placement creative management (Pop-up, Daily Discovery, Skinny Banner, Floating Widget, Homepage Carousel Banner, Homepage Carousel Skinny, DD Shopee Mall Card, DD Banner Mall Card, Mall Page Banner, Mall Category Page Banner, Category Page Banner), DD Shopee Mall Card edit-time re-upload validation, max budget fetching, and Malaysia (MY) region-specific i18n text for upload deadline notice, submit prompt tips, and admin message banners (creative missing title, creative reject content) via `getBrandMaxTransifyKey()` in `src/_shared/utils/brand-max-transify.ts`
- **Brand Max Ad Type Selector** — When the `szAdsBrandConsideration` feature toggle or Display Ads sunset is active, the creation entry page switches from a radio-button group to a tab-card UI, presenting Brand Max (Consideration) and Search Brand as the available ad types
- **Performance Metrics & Reporting** — Time-range-based metric charts (ECharts) with configurable metrics, report config persistence, audience movement data, accessible from detail pages for all ad types
- **Budget & Bid Management** — Budget validation driven by Constantine configuration, budget-adjust toast notifications, consideration campaign max budget fetching, suggested daily budget for search-brand ads
- **Product Selection** — Product query and selection UI with category/search/recommend filtering for Search-Brand ad creation
- **Creative Assets Management** — Dedicated upload components for brand images and videos, live/app/PC preview components, creative guidelines, video frame extraction, and multi-banner management (up to 4 banners)
- **Multi-Platform Support** — Adapts UI and routing for both Seller Center and BD Centre portals, with SecureFetch anti-bot protection on SC and BD-specific breadcrumb handling

---

## Project Architecture

`pas-display` follows the **Multi-Module Framework (MMC)** architecture:

```
Seller Center / BD Centre (Host Portal)
       │
       └── pas-display (MMC Module, id: 129, type: module, tech: vue3)
               │
               ├── Module Federation Consumer
               │       └── pas-common (shared utilities, components, types)
               │
               ├── Vue 3 Router (registered via app.registerRouterModule)
               │       ├── /portal/marketing/pas/display  (Display Ads)
               │       └── /portal/marketing/pas/brand    (Search-Brand / Consideration Ads)
               │
               └── Global Stores (Vue reactive)
                       ├── Constantine (business configuration from backend)
                       └── Meta (feature toggle flags: extToggle, adsToggle)
```

**State Management:**

State is managed with plain Vue reactive objects (no Pinia/Vuex):

- `src/_shared/store/constantine.ts` — reactive singleton holding the full `Config` object fetched from `/config/get/`; provides budget limits, creative dimension constraints, currency precision, and ad-type-specific settings (`displayAds`, `searchBrandAds`, `brandConsiderationAds`)
- `src/_shared/store/meta.ts` — two reactive stores:
  - `metaNonAdsDataStore` — holds `extToggle` (feature flags like `szAdsBrandConsideration`, `szAdsSearchBrandAds`) and `userShop`
  - `adsMetaDataStore` — holds `adsToggle` (flags like `displayAds`, `enableDisplayAdsSunset { displayAdsSunset, displayAdsSunsetNoticePeriod, sunsetDate }`, `brandAdsPackage`) and `brandAdsPackage`
- `src/_shared/store/page-status/` — page-level ephemeral state (estimated results, selected time range, metric selections, report load status)

**Router Setup:**

Routes are registered in `src/_shared/router/index.ts` via `app.registerRouterModule`. All routes share a `beforeEnter` guard that pre-fetches Constantine, AdsMeta, and MetaNonAdsData before any page renders.

| Route | Component | Description |
|---|---|---|
| `/portal/marketing/pas/display` | `pages/index.vue` | Display Ads list/index |
| `/portal/marketing/pas/display/create` | `pages/create/display-ads/index.vue` | Display Ads creation |
| `/portal/marketing/pas/display/edit/:campaignId` | `pages/create/display-ads/index.vue` | Display Ads edit |
| `/portal/marketing/pas/display/detail/:campaignId` | `pages/detail/display-ads/index.vue` | Display Ads detail |
| `/portal/marketing/pas/brand` | `pages/index.vue` | Brand Ads list/index |
| `/portal/marketing/pas/brand/create` | `pages/create/index.vue` | Search-Brand / Consideration creation |
| `/portal/marketing/pas/brand/search-brand-edit/:campaignId` | `pages/create/index.vue` | Search-Brand edit |
| `/portal/marketing/pas/brand/detail/:campaignId` | `pages/detail/search-brand/index.vue` | Search-Brand detail |
| `/portal/marketing/pas/brand/consideration-edit/:campaignId` | `pages/create/index.vue` | Consideration edit |
| `/portal/marketing/pas/brand/consideration-detail/:campaignId` | `pages/detail/brand-consideration/index.vue` | Consideration detail |

**Data Flow:**
1. Route guard (`beforeEnter`) pre-fetches `Constantine`, `AdsMeta`, and `MetaNonAdsData` stores in parallel before any page renders.
2. Pages read configuration from `Constantine` store (budget limits, creative dimension constraints, etc.).
3. Feature toggles are read from `metaNonAdsDataStore.extToggle` and `adsMetaDataStore.adsToggle`.
4. `enableDisplayAdsSunset` nested toggle in `adsToggle` controls Display Ads sunset behavior: `displayAdsSunset` gates the Display Ads creation option; `displayAdsSunsetNoticePeriod` shows a sunset notice alert on the creation page.
5. When `szAdsBrandConsideration` is true (or `enableDisplayAdsSunset.displayAdsSunset` is true), the brand creation entry (`pages/create/index.vue`) renders a tab-card selector instead of a radio-button group, exposing only Brand Consideration and Search Brand ad types.
6. API responses use `BASE_PREFIX.V1` (`/api/pas/v1`) or `BASE_PREFIX.V3` (`/api/marketing/v3/pas`).
7. Numeric values from the backend are inflated by 10^5 and must be converted using `convertServerNumber` / `convertClientNumber` from `pas-common/utils`.

**Notable Patterns:**
- **Lazy loading** — all page components are loaded via MMC's code-splitting; the module entry `src/index.ts` only registers the router
- **Module Federation** — `pas-common` is consumed as a remote module; `eds-vue` is explicitly excluded from shared config in `mmc.config.js` so each module bundles its own version (5.0.40 for `pas-display`)
- **Rsbuild support** — `mmc.config.js` provides both webpack and rspack (rsbuild) configurations; rsbuild is used in dev mode for faster HMR

---

## Directory Structure

```
pas-display/
├── mmc.config.js                    # MMC module configuration (id: 129, vue3)
├── package.json
├── src/
│   ├── index.ts                     # Entry point – imports router registration
│   ├── custom.d.ts                  # Custom type declarations
│   ├── polyfill/
│   │   └── _polyfill-event-bus.ts   # Vue 3 $on/$off/$emit polyfill (WeakMap-based)
│   ├── track/
│   │   ├── index.ts                 # Re-exports all tracking functions from pas-common
│   │   └── types.ts                 # Tracking types (ProductSelectionMap)
│   ├── _shared/
│   │   ├── api/
│   │   │   ├── base.ts              # BASE_PREFIX enum (V1, V3)
│   │   │   ├── common/              # Calendar info, active items check, shop data, event reporting
│   │   │   ├── create-page/         # Display Ads creation API (billing, estimates, audience groups)
│   │   │   │   └── brand/           # Search-Brand / Consideration creation API (keywords, budget, creatives)
│   │   │   ├── detail-page/         # Display Ads detail API (creatives, messages, reports)
│   │   │   │   ├── brand/           # Search-Brand detail API (edit, permissions, banners)
│   │   │   │   └── consideration/   # Brand Consideration detail API (edit, banners)
│   │   │   ├── meta/                # Config (Constantine) + Meta (toggles) API + type definitions
│   │   │   ├── product-selector/    # Product query & list-by-item-id API
│   │   │   ├── report/              # Time-series metrics, report config, audience movement API
│   │   │   └── request/             # commonRequest factory + SecureFetch + captcha handling
│   │   ├── components/
│   │   │   ├── back-button/         # Back navigation
│   │   │   ├── brand-creative-preview/  # App / Live / PC preview tabs + preview prompt
│   │   │   ├── brand-cratives-guideline/ # Brand creatives guideline
│   │   │   ├── brand-creatives-uploader/# Brand image uploader
│   │   │   ├── budget-adjust-toast/ # Budget change notification toast
│   │   │   ├── cascader/            # Custom cascader component
│   │   │   ├── creatives-guideline/ # Creative spec guidelines display
│   │   │   ├── creatives-preview/   # Display Ads creative preview
│   │   │   ├── date-range-picker/   # Custom date range picker
│   │   │   ├── DateRangePicker/     # Legacy date picker (date-picker subpackage)
│   │   │   ├── keywords-content/    # Keyword list display
│   │   │   ├── landing-page/        # Landing page selector
│   │   │   ├── location-preview/    # Location targeting preview
│   │   │   ├── metric-chart/        # ECharts-based line metric chart + metric items
│   │   │   ├── navs/                # Navigation component
│   │   │   ├── product-selection/   # Product selection UI with tab selection
│   │   │   ├── reserved-keywords-preview/ # Reserved keyword preview
│   │   │   ├── simple-modal/        # Generic modal wrapper
│   │   │   ├── video-creatives-uploader/  # Video creative uploader
│   │   │   └── video-preview/       # Video preview component
│   │   ├── composables/
│   │   │   ├── useBrandEstimatedResult.ts # Estimated result text formatting (exports useSearchBrandEstimatedTexts)
│   │   │   ├── useBudgetConfig.ts         # Budget config from Constantine (min daily budget, input step)
│   │   │   ├── useConsiderationBudget.ts  # Max budget for Consideration Ads
│   │   │   ├── useCreativesEditing.ts     # Multi-banner creative editing state (up to 4 banners)
│   │   │   ├── useDuration.ts             # Report date range & time config sync
│   │   │   ├── useKeywords.ts             # Keyword fetching and grouping
│   │   │   ├── useSelectMetrics.ts        # Metric selection and persistence for reports
│   │   │   ├── useTable.ts                # Report table data loading and sorting
│   │   │   └── useVue.ts                  # useRoute / useRouter / useVueInstance helpers
│   │   ├── constants/
│   │   │   ├── api.ts               # All API endpoint paths
│   │   │   ├── campaign.ts          # CampaignStates / PaymentStates enums
│   │   │   ├── CDN.ts               # CDN host, guideline/preview image paths
│   │   │   ├── index.ts             # ToggleInfo enum, re-exports campaign constants
│   │   │   ├── keyword.ts           # KeywordTabType, KeywordGroupName, group translation maps
│   │   │   ├── message.ts           # AdminMessageType enum, MessageMap
│   │   │   ├── metric-field.ts      # Metric definitions & dashboard configs (default/brand/consideration)
│   │   │   ├── placement.ts         # DISPLAY_ADS_PLACEMENT = 9
│   │   │   ├── region.ts            # Region types, domain suffixes, timezone areas, RegionCode enum
│   │   │   ├── router.ts            # RouterMap enum + RouterPath + performance marks & measurement
│   │   │   └── time.ts              # TimeRanges enum, ONE_DAY, DatePickerListItem types
│   │   ├── router/
│   │   │   └── index.ts             # Route registration (Display + Brand paths), page session ID
│   │   ├── store/
│   │   │   ├── constantine.ts       # Business config reactive store
│   │   │   ├── meta.ts              # Feature toggle reactive store (metaNonAdsDataStore + adsMetaDataStore)
│   │   │   └── page-status/         # Page-level state (estimated results, time range, metrics, report status)
│   │   ├── styles/
│   │   │   ├── constants.scss       # SCSS variables (auto-injected)
│   │   │   └── index.scss           # Global styles (auto-injected)
│   │   ├── types/
│   │   │   ├── index.ts             # PlainType, SummaryDate, ReportLoadStatus enum
│   │   │   └── metric-item.ts       # MetricSourceItem, ReportMetricItem type extensions
│   │   └── utils/
│   │       ├── brand-max-transify.ts # Region-aware transify key selector for Brand Max Ads — getBrandMaxTransifyKey(keyType) returns MY-specific keys (suffixed _my) for Malaysia region, default keys otherwise; covers UPLOAD_DEADLINE, SUBMIT_PROMPT_NOTE_TIPS_2, CREATIVE_MISSING_MSG_TITLE, REJECT_NOTE_BANNER_CONTENT
│   │       ├── constantine.ts       # getCurrencyPrecision / getCpmCurrencyPrecision / getCpcCurrencyPrecision
│   │       ├── creative-initialization.ts # Creative item + validation initialization helpers
│   │       ├── domain.ts            # Domain validation and name helpers
│   │       ├── duration.ts          # getTimeRange wrapper for report date ranges
│   │       ├── eventBus.ts          # mitt-based global event bus
│   │       ├── formatter/
│   │       │   ├── currency/        # localFormatCurrency, getCurrency, currencySymbol
│   │       │   ├── date/            # createDate, getDate, customFormatDate, timestamp converters
│   │       │   ├── number/          # formatNumber, formatNumberLocalized
│   │       │   └── percentage/      # formatPercentage
│   │       ├── index.ts             # addFilePrefix, removeFilePrefix, textCapitalize, formatRange, formatMsToMinSec
│   │       ├── timezone.ts          # Shop/browser time offset conversion, displayDateRange
│   │       └── type-guards.ts       # isString, isNumber, isObject, isPlainObject, isFunction, isBoolean
│   └── pages/
│       ├── index.vue                # Shared root page (Display & Brand index)
│       ├── create/
│       │   ├── index.vue            # Brand Ads creation entry (tab-card for Brand Max / Search Brand / Display)
│       │   ├── type.ts              # CreativeListItem, FormInstance types
│       │   ├── composables/
│       │   │   └── useBrandFormData.ts  # Brand consideration edit form data loading
│       │   ├── display-ads/         # Display Ads creation page + modals
│       │   │   ├── modals/          # audience-type, confirm, creation-form, custom-audience,
│       │   │   │                    # reservation, result-card, time-length, user-guide
│       │   │   ├── mixins/          # BillingBehaviour mixin
│       │   │   ├── constants.ts     # showResult, creation form constants
│       │   │   └── types.ts         # Display ads creation types
│       │   ├── search-brand/        # Search-Brand Ads creation page + components
│       │   │   ├── components/      # brand-budget-setting, creatives-setting, estimated-result,
│       │   │   │                    # premium-benefits, modals (publish-status)
│       │   │   └── constants.ts     # Validation, creative transforms, admin message mapping
│       │   └── components/          # Shared creation components
│       │       ├── consideration-basic-form/  # Consideration ad name, duration, budget form
│       │       ├── consideration-creative/    # Per-placement creative upload (app + PC)
│       │       ├── consideration-preview/
│       │       ├── consideration-preview-prompt/
│       │       ├── consideration-date-picker.vue
│       │       ├── creatives-uploader/
│       │       ├── estimate-result/
│       │       ├── preview-empty/
│       │       ├── constants.ts     # Placement-to-banner mapping, creative config helpers
│       │       └── type.ts          # EstimatedResultItem, SelectDateRange
│       └── detail/
│           ├── display-ads/         # Display Ads detail page
│           │   ├── modals/          # ad-creatives, basic-info, creatives-upload,
│           │   │                    # message-history, skeleton, steps
│           │   ├── constant.ts      # Chart metrics, audience type maps
│           │   ├── types.ts         # Detail page types
│           │   └── utils.ts         # Detail page utilities
│           ├── search-brand/        # Search-Brand Ads detail page
│           │   ├── components/      # banner, creatives (edit/view/video/admin-message),
│           │   │                    # detail-header, message-history, reserved-keywords
│           │   └── constants.ts     # Metrics, banner config, creative validators
│           └── brand-consideration/ # Brand Consideration Ads detail page
│               ├── components/
│               │   ├── audience-movement/  # Summary card, step container
│               │   ├── banner/
│               │   ├── creatives/          # Creative item view
│               │   ├── detail-header/
│               │   └── performance-detail-table/
│               └── constants.ts     # Consideration metrics, campaign editability
```

---

## Quick Start

### Prerequisites

| Requirement | Version |
|---|---|
| Node.js | ≥ 16.14.0 (Node 20 recommended) |
| Yarn | Any (used as project package manager) |
| pnpm | ≥ 8.0.0 (required to install MMC) |
| MMC (`@shopee/multi-module-cli`) | V3.x (use branch `zangse/ads-mmc-master-v2-rebase` for this project) |
| Python | 3.10 (required by MMC native dependencies) |

Install MMC globally:

```bash
pnpm i -g @shopee/multi-module-cli
mmc setup
mmc -V  # should display 4 versions (mmc-core, mmc-vue, mmc-react, mmc-vue3)
```

> **Note**: The npm registry must be set to `https://npm.shopee.io/`.

### Configuration

The module ID and portal binding are defined in `mmc.config.js`:

```js
module.exports = {
  id: 129,       // Module ID registered in Seller Portal
  type: "module",
  tech: "vue3",
  // ...
};
```

Router parameters and portal binding are stored in `config/.remote-config.json` (auto-generated by `yarn run init`, **do not commit manually**).

SCSS variables are auto-injected from:
- `src/_shared/styles/constants.scss`
- `src/_shared/styles/index.scss`

### Installation

Run **once** before your first development session (or when dependencies change):

```bash
# Install for Seller Center (portal ID 21)
yarn run init -p 21

# Install for BD Centre (portal ID 17)
yarn run init -p 17
```

> `yarn run init` installs dependencies and pulls remote config from Seller Portal. It overwrites `.browserslistrc`, `.stylelintrc.json`, and `tsconfig.json`.

### Build

Local build (for inspection, not for production):

```bash
yarn build
# or
mmc build
```

Production builds are triggered via [Seller Portal](https://seller-portal.i.shopee.io/) (see [Deployment](#deployment)).

### Local Development

There are two modes for consuming `pas-common`:

#### Local mode (default `yarn dev`)

Requires a running `pas-common` local dev server (port 8001). Start `pas-common` dev server first, then:

```bash
yarn dev
```

If `pas-common` is not running locally, you will see:
```
<e> [FederatedTypesPlugin] Unable to download 'pas-common' remote types index file: connect ECONNREFUSED 127.0.0.1:8001
```

#### Remote mode

Use the published `master` branch types from the remote CDN without needing a local `pas-common`:

```bash
yarn dev:remote
```

Use a specific `pas-common` branch:

```bash
yarn dev -b {feature-branch-name}
```

Additional scripts:

| Script | Purpose |
|---|---|
| `yarn dev:webstorm` | Start dev with WebStorm editor integration |
| `yarn start` | Init with SC portal (id 21) then start remote dev |
| `yarn inspect` | Inspect webpack/rspack configuration |
| `yarn lint` | Run ESLint + Stylelint |
| `yarn lint:es:fix` | Auto-fix ESLint issues |
| `yarn lint:style:fix` | Auto-fix Stylelint issues |
| `yarn type:check` | Run vue-tsc type checking |

### Development

After starting the dev server:

1. Navigate to the test environment of your selected portal:
   - **Seller Center**: [https://seller.test.shopee.sg](https://seller.test.shopee.sg) — use the [Pas Helper Chrome extension](https://confluence.shopee.io/pages/viewpage.action?pageId=1776244098) for one-click login
   - **BD Centre**: [https://bd-centre.test.shopee.com/ads-crm/shop](https://bd-centre.test.shopee.com/ads-crm/shop) — find a shop by ID and navigate to a display ad

2. Open browser DevTools and connect the local dev server:
   - Click **MMF DevTools** icon → **Connect to Dev Server**
   - Or run in console: `mmfDevtools.enable()`

3. Reload the page — the portal loads resources from your local dev server. You will see `[MMF_DEVTOOLS]` and `[HMR] connected` in the console.

### Deployment

Production build and release are managed via [Seller Portal](https://seller-portal.i.shopee.io/):

1. **Build**: Select the module group for `pas-display`, fill in build information, and click **Build**.
2. **Release**: After a successful build, click **Publish** on the build record row and fill in the release form (portal, PFB, regions).
3. **Offline**: Toggle **Offline Mode** before building to take the module offline after release.

For CI deployment:

```bash
yarn deploy:ci   # release-bot automated release
yarn deploy      # release-bot with auto-branch (-a) and master branch (-b master)
```

**CI/CD Pipeline** (`.gitlab-ci.yml`):

The GitLab CI pipeline runs on `harbor.shopeemobile.com/seller-center/multi-cli-tool-v3` and has the following stages:

| Stage | Job | Trigger | Description |
|---|---|---|---|
| `lint` | `lint_sc` | Merge Request | Init with SC portal (id 21), then `yarn lint` |
| `lint` | `lint_bd` | Merge Request | Init with BD portal (id 17), then `yarn lint` |
| `parallel_jobs` | `ai-code-review` | Merge Request | Automated AI code review (from `pas-tech/node-tools` template) |
| `release_verify` | `release_verify` | Merge Request | Verifies release via deploy-platform API |
| `auto_deploy` | `auto_deploy` | Push to `master` | Auto-deploys to `test` and `uat` environments via `yarn deploy` |

---

## API Documentation

All API endpoints are defined in `src/_shared/constants/api.ts`. Requests are made through `commonRequest` in `src/_shared/api/request/index.ts`, which wraps `pas-common`'s `createRequest` with:

- Automatic error handling (shows toast for rate-limit errors, code 7)
- Default `skipError: true` (pas-display-specific default)
- SecureFetch anti-bot protection (Seller Center only, disabled for BD users)
- Captcha modal handling via `bindCaptchaEvent()`

**API Base Prefixes** (`src/_shared/api/base.ts`):

| Prefix | Path |
|---|---|
| `BASE_PREFIX.V1` | `/api/pas/v1` |
| `BASE_PREFIX.V3` | `/api/marketing/v3/pas` |

| Page | Page URL | API Endpoint | Description |
|---|---|---|---|
| Config & Meta | All pages (beforeEnter) | `/config/get/` | Fetch Constantine business configuration |
| Config & Meta | All pages (beforeEnter) | `/meta/get/` | Fetch ads meta data (adsToggle, brandAdsPackage) |
| Config & Meta | All pages (beforeEnter) | `/meta/get_non_ads_data/` | Fetch non-ads meta data (extToggle, userShop) |
| Display Ads Creation | `/portal/marketing/pas/display/create` | `/display/create/` | Create a display ad campaign |
| Display Ads Creation | `/portal/marketing/pas/display/create` | `/display/get_calendar_info/` | Get reservation calendar info with audience expansion |
| Display Ads Creation | `/portal/marketing/pas/display/create` | `/display/get_estimated_result/` | Get estimated result for display ad |
| Display Ads Creation | `/portal/marketing/pas/display/create` | `/display/list_billing_option/` | List available billing options |
| Display Ads Creation | `/portal/marketing/pas/display/create` | `/display/list_audience_group/` | List audience groups for targeting |
| Display Ads Edit | `/portal/marketing/pas/display/edit/:campaignId` | `/display/edit/` | Edit an existing display ad campaign |
| Display Ads Detail | `/portal/marketing/pas/display/detail/:campaignId` | `/display/get_single_detail/` | Get display ad campaign detail |
| Display Ads Detail | `/portal/marketing/pas/display/detail/:campaignId` | `/display/upload_creative/` | Upload creative file for display ad |
| Display Ads Detail | `/portal/marketing/pas/display/detail/:campaignId` | `/display/update_creative/` | Update creative for display ad |
| Display Ads Detail | `/portal/marketing/pas/display/detail/:campaignId` | `/display/cancel/` | Cancel a display ad campaign |
| Display Ads Detail | `/portal/marketing/pas/display/detail/:campaignId` | `/display/list_admin_message/` | Get admin message history |
| Display Ads Detail | `/portal/marketing/pas/display/detail/:campaignId` | `/display/close_admin_message/` | Close/dismiss an admin message |
| Search-Brand Creation | `/portal/marketing/pas/brand/create` | `/search_brand/create/` | Create a search-brand ad campaign |
| Search-Brand Creation | `/portal/marketing/pas/brand/create` | `/search_brand/get_estimated_result/` | Get estimated results for search-brand ad |
| Search-Brand Creation | `/portal/marketing/pas/brand/create` | `/search_brand/get_suggest_budget/` | Get suggested daily budget |
| Search-Brand Creation | `/portal/marketing/pas/brand/create` | `/search_brand/product_query/` | Query products for selection |
| Search-Brand Creation | `/portal/marketing/pas/brand/create` | `/search_brand/product_list_by_item_id/` | List products by item IDs |
| Search-Brand Creation | `/portal/marketing/pas/brand/create` | `/brand_ads/list_grouped_keyword/` | List grouped keywords (core/alias/market/package/others) |
| Search-Brand Creation | `/portal/marketing/pas/brand/create` | `/brand_ads/list_reserved_keyword/` | List reserved keywords |
| Search-Brand Creation | `/portal/marketing/pas/brand/create` | `/creative/upload/` | Upload brand creative image |
| Search-Brand Creation | `/portal/marketing/pas/brand/create` | `/brand_ads/get_video_meta/` | Extract video frame metadata |
| Search-Brand Edit | `/portal/marketing/pas/brand/search-brand-edit/:campaignId` | `/search_brand/batch_edit/` | Batch edit search-brand ad |
| Search-Brand Detail | `/portal/marketing/pas/brand/detail/:campaignId` | `/search_brand/get_single_detail/` | Get search-brand ad detail |
| Search-Brand Detail | `/portal/marketing/pas/brand/detail/:campaignId` | `/search_brand/edit/` | Edit search-brand ad (from detail page) |
| Search-Brand Detail | `/portal/marketing/pas/brand/detail/:campaignId` | `/search_brand/is_updatable/` | Check if search-brand ad can be updated |
| Search-Brand Detail | `/portal/marketing/pas/brand/detail/:campaignId` | `/search_brand/list_admin_message/` | Get search-brand admin messages |
| Search-Brand Detail | `/portal/marketing/pas/brand/detail/:campaignId` | `/search_brand/close_admin_message/` | Close search-brand admin message |
| Search-Brand Detail | `/portal/marketing/pas/brand/detail/:campaignId` | `/search_brand/event_report/` | Report search-brand event |
| Search-Brand Detail | `/portal/marketing/pas/brand/detail/:campaignId` | `/search_brand/event_get/` | Get search-brand event data |
| Consideration Creation | `/portal/marketing/pas/brand/create` | `/brand_consideration/create/` | Create brand consideration campaign |
| Consideration Creation | `/portal/marketing/pas/brand/create` | `/brand_consideration/get_calendar_info/` | Get consideration reservation calendar |
| Consideration Creation | `/portal/marketing/pas/brand/create` | `/brand_consideration/get_max_budget/` | Get max budget for consideration campaign |
| Consideration Creation | `/portal/marketing/pas/brand/create` | `/brand_consideration/get_estimated_and_booking/` | Get estimated results and booking info |
| Consideration Edit | `/portal/marketing/pas/brand/consideration-edit/:campaignId` | `/brand_consideration/edit/` | Edit brand consideration campaign |
| Consideration Detail | `/portal/marketing/pas/brand/consideration-detail/:campaignId` | `/brand_consideration/get_single_detail/` | Get brand consideration detail |
| Consideration Detail | `/portal/marketing/pas/brand/consideration-detail/:campaignId` | `/brand_consideration/close_admin_message/` | Close consideration admin message |
| Report (all detail pages) | Detail pages | `/report/get/` | Get report data with metrics |
| Report (all detail pages) | Detail pages | `/report/get_time_graph/` | Get time-series graph data |
| Report (all detail pages) | Detail pages | `/report/get_config/` | Get saved report configuration |
| Report (all detail pages) | Detail pages | `/report/update_time_config/` | Update time range config |
| Report (all detail pages) | Detail pages | `/report/update_selected_metric_config/` | Update selected metric config |
| Report (all detail pages) | Detail pages | `/report/get_audience/` | Get audience movement data |
| Common | Multiple pages | `/shop/check_has_enough_active_item/` | Check if shop has enough active items |
| Common | Multiple pages | `/shop/get_preview_data/` | Get shop preview data |

**Number Conversion:**
Backend inflates numbers by 10^5. Always convert:
```typescript
import { convertServerNumber, convertClientNumber } from "pas-common/utils";
// API response → UI
item.budget = convertServerNumber(item.budget);
// UI → API request
payload.dailyBudget = convertClientNumber(payload.dailyBudget);
```

---

## Local Storage

| Key | Value | Purpose |
|---|---|---|
| `SELLER_CENTER_SHOPEE_ADS_PAGE_SESSION_ID` | UUID string | Page session ID, regenerated on every route path change. Used to correlate tracking events within the same page session for analytics. |

The page session ID is managed in `src/_shared/router/index.ts`. On each route change (where the path differs from the previous route), a new UUID is generated via `uuid.v4()` and stored in `localStorage`. If the path has not changed (e.g., form submission or data refresh), the session ID is preserved.

---

## TMS Tracking

All tracking functions are re-exported from `pas-common` tracking entries in `src/track/index.ts`. Never import directly from `pas-common/tracking/entries/`; always import from `src/track`:

```typescript
import { reportClickOfBrandAdsDtlPerf } from "src/track";
```

**Tracking entry sources:**

| Tracking Entry | Description |
|---|---|
| `sellerCenterCreateDisplayAds` | Display Ads creation (SC) |
| `sellerCenterEditDisplayAds` | Display Ads editing (SC) |
| `sellerCenterDisplayAdDetail` | Display Ads detail (SC) |
| `createDisplayAds` | Display Ads creation events |
| `createBrandAds` | Search-Brand Ads creation events (cancel, publish, video toggle, upload, keyword edit) |
| `brandAdsDetail` | Search-Brand Ads detail events (creative template, banners, perf, video) |
| `sellerCenterCreateBrandAds` | Search-Brand Ads creation view (SC) |
| `editBrandMaxAds` | Brand Max Ads editing events (view, cancel, publish) |
| `brandMaxAdsDetail` | Brand Max Ads detail events (view, perf, status change, business insight) |

---

## Performance Monitoring

`pas-display` uses the **Web Performance API** (`performance.mark` / `performance.measure`) to measure page load times. Marks and measurement utilities are defined in `src/_shared/constants/router.ts`.

**Performance Marks:**

| Constant | Mark Name | Purpose |
|---|---|---|
| `PERFORMANCE_MARK_INDEX_ENTER` | `pas_brand_ads_index_enter` | Module index route entered |
| `PERFORMANCE_MARK_CREATE_ENTER` | `pas_brand_ads_create_enter` | Create page route entered |
| `PERFORMANCE_MARK_DETAIL_ENTER` | `pas_brand_ads_detail_enter` | Detail page route entered |
| `PERFORMANCE_MARK_CONSIDERATION_DETAIL_ENTER` | `pas_brand_ads_consideration_detail_enter` | Consideration detail route entered |
| `PERFORMANCE_MARK_CREATE_MOUNTED` | `pas_brand_ads_create_mounted` | Create page component mounted |
| `PERFORMANCE_MARK_DETAIL_MOUNTED` | `pas_brand_ads_detail_mounted` | Detail page component mounted |
| `PERFORMANCE_MARK_CONSIDERATION_DETAIL_MOUNTED` | `pas_brand_ads_consideration_detail_mounted` | Consideration detail component mounted |

**Measurement Utilities:**

```typescript
import {
  generateDetailPerformanceData,
  generateCreatePerformanceData,
  generateConsiderationDetailPerformanceData,
} from "src/_shared/constants/router";

// Call in the mounted() hook of the relevant page
const perfData = generateDetailPerformanceData();
// Returns: { moduleToEnter, enterToMounted, moduleToMounted } in milliseconds
```

Marks are set in `beforeEnter` router guards and cleared when the module navigates away from the Display/Brand module paths (reset logic in `src/_shared/router/index.ts`).

---

## Business Terminology Glossary

| Term | Definition |
|---|---|
| **Display Ads** | Reservation-based banner ads shown in high-traffic placements (Daily Discovery, RN, PC) |
| **Search-Brand Ads (SBA)** | Brand search ads that appear at the top of search results for reserved keywords |
| **Brand Consideration Ads** | Awareness-focused ads targeting audience segments with Pop-up, Daily Discovery, Skinny Banner, Floating Widget, Homepage Carousel, and Mall Page placements |
| **Brand Max** | A search-brand ads package type with premium features and higher budget tiers |
| **Constantine** | Backend business-config service; values fetched at runtime into the `Constantine` reactive store |
| **MetaNonAdsData / AdsMeta** | Feature toggle stores (`extToggle`, `adsToggle`, `brandAdsPackage`) |
| **Display Ads Sunset** | Feature controlled by `enableDisplayAdsSunset` toggle; gracefully deprecates the Homepage Carousel (Display Ads) placement with a notice period before full sunset |
| **CPM** | Cost Per Mille — cost to advertiser per 1,000 impressions |
| **CPC** | Cost Per Click — amount spent per click |
| **CIR** | Cost-Income-Ratio = Ads Revenue / Ads GMV |
| **ROI / ROAS** | Return on Investment / Return on Ads Spending = Ads GMV / Ads Revenue |
| **CTR** | Click-Through Rate = Clicks / Impressions |
| **CR** | Conversion Rate = Ad Orders / Clicks |
| **ECPM** | Effective Cost per Mille = Total Ad Spend / Total Impressions |
| **Impression** | A single view of an ad |
| **GMV** | Gross Merchandise Value — total sales attributed to ads within the attribution window (7 days) |
| **Daily Discovery (DD)** | Banner ad placement on Shopee app home feed; creative dimensions: 531×792 px |
| **RN (React Native)** | Mobile banner placement; creative dimensions: 1200×640 px |
| **PC Creative** | Desktop banner placement; creative dimensions: 1200×360 px |
| **Skinny Banner** | Wide and short banner; creative dimensions: 1200×110 px (PC) / 1200×360 px (App) |
| **Floating Widget** | Small floating creative; dimensions: 360×360 px |
| **Pop-up** | Full-screen pop-up creative; dimensions: 580×720 px |
| **BDC / BD Centre** | BD Centre — internal CRM platform for relationship managers to manage large advertiser accounts |
| **SC / Seller Center** | Platform where sellers manage their ads and listings |
| **QSS** | QuickStart Service — onboarding program to help new advertisers ramp up quickly |
| **CampaignStates** | Possible ad states: `scheduled`, `ongoing`, `paused`, `ended`, `banned`, `cancelled`, `creative_missing`, `creative_reviewing`, `creative_rejected`, `temp_reserved`, `unknown` |
| **Page Session ID** | UUID stored in `localStorage` under key `SELLER_CENTER_SHOPEE_ADS_PAGE_SESSION_ID`, regenerated on each route change |
| **Take-Rate** | Ads Revenue / Platform GMV — measures how effectively Shopee monetises its platform |
| **Ads Order** | An order counted when a user purchases within 7 days after clicking a related ad |

---

## References

- [pas-display GitLab Repository](https://git.garena.com/shopee/isfe/ao/pas-display)
- [pas-common GitLab Repository](https://git.garena.com/shopee/isfe/ao/pas-common)
- [MMC Documentation](https://seller-portal.i.test.shopee.io/mmc-docs/guide/getting-started.html)
- [MMC Development Guide](https://seller-portal.i.test.shopee.io/mmc-docs/guide/basic/development.html)
- [MMC Initialization Guide](https://seller-portal.i.test.shopee.io/mmc-docs/guide/basic/initialization.html)
- [Seller Portal Build & Release](https://seller-portal.i.test.shopee.io/docs/pages/seller-portal/build-and-release.html)
- [Paid Ads Glossary (Confluence)](https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPAD&title=Paid+Ads+Glossary)
- [Pas Helper Chrome Extension](https://confluence.shopee.io/pages/viewpage.action?pageId=1776244098)
- [BD Centre Shop List](https://bd-centre.test.shopee.com/ads-crm/shop?type=all)
- [Seller Portal (Production)](https://seller-portal.i.shopee.io/)

---

## Frequently Asked Questions

**1. Why does `yarn dev` fail with `ECONNREFUSED 127.0.0.1:8001`?**

The default `yarn dev` command runs in local mode and expects a `pas-common` dev server running on port 8001. Either start the `pas-common` dev server first, or use `yarn dev:remote` to load types from the remote master branch instead.

**2. What is the difference between `yarn dev` and `yarn dev:remote`?**

`yarn dev` (local mode) fetches `pas-common` types from a locally running `pas-common` dev server (port 8001), which is required when you are also making changes to `pas-common`. `yarn dev:remote` fetches published types from the remote `master` branch CDN — no local `pas-common` server needed. Use `yarn dev -b {branch-name}` to target a specific remote branch.

**3. Do I need to run `yarn run init` every time before `yarn dev`?**

No. Run `yarn run init` only once (or when dependencies or the portal configuration change). This command installs dependencies and pulls portal configuration from Seller Portal. After that, `yarn dev` is sufficient for daily development.

**4. How do I access my local dev server from the Seller Center browser page?**

After running `yarn dev`, go to the Seller Center or BD Centre test environment, open browser DevTools, and run `mmfDevtools.enable()` in the console. Then reload the page. You will see `[MMF_DEVTOOLS]` and `[HMR] connected` in the console when the local server is connected.

**5. Where are business configuration values (min budget, creative dimensions, etc.) read from?**

All business configuration values come from the `Constantine` reactive store (`src/_shared/store/constantine.ts`), which is pre-fetched on every route entry via the `beforeEnter` guard. Access it with:
```typescript
import { constantine } from "src/_shared/store/constantine";
constantine?.displayAds?.minBudget;
```

**6. How do I read feature toggle flags?**

Feature toggles are stored in `metaNonAdsDataStore.extToggle` (non-ads toggles) and `adsMetaDataStore.adsToggle` (ads-specific toggles):
```typescript
import { metaNonAdsDataStore, adsMetaDataStore } from "src/_shared/store/meta";
metaNonAdsDataStore?.extToggle?.featureName;
adsMetaDataStore?.adsToggle?.featureName;
// Display Ads sunset flags
adsMetaDataStore?.adsToggle?.enableDisplayAdsSunset?.displayAdsSunset;
adsMetaDataStore?.adsToggle?.enableDisplayAdsSunset?.displayAdsSunsetNoticePeriod;
adsMetaDataStore?.adsToggle?.enableDisplayAdsSunset?.sunsetDate;
```

**7. Where do I add new tracking functions?**

Do not create new tracking functions in `pas-display`. Instead, define the tracking function in `pas-common/tracking/entries/` and re-export it from `src/track/index.ts`. Then import it from `src/track`.

**8. Why does `mmc.config.js` delete the `eds-vue` shared config?**

`pas-display` needs its own separate instance of `eds-vue` (version 5.0.40) rather than the shared portal version. The `extendPackConfig` function removes `eds-vue` from the Module Federation `shared` configuration so that each module bundles its own copy.

**9. How is the page session ID used?**

A UUID page session ID is stored under `SELLER_CENTER_SHOPEE_ADS_PAGE_SESSION_ID` in `localStorage` and regenerated on every route path change. It is used to correlate tracking events that occur within the same page session for analytics purposes.

**10. How do I run the module on BD Centre instead of Seller Center?**

Run `yarn run init -p 17` to initialize with the BD Centre portal (portal ID 17), then start the dev server normally. The module automatically detects `app.bdUser.id` and adjusts breadcrumbs and SecureFetch behavior accordingly.

**11. What happens when the Display Ads sunset feature is active?**

When `adsMetaDataStore.adsToggle.enableDisplayAdsSunset.displayAdsSunset` is `true`, the Display Ads (Homepage Carousel) option is hidden from the creation page, and the brand creation entry switches to a tab-card showing only Brand Consideration and Search Brand. During the notice period (`displayAdsSunsetNoticePeriod` is `true`), a sunset alert is shown with the sunset date (`sunsetDate`).

**12. Why can't I save changes to a DD Shopee Mall Card creative during editing?**

When editing a Brand Consideration campaign, if the DD Shopee Mall Card creative has already been approved or rejected, and you have not re-uploaded the image, the creative text must also be changed. Changing only text without re-uploading the image (or changing only the image without text) will result in a validation error. This prevents accidental re-submission of an identical creative.

<!-- Generated by ads-workspace/skills/ads-readme-generate | checked: ba899929e8c3ad220d49f3871d554342f5ccdecb | spec: 76fce5f679f9550b -->
