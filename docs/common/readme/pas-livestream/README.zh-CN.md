<!-- ads-workspace-gdoc-sync: gdoc_id=1pfjVqtOvB11b4NURim3dXSafiQEJVPbw5PK2VCIno4E gdoc_url=https://docs.google.com/document/d/1pfjVqtOvB11b4NURim3dXSafiQEJVPbw5PK2VCIno4E/edit -->

# pas-livestream

## 目录

- [项目概述](#项目概述)
- [核心功能](#核心功能)
- [项目架构](#项目架构)
- [目录结构](#目录结构)
- [开发规范](#开发规范)
  - [代码风格](#代码风格)
  - [项目结构](#项目结构)
  - [命名规范](#命名规范)
  - [错误处理](#错误处理)
  - [单元测试](#单元测试)
  - [Code Review & Git 工作流](#code-review--git-工作流)
- [快速开始](#快速开始)
  - [环境要求](#环境要求)
  - [配置说明](#配置说明)
  - [安装依赖](#安装依赖)
  - [构建](#构建)
  - [本地开发](#本地开发)
  - [开发说明](#开发说明)
  - [部署](#部署)
- [API 文档](#api-文档)
- [本地存储](#本地存储)
- [TMS 埋点追踪](#tms-埋点追踪)
- [性能监控](#性能监控)
- [业务术语表](#业务术语表)
- [参考资料](#参考资料)
- [常见问题](#常见问题)

---

## 项目概述

`pas-livestream` 是基于 Vue 3 + TypeScript 开发的 Shopee 广告微前端模块，用于在卖家中心（Seller Center）平台上创建、管理和分析直播带货广告（Live Stream Ads）活动。该模块基于 Multi-Module Framework（MMC/MMF）架构构建，通过 Webpack Module Federation 消费 `pas-common` 中的共享工具函数和组件，仅在卖家中心 Portal 内运行。

---

## 核心功能

- **直播广告创建**：多步骤创建流程，支持两种竞价目标——最大化 GMV（`MAX_GMV`）和最大化观看量（`MAX_VIEWS`）。
- **重启广告流程**：复用同一创建页面组件重启已结束的广告活动，并自动填充原活动数据。
- **重启最低预算提示横幅**：重启广告时，`getBudgetForCreation` 现在同时返回 `recommended`（推荐预算）和 `minBudget`（最低预算，来自 `GetBudgetForCreationRes.dailyBudget.min` / `.minBudget`）。若原活动的日预算低于 API 返回的最低预算，基础设置表单将显示一个警告 `EdsAlert` 横幅。预算输入的有效最低值在 `restartApiMinBudget` 有值时切换为该值。
- **目标 ROAS 配置**：针对最大化 GMV 目标的可选目标 ROAS 输入，支持从后端获取 ROAS 推荐值。
- **ROI Two 模式（Max GMV ROI Two / Max View ROI Two）**：通过功能开关控制的高级模式，发布时将 Max GMV / Max Views 广告目标自动转换为 `MAX_GMV_ROI_TWO` / `MAX_VIEW_ROI_TWO`。由 `/meta/get/` 中的 `adsToggle.liveStreamAds` 和 `adsToggle.liveStreamAdsViewMax` 控制。
- **广告详情页**：支持查看和编辑广告预算、投放时段（Time Slot）和 ROAS 目标；包含预算和时长警告横幅。
- **预算编辑最低预算提示**：详情页 `BudgetEditPopover` 内嵌一个 `EdsAlert`（`showMinBudgetPrompt`），当当前广告日预算低于 `latestMinBudget`（通过 `/setup_helper/get_budget_data_for_edit/` 获取）时显示。Popover 的 `minBudget` prop 接收 `latestMinBudget || minBudgetFinal`。
- **性能图表 & 报表**：由共享报告 API 驱动的按天时间序列图表和聚合报表。
- **Paid GMV / Placed GMV 指标标签**：当 `extToggle.szSupportPaidGmvMetrics` 开启时，性能图表和报表展示 Paid GMV 与 Placed GMV 的切换标签（GmvMetricSwitch）。Paid GMV 的日期范围下限受 `scConfig.paidGmvPhaseOneReleaseDate` 约束。图表和报表在 Paid GMV 标签激活时向 API 传入 `usePaidGmv: true` 参数。
- **预估 GMV / 观看量**：在创建页面实时显示预估表现区间，受预算和时间输入驱动。
- **活跃广告阈值检测**：当卖家活跃直播广告数量超限时阻止创建。
- **ROI Two 时间重叠检测**：当新创建或重启的广告时段与已存在的 ROI Two 广告重叠时发出警告。
- **ROI Two ROAS 编辑（升级弹窗）**：当 `enableSimpleRoiTwo` 开启时，详情页编辑 ROI Two 目标将打开 `RoiUpgradeModal` 而非标准的 `RoiModal`。
- **ROAS 编辑最低预算提示**：`RoiModal` 和 `RoiUpgradeModal` 均通过 `#extra-alert` 插槽展示最低预算提示（`targetRoasMinBudgetPromptText`），当 `showTargetRoasMinBudgetPrompt` 为 true 时触发。最低预算由 `performance-table/index.vue` 中的 `fetchTargetRoasMinBudget()` 通过 `getCampaignExpense`（`/setup_helper/get_budget_data_for_edit/`）获取，同时作为 `:extra-alert-text` prop 传入 `RoasModal`。
- **食品主播编辑限制（V2）**：当 `szAdsLiveLimitFoodSellerTwo` 功能开关激活时，`liveStreamAccount.streamerTypeList` 中包含 `FOOD` 但不包含 `MP` 的卖家无法编辑 ROAS 目标，编辑控件将显示提示浮层（`live_ads_food_streamer_deboost_tip_pc_hover`）。
- **功能开关**：
  - `metaConfig.adsToggle.liveStreamAds` — 启用 ROI Two 模式、目标 ROAS 编辑及创建/详情页主要功能（来源：`/meta/get/`）
  - `metaConfig.adsToggle.liveStreamAdsViewMax` — 启用 Max View ROI Two 目标（来源：`/meta/get/`）
  - `metaNonAdsConfig.extToggle.szSupportPaidGmvMetrics` — 启用 Paid GMV 指标标签（来源：`/meta/get_non_ads_data/`）
  - `metaNonAdsConfig.extToggle.szAutoBudgetIncrease` — 自动预算增加功能
  - `app.features?.support("szAdsLiveLimitFoodSellerTwo")` — 食品主播 ROAS 编辑限制
- **页面会话追踪**：每次路由导航时生成基于 UUID 的页面会话 ID，存储于 `localStorage` 的 `SELLER_CENTER_SHOPEE_ADS_PAGE_SESSION_ID` 键下。

---

## 项目架构

```
卖家中心 Portal (SC)
        │
        ▼
  MMF Runtime（模块联邦）
        │
        ├─── pas-livestream  ←── 本模块
        │         │
        │         ├── Webpack Module Federation 消费者
        │         └── 与 pas-common 共享运行时（类型、工具函数、组件）
        │
        └─── pas-common（MF 提供者）
                  ├── 共享类型/工具函数/组件
                  └── 埋点定义
```

**技术栈**

| 层级 | 技术 |
|---|---|
| 框架 | Vue 3 Composition API（`<script setup>`） |
| 语言 | TypeScript（严格模式） |
| 构建工具 | MMC（Multi-Module CLI）v3，Webpack 5 / Rsbuild |
| 模块联邦 | 与 `pas-common` 共享（类型、工具函数、组件） |
| UI 组件库 | EDS Vue（`eds-vue` v5） |
| 包管理器 | Yarn |
| 样式 | SCSS（组件级 scoped） |
| 状态管理 | `reactive()` 单例（不使用 Vuex/Pinia） |
| 路由 | 通过 `app.registerRouterModule` 注册到 `framework` 路由 |

**模块 ID**：`282`（在 Seller Portal 中注册，类型为 `module`，技术栈为 `vue3`）。

**路由前缀**：所有路由嵌套在 `/portal/marketing/pas/live-stream/` 下。

| 路由名称 | 路径 | 组件 |
|---|---|---|
| `PAS_LIVE_STREAM_ADS_INDEX_PAGE` | `/portal/marketing/pas/live-stream/` | `src/pages/index.vue` |
| `PAS_LIVE_STREAM_ADS_CREATE_PAGE` | `create` | `src/pages/create/index.vue` |
| `PAS_LIVE_STREAM_ADS_RESTART_PAGE` | `restart/:campaignId` | `src/pages/create/index.vue` |
| `PAS_LIVE_STREAM_ADS_DETAIL_PAGE` | `detail/:campaignId` | `src/pages/detail/index.vue` |

**详情页指标标签**：当 `szSupportPaidGmvMetrics` 开启时，详情页维护 `metricTab` 状态（`MetricType.PAID_GMV` 或 `MetricType.PLACED_GMV`）。当所选日期范围早于 `paidGmvPhaseOneReleaseDate` 时，标签自动切换为 `PLACED_GMV`。

---

## 目录结构

```
pas-livestream/
├── mmc.config.js                   # MMC 构建配置（模块 ID、webpack 扩展）
├── package.json                    # 依赖项和脚本
├── .gitlab-ci.yml                  # CI/CD 流水线（lint、e2e、部署）
├── config/
│   └── .remote-config.json         # 由 `yarn run init` 自动生成；本地路由/参数覆盖
└── src/
    ├── index.ts                    # 模块入口：注册路由、设置 EDS 语言
    ├── custom.d.ts                 # TypeScript 全局声明
    ├── track/
    │   └── index.ts                # 从 pas-common 重新导出所有埋点函数
    ├── pages/
    │   ├── index.vue               # 路由视图根组件（注册埋点指令、事件映射）
    │   ├── utils.ts                # 页面共用工具函数（如 openOperationLimitModal）
    │   ├── create/                 # 创建 & 重启页面
    │   │   ├── index.vue           # 创建/重启主页面组件
    │   │   ├── constant.ts         # 表单初始状态、验证规则、重叠确认弹窗逻辑
    │   │   ├── types.ts            # FormInstance、FormInstantInject 类型定义
    │   │   ├── basic-setting/      # 广告名称、日期、预算输入
    │   │   │   ├── date-picker-selection/
    │   │   │   └── time-picker-selection/
    │   │   ├── bidding-strategy/   # 目标选择（Max GMV / Max Views）
    │   │   │   └── target-roas/    # 目标 ROAS 配置子步骤
    │   │   ├── skeletor/           # 创建页面加载骨架屏
    │   │   ├── tab-selection/      # 标签页目标选择 UI
    │   │   ├── limitation-prompt/  # 活跃广告超限时展示的弹窗
    │   │   └── publish-result/     # 发布成功后的结果页面
    │   └── detail/                 # 广告详情页
    │       ├── index.vue           # 详情主页面组件（管理 metricTab 状态）
    │       ├── basic-campaign-info/ # 广告信息卡片（名称、状态、预算、时段）
    │       │   ├── budget-warning-banner/
    │       │   └── time-length-picker/
    │       ├── performance-chart/  # 时间序列图表（含 GmvMetricSwitch）
    │       ├── performance-table/  # 聚合指标报表（含 ROAS 编辑）
    │       │   └── roas-warning/
    │       └── skeletor/           # 详情页面加载骨架屏
    └── _shared/                    # 所有页面共享代码
        ├── api/
        │   ├── common/             # Meta、配置、横幅 API
        │   ├── live-stream/        # 广告 CRUD 及发布 API
        │   ├── report/             # 性能指标 API
        │   └── request/            # 基础请求工厂（commonRequest）
        ├── assets/
        │   ├── image/              # PNG 资源（头像、竞价策略图标）
        │   └── svg/                # SVG 图标（警告、信息、关闭）
        ├── components/
        │   ├── back-button/        # 返回导航按钮
        │   └── time-picker-range/  # 自定义时段范围选择器（HH:MM 格式）
        ├── composable/
        │   ├── use-creation-budget.ts   # 预算最小/最大值计算及 Toast 提示逻辑
        │   ├── use-duration.ts          # 报告日期范围状态及远端缓存同步
        │   ├── use-route.ts             # 路由参数和 query 辅助函数
        │   └── useSelectMetrics.ts      # 指标列选择逻辑
        ├── constants/
        │   ├── api.ts              # 所有 API 端点路径
        │   ├── app-config.ts       # 时间常量（ONE_HOUR、ONE_DAY 等）
        │   ├── campaign.ts         # MaxDate、ColdStartPhaseTrait
        │   ├── metric-item.ts      # 指标展示项定义
        │   ├── metrics-field.ts    # 指标字段键定义
        │   └── router.ts           # RouterMap 枚举、RouterPath、性能打点辅助函数
        ├── store/
        │   ├── config/
        │   │   ├── contantine.ts   # 配置仓库（adsConfig、货币、scConfig 等）
        │   │   ├── meta.ts         # 广告 Meta 仓库（adsCredit、hasAds、liveStreamAccount、adsToggle）
        │   │   └── meta-non-ads.ts # 功能开关仓库（extToggle 标志）
        │   └── report/             # 报告日期范围和加载状态仓库
        ├── styles/
        │   └── page.scss           # 全局页面样式（通过 webpack injectStyle 注入）
        ├── types/
        │   ├── campaign.ts         # CampaignInfo、LiveAdsCampaignInfo、Objective、TimeSlot
        │   └── index.ts            # 重新导出
        └── utils/
            ├── date-range.ts       # 日期范围辅助函数
            ├── report.tsx          # 报告格式化工具
            ├── router.ts           # URL 查询参数更新辅助函数
            ├── target-roas.ts      # 目标 ROAS 计算辅助函数
            └── time.ts             # 时间格式化及请求/响应转换
```

---

## 开发规范

### 代码风格

| 工具 | 配置 |
|---|---|
| TypeScript | 严格模式；类型级别标识符（`class`、`interface`、`enum`）须为 `PascalCase` 或 `UPPER_CASE`（ESLint `.eslintrc.js` 强制执行） |
| ESLint | 继承 `@shopee/pas-module-config/src/eslint/vue`（`.eslintrc.js`） |
| Stylelint | 继承 MMC 管理的 `.stylelintrc.json`（每次 `yarn run init` 会被覆盖） |
| Prettier | 继承 `@shopee/pas-module-config/src/prettier/index`（`.prettierrc.js`） |

每次提交前，Husky + lint-staged 自动对暂存的 `src/**/*.{ts,vue,css,scss,less}` 文件执行 Prettier + ESLint + Stylelint。

### 项目结构

- **页面**（`src/pages/`）：路由级组件。每个路由目录（`create/`、`detail/`）管理自身的子组件、常量和类型。
- **共享代码**（`src/_shared/`）：API 客户端、composable 函数、常量、状态单例、类型及各页面共用的工具函数。
- **状态管理**：`reactive()` 单例（不使用 Vuex/Pinia）。三个 store：`Constantine`（来自 `/config/get/` 的配置）、`metaConfig`（广告 meta + `adsToggle`）、`metaNonAdsConfig`（`extToggle` 功能开关）。
- **Composable**：可复用的 Vue 3 composable 函数位于 `src/_shared/composable/`，命名规范为 `use-*.ts`。

### 命名规范

- **类型级标识符**：`PascalCase` 或 `UPPER_CASE`（ESLint `@typescript-eslint/naming-convention` 规则，`typeLike` 选择器）。
- **Composable 文件**：`use-*.ts` 前缀（kebab-case）。
- **埋点函数**：遵循 `pas-common/tracking/entries/` 中的命名规范，禁止在 `pas-livestream` 内部定义埋点函数。
- **提交信息**：遵循 `commitlint`（继承 `@shopee/pas-module-config`）规定的 conventional commit 格式。

### 错误处理

- **发布错误**：通过 `PublishErrorCode` 枚举（`src/_shared/api/live-stream/types.ts`）处理。`DUPLICATE_NAME`、`HAS_EXCEEDED_AD_THRESHOLD`、`CAMPAIGN_LEVEL_RATE_LIMIT`、`PARTIAL_ERROR` 各有对应的 UI 反馈。
- **编辑错误**：`editCampaignInfo` 使用 `skipError: true`，手动对 `CAMPAIGN_LEVEL_RATE_LIMIT` 调用 `openOperationLimitModal`，其他错误调用 `EdsToastInstance.error`。
- **防抖函数**：须在 `onBeforeUnmount` 中取消，以防止内存泄漏（参见 `basic-setting/index.vue` 中的实现规范）。

### 单元测试

仓库中没有单元测试。功能正确性通过 `pas-e2e-tests` 中的 E2E 测试进行验证，由 CI 在合并请求到 `master`/`release` 分支时触发（标签：`@pas-livestream`）。

### Code Review & Git 工作流

- **提交前**：Husky 运行 lint-staged —— `*.{ts,vue}` 文件自动执行 Prettier + ESLint 修复；`*.{css,scss,less,vue}` 文件自动执行 Prettier + Stylelint 修复。
- **CI 阶段**：`lint` → `e2e_tests` → `release_verify` → `auto_deploy_test` → `auto_deploy_e2e_tests`（参见 `.gitlab-ci.yml`）。
- **推送前本地检查**：`yarn lint && yarn type:check`。

---

## 快速开始

### 环境要求

| 要求 | 版本 |
|---|---|
| Node.js | >= 16.14.0（推荐 Node 20） |
| pnpm | >= 8.0.0（推荐 pnpm 8） |
| MMC（Multi-Module CLI） | 最新 v3.x |
| Yarn | 任意版本（项目包管理器） |

**全局安装 MMC（首次使用前必须）：**

```bash
pnpm i -g @shopee/multi-module-cli

# 安装后运行一次性设置
mmc setup

# 验证安装（应显示 4 行版本信息）
mmc -V
```

### 配置说明

MMC 从 `mmc.config.js` 读取模块配置，关键字段如下：

```js
// mmc.config.js
module.exports = {
  id: 282,        // 在 Seller Portal 中注册的模块 ID
  type: "module",
  tech: "vue3",
  injectStyle: {
    scss: { inject: ["src/_shared/styles/page.scss"] },
  },
  // webpack 和 rsbuild 通过 @shopee/pas-module-config 扩展
};
```

执行 `yarn run init` 后，MMC 会自动生成 `config/.remote-config.json`，其中包含从 Seller Portal 测试环境拉取的路由和参数配置。可通过修改该文件中的 `router` 和 `params` 字段来覆盖本地开发路由，但注意该文件在每次执行 `yarn run init` 时会被**覆盖**。

### 安装依赖

在开始开发前（或清理项目后），运行一次 `yarn run init` 以安装依赖、获取 Portal 配置并生成所需配置文件。

```bash
# 为卖家中心安装依赖（Portal ID 为 21）
yarn run init -p 21
```

> **警告：** 运行 `yarn run init` 会覆盖 `.browserslistrc`、`.stylelintrc.json` 和 `tsconfig.json`，这些文件由 MMC 管理。

### 构建

```bash
# 本地构建（输出到 dist/）
yarn build
```

生产环境构建请通过 [Seller Portal](https://seller-portal.i.shopee.io/) 触发构建流水线（参见[部署](#部署)）。

### 本地开发

**第一步 — 启动开发服务器**

```bash
# 默认模式：使用本地 pas-common 开发服务器（需先启动 pas-common）
yarn dev

# 远程模式：从远端 master 分支加载 pas-common 类型
yarn dev:remote

# 快速启动：一条命令完成 init + 远程开发
yarn start

# 远程模式（指定 pas-common 分支）
LOCAL_DEV=1 branchName='<feature-branch>' mmc dev
```

> 若在未启动本地 pas-common 服务器的情况下运行 `yarn dev`，终端会出现：
> ```
> [FederatedTypesPlugin] Unable to download 'pas-common' remote types index file: connect ECONNREFUSED 127.0.0.1:8001
> ```
> 请改用 `yarn dev:remote`，或先启动本地 pas-common 服务器。

**第二步 — 打开卖家中心测试环境**

访问对应区域的卖家中心测试环境（如 `https://seller.test.shopee.sg`）。推荐使用 [Pas Helper Chrome 扩展](https://chromewebstore.google.com/detail/pas-helper/nhfhjiehemipamajmeimnnkinhncgpcd) 进行一键登录。

**第三步 — 连接本地开发服务器**

在浏览器 DevTools 中执行：

```js
mmfDevtools.enable()
```

或使用 SC 页面工具栏中的 **MMF DevTools** UI。启用后刷新页面，浏览器将从本地开发服务器加载资源。控制台出现 `[MMF_DEVTOOLS]` 输出和 `[HMR] connected` 时表示连接成功。

### 开发说明

**配合 pas-common 开发**

修改 `pas-common` 时，需先启动 pas-common 本地开发服务器，再使用 `yarn dev` 加载本地类型。如果只是消费 pas-common 的 master 分支内容，使用 `yarn dev:remote` 即可。

**类型检查（监听模式）**

```bash
# 已通过 concurrently 集成在 `yarn dev` 中
vue-tsc -w --noEmit --pretty

# 一次性类型检查
yarn type:check
```

**代码检查**

```bash
yarn lint           # ESLint + Stylelint
yarn lint:es:fix    # 自动修复 ESLint 问题
yarn lint:style:fix  # 自动修复 Stylelint 问题
yarn prettier       # 使用 Prettier 格式化
```

### 部署

生产构建和发布通过 [Seller Portal](https://seller-portal.i.shopee.io/) 管理：

1. 在 Seller Portal 中找到 `pas-livestream`（模块 ID `282`）对应的模块组。
2. 填写构建信息表单，点击 **Build** 开始构建。
3. 构建成功后，在 Action 列点击 **Publish**。
4. 在发布表单中选择目标 Portal、PFB 和区域，点击 **Publish** 完成发布。

**CI/CD 流水线**（`.gitlab-ci.yml`）：

| 阶段 | 任务 | 触发条件 | 说明 |
|---|---|---|---|
| `lint` | `lint` | 合并请求 | 运行 `yarn lint`（ESLint + Stylelint） |
| `parallel_jobs` | `ai-code-review` | 合并请求 | AI 代码审查 |
| `e2e_tests` | `e2e_tests` | 合并请求到 master/release | 触发 `pas-e2e-tests`，标签 `@pas-livestream` |
| `release_verify` | `release_verify` | 合并请求 | 通过 deploy-platform API 验证发布 |
| `auto_deploy` | `auto_deploy_test` | 推送到 master/release（合并提交） | 自动部署到测试环境，PFB `pfb-ads-platform-e2e` |
| `auto_deploy` | `auto_deploy_uat` | 推送到 master | 自动部署到 UAT 环境 |
| `auto_deploy_e2e` | `auto_deploy_e2e_tests` | `auto_deploy_test` 完成后 | 部署后触发 E2E 测试 |

```bash
# CI/CD 自动化发布（CI 流水线中使用）
yarn deploy:ci
```

> **下线模式**：若需下线该模块，在构建前开启"Offline Mode"并完成构建发布。下线后，该模块的所有路由将无法访问。

---

## API 文档

所有 API 端点均定义在 `src/_shared/constants/api.ts` 中，格式为 `export const API = { ... } as const`。请求工厂位于 `src/_shared/api/request/index.ts`，通过懒加载从 `pas-common/request` 创建 `commonRequest` 实例，基础 URL 路由由框架内部统一处理。

### 端点参考

| 页面 | 页面 URL | API 端点 | 说明 |
|---|---|---|---|
| 全局 | `/portal/marketing/pas/live-stream/` | `/meta/get/` | 获取广告信用额度、adsToggle 标志、hasAds 及直播账号信息 |
| 全局 | `/portal/marketing/pas/live-stream/` | `/meta/get_non_ads_data/` | 获取 extToggle 功能开关标志（如 `szSupportPaidGmvMetrics`） |
| 全局 | `/portal/marketing/pas/live-stream/` | `/config/get/` | 获取 Constantine 配置（预算限制、ROAS 设置、货币、scConfig） |
| 全局 | `/portal/marketing/pas/live-stream/` | `/report/get_config/` | 获取报告时间范围配置 |
| 全局 | `/portal/marketing/pas/live-stream/` | `/banner/get/` | 获取横幅展示状态（如 ROI Two 创建页横幅、时间选择器提示） |
| 全局 | `/portal/marketing/pas/live-stream/` | `/banner/modify/` | 更新全局横幅操作 |
| 全局 | `/portal/marketing/pas/live-stream/` | `/banner/campaign_get/` | 获取广告级别横幅状态 |
| 全局 | `/portal/marketing/pas/live-stream/` | `/banner/campaign_modify/` | 更新广告级别横幅操作 |
| 创建 / 重启 | `.../live-stream/create` | `/live_stream/get_setup_status/` | 获取创建时的默认广告名称 |
| 创建 / 重启 | `.../live-stream/create` | `/live_stream/publish/` | 创建或重启直播广告活动 |
| 创建 / 重启 | `.../live-stream/create` | `/live_stream/get_estimated_data/` | 根据预算和时间设置获取预估 GMV 区间 |
| 创建 / 重启 | `.../live-stream/create` | `/live_stream/get_budget_data_for_creation/` | 获取创建/重启时的推荐预算和最低预算。返回 `{ recommended, minBudget }`（来自 `dailyBudget.min` / `dailyBudget.minBudget`）。`minBudget` 在重启流程中作为有效最低预算使用 |
| 创建 / 重启 | `.../live-stream/create` | `/live_stream/check_active_campaign_threshold/` | 检查卖家是否超过活跃广告数量阈值 |
| 创建 / 重启 | `.../live-stream/create` | `/live_stream/check_overlapping_ads_for_roi_two/` | 检查与已有 ROI Two 广告的时间重叠 |
| 创建 / 重启 | `.../live-stream/create` | `/setup_helper/get_recommended_target_roi/` | 获取带百分位区间的推荐目标 ROAS 值 |
| 详情 | `.../live-stream/detail/:campaignId` | `/live_stream/get/` | 根据 `campaignId` 获取广告详情 |
| 详情 | `.../live-stream/detail/:campaignId` | `/live_stream/edit/` | 编辑已有广告的预算、时段、ROAS 目标或 ROI Two 目标 |
| 详情 | `.../live-stream/detail/:campaignId` | `/setup_helper/get_budget_data_for_edit/` | 获取编辑时的预算约束数据。由 `basic-campaign-info`（获取预算编辑弹窗的 `latestMinBudget`）和 `performance-table` 通过 `fetchTargetRoasMinBudget()` 使用（获取 ROAS 编辑弹窗的最低预算） |
| 详情 | `.../live-stream/detail/:campaignId` | `/report/get/` | 获取报表聚合性能指标（支持 `usePaidGmv` 参数） |
| 详情 | `.../live-stream/detail/:campaignId` | `/report/get_time_graph/` | 获取图表时间序列性能数据（支持 `usePaidGmv` 参数） |
| 详情 | `.../live-stream/detail/:campaignId` | `/report/update_time_config/` | 将用户选择的日期范围持久化到后端 |
| 详情 | `.../live-stream/detail/:campaignId` | `/report/update_selected_metric_config/` | 将用户选择的指标列持久化到后端 |

**数字转换**：后端将所有金额/比率值乘以 100,000 以避免浮点精度问题。读取 API 响应时使用 `convertServerNumber`（÷100,000），发送请求时使用 `convertClientNumber`（×100,000），均从 `pas-common/utils` 导入。

**请求工厂**：所有 API 调用使用 `src/_shared/api/request/index.ts` 中的 `commonRequest`，通过懒加载并以泛型提供类型安全：
```typescript
commonRequest<RequestType, ResponseType>(endpoint, { params, skipError? })
```

**Paid GMV API 参数**：当 Paid GMV 指标标签激活时（`metricTab === MetricType.PAID_GMV`），`getTimeGraph` 和 `getReport` 均在请求体中携带 `usePaidGmv: true`，以从后端获取基于 Paid GMV 的指标数据。

---

## 本地存储

| 键名 | 值 | 设置位置 | 说明 |
|---|---|---|---|
| `SELLER_CENTER_SHOPEE_ADS_PAGE_SESSION_ID` | UUID v4 字符串 | `src/_shared/router/index.ts` | 在 `/portal/marketing/pas/` 下每次路由导航时生成。用于分析事件中的页面会话追踪。页面刷新或路径变化时重新生成；同路径操作（表单提交、数据刷新）时保持不变。 |

---

## TMS 埋点追踪

所有埋点函数均在 `src/track/index.ts` 中从 `pas-common` 的埋点入口文件重新导出：

```typescript
// src/track/index.ts
export * from "pas-common/tracking/entries/sellerCenterLivestreamAdDetail";
export * from "pas-common/tracking/entries/createLiveAds";
export * from "pas-common/tracking/entries/sellerCenterShopeeAds";
export * from "pas-common/tracking/entries/sellerCenterRestartLivestreamAd";
export * from "pas-common/tracking/entries/sellerCenterCreateLiveAds";
```

**规范**：始终从 `src/track`（而非直接从 `pas-common`）导入埋点函数。不要在 `pas-livestream` 内部定义新埋点函数——请先在 `pas-common` 埋点入口文件中添加，再从 `src/track/index.ts` 重新导出。

**模块常用埋点事件：**

| 事件类型 | 函数名 | 触发时机 |
|---|---|---|
| 页面浏览 | `reportViewOfSCCreateLiveAds` | 创建页面挂载 |
| 页面浏览 | `reportViewOfSCRestartLivestreamAd` | 重启页面挂载 |
| 页面浏览 | `reportViewOfSCLivestreamAdDtl` | 详情页面挂载 |
| 点击 | `reportClickOfCreateLiveAdsBottomActionLiveAdsPublish` | 点击发布按钮 |
| 点击 | `reportClickOfCreateLiveAdsBottomActionLiveAdsCancel` | 点击取消按钮 |
| 曝光 | `reportImpOfSCLivestreamAdDtlPerfPerf` | 性能图表可见 |
| 点击 | `reportClickOfSCLivestreamAdDtlPerfGmvDefinitionSelection` | 切换 GMV 指标标签 |
| 曝光 | `reportImpOfSCLivestreamAdDtlPerfGmvDefinitionSelection` | 详情页挂载时上报初始指标标签状态 |
| 曝光 | `reportImpOfSCLivestreamAdDtlTimeSelectorPromptTimeSelectorPrompt` | 日期范围提示弹出 |
| 点击 | `reportClickOfSCLivestreamAdDtlTimeSelectorPromptGotIt` | 关闭日期范围提示 |

**`v-track-impression` 指令**：通过 `src/pages/index.vue` 中的 `useTrackingDirective()`（来自 `pas-common/tracking`）全局注册。用法：
```vue
<PerformanceChart v-track-impression="reportImpFn" />
```

---

## 性能监控

本模块使用浏览器 [Performance API](https://developer.mozilla.org/en-US/docs/Web/API/Performance) 测量页面加载时间。性能打点和测量均定义在 `src/_shared/constants/router.ts` 中。

**性能打点**

| 常量 | 打点名称 | 设置时机 |
|---|---|---|
| `PERFORMANCE_MARK_INDEX_ENTER` | `pas_livestream_ads_index_enter` | 根路由 `beforeEnter` |
| `PERFORMANCE_MARK_CREATE_ENTER` | `pas_livestream_ads_create_enter` | 创建/重启路由 `beforeEnter` |
| `PERFORMANCE_MARK_DETAIL_ENTER` | `pas_livestream_ads_detail_enter` | 详情路由 `beforeEnter` |
| `PERFORMANCE_MARK_CREATE_MOUNTED` | `pas_livestream_ads_create_mounted` | 创建页面 `onMounted` |
| `PERFORMANCE_MARK_DETAIL_MOUNTED` | `pas_livestream_ads_detail_mounted` | 详情页面 `onMounted` |

**性能测量**

| 测量名称 | 起始打点 | 结束打点 | 含义 |
|---|---|---|---|
| `module_enter_to_create` | `_index_enter` | `_create_enter` | 从模块入口到创建路由进入的耗时 |
| `create_enter_to_mounted` | `_create_enter` | `_create_mounted` | 从创建路由进入到组件挂载的耗时 |
| `module_enter_to_create_mounted` | `_index_enter` | `_create_mounted` | 从模块入口到创建页面就绪的总耗时 |
| `module_enter_to_detail` | `_index_enter` | `_detail_enter` | 从模块入口到详情路由进入的耗时 |
| `detail_enter_to_mounted` | `_detail_enter` | `_detail_mounted` | 从详情路由进入到组件挂载的耗时 |
| `module_enter_to_detail_mounted` | `_index_enter` | `_detail_mounted` | 从模块入口到详情页面就绪的总耗时 |

**测量函数**

```typescript
generateCreatePerformanceData()   // 返回 { moduleToEnter, enterToMounted, moduleToMounted }（毫秒）
generateDetailPerformanceData()   // 返回 { moduleToEnter, enterToMounted, moduleToMounted }（毫秒）
```

这些数值作为属性传递给对应的页面浏览埋点事件（如 `reportViewOfSCCreateLiveAds({ ...performanceData })`）。

---

## 业务术语表

| 术语 | 说明 |
|---|---|
| **直播广告（Live Stream Ads）** | 允许卖家在 Shopee 直播带货过程中投放广告以推广商品的广告类型 |
| **最大化 GMV（Max GMV）** | 以最大化直播商品交易总额为目标的竞价目标 |
| **最大化观看量（Max Views）** | 以最大化直播观看人数为目标的竞价目标 |
| **Max GMV ROI Two** | ROI Two 启用时使用的内部目标值（`MAX_GMV_ROI_TWO`），发布时由 Max GMV 自动转换。由 `adsToggle.liveStreamAds` 控制 |
| **Max View ROI Two** | 内部目标值（`MAX_VIEW_ROI_TWO`），当 `adsToggle.liveStreamAdsViewMax` 开启时由 Max Views 转换 |
| **目标 ROAS（Target ROAS）** | （广告支出回报率）卖家设定的 ROAS 下限，系统将尽力维持 |
| **ROI Two** | 第二代 ROAS 优化模式，控制更为严格 |
| **日预算（Daily Budget）** | 卖家愿意为一个广告活动每天支出的最大金额 |
| **时段（Time Slot）** | 直播广告在一天内投放的 HH:MM–HH:MM 时间窗口 |
| **Constantine** | 从 `/config/get/` 填充的本地响应式配置仓库；存储预算限制、竞价设置、货币配置及 `scConfig` 等 |
| **adsToggle** | 来自 `/meta/get/`（类型 `ADS_TOGGLE`）的功能开关对象；控制直播广告主要功能的灰度发布 |
| **extToggle** | 来自 `/meta/get_non_ads_data/`（类型 `EXT_TOGGLE`）的功能开关对象；控制附加实验性功能 |
| **Paid GMV** | 基于付费归因模型的 GMV 指标变体。由 `extToggle.szSupportPaidGmvMetrics` 控制。日期范围下限受 `scConfig.paidGmvPhaseOneReleaseDate` 约束 |
| **Placed GMV** | 基于下单归因模型的默认 GMV 指标。当 Paid GMV 标签不可用或被禁用时显示 |
| **食品主播（Food Streamer）** | 卖家主播类型（`StreamerType.FOOD`），受额外编辑限制约束；通过 meta 中 `liveStreamAccount.streamerTypeList` 识别 |
| **CIR** | （成本收入比）广告收入 / 广告 GMV；ROAS/ROI 的倒数 |
| **ROAS** | （广告支出回报率）广告 GMV / 广告收入；ROI 的同义词 |
| **CPC** | （每次点击成本）每次广告点击的花费 |
| **CPM** | （千次展示成本）每 1,000 次广告展示的费用 |
| **CTR** | （点击率）总点击次数 / 总展示次数 |
| **CR** | （转化率）广告订单数 / 总点击次数 |
| **冷启动（Cold Start）** | 新广告活动初期，系统因缺乏数据而无法进行精准预测的阶段 |
| **SC** | Seller Center（卖家中心）——本模块所在的 Shopee 卖家管理平台 |
| **MMF / MMC** | Multi-Module Framework / Multi-Module CLI——支撑本模块的微前端基础设施 |
| **QSS** | QuickStart Service（快速启动服务）——帮助新广告主快速提升广告使用量的项目 |
| **MCN** | Multi-Channel Network（多频道网络）——MCN 机构可在此平台为旗下达人创建直播广告 |

---

## 参考资料

- [MMC 文档](https://seller-portal.i.test.shopee.io/mmc-docs/guide/getting-started.html)
- [MMC 初始化指南](https://seller-portal.i.test.shopee.io/mmc-docs/guide/basic/initialization.html)
- [MMC 开发指南](https://seller-portal.i.test.shopee.io/mmc-docs/guide/basic/development.html)
- [Seller Portal 构建与发布](https://seller-portal.i.test.shopee.io/docs/pages/seller-portal/build-and-release.html)
- [广告平台前端概述](https://sra.test.shopee.io/05.Business_Systems/5.3_Ads_Business_and_Architecture_Introduction/5.3.6._ads.platform.html)
- [Pas Helper Chrome 扩展](https://chromewebstore.google.com/detail/pas-helper/nhfhjiehemipamajmeimnnkinhncgpcd)
- [pas-common 代码仓库](https://git.garena.com/shopee/isfe/ao/pas-common)
- [pas-livestream 代码仓库](https://git.garena.com/shopee/isfe/ao/pas-livestream)
- [Paid Ads 术语表](https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPAD&title=Paid+Ads+Glossary)

---

## 常见问题

**1. 如何首次开始本地开发？**

运行一次 `yarn run init -p 21` 以安装依赖并获取卖家中心 Portal 配置。然后运行 `yarn dev`（需提前启动本地 pas-common 服务器）或 `yarn dev:remote` 启动开发服务器。也可以使用 `yarn start` 一条命令完成初始化和远程开发。打开 SC 测试环境后，在 DevTools 中运行 `mmfDevtools.enable()` 进行连接。

**2. 为什么 `yarn dev` 显示 pas-common 连接被拒绝的错误？**

这是因为在未启动本地 pas-common 开发服务器的情况下运行了本地模式（`yarn dev`）。请先启动 pas-common 本地服务器，或改用 `yarn dev:remote`（从 master 分支加载类型）。

**3. 创建流程和重启流程有什么区别？**

两个流程共用同一个 `src/pages/create/index.vue` 组件。区别在于路由名称：若当前路由为 `RouterMap.RESTART_PAGE`，页面会预加载已有广告数据、禁用目标选择器，并将按钮文案改为"重启"。

**4. 什么情况下使用 `MAX_GMV_ROI_TWO` 而非 `MAX_GMV`？**

当 ROI Two 功能开启（`adsToggle.liveStreamAds` 为 true）时，实际发送给后端的目标值是 `MAX_GMV_ROI_TWO`。UI 层面仍以"最大化 GMV"呈现；转换逻辑在调用 `publishLiveStreamAds` 前由 `prepareCampaignParams` 完成。注意：此开关来自 `adsToggle`（`/meta/get/`），而非 `extToggle`。

**5. 功能开关在本模块中如何工作？**

本模块有两套开关系统：
- `metaConfig.adsToggle`（来自 `/meta/get/`，类型 `ADS_TOGGLE`）：控制 ROI Two 模式（`liveStreamAds`）和 Max View ROI Two（`liveStreamAdsViewMax`）。
- `metaNonAdsConfig.extToggle`（来自 `/meta/get_non_ads_data/`）：控制附加功能，如 `szSupportPaidGmvMetrics`（Paid GMV 指标标签）。
主路由守卫会在 `adsToggle.liveStreamAds` 为假值时重定向到 PAS 首页。

**6. 如何处理与 API 之间的数字传输？**

后端将所有金额/比率值乘以 100,000 以规避浮点精度问题。读取响应时使用 `convertServerNumber`（÷100,000），发送请求时使用 `convertClientNumber`（×100,000），均从 `pas-common/utils` 导入。

**7. `Constantine` 仓库是什么？存储哪些内容？**

`Constantine` 是 `src/_shared/store/config/contantine.ts` 中的 `reactive<ConfigListRes>` 对象，由路由进入时调用 `getConfig()` 填充。存储直播广告配置（最小/最大预算、ROAS 设置、货币精度、功能降级标志、`scConfig.paidGmvPhaseOneReleaseDate` 等）。

**8. 如何添加新的埋点事件？**

不要在本模块内创建埋点函数。请在 `pas-common/tracking/entries/` 的对应入口文件中添加事件定义，然后在 `pas-livestream` 的 `src/track/index.ts` 中重新导出。组件中从 `src/track` 导入埋点函数。

**9. 哪些文件是自动生成的、不应手动编辑？**

`config/.remote-config.json` 在每次执行 `yarn run init` 时都会被覆盖。`.browserslistrc`、`.stylelintrc.json` 和 `tsconfig.json` 也会在 MMC 初始化时被覆盖，请通过修改 MMC 配置进行自定义。

**10. Paid GMV / Placed GMV 指标标签如何工作？**

当 `extToggle.szSupportPaidGmvMetrics` 开启时，详情页在性能图表中展示 `GmvMetricSwitch` 切换组件。`metricTab` 状态（`MetricType.PAID_GMV` 或 `MetricType.PLACED_GMV`）在 `detail/index.vue` 中管理，并向下传递给图表和报表组件。当所选日期范围早于 `scConfig.paidGmvPhaseOneReleaseDate` 时，标签自动切换为 `PLACED_GMV`，`disablePaidGmv` 置为 `true`。

<!-- Generated by ads-workspace/skills/ads-readme-generate | checked: 016db11b95c20c1ee2889eb289facecab4bd5ffb | spec: 76fce5f679f9550b -->
