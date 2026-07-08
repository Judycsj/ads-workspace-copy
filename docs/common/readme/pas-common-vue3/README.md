<!-- ads-workspace-gdoc-sync: gdoc_id=1Htltm6LTOeT6fl0H1CkmcCRP2nTObMkCA1NUfFquwAQ gdoc_url=https://docs.google.com/document/d/1Htltm6LTOeT6fl0H1CkmcCRP2nTObMkCA1NUfFquwAQ/edit -->

# pas-common

> Shared Module Federation Provider for Shopee Paid Ads (Seller Center Ads)

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

`pas-common` is a Vue 3 + TypeScript Module Federation Provider that supplies shared components, utility functions, type definitions, tracking logic, and framework compatibility layers to all Shopee Paid Ads business modules (`pas-index`, `pas-product`, `pas-display`, `pas-livestream`). It operates as a remote component provider (MMC module id: `404`) within the Multi-Module Framework (MMF), exposing resources consumed via the `pas-common` alias across ad-type modules deployed to Shopee Seller Center.

---

## Key Features

- **55+ Shared Vue 3 Components** — Business components (budget editing, product selector, target ROAS, ads diagnosis, ROI controls, auto top-up, auto escrow, Smart Voucher notice, GMS exclude product, rapid boost effect, compound mission card) and UI components (avatar, drawer, carousel, metric chart, status modal, operation log) all typed with full Props/Emits definitions.
- **Comprehensive Utility Library** — Formatting (currency, date, number, string), campaign logic, CSV export, ACL access control, event bus, discounts, rewards, target ROAS calculations, LRU cache, body scroll prevention, positive operation boost, and min-budget validation helpers (`min-budget/`, gated by feature flag `szLimitMinBudgetAutoIncrease`).
- **Complete Type Definitions** — Campaign, affiliate, keyword, metrics, currency, time, report, rewards, and to-do list types shared across all consumer modules.
- **Unified Request Factory** — `createRequest()` factory function with rate-limit handling, security antibot/signature/DFP integration, and configurable response interceptors, exposed via `./request` MF entry.
- **TMS Tracking Integration** — 42 page-specific tracking entry files generated via the `tracking import` CLI command, with a Vue directive (`useTrackingDirective`) and centralized `report()` function including session ID enrichment.
- **Framework Compatibility Layer** — Normalizes the seller portal `framework` (i18n, router, shop, environment, timeService, modal, filters) for use in all consumer modules, including BD user fallback and MCN support.
- **EDS Vue Re-exports** — Centralized re-exports of 40+ EDS Vue design system components and types (`EdsTable`, `EdsButton`, `EdsModal`, `EdsForm`, `EdsSelector`, etc.) for uniform versioning (`5.0.36`).
- **Module Federation with Webpack/Rspack** — Configured code splitting for `echarts`, `eds-vue`, `tracking`, `vendors`, and component entry chunks for optimized load performance. Supports both webpack and rsbuild.
- **Shared Composables** — `useVoucherEstimation` (debounced voucher estimation with LRU caching and provide/inject), `usePositiveOperationBoost` (operation boost banners), `useGenericPollExport` (generic polling export).
- **Component Documentation System** — VuePress-based documentation with `vue-docgen` for auto-generated Props/Events/Slots tables and demo components.

---

