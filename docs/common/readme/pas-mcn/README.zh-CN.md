<!-- ads-workspace-gdoc-sync: gdoc_id=10SJuy9qhGM22O3q0lnhnV13UBUjAsfTFsNgP7cVWqhk gdoc_url=https://docs.google.com/document/d/10SJuy9qhGM22O3q0lnhnV13UBUjAsfTFsNgP7cVWqhk/edit -->

# pas-mcn

> MCN（多频道网络）广告入口模块 — 基于 Multi-Module Framework (MMF) 构建，运行于 Shopee Seller Portal。模块 ID：**310**。支持地区：印度尼西亚（`id`）、越南（`vn`）。
>
> GitLab: https://git.garena.com/shopee/isfe/ao/pas-mcn

---

## 目录 / Table of Contents

- [项目概述](#项目概述)
- [核心功能](#核心功能)
- [项目架构](#项目架构)
- [目录结构](#目录结构)
- [快速开始](#快速开始)
  - [前置条件](#前置条件)
  - [配置](#配置)
  - [安装](#安装)
  - [构建](#构建)
  - [本地开发](#本地开发)
  - [开发流程](#开发流程)
  - [部署](#部署)
- [API 文档](#api-文档)
- [本地存储](#本地存储)
- [TMS 埋点](#tms-埋点)
- [性能监控](#性能监控)
- [业务术语表](#业务术语表)
- [参考资料](#参考资料)
- [常见问题](#常见问题)

---

## 项目概述

`pas-mcn` 是一个 Vue 3 模块，提供 Shopee MCN（多频道网络）广告入口功能。MCN 运营方可通过该模块创建并管理直播广告活动、查看聚合及单个 Affiliate 的表现数据、进行预算充值以及查看交易记录，所有功能均在 Seller Portal 的 Multi-Module Framework 体系内运行。

---

## 核心功能

- **直播广告活动管理** — 创建新活动、重启暂停活动、编辑设置（排期、预算、出价），查看含绩效图表与数据表格的活动详情页。
- **MCN 首页看板** — 跨所有 Affiliate 的聚合视图：广告余额、核心 KPI 指标、广告统计表、Affiliate 统计表。
- **Affiliate 单独首页** — 针对单个 Affiliate 的活动与表现数据下钻视图。
- **目标 ROAS 出价策略** — 支持最大化 GMV 与最大化观看量两种出价模式，可配置目标 ROI/ROAS。
- **批量编辑** — 对多个活动同时修改状态、预算或其他设置。
- **绩效分析** — 时序图表、分指标数据，支持导出 CSV。
- **充值与交易管理** — 通过结算流程发起充值，查看含 MCN 专属导出功能的完整交易记录。
- **多语言支持** — 通过 EDS Vue `i18n` 系统支持 20+ 种语言。
- **地区感知路由** — 模块仅面向 `id` 和 `vn` 地区开放，支持从旧版 Seller Center 路由跳转。

---

## 项目架构

### 模块组成

`pas-mcn` 是一个 MMF **模块**（非 portal）。它由 Seller Portal 宿主通过 Multi-Module Framework 运行时动态加载。入口文件为 `src/index.ts`，通过 framework 导出注册路由、store 和根 Vue 应用。

```
Seller Portal（宿主）
  └── MMF 运行时
        └── pas-mcn（模块 310）         ← 本仓库
              ├── framework（共享 MMF 上下文：router、i18n、environment、request）
              └── pas-common（CDN 远程模块，共享广告工具库）
```

`pas-common` 默认从 CDN（`config.cdnPrefix`）加载。如需本地调试，在 `mmc.config.js` 中注释掉 `remoteAppHost = config.cdnPrefix` 并在本地启动 `pas-common`。

### 状态管理

Store 直接使用 **Vue 3 `reactive()`**（不依赖 Pinia 或 Vuex 模块）。共四个 store 切片：

| Store 文件 | 内容 |
|---|---|
| `src/_shared/store/config/meta.ts` | `adsToggle`、`adsCredit`、广告元数据 |
| `src/_shared/store/config/contantine.ts` | `ADS_CONFIG`、`BID_PRICE`、`CURRENCY`、`LINK`、`NUMBER_CONSTANTS`、`FEATURE_DOWNGRADE` |
| `src/_shared/store/config/meta-non-ads.ts` | 外部开关、用户店铺信息 |
| `src/_shared/store/report/index.ts` | `summaryDate`、`cachedTimeRange`、`selectedMetrics`、`reportLoadStatus` |

### 路由

基础路径：`/portal/pas`。路由定义在 `src/router/index.ts` 的 `RouterMap` 枚举中：

| 路由名称 | 路径 | 页面 |
|---|---|---|
| `MCN_HOMEPAGE` | `/portal/pas` | `pages/homepage` |
| `MCN_AFFILIATE_HOMEPAGE` | `/affiliate/:affiliateId` | `pages/affiliateHomepage` |
| `MCN_LIVE_CREATE` | `/live/create` | `pages/create` |
| `MCN_LIVE_RESTART` | `/live/restart/:campaignId` | `pages/create` |
| `MCN_LIVE_DETAIL` | `/live/detail/:campaignId` | `pages/detail` |
| `MCN_TOP_UP` | `/top-up` | `pages/top-up` |
| `MCN_TRANSACTION` | `/transaction` | `pages/transaction` |

旧版 Seller Center 路由（`SC_HOMEPAGE`、`SC_TOPUP`）重定向至新路径。

### 请求层

所有 API 调用经由 `src/_shared/api/request/index.ts` 处理，基于 `@seller-portal/request`（axios 封装）。特性：

- GET 参数自动 camelCase → snake_case 转换
- 限流错误处理（错误码 7）
- Seller Gateway session 刷新（`refresh-seller-gateway-session.ts`）
- 地区感知 base URL（`*.shopee.sg`、`*.shopee.co.id` 等）
- `withCredentials: true`；通过 EDS 弹出错误提示

---

## 目录结构

```
pas-mcn/
├── src/
│   ├── _shared/                      # 跨页面共享层
│   │   ├── api/                      # 按业务域拆分的 API 模块
│   │   │   ├── affiliate/            # Affiliate 搜索与详情
│   │   │   ├── common/               # Meta、Config、Banner
│   │   │   ├── homepage/             # MCN 及 Affiliate 首页查询
│   │   │   ├── live-stream/          # 活动增删改查与估算
│   │   │   ├── report/               # 图表、指标、导出
│   │   │   ├── request/              # HTTP 客户端与拦截器
│   │   │   ├── top-up/               # 充值设置
│   │   │   └── transaction/          # 交易记录与导出
│   │   ├── assets/                   # 图片（PNG）与 SVG
│   │   ├── components/               # 可复用 Vue 组件
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
│   │   ├── composable/               # Vue 3 组合式函数
│   │   │   ├── useCreationBudget.ts
│   │   │   ├── useDuration.ts
│   │   │   ├── usePagination.ts
│   │   │   ├── useRoute.ts
│   │   │   └── useSelectMetrics.tsx
│   │   ├── constants/                # API 端点、活动枚举、指标配置
│   │   ├── framework/                # MMF framework 导出（router、i18n、request、environment）
│   │   ├── routes/                   # 共享路由定义
│   │   ├── store/                    # 响应式 store（config/、report/）
│   │   ├── styles/                   # 全局 SCSS（page.scss）
│   │   ├── types/                    # TypeScript 类型（campaign、common）
│   │   └── utils/                   # csv、currency、date、time、type 工具函数
│   ├── pages/
│   │   ├── index.vue                 # 根布局容器
│   │   ├── homepage/                 # MCN 聚合首页
│   │   ├── affiliateHomepage/        # 单 Affiliate 首页
│   │   ├── create/                   # 活动创建与重启
│   │   ├── detail/                   # 活动详情与编辑
│   │   ├── top-up/                   # 充值 / 支付
│   │   └── transaction/              # 交易记录
│   ├── router/                       # Vue Router 配置（index.ts）
│   ├── track/                        # TMS 埋点事件函数
│   └── index.ts                      # 模块入口
├── config/                           # 构建辅助配置（babel、eslint、tsconfig）
├── mmc.config.js                     # MMC 模块配置（ID: 310，tech: vue3）
├── .gitlab-ci.yml                    # CI/CD：lint → release_verify → auto_deploy
├── eslintrc.js                       # ESLint 配置（继承 @shopee/pas-module-config）
├── commitlint.config.js              # Commitlint 配置
└── package.json
```

---

## 快速开始

### 前置条件

| 工具 | 版本要求 |
|---|---|
| Node.js | >= 16.14.0（推荐 Node 20） |
| pnpm | >= 8.0.0 |
| yarn | 任意版本 |
| MMC | 最新 V3.x |

### 配置

安装依赖前，先将 npm registry 指向 Shopee 内部源：

```bash
npm config set registry https://npm.shopee.io/
```

### 安装

全局安装 MMC（仅需一次，已安装可跳过）：

```bash
pnpm i -g @shopee/multi-module-cli
mmc setup        # 配置 MMC 环境
mmc -V           # 验证安装：应显示 4 行版本信息
```

安装项目依赖并初始化模块：

```bash
# 推荐：一步完成依赖安装 + mmc init
yarn start

# 或分步执行：
yarn run init    # 首次开发前执行一次
yarn dev
```

`mmc init` 从 Seller Portal 测试环境拉取模块配置并写入 `config/.remote-config.json`。

### 构建

```bash
yarn build
```

执行 `mmc build` 进行生产构建，产物输出至 `dist/`。

### 本地开发

1. 运行 `yarn start`（或首次执行 `yarn run init`，之后执行 `yarn dev`）。
2. 打开 MCN 测试入口：[https://mcn.affiliate.test.shopee.co.id](https://mcn.affiliate.test.shopee.co.id)
3. 使用测试账号登录：
   - 用户名：`mcn_id.2`
   - 密码：`123456`
4. 在左侧导航栏点击 **Shopee Ads**。
5. 打开浏览器 DevTools 控制台，执行：
   ```js
   window.proxy.mmfDevtools.enable()
   ```
6. 刷新页面 — portal 连接到本地开发服务器。控制台应出现 `[MMF_DEVTOOLS]` 和 `[HMR] connected`。

#### 本地联调 pas-common

默认情况下，`pas-common` 从 CDN 加载。如需调试 `pas-common` 本地变更：

1. 在本地启动 `pas-common` 开发服务器。
2. 在 `mmc.config.js` 中注释掉以下行：
   ```js
   // remoteAppHost = config.cdnPrefix
   ```

### 开发流程

```bash
yarn dev            # 启动开发服务器（含并发类型检查）
yarn dev:remote     # 远程开发模式
yarn type:check     # 仅执行 TypeScript 校验
yarn lint           # ESLint + Stylelint
yarn lint:fix       # 自动修复 lint 问题
```

### 部署

CI/CD 流水线定义在 `.gitlab-ci.yml`：

| 阶段 | 触发时机 | 操作 |
|---|---|---|
| `lint` | 每次 MR | `yarn lint` |
| `release_verify` | MR + push | 通过部署平台 API 校验发布 |
| `auto_deploy` | push 到 `master` | 自动部署到 test 和 UAT 环境 |

生产发布流程：

1. 运行 `yarn build` 或在 Seller Portal 部署平台触发构建。
2. 构建成功后，在构建记录表中点击 **Publish**。
3. 在发布表单中选择 portal、PFB 和目标地区。
4. 提交后，Space 作业负责实际部署。

如需下线模块，构建前开启 **Offline Mode** 再执行发布。

---

## API 文档

所有端点路径相对于 base prefix（见 `src/_shared/api/request/base.ts`）。可用前缀：

| 前缀常量 | 值 |
|---|---|
| `V1` | `/api/pas_mcn/v1` |
| `FREE` | *（空值，不添加前缀）* |

| 页面 | API 端点 | 说明 |
|---|---|---|
| 公共 | `/meta/get/` | 获取广告元数据（`adsToggle`、`adsCredit` 等） |
| 公共 | `/config/get/` | 获取运行时配置 |
| 公共 | `/meta/get_ads_data/` | 获取广告数据 |
| 公共 | `/meta/get_non_ads_data/` | 获取非广告数据（外部开关、店铺信息） |
| 公共 | `/setup_helper/get_budget_data_for_edit/` | 获取编辑活动时的预算数据 |
| 公共 | `/banner/get/` | 获取 Banner 信息 |
| 公共 | `/banner/modify/` | 修改 Banner |
| 公共 | `/setup_helper/get_recommended_roi_two_target/` | 获取推荐 ROI 目标值 |
| 公共 | `/api/v2/pas/login/` | 登录 Seller Platform（使用 `FREE` 前缀） |
| 首页 | `/homepage/query_for_mcn/` | 查询 MCN 首页聚合数据 |
| 首页 | `/homepage/query_affiliate_for_mcn/` | 查询 MCN 下单个 Affiliate 数据 |
| 首页 | `/homepage/mass_edit/` | 批量编辑活动状态/预算 |
| 直播广告 | `/live_stream/get_setup_status/` | 获取活动配置状态 |
| 直播广告 | `/live_stream/publish/` | 发布（创建）新活动 |
| 直播广告 | `/live_stream/edit/` | 编辑现有活动 |
| 直播广告 | `/live_stream/get/` | 获取活动数据 |
| 直播广告 | `/live_stream/get_estimated_data/` | 获取活动预估表现数据 |
| 直播广告 | `/live_stream/get_budget_data_for_creation/` | 获取新建活动的预算数据 |
| 直播广告 | `/live_stream/check_overlapping_ads_for_roi_two/` | 校验目标 ROI 模式下的重叠广告 |
| 直播广告 | `/live_stream/search_target_affiliate/` | 搜索目标 Affiliate |
| 直播广告 | `/live_stream/get_affiliate/` | 获取 Affiliate 详情 |
| 报表 | `/report/get_time_graph/` | 获取时序图表数据 |
| 报表 | `/report/update_time_config/` | 更新时间范围配置 |
| 报表 | `/report/get_config/` | 获取报表配置 |
| 报表 | `/report/export_job/trigger/` | 触发 CSV 导出任务 |
| 报表 | `/report/get/` | 获取报表数据 |
| 报表 | `/report/update_selected_metric_config/` | 更新已选指标配置 |
| 充值 | `/topup/get_setting/` | 获取充值设置 |
| 交易 | `/transaction_history/get/` | 获取交易记录 |
| 交易 | `/transaction_history/export_for_mcn/` | 导出 MCN 交易记录 |

---

## 本地存储

| Key | 类型 | 用途 | 涉及文件 |
|---|---|---|---|
| `MCN_CHART_METRICS` | `Array<MetricItemType>` | 跨会话持久化用户选择的图表指标 | `src/pages/homepage/components/core-metrics/index.vue`、`src/pages/affiliateHomepage/components/core-metrics.vue`、`src/_shared/api/report/index.ts` |

---

## TMS 埋点

埋点通过 `src/track/` 目录下的函数实现，调用 `pas-common/utils` 中的 `triggerReport()`。

### 首页 — TMS 票据 [#23941](https://trafficsuite.shopee.io/tms/tms_designer/ticket-center/23941)、[#23960](https://trafficsuite.shopee.io/tms/tms_designer/ticket-center/23960)

| 函数名 | 操作类型 | 触发时机 | 参数 |
|---|---|---|---|
| `reportHomePageView` | VIEW | 页面挂载 | `sourcePage` |
| `homePageTopSessionImpression` | IMPRESSION | 顶部区块进入视口 | `sourcePage` |
| `homePageCreateAdsClick` | CLICK | 点击"创建广告"按钮 | `sourcePage` |
| `homePageTopUpClick` | CLICK | 点击"充值"按钮 | `sourcePage` |

### Affiliate 首页 — TMS 票据 [#23941](https://trafficsuite.shopee.io/tms/tms_designer/ticket-center/23941)

| 函数名 | 操作类型 | 触发时机 |
|---|---|---|
| `reportAffiliateHomePageView` | VIEW | 页面挂载 |
| `affiliateHomePageTopSessionImpression` | IMPRESSION | 顶部区块进入视口 |
| `affiliateHomePageCreateAdsClick` | CLICK | 点击"创建广告"按钮 |

### 创建广告 — TMS 票据 [#23941](https://trafficsuite.shopee.io/tms/tms_designer/ticket-center/23941)

| 函数名 | 操作类型 | 触发时机 | 参数 |
|---|---|---|---|
| `reportCreateAdsView` | VIEW | 页面挂载 | `preSourcePage` |
| `createAdsCancelClick` | CLICK | 点击取消按钮 | `preSourcePage` |
| `createAdsDiscardPopupImpression` | IMPRESSION | 放弃更改弹窗出现 | `preSourcePage` |
| `createAdsDiscardPopupConfirmClick` | CLICK | 确认放弃 | `preSourcePage` |
| `createAdsDiscardPopupCancelClick` | CLICK | 取消放弃 | `preSourcePage` |
| `createAdsPublishClick` | CLICK | 点击发布按钮 | `preSourcePage`、`biddingStrategy` |

### 充值 — TMS 票据 [#23960](https://trafficsuite.shopee.io/tms/tms_designer/ticket-center/23960)

| 函数名 | 操作类型 | 触发时机 | 参数 |
|---|---|---|---|
| `reportTopUpView` | VIEW | 页面挂载 | `preSourcePage` |
| `topUpCheckoutClick` | CLICK | 点击结算按钮 | `preSourcePage` |
| `topUpCancelClick` | CLICK | 点击取消按钮 | `preSourcePage` |

---

## 性能监控

本代码库中未配置任何应用级性能监控（Sentry、Grafana、Web Vitals）。此模块中的"性能"指标专指广告活动表现（GMV、ROAS、曝光、点击），而非浏览器/运行时指标。

---

## 业务术语表

| 术语 | 全称 | 定义 |
|---|---|---|
| MCN | Multi-Channel Network（多频道网络） | 管理多个 Affiliate 创作者及其广告活动的机构 |
| Affiliate | — | 与 MCN 合作的内容创作者/达人 |
| 直播广告 | Live Stream Ad | 在直播期间向观众投放的广告活动形式 |
| Ads GMV | Ads Gross Merchandise Value | 用户点击广告后 7 天内产生的总销售额 |
| ROAS | Return on Ads Spending | Ads GMV / 广告花费 — 越高越好 |
| ROI | Return on Investment | Ads GMV / 广告支出 |
| CIR | Cost-Income Ratio（成本收入比） | Ads Revenue / Ads GMV — 越低说明广告越便宜 |
| CPC | Cost Per Click（每次点击费用） | 每次广告点击的花费金额 |
| CTR | Click-Through Rate（点击率） | 点击数 / 曝光数 |
| CR | Conversion Rate（转化率） | 广告订单数 / 点击数 |
| eCPM | Effective Cost per Mille（有效千次曝光费用） | 总广告花费 / 总曝光数 × 1,000 |
| SC | Seller Center（卖家中心） | 卖家管理广告、商品和店铺设置的平台 |
| PDP | Product Detail Page（商品详情页） | 单个商品的列表详情页面 |
| MMC | Multi-Module CLI | 用于开发和构建 MMF 模块的 CLI 工具 |
| MMF | Multi-Module Framework | Shopee 将多个模块组合为 portal 的微前端运行时框架 |
| TMS | Traffic Management System | Shopee 前端埋点/分析系统 |

---

## 参考资料

- **GitLab 仓库**：https://git.garena.com/shopee/isfe/ao/pas-mcn
- **MMC 文档**：https://seller-portal.i.test.shopee.io/mmc-docs/guide/getting-started.html
- **MMC 开发指南**：https://seller-portal.i.test.shopee.io/mmc-docs/guide/basic/development.html
- **构建与发布指南**：https://seller-portal.i.test.shopee.io/docs/pages/seller-portal/build-and-release.html
- **TMS 票据 #23941**：https://trafficsuite.shopee.io/tms/tms_designer/ticket-center/23941
- **TMS 票据 #23960**：https://trafficsuite.shopee.io/tms/tms_designer/ticket-center/23960
- **Paid Ads 业务术语表**：https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPAD&title=Paid+Ads+Glossary

---

## 常见问题

**1. 如何首次启动本地开发？**

运行 `yarn start`。该命令依次执行 `mmc init`（拉取远程配置并安装依赖）和 `mmc dev`。之后打开 `https://mcn.affiliate.test.shopee.co.id`，以 `mcn_id.2 / 123456` 登录，进入 Shopee Ads，在浏览器控制台执行 `window.proxy.mmfDevtools.enable()`。

**2. 为什么看到的是空白页面或生产环境版本？**

MMF devtools 每次会话都需要重新启用。在浏览器控制台执行 `window.proxy.mmfDevtools.enable()` 并刷新页面。确认控制台出现 `[MMF_DEVTOOLS]` 和 `[HMR] connected` 日志。

**3. 如何新增路由？**

1. 在 `src/router/index.ts` 的 `RouterMap` 枚举中新增条目。
2. 在 `src/pages/` 下创建对应的页面组件。
3. 在同一文件的路由数组中添加路由定义。
4. 如有需要，为旧版 Seller Center 路径添加重定向。

**4. 如何调用新的 API 端点？**

1. 在 `src/_shared/constants/api.ts` 中对应命名空间常量下添加端点路径。
2. 在对应的 `src/_shared/api/<domain>/index.ts` 中创建或扩展 API 函数。
3. 在对应的 `types.ts` 中定义请求/响应类型。
4. 构建完整路径时使用合适的 `BASE_PREFIX` 枚举值（所有标准 MCN 端点用 `V1`，登录端点 `/api/v2/pas/login/` 用 `FREE`）。

**5. 如何新增 TMS 埋点事件？**

1. 如有需要，在 `src/track/types.ts` 中补充页面/区块/目标类型。
2. 在对应的 `src/track/*Trackers.ts` 中使用 `pas-common/utils` 的 `triggerReport()` 创建埋点函数。
3. 在对应页面或组件中调用该函数。

**6. 为什么模块在我的地区不可用？**

`pas-mcn` 仅面向 `id`（印度尼西亚）和 `vn`（越南）地区开放（`src/router/index.ts` 中的 `WhiteList`），不支持其他地区访问。

**7. 如何在本地调试 pas-common 而非使用 CDN 版本？**

启动 `pas-common` 开发服务器，然后在 `mmc.config.js` 中注释掉 `remoteAppHost = config.cdnPrefix`，再重启 `yarn dev`。

**8. 生产部署流程是什么？**

推送到 `master` 分支会触发 GitLab CI 的 `auto_deploy` 阶段，自动部署到 test 和 UAT 环境。生产发布需在 Seller Portal 部署平台（`https://seller-portal.i.shopee.io/`）触发构建，构建成功后点击 **Publish** 启动发布作业。

**9. 如何让图表指标选择在刷新后保持？**

已选指标会序列化后存储在 `localStorage` 的 `MCN_CHART_METRICS` 键下。读取逻辑（含默认值回退）位于 `src/_shared/api/report/index.ts`。

**10. MCN 首页与 Affiliate 首页有何区别？**

MCN 首页（`/portal/pas`）展示 MCN 管理的所有 Affiliate 的聚合数据视图。Affiliate 首页（`/affiliate/:affiliateId`）是针对单个 Affiliate 活动与表现数据的下钻视图。

---

<!-- Generated by ads-workspace/skills/ads-readme-generate | checked: 69aa2e04ac9e5115a4c8c80b273049ef70cf2e78 | spec: 76fce5f679f9550b -->
