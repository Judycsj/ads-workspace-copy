<!-- ads-workspace-gdoc-sync: gdoc_id=1P_r-7frxQm3XmqczPjXEH9EpAm64FuGgMu7-LCwa_GI gdoc_url=https://docs.google.com/document/d/1P_r-7frxQm3XmqczPjXEH9EpAm64FuGgMu7-LCwa_GI/edit -->

# pas-index

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

`pas-index` is the main frontend module for the Shopee Ads (Paid Ads) platform within Seller Center. It serves as the primary entry point for sellers to manage their ad campaigns, top up their ad balance, view to-do task recommendations, track rewards, manage their account wallet, and access the Fee Waiver Program and Campaign Accelerator. Built on the Multi-Module Framework (MMC) using Vue 3 + TypeScript, it integrates tightly with the Seller Center portal ecosystem and the `pas-common` shared library.

---

## Key Features

- **Ads Homepage**: Unified campaign listing with tab-based navigation across Product Ads, Product NPA Ads, Shop Ads, Brand Ads, Brand Consideration Ads, Display Ads, and Live Ads. Includes campaign-level statistics, mass edit, diagnosis integration, and GMV metric views.
- **Top-Up Page**: Ad balance top-up with support for auto top-up settings, voucher application, and top-up incentive rewards display.
- **To-Do List Page**: Actionable ad optimization task cards (potential items, daily budget recommendations, ROAS enhancement, ROI2 migration, credit expiry) organized in tabbed views (All / Action / Reminder).
- **Campaign Budget Recommendation Page**: Dedicated page for viewing and applying AI-recommended daily budget increases for campaign surge days.
- **Account Wallet Page**: Multi-tab page showing Ads Wallet balance, Free Ads Credit details, and Top-Up History.
- **Rewards Center**: Incentive program listing across multiple program types (QSS, QSS one-month, item spending, topup, multi-tier, simple fixed spending, compound, target spending, ads credit package, sustained ATU, signup spending, campaign optimization, sustained auto escrow, fee auto escrow, etc.) with status filtering (All / To Complete / Completed / Expired). Includes progress summary components and GMS campaign state management.
- **Fee Waiver Program (FSS)**: Dedicated standalone page at `/portal/marketing/pas/fee-waiver-program`. Displays the take-rate formula (Spending ÷ GMV) with a real-time progress bar against the seller's target take-rate, eligibility status, and action suggestions (top-up with escrow reward tag, create new ads, increase budget, decrease target ROAS). Gated by `isEligible` check — non-eligible sellers are redirected to the homepage. Accessible from the CMT campaign page via `?type=FSS_FEE_WAIVER_PROGRAM`.
- **Campaign Accelerator**: Dedicated standalone page at `/portal/marketing/pas/campaign-accelerator`. Shows package details (sign-up and live periods), a status badge (Scheduled / Ongoing / Ended), and a sign-up flow with GMS Product Ad ROI configuration and optional auto-escrow (live and post-live fee rates). Gated by the `szAdsCampaignAccelerator` feature flag — redirects to homepage if unavailable. Accessible from the CMT campaign page via `?type=CAMPAIGN_GMV_MAX_ACCELERATOR`.
- **GMS AI Report (Seller Agent)**: AI-generated diagnostic report for GMS (GMV Max Simple) Product Ad campaigns, opened as a 960px drawer (`GmsAiReportPanel` → `GmsAiReportDrawer`) from the Shop GMV Max Ads list. The report is rendered as an iframe loading from `/api/pas/v1/seller_agent/report/page/{report_id}`. Report readiness is polled via `POST /seller_agent/report/status`; users can submit feedback (thumbs up/down, comment) via `POST /seller_agent/report/feedback`. The drawer also embeds shop-wise booster controls (budget increase, campaign surge, smart voucher) via `getRoi3BoosterModule`.
- **Smart Shop Booster (Shop-Wise Booster)**: A shop-level optimization drawer (800px) aggregating three modules — Auto Budget Increase, Campaign Surge toggle, and Smart Voucher toggle — into a single settings panel. Available from the homepage GMS campaign view. Settings are fetched via `GET /smart_booster/get/` and saved via `POST /smart_booster/set/`.
- **Smart Voucher Drawer**: Dedicated 800px optimization drawer showing 14-day voucher performance stats (vouchered GMV, voucher amount, WoW uplift) and per-campaign action recommendations (decrease ROAS target, increase budget). Toggle-based enable/disable via `POST /smart_voucher/set/`. Actions estimated via `POST /smart_voucher/check_action/`.
- **Auto-GMS Performance Table**: Product-level performance table inside the Shop GMV Max Ads list. Supports product-type filter, recommendation-label filter (`RecommendationFilter`), keyword search, batch product add (`BatchAddProducts`), and multi-select delete (up to 30 items). Data sourced from `POST /product/gms/list_item_product_performance/`.
- **Prompts Management System**: Priority-ordered modal and prompt queue (URL-triggered → API-triggered) ensuring only one prompt appears at a time. Supports 45+ prompt types including campaign escrow, OCPM upgrade consent, auto escrow announcement, NPA announcement, GMV definition upgrade, mass feature operation, no-balance notice, brand max ads adoption (`BRAND_MAX_ADS_ADOPTION_POPUP`), GMS create encouragement (`GMS_CREATE_ENCOURAGEMENT_V2`), and more.
- **Performance Monitoring (APMS/MDAP)**: Instrumented timing metrics tracking sidebar-to-module enter time, router-to-homepage render time, campaign table render time, and line chart render time.
- **Shop Switcher Integration**: Supports switching between shops with automatic metadata refresh.
- **Permission Guard**: Route-level ACL checks (`hasViewAdsAccess`, `hasEditAdsAccess`, `hasTopupAdsAccess`, `hasExportAccess`) via `pas-common/utils`.
- **Holiday Mode Guard**: Detects seller holiday mode and shows confirmation modal before allowing entry to the ads module.
- **Feature Flags**: Region-specific feature toggles (e.g., `uiAdsTutorialVideos` enabled for TW, MY, VN, SG).

---

## Project Architecture

`pas-index` is a **MMC module** (type: `module`, tech: `vue3`, id: `375`) registered under the Seller Center portal (portal id: `21` — `local-seller-center`, and `22` — `cb-seller-center`).

```
Seller Center Portal (MMF)
  └── pas-index (Module ID: 375)
        ├── src/index.ts           ← Module entry: imports router
        ├── src/router/index.ts    ← Route definitions & guards
        └── src/pages/
              ├── Index.vue              ← Root page component (shop switcher, i18n, metrics)
              ├── homepage/              ← Main campaign listing page
              ├── top-up/                ← Ad balance top-up
              ├── to-do-list/            ← Task recommendations
              ├── campaign-budget-rcmd/  ← Budget recommendation page
              ├── account-wallet/        ← Ads wallet & credit
              ├── rewards-center/        ← Incentive programs
              ├── fee-waiver-program/    ← FSS fee waiver program (standalone route)
              └── campaign-accelerator/  ← Campaign accelerator (standalone route)
```