## Project Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Seller Center Portal                         │
│           (seller.{test|uat|prod}.shopee.{CID})                    │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ MMF Runtime
         ┌─────────────────────┼──────────────────────┐
         │                     │                       │
    pas-index             pas-product           pas-display / pas-livestream
    (MF Consumer)         (MF Consumer)         (MF Consumers)
         │                     │                       │
         └─────────────────────┼───────────────────────┘
                               │ Module Federation (pas-common alias)
                    ┌──────────▼────────────┐
                    │      pas-common        │
                    │   (MF Provider)        │
                    │   MMC module id: 404   │
                    │   port: 8001           │
                    ├────────────────────────┤
                    │  ./components          │
                    │  ./components/homepage │
                    │  ./components/metric-chart │
                    │  ./utils               │
                    │  ./types               │
                    │  ./framework           │
                    │  ./eds-vue             │
                    │  ./api                 │
                    │  ./request             │
                    │  ./tracking            │
                    │  ./tracking/entries/*  │
                    └────────────────────────┘
```

**Key architectural decisions:**
- `pas-common` is a **Module Federation Provider** (`consumer: false`), never a consumer.
- `eds-vue` is declared as a **singleton shared dependency** (version `5.0.36`, strict) to prevent duplicate instances.
- Chunk splitting separates `echarts`, `eds-vue`, `tracking`, `vendors`, homepage entry, and shared utils into distinct chunks for optimized caching.
- TypeScript types are emitted via `@shopee/module-federation-typescript` (`FederatedTypesPlugin`) and consumed as `@mf-types/pas-common/_types/` in consumer projects.
- Rsbuild is supported alongside webpack for dev mode via the `rsbuild` config in `mmc.config.js`.

---

## Directory Structure

```
pas-common/
├── mmc.config.js               # MMC/Module Federation configuration (id: 404, port: 8001)
├── package.json                # Dependencies: eds-vue 5.0.36, echarts, vuelidate, etc.
├── .pas.tracking.config.js     # TMS tracking CLI configuration
├── .gitlab-ci.yml              # CI: lint, code_review, release_verify, auto_deploy to test/uat
├── eslintrc.js                 # ESLint configuration (extends @shopee/pas-module-config)
├── commitlint.config.js        # Commit message linting
├── vuepress-docs/              # Component documentation (VuePress + vue-docgen)
└── src/
    ├── bootstrap.ts            # Module bootstrap entry point
    ├── index.ts                # Root export
    ├── components/             # 55+ shared Vue 3 components
    │   ├── index.ts            # Full components export (./components MF entry)
    │   ├── homepage.ts         # Homepage-only export (./components/homepage MF entry)
    │   ├── chart.ts            # Metric chart export (./components/metric-chart MF entry)
    │   ├── _shared/            # Shared assets, request utils, SCSS styles
    │   ├── ads-creation-sv-notice-modal/  # Smart Voucher notice modal at ads creation
    │   ├── ads-diagnosis/      # Ads health diagnosis component
    │   ├── auto-budget-increase/   # Auto budget increase modal
    │   ├── auto-escrow-drawer/ # Auto escrow settings drawer
    │   ├── auto-top-up-settings/   # Auto top-up configuration
    │   ├── avatar/             # Campaign/shop avatar display
    │   ├── back-home/          # Navigation back-home component
    │   ├── bid-price-edit-popover/ # Keyword bid price inline editing
    │   ├── blank-modal/        # Generic blank modal wrapper
    │   ├── brand-date-picker/  # Brand ads calendar date picker
    │   ├── bread-crumb/        # Breadcrumb navigation
    │   ├── budget-edit-popover/    # Campaign budget inline editing
    │   ├── budget-input/       # Budget amount input field
    │   ├── campaign-status-action/ # Campaign pause/resume/end actions
    │   ├── carousel/           # Image carousel
    │   ├── common-card/        # Generic card layout
    │   ├── currency-input/     # Currency-aware input field
    │   ├── custom-eds-toast/   # Dynamic toast notifications
    │   ├── date-range-popover/ # Date range selection popover
    │   ├── drawer/             # Slide-out drawer panel
    │   ├── ellipsis-text/      # Text truncation with tooltip
    │   ├── empty-ads/          # Empty state for ads lists
    │   ├── export-report-button/   # Report download button
    │   ├── gmv-metric-switch/  # GMV/ROAS metric toggle
    │   ├── gms-exclude-product-drawer/  # GMS exclude product management drawer
    │   ├── growth-tooltip/     # Growth indicator tooltip
    │   ├── keyword-action-group/   # Keyword batch actions (bid, match type)
    │   ├── keyword-list/       # Keyword display list
    │   ├── keyword-selector/   # Keyword search and selection
    │   ├── link-toast/         # Toast with clickable link
    │   ├── loadable-list/      # List with loading state
    │   ├── manual-ads-migration/   # Manual-to-ROI2 migration controls
    │   ├── match-type-popover/ # Keyword match type selection
    │   ├── metric-chart/       # ECharts-based performance chart
    │   ├── modal-template/     # Status modal template (StatusModal)
    │   ├── multiple-cascader-select/ # Multi-level cascader selector
    │   ├── npa-bidding/        # NPA (Non-Product Ads) bidding controls
    │   ├── number-input/       # Numeric input component
    │   ├── operation-entrance/ # Operation entry point display
    │   ├── operation-log/      # Audit/operation log viewer
    │   ├── product-avatar/     # Product image avatar
    │   ├── product-list/       # Product ads list with batch support
    │   ├── product-selector/   # Product search and selection
    │   ├── rapid-boost-effect/ # Rapid boost effect popover and chart
    │   ├── rec-action-panel/   # Recommendation action panel
    │   ├── remove-optimise-warning-banner/ # Optimization removal warning
    │   ├── render-unit/        # Generic render unit wrapper
    │   ├── result-modal/       # Operation result modal
    │   ├── rewards-center/     # Rewards/incentive center components
    │   ├── roas-cold-start-prompt/ # ROAS cold start guidance
    │   ├── roi/                # ROI/ROAS bidding controls (create, edit, modal)
    │   ├── scroll-toast/       # Scroll-triggered toast
    │   ├── secure-session/     # Secure session handling
    │   ├── select-affiliates/  # Affiliate selection component
    │   ├── select-metrics/     # Metrics column selector
    │   ├── simple-pagination/  # Lightweight pagination
    │   ├── target-audience/    # Target audience / TADS audience modal
    │   ├── target-roas/        # Target ROAS configuration
    │   ├── time-edit-popover/  # Campaign time schedule editing
    │   ├── to-do-mini-card/    # Mini to-do card component
    │   ├── ult-on-boarding/    # Onboarding banners and announcements
    │   └── warning-modal/      # Warning confirmation modal
    ├── utils/                  # Shared utility functions (./utils MF entry)
    │   ├── index.ts
    │   ├── acl/                # Access control (ACCESS_KEYS permission checks)
    │   ├── budget-input/       # Budget input validation helpers
    │   ├── campaign/           # Campaign business logic utilities
    │   ├── csv/                # CSV export utilities
    │   ├── currency/           # Currency formatting and conversion
    │   ├── date/               # Date formatting utilities
    │   ├── discount/           # Discount calculation utilities
    │   ├── event-bus/          # Cross-module event bus
    │   ├── fixed-card/         # Fixed card layout utilities
    │   ├── lru-cache/          # LRU cache (maxSize-bounded Map; used by useVoucherEstimation)
    │   ├── min-budget/         # Min-budget validation helpers (szLimitMinBudgetAutoIncrease feature)
    │   ├── number/             # Number formatting, convertServerNumber/convertClientNumber
    │   ├── number-adjustments/ # Number adjustment helpers
    │   ├── prevent-body-scroll/# Body scroll lock utility
    │   ├── report/             # Report generation utilities
    │   ├── rewards/            # Rewards center utilities
    │   ├── string/             # String manipulation utilities
    │   ├── target-roas/        # Target ROAS computation (openColdStartPrompt)
    │   ├── to-do-list/         # To-do list utilities
    │   ├── track/              # Tracking helper utilities
    │   └── util/               # General-purpose helpers
    ├── types/                  # Shared TypeScript type definitions (./types MF entry)
    │   ├── index.ts
    │   ├── affiliate/          # Affiliate program types
    │   ├── base/               # Base/primitive types
    │   ├── campaign/           # Campaign entity types
    │   ├── common/             # Common shared types
    │   ├── currency/           # Currency types
    │   ├── keyword/            # Keyword types
    │   ├── metrics/            # Ad metrics types
    │   ├── number/             # Number types
    │   ├── report/             # Report types
    │   ├── rewards/            # Rewards types
    │   ├── time/               # Time/schedule types
    │   └── to-do-list/         # To-do list types
    ├── framework/              # Seller portal framework bridge (./framework MF entry)
    │   ├── index.ts            # Exports: translate, app, shop, region, environment,
    │   │                       #          timeService, modal, filters, formatDate,
    │   │                       #          cdnFile, formatNumber, language, isBDUser,
    │   │                       #          shopSwitcher, sellerOrigin, Currency, AccountType
    │   └── currency.ts         # Currency utility class
    ├── eds-vue/                # EDS Vue component re-exports (./eds-vue MF entry)
    │   └── index.ts            # 40+ components: EdsTable, EdsButton, EdsModal,
    │                           #   EdsSelector, EdsForm, createModalInstance, etc.
    ├── api/                    # Shared API functions (./api MF entry)
    │   ├── index.ts
    │   ├── product/            # Product ads API types and functions
    │   ├── setup-helper/       # Setup helper API types and functions
    │   ├── smart-voucher/      # Smart Voucher estimation API
    │   └── rewards-center/     # Rewards center API
    ├── request/                # Unified request factory (./request MF entry)
    │   ├── index.ts            # createRequest(), getSkipError()
    │   └── types.ts            # BASE_PREFIX, REQUEST_METHOD, APIError, RequestOptions, CoreRequestFunction
    ├── tracking/               # TMS tracking definitions (./tracking MF entry)
    │   ├── index.ts            # Exports: useTrackingDirective, TrackingProps
    │   ├── report.ts           # report(), getSharedComponentTrackingTrigger()
    │   ├── track.tpl.ejs       # EJS template for auto-generated tracking files
    │   ├── useTrackingDirective.ts  # Vue v-tracking directive
    │   └── entries/            # 42 page-specific tracking entry directories
    │       ├── adsFssWaiverLandingPage/
    │       ├── brandAdsDetail/
    │       ├── campaignBudgetRecommendationPage/
    │       ├── createBrandAds/
    │       ├── createDisplayAds/
    │       ├── createLiveAds/
    │       ├── createNewProductAds/
    │       ├── createProductAds/
    │       ├── createShopAds/
    │       ├── sellerCenterAdsCampaignPage/
    │       ├── sellerCenterShopeeAds/  # 150+ sub-modules including smartVoucher, spendingTask, escrow, GMS
    │       └── ... (42 total entries)
    ├── constants/              # Shared constants (not MF-exposed directly)
    │   └── index.ts            # BROAD_MATCH_PRICE_MULTIPLIER, Region, ACCESS_KEYS,
    │                           # API_ERROR_CODE_TO_MESSAGE, noop
    ├── composables/            # Shared composables
    │   ├── index.ts
    │   ├── useGenericPollExport.ts     # Generic polling export composable
    │   ├── useVoucherEstimation.ts     # Debounced voucher estimation with LRU cache + provide/inject
    │   └── usePositiveOperationBoost.ts # Positive operation boost banner composable
    ├── filters/                # Vue filter compatibility layer
    │   ├── cdn-formatter/
    │   ├── currency-formatter/
    │   ├── date-formatter/
    │   └── number-formatter/
    ├── polyfill/               # Framework polyfills
    │   └── _polyfill-event-bus.ts   # Event bus polyfill
    └── ads-remote/             # Re-exports for ads-remote module consumption
        ├── api.ts
        ├── components.ts
        ├── framework.ts
        ├── tracking.ts
        ├── types.ts
        └── utils.ts
```

---

## Quick Start

### Prerequisites

| Requirement | Version |
|---|---|
| Node.js | >= 16.14.0 (20 recommended) |
| pnpm | >= 8.0.0 (required to install MMC) |
| MMC CLI (`@shopee/multi-module-cli`) | Latest v3.x |
| npm registry | `https://npm.shopee.io/` |

Install MMC globally (first-time setup only):

```bash
pnpm i -g @shopee/multi-module-cli

# Run setup after install
mmc setup

# Verify installation (should display 4 versions)
mmc -V
```

### Configuration

`pas-common` is configured as MMC module id `404` (portal id `21` = local-seller-center). This is set in `mmc.config.js`:

```js
module.exports = {
  id: 404,
  port: 8001,
  type: "module",
  tech: "vue3",
  // ...
};
```

The `eds-vue` dependency is declared as a singleton shared dependency — both `pas-common` and consumer modules **must** use `eds-vue@5.0.36`.

### Installation

Run once before first development session:

```bash
yarn run init
# Select "local-seller-center" when prompted
```

> **Note:** If developing alongside a consumer module (e.g., `pas-product`), run `yarn run init` in both projects and select the **same portal option** in each.

### Build

```bash
# Local build
yarn build

# Type check only
yarn type:check

# Inspect webpack config
yarn inspect
```

### Local Development

**Step 1: Start the dev server**

```bash
yarn dev
```

This concurrently runs `mmc dev` (with `LOCAL_DEV=1`) and `vue-tsc -w` for type watching.

For WebStorm users:

```bash
yarn dev:webstorm
```

**Step 2: Connect to the dev server**

Open your target seller center test environment:

```
https://seller.{test|uat}.shopee.{CID}
```

In the browser DevTools console, enable dev mode:

```js
mmfDevtools.enable()
```

Reload the page. You will see `[MMF_DEVTOOLS]` and `[HMR] connected` in the console when the dev server is connected.

**Step 3: Develop alongside consumer modules**

If you need to develop `pas-common` together with a consumer (e.g., `pas-product`), start `yarn dev` in both projects simultaneously — MMF will connect both local dev servers.

**Linting:**

```bash
yarn lint          # Run ESLint + Stylelint
yarn lint:es:fix   # Auto-fix ESLint issues
yarn lint:style:fix # Auto-fix style issues
yarn prettier      # Format with Prettier
```

### Deployment

Production deployments are managed via the **Seller Portal** build system.

**Quick deployment steps:**

1. Open [Seller Portal Build Page](https://seller-portal.i.shopee.io/build/modules-group)
2. Select **Shopee Ads (Seller center)** → **Pas Common** → your branch
3. Select target environment (test / UAT / production)
4. Select **Auto Publish** → choose `local-seller-center` and `cb-seller-center` in portal → select all regions
5. Optionally fill in the **PFB 2.0** field for a feature branch deployment
6. Click **Build & Publish**

**CI/CD (`.gitlab-ci.yml`):**

| Stage | Trigger | Action |
|---|---|---|
| `lint` | Merge request | `yarn lint` |
| `code_review` | Merge request | AI code review |
| `release_verify` | Merge request | Deploy platform verification |
| `auto_deploy` | Push to `master` | `yarn deploy -e test && yarn deploy -e uat` |
| `pages` | Manual (`web`) | Build VuePress documentation |

---

## API Documentation

All API endpoints use a version prefix (typically `/api/pas/v1`) followed by the path string listed below. The **Page** column indicates which component or module defines the endpoint.

| Page | Page URL | API Endpoint | Description |
|---|---|---|---|
| Setup Helper | `src/api/setup-helper/` | `/setup_helper/get_recommended_roi_two_target/` | Get recommended ROI2 target values |
| Target ROAS | `src/components/target-roas/api/` | `/setup_helper/get_recommended_target_roi/` | Get recommended target ROAS config |
| Keyword Selector | `src/components/keyword-selector/api/` | `/setup_helper/list_keyword_hint/` | List keyword hints for autocomplete |
| Keyword Selector | `src/components/keyword-selector/api/` | `/setup_helper/list_recommended_keyword/` | List recommended keywords |
| Keyword Selector | `src/components/keyword-selector/api/` | `/setup_helper/search_keyword/` | Search keywords by query |
| Product Selector | `src/components/product-selector/api/` | `/setup_helper/product_selector/list_by_item_id/` | List products by item IDs |
| Product Selector | `src/components/product-selector/api/` | `/setup_helper/get_category_tree/` | Get product category tree |
| Product Selector | `src/components/product-selector/api/` | `/category/page_active_collection_list/` | List active product collections |
| Product Selector | `src/components/product-selector/api/` | `/public/category/tree/` | Get public category tree |
| Auto Budget Increase | `src/components/budget-edit-popover/api/` | `/auto_budget_increase/edit/` | Edit auto budget increase setting |
| Auto Budget Increase | `src/components/budget-edit-popover/api/` | `/auto_budget_increase/get/` | Get auto budget increase setting |
| Auto Top-up Settings | `src/components/auto-top-up-settings/api/` | `/topup/check_cncb_subaccount_password/` | Check CNCB sub-account password |
| Auto Top-up Settings | `src/components/auto-top-up-settings/api/` | `/topup/edit_auto_topup_setting/` | Edit auto top-up setting |
| Auto Top-up Settings | `src/components/auto-top-up-settings/api/` | `/topup/get_auto_topup_setting/` | Get auto top-up setting |
| Auto Top-up Settings | `src/components/auto-top-up-settings/api/` | `/topup/get_setting/` | Get top-up setting |
| Auto Top-up Settings | `src/components/auto-top-up-settings/api/` | `/topup/get_suggest_auto_topup_setting/` | Get suggested auto top-up setting |
| Auto Top-up Settings | `src/components/auto-top-up-settings/api/` | `/topup/set_has_seen_auto_topup/` | Mark auto top-up as seen |
| Auto Escrow Drawer | `src/components/auto-escrow-drawer/api/` | `/topup/auto_escrow/edit_setting/` | Edit auto escrow setting |
| Auto Escrow Drawer | `src/components/auto-escrow-drawer/api/` | `/topup/auto_escrow/get_eligibility/` | Get auto escrow eligibility |
| Auto Escrow Drawer | `src/components/auto-escrow-drawer/api/` | `/topup/auto_escrow/get_estimated_auto_ads_data/` | Get estimated automated ads data |
| Auto Escrow Drawer | `src/components/auto-escrow-drawer/api/` | `/topup/auto_escrow/get_estimated_topup_data/` | Get estimated top-up data |
| Auto Escrow Drawer | `src/components/auto-escrow-drawer/api/` | `/topup/auto_escrow/get_setting/` | Get auto escrow setting |
| Manual Ads Migration | `src/components/manual-ads-migration/api/` | `/homepage/trigger_async_upgrade/` | Trigger async manual-to-ROI2 upgrade |
| Rewards Center | `src/api/rewards-center/` | `/incentive/campaign/mass_optimize/` | Mass optimize incentive campaigns |
| Rewards Center | `src/api/rewards-center/` | `/incentive/list_banner/` | List reward banners |
| Rewards Center | `src/api/rewards-center/` | `/incentive/modify/` | Modify reward program |
| Rewards Center | `src/api/rewards-center/` | `/incentive/modify_banner/` | Modify reward banner |
| Operation Log | `src/components/operation-entrance/api/` | `/operation_log/query/` | Query operation logs |
| Operation Log | `src/components/operation-entrance/api/` | `/operation_log/query_result_count/` | Get operation log result count |
| Product API | `src/api/product/` | `/product/edit/` | Mass edit product ads campaigns |
| Product API | `src/api/product/` | `/product/get_roi_two_uplift/` | Get ROI2 uplift data |
| Product API | `src/api/product/` | `/product/gms/get_campaign_id/` | Get GMS campaign ID |
| Product API | `src/api/product/` | `/product/list_estimated_simple_roi_two_data/` | List estimated simple ROI2 data |
| Product API | `src/api/product/` | `/product/list_overlapping_ads_for_roi_two/` | List overlapping ads for ROI2 |
| Product API | `src/api/product/` | `/product/list_recommended_roi_two_target/` | List recommended ROI2 targets |
| Manual Ads Migration | `src/components/manual-ads-migration/api/` | `/product/get_budget_data_for_creation/` | Get budget data for creation |
| Manual Ads Migration | `src/components/manual-ads-migration/api/` | `/product/get_estimated_data/` | Get ROI2 estimated data |
| Manual Ads Migration | `src/components/manual-ads-migration/api/` | `/product/get_single_manual_upgrade_data/` | Get single manual upgrade data |
| QSS | `src/api/rewards-center/` | `/qss/sign_up_program/` | Sign up for QSS program |
| Export Report | `src/components/export-report-button/api/` | `/report/export_job/download/` | Download report (CRM) |
| Export Report | `src/components/export-report-button/api/` | `/report/export_job/get_download_url/` | Get report download URL |
| Export Report | `src/components/export-report-button/api/` | `/report/export_job/get_single_result/` | Get single report result status |
| Export Report | `src/components/export-report-button/api/` | `/report/export_job/trigger_or_get_previous/` | Trigger report export or get previous |
| Operation Log Export | `src/components/operation-entrance/api/` | `/report/export_job/get_operation_log_result/` | Get operation log export result |
| Operation Log Export | `src/components/operation-entrance/api/` | `/report/export_job/trigger_operation_log/` | Trigger operation log export |
| Brand Date Picker | `src/components/brand-date-picker/api/` | `/search_brand/get_calendar_info/` | Get brand ads calendar info |
| Smart Voucher | `src/api/smart-voucher/` | `/smart_voucher/list_voucher_estimation/` | List voucher estimations for campaign creation/editing flows |
| Target Audience | `src/components/target-audience/` | `/target_audience/get_group_estimated_result/` | Get audience group estimated result |
| Target Audience | `src/components/target-audience/` | `/target_audience/list_available_option/` | List available audience options |

### Module Federation Endpoints

Consumer modules import from `pas-common` using these MF paths:

| MF Entry | Import Path | Contents |
|---|---|---|
| `./components` | `pas-common/components` | All 55+ shared components |
| `./components/homepage` | `pas-common/components/homepage` | Homepage-specific component subset |
| `./components/metric-chart` | `pas-common/components/metric-chart` | Metric chart only |
| `./utils` | `pas-common/utils` | All utility functions |
| `./types` | `pas-common/types` | All type definitions |
| `./framework` | `pas-common/framework` | Portal framework bridge |
| `./eds-vue` | `pas-common/eds-vue` | EDS Vue components and types |
| `./api` | `pas-common/api` | Shared API functions |
| `./request` | `pas-common/request` | Unified request factory (`createRequest`, `BASE_PREFIX`, types) |
| `./tracking` | `pas-common/tracking` | Tracking directive and types |
| `./tracking/entries/{page}` | `pas-common/tracking/entries/{page}` | Per-page tracking functions |

### Key Exports

**Framework (`pas-common/framework`)**

```typescript
import { translate, app, shop, region, environment, timeService, modal,
         formatDate, cdnFile, formatNumber, language, isBDUser,
         shopSwitcher, sellerOrigin, Currency, AccountType,
         EdsToastInstance, modalInstance, particularApp, TriggerOptions,
         bindVueFilters, filters } from "pas-common/framework";
```

**Request (`pas-common/request`)**

```typescript
import { createRequest, getSkipError, BASE_PREFIX, REQUEST_METHOD } from "pas-common/request";
import type { RequestOptions, APIError, APIExternalResponse, CreateRequestConfig, CoreRequestFunction } from "pas-common/request";

const v1Request = createRequest({ version: BASE_PREFIX.V1 });
const data = await v1Request<ReqType, ResType>("/product/get/", { params: payload });
```

**Utilities (`pas-common/utils`)**

Key exports include:
- `convertServerNumber(v)` / `convertClientNumber(v)` — Number inflation/deflation (÷/× 100,000)
- Currency, date, number, and string formatting functions
- `useAcl` — ACL permission checks using `ACCESS_KEYS` enum
- Campaign business logic utilities
- `openColdStartPrompt` — Target ROAS cold start prompt

**Constants (`pas-common/constants`)**

```typescript
import { BROAD_MATCH_PRICE_MULTIPLIER, Region, ACCESS_KEYS,
         API_ERROR_CODE_TO_MESSAGE, noop } from "pas-common/constants";
```

**Smart Voucher (`src/api/smart-voucher/`)**

```typescript
import { listVoucherEstimation } from "src/api/smart-voucher";
// Returns voucher amount estimates (gainedVoucherAmount, roasGainedVoucherAmount,
// budgetGainedVoucherAmount) based on campaignType and per-campaign ROI/budget settings.
```

**Number Conversion**

The backend inflates numeric values by 10^5 (100,000) to avoid floating-point issues:

```typescript
// In pas-common's own API files:
import { convertServerNumber, convertClientNumber } from "src/utils";

// In consumer modules:
import { convertServerNumber, convertClientNumber } from "pas-common/utils";
```

---

## Local Storage

pas-common uses the following browser storage keys for tracking session management:

| Storage Type | Key | Purpose |
|---|---|---|
| `localStorage` | `SELLER_CENTER_SHOPEE_ADS_PAGE_SESSION_ID` | Page session ID injected into all tracking payloads via `report()` |
| `sessionStorage` | `HC_SESSION_ID` | JSON blob containing `sessionId` for user session tracking |

These keys are read by `src/tracking/report.ts` and automatically enriched into every tracking event dispatched through the `report()` function.

---

## TMS Tracking

### Overview

pas-common integrates with TMS (Traffic Management System) for analytics tracking. The `tracking/` directory contains:

- **`report.ts`** — Core `report(params)` function that enriches events with `pageSessionId` (from `localStorage`) and `userSessionId` (from `sessionStorage`) before calling `app.tracker.trigger()`.
- **`useTrackingDirective.ts`** — Vue directive `v-tracking` for declarative event tracking.
- **`entries/`** — 42 auto-generated page-specific tracking directories, each exposed as a separate MF entry (`./tracking/entries/{pageName}`).

### Tracking Entries

| Entry Name | Description |
|---|---|
| `adsFssWaiverLandingPage` | FSS waiver landing page |
| `brandAdsDetail` | Brand ads detail page |
| `brandMaxAdsDetail` | Brand max ads detail page |
| `campaignBudgetRecommendationPage` | Campaign budget recommendation |
| `createBrandAds` | Brand ads creation |
| `createDisplayAds` | Display ads creation |
| `createLiveAds` | Live ads creation |
| `createNewProductAds` | New product ads creation |
| `createProductAds` | Product ads creation |
| `createShopAds` | Shop ads creation |
| `editBrandMaxAds` | Brand max ads editing |
| `productAdsDetail` | Product ads detail |
| `qssCreatingYourAdsNowPopup` | QSS creating ads popup |
| `qssUnableToCreateAdsPopup` | QSS unable to create ads popup |
| `searchBrandAdDetails` | Search brand ad details |
| `sellerCenterAdsCampaignPage` | SC ads campaign page |
| `sellerCenterAdsDetails` | SC ads details |
| `sellerCenterAdsHomepage` | SC ads homepage |
| `sellerCenterAdsMyAccountPage` | SC ads my account |
| `sellerCenterAdsQssEnrolment` | SC QSS enrolment |
| `sellerCenterAdsToDoList` | SC ads to-do list |
| `sellerCenterAdsTopup` | SC ads top-up |
| `sellerCenterCampaignBudgetRecommendationPage` | SC campaign budget recommendation |
| `sellerCenterCreateBrandAds` | SC create brand ads |
| `sellerCenterCreateDisplayAds` | SC create display ads |
| `sellerCenterCreateLiveAds` | SC create live ads |
| `sellerCenterCreateProductAds` | SC create product ads |
| `sellerCenterCreateShopAds` | SC create shop ads |
| `sellerCenterDisplayAdDetail` | SC display ad detail |
| `sellerCenterEditDisplayAds` | SC edit display ads |
| `sellerCenterLivestreamAdDetail` | SC livestream ad detail |
| `sellerCenterProductAdDetail` | SC product ad detail |
| `sellerCenterRestartLivestreamAd` | SC restart livestream ad |
| `sellerCenterRestartProductAd` | SC restart product ad |
| `sellerCenterRestartShopAd` | SC restart shop ad |
| `sellerCenterShopAdDetail` | SC shop ad detail |
| `sellerCenterShopeeAds` | SC Shopee Ads main (150+ sub-modules including smartVoucher, smartVoucherDrawer, spendingTaskCreatePopup, spendingTaskDrawer, escrowFeeRatePopup, escrowRewardPopup, gmsCreatePopup, gmsProductManage, adsRewards, allAdsListGms, ocpmNoticePopup, takeRateRoasPopup, aiReportDrawer, brandMaxAdsLaunchPopUpV2, etc.) |
| `sellerCenterShopeeAdsQssGuidePage` | SC QSS guide page |
| `sellerCenterShopeeAdsRewardsPage` | SC rewards page |
| `sellerCenterTopUp` | SC top-up page |
| `sellerCenterViewRecommendationCards` | SC view recommendation cards |
| `shopAdsDetail` | Shop ads detail page |

### Importing Tracking Entries

Use the `tracking` CLI to auto-generate entry files from TMS tickets:

```bash
tracking import -t {ticket-id}
```

This generates files in `src/tracking/entries/{pageName}/`:
- `types.ts` — TypeScript tracking interfaces
- `index.ts` — Tracking functions (from `track.tpl.ejs` template)

**If the command fails with an authentication error**, update your TMS token:

1. Visit [https://trafficsuite.shopee.io/tms](https://trafficsuite.shopee.io/tms)
2. Open DevTools → Application → Cookies → `https://trafficsuite.shopee.io`
3. Copy the `_oauth2_proxy_mesos` cookie value
4. Paste it into `.pas.tracking.tms.token` (git-ignored)

### Tracking Configuration (`.pas.tracking.config.js`)

- TMS group ID: `0`
- Token source: `.pas.tracking.tms.token` file
- Output grouping: by `page` and `section` fields
- Name shortening: `Impression→Imp`, `SellerCenter→SC`, `Product→Prod`, `Keyword→Kw`, etc.

### Using Tracking in Consumer Modules

```typescript
// Import page-specific tracking functions
import { trackClickSomething } from "pas-common/tracking/entries/createProductAds";

// Use the v-tracking directive
import { useTrackingDirective } from "pas-common/tracking";

// Use shared component tracking trigger
import { getSharedComponentTrackingTrigger } from "pas-common/tracking";
```

---

## Performance Monitoring

### Webpack Chunk Splitting

`mmc.config.js` configures the following chunk groups for production performance:

| Chunk Name | Contents | Min Size |
|---|---|---|
| `echarts` | `echarts` + `zrender` packages | 30 KB |
| `eds-vue` | `eds-vue`, `@eds-vue/*` (excluding svg), `src/eds-vue` | 30 KB |
| `vendors` | All other `node_modules` | 50 KB |
| `tracking` | `src/tracking/` | 120 KB |
| `homepage-entry` | `src/components/homepage.ts` | 1 KB |
| `shared-entry` | `src/components/index.ts` | 1 KB |
| `shared` | `src/framework`, `src/api`, `src/utils`, `src/types` | 30 KB |

**Module optimization settings:**
- `concatenateModules: true` — Scope hoisting
- `chunkIds: "deterministic"` — Stable chunk IDs in production
- `maxInitialRequests: 25`, `maxAsyncRequests: 25`

### Dev Mode Code Inspector

In dev mode, the `code-inspector-plugin` is enabled, allowing click-to-source navigation from browser to editor. The editor is configurable via the `EDITOR` environment variable (defaults to `cursor`):

```bash
yarn dev:webstorm   # Sets EDITOR=webstorm
```

---

## Business Terminology Glossary

Key terms used throughout the codebase:

| Term | Definition |
|---|---|
| **ROAS / ROI** | Return on Ad Spending / Return on Investment. Ads GMV ÷ Ads Revenue. Used interchangeably in codebase (`roi/`, `target-roas/`). |
| **CIR** | Cost-Income Ratio. Ads Revenue ÷ Ads GMV. Inverse of ROAS. |
| **CPC** | Cost Per Click. Ad spend ÷ click count. |
| **CTR** | Click-Through Rate. Clicks ÷ Impressions. |
| **CPM** | Cost Per Mille. Cost per 1,000 impressions. |
| **CR** | Conversion Rate. Ad orders ÷ total clicks on the ad. |
| **ECPM** | Effective Cost per Mille. Total Ad Spend ÷ Total Impressions. |
| **Take-Rate** | Ads Revenue ÷ Platform GMV. Measures how effectively Shopee monetizes via ads. |
| **oCPC / Simple Mode** | Optimized CPC — system auto-selects keywords and adjusts bids. |
| **Target ROAS** | Seller-specified ROAS goal; system adjusts bids to hit the target. |
| **Broad Match** | Keyword match type where related queries trigger the ad (multiplier: `BROAD_MATCH_PRICE_MULTIPLIER = 1.2`). |
| **Exact Match** | Keyword match type where only the exact query triggers the ad. |
| **QSS** | QuickStart Service. Helps new advertisers ramp up ad usage. |
| **TADS / DADS** | Targeting/Discovery Ads. Audience-segmented display ads. |
| **NPA** | Non-Product Ads. Bidding type for brand/shop ads. |
| **Auto Top-up (ATU)** | Automatic credit top-up when ad balance is low. |
| **Escrow** | Auto Escrow (ATU) — fee rate configuration for automatic billing. |
| **Smart Voucher** | Voucher estimation and incentive feature at campaign creation time, showing estimated voucher gain based on ROI/budget settings. |
| **GMS** | Gross Merchandise Sales campaign type. `GmsExcludeProductDrawer` manages excluded products for GMS campaigns. |
| **Rapid Boost** | Short-term ad boost with effectiveness measured by comparing boosted vs. non-boosted cumulative broad GMV over time. |
| **PFB** | Per-Feature Branch deployment for isolated testing. |
| **GMV** | Gross Merchandise Value. Total transaction value. |
| **ACL** | Access Control List. Permission gating using `ACCESS_KEYS` enum. |
| **SC** | Seller Center — the platform where sellers manage ads. |
| **SIP** | Shopee International Platform. |
| **Cold Start** | Ads with insufficient data for accurate prediction. |
| **MCN** | Multi-Channel Network. Special seller type with `isMCN` flag. |
| **SRM** | Seller Relationship Management. Organizes seller data for segmentation. |
| **COD** | Cash on delivery. |
| **MMC** | Multi-Module CLI (`@shopee/multi-module-cli`). The build and dev toolchain for Module Federation modules. |
| **MMF** | Multi-Module Framework. The runtime connecting MF Provider and Consumer modules inside Seller Center. |

---

## References

- [GitLab Repository](https://git.garena.com/shopee/isfe/ao/pas-common-vue3)
- [MMC Documentation](https://seller-portal.i.test.shopee.io/mmc-docs/guide/getting-started.html)
- [Seller Portal Build & Release](https://seller-portal.i.shopee.io/build/modules-group)
- [Ads Platform Overview (SRA Docs)](https://sra.test.shopee.io/05.Business_Systems/5.3_Ads_Business_and_Architecture_Introduction/5.3.6._ads.platform.html)
- [TMS Platform](https://trafficsuite.shopee.io/tms)
- [Paid Ads Glossary (Confluence)](https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPAD&title=Paid+Ads+Glossary)
- [Component Documentation (VuePress)](http://localhost:8080/isfe/ao/pas-common/) — run `yarn docs:dev` locally
- [MMC DOD Support](https://dod.shopee.io/team?id=296)

---

## Frequently Asked Questions

**1. Why does `yarn run init` ask me to select a portal option, and which should I choose?**

MMC pulls the module's test environment configuration (router, params) from Seller Portal by the module id (`404`). Select `local-seller-center` (portal id `21`) for standard development. Both `pas-common` and any consumer module you develop alongside it must select the **same option**, otherwise the module federation connection will fail.

**2. How do I add a new shared component to pas-common?**

Create a directory under `src/components/{component-name}/` with `index.ts`, `types.ts`, and the `.vue` file. Export the component and its types from `index.ts`, then add the export to `src/components/index.ts` (and `homepage.ts` if used by the homepage). Avoid business logic specific to a single ad type.

**3. How do I consume a pas-common export in a consumer module?**

Import using the `pas-common` alias:
```typescript
import { ProductSelector } from "pas-common/components";
import { convertServerNumber } from "pas-common/utils";
import { translate } from "pas-common/framework";
import { createRequest, BASE_PREFIX } from "pas-common/request";
```
TypeScript types are available at `@mf-types/pas-common/_types/` in consumer projects.

**4. How does the `convertServerNumber` / `convertClientNumber` system work?**

The backend stores monetary and rate values inflated by 100,000 to avoid floating-point issues. Use `convertServerNumber(v)` (divides by 100,000) when receiving API responses, and `convertClientNumber(v)` (multiplies by 100,000) when sending values to the API. In `pas-common`'s own API files, import from `src/utils`; in consumer modules, import from `pas-common/utils`.

**5. How do I add a new tracking entry for a page?**

Run `tracking import -t {ticket-id}` where `{ticket-id}` is the TMS ticket. This generates `src/tracking/entries/{pageName}/types.ts` and `index.ts`. The new entry is automatically exposed as a new MF endpoint (`./tracking/entries/{pageName}`) because `mmc.config.js` reads the entries directory dynamically via `fs.readdirSync`.

**6. What is the `homepage.ts` export, and how does it differ from `index.ts`?**

`src/components/homepage.ts` is a subset of `src/components/index.ts` — it exports only the components also used by `pas-index` (the homepage module). This separation allows the homepage to load a smaller initial bundle. If your component is used by both the homepage and other modules, export it from both files.

**7. How do I use `translate()` vs `$t()` for i18n?**

Use `$t("key")` in Vue templates. Use `translate("key")` (imported from `pas-common/framework`) in TypeScript files and Vue `<script setup>` sections. Never use `i18n.t()` directly.

**8. How does `useVoucherEstimation` work and when should I use it?**

`useVoucherEstimation(options)` is a composable that fetches Smart Voucher estimations for campaign creation/editing flows with a 500ms debounce, an LRU cache of 100 entries, and stale-request cancellation. It uses `provide/inject` so parent components call `useVoucherEstimation` and child components call `useVoucherEstimationInject()` to access the same data context. Use it when building campaign creation forms that display voucher reward estimates based on the seller's ROI target and daily budget inputs.

**9. How do I use the unified request factory (`createRequest`)?**

The `./request` MF entry exposes `createRequest()` which returns a single `request` function supporting POST/GET/PUT with rate-limit handling and security integration:
```typescript
import { createRequest, BASE_PREFIX } from "pas-common/request";
const v1Request = createRequest({ version: BASE_PREFIX.V1 });
const data = await v1Request<ReqType, ResType>("/product/get/", { params: payload });
```

**10. What happens when I push to `master`?**

The CI pipeline automatically deploys to both **test** and **uat** environments via `yarn deploy -e test && yarn deploy -e uat` using `release-bot`. This triggers the `auto_deploy` stage in `.gitlab-ci.yml`.

<!-- Generated by ads-workspace/skills/ads-readme-generate | checked: 099987f8a94b84119c0d18417a1c54bf558bd726 | spec: 76fce5f679f9550b -->
