<!-- ads-workspace-gdoc-sync: gdoc_id=1fT3okdvN--wv40ExSEEXY7HHdSe09xVJ0sv1TV7JuQQ gdoc_url=https://docs.google.com/document/d/1fT3okdvN--wv40ExSEEXY7HHdSe09xVJ0sv1TV7JuQQ/edit -->

# pas-livestream

## Table of Contents

- [Project Overview](#project-overview)
- [Key Features](#key-features)
- [Project Architecture](#project-architecture)
- [Directory Structure](#directory-structure)
- [Development Guidelines](#development-guidelines)
  - [Code Style](#code-style)
  - [Project Structure](#project-structure)
  - [Naming Conventions](#naming-conventions)
  - [Error Handling](#error-handling)
  - [Unit Testing](#unit-testing)
  - [Code Review & Git Workflow](#code-review--git-workflow)
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

`pas-livestream` is a Vue 3 + TypeScript micro-frontend module for Shopee Ads that enables sellers to create, manage, and analyze Live Stream Ads campaigns within the Seller Center platform. Built on the Multi-Module Framework (MMC/MMF) architecture, it consumes shared utilities and components from `pas-common` via Webpack Module Federation, and runs exclusively inside the Seller Center portal.

---

## Key Features

- **Live Stream Ads Creation**: Multi-step creation flow supporting two bidding objectives — Max GMV (`MAX_GMV`) and Max Views (`MAX_VIEWS`).
- **Restart Flow**: Reuse the same creation page component to restart ended campaigns with pre-populated fields from the existing campaign.
- **Restart Min Budget Banner**: When restarting a campaign, `getBudgetForCreation` now returns both `recommended` budget and `minBudget` (sourced from `GetBudgetForCreationRes.dailyBudget.min` / `.minBudget`). If the previous daily budget is below this API-fetched minimum, the Basic Settings form shows a warning `EdsAlert` banner. The effective minimum used for budget input validation switches to `restartApiMinBudget` when available.
- **Target ROAS Configuration**: Optional Target ROAS input for Max GMV objective, with ROAS recommendation fetched from backend.
- **ROI Two Mode (Max GMV ROI Two / Max View ROI Two)**: Feature-toggle-gated mode converting Max GMV / Max Views campaigns to `MAX_GMV_ROI_TWO` / `MAX_VIEW_ROI_TWO` objectives upon publish. Controlled by `adsToggle.liveStreamAds` and `adsToggle.liveStreamAdsViewMax` from `/meta/get/`.
- **Ads Detail Page**: View and edit campaign budget, duration (time slot), and ROAS target; includes budget and time warning banners.
- **Budget Edit Min Budget Prompt**: Inside `BudgetEditPopover` on the detail page, an `EdsAlert` is shown (`showMinBudgetPrompt`) when the current campaign budget falls below `latestMinBudget` (fetched from `/setup_helper/get_budget_data_for_edit/`). The popover receives `latestMinBudget || minBudgetFinal` as its effective `minBudget` prop.
- **Performance Chart & Table**: Daily metric time-series charts and aggregated report tables powered by the shared report API.
- **Paid GMV / Placed GMV Metric Tab**: When `extToggle.szSupportPaidGmvMetrics` is enabled, the performance chart and table display a tab switcher between Paid GMV and Placed GMV metrics. Paid GMV date range is constrained to on or after `scConfig.paidGmvPhaseOneReleaseDate`. Both chart and table pass `usePaidGmv: true` to the report API when Paid GMV tab is active.
- **Estimated GMV / Views**: Real-time estimated performance range shown on the creation page, conditioned on budget and time inputs.
- **Active Campaign Threshold Check**: Prevents creation when the seller has too many active live stream ads.
- **ROI Two Overlap Detection**: Warns if a newly created or restarted campaign's schedule overlaps with an existing ROI Two campaign.
- **ROI Two ROAS Editing (Upgrade Modal)**: When `enableSimpleRoiTwo` is active, editing the ROI Two target on the detail page opens `RoiUpgradeModal` instead of the standard `RoiModal`.
- **ROAS Edit Min Budget Prompt**: Both `RoiModal` and `RoiUpgradeModal` display a min budget prompt (`targetRoasMinBudgetPromptText`) via the `#extra-alert` slot when `showTargetRoasMinBudgetPrompt` is true. The latest minimum is fetched by `fetchTargetRoasMinBudget()` in `performance-table/index.vue` via `getCampaignExpense` (`/setup_helper/get_budget_data_for_edit/`). Also passed as `:extra-alert-text` prop to `RoasModal`.
- **Food Streamer Editing Restriction (V2)**: When `szAdsLiveLimitFoodSellerTwo` feature is active, sellers whose `liveStreamAccount.streamerTypeList` contains `FOOD` but not `MP` cannot edit their ROAS target. The edit control shows a tooltip (`live_ads_food_streamer_deboost_tip_pc_hover`).
- **Feature Toggles**:
  - `metaConfig.adsToggle.liveStreamAds` — enables ROI Two mode, Target ROAS editing, and most creation/detail page features (sourced from `/meta/get/`)
  - `metaConfig.adsToggle.liveStreamAdsViewMax` — enables Max View ROI Two objective (sourced from `/meta/get/`)
  - `metaNonAdsConfig.extToggle.szSupportPaidGmvMetrics` — enables Paid GMV metric tab (sourced from `/meta/get_non_ads_data/`)
  - `metaNonAdsConfig.extToggle.szAutoBudgetIncrease` — auto budget increase feature
  - `app.features?.support("szAdsLiveLimitFoodSellerTwo")` — food streamer ROAS editing restriction
- **Page Session Tracking**: A UUID-based page session ID is generated on each navigation and stored in `localStorage` under `SELLER_CENTER_SHOPEE_ADS_PAGE_SESSION_ID`.

---

## Project Architecture

```
Seller Center Portal (SC)
        │
        ▼
  MMF Runtime (Module Federation)
        │
        ├─── pas-livestream  ←── this module
        │         │
        │         ├── Webpack Module Federation Consumer
        │         └── Shares runtime with pas-common (types, utils, components)
        │
        └─── pas-common (MF Provider)
                  ├── Shared types/utils/components
                  └── Tracking definitions
```

**Technology Stack**

| Layer | Technology |
|---|---|
| Framework | Vue 3 Composition API (`<script setup>`) |
| Language | TypeScript (strict) |
| Build Tool | MMC (Multi-Module CLI) v3, Webpack 5 / Rsbuild |
| Module Federation | Shared with `pas-common` (types, utils, components) |
| UI Library | EDS Vue (`eds-vue` v5) |
| Package Manager | Yarn |
| Styling | SCSS (scoped per component) |
| State Management | `reactive()` singletons (no Vuex/Pinia) |
| Routing | `framework` router via `app.registerRouterModule` |

**Module ID**: `282` (registered in Seller Portal under type `module`, tech `vue3`).

**Route Prefix**: All routes are nested under `/portal/marketing/pas/live-stream/`.

| Route Name | Path | Component |
|---|---|---|
| `PAS_LIVE_STREAM_ADS_INDEX_PAGE` | `/portal/marketing/pas/live-stream/` | `src/pages/index.vue` |
| `PAS_LIVE_STREAM_ADS_CREATE_PAGE` | `create` | `src/pages/create/index.vue` |
| `PAS_LIVE_STREAM_ADS_RESTART_PAGE` | `restart/:campaignId` | `src/pages/create/index.vue` |
| `PAS_LIVE_STREAM_ADS_DETAIL_PAGE` | `detail/:campaignId` | `src/pages/detail/index.vue` |

**Detail Page Metric Tab**: When `szSupportPaidGmvMetrics` is enabled, the detail page maintains a `metricTab` state (`MetricType.PAID_GMV` or `MetricType.PLACED_GMV`). The tab automatically switches to `PLACED_GMV` when the selected date range starts before `paidGmvPhaseOneReleaseDate`.

---

## Directory Structure

```
pas-livestream/
├── mmc.config.js                   # MMC build configuration (module ID, webpack extends)
├── package.json                    # Dependencies and scripts
├── .gitlab-ci.yml                  # CI/CD pipeline (lint, e2e, deploy)
├── config/
│   └── .remote-config.json         # Auto-generated by `yarn run init`; local router/params override
└── src/
    ├── index.ts                    # Module entry: registers router, sets EDS locale
    ├── custom.d.ts                 # TypeScript ambient declarations
    ├── track/
    │   └── index.ts                # Re-exports all tracking functions from pas-common
    ├── pages/
    │   ├── index.vue               # Router-view root (registers tracking directive, event map)
    │   ├── utils.ts                # Shared page utilities (e.g., openOperationLimitModal)
    │   ├── create/                 # Creation & Restart page
    │   │   ├── index.vue           # Main create/restart page component
    │   │   ├── constant.ts         # Form init state, validation rules, overlap modal logic
    │   │   ├── types.ts            # FormInstance, FormInstantInject types
    │   │   ├── basic-setting/      # Campaign name, date, budget inputs
    │   │   │   ├── date-picker-selection/
    │   │   │   └── time-picker-selection/
    │   │   ├── bidding-strategy/   # Objective selection (Max GMV / Max Views)
    │   │   │   └── target-roas/    # Target ROAS configuration sub-step
    │   │   ├── skeletor/           # Loading skeleton for create page
    │   │   ├── tab-selection/      # Tab-based objective selection UI
    │   │   ├── limitation-prompt/  # Modal shown when active ad threshold exceeded
    │   │   └── publish-result/     # Success result page after publishing
    │   └── detail/                 # Campaign detail page
    │       ├── index.vue           # Main detail page component (manages metricTab state)
    │       ├── basic-campaign-info/ # Campaign info cards (name, state, budget, time slot)
    │       │   ├── budget-warning-banner/
    │       │   └── time-length-picker/
    │       ├── performance-chart/  # Time-series chart with GmvMetricSwitch
    │       ├── performance-table/  # Aggregated metrics table with ROAS edit
    │       │   └── roas-warning/
    │       └── skeletor/           # Loading skeleton for detail page
    └── _shared/                    # Code shared across all pages
        ├── api/
        │   ├── common/             # Meta, config, banner APIs
        │   ├── live-stream/        # Campaign CRUD and publish APIs
        │   ├── report/             # Performance metrics APIs
        │   └── request/            # Base request factory (commonRequest)
        ├── assets/
        │   ├── image/              # PNG assets (avatar, bidding strategy icons)
        │   └── svg/                # SVG icons (alert, info, close)
        ├── components/
        │   ├── back-button/        # Navigation back button
        │   └── time-picker-range/  # Custom time-of-day range picker (HH:MM)
        ├── composable/
        │   ├── use-creation-budget.ts   # Budget min/max computation and toast logic
        │   ├── use-duration.ts          # Report date-range state and remote cache sync
        │   ├── use-route.ts             # Route params and query helpers
        │   └── useSelectMetrics.ts      # Metrics column selection logic
        ├── constants/
        │   ├── api.ts              # All API endpoint paths
        │   ├── app-config.ts       # Time constants (ONE_HOUR, ONE_DAY, etc.)
        │   ├── campaign.ts         # MaxDate, ColdStartPhaseTrait
        │   ├── metric-item.ts      # Metric display item definitions
        │   ├── metrics-field.ts    # Metric field key definitions
        │   └── router.ts           # RouterMap enum, RouterPath, performance mark helpers
        ├── store/
        │   ├── config/
        │   │   ├── contantine.ts   # Configuration store (adsConfig, currency, etc.)
        │   │   ├── meta.ts         # Ads meta store (adsCredit, hasAds, liveStreamAccount, adsToggle)
        │   │   └── meta-non-ads.ts # Feature toggle store (extToggle flags)
        │   └── report/             # Report date range and load status store
        ├── styles/
        │   └── page.scss           # Global page styles (injected via webpack injectStyle)
        ├── types/
        │   ├── campaign.ts         # CampaignInfo, LiveAdsCampaignInfo, Objective, TimeSlot
        │   └── index.ts            # Re-exports
        └── utils/
            ├── date-range.ts       # Date range helpers
            ├── report.tsx          # Report formatting utilities
            ├── router.ts           # URL query param update helper
            ├── target-roas.ts      # Target ROAS calculation helpers
            └── time.ts             # Time formatting and request/response conversion
```

---

## Development Guidelines

### Code Style

| Tool | Config |
|---|---|
| TypeScript | Strict mode; type-like identifiers (`class`, `interface`, `enum`) must be `PascalCase` or `UPPER_CASE` (enforced via `.eslintrc.js`) |
| ESLint | Extends `@shopee/pas-module-config/src/eslint/vue` (`.eslintrc.js`) |
| Stylelint | Extends MMC-managed `.stylelintrc.json` (overwritten on `yarn run init`) |
| Prettier | Extends `@shopee/pas-module-config/src/prettier/index` (`.prettierrc.js`) |

Pre-commit hooks (Husky + lint-staged) auto-run Prettier + ESLint + Stylelint on staged `src/**/*.{ts,vue,css,scss,less}` files before every commit.

### Project Structure

- **Pages** (`src/pages/`): Route-level components. Each route directory (`create/`, `detail/`) owns its child components, constants, and types.
- **Shared code** (`src/_shared/`): API clients, composable functions, constants, store singletons, types, and utilities used across all pages.
- **State management**: `reactive()` singletons (no Vuex/Pinia). Three stores: `Constantine` (config from `/config/get/`), `metaConfig` (ads meta + `adsToggle`), `metaNonAdsConfig` (`extToggle` feature flags).
- **Composables**: Reusable Vue 3 composable functions in `src/_shared/composable/`; naming pattern `use-*.ts`.

### Naming Conventions

- **Type-like identifiers**: `PascalCase` or `UPPER_CASE` (ESLint `@typescript-eslint/naming-convention` rule, `typeLike` selector).
- **Composable files**: `use-*.ts` prefix (kebab-case).
- **Tracking functions**: follow `pas-common/tracking/entries/` naming pattern; never define tracking functions inside `pas-livestream`.
- **Commit messages**: conventional commit format enforced by `commitlint` extending `@shopee/pas-module-config`.

### Error Handling

- **Publish errors**: handled via `PublishErrorCode` enum (`src/_shared/api/live-stream/types.ts`). Codes `DUPLICATE_NAME`, `HAS_EXCEEDED_AD_THRESHOLD`, `CAMPAIGN_LEVEL_RATE_LIMIT`, and `PARTIAL_ERROR` each trigger distinct UI feedback.
- **Edit errors**: `editCampaignInfo` uses `skipError: true` and manually dispatches `openOperationLimitModal` for `CAMPAIGN_LEVEL_RATE_LIMIT` or `EdsToastInstance.error` for generic failures.
- **Debounced functions**: must be cancelled in `onBeforeUnmount` to prevent memory leaks (pattern established in `basic-setting/index.vue`).

### Unit Testing

There are no unit tests in the repository. Functional correctness is verified through E2E tests in `pas-e2e-tests`, triggered by CI on merge requests to `master`/`release` (identified by tag `@pas-livestream`).

### Code Review & Git Workflow

- **Pre-commit**: Husky runs lint-staged — Prettier + ESLint auto-fix on `*.{ts,vue}`; Prettier + Stylelint auto-fix on `*.{css,scss,less,vue}`.
- **CI stages**: `lint` → `e2e_tests` → `release_verify` → `auto_deploy_test` → `auto_deploy_e2e_tests` (see `.gitlab-ci.yml`).
- **Run checks locally before pushing**: `yarn lint && yarn type:check`.

---

## Quick Start

### Prerequisites
|---|---|
| Node.js | >= 16.14.0 (Node 20 recommended) |
| pnpm | >= 8.0.0 (pnpm 8 recommended) |
| MMC (Multi-Module CLI) | Latest v3.x |
| Yarn | Any (used as project package manager) |

**Install MMC globally (required before first use):**

```bash
pnpm i -g @shopee/multi-module-cli

# Run setup after install (one-time)
mmc setup

# Verify installation (should display 4 version lines)
mmc -V
```

### Configuration

MMC reads module configuration from `mmc.config.js`. The key fields are:

```js
// mmc.config.js
module.exports = {
  id: 282,        // Module ID registered in Seller Portal
  type: "module",
  tech: "vue3",
  injectStyle: {
    scss: { inject: ["src/_shared/styles/page.scss"] },
  },
  // webpack and rsbuild extend via @shopee/pas-module-config
};
```

After running `yarn run init`, MMC auto-generates `config/.remote-config.json` with the router and params pulled from the Seller Portal test environment. You can edit `router` and `params` in this file to override local development routing — but note this file is **overwritten** on each `yarn run init`.

### Installation

Run `yarn run init` **once** before starting development (or after cleaning the project). This installs dependencies, fetches portal configuration, and generates required config files.

```bash
# Install dependencies for Seller Center (portal ID 21)
yarn run init -p 21
```

> **Warning:** Running `yarn run init` overwrites `.browserslistrc`, `.stylelintrc.json`, and `tsconfig.json` with MMC-managed versions.

### Build

```bash
# Local build (outputs to dist/)
yarn build
```

For production builds, use [Seller Portal](https://seller-portal.i.shopee.io/) to trigger the build pipeline (see [Deployment](#deployment)).

### Local Development

**Step 1 — Start the dev server**

```bash
# Default: uses local pas-common dev server (pas-common must be running locally)
yarn dev

# Remote mode: loads pas-common types from remote master branch
yarn dev:remote

# Quick start: init + remote dev in one command
yarn start

# Remote mode with specific pas-common branch
LOCAL_DEV=1 branchName='<feature-branch>' mmc dev
```

> If you run `yarn dev` without a local pas-common server running, you will see:
> ```
> [FederatedTypesPlugin] Unable to download 'pas-common' remote types index file: connect ECONNREFUSED 127.0.0.1:8001
> ```
> Use `yarn dev:remote` instead, or start the local pas-common server first.

**Step 2 — Open the Seller Center test environment**

Navigate to the Seller Center test environment for your region (e.g., `https://seller.test.shopee.sg`). Use the [Pas Helper Chrome Extension](https://chromewebstore.google.com/detail/pas-helper/nhfhjiehemipamajmeimnnkinhncgpcd) for one-click login with test accounts.

**Step 3 — Connect to your local dev server**

Open DevTools in the browser and run:

```js
mmfDevtools.enable()
```

Or use the **MMF DevTools** UI (toolbar icon in the SC page). After enabling, reload the page — the browser will load resources from your local dev server. The console will show `[MMF_DEVTOOLS]` output and `[HMR] connected` when the dev server is successfully connected.

### Development

**Working with pas-common**

When modifying `pas-common`, start the pas-common local dev server first, then use `yarn dev` to load local types. For read-only consumption of pas-common's master branch, use `yarn dev:remote`.

**Type checking (watch mode)**

```bash
# Already included in `yarn dev` via concurrently
vue-tsc -w --noEmit --pretty

# One-off type check
yarn type:check
```

**Linting**

```bash
yarn lint          # ESLint + Stylelint
yarn lint:es:fix   # Auto-fix ESLint issues
yarn lint:style:fix # Auto-fix Stylelint issues
yarn prettier      # Format with Prettier
```

### Deployment

Production build and release are managed through [Seller Portal](https://seller-portal.i.shopee.io/):

1. Navigate to the module group for `pas-livestream` (module ID `282`).
2. Fill out the build information form and click **Build**.
3. Once the build succeeds, click **Publish** in the Action column.
4. In the release form, select the target portal, PFB, and regions, then click **Publish**.

**CI/CD Pipeline** (`.gitlab-ci.yml`):

| Stage | Job | Trigger | Description |
|---|---|---|---|
| `lint` | `lint` | Merge request | Runs `yarn lint` (ESLint + Stylelint) |
| `parallel_jobs` | `ai-code-review` | Merge request | AI-powered code review |
| `e2e_tests` | `e2e_tests` | Merge request to master/release | Triggers `pas-e2e-tests` with tag `@pas-livestream` |
| `release_verify` | `release_verify` | Merge request | Verifies release via deploy-platform API |
| `auto_deploy` | `auto_deploy_test` | Push to master/release (merge commits) | Auto-deploys to test env on PFB `pfb-ads-platform-e2e` |
| `auto_deploy` | `auto_deploy_uat` | Push to master | Auto-deploys to UAT env |
| `auto_deploy_e2e` | `auto_deploy_e2e_tests` | After `auto_deploy_test` | Triggers E2E tests post-deploy |

```bash
# CI/CD automated release (used in CI pipeline)
yarn deploy:ci
```

> **Offline Mode**: To take the module offline, toggle "Offline Mode" before building and releasing. Once released in offline mode, the module's routes will be inaccessible.

---

## API Documentation

All API endpoints are defined in `src/_shared/constants/api.ts` as `export const API = { ... } as const`. The request factory in `src/_shared/api/request/index.ts` lazily creates a `commonRequest` instance from `pas-common/request`, which handles base URL routing internally.

### Endpoint Reference

| Page | Page URL | API Endpoint | Description |
|---|---|---|---|
| All | `/portal/marketing/pas/live-stream/` | `/meta/get/` | Fetches ads credit, adsToggle flags, hasAds, and live stream account info |
| All | `/portal/marketing/pas/live-stream/` | `/meta/get_non_ads_data/` | Fetches extToggle feature flags (e.g., `szSupportPaidGmvMetrics`) |
| All | `/portal/marketing/pas/live-stream/` | `/config/get/` | Fetches Constantine configuration (budget limits, ROAS settings, currency, scConfig) |
| All | `/portal/marketing/pas/live-stream/` | `/report/get_config/` | Fetches report time range configuration |
| All | `/portal/marketing/pas/live-stream/` | `/banner/get/` | Fetches banner display state (e.g., ROI Two creation page banner, time selector prompt) |
| All | `/portal/marketing/pas/live-stream/` | `/banner/modify/` | Updates global banner action |
| All | `/portal/marketing/pas/live-stream/` | `/banner/campaign_get/` | Fetches per-campaign banner state |
| All | `/portal/marketing/pas/live-stream/` | `/banner/campaign_modify/` | Updates campaign-level banner action |
| Create / Restart | `.../live-stream/create` | `/live_stream/get_setup_status/` | Fetches default campaign name for creation |
| Create / Restart | `.../live-stream/create` | `/live_stream/publish/` | Creates or restarts a live stream ad campaign |
| Create / Restart | `.../live-stream/create` | `/live_stream/get_estimated_data/` | Fetches estimated GMV range for given budget and time settings |
| Create / Restart | `.../live-stream/create` | `/live_stream/get_budget_data_for_creation/` | Fetches recommended budget and minimum budget for creation/restart. Returns `{ recommended, minBudget }` (sourced from `dailyBudget.min` / `dailyBudget.minBudget`). `minBudget` drives the effective minimum during the restart flow |
| Create / Restart | `.../live-stream/create` | `/live_stream/check_active_campaign_threshold/` | Checks if seller has exceeded active campaign threshold |
| Create / Restart | `.../live-stream/create` | `/live_stream/check_overlapping_ads_for_roi_two/` | Checks for schedule overlap with existing ROI Two campaigns |
| Create / Restart | `.../live-stream/create` | `/setup_helper/get_recommended_target_roi/` | Fetches recommended Target ROAS value with percentile bounds |
| Detail | `.../live-stream/detail/:campaignId` | `/live_stream/get/` | Fetches campaign detail by `campaignId` |
| Detail | `.../live-stream/detail/:campaignId` | `/live_stream/edit/` | Edits budget, time slot, ROAS target, or ROI Two target of an existing campaign |
| Detail | `.../live-stream/detail/:campaignId` | `/setup_helper/get_budget_data_for_edit/` | Fetches budget constraint data for editing. Used by `basic-campaign-info` (to get `latestMinBudget` for budget edit popover) and by `performance-table` via `fetchTargetRoasMinBudget()` (to get min budget for ROAS edit modals) |
| Detail | `.../live-stream/detail/:campaignId` | `/report/get/` | Fetches aggregated performance metrics for the performance table (accepts `usePaidGmv`) |
| Detail | `.../live-stream/detail/:campaignId` | `/report/get_time_graph/` | Fetches time-series performance data for the chart (accepts `usePaidGmv`) |
| Detail | `.../live-stream/detail/:campaignId` | `/report/update_time_config/` | Persists user-selected date range to backend |
| Detail | `.../live-stream/detail/:campaignId` | `/report/update_selected_metric_config/` | Persists user-selected metric columns to backend |

**Number Conversion**: Backend inflates numeric values by 10^5 to avoid floating point issues. Use `convertServerNumber` (÷100,000) when reading API responses and `convertClientNumber` (×100,000) when sending requests. Both are imported from `pas-common/utils`.

**Request Factory**: All API calls use `commonRequest` from `src/_shared/api/request/index.ts`, which lazily loads and wraps the framework HTTP client with type safety via generics:
```typescript
commonRequest<RequestType, ResponseType>(endpoint, { params, skipError? })
```

**Paid GMV API Parameter**: When the Paid GMV metric tab is active (`metricTab === MetricType.PAID_GMV`), both `getTimeGraph` and `getReport` include `usePaidGmv: true` in the request body to receive paid GMV-based metrics from the backend.

---

## Local Storage

| Key | Value | Set By | Description |
|---|---|---|---|
| `SELLER_CENTER_SHOPEE_ADS_PAGE_SESSION_ID` | UUID v4 string | `src/_shared/router/index.ts` | Generated on each route navigation under `/portal/marketing/pas/`. Used for page session tracking in analytics events. Regenerated on page refresh or path change; unchanged for same-path operations (form submit, data refresh). |

---

## TMS Tracking

All tracking functions are re-exported from `pas-common` tracking entries in `src/track/index.ts`:

```typescript
// src/track/index.ts
export * from "pas-common/tracking/entries/sellerCenterLivestreamAdDetail";
export * from "pas-common/tracking/entries/createLiveAds";
export * from "pas-common/tracking/entries/sellerCenterShopeeAds";
export * from "pas-common/tracking/entries/sellerCenterRestartLivestreamAd";
export * from "pas-common/tracking/entries/sellerCenterCreateLiveAds";
```

**Convention**: Always import tracking functions from `src/track` (not directly from `pas-common`). Do not define new tracking functions inside `pas-livestream` — add them to `pas-common` tracking entries first.

**Common tracking events used across the module:**

| Event Type | Function Name | Trigger |
|---|---|---|
| View | `reportViewOfSCCreateLiveAds` | Create page mounted |
| View | `reportViewOfSCRestartLivestreamAd` | Restart page mounted |
| View | `reportViewOfSCLivestreamAdDtl` | Detail page mounted |
| Click | `reportClickOfCreateLiveAdsBottomActionLiveAdsPublish` | Publish button clicked |
| Click | `reportClickOfCreateLiveAdsBottomActionLiveAdsCancel` | Cancel button clicked |
| Impression | `reportImpOfSCLivestreamAdDtlPerfPerf` | Performance chart visible |
| Click | `reportClickOfSCLivestreamAdDtlPerfGmvDefinitionSelection` | GMV metric tab switched |
| Impression | `reportImpOfSCLivestreamAdDtlPerfGmvDefinitionSelection` | Detail page mounted (initial metric tab state) |
| Impression | `reportImpOfSCLivestreamAdDtlTimeSelectorPromptTimeSelectorPrompt` | Date range prompt shown |
| Click | `reportClickOfSCLivestreamAdDtlTimeSelectorPromptGotIt` | Date range prompt dismissed |

**`v-track-impression` directive**: Registered globally in `src/pages/index.vue` via `useTrackingDirective()` from `pas-common/tracking`. Used as:
```vue
<PerformanceChart v-track-impression="reportImpFn" />
```

---

## Performance Monitoring

The module uses the browser [Performance API](https://developer.mozilla.org/en-US/docs/Web/API/Performance) to measure page load times. Performance marks and measurements are defined in `src/_shared/constants/router.ts`.

**Performance Marks**

| Constant | Mark Name | Set When |
|---|---|---|
| `PERFORMANCE_MARK_INDEX_ENTER` | `pas_livestream_ads_index_enter` | Root route `beforeEnter` |
| `PERFORMANCE_MARK_CREATE_ENTER` | `pas_livestream_ads_create_enter` | Create/Restart route `beforeEnter` |
| `PERFORMANCE_MARK_DETAIL_ENTER` | `pas_livestream_ads_detail_enter` | Detail route `beforeEnter` |
| `PERFORMANCE_MARK_CREATE_MOUNTED` | `pas_livestream_ads_create_mounted` | Create page `onMounted` |
| `PERFORMANCE_MARK_DETAIL_MOUNTED` | `pas_livestream_ads_detail_mounted` | Detail page `onMounted` |

**Performance Measures**

| Measure Name | From Mark | To Mark | Meaning |
|---|---|---|---|
| `module_enter_to_create` | `_index_enter` | `_create_enter` | Time from module entry to create route enter |
| `create_enter_to_mounted` | `_create_enter` | `_create_mounted` | Time from create route enter to component mount |
| `module_enter_to_create_mounted` | `_index_enter` | `_create_mounted` | Total time from module entry to create page ready |
| `module_enter_to_detail` | `_index_enter` | `_detail_enter` | Time from module entry to detail route enter |
| `detail_enter_to_mounted` | `_detail_enter` | `_detail_mounted` | Time from detail route enter to component mount |
| `module_enter_to_detail_mounted` | `_index_enter` | `_detail_mounted` | Total time from module entry to detail page ready |

**Measurement Functions**

```typescript
generateCreatePerformanceData()   // Returns { moduleToEnter, enterToMounted, moduleToMounted } in ms
generateDetailPerformanceData()   // Returns { moduleToEnter, enterToMounted, moduleToMounted } in ms
```

These values are passed as properties to the corresponding view-tracking events (e.g., `reportViewOfSCCreateLiveAds({ ...performanceData })`).

---

## Business Terminology Glossary

| Term | Definition |
|---|---|
| **Live Stream Ads** | Ad type enabling sellers to promote products during live streaming sessions on Shopee |
| **Max GMV** | Bidding objective that optimizes for maximum Gross Merchandise Value from the live stream |
| **Max Views** | Bidding objective that optimizes for maximum viewer count of the live stream |
| **Max GMV ROI Two** | Internal objective value (`MAX_GMV_ROI_TWO`) used when ROI Two is enabled; converted from Max GMV on publish. Enabled by `adsToggle.liveStreamAds` |
| **Max View ROI Two** | Internal objective value (`MAX_VIEW_ROI_TWO`); converted from Max Views when `adsToggle.liveStreamAdsViewMax` is enabled |
| **Target ROAS** | (Return On Ad Spending) A seller-defined ROAS floor that the system attempts to maintain |
| **ROI Two** | Second-generation ROAS optimization mode with tighter controls |
| **Daily Budget** | Maximum amount a seller is willing to spend per day on a campaign |
| **Time Slot** | The HH:MM–HH:MM window within a day during which the live stream ad is active |
| **Constantine** | The local reactive config store populated from `/config/get/`; holds budget limits, bid settings, currency config, and `scConfig` |
| **adsToggle** | Feature flag object from `/meta/get/` (type `ADS_TOGGLE`); controls rollout of main live stream ad features |
| **extToggle** | Feature flag object from `/meta/get_non_ads_data/` (type `EXT_TOGGLE`); controls additional experimental features |
| **Paid GMV** | GMV metric variant based on paid attribution model. Enabled by `extToggle.szSupportPaidGmvMetrics`. Date range is constrained to on or after `scConfig.paidGmvPhaseOneReleaseDate` |
| **Placed GMV** | Default GMV metric based on placed-order attribution. Shown when Paid GMV tab is unavailable or disabled |
| **Food Streamer** | Seller streamer type (`StreamerType.FOOD`) subject to additional restrictions; identified via `liveStreamAccount.streamerTypeList` in meta |
| **CIR** | (Cost-Income-Ratio) Ads Revenue / Ads GMV; inverse of ROAS/ROI |
| **ROAS** | (Return On Ads Spending) Ads GMV / Ads Revenue; synonym of ROI |
| **CPC** | (Cost Per Click) Amount spent per click on an ad |
| **CPM** | (Cost Per Mille) Cost to advertiser for every 1,000 impressions |
| **CTR** | (Click-Through Rate) Total clicks / total impressions |
| **CR** | (Conversion Rate) Ad orders / total clicks |
| **Cold Start** | Period at the start of a new campaign during which the system has insufficient data for accurate prediction |
| **SC** | Seller Center — the Shopee seller management platform where this module runs |
| **MMF / MMC** | Multi-Module Framework / Multi-Module CLI — the micro-frontend infrastructure powering the module |
| **QSS** | QuickStart Service — a program helping new advertisers ramp up ad usage quickly |
| **MCN** | Multi-Channel Network — agency platform where MCN agencies can create Live Ads for affiliated influencers |

---

## References

- [MMC Documentation](https://seller-portal.i.test.shopee.io/mmc-docs/guide/getting-started.html)
- [MMC Initialization Guide](https://seller-portal.i.test.shopee.io/mmc-docs/guide/basic/initialization.html)
- [MMC Development Guide](https://seller-portal.i.test.shopee.io/mmc-docs/guide/basic/development.html)
- [Seller Portal Build & Release](https://seller-portal.i.test.shopee.io/docs/pages/seller-portal/build-and-release.html)
- [Ads Platform Frontend Overview](https://sra.test.shopee.io/05.Business_Systems/5.3_Ads_Business_and_Architecture_Introduction/5.3.6._ads.platform.html)
- [Pas Helper Chrome Extension](https://chromewebstore.google.com/detail/pas-helper/nhfhjiehemipamajmeimnnkinhncgpcd)
- [pas-common Repository](https://git.garena.com/shopee/isfe/ao/pas-common)
- [pas-livestream Repository](https://git.garena.com/shopee/isfe/ao/pas-livestream)
- [Paid Ads Glossary](https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPAD&title=Paid+Ads+Glossary)

---

## Frequently Asked Questions

**1. How do I start local development for the first time?**

Run `yarn run init -p 21` once to install dependencies and fetch the Seller Center portal configuration. Then run `yarn dev` (with a local pas-common server running) or `yarn dev:remote` to start the dev server. Alternatively, `yarn start` combines init and remote dev in one command. Open the SC test environment and run `mmfDevtools.enable()` in DevTools to connect.

**2. Why does `yarn dev` show a connection refused error about pas-common?**

This happens when you run `yarn dev` (local mode) without a running pas-common local dev server. Either start the pas-common local server first, or switch to remote mode with `yarn dev:remote` which loads types from the master branch.

**3. What is the difference between Create and Restart flows?**

Both flows use the same `src/pages/create/index.vue` component. The distinction is made via the route name: if the current route is `RouterMap.RESTART_PAGE`, the page pre-loads existing campaign data, disables the objective selector, and shows a "Restart" button instead of "Publish".

**4. When is `MAX_GMV_ROI_TWO` used instead of `MAX_GMV`?**

`MAX_GMV_ROI_TWO` is the actual objective sent to the backend when ROI Two is enabled (`adsToggle.liveStreamAds` is true). The UI presents it as "Max GMV"; the conversion happens inside `prepareCampaignParams` before calling `publishLiveStreamAds`. Note: this is controlled by `adsToggle` (from `/meta/get/`), not `extToggle`.

**5. How do feature toggles work in this module?**

There are two toggle systems:
- `metaConfig.adsToggle` (from `/meta/get/` with `ADS_TOGGLE` info type): controls ROI Two mode (`liveStreamAds`) and Max View ROI Two (`liveStreamAdsViewMax`).
- `metaNonAdsConfig.extToggle` (from `/meta/get_non_ads_data/`): controls additional features like `szSupportPaidGmvMetrics` for the Paid GMV metric tab.
The main route guard redirects to the PAS home page if `adsToggle.liveStreamAds` is falsy.

**6. How are numbers sent to and received from the API?**

The backend multiplies all monetary/ratio values by 100,000 to avoid floating point issues. Use `convertServerNumber` (divides by 100,000) when reading responses and `convertClientNumber` (multiplies by 100,000) when sending requests. Both are imported from `pas-common/utils`.

**7. What is the `Constantine` store and what does it contain?**

`Constantine` is a `reactive<ConfigListRes>` object in `src/_shared/store/config/contantine.ts`, populated by `getConfig()` on route entry. It holds live stream ads configuration (min/max budget, ROAS settings, currency precision, feature downgrade flags, `scConfig.paidGmvPhaseOneReleaseDate`, etc.).

**8. How do I add a new tracking event?**

Do not create tracking functions locally. Add the event definition to `pas-common/tracking/entries/` in the appropriate entry file, then re-export it from `src/track/index.ts` in `pas-livestream`. Import tracking functions in components from `src/track`.

**9. What files are auto-generated and should not be manually edited?**

`config/.remote-config.json` is overwritten on every `yarn run init`. `.browserslistrc`, `.stylelintrc.json`, and `tsconfig.json` are also overwritten by MMC on initialization. Edit their MMC config counterparts instead.

**10. How does the Paid GMV / Placed GMV metric tab work?**

When `extToggle.szSupportPaidGmvMetrics` is enabled, the detail page shows a `GmvMetricSwitch` tab in the performance chart. The `metricTab` state (`MetricType.PAID_GMV` or `MetricType.PLACED_GMV`) is managed in `detail/index.vue` and passed down to both chart and table. When the selected date range starts before `scConfig.paidGmvPhaseOneReleaseDate`, the tab automatically switches to `PLACED_GMV` and `disablePaidGmv` is set to `true`.

<!-- Generated by ads-workspace/skills/ads-readme-generate | checked: 016db11b95c20c1ee2889eb289facecab4bd5ffb | spec: 76fce5f679f9550b -->