The module contains **three top-level routes**:

1. `/portal/marketing/pas` — the main ads portal, with children: `index` (homepage), `top-up`, `todolist`, `campaign-budget-recommendation`, `wallet`, `rewards`.
2. `/portal/marketing/pas/fee-waiver-program` — the FSS fee waiver program, a standalone route outside the main ads children hierarchy.
3. `/portal/marketing/pas/campaign-accelerator` — the campaign accelerator, another standalone route.

The `roas-protection/` directory is not a standalone route — it is embedded within the homepage as a widget component. Similarly, `reinforce-roi3/` provides an alternative ROAS protection card layout used on the homepage when the corresponding feature flag is active.

The module follows a two-flow architecture:
- **Old Flow**: Handles legacy campaign creation and management pages (sub-pages built inside this project).
- **Ultimate Setup Flow (USF)**: Uses multiple separate MMC modules for ad creation/detail pages. `pas-index` hosts only the **homepage**, **top-up**, **wallet**, **to-do list**, **rewards center**, **campaign budget recommendation**, **fee waiver program**, and **campaign accelerator** pages in this flow.

Shared logic is provided by `pas-common` (a separate dependency module). All EDS Vue components must be imported via `pas-common/eds-vue`, not directly from `eds-vue`.

The API layer uses a unified `createRequest` factory (`src/api/request/index.ts`) that wraps Axios with interceptors for no-authorization redirect, rate-limit error handling, and optional SecureFetch (anti-bot, signature, DFP). The factory supports GET, POST, and PUT methods with configurable response interceptors.

---

## Directory Structure

```
📦src
 ┣ 📂api              ← API functions and request/response types
 ┃ ┣ 📂banner         ← Banner-related API (get, modify, mass campaign modify, min bid/budget CSV)
 ┃ ┣ 📂campaign       ← Campaign API types and functions
 ┃ ┣ 📂campaign-accelerator ← Campaign Accelerator API (get, edit)
 ┃ ┣ 📂common         ← Common API entry and types
 ┃ ┣ 📂fss            ← FSS fee waiver program API (get_action, get, list_history)
 ┃ ┣ 📂meta           ← Ads metadata fetch
 ┃ ┣ 📂report         ← Reporting API (time graph, export, config)
 ┃ ┣ 📂request        ← Unified request factory (createRequest, types)
 ┃ ┣ 📂rewards        ← Rewards center API (query, modify, banner, mass create)
 ┃ ┣ 📂roas-protection← ROAS protection API (overview, campaign history, campaign detail)
 ┃ ┣ 📂roi            ← ROI-related API
 ┃ ┣ 📂seller-agent   ← Seller Agent AI report API (report status, feedback, report page URL)
 ┃ ┣ 📂smart-voucher  ← Smart voucher API (get, list_action, set, check_action)
 ┃ ┣ 📂to-do-list     ← To-do list task API
 ┃ ┣ 📂top-up         ← Top-up API
 ┃ ┣ 📂transaction-history ← Transaction history API
 ┃ ┣ 📂wallet         ← Wallet/credit API
 ┃ ┣ 📜constant.ts    ← API path constants (~135 endpoints)
 ┃ ┣ 📜request.ts     ← Legacy adapter wrapping createRequest into v1Request
 ┃ └ 📜types.ts       ← Common API types
 ┣ 📂assets           ← Static resources (images, SVGs)
 ┣ 📂components       ← Shared reusable UI components
 ┃ ┣ 📂batch-product-table    ← Batch product creation/result table
 ┃ ┣ 📂modals                 ← Modal components (activate-ads-cps, auto-budget-inc, campaign-day, etc.)
 ┃ ┣ 📂custom-skeleton        ← Skeleton loading component
 ┃ ┗ 📂to-do-list             ← To-do list card and action components
 ┣ 📂composables      ← Composition API utilities (usePagination)
 ┣ 📂constants        ← Business and logical constants
 ┃ ┣ 📜app-config.ts  ← localStorage key registry (StorageKey)
 ┃ ┣ 📜campaign_ad.ts ← CampaignAdStates enum, ReportCampaignType enum
 ┃ ┣ 📜currency.ts    ← Currency constants
 ┃ ┣ 📜event-bus.ts   ← Event bus key constants
 ┃ ┣ 📜router.ts      ← RouterPath constants
 ┃ ┣ 📜types.ts       ← Shared type exports (StatusType, GMS_PAGE_ID, etc.)
 ┃ ┗ 📜...            ← Other domain constants
 ┣ 📂metric           ← APMS/MDAP performance tracking
 ┃ ┣ 📜metricMdap.ts  ← MetricKeys enum, METRICMAP, metricSchema
 ┃ ┗ 📜load.ts        ← LoadMeasure helper class
 ┣ 📂pages            ← Page-level components
 ┃ ┣ 📂homepage       ← Main ads homepage (campaign table, filters, modals, prompts)
 ┃ ┃ ┣ 📂components   ← Homepage-specific components (tab-bar, campaign-statistic, modals, etc.)
 ┃ ┃ ┃ ┣ 📂shop-gmv-max-ads-list ← GMS campaign list with AI report panel and auto-GMS performance table
 ┃ ┃ ┃ ┣ 📂auto-gms-performance-table ← GMS product performance table (filter, recommendation label, batch add)
 ┃ ┃ ┃ ┣ 📂smart-voucher-drawer  ← Smart Voucher optimization drawer (14-day stats, action recommendations)
 ┃ ┃ ┃ ┗ 📂smart-shop-booster-drawer ← Shop-Wise Booster unified settings drawer (ABI + surge + smart voucher)
 ┃ ┃ ┣ 📂composable   ← Homepage composables (usePromptsManager, useQSS, useFetchHomepageStatistic, etc.)
 ┃ ┃ ┗ 📂utils        ← Prompt action types and utilities
 ┃ ┣ 📂top-up         ← Top-up page with auto-topup, vouchers, rewards
 ┃ ┣ 📂to-do-list     ← To-do list task page
 ┃ ┣ 📂campaign-budget-rcmd ← Budget recommendation page
 ┃ ┣ 📂account-wallet ← Ads wallet, free ads credit, top-up history
 ┃ ┣ 📂rewards-center ← Incentive programs listing page
 ┃ ┃ ┣ 📂programs     ← Individual program type implementations
 ┃ ┃ ┃ ┣ 📂ads-credit-package-program    ← ACP program display logic
 ┃ ┃ ┃ ┣ 📂compound-*-program            ← Compound spending programs
 ┃ ┃ ┃ ┣ 📂fee-auto-escrow-program       ← Fee auto escrow program with accelerate drawer
 ┃ ┃ ┃ ┣ 📂item-spending-program         ← Item spending program
 ┃ ┃ ┃ ┣ 📂multi-tier-*-program          ← Multi-tier programs
 ┃ ┃ ┃ ┣ 📂qss-*-program                 ← QSS programs
 ┃ ┃ ┃ ┣ 📂simple_fixed_spending_program ← GMS simple fixed spending
 ┃ ┃ ┃ ┣ 📂single-tier-*-program         ← Single-tier programs
 ┃ ┃ ┃ ┣ 📂spending-*-program            ← Spending programs
 ┃ ┃ ┃ ┣ 📂target-spending-program       ← Target spending program
 ┃ ┃ ┃ ┣ 📂top-spending-program          ← Top spending program
 ┃ ┃ ┃ ┣ 📂topup-program                 ← Top-up program
 ┃ ┃ ┃ ┗ 📂components/progress-summary   ← Progress summary sub-components
 ┃ ┃ ┗ 📂utils        ← Rewards center utilities and manual migration check
 ┃ ┣ 📂fee-waiver-program   ← FSS fee waiver program page (standalone route)
 ┃ ┃ ┣ 📂components         ← Skeleton loading
 ┃ ┃ └ 📂modals             ← FSS modals (topup, create-ads, increase-budget, lower-roi, data-history)
 ┃ ┣ 📂campaign-accelerator ← Campaign accelerator page (standalone route)
 ┃ ┃ ┣ 📂components         ← Detail, fee-rate-modal, post-campaign-fee-rate-popover, skeleton
 ┃ ┃ └ 📜post-sign-up.vue   ← Post-signup view with auto-escrow and campaign settings
 ┃ ┣ 📂roas-protection← ROAS protection widget (embedded in homepage, not a standalone route)
 ┃ └ 📜Index.vue      ← Root page (sets up i18n, shop switcher, metrics)
 ┣ 📂router           ← Route definitions and navigation guards
 ┃ ┣ 📜index.ts       ← All routes + beforeEnter guards + page session tracking
 ┃ ┣ 📜constant.ts    ← Route names (RouterMap), setup flow URLs (AdsSetupPage), helpers
 ┃ └ 📜utils.ts       ← getAdsSetupRoute helper for URL generation
 ┣ 📂store            ← Reactive global state
 ┃ ┣ 📂auto-budget-config ← Auto budget increase configuration
 ┃ ┣ 📂config-center  ← Constantine (reactive config), top-up config, links config
 ┃ ┣ 📂meta           ← Ads metadata (adsAccount, extToggle, adsToggle, etc.)
 ┃ ┣ 📂qss            ← QuickStart Service state and getters
 ┃ ┣ 📂report-cache   ← Report time/metric cache with snake/camelCase conversion
 ┃ ┣ 📂rewards        ← Sustained auto escrow program state
 ┃ ┗ 📂top-up         ← Top-up page state
 ┣ 📂styles           ← Global SCSS (constants, mixins, index)
 ┣ 📂track            ← TMS tracking function exports
 ┃ ┣ 📜index.ts       ← Named exports from pas-common tracking entries
 ┃ ┣ 📜types.ts       ← Tracking type definitions
 ┃ ┗ 📜trackingEntry.ts ← Tracking entry point (re-exports)
 ┣ 📜index.ts         ← Module entry point (imports router)
 ┗ 📜module.json      ← MMF module config (notification navigation, routes)
```

