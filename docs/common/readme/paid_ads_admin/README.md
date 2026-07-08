<!-- ads-workspace-gdoc-sync: gdoc_id=19haJE9duvvC6GJbgLjoY1Kdl390DRGbwaCOOkfLYzWc gdoc_url=https://docs.google.com/document/d/19haJE9duvvC6GJbgLjoY1Kdl390DRGbwaCOOkfLYzWc/edit -->

# Paid Ads Admin

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
- [Deployment](#deployment-1)
  - [Frontend Static (Space CMDB)](#frontend-static-space-cmdb)
  - [BFF (Deprecated)](#bff-deprecated)
- [Business Terminology Glossary](#business-terminology-glossary)
- [References](#references)
- [Frequently Asked Questions](#frequently-asked-questions)

---

## Project Overview

Paid Ads Admin is an internal React 18 + Vite single-page application that provides Shopee's ads operations team with a unified management portal. The portal allows admins to manage all ad types (Product Ads, Shop Ads, Live Ads, Video Ads, Banner Ads, Display Ads, Brand Max Ads), handle billing and top-up operations, review ad creatives, operate fraud/whitelist/blacklist tooling, and monitor ad CRM data across 12 regions (SG, ID, MY, PH, TH, TW, VN, BR, MX, CO, CL, AR).

---

## Key Features

- **Product Ads (USF Keyword Ads)** — Overview, Reporting, Operation Log, Deduction Log, GMS Ads Creation Tool, Diagnosis
- **Shop Ads (USF Shop Ads)** — Overview, Reporting, Operation Log, Deduction Log, Keywords Whitelist
- **Live Ads** — Overview, Reporting, Operation Log, Deduction Log
- **Video Ads** — Overview, Reporting, Operation Log, Deduction Log
- **Banner Ads** — Campaign Setup, Overview, Reporting, Operation Log, Creative Review, Package Management, Keyword Nomination
- **Display Ads** — Whitelist, Inventory Management, Ads Management (create/edit), Creative Review, Billing & Payment, Billing Info, Display Ads Credit Balance Log
- **Brand Max Ads (Brand Consideration Ads)** — Campaign Overview, Reporting, Operation Log, Creative Review, Deduction Log, Inventory Allocation
- **Top Up / Manual Ads Credit** — Manual top-up, deduction, transfer, batch upload/approval history, Ads Credit Sub-Type management
- **Balance Log** — Account balance log viewer
- **Fraud Tool** — Fraud user management
- **Whitelist / Blacklist** — User whitelist management with six operation modes (Mass Add/Remove, Single Add/Remove, Open-to-All, Open-to-None); supports special whitelist types — ROI Settings (ROI3), Shop Ads 2.0, Escrow Mandatory Fee Rate (5-column CSV: shop ID, fixed rate, optional fee rate change type/value, override flag), and Video Ads (2-column CSV: userid, subtype KOL/Seller) — each with type-specific CSV validation and per-type display constraints; keyword/ad blacklist management
- **Bad Case Benchmark** — Benchmark review and result analysis
- **Reindex Tool** — Ads reindex and audit
- **DB Viewer** — Admin database viewer
- **Visualiser** — Ad entity info visualiser
- **Ads CRM User Sync (Cron Job Sync)** — CRM data sync job management
- **Account Settings** — Account feature operation and operation log
- **Live Testing Tool** — Flag tab reset tool
- **Rebate Manual Review** — Rebate review

---

## Project Architecture

### Technology Stack

| Layer                | Technology                                                      |
| -------------------- | --------------------------------------------------------------- |
| Framework            | React 18                                                        |
| Build tool           | Vite 5                                                          |
| Language             | TypeScript                                                      |
| State management     | Redux (redux-thunk + `@reduxjs/toolkit`) + Recoil + react-query |
| Router               | React Router 6 (`createBrowserRouter`)                          |
| UI component library | Ant Design 5                                                    |
| CSS preprocessor     | SCSS (sass)                                                     |
| HTTP client          | axios                                                           |
| Protobuf             | ts-proto                                                        |

### Application Entry

```
index.html
└── src/main.tsx           ← ReactDOM.createRoot entry
    └── src/App.tsx        ← createBrowserRouter, AuthWrapper, PageContext
        └── src/routes/root.tsx  ← Ant Design Layout (Header + Sider + Content)
            └── <Outlet />       ← Lazy-loaded page components from src/bundle.ts
```

### State Management

The Redux store is created in `src/_shared/redux/index.ts` with `@reduxjs/toolkit`'s `configureStore`, combining the following slices:

| Slice                   | State Type                   | Description                   |
| ----------------------- | ---------------------------- | ----------------------------- |
| `balance`               | `BalanceState`               | Balance log                   |
| `benchmark`             | `BadCaseBenchmarkState`      | Bad case benchmark            |
| `blacklistKeywords`     | `BlackListKeywordsState`     | Blacklist keywords            |
| `brandConsiderationAds` | `BrandConsiderationAdsState` | Brand Max Ads                 |
| `dbViewer`              | `DbViewerState`              | DB viewer                     |
| `displayAds`            | `DisplayAdsState`            | Display Ads                   |
| `inventoryManagement`   | `InventoryManagementState`   | Display Ads inventory         |
| `fraudTool`             | `FraudState`                 | Fraud tool                    |
| `keywordNomination`     | `KeywordNominationState`     | Banner Ads keyword nomination |
| `listFlag`              | `ListFlagState`              | Live testing flags            |
| `manualAdsCredit`       | `ManualAdsCreditState`       | Manual top-up / credit        |
| `packageManagement`     | `PackageManagementState`     | Banner Ads package            |
| `pageHistory`           | `HistoryState`               | Page navigation history       |
| `searchBrandAds`        | `SearchBrandAdsState`        | Banner / Search Brand Ads     |
| `usfKeywordAds`         | `UsfKeywordAdsState`         | Product Ads                   |
| `usfShopAds`            | `UsfShopAdsState`            | Shop Ads                      |
| `videoAds`              | `VideoAdsState`              | Video Ads                     |
| `accountSettings`       | `AccountSettingsState`       | Account settings              |
| `router`                | `RouterState`                | react-router-redux            |

### Routing

Routes are defined as an enum in `src/_shared/config/routes.ts` and registered in `src/bundle.ts`. All pages are **lazy-loaded** via `lazyLoad()`. The router uses `basename = /<region>` extracted from the URL path. The default redirect is `/` → `/usfkeyword`.

Region-specific route filtering is applied in `bundlesFilter()` in `src/bundle.ts`. Key exclusions:

- **AR**: No Boost Ads, Shop Ads, Live Ads, Video Ads, Display Ads, Banner Ads, Cron Job Sync, Fraud Tool, Visualiser
- **MX / CO / CL**: No Banner Ads Setup / Overview / Creative Review
- **MX**: No Boost Ads Variable Setting

### API Request Architecture

API requests use axios. Endpoints are defined in `src/_shared/constant/api.ts`. Two base path prefixes are used:

- `/bff/*` — routes that still proxy through the legacy BFF (NestJS, now deprecated)
- `/api/v2/*` — routes registered directly in MTS-ECP (current approach)

For new endpoints, the `X-Soup-Object-Code` header is set to the region code for SOUP permission validation:

```ts
instance.defaults.headers.post[
  "X-Soup-Object-Code"
] = getLocalRegion()?.toLocaleLowerCase();
```

MTS-ECP endpoint management console: https://space.shopee.io/mts/ecpnonlive/domain-listing/endpoint-listing?domain=admin.ads.shopee.io

---

## Directory Structure

```
paid_ads_admin/
├── src/
│   ├── _shared/                    # Shared utilities and components
│   │   ├── api/                    # API call functions and auth
│   │   ├── assets/                 # Static images and SVGs
│   │   ├── components/             # Shared UI components
│   │   │   ├── AdsOverviewTemplate/    # Overview page template (USF Ads)
│   │   │   ├── CsvExport/              # CSV export button
│   │   │   ├── CsvReader/              # CSV reader / parse
│   │   │   ├── CustomizeForm/          # Shared search form (date, input, select, …)
│   │   │   ├── DeductionLogTemplate/   # Deduction log template
│   │   │   ├── OperationLogTemplate/   # Operation log template
│   │   │   ├── PageTemplate/           # Flexible page template
│   │   │   ├── PageWrapper/            # Standard page wrapper
│   │   │   ├── ReportingTemplate/      # Reporting page template
│   │   │   ├── WithAuthContext/        # HOC: provides pageKey
│   │   │   ├── WithLayout/             # HOC: applies layout
│   │   │   ├── WithPermissionWrapper/  # HOC: SOUP permission check
│   │   │   └── WithProvider/           # HOC: Redux Provider
│   │   ├── config/
│   │   │   ├── routes.ts               # Routes enum
│   │   │   └── commonType.ts / constants.ts
│   │   ├── constant/
│   │   │   ├── api.ts                  # All API endpoint constants
│   │   │   └── global.ts               # Region enum, FormatType, PlatformTypes
│   │   ├── hook/                   # Custom React hooks
│   │   ├── redux/                  # Redux store: reducers, actions, typings
│   │   ├── typings/                # Type files (custom + proto-generated)
│   │   └── utils/                  # Utility functions (date, CSV, region, …)
│   ├── 404/                        # Not found page
│   ├── NoPermissionPage/           # No platform permission page
│   ├── accountSettings/            # Account settings pages
│   ├── balance/                    # Balance log
│   ├── bannerAds/                  # Banner Ads pages
│   ├── benchmark/                  # Bad Case Benchmark pages
│   ├── blacklistkeyword/           # Blacklist keyword page
│   ├── boostAds/                   # Boost Ads variable setting
│   ├── brandConsiderationAds/      # Brand Max Ads pages
│   ├── cronJobSync/                # Ads CRM user sync
│   ├── dbViewer/                   # Database viewer
│   ├── displayAds/                 # Display Ads pages
│   ├── featureOperation/           # Feature operation page
│   ├── fraudTool/                  # Fraud tool page
│   ├── liveAds/                    # Live Ads pages
│   ├── liveTestingTool/            # Live testing tool (flag reset)
│   ├── loginCallback/              # SSO login callback
│   ├── manualAdsCredit/            # Top Up / Manual Ads Credit pages
│   ├── rebateManualReview/         # Rebate manual review
│   ├── reindex/                    # Reindex tool
│   ├── rootShare/                  # Auth, contexts, hooks, shared components
│   ├── routes/                     # App layout: root.tsx (header + sider)
│   ├── usfKeywordAds/              # Product Ads (USF Keyword) pages
│   ├── usfShopAds/                 # Shop Ads (USF Shop) pages
│   ├── videoAds/                   # Video Ads pages
│   ├── visualiser/                 # Ad entity visualiser
│   ├── whitelist/                  # Whitelist management
│   ├── App.tsx                     # Router setup, AuthWrapper, PageContext
│   ├── bundle.ts                   # Route-to-component lazy imports
│   ├── config.ts                   # Kayatoast siteConfig (sidebar nav)
│   ├── main.tsx                    # App entry point
│   └── theme.scss                  # Global Ant Design theme overrides
├── static/                         # Public static assets
├── deploy/                         # Deployment scripts
├── index.html                      # HTML entry
├── vite.config.ts                  # Vite configuration (proxy, aliases, plugins)
├── tsconfig.json                   # TypeScript configuration
├── package.json                    # Dependencies and scripts
└── commitlint.config.js            # Commitlint configuration
```

---

## Quick Start

### Prerequisites

- **Node.js** ≥ 16.0.0
- **yarn** (install via Homebrew: `brew install yarn` or OS package manager)

### Configuration

The Vite dev server proxies both `/bff` and `/api` paths. Configure these in `package.json` under `kayaToast.proxyPath`:

```json
"kayaToast": {
  "proxyPath": ["/bff", "/api"]
}
```

The default proxy target is `https://admin.ads.test.shopee.io/`. To change the target (e.g., for local BFF), edit `vite.config.ts`:

```ts
// Uncomment for local BFF target on /bff path
// target: path === "/bff" ? "http://localhost:7001/" : "https://admin.ads.test.shopee.io/"
```

To enable PFB (proxy forwarding for browser cookies), create a `.env` file:

```ini
VITE_ENABLE_PFB=true
VITE_PFB=<your_PFB_cookie_value>
```

To add new API path prefixes to the proxy, update `package.json` `proxyPath` array and ensure `vite.config.ts` reads it (it already iterates `proxyPath` to build the Vite proxy config).

### Installation

```sh
yarn install
```

### Build

```sh
# Production build
yarn build

# Lint JS and CSS
yarn lint

# Auto-fix lint issues
yarn lint:fix

# Format code
yarn format
```

### Local Development

```sh
yarn start
```

The dev server runs on port **8888** (`http://localhost:8888`). All `/bff` and `/api` requests are proxied to `https://admin.ads.test.shopee.io/`.

You will need valid browser cookies (SPC_ST, SPC_CDS, etc.) from admin.ads.test.shopee.io for authenticated requests to pass through.

### Development

**Adding a new page:**

1. Add a new route constant to `src/_shared/config/routes.ts`.
2. Register a lazy-loaded bundle entry in `src/bundle.ts`.
3. Add a sidebar nav entry in `src/config.ts` under `sideNav`.
4. Create the page component under a new or existing feature directory in `src/`.

**Adding a new API endpoint:**

New endpoints must be registered in MTS-ECP first:

- MTS ECP console (non-live): https://space.shopee.io/mts/ecpnonlive/domain-listing/endpoint-listing?domain=admin.ads.shopee.io
- Then add the endpoint constant to `src/_shared/constant/api.ts` using `/api/v2/<path>` prefix.
- Reference the MTS integration guide: [Confluence — MTS Portal Integration](https://confluence.shopee.io/display/SPAD/%5BPaid+Ads+-+WebFE%5D+MTS+Portal+integration)

**Generating TypeScript types from proto:**

```sh
# Mac M1 / Apple Silicon
yarn run protoc [proto_file_path]

# Non-M1 / amd64
yarn run protoc2 [proto_file_path]
```

If the pre-compiled protoc binary does not work, install via Homebrew:

```sh
brew install protobuf
```

**Commit message format:**

```
{type}[SPPA-xxxx]: {description}
```

Valid types: `chore`, `docs`, `feat`, `fix`, `refactor`, `style`. JIRA ticket is mandatory except for `chore` commits.

Example:

```
feat[SPPA-1234]: add GMS Ads Creation Tool diagnosis tab
chore: update antd to 5.15.3
```

### Deployment

Frontend static assets are deployed via Space CMDB (see [Deployment](#deployment-1) section). There is no local deployment step — `yarn build` produces the `dist/` folder which is uploaded by CI.

---

## API Documentation

All API endpoints are defined in `src/_shared/constant/api.ts`. Endpoints prefixed with `/api/v2/` are routed via MTS-ECP; endpoints prefixed with `/bff/` still proxy through the legacy BFF.

| Page                           | Page URL                                               | API Endpoint                                                                    | Description                                       |
| ------------------------------ | ------------------------------------------------------ | ------------------------------------------------------------------------------- | ------------------------------------------------- |
| Auth                           | `/login-callback`                                      | `/api/v1/auth/info`                                                             | Get user login info                               |
| Auth                           | `/login-callback`                                      | `/api/v1/auth/logout`                                                           | Logout user                                       |
| Account Settings               | `/accountSettings`                                     | `/api/v2/account_settings/operation_log`                                        | Account settings operation log                    |
| Account Settings               | `/accountSettings`                                     | `/api/v2/account_setting_task_create`                                           | Create account setting task                       |
| Account Settings               | `/accountSettings`                                     | `/api/v2/account_setting_task_list`                                             | List account setting tasks                        |
| Account Settings               | `/accountSettings`                                     | `/api/v2/account_setting_task_download`                                         | Download account setting task                     |
| Account Settings               | `/accountSettingsOverview`                             | `/api/v2/account_setting_overview`                                              | Account settings overview                         |
| Balance Log                    | `/balanceLog`                                          | `/api/v2/balance/get_balance_log`                                               | Load balance log                                  |
| Banner Ads                     | `/bannerAds/*`                                         | `/api/v2/banner/get_shop_reserved_keyword`                                      | Get reserved keywords for shop                    |
| Banner Ads                     | `/bannerAds/setUp`                                     | `/api/v2/banner/create_banner`                                                  | Create banner ad campaign                         |
| Banner Ads                     | `/bannerAds/overview`                                  | `/api/v2/banner/list_banner_campaigns`                                          | List banner campaigns                             |
| Banner Ads                     | `/bannerAds/overview`                                  | `/api/v2/banner/get_banners`                                                    | Get banner ads                                    |
| Banner Ads                     | `/bannerAds/overview`                                  | `/api/v2/banner/brand_ads_get_detail`                                           | Get brand ads detail                              |
| Banner Ads                     | `/bannerAds/report`                                    | `/api/v2/banner/reporting`                                                      | Brand ads reporting                               |
| Banner Ads                     | `/bannerAds/operationLog`                              | `/api/v2/banner/operation_log`                                                  | Banner ads operation log                          |
| Banner Ads                     | `/bannerAds/*`                                         | `/api/v2/banner/update_banners`                                                 | Update banner ads                                 |
| Banner Ads                     | `/bannerAds/*`                                         | `/api/v2/banner/update_campaign_status`                                         | Update campaign status                            |
| Banner Ads                     | `/bannerAds/packageManagement`                         | `/api/v2/banner/list_search_brand_package`                                      | List search brand packages                        |
| Banner Ads                     | `/bannerAds/packageManagement`                         | `/api/v2/banner/batch_upload_search_brand_package`                              | Batch upload search brand packages                |
| Banner Ads                     | `/bannerAds/packageManagement/changeLog`               | `/api/v2/banner/list_search_brand_package_changelog`                            | List package management changelog                 |
| Banner Ads                     | `/bannerAds/packageManagement`                         | `/api/v2/banner/remove_brand_pkg_period`                                        | Remove brand package period                       |
| Banner Ads                     | `/bannerAds/keywordNomination`                         | `/api/v2/banner/list_grouped_keyword`                                           | List grouped keywords                             |
| Banner Ads                     | `/bannerAds/keywordNomination/changelog`               | `/api/v2/banner/list_brand_keyword_change_log`                                  | Banner ads keyword change log                     |
| Banner Ads                     | `/bannerAds/keywordNomination`                         | `/api/v2/banner/batch_upload_brand_keyword`                                     | Batch upload brand keywords                       |
| Banner Ads                     | `/bannerAds/keywordNomination`                         | `/api/v2/banner/remove_brand_keyword`                                           | Remove brand keyword                              |
| Banner Ads                     | `/bannerAds/creativeReview`                            | `/api/v2/banner/brand_ads_list_creatives`                                       | List brand creative assets                        |
| Banner Ads                     | `/bannerAds/creativeReview`                            | `/api/v2/banner/update_creative_status`                                         | Update brand creative status                      |
| Banner Ads                     | `/bannerAds/*`                                         | `/api/v2/brand/ads_get_fe_configs`                                              | Get brand ads FE configs                          |
| Banner Ads                     | `/bannerAds/creativeReview/detail`                     | `/api/v2/brand/brand_ads_get_creative_detail`                                   | Get brand ads creative detail                     |
| Benchmark                      | `/benchmark/review`                                    | `/api/v2/bad_case/bad_case_search`                                              | Bad case list search                              |
| Benchmark                      | `/benchmark/review`                                    | `/api/v2/bad_case/update_bad_case`                                              | Update bad case                                   |
| Blacklist                      | `/blacklist`                                           | `/api/v2/search/blacklist`                                                      | Get ads blacklist                                 |
| Blacklist                      | `/blacklist`                                           | `/api/v2/update/blacklist`                                                      | Update ads blacklist                              |
| Blacklist                      | `/blacklist/operationLog`                              | `/api/v2/blacklist_log_search/blacklist`                                        | Blacklist operation log search                    |
| Blacklist Keyword (legacy BFF) | `/blacklistkeyword`                                    | `/bff/blacklistKeywords/get_blacklist_keyword`                                  | Get blacklist keywords                            |
| Blacklist Keyword (legacy BFF) | `/blacklistkeyword`                                    | `/bff/blacklistKeywords/add_blacklist_keyword`                                  | Add blacklist keyword                             |
| Blacklist Keyword (legacy BFF) | `/blacklistkeyword`                                    | `/bff/blacklistKeywords/update_blacklist_keyword`                               | Update blacklist keyword                          |
| Boost Ads (legacy BFF)         | `/boostAds/variableSetting`                            | `/bff/get_item_boost_variable_settings`                                         | Get boost variable settings                       |
| Boost Ads (legacy BFF)         | `/boostAds/variableSetting`                            | `/bff/add_item_boost_variable_setting`                                          | Add boost variable setting                        |
| Brand Consideration Ads        | `/brandConsiderationAds/operation`                     | `/api/v2/brand_consideration_ads/operation_log`                                 | Brand Consideration Ads operation log             |
| Brand Consideration Ads        | `/brandConsiderationAds/report`                        | `/api/v2/brand_consideration_ads/report`                                        | Brand Consideration Ads reporting                 |
| Brand Consideration Ads        | `/brandConsiderationAds/overview`                      | `/api/v2/brand_consideration_ads/overview`                                      | Brand Consideration Ads overview                  |
| Brand Consideration Ads        | `/brandConsiderationAds/overview`                      | `/api/v2/brand_consideration_ads/update_status`                                 | Update Brand Consideration Ads status             |
| Brand Consideration Ads        | `/brandConsiderationAds/overview/detail`               | `/api/v2/brand_consideration_ads/get_detail`                                    | Get Brand Consideration Ads detail                |
| Brand Consideration Ads        | `/brandConsiderationAds/deductionLog`                  | `/api/v2/brand_consideration_ads/deduction_log`                                 | Brand Consideration Ads deduction log             |
| Brand Consideration Ads        | `/brandConsiderationAds/inventoryAllocation`           | `/api/v2/brand_consideration_ads/brand_consideration_list_inventory`            | List inventory                                    |
| Brand Consideration Ads        | `/brandConsiderationAds/inventoryAllocation/changeLog` | `/api/v2/brand_consideration_ads/brand_consideration_list_inventory_change_log` | Inventory change log                              |
| Brand Consideration Ads        | `/brandConsiderationAds/inventoryAllocation`           | `/api/v2/brand_consideration_ads/brand_consideration_batch_edit_inventory`      | Batch edit inventory allocation                   |
| Brand Consideration Ads        | `/brandConsiderationAds/creativeReview`                | `/api/v2/brand_consideration_ads/list_creatives`                                | List Brand Consideration Ads creatives            |
| Brand Consideration Ads        | `/brandConsiderationAds/creativeReview/detail`         | `/api/v2/brand_consideration_ads/creative_detail`                               | Brand Consideration Ads creative detail           |
| Brand Consideration Ads        | `/brandConsiderationAds/creativeReview`                | `/api/v2/brand_consideration_ads/creative_qc`                                   | QC / approve creative                             |
| Brand Consideration Ads        | `/brandConsiderationAds/*`                             | `/api/v2/brand_consideration_ads/brand_consideration_get_config`                | Get Brand Consideration Ads configs               |
| Cron Job Sync                  | `/cronJobSync`                                         | `/api/v2/cron_job_sync/get`                                                     | Get cron job sync status                          |
| Cron Job Sync                  | `/cronJobSync`                                         | `/api/v2/cron_job_sync/get_rebate`                                              | Get rebate cron job sync status                   |
| Cron Job Sync                  | `/cronJobSync`                                         | `/api/v2/cron_job_sync/trigger`                                                 | Trigger cron job sync                             |
| Cron Job Sync                  | `/cronJobSync`                                         | `/api/v2/cron_job_sync/trigger_rebate`                                          | Trigger rebate cron job sync                      |
| DB Viewer                      | `/dbViewer`                                            | `/api/v2/db_viewer/get_database_viewer_metadata`                                | Get DB viewer metadata                            |
| DB Viewer                      | `/dbViewer`                                            | `/api/v2/db_viewer/database_viewer`                                             | DB viewer query                                   |
| Display Ads                    | `/displayAds/*`                                        | `/api/v2/display_ads/get_admin_toggles`                                         | Get admin feature toggles                         |
| Display Ads                    | `/displayAds/*`                                        | `/api/v2/display_ads/list_audience_group`                                       | List audience groups                              |
| Display Ads                    | `/displayAds/inventoryManagement`                      | `/api/v2/display_ads/get_inventory_info`                                        | Get inventory info                                |
| Display Ads                    | `/displayAds/inventoryManagement`                      | `/api/v2/display_ads/get_display_ads_list_by_date`                              | Get display ads list by date                      |
| Display Ads                    | `/displayAds/inventoryManagement/cpmPricing`           | `/api/v2/display_ads/get_cpm_pricing_list`                                      | Get CPM pricing list                              |
| Display Ads                    | `/displayAds/inventoryManagement`                      | `/api/v2/display_ads/get_block_shop_list_by_date`                               | Get blocked shop list by date                     |
| Display Ads                    | `/displayAds/inventoryManagement`                      | `/api/v2/display_ads/block_shop`                                                | Block shop                                        |
| Display Ads                    | `/displayAds/inventoryManagement`                      | `/api/v2/display_ads/un_block_shop`                                             | Unblock shop                                      |
| Display Ads                    | `/displayAds/inventoryManagement/cpmPricing`           | `/api/v2/display_ads/upload_cpm_pricing`                                        | Upload CPM pricing                                |
| Display Ads                    | `/displayAds/*`                                        | `/api/v2/display_ads/get_reason_list_with_prefix`                               | Get reason list with prefix                       |
| Display Ads                    | `/displayAds/creativeReview`                           | `/api/v2/display_ads/get_creative_list`                                         | Get creative list                                 |
| Display Ads                    | `/displayAds/creativeReview/detail`                    | `/api/v2/display_ads/get_creative_detail_by_id`                                 | Get creative detail by ID                         |
| Display Ads                    | `/displayAds/creativeReview`                           | `/api/v2/display_ads/approve_creative`                                          | Approve creative                                  |
| Display Ads                    | `/displayAds/billingAndPayment`                        | `/api/v2/display_ads/get_billings`                                              | Get billings                                      |
| Display Ads                    | `/displayAds/billingAndPayment`                        | `/api/v2/display_ads/export_ready_for_invoice_billings`                         | Export ready-for-invoice billings                 |
| Display Ads                    | `/displayAds/billingAndPayment`                        | `/api/v2/display_ads/update_payment`                                            | Update payment                                    |
| Display Ads                    | `/displayAds/billingAndPayment`                        | `/api/v2/display_ads/get_ready_for_invoice_billing_count`                       | Get ready-for-invoice billing count               |
| Display Ads                    | `/displayAds/whitelist`                                | `/api/v2/display_ads/get_whitelist_shops`                                       | Get whitelist shops                               |
| Display Ads                    | `/displayAds/whitelist`                                | `/api/v2/display_ads/add_whitelist_shops`                                       | Add whitelist shops                               |
| Display Ads                    | `/displayAds/whitelist`                                | `/api/v2/display_ads/remove_whitelist_shops`                                    | Remove whitelist shops                            |
| Display Ads                    | `/displayAds/whitelist`                                | `/api/v2/display_ads/get_affect_ads_list_by_un_whitelist`                       | Get ads affected by whitelist removal             |
| Display Ads                    | `/displayAds/inventoryManagement/cpmPricing`           | `/api/v2/display_ads/get_upload_cpm_reminder`                                   | Get upload CPM reminder                           |
| Display Ads                    | `/displayAds/adsManagement`                            | `/api/v2/display_ads/get_display_ads_list`                                      | Get display ads list                              |
| Display Ads                    | `/displayAds/adsManagement`                            | `/api/v2/display_ads/get_shop_name`                                             | Get shop name                                     |
| Display Ads                    | `/displayAds/adsManagement`                            | `/api/v2/display_ads/get_display_ads_detail`                                    | Get display ads detail                            |
| Display Ads                    | `/displayAds/adsManagement/updateCreative`             | `/api/v2/display_ads/upload_display_ads_creative`                               | Upload display ads creative                       |
| Display Ads                    | `/displayAds/adsManagement`                            | `/api/v2/display_ads/get_display_ads_calendar_info`                             | Get display ads calendar info                     |
| Display Ads                    | `/displayAds/adsManagement/create`                     | `/api/v2/display_ads/create_display_ads`                                        | Create display ads                                |
| Display Ads                    | `/displayAds/adsManagement/edit`                       | `/api/v2/display_ads/edit_display_ads`                                          | Edit display ads                                  |
| Display Ads                    | `/displayAds/adsManagement`                            | `/api/v2/display_ads/set_display_ads_status`                                    | Set display ads status                            |
| Display Ads                    | `/displayAds/adsManagement`                            | `/api/v2/display_ads/get_display_ads_cpm_info`                                  | Get display ads CPM info                          |
| Display Ads                    | `/displayAds/billingInfo`                              | `/api/v2/display_ads/upload_display_shop_billing_info`                          | Upload display shop billing info                  |
| Display Ads                    | `/displayAds/adsManagement`                            | `/api/v2/display_ads/get_display_ads_company_profiles`                          | Get company profiles                              |
| Display Ads                    | `/displayAds/adsManagement`                            | `/api/v2/display_ads/get_display_ads_config`                                    | Get display ads config                            |
| Display Ads                    | `/displayAds/inventoryManagement`                      | `/api/v2/display_ads/get_display_ads_premium_rate`                              | Get premium rate                                  |
| Display Ads                    | `/displayAds/inventoryManagement`                      | `/api/v2/display_ads/set_display_ads_premium_rate`                              | Set premium rate                                  |
| Display Ads                    | `/displayAds/inventoryManagement`                      | `/api/v2/display_ads/get_display_ads_premium_rate_audits`                       | Get premium rate audits                           |
| Display Ads Credit             | `/displayAds/creditBalancelog`                         | `/api/v2/display_credit/display_ads_balance_log_overview`                       | Display Ads credit balance log overview           |
| Display Ads Credit             | `/displayAds/creditBalancelog/detail`                  | `/api/v2/display_credit/display_ads_balance_log_shop_detail`                    | Display Ads credit balance log shop detail        |
| Display Ads (legacy BFF)       | `/displayAds/adsManagement`                            | `/bff/displayAds/upload_creative_image`                                         | Upload creative image (legacy BFF, multipart)     |
| Fraud Tool (legacy BFF)        | `/fraudTool`                                           | `/bff/fraudTool/get_fraud_reasons`                                              | Get fraud reasons                                 |
| Fraud Tool (legacy BFF)        | `/fraudTool`                                           | `/bff/fraudTool/get_fraud_users`                                                | Get fraud users                                   |
| Fraud Tool (legacy BFF)        | `/fraudTool`                                           | `/bff/fraudTool/add_fraud_users`                                                | Add fraud users                                   |
| Fraud Tool (legacy BFF)        | `/fraudTool`                                           | `/bff/fraudTool/delete_fraud_users`                                             | Delete fraud users                                |
| Live Ads                       | `/live`                                                | `/api/v2/live_ads/overview`                                                     | Live Ads overview list                            |
| Live Ads                       | `/live/detail`                                         | `/api/v2/live_ads/overview_detail`                                              | Live Ads overview detail                          |
| Live Ads                       | `/live/reporting`                                      | `/api/v2/live_ads/reporting`                                                    | Live Ads reporting                                |
| Live Ads                       | `/live/reporting/detail`                               | `/api/v2/live_ads/reporting_detail`                                             | Live Ads reporting detail                         |
| Live Ads                       | `/live/operationLog`                                   | `/api/v2/live_ads/operation_log`                                                | Live Ads operation log                            |
| Live Ads                       | `/live/deductionLog`                                   | `/api/v2/live_ads/deduction_log`                                                | Live Ads deduction log                            |
| Live Testing Tool              | `/liveTestingTool/flagTabReset`                        | `/api/v2/flag/list_allowed`                                                     | List allowed flags                                |
| Live Testing Tool              | `/liveTestingTool/flagTabReset`                        | `/api/v2/flag/list_overview`                                                    | List flag overview                                |
| Live Testing Tool              | `/liveTestingTool/flagTabReset`                        | `/api/v2/flag/update_flag`                                                      | Update flag                                       |
| Manual Ads Credit              | `/manualAdsCredit/topup`                               | `/api/v2/top_up/set_manual_topup`                                               | Set manual top-up                                 |
| Manual Ads Credit              | `/manualAdsCredit/subtype`                             | `/api/v2/top_up/get_ads_credit_subtypes`                                        | Get ads credit sub-types                          |
| Manual Ads Credit              | `/manualAdsCredit/subtype`                             | `/api/v2/top_up/set_ads_credit_subtypes`                                        | Set ads credit sub-types                          |
| Manual Ads Credit              | `/manualAdsCredit/topup`                               | `/api/v2/top_up/set_display_manual_topup`                                       | Set display manual top-up                         |
| Manual Ads Credit              | `/manualAdsCredit/overview`                            | `/api/v2/top_up/get_manual_topup_summary`                                       | Get manual top-up summary                         |
| Manual Ads Credit              | `/manualAdsCredit/overview`                            | `/api/v2/top_up/batch_update_manual_topup`                                      | Batch update manual top-up status                 |
| Manual Ads Credit              | `/manualAdsCredit/topup`                               | `/api/v2/top_up/get_soup_permission_list`                                       | Get eligible approvers list                       |
| Manual Ads Credit              | `/manualAdsCredit/topup`                               | `/api/v2/top_up/get_manual_topup_config`                                        | Get manual top-up config                          |
| Manual Ads Credit              | `/manualAdsCredit/history`                             | `/api/v2/top_up/upload_file`                                                    | Upload batch top-up file                          |
| Manual Ads Credit              | `/manualAdsCredit/history`                             | `/api/v2/top_up/async_batch_set_manual_topup`                                   | Async batch set manual top-up                     |
| Manual Ads Credit              | `/manualAdsCredit/history`                             | `/api/v2/top_up/batch_upload_log`                                               | Get batch upload log                              |
| Manual Ads Credit              | `/manualAdsCredit/history`                             | `/api/v2/top_up/batch_action_log`                                               | Get batch action log                              |
| Manual Ads Credit              | `/manualAdsCredit/history`                             | `/api/v2/top_up/async_batch_update_manual_topup`                                | Async batch update manual top-up                  |
| Manual Ads Credit              | `/manualAdsCredit/deduction`                           | `/api/v2/deduct/get_credit_summary`                                             | Get credit summary                                |
| Manual Ads Credit              | `/manualAdsCredit/deduction`                           | `/api/v2/deduct/set_manual_deduct`                                              | Set manual deduction                              |
| Manual Ads Credit              | `/manualAdsCredit/deduction`                           | `/api/v2/deduct/async_batch_set_manual_deduct`                                  | Async batch set manual deduction                  |
| Manual Ads Credit              | `/manualAdsCredit/transfer`                            | `/api/v2/transfer/async_batch_set_manual_transfer`                              | Async batch set manual transfer                   |
| Product Ads                    | `/usfkeyword`                                          | `/api/v2/product_ads/overview`                                                  | Product Ads overview                              |
| Product Ads                    | `/usfkeyword/overview/detail`                          | `/api/v2/product_ads/reporting_detail`                                          | Product Ads reporting detail                      |
| Product Ads                    | `/usfkeyword/reporting`                                | `/api/v2/product_ads/reporting`                                                 | Product Ads reporting                             |
| Product Ads                    | `/usfkeyword/operationLog`                             | `/api/v2/product_ads/operation_log`                                             | Product Ads operation log                         |
| Product Ads                    | `/usfkeyword/deductionLog`                             | `/api/v2/product_ads/deduction_log`                                             | Product Ads deduction log                         |
| Product Ads                    | `/usfkeyword/diagnosis`                                | `/api/v2/product_ads/diagnosis_list`                                            | Product Ads diagnosis list                        |
| Product Ads (GMS)              | `/usfkeyword/gmsAdsCreationTool`                       | `/api/v2/product_ads/list_system_gms_shop`                                      | List system GMS shops                             |
| Product Ads (GMS)              | `/usfkeyword/gmsAdsCreationTool`                       | `/api/v2/product_ads/add_system_gms_shop`                                       | Add system GMS shop                               |
| Product Ads (GMS)              | `/usfkeyword/gmsAdsCreationTool`                       | `/api/v2/product_ads/batch_pause_system_gms`                                    | Batch pause system GMS                            |
| Product Ads (GMS)              | `/usfkeyword/gmsAdsCreationTool`                       | `/api/v2/product_ads/pause_system_gms`                                          | Pause system GMS                                  |
| Product Ads (GMS)              | `/usfkeyword/gmsAdsCreationTool`                       | `/api/v2/product_ads/resume_system_gms`                                         | Resume system GMS                                 |
| Reindex                        | `/reindex`                                             | `/api/v2/reindex/reindex_ads`                                                   | Reindex ads                                       |
| Reindex                        | `/reindex`                                             | `/api/v2/reindex/get_reindex_ads_audit`                                         | Get reindex ads audit                             |
| Reindex                        | `/reindex`                                             | `/api/v2/reindex/get_reindex_ads_mass_upload_audit`                             | Get mass upload audit                             |
| Shop Ads                       | `/usfshop`                                             | `/api/v2/shop_ads/overview`                                                     | Shop Ads overview                                 |
| Shop Ads                       | `/usfshop/reporting`                                   | `/api/v2/shop_ads/reporting`                                                    | Shop Ads reporting                                |
| Shop Ads                       | `/usfshop/reporting/detail`                            | `/api/v2/shop_ads/reporting_detail`                                             | Shop Ads reporting detail                         |
| Shop Ads                       | `/usfshop/operationLog`                                | `/api/v2/shop_ads/operation_log`                                                | Shop Ads operation log                            |
| Shop Ads                       | `/usfshop/deductionLog`                                | `/api/v2/shop_ads/deduction_log`                                                | Shop Ads deduction log                            |
| Shop Ads Keyword Whitelist     | `/usfshop/keywordsWhitelist`                           | `/api/v2/reserved_keyword_whitelist/get_keywords`                               | Get reserved keyword whitelist                    |
| Shop Ads Keyword Whitelist     | `/usfshop/keywordsWhitelist`                           | `/api/v2/reserved_keyword_whitelist/get_audits`                                 | Get keyword whitelist audits                      |
| Shop Ads Keyword Whitelist     | `/usfshop/keywordsWhitelist`                           | `/api/v2/reserved_keyword_whitelist/set_keywords`                               | Set reserved keywords (write permission required) |
| User Whitelist                 | `/whitelist`                                           | `/api/v2/whitelist/get_whitelist_users`                                         | Get whitelist users                               |
| User Whitelist                 | `/whitelist`                                           | `/api/v2/whitelist/add_whitelist_users`                                         | Add whitelist users                               |
| User Whitelist                 | `/whitelist`                                           | `/api/v2/whitelist/poll_add_whitelist_user`                                     | Poll whitelist user add status                    |
| User Whitelist (legacy BFF)    | `/whitelist`                                           | `/bff/whitelist/delete_whitelist_users`                                         | Delete whitelist users                            |
| User Whitelist (legacy BFF)    | `/whitelist`                                           | `/bff/whitelist/get_whitelist_type`                                             | Get whitelist type                                |
| User Whitelist (legacy BFF)    | `/whitelist`                                           | `/bff/soup/get_users_by_name`                                                   | Get users by name (Banner Ads)                    |
| Video Ads                      | `/video`                                               | `/api/v2/video_ads/overview`                                                    | Video Ads overview                                |
| Video Ads                      | `/video/reporting`                                     | `/api/v2/video_ads/reporting`                                                   | Video Ads reporting                               |
| Video Ads                      | `/video/operationLog`                                  | `/api/v2/video_ads/operation_log`                                               | Video Ads operation log                           |
| Video Ads                      | `/video/deductionLog`                                  | `/api/v2/video_ads/deduction_log`                                               | Video Ads deduction log                           |
| Visualiser (legacy BFF)        | `/visualiser`                                          | `bff/api/v1/get_entity_infos`                                                   | Get entity info for visualiser                    |

> **Note:** Endpoints with `(legacy BFF)` label still proxy through the deprecated BFF. All new endpoints must use MTS-ECP and the `/api/v2/` prefix. The `/api/v1/auth/*` endpoints use MTS auth (not BFF).

---

## Deployment

### Frontend Static (Space CMDB)

The frontend static assets are deployed via Space CMDB:

- **Live:** https://space.shopee.io/console/cmdb/deployment/detail/shopee.mp_search_recommendation_ads.paidads.advertiser_platform.webfe.paid_ads_admin.static

Build command: `yarn build`

The deployed portals are accessible at:

| Environment | URL                               |
| ----------- | --------------------------------- |
| Live        | https://admin.ads.shopee.io/      |
| Test        | https://admin.ads.test.shopee.io/ |
| UAT         | https://admin.ads.uat.shopee.io/  |

CI/CD is managed via Jenkins:

| Environment | Jenkins                                                  |
| ----------- | -------------------------------------------------------- |
| Live        | https://jenkins.shopeemobile.com/view/paidadsadmin/      |
| Test/UAT    | https://jenkins.test.shopeemobile.com/view/paidadsadmin/ |

### BFF (Deprecated)

The legacy BFF (paid_ads_admin_bff, NestJS) is **no longer actively maintained**. Historical reference only.

- Space CMDB (legacy): https://space.shopee.io/console/cmdb/deployment/detail/shopee.mp_search_recommendation_ads.paidads.advertiser_platform.webfe.paid_ads_admin.node
- GitLab repository (historical): https://git.garena.com/shopee/isfe/ao/paid_ads_admin_bff

New endpoints **must not** use BFF. They should be registered in MTS-ECP and use the `/api/v2/` prefix.

---

## Business Terminology Glossary

| Term          | Full Name                      | Definition                                                                                             |
| ------------- | ------------------------------ | ------------------------------------------------------------------------------------------------------ |
| Ads GMV       | Ads Gross Merchandise Value    | Total sales generated from ads within a time frame (typically 7-day attribution window after ad click) |
| Take-Rate     | —                              | Ads Revenue / Platform GMV; measures Shopee's ad monetisation efficiency                               |
| CIR           | Cost-Income-Ratio              | Ads Revenue / Ads GMV                                                                                  |
| ROI           | Return on Investment           | Ads GMV / Ads Revenue (inverse of CIR); also called ROAS                                               |
| CPC           | Cost Per Click                 | Amount spent per click                                                                                 |
| CPM           | Cost Per Mille                 | Cost per 1,000 impressions                                                                             |
| eCPM          | Effective Cost per Mille       | Total Ad Spend / Total Impressions                                                                     |
| CTR           | Click-Through Rate             | Clicks / Impressions                                                                                   |
| CR            | Conversion Rate                | Ad Orders / Clicks                                                                                     |
| Advv          | Advertiser Value               | Long-term revenue measurement for platform                                                             |
| TADS          | Targeting Ads                  | Discovery/targeting ads (synonymous with DADS)                                                         |
| oCPC          | Simple Mode                    | Auto-keyword optimisation for sellers (optimize Cost per Click)                                        |
| QSS           | QuickStart Service             | Service to help new advertisers ramp up ad usage                                                       |
| SRM           | Seller Relationship Management | Seller data segmentation for engagement and revenue                                                    |
| Manual Top-up | —                              | CB Seller credit top-up requiring manual admin review                                                  |
| Auto Top-up   | —                              | Local Seller automatic credit top-up                                                                   |
| SVS Top-up    | Seller Value Service Top-up    | CB Seller top-up credit via SVS PDP                                                                    |
| Whitelist     | —                              | Sellers whitelisted for special features (Target ROI, custom Shop Ads, etc.)                           |
| Blacklist     | —                              | Blacklisted keywords or item IDs                                                                       |
| BFF           | Backend For Frontend           | Legacy NestJS proxy layer (deprecated — replaced by MTS-ECP)                                           |
| MTS           | —                              | Shopee's internal API gateway / endpoint configuration platform                                        |
| SOUP          | —                              | Shopee's internal permission system; provides role-based access control                                |
| CMDB          | —                              | Configuration Management Database; Space CMDB manages service deployments                              |

---

## References

- **GitLab repository:** https://git.garena.com/shopee/isfe/ao/paid_ads_admin
- **MTS-ECP Endpoint Management (non-live):** https://space.shopee.io/mts/ecpnonlive/domain-listing/endpoint-listing?domain=admin.ads.shopee.io
- **MTS-ECP Endpoint Management (live):** https://space.shopee.io/mts/ecplive/domain-listing/endpoint-listing?domain=admin.ads.shopee.io
- **MTS Portal Integration Guide (Confluence):** https://confluence.shopee.io/display/SPAD/%5BPaid+Ads+-+WebFE%5D+MTS+Portal+integration
- **Space CMDB — Frontend Static Deployment:** https://space.shopee.io/console/cmdb/deployment/detail/shopee.mp_search_recommendation_ads.paidads.advertiser_platform.webfe.paid_ads_admin.static
- **Space CMDB — BFF (Deprecated):** https://space.shopee.io/console/cmdb/deployment/detail/shopee.mp_search_recommendation_ads.paidads.advertiser_platform.webfe.paid_ads_admin.node
- **BFF Repository (historical reference only):** https://git.garena.com/shopee/isfe/ao/paid_ads_admin_bff
- **Paid Ads Glossary (Confluence):** https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPAD&title=Paid+Ads+Glossary
- **Jenkins — Live:** https://jenkins.shopeemobile.com/view/paidadsadmin/
- **Jenkins — Test/UAT:** https://jenkins.test.shopeemobile.com/view/paidadsadmin/
- **React:** https://reactjs.org/
- **Vite:** https://vitejs.dev/
- **Ant Design:** https://ant.design/
- **TypeScript:** https://www.typescriptlang.org/

---

## Frequently Asked Questions

**1. How do I run the portal locally?**

Install Node.js ≥ 16 and yarn, then run `yarn install && yarn start`. The dev server starts on port 8888. You need valid browser cookies (SPC_ST, SPC_CDS) from admin.ads.test.shopee.io — log in there first, then copy the cookies into your local browser session. API requests to `/bff` and `/api` are automatically proxied to the test environment.

**2. How do I add a new page/route?**

1. Add a route constant in `src/_shared/config/routes.ts`.
2. Register a lazy-loaded bundle in `src/bundle.ts` pointing to the new page component.
3. Add a sidebar entry in `src/config.ts` under `sideNav`.
4. Create the page component in a feature directory under `src/`.

**3. How do I add a new API endpoint?**

New APIs must no longer use BFF. Register the endpoint in MTS-ECP (non-live first, then live), configure SOUP permission code and backend service route. Then add the path constant to `src/_shared/constant/api.ts` using the `/api/v2/<path>` prefix. See the [MTS Portal Integration Guide](https://confluence.shopee.io/display/SPAD/%5BPaid+Ads+-+WebFE%5D+MTS+Portal+integration) for step-by-step instructions.

**4. How does SOUP permission checking work?**

The SOUP object code (region code) is set as a request header: `X-Soup-Object-Code: <region>`. MTS-ECP validates this against the configured permission for each endpoint. If the check fails, MTS returns a 403 response that the frontend handles. No BFF-level SOUP logic is needed for `/api/v2/` endpoints.

**5. How do I debug MTS-ECP endpoint routing issues locally?**

Add `_show_debug_info=2` as a query parameter to the failing request URL (e.g., `https://admin.ads.test.shopee.io/api/v2/cron_job_sync/get?_show_debug_info=2`). The response will include a `jaeger_tracing_url` that you can use to trace the request end-to-end.

**6. How do I add a new proxy path prefix for local development?**

Update `package.json` `kayaToast.proxyPath` to add the new path (e.g., `["/bff", "/api", "/newprefix"]`). The `vite.config.ts` already iterates this array dynamically to configure the Vite proxy.

**7. How do I generate TypeScript types from .proto files?**

Use `yarn run protoc [proto_file_path]` (M1/Apple Silicon) or `yarn run protoc2 [proto_file_path]` (non-M1). If the binary fails, install `protoc` globally via `brew install protobuf` and then retry `protoc2`.

**8. Why are some endpoints still using `/bff/` prefix?**

These endpoints have not yet been migrated to MTS-ECP. Migration requires registering them in the ECP console and configuring SOUP permissions — see the Confluence guide. Until migrated, they continue to proxy through the legacy NestJS BFF.

**9. How does region-based routing work?**

The URL basename is `/<region>` (e.g., `/sg`, `/id`). On load, `App.tsx` checks if the URL contains a valid region prefix; if not, it redirects to `/sg`. Region is stored in `src/_shared/utils/region.ts` and read from the URL path. Feature availability varies by region — see `bundlesFilter()` in `src/bundle.ts` and `siteConfigFilter()` in `src/config.ts`.

**10. How do I raise a Merge Request?**

Raise MRs to both `uat` and `master` branches for any feature or bug fix. Commit messages must follow the format `{type}[SPPA-xxxx]: {description}`. The commitlint hook enforces this automatically on commit.

<!-- Generated by ads-workspace/skills/ads-readme-generate | checked: 147a89af37a84b96263ea5d6eabafda1e8dd5948 | spec: 76fce5f679f9550b -->