---

## Quick Start

### Prerequisites

- **Node.js** >= 16.14.0 (Node 20 recommended)
- **pnpm** >= 8.0.0 (pnpm 8 recommended)
- **npm global registry** set to `https://npm.shopee.io/`
- **MMC CLI** installed globally: `@shopee/multi-module-cli`
- Python 3.10 (required by MMC)
- xcodebuild (macOS only, required by MMC)

### Configuration

The module is configured via `mmc.config.js` at the repository root. Key settings:

| Field | Value | Description |
|-------|-------|-------------|
| `id` | `375` | MMF module ID |
| `type` | `module` | MMC artifact type |
| `tech` | `vue3` | Vue 3 framework |
| `injectStyle` | SCSS mixins, constants, index | Global SCSS injected into all components |
| `webpack` | Custom splitChunks | Merges commons, homepage API/constants into `app-common` chunk |
| `rsbuild` | rspack config | Used for dev mode only |

The `config/.remote-config.json` file is auto-generated by `yarn run init`. It contains fetched portal configuration (routes, params) from the Seller Portal API. Do not manually commit this file; it is overwritten on each `init`.

### Installation

Install MMC globally (first-time setup):

```bash
pnpm i -g @shopee/multi-module-cli
mmc setup
mmc -V   # verify: should show mmc-core, mmc-vue, mmc-react, mmc-vue3 versions
```

Install project dependencies:

```bash
yarn run init
# When prompted, select: local-seller-center (portal id: 21)
```

> **Note**: `yarn run init --prod` installs only `dependencies` (not `devDependencies`), used in CI build stages.

### Build

Build the module for deployment via the Seller Portal UI:

1. Open [Seller Portal Build Page](https://seller-portal.i.shopee.io/build/modules-group)
2. Select **Shopee Ads (Seller center)** → **Pas** → your branch → target environment
3. Select **Auto Publish**, then select portals: `local-seller-center` and `cb-seller-center`, and choose all regions
4. Optionally fill in the **PFB 2.0** field for feature branch builds
5. Click **Build & Publish**

Or trigger via CI (auto-deploy to test after merging to `master` or `release`):

```bash
yarn deploy:ci -e test -p pfb-ads-platform-e2e -b $CI_COMMIT_BRANCH
```

### Local Development

**Step 1** — Initialize (first time or after a long break):

```bash
yarn run init
# Select: local-seller-center
```

**Step 2** — Start the dev server:

```bash
yarn dev
# Starts: mmc dev (LOCAL_DEV=1) + vue-tsc type watcher concurrently
```

**Step 3** — Connect to the test portal in the browser:

1. Open `https://seller.test.shopee.{CID}` in your browser (e.g., `https://seller.test.shopee.sg`)
2. Open browser DevTools console
3. Run: `mmfDevtools.enable()`
4. Reload the page — the portal will load your local module instead of the remote version

> **Tip**: If the page still shows the remote version, clear browser cache and reload.

**WebStorm users**:

```bash
yarn dev:webstorm
```

**Develop with remote branch**:

```bash
yarn dev:remote   # Uses master branch remote assets
```

### Development

Key development rules for this project:

1. **All new features** must be developed in the **Ultimate Setup Flow**. Check if logic exists in old flow before proceeding.
2. Do not create new files in `old flow only` folders (`components/`, `store/`, etc. outside the `pages/homepage/` composable pattern).
3. Import EDS Vue components via `pas-common/eds-vue`, not directly from `eds-vue`.
4. Import `pas-common` components from `pas-common/components/homepage`, not from `pas-common/components`.
5. For tracking functions, use `export *` only for `sellerCenterShopeeAds` and `sellerCenterAdsCampaignPage`; use named exports for all other tracking entries.
6. Adding a new homepage prompt: follow the 3-step Prompts Management System (add `PromptId` → choose trigger array → implement action with cleanup).

Run linting:

```bash
yarn lint          # ESLint + Stylelint
yarn lint:fix      # Auto-fix linting issues
yarn lint:changed  # Lint changed files only (CI-friendly)
```

Type checking:

```bash
yarn type:check    # Run vue-tsc type check
```

### Deployment

After CI auto-deploys to test (triggered on merge to `master` or `release`), the pipeline also:
- Runs E2E tests (`@pas-index` tag) against the `pfb-ads-platform-e2e` PFB
- Auto-deploys to UAT (`yarn deploy -e uat`)

Manual release steps:
1. Build a successful job in Seller Portal
2. Click **Publish** on the build record
3. Select portal (`local-seller-center`, `cb-seller-center`), PFB, and regions
4. Click **Publish** to start the release job

To take a module offline: toggle **Offline Mode** before building, then release.

---

## API Documentation

All API requests are made via `createRequest` from `src/api/request/index.ts`, which wraps Axios with:
- No-authorization interceptor (redirects to home if `code === 1400109802`)
- Rate-limit error handling (shows toast if `code === 7`)
- Optional SecureFetch (`withSecureFetchParams: true`) for anti-bot, signature, and DFP protection
- Support for GET, POST, and PUT methods via unified `request` function

**Base URL prefix** (`BASE_PREFIX` in `src/api/request/types.ts`):

| Prefix | Base Path |
|--------|-----------|
| `BASE_PREFIX` (default) | `/api/pas/v1` |

**API endpoints** (from `src/api/constant.ts`):

| Page | Page URL | API Endpoint | Description |
|------|----------|--------------|-------------|
| Meta | `/portal/marketing/pas` | `/meta/get_ads_data/` | Fetch ads account metadata |
| Meta | `/portal/marketing/pas` | `/meta/get_non_ads_data/` | Fetch non-ads metadata |
| Config | `/portal/marketing/pas` | `/config/get/` | Get configuration |
| Homepage | `/portal/marketing/pas/index` | `/homepage/query/` | Query homepage campaign list |
| Homepage | `/portal/marketing/pas/index` | `/homepage/mass_edit/` | Mass edit campaigns |
| Homepage | `/portal/marketing/pas/index` | `/homepage/list_subentry/` | List homepage sub-entries |
| Homepage | `/portal/marketing/pas/index` | `/homepage/get_creation_prompt_card/` | Get creation prompt card |
| Homepage | `/portal/marketing/pas/index` | `/homepage/get_mass_edit_warning_for_roi_two/` | Get mass edit warning for ROI2 |
| Homepage | `/portal/marketing/pas/index` | `/homepage/list_additional_trait/` | List additional traits |
| Homepage | `/portal/marketing/pas/index` | `/homepage/list_additional_metrics/` | List additional metrics |
| Homepage | `/portal/marketing/pas/index` | `/homepage/update_trait/` | Update trait |
| Homepage | `/portal/marketing/pas/index` | `/homepage/list_upgradable/` | List upgradable campaigns |
| Homepage | `/portal/marketing/pas/index` | `/homepage/trigger_async_upgrade/` | Trigger async upgrade |
| Homepage | `/portal/marketing/pas/index` | `/homepage/list_merged_upgradable/` | List merged upgradable campaigns |
| Homepage | `/portal/marketing/pas/index` | `/homepage/list_upgraded/` | List upgraded campaigns |
| Homepage | `/portal/marketing/pas/index` | `/homepage/check_async_upgrade_status/` | Check async upgrade status |
| Homepage | `/portal/marketing/pas/index` | `/homepage/list_stopped_ads_by_roi_two_migration/` | List stopped ads by ROI2 migration |
| Homepage | `/portal/marketing/pas/index` | `/homepage/list_upgradable_ads_to_simple_roi_two/` | List upgradable ads to simple ROI2 |
| Homepage | `/portal/marketing/pas/index` | `/report/get_homepage_time_graph/` | Homepage line chart data |
| Homepage | `/portal/marketing/pas/index` | `/setup_helper/get_campaign_expense_statistics/` | Campaign expense data |
| Homepage | `/portal/marketing/pas/index` | `/banner/get/` | Get banner status |
| Homepage | `/portal/marketing/pas/index` | `/banner/modify/` | Modify banner |
| Homepage | `/portal/marketing/pas/index` | `/banner/mass_campaign_modify/` | Mass campaign modify |
| Homepage | `/portal/marketing/pas/index` | `/diagnosis/batch_list_verdict/` | Batch list ad diagnosis verdicts |
| Homepage | `/portal/marketing/pas/index` | `/diagnosis/homepage_batch_list_verdict/` | Homepage batch list diagnosis verdicts |
| Homepage | `/portal/marketing/pas/index` | `/diagnosis/track/` | Track diagnosis |
| Homepage | `/portal/marketing/pas/index` | `/smart_booster/get/` | Get smart booster settings |
| Homepage | `/portal/marketing/pas/index` | `/smart_booster/set/` | Set smart booster settings |
| Homepage | `/portal/marketing/pas/index` | `/smart_voucher/get/` | Get smart voucher settings |
| Homepage | `/portal/marketing/pas/index` | `/smart_voucher/list_action/` | List smart voucher actions |
| Homepage | `/portal/marketing/pas/index` | `/smart_voucher/set/` | Set smart voucher settings |
| Homepage | `/portal/marketing/pas/index` | `/smart_voucher/check_action/` | Check smart voucher action |
| Seller Agent | `/portal/marketing/pas/index` | `/seller_agent/report/status` | Poll GMS AI report generation status |
| Seller Agent | `/portal/marketing/pas/index` | `/seller_agent/report/feedback` | Submit feedback on a GMS AI report |
| Campaign | `/portal/marketing/pas/index` | `/product/get/` | Get product ad details |
| Campaign | `/portal/marketing/pas/index` | `/product/get_setup_status/` | Get product ad setup status |
| Campaign | `/portal/marketing/pas/index` | `/product/edit/` | Edit product ad |
| Campaign | `/portal/marketing/pas/index` | `/product/publish/` | Publish product ad |
| Campaign | `/portal/marketing/pas/index` | `/product/mass_create/` | Mass create product ads |
| Campaign | `/portal/marketing/pas/index` | `/product/get_budget_data_for_creation/` | Get budget data for creation |
| Campaign | `/portal/marketing/pas/index` | `/product/list_overlapping_ads_for_roi_two/` | List overlapping ads for ROI2 |
| Campaign | `/portal/marketing/pas/index` | `/product/get_estimated_data/` | Get ROI2 estimated data |
| Campaign | `/portal/marketing/pas/index` | `/product/gms/get_estimated_data/` | Get GMS estimated data |
| Campaign | `/portal/marketing/pas/index` | `/product/gms/product_selector/list/` | List GMS product selector items |
| Campaign | `/portal/marketing/pas/index` | `/product/gms/get_total_selected/` | Get GMS total selected items |
| Campaign | `/portal/marketing/pas/index` | `/product/gms/list_item_product_performance/` | List GMS item product performance |
| Campaign | `/portal/marketing/pas/index` | `/product/gms/count_total_item/` | Count total GMS items |
| Campaign | `/portal/marketing/pas/index` | `/product/gms/item/edit/` | Edit GMS item |
| Campaign | `/portal/marketing/pas/index` | `/product/get_roi_two_uplift/` | Get ROI2 uplift |
| Campaign | `/portal/marketing/pas/index` | `/product/get_single_manual_upgrade_data/` | Get single manual upgrade data |
| Campaign | `/portal/marketing/pas/index` | `/product/trigger_batch_upgrade_to_roi_two/` | Batch upgrade to ROI2 |
| Campaign | `/portal/marketing/pas/index` | `/product/upgrade_to_roi_two/` | Single upgrade to ROI2 |
| Campaign | `/portal/marketing/pas/index` | `/product/trigger_batch_upgrade_to_simple_roi_two/` | Batch upgrade to simple ROI2 |
| Campaign | `/portal/marketing/pas/index` | `/product/upgrade_to_simple_roi_two/` | Single upgrade to simple ROI2 |
| Campaign | `/portal/marketing/pas/index` | `/product/mass_create_for_npa_todo_popup/` | Mass create for NPA todo popup |
| Campaign | `/portal/marketing/pas/index` | `/setup_helper/get_budget_data_for_edit/` | Get budget data for edit |
| Campaign | `/portal/marketing/pas/index` | `/setup_helper/list_npa_todo_popup_item/` | List NPA todo popup items |
| Campaign | `/portal/marketing/pas/index` | `/setup_helper/get_recommended_roi_two_target/` | Get recommended ROI2 target |
| Campaign | `/portal/marketing/pas/index` | `/setup_helper/product_selector/query/` | Query product selector items |
| Campaign | `/portal/marketing/pas/index` | `/product_selector/list_additional_trait/` | List product selector additional traits |
| Campaign | `/portal/marketing/pas/index` | `/shop/check_has_enough_active_item/` | Check active items |
| Campaign | `/portal/marketing/pas/index` | `/search_brand/edit/` | Edit search brand |
| Campaign | `/portal/marketing/pas/index` | `/live_stream/edit/` | Edit live stream |
| Campaign Surge | `/portal/marketing/pas/campaign-budget-recommendation` | `/campaign_day/get_surge_setting/` | Get surge setting |
| Campaign Surge | `/portal/marketing/pas/campaign-budget-recommendation` | `/campaign_day/set_surge_setting/` | Set surge setting |
| Campaign Surge | `/portal/marketing/pas/campaign-budget-recommendation` | `/campaign_day/get_prompt/` | Get surge prompt |
| Campaign Surge | `/portal/marketing/pas/campaign-budget-recommendation` | `/campaign_day/stop_prompt/` | Stop surge prompt |
| Campaign Surge | `/portal/marketing/pas/campaign-budget-recommendation` | `/campaign_surge/list_optimized_campaign_subtype` | List optimized campaign subtypes |
| Campaign Surge | `/portal/marketing/pas/campaign-budget-recommendation` | `/campaign_surge/list_optimized_campaign` | List optimized campaigns |
| Campaign Accelerator | `/portal/marketing/pas/campaign-accelerator` | `/campaign_accelerator/get/` | Get campaign accelerator package and user settings |
| Campaign Accelerator | `/portal/marketing/pas/campaign-accelerator` | `/campaign_accelerator/edit/` | Sign up or edit campaign accelerator settings |
| Fee Waiver (FSS) | `/portal/marketing/pas/fee-waiver-program` | `/fss_program/get/` | Get FSS program overview (eligibility, progress, actions) |
| Fee Waiver (FSS) | `/portal/marketing/pas/fee-waiver-program` | `/fss_program/get_action/` | Get FSS action data (topup/create/budget/roas recommendations) |
| Fee Waiver (FSS) | `/portal/marketing/pas/fee-waiver-program` | `/fss_program/list_history/` | List FSS program history records |
| Top-up | `/portal/marketing/pas/top-up` | `/topup/list_available_voucher/` | List available vouchers |
| Top-up | `/portal/marketing/pas/top-up` | `/topup/claim_voucher/` | Claim voucher |
| Top-up | `/portal/marketing/pas/top-up` | `/topup/get_suggest_auto_topup_setting/` | Get suggested auto top-up setting |
| Top-up | `/portal/marketing/pas/top-up` | `/topup/edit_auto_topup_setting/` | Edit auto top-up settings |
| Top-up | `/portal/marketing/pas/top-up` | `/topup/get_setting/` | Get top-up settings |
| Top-up | `/portal/marketing/pas/top-up` | `/topup/set_has_seen_auto_topup/` | Set has seen auto top-up |
| Rewards | `/portal/marketing/pas/rewards` | `/incentive/query/` | Query incentive programs |
| Rewards | `/portal/marketing/pas/rewards` | `/incentive/get_reward_summary/` | Get rewards summary |
| Rewards | `/portal/marketing/pas/rewards` | `/incentive/modify/` | Modify incentive program |
| Rewards | `/portal/marketing/pas/rewards` | `/incentive/check_has_manual_migration/` | Check manual migration |
| Rewards | `/portal/marketing/pas/rewards` | `/incentive/list_banner/` | List reward banners |
| Rewards | `/portal/marketing/pas/rewards` | `/incentive/modify_banner/` | Modify reward banner |
| Rewards | `/portal/marketing/pas/rewards` | `/incentive/batch_modify/` | Batch modify incentive |
| Rewards | `/portal/marketing/pas/rewards` | `/incentive/accelerate/check_eligibility/` | Check accelerate program eligibility |
| Rewards | `/portal/marketing/pas/rewards` | `/incentive/campaign/list_eligible_item/` | List eligible items for incentive |
| Rewards | `/portal/marketing/pas/rewards` | `/incentive/campaign/mass_create/` | Mass create incentive campaigns |
| To-do List | `/portal/marketing/pas/todolist` | `/todo/list_task/` | List to-do tasks |
| To-do List | `/portal/marketing/pas/todolist` | `/todo/get_task/` | Get single to-do task |
| To-do List | `/portal/marketing/pas/todolist` | `/todo/update_task/` | Update to-do task |
| To-do List | `/portal/marketing/pas/todolist` | `/todo/set_has_seen/` | Set task as seen |
| To-do List | `/portal/marketing/pas/todolist` | `/todo/potential_item/list/` | List potential items |
| To-do List | `/portal/marketing/pas/todolist` | `/todo/potential_item/publish/` | Publish potential item ads |
| To-do List | `/portal/marketing/pas/todolist` | `/todo/potential_item/list_overlapping_ads/` | List overlapping potential item ads |
| To-do List | `/portal/marketing/pas/todolist` | `/todo/daily_budget/check_campaign_list/` | Check daily budget campaign list |
| To-do List | `/portal/marketing/pas/todolist` | `/todo/daily_budget/list_campaign/` | List daily budget campaigns |
| To-do List | `/portal/marketing/pas/todolist` | `/todo/daily_budget/mass_optimize_campaign/` | Mass optimize campaign budgets |
| To-do List | `/portal/marketing/pas/todolist` | `/todo/rcmd_roi_two_target/list_campaign/` | List ROI2 target campaigns |
| To-do List | `/portal/marketing/pas/todolist` | `/todo/rcmd_roi_two_target/mass_optimize_campaign/` | Mass optimize ROI2 campaigns |
| To-do List | `/portal/marketing/pas/todolist` | `/todo/enhance_roas/list/` | List ROAS enhancement items |
| To-do List | `/portal/marketing/pas/todolist` | `/todo/enhance_roas/optimize/` | Optimize ROAS |
| To-do List | `/portal/marketing/pas/todolist` | `/todo/credit_expiring/get_action_data/` | Get credit expiring action data |
| Wallet | `/portal/marketing/pas/wallet` | `/wallet/get/` | Get ads wallet balance |
| Wallet | `/portal/marketing/pas/wallet` | `/wallet/list_free_ads_credit/` | List free ads credits |
| Wallet | `/portal/marketing/pas/wallet` | `/wallet/list_banner/` | List wallet banners |
| Transaction | `/portal/marketing/pas/wallet` | `/transaction_history/get/` | Get transaction history |
| Transaction | `/portal/marketing/pas/wallet` | `/transaction_history/get_csv/` | Get transaction history CSV |
| ROAS Protection | `/portal/marketing/pas/index` | `/rebate/get_overview/` | Get ROAS protection overview |
| ROAS Protection | `/portal/marketing/pas/index` | `/rebate/list_campaign_history/` | List ROAS protection campaign history |
| ROAS Protection | `/portal/marketing/pas/index` | `/rebate/campaign_get/` | Get ROAS protection campaign detail |
| Report | `/portal/marketing/pas/index` | `/report/get/` | Get report data |
| Report | `/portal/marketing/pas/index` | `/report/update_selected_metric_config/` | Update metric config |
| Report | `/portal/marketing/pas/index` | `/report/update_time_config/` | Update time config |
| Report | `/portal/marketing/pas/index` | `/report/get_config/` | Get report config |
| Report | `/portal/marketing/pas/index` | `/report/export_job/list_homepage_result/` | List homepage export results |
| Report | `/portal/marketing/pas/index` | `/report/export_job/trigger/` | Trigger export job |
| Report | `/portal/marketing/pas/index` | `/report/export_job/get_single_result/` | Get single export result |
| Report | `/portal/marketing/pas/index` | `/report/export_job/get_download_url/` | Get export download URL |
| Report | `/portal/marketing/pas/index` | `/report/get_time_graph/` | Get report time graph |
| Report | `/portal/marketing/pas/index` | `/report/get_rapid_boost_effect/` | Get rapid boost effect data |
| Download | `/portal/marketing/pas/index` | `/download/get_csv/` | Download CSV |
| QSS | `/portal/marketing/pas/index` | `/qss/sign_up_program/` | QSS sign up program |
| QSS | `/portal/marketing/pas/index` | `/qss/mark_as_read/` | QSS mark as read |
| QSS | `/portal/marketing/pas/index` | `/qss/get_info/` | Get QSS info |
| QSS | `/portal/marketing/pas/index` | `/qss/get_ads_creation_record/` | Get QSS ads creation record |
| Banner | `/portal/marketing/pas/index` | `/banner/min_bid_price/get_impacted_ads_csv/` | Download CSV of ads impacted by min bid price changes |
| Banner | `/portal/marketing/pas/index` | `/banner/manual_prod_min_budget_increase/get_csv` | Download CSV of ads impacted by min daily budget increase |
| Report | `/portal/marketing/pas/index` | `/onboarding/get_csv_budget_migration/` | Get onboarding budget migration CSV |
| Rewards (Legacy) | `/portal/marketing/pas/rewards` | `/incentive/qss_one_month/list_eligible_item/` | List eligible items for QSS one-month program (deprecated) |
| Rewards (Legacy) | `/portal/marketing/pas/rewards` | `/incentive/qss_one_month/mass_create/` | Mass create for QSS one-month program (deprecated) |
| Rewards (Legacy) | `/portal/marketing/pas/rewards` | `/incentive/basic_item_spending/list_eligible_item/` | List eligible items for basic item spending (deprecated) |
| Rewards (Legacy) | `/portal/marketing/pas/rewards` | `/incentive/basic_item_spending/mass_create/` | Mass create for basic item spending (deprecated) |

---

## Local Storage

The module uses `localStorage` for persisting UI state across sessions. Keys are defined in `src/constants/app-config.ts` (via `StorageKey` enum) and `src/router/index.ts` (page session ID):

| Key | Purpose |
|-----|---------|
| `SHOP_ADS_V2_UPGRADE_MODAL` | Track if shop ads v2 upgrade modal has been shown |
| `SHOP_ADS_V2_VIDEO_MODAL` | Track if shop ads v2 video modal has been shown |
| `SHOP_ADS_CREATIVE_TIP` | Track if shop ads creative tip has been shown |
| `BROAD_MATCH_NEW_INTRO_KEY` | Track if broad match intro has been shown |
| `SHOPEE_ADS_METRICS_KEY` | Store selected metrics configuration |
| `DISPLAYED_TARGET_SIMPLE_MODE` | Track if target simple mode modal has been shown |
| `DISPLAYED_TARGET_BUYER_SEGMENT` | Track if buyer segment targeting modal has been shown |
| `DISPLAYED_BUYER_SEGMENT_REPORT` | Track if buyer segment report modal has been shown |
| `DISPLAYED_PRICE_LAYER_MODAL` | Track if price layer modal has been shown |
| `DISPLAYED_DETAIL_TARGET_SIMPLE_MODE` | Track if detail target simple mode has been shown |
| `DISPLAYED_ADS_PROMPT_DAY_INFO` | Track if ads prompt day info has been shown |
| `ADS_HAS_BOOST_USER_KEY` | Track if user has used boost feature |
| `KEYWORD_ADS_ECPC_NEW_TIP_VISIBLE` | Track if keyword ads eCPC new tip is visible |
| `SELLER_CENTER_SHOPEE_ADS_PAGE_SESSION_ID` | Page session ID for session correlation (set on every route change; defined in `src/router/index.ts`) |

---

## TMS Tracking

Tracking events are exported from `src/track/index.ts`. The module uses named exports from `pas-common` tracking entries, following the pattern:

- `export *` is used for `sellerCenterShopeeAds` (main entry point) and `sellerCenterAdsCampaignPage`
- All other tracking entries use **named exports** for better tree-shaking

**Tracked pages and key events:**

| Page | Entry | Sample Events |
|------|-------|---------------|
| Ads Homepage | `sellerCenterShopeeAds` | Module impression, section events |
| Ads Homepage | `sellerCenterAdsHomepage` | To-do list carousel, live ads popover, GST prompt, NPA prompt |
| Campaign Page (Accelerator) | `sellerCenterAdsCampaignPage` | Campaign page view, sign-up button click |
| Top-Up | `sellerCenterAdsTopup` | Auto top-up toggle, voucher apply, package click, go to checkout |
| To-Do List | `sellerCenterAdsToDoList` | Tab views, apply/more-info clicks, upgrade ROAS prompt |
| My Account | `sellerCenterAdsMyAccountPage` | Wallet view, auto top-up click, credit hover, banner impression |
| Campaign Budget Rcmd | `campaignBudgetRecommendationPage` | Tab impressions, optimise button click |
| Campaign Budget Rcmd | `sellerCenterCampaignBudgetRecommendationPage` | Page view |
| Rewards Center | `sellerCenterShopeeAdsRewardsPage` | Page view, card click, task pop interactions |
| Fee Waiver (FSS) | `adsFssWaiverLandingPage` | Page view, action module impression, action button click, view history |
| QSS | `sellerCenterAdsQssEnrolment` | QSS enrollment view |
| QSS Guide | `sellerCenterShopeeAdsQssGuidePage` | Guide page view, create ads, action button |
| QSS Popup | `qssCreatingYourAdsNowPopup` | Creating ads now popup view, top-up click, more details |
| QSS Popup | `qssUnableToCreateAdsPopup` | Unable to create ads popup view |
| Top-Up Rewards | `sellerCenterTopUp` | Seller incentive bonus bar, top-up rewards progress bar |
| View Rcmd Cards | `sellerCenterViewRecommendationCards` | Campaign surge recommendation popup, authorize checkbox/button |

---

## Performance Monitoring

The module instruments key user journeys using APMS (via MDAP `customReporter.sendData`). Metric points are defined in `src/metric/metricMdap.ts`:

| Metric Key | Point ID | Description |
|-----------|---------|-------------|
| `LEFT_MENU_TO_ADS_MODULE` | `dadbf4325384ec1a810b3631eb3b14a3` | Time from sidebar click to module enter |
| `MARKETING_LOAD_MEASURE` | `cf8e2439755340de965d73062ca85055` | Time from module enter to homepage enter |
| `MARKETING_LOAD_MEASURE_TOTAL` | `945a9b28cf98e3d1f1010a3e0f278995` | Full load time (first cold load only) |
| `ADS_LISTPAGE_FROM_ROUTER_TO_PAGE` | `952654b35cd8ab5f87bf818225eb52c5` | Router enter to Index.vue mounted |
| `ADS_LISTPAGE_CAMPAIGN_EXPENSE_API` | `cadda73eba35ad8a3ccab690f7491d1f` | Campaign expense API response time |
| `ADS_LISTPAGE_CAMPAIGN_STATISTICS_API` | `f60eaad1c284ac1a4106435621ade2b5` | Campaign statistics API response time |
| `ADS_LISTPAGE_FROM_ROUTER_TO_TABLE_API` | `ca204ee1e96d7f8164c664e0c4298be3` | Router to first table API call |
| `ADS_LISTPAGE_FROM_ROUTER_TO_TABLE_RENDERED` | `91e1ce48f5fba80e93438ec394472d21` | Router to table fully rendered |
| `ADS_LEFT_MENU_CAMPAIGN_LIST_API` | `4e52f8509fb24950b15b7fe6a04d7021` | Left menu campaign list API (deprecated) |
| `ADS_LIST_PAGE_FROM_ROUTER_TO_LEFT_MENU_API` | `b710978f1bab3851e6cdd47251da8d95` | Router to left menu API |
| `ADS_LEFT_MENU_FROM_ROUTER_TO_MENU_RENDERED` | `02af73a8ca87403fe264729eebc7b365` | Router to left menu rendered |
| `ADS_LIST_PAGE_LINECHART_API` | `d261d56f09ed6eb648bed80761acc317` | Homepage line chart API response |
| `ADS_LIST_PAGE_FROM_ROUTER_TO_LINECHART_API` | `25d71975394da8ae7a994b001c06609b` | Router to line chart API |
| `ADS_LIST_PAGE_FROM_ROUTER_TO_LINECHART_RENDERED` | `500f903eca724bd88983d08cf1151f79` | Router to line chart rendered |

Measurements use the browser `performance.mark` / `performance.measure` API. Each metric is reported only once per session (`onlyCountOnce: true`).

---

## Business Terminology Glossary

| Term | Full Name | Definition |
|------|-----------|------------|
| **Ads GMV** | Ads Gross Merchandise Value | Total sales generated from ads. Attributed when a user purchases within 7 days of an ad click. |
| **CTR** | Click-Through Rate | Total ad clicks / total impressions |
| **CPC** | Cost Per Click | Amount spent per ad click |
| **CR** | Conversion Rate | Ad orders / total clicks on the ad |
| **ROAS** | Return on Ad Spending | Ads GMV / Ads Revenue (synonym of ROI) |
| **ROI** | Return on Investment | Ad GMV / Ad Expenditure |
| **CIR** | Cost-Income Ratio | Ads Revenue / Ads GMV |
| **CPM** | Cost Per Mille | Cost per 1,000 ad impressions |
| **ECPM** | Effective Cost per Mille | Total Ad Spend / Total impressions |
| **QSS** | QuickStart Service | Service to help new advertisers quickly ramp up ad usage |
| **SRM** | Seller Relationship Management | End-to-end seller management for advertising teams |
| **SC** | Seller Center | Platform for sellers to manage ads, products, etc. |
| **PDP** | Product Detail Page | Individual product page on Shopee |
| **DD** | Daily Discovery | "Daily Discover" ad placement at bottom of main site |
| **YMAL** | You May Also Like | Ad placement below product detail pages |
| **CPS** | Cost Per Sale | Pay-per-sale billing model (seller pays only on purchase) |
| **GMV Max** | — | Auto-bidding ad product (Target2.0 / Simple2.0) for optimized ROAS |
| **NPB** | New Product Boost | Ads feature giving exclusive traffic to newly listed products |
| **NPA** | New Product Ads | Todo items for potential new product ads |
| **TADS** | Targeting Ads | Discovery ads for reaching specific buyer segments |
| **Whitelist** | — | Feature flag enabling specific sellers to access new ad features |
| **Cold Start** | — | Ads with insufficient data for accurate system predictions |
| **Advv** | Advertiser Value | Long-term revenue increase measurement for the platform |
| **Take-Rate** | — | Ads Revenue / Platform GMV; measures platform monetization effectiveness |
| **ACP** | Ads Credit Package | Discounted top-up package with free ad credits |
| **ATU** | Auto Top-Up | Automatic balance top-up when credit falls below threshold |
| **GMS** | GMV Max Simple | Simple fixed spending program for product ads |
| **OCPM** | Optimized Cost Per Mille | Optimized bidding model based on impressions |
| **FSS** | Fee Subsidy Service | Fee waiver program where eligible sellers receive ad fee waivers by maintaining a target take-rate (Spending ÷ GMV) |
| **SIP** | Shopee International Platform | Cross-border e-commerce platform |
| **COD** | Cash on Delivery | Payment method where buyer pays upon delivery |

---

## References

- **Project GitLab Repository**: https://git.garena.com/shopee/isfe/ao/pas-index
- **MMC CLI Docs**: https://seller-portal.i.test.shopee.io/mmc-docs/guide/getting-started.html
- **MMC Development Guide**: https://seller-portal.i.test.shopee.io/mmc-docs/guide/basic/development.html
- **MMF Build & Release**: https://seller-portal.i.test.shopee.io/docs/pages/seller-portal/build-and-release.html
- **Seller Portal Build Page**: https://seller-portal.i.shopee.io/build/modules-group
- **USF Architecture Overview**: https://confluence.shopee.io/display/SPAD/%5BUltimate+Setup+Flow%5D%5BTD%5D+Architecture+Overview
- **USF Homepage TD**: https://confluence.shopee.io/display/SPAD/%5BUltimate+Setup+Flow%5D%5BTD%5D+Home+Page
- **Paid Ads Glossary**: https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPAD&title=Paid+Ads+Glossary
- **Ads Platform Overview (SRA)**: https://sra.test.shopee.io/05.Business_Systems/5.3_Ads_Business_and_Architecture_Introduction/5.3.6._ads.platform.html
- **Pas Helper Chrome Extension**: https://chromewebstore.google.com/detail/pas-helper/nhfhjiehemipamajmeimnnkinhncgpcd
- **Seller Center Test (SG)**: https://seller.test.shopee.sg

---

## Frequently Asked Questions

**1. How do I start local development for the first time?**
Run `yarn run init` (select `local-seller-center`), then `yarn dev`. Open the test Seller Center URL in your browser, open DevTools, and run `mmfDevtools.enable()` to connect to your local dev server.

**2. What is the relationship between `pas-index` and the Ultimate Setup Flow (USF)?**
In USF, `pas-index` hosts the **homepage**, **top-up page**, **wallet page**, **to-do list**, **rewards center**, **campaign budget recommendation**, **fee waiver program (FSS)**, and **campaign accelerator** pages. Ad creation and detail pages are separate MMC modules. Old flow had all sub-pages inside this project. New features should always target the USF.

**3. Why can't I import directly from `eds-vue`?**
All EDS Vue components must be imported through `pas-common/eds-vue` to ensure consistent versioning and bundle optimization across the ads platform modules. Direct imports from `eds-vue` are prohibited.

**4. How do I add a new modal/prompt to the homepage?**
Follow the Prompts Management System: (1) Add a new `PromptId` to the enum in `src/pages/homepage/utils/prompt-actions/types.ts`; (2) Add it to the appropriate trigger array (`urlTriggeredPrompts` or `apiTriggeredPrompts`) in `usePromptsQueue`; (3) Implement the action function with cleanup logic. Only one prompt shows at a time.

**5. How do I deploy to a specific environment with a PFB?**
In the Seller Portal Build page, select your branch, enable Auto Publish, select both `local-seller-center` and `cb-seller-center` portals, all regions, and fill in the **PFB 2.0** field with your PFB name. Click **Build & Publish**.

**6. What does `feature-flags.js` control?**
It defines region-specific feature flags. For example, `uiAdsTutorialVideos` is enabled only for TW, MY, VN, and SG by default. This file is consumed by the MMC framework to conditionally enable features per region.

**7. How do I add a new tracking event?**
Add a named export in `src/track/index.ts` from the appropriate `pas-common/tracking/entries/*` file. Use `export *` only for `sellerCenterShopeeAds` and `sellerCenterAdsCampaignPage`. For all other tracking entry files, use named exports for tree-shaking.

**8. What happens when a seller is in holiday mode?**
The `beforeEnter` router guard detects `app.user.holidayMode`. If true, it shows a confirmation modal asking the seller to exit holiday mode (redirects to `/portal/settings/shop/general`) or go back to the portal root. Entry to the ads module is blocked.

**9. How does the Fee Waiver Program (FSS) page work?**
The FSS page is a standalone route at `/portal/marketing/pas/fee-waiver-program`. On load, it calls `/fss_program/get/` to check eligibility and fetch take-rate progress. Non-eligible sellers are redirected to the homepage. Eligible sellers see their current take-rate (Spending ÷ GMV) against a target, with action suggestions. The page is accessible from the CMT campaign page with `?type=FSS_FEE_WAIVER_PROGRAM`.

**10. How does the Campaign Accelerator page work?**
The Campaign Accelerator page is a standalone route at `/portal/marketing/pas/campaign-accelerator`. It is gated by the `szAdsCampaignAccelerator` feature flag — if unavailable, the user is redirected to the homepage. The page calls `/campaign_accelerator/get/` to fetch the current package and user settings. Sellers can sign up during the sign-up period, which triggers a fee-rate/ROI configuration modal followed by an optional auto-escrow setup. After sign-up, the page shows the `PostSignUp` view.

<!-- Generated by ads-workspace/skills/ads-readme-generate | checked: f9a9f96383ca71663d2eab3400ae57ca7a6b2d8c | spec: 76fce5f679f9550b -->
