<!-- ads-workspace-gdoc-sync: gdoc_id=11nQPwcNp12aFjlDzw2zqAzFWis9-6f9VNOxhokN_NYY gdoc_url=https://docs.google.com/document/d/11nQPwcNp12aFjlDzw2zqAzFWis9-6f9VNOxhokN_NYY/edit -->

# pas-index

## 目录

- [项目概述](#项目概述)
- [核心功能](#核心功能)
- [项目架构](#项目架构)
- [目录结构](#目录结构)
- [快速开始](#快速开始)
  - [环境要求](#环境要求)
  - [配置](#配置)
  - [安装](#安装)
  - [构建](#构建)
  - [本地开发](#本地开发)
  - [开发规范](#开发规范)
  - [部署](#部署)
- [API 文档](#api-文档)
- [本地存储](#本地存储)
- [TMS 埋点追踪](#tms-埋点追踪)
- [性能监控](#性能监控)
- [业务术语表](#业务术语表)
- [参考链接](#参考链接)
- [常见问题](#常见问题)

---

## 项目概述

`pas-index` 是 Shopee Ads（付费广告）平台在 Seller Center 中的主前端模块。它是卖家管理广告活动、充值广告余额、查看待办任务推荐、追踪奖励、管理账户钱包，以及访问费用减免计划（FSS）和活动加速器的主要入口。基于多模块框架（MMC）使用 Vue 3 + TypeScript 构建，与 Seller Center 门户生态系统和 `pas-common` 共享库紧密集成。

---

## 核心功能

- **广告首页**：统一的广告活动列表，支持按标签页导航浏览产品广告、产品 NPA 广告、店铺广告、品牌广告、品牌考量广告、展示广告和直播广告。包含广告活动级别统计、批量编辑、诊断集成和 GMV 指标视图。
- **充值页面**：广告余额充值，支持自动充值设置、优惠券使用和充值激励奖励展示。
- **待办列表页面**：可操作的广告优化任务卡片（潜力商品、每日预算推荐、ROAS 提升、ROI2 迁移、额度到期），按标签页组织（全部 / 操作 / 提醒）。
- **活动预算推荐页面**：专用页面，用于查看和应用 AI 推荐的活动高峰日每日预算增加。
- **账户钱包页面**：多标签页面，展示广告钱包余额、免费广告额度详情和充值历史。
- **奖励中心**：激励计划列表，涵盖多种计划类型（QSS、QSS 一个月、商品消费、充值、多层级、简单固定消费、复合、目标消费、广告额度包、持续 ATU、注册消费、活动优化、持续自动托管、费用自动托管等），支持状态筛选（全部 / 待完成 / 已完成 / 已过期）。包含进度摘要组件和 GMS 活动状态管理。
- **费用减免计划（FSS）**：独立页面，路由地址 `/portal/marketing/pas/fee-waiver-program`。显示 Take-Rate 公式（消费额 ÷ GMV）及实时进度条，与目标 Take-Rate 比对，展示资格状态和操作建议（充值含托管奖励标签、创建新广告、增加预算、降低目标 ROAS）。通过 `isEligible` 判断权限——不符合条件的卖家将被重定向到首页。可从 CMT 活动页面通过 `?type=FSS_FEE_WAIVER_PROGRAM` 进入。
- **活动加速器（Campaign Accelerator）**：独立页面，路由地址 `/portal/marketing/pas/campaign-accelerator`。展示活动包详情（报名期和活动期）、状态标签（待开始 / 进行中 / 已结束），以及含 GMS 产品广告 ROI 配置和可选自动托管（活动期和活动后费率）的报名流程。通过 `szAdsCampaignAccelerator` 功能开关控制——不可用时重定向到首页。可从 CMT 活动页面通过 `?type=CAMPAIGN_GMV_MAX_ACCELERATOR` 进入。
- **GMS AI 报告（Seller Agent）**：为 GMS（GMV Max Simple）产品广告活动生成的 AI 诊断报告，以 960px 抽屉形式展示（`GmsAiReportPanel` → `GmsAiReportDrawer`），从店铺 GMV Max 广告列表打开。报告内容以 iframe 加载自 `/api/pas/v1/seller_agent/report/page/{report_id}`，通过 `POST /seller_agent/report/status` 轮询生成状态，用户可通过 `POST /seller_agent/report/feedback` 提交反馈（点赞/点踩、评论）。报告抽屉同时内嵌店铺智能助推控件（预算增加、活动高峰、智能优惠券）。
- **店铺智能助推（Shop-Wise Booster）**：店铺级优化抽屉（800px），将三个优化模块——自动增加预算、活动高峰开关、智能优惠券开关——整合为单一设置面板。在首页 GMS 活动视图中可用。设置通过 `GET /smart_booster/get/` 获取，通过 `POST /smart_booster/set/` 保存。
- **智能优惠券抽屉（Smart Voucher Drawer）**：专用 800px 优化抽屉，展示近 14 天优惠券效果数据（已优惠 GMV、优惠券金额、周同比提升）及各活动操作推荐（降低 ROAS 目标、增加预算）。通过 `POST /smart_voucher/set/` 开启/关闭，操作效果通过 `POST /smart_voucher/check_action/` 预估。
- **Auto-GMS 商品表现表格**：嵌入店铺 GMV Max 广告列表中的商品级表现表格。支持商品类型筛选、推荐标签筛选（`RecommendationFilter`）、关键词搜索、批量添加商品（`BatchAddProducts`）和多选删除（最多 30 条）。数据来源于 `POST /product/gms/list_item_product_performance/`。
- **弹窗管理系统**：优先级排序的弹窗和提示队列（URL 触发 → API 触发），确保同一时间只显示一个弹窗。支持 45+ 种弹窗类型，包括活动托管弹窗、OCPM 升级同意、自动托管公告、NPA 公告、GMV 定义升级、批量功能操作、余额不足提醒、品牌 Max 广告采纳（`BRAND_MAX_ADS_ADOPTION_POPUP`）、GMS 创建鼓励（`GMS_CREATE_ENCOURAGEMENT_V2`）等。
- **性能监控（APMS/MDAP）**：检测关键用户路径的时间指标，包括侧边栏到模块进入时间、路由到首页渲染时间、活动表格渲染时间和折线图渲染时间。
- **店铺切换集成**：支持在店铺之间切换，自动刷新元数据。
- **权限守卫**：路由级别的 ACL 检查（`hasViewAdsAccess`、`hasEditAdsAccess`、`hasTopupAdsAccess`、`hasExportAccess`），通过 `pas-common/utils` 实现。
- **假期模式守卫**：检测卖家假期模式，在允许进入广告模块之前显示确认弹窗。
- **功能开关**：区域特定的功能开关（例如 `uiAdsTutorialVideos` 仅在 TW、MY、VN、SG 启用）。

---

## 项目架构

`pas-index` 是一个 **MMC 模块**（type: `module`，tech: `vue3`，id: `375`），注册在 Seller Center 门户下（portal id: `21` — `local-seller-center`，以及 `22` — `cb-seller-center`）。

```
Seller Center Portal (MMF)
  └── pas-index (Module ID: 375)
        ├── src/index.ts           ← 模块入口：导入路由
        ├── src/router/index.ts    ← 路由定义和守卫
        └── src/pages/
              ├── Index.vue              ← 根页面组件（店铺切换、i18n、指标）
              ├── homepage/              ← 主广告活动列表页
              ├── top-up/                ← 广告余额充值
              ├── to-do-list/            ← 任务推荐
              ├── campaign-budget-rcmd/  ← 预算推荐页
              ├── account-wallet/        ← 广告钱包和额度
              ├── rewards-center/        ← 激励计划
              ├── fee-waiver-program/    ← FSS 费用减免计划（独立路由）
              └── campaign-accelerator/  ← 活动加速器（独立路由）
```

该模块包含 **三个顶级路由**：

1. `/portal/marketing/pas` — 主广告门户，子路由包括：`index`（首页）、`top-up`、`todolist`、`campaign-budget-recommendation`、`wallet`、`rewards`。
2. `/portal/marketing/pas/fee-waiver-program` — FSS 费用减免计划，独立路由，不属于主广告子路由层级。
3. `/portal/marketing/pas/campaign-accelerator` — 活动加速器，另一个独立路由。

`roas-protection/` 目录不是独立路由——它作为小部件组件嵌入在首页中。类似地，`reinforce-roi3/` 提供了一种替代的 ROAS 保护卡片布局，在对应功能开关激活时用于首页展示。

该模块遵循双流架构：
- **旧流程**：处理遗留的广告创建和管理页面（子页面在本项目内构建）。
- **终极设置流程（USF）**：使用多个独立的 MMC 模块处理广告创建/详情页面。`pas-index` 在此流程中托管**首页**、**充值**、**钱包**、**待办列表**、**奖励中心**、**活动预算推荐**、**费用减免计划（FSS）** 和**活动加速器**页面。

共享逻辑由 `pas-common`（独立的依赖模块）提供。所有 EDS Vue 组件必须通过 `pas-common/eds-vue` 导入，不能直接从 `eds-vue` 导入。

API 层使用统一的 `createRequest` 工厂函数（`src/api/request/index.ts`），封装 Axios 并提供无授权重定向拦截器、限流错误处理和可选的 SecureFetch（反机器人、签名、DFP）。工厂函数支持 GET、POST 和 PUT 方法，并可配置响应拦截器。

---

## 目录结构

```
📦src
 ┣ 📂api              ← API 函数和请求/响应类型
 ┃ ┣ 📂banner         ← Banner 相关 API（获取、修改、批量活动修改、最低出价/预算 CSV）
 ┃ ┣ 📂campaign       ← 活动 API 类型和函数
 ┃ ┣ 📂campaign-accelerator ← 活动加速器 API（获取、编辑）
 ┃ ┣ 📂common         ← 通用 API 入口和类型
 ┃ ┣ 📂fss            ← FSS 费用减免计划 API（get_action、get、list_history）
 ┃ ┣ 📂meta           ← 广告元数据获取
 ┃ ┣ 📂report         ← 报告 API（时间图表、导出、配置）
 ┃ ┣ 📂request        ← 统一请求工厂（createRequest、类型定义）
 ┃ ┣ 📂rewards        ← 奖励中心 API（查询、修改、banner、批量创建）
 ┃ ┣ 📂roas-protection← ROAS 保护 API（概览、活动历史、活动详情）
 ┃ ┣ 📂roi            ← ROI 相关 API
 ┃ ┣ 📂seller-agent   ← Seller Agent AI 报告 API（报告状态、反馈、报告页面 URL）
 ┃ ┣ 📂smart-voucher  ← 智能优惠券 API（get、list_action、set、check_action）
 ┃ ┣ 📂to-do-list     ← 待办列表任务 API
 ┃ ┣ 📂top-up         ← 充值 API
 ┃ ┣ 📂transaction-history ← 交易历史 API
 ┃ ┣ 📂wallet         ← 钱包/额度 API
 ┃ ┣ 📜constant.ts    ← API 路径常量（约 135 个端点）
 ┃ ┣ 📜request.ts     ← 旧版适配器，将 createRequest 封装为 v1Request
 ┃ └ 📜types.ts       ← 通用 API 类型
 ┣ 📂assets           ← 静态资源（图片、SVG）
 ┣ 📂components       ← 共享可复用 UI 组件
 ┃ ┣ 📂batch-product-table    ← 批量产品创建/结果表格
 ┃ ┣ 📂modals                 ← 弹窗组件（activate-ads-cps、auto-budget-inc、campaign-day 等）
 ┃ ┣ 📂custom-skeleton        ← 骨架屏加载组件
 ┃ ┗ 📂to-do-list             ← 待办列表卡片和操作组件
 ┣ 📂composables      ← Composition API 工具（usePagination）
 ┣ 📂constants        ← 业务和逻辑常量
 ┃ ┣ 📜app-config.ts  ← localStorage 键注册表（StorageKey）
 ┃ ┣ 📜campaign_ad.ts ← CampaignAdStates 枚举、ReportCampaignType 枚举
 ┃ ┣ 📜currency.ts    ← 货币常量
 ┃ ┣ 📜event-bus.ts   ← 事件总线键常量
 ┃ ┣ 📜router.ts      ← RouterPath 常量
 ┃ ┣ 📜types.ts       ← 共享类型导出（StatusType、GMS_PAGE_ID 等）
 ┃ ┗ 📜...            ← 其他领域常量
 ┣ 📂metric           ← APMS/MDAP 性能追踪
 ┃ ┣ 📜metricMdap.ts  ← MetricKeys 枚举、METRICMAP、metricSchema
 ┃ ┗ 📜load.ts        ← LoadMeasure 辅助类
 ┣ 📂pages            ← 页面级组件
 ┃ ┣ 📂homepage       ← 主广告首页（活动表格、筛选器、弹窗、提示）
 ┃ ┃ ┣ 📂components   ← 首页特定组件（tab-bar、campaign-statistic、modals 等）
 ┃ ┃ ┃ ┣ 📂shop-gmv-max-ads-list ← GMS 活动列表，含 AI 报告面板和 Auto-GMS 商品表现表格
 ┃ ┃ ┃ ┣ 📂auto-gms-performance-table ← GMS 商品表现表格（筛选、推荐标签、批量添加）
 ┃ ┃ ┃ ┣ 📂smart-voucher-drawer  ← 智能优惠券优化抽屉（14 天数据、操作推荐）
 ┃ ┃ ┃ ┗ 📂smart-shop-booster-drawer ← 店铺智能助推统一设置抽屉（ABI + 高峰 + 优惠券）
 ┃ ┃ ┣ 📂composable   ← 首页 composables（usePromptsManager、useQSS、useFetchHomepageStatistic 等）
 ┃ ┃ ┗ 📂utils        ← 弹窗操作类型和工具
 ┃ ┣ 📂top-up         ← 充值页面（自动充值、优惠券、奖励）
 ┃ ┣ 📂to-do-list     ← 待办列表任务页面
 ┃ ┣ 📂campaign-budget-rcmd ← 预算推荐页面
 ┃ ┣ 📂account-wallet ← 广告钱包、免费广告额度、充值历史
 ┃ ┣ 📂rewards-center ← 激励计划列表页面
 ┃ ┃ ┣ 📂programs     ← 各计划类型实现
 ┃ ┃ ┃ ┣ 📂ads-credit-package-program    ← ACP 计划展示逻辑
 ┃ ┃ ┃ ┣ 📂compound-*-program            ← 复合消费计划
 ┃ ┃ ┃ ┣ 📂fee-auto-escrow-program       ← 费用自动托管计划（含加速抽屉）
 ┃ ┃ ┃ ┣ 📂item-spending-program         ← 商品消费计划
 ┃ ┃ ┃ ┣ 📂multi-tier-*-program          ← 多层级计划
 ┃ ┃ ┃ ┣ 📂qss-*-program                 ← QSS 计划
 ┃ ┃ ┃ ┣ 📂simple_fixed_spending_program ← GMS 简单固定消费
 ┃ ┃ ┃ ┣ 📂single-tier-*-program         ← 单层级计划
 ┃ ┃ ┃ ┣ 📂spending-*-program            ← 消费计划
 ┃ ┃ ┃ ┣ 📂target-spending-program       ← 目标消费计划
 ┃ ┃ ┃ ┣ 📂top-spending-program          ← 顶级消费计划
 ┃ ┃ ┃ ┣ 📂topup-program                 ← 充值计划
 ┃ ┃ ┃ ┗ 📂components/progress-summary   ← 进度摘要子组件
 ┃ ┃ ┗ 📂utils        ← 奖励中心工具和手动迁移检查
 ┃ ┣ 📂fee-waiver-program   ← FSS 费用减免计划页面（独立路由）
 ┃ ┃ ┣ 📂components         ← 骨架屏加载
 ┃ ┃ └ 📂modals             ← FSS 弹窗（充值、创建广告、增加预算、降低 ROI、数据历史）
 ┃ ┣ 📂campaign-accelerator ← 活动加速器页面（独立路由）
 ┃ ┃ ┣ 📂components         ← 详情、费率弹窗、活动后费率气泡、骨架屏
 ┃ ┃ └ 📜post-sign-up.vue   ← 报名后视图（自动托管和活动设置）
 ┃ ┣ 📂roas-protection← ROAS 保护小部件（嵌入首页，非独立路由）
 ┃ └ 📜Index.vue      ← 根页面（设置 i18n、店铺切换、指标）
 ┣ 📂router           ← 路由定义和导航守卫
 ┃ ┣ 📜index.ts       ← 所有路由 + beforeEnter 守卫 + 页面会话追踪
 ┃ ┣ 📜constant.ts    ← 路由名称（RouterMap）、设置流程 URL（AdsSetupPage）、辅助函数
 ┃ └ 📜utils.ts       ← getAdsSetupRoute URL 生成辅助函数
 ┣ 📂store            ← 响应式全局状态
 ┃ ┣ 📂auto-budget-config ← 自动预算增加配置
 ┃ ┣ 📂config-center  ← Constantine（响应式配置）、充值配置、链接配置
 ┃ ┣ 📂meta           ← 广告元数据（adsAccount、extToggle、adsToggle 等）
 ┃ ┣ 📂qss            ← QuickStart Service 状态和 getters
 ┃ ┣ 📂report-cache   ← 报告时间/指标缓存（含 snake/camelCase 转换）
 ┃ ┣ 📂rewards        ← 持续自动托管计划状态
 ┃ ┗ 📂top-up         ← 充值页面状态
 ┣ 📂styles           ← 全局 SCSS（常量、混入、索引）
 ┣ 📂track            ← TMS 埋点函数导出
 ┃ ┣ 📜index.ts       ← 从 pas-common 追踪入口的命名导出
 ┃ ┣ 📜types.ts       ← 追踪类型定义
 ┃ ┗ 📜trackingEntry.ts ← 追踪入口点（重新导出）
 ┣ 📜index.ts         ← 模块入口点（导入路由）
 ┗ 📜module.json      ← MMF 模块配置（通知导航、路由）
```

---

## 快速开始

### 环境要求

- **Node.js** >= 16.14.0（推荐 Node 20）
- **pnpm** >= 8.0.0（推荐 pnpm 8）
- **npm 全局注册表** 设置为 `https://npm.shopee.io/`
- **MMC CLI** 全局安装：`@shopee/multi-module-cli`
- Python 3.10（MMC 需要）
- xcodebuild（仅 macOS，MMC 需要）

### 配置

模块通过仓库根目录的 `mmc.config.js` 配置。关键设置：

| 字段 | 值 | 描述 |
|------|-----|------|
| `id` | `375` | MMF 模块 ID |
| `type` | `module` | MMC 产物类型 |
| `tech` | `vue3` | Vue 3 框架 |
| `injectStyle` | SCSS mixins、constants、index | 全局注入到所有组件的 SCSS |
| `webpack` | 自定义 splitChunks | 将 commons、首页 API/常量合并到 `app-common` chunk |
| `rsbuild` | rspack 配置 | 仅用于开发模式 |

`config/.remote-config.json` 文件由 `yarn run init` 自动生成。它包含从 Seller Portal API 获取的门户配置（路由、参数）。请勿手动提交此文件；每次 `init` 都会覆盖。

### 安装

全局安装 MMC（首次设置）：

```bash
pnpm i -g @shopee/multi-module-cli
mmc setup
mmc -V   # 验证：应显示 mmc-core、mmc-vue、mmc-react、mmc-vue3 版本
```

安装项目依赖：

```bash
yarn run init
# 提示时选择：local-seller-center（portal id: 21）
```

> **注意**：`yarn run init --prod` 仅安装 `dependencies`（不安装 `devDependencies`），用于 CI 构建阶段。

### 构建

通过 Seller Portal UI 构建模块进行部署：

1. 打开 [Seller Portal 构建页面](https://seller-portal.i.shopee.io/build/modules-group)
2. 选择 **Shopee Ads (Seller center)** → **Pas** → 你的分支 → 目标环境
3. 选择 **Auto Publish**，然后选择门户：`local-seller-center` 和 `cb-seller-center`，并选择所有区域
4. 可选填写 **PFB 2.0** 字段用于功能分支构建
5. 点击 **Build & Publish**

或通过 CI 触发（合并到 `master` 或 `release` 后自动部署到 test）：

```bash
yarn deploy:ci -e test -p pfb-ads-platform-e2e -b $CI_COMMIT_BRANCH
```

### 本地开发

**第 1 步** — 初始化（首次或长时间未开发后）：

```bash
yarn run init
# 选择：local-seller-center
```

**第 2 步** — 启动开发服务器：

```bash
yarn dev
# 启动：mmc dev (LOCAL_DEV=1) + vue-tsc 类型监视器并发运行
```

**第 3 步** — 在浏览器中连接到测试门户：

1. 在浏览器中打开 `https://seller.test.shopee.{CID}`（例如 `https://seller.test.shopee.sg`）
2. 打开浏览器 DevTools 控制台
3. 运行：`mmfDevtools.enable()`
4. 刷新页面 — 门户将加载你的本地模块而非远程版本

> **提示**：如果页面仍显示远程版本，请清除浏览器缓存并刷新。

**WebStorm 用户**：

```bash
yarn dev:webstorm
```

**使用远程分支开发**：

```bash
yarn dev:remote   # 使用 master 分支远程资源
```

### 开发规范

本项目的关键开发规则：

1. **所有新功能**必须在**终极设置流程**中开发。在开始之前检查旧流程中是否存在相关逻辑。
2. 不要在 `old flow only` 文件夹中创建新文件（`pages/homepage/` composable 模式之外的 `components/`、`store/` 等）。
3. 通过 `pas-common/eds-vue` 导入 EDS Vue 组件，不要直接从 `eds-vue` 导入。
4. 从 `pas-common/components/homepage` 导入 `pas-common` 组件，不要从 `pas-common/components` 导入。
5. 对于追踪函数，仅对 `sellerCenterShopeeAds` 和 `sellerCenterAdsCampaignPage` 使用 `export *`；所有其他追踪入口使用命名导出。
6. 添加新的首页弹窗：遵循 3 步弹窗管理系统（添加 `PromptId` → 选择触发数组 → 实现带清理逻辑的操作）。

运行代码检查：

```bash
yarn lint          # ESLint + Stylelint
yarn lint:fix      # 自动修复代码检查问题
yarn lint:changed  # 仅检查已更改的文件（CI 友好）
```

类型检查：

```bash
yarn type:check    # 运行 vue-tsc 类型检查
```

### 部署

CI 自动部署到 test 后（在合并到 `master` 或 `release` 时触发），流水线还会：
- 针对 `pfb-ads-platform-e2e` PFB 运行 E2E 测试（`@pas-index` 标签）
- 自动部署到 UAT（`yarn deploy -e uat`）

手动发布步骤：
1. 在 Seller Portal 中构建成功的任务
2. 在构建记录上点击 **Publish**
3. 选择门户（`local-seller-center`、`cb-seller-center`）、PFB 和区域
4. 点击 **Publish** 开始发布任务

下线模块：在构建前开启 **Offline Mode**，然后发布。

---

## API 文档

所有 API 请求通过 `src/api/request/index.ts` 中的 `createRequest` 发起，它封装了 Axios 并提供：
- 无授权拦截器（当 `code === 1400109802` 时重定向到首页）
- 限流错误处理（当 `code === 7` 时显示 toast 提示）
- 可选的 SecureFetch（`withSecureFetchParams: true`）用于反机器人、签名和 DFP 保护
- 通过统一的 `request` 函数支持 GET、POST 和 PUT 方法

**基础 URL 前缀**（`src/api/request/types.ts` 中的 `BASE_PREFIX`）：

| 前缀 | 基础路径 |
|------|----------|
| `BASE_PREFIX`（默认） | `/api/pas/v1` |

**API 端点**（来自 `src/api/constant.ts`）：

| 页面 | 页面 URL | API 端点 | 描述 |
|------|----------|----------|------|
| Meta | `/portal/marketing/pas` | `/meta/get_ads_data/` | 获取广告账户元数据 |
| Meta | `/portal/marketing/pas` | `/meta/get_non_ads_data/` | 获取非广告元数据 |
| Config | `/portal/marketing/pas` | `/config/get/` | 获取配置 |
| 首页 | `/portal/marketing/pas/index` | `/homepage/query/` | 查询首页活动列表 |
| 首页 | `/portal/marketing/pas/index` | `/homepage/mass_edit/` | 批量编辑活动 |
| 首页 | `/portal/marketing/pas/index` | `/homepage/list_subentry/` | 列出首页子入口 |
| 首页 | `/portal/marketing/pas/index` | `/homepage/get_creation_prompt_card/` | 获取创建提示卡片 |
| 首页 | `/portal/marketing/pas/index` | `/homepage/get_mass_edit_warning_for_roi_two/` | 获取 ROI2 批量编辑警告 |
| 首页 | `/portal/marketing/pas/index` | `/homepage/list_additional_trait/` | 列出附加特征 |
| 首页 | `/portal/marketing/pas/index` | `/homepage/list_additional_metrics/` | 列出附加指标 |
| 首页 | `/portal/marketing/pas/index` | `/homepage/update_trait/` | 更新特征 |
| 首页 | `/portal/marketing/pas/index` | `/homepage/list_upgradable/` | 列出可升级活动 |
| 首页 | `/portal/marketing/pas/index` | `/homepage/trigger_async_upgrade/` | 触发异步升级 |
| 首页 | `/portal/marketing/pas/index` | `/homepage/list_merged_upgradable/` | 列出合并可升级活动 |
| 首页 | `/portal/marketing/pas/index` | `/homepage/list_upgraded/` | 列出已升级活动 |
| 首页 | `/portal/marketing/pas/index` | `/homepage/check_async_upgrade_status/` | 检查异步升级状态 |
| 首页 | `/portal/marketing/pas/index` | `/homepage/list_stopped_ads_by_roi_two_migration/` | 列出因 ROI2 迁移停止的广告 |
| 首页 | `/portal/marketing/pas/index` | `/homepage/list_upgradable_ads_to_simple_roi_two/` | 列出可升级到简单 ROI2 的广告 |
| 首页 | `/portal/marketing/pas/index` | `/report/get_homepage_time_graph/` | 首页折线图数据 |
| 首页 | `/portal/marketing/pas/index` | `/setup_helper/get_campaign_expense_statistics/` | 活动费用数据 |
| 首页 | `/portal/marketing/pas/index` | `/banner/get/` | 获取 banner 状态 |
| 首页 | `/portal/marketing/pas/index` | `/banner/modify/` | 修改 banner |
| 首页 | `/portal/marketing/pas/index` | `/banner/mass_campaign_modify/` | 批量活动修改 |
| 首页 | `/portal/marketing/pas/index` | `/diagnosis/batch_list_verdict/` | 批量列出广告诊断结果 |
| 首页 | `/portal/marketing/pas/index` | `/diagnosis/homepage_batch_list_verdict/` | 首页批量列出诊断结果 |
| 首页 | `/portal/marketing/pas/index` | `/diagnosis/track/` | 追踪诊断 |
| 首页 | `/portal/marketing/pas/index` | `/smart_booster/get/` | 获取智能助推设置 |
| 首页 | `/portal/marketing/pas/index` | `/smart_booster/set/` | 设置智能助推 |
| 首页 | `/portal/marketing/pas/index` | `/smart_voucher/get/` | 获取智能优惠券设置 |
| 首页 | `/portal/marketing/pas/index` | `/smart_voucher/list_action/` | 列出智能优惠券操作 |
| 首页 | `/portal/marketing/pas/index` | `/smart_voucher/set/` | 设置智能优惠券 |
| 首页 | `/portal/marketing/pas/index` | `/smart_voucher/check_action/` | 检查智能优惠券操作 |
| Seller Agent | `/portal/marketing/pas/index` | `/seller_agent/report/status` | 轮询 GMS AI 报告生成状态 |
| Seller Agent | `/portal/marketing/pas/index` | `/seller_agent/report/feedback` | 提交 GMS AI 报告反馈 |
| 活动 | `/portal/marketing/pas/index` | `/product/get/` | 获取产品广告详情 |
| 活动 | `/portal/marketing/pas/index` | `/product/get_setup_status/` | 获取产品广告设置状态 |
| 活动 | `/portal/marketing/pas/index` | `/product/edit/` | 编辑产品广告 |
| 活动 | `/portal/marketing/pas/index` | `/product/publish/` | 发布产品广告 |
| 活动 | `/portal/marketing/pas/index` | `/product/mass_create/` | 批量创建产品广告 |
| 活动 | `/portal/marketing/pas/index` | `/product/get_budget_data_for_creation/` | 获取创建预算数据 |
| 活动 | `/portal/marketing/pas/index` | `/product/list_overlapping_ads_for_roi_two/` | 列出 ROI2 重叠广告 |
| 活动 | `/portal/marketing/pas/index` | `/product/get_estimated_data/` | 获取 ROI2 预估数据 |
| 活动 | `/portal/marketing/pas/index` | `/product/gms/get_estimated_data/` | 获取 GMS 预估数据 |
| 活动 | `/portal/marketing/pas/index` | `/product/gms/product_selector/list/` | 列出 GMS 商品选择器商品 |
| 活动 | `/portal/marketing/pas/index` | `/product/gms/get_total_selected/` | 获取 GMS 已选商品总数 |
| 活动 | `/portal/marketing/pas/index` | `/product/gms/list_item_product_performance/` | 列出 GMS 商品表现 |
| 活动 | `/portal/marketing/pas/index` | `/product/gms/count_total_item/` | 统计 GMS 商品总数 |
| 活动 | `/portal/marketing/pas/index` | `/product/gms/item/edit/` | 编辑 GMS 商品 |
| 活动 | `/portal/marketing/pas/index` | `/product/get_roi_two_uplift/` | 获取 ROI2 提升数据 |
| 活动 | `/portal/marketing/pas/index` | `/product/get_single_manual_upgrade_data/` | 获取单个手动升级数据 |
| 活动 | `/portal/marketing/pas/index` | `/product/trigger_batch_upgrade_to_roi_two/` | 批量升级到 ROI2 |
| 活动 | `/portal/marketing/pas/index` | `/product/upgrade_to_roi_two/` | 单个升级到 ROI2 |
| 活动 | `/portal/marketing/pas/index` | `/product/trigger_batch_upgrade_to_simple_roi_two/` | 批量升级到简单 ROI2 |
| 活动 | `/portal/marketing/pas/index` | `/product/upgrade_to_simple_roi_two/` | 单个升级到简单 ROI2 |
| 活动 | `/portal/marketing/pas/index` | `/product/mass_create_for_npa_todo_popup/` | NPA 待办弹窗批量创建 |
| 活动 | `/portal/marketing/pas/index` | `/setup_helper/get_budget_data_for_edit/` | 获取编辑预算数据 |
| 活动 | `/portal/marketing/pas/index` | `/setup_helper/list_npa_todo_popup_item/` | 列出 NPA 待办弹窗商品 |
| 活动 | `/portal/marketing/pas/index` | `/setup_helper/get_recommended_roi_two_target/` | 获取推荐 ROI2 目标 |
| 活动 | `/portal/marketing/pas/index` | `/setup_helper/product_selector/query/` | 查询商品选择器商品 |
| 活动 | `/portal/marketing/pas/index` | `/product_selector/list_additional_trait/` | 列出商品选择器附加特征 |
| 活动 | `/portal/marketing/pas/index` | `/shop/check_has_enough_active_item/` | 检查活跃商品 |
| 活动 | `/portal/marketing/pas/index` | `/search_brand/edit/` | 编辑搜索品牌 |
| 活动 | `/portal/marketing/pas/index` | `/live_stream/edit/` | 编辑直播 |
| 活动高峰 | `/portal/marketing/pas/campaign-budget-recommendation` | `/campaign_day/get_surge_setting/` | 获取高峰设置 |
| 活动高峰 | `/portal/marketing/pas/campaign-budget-recommendation` | `/campaign_day/set_surge_setting/` | 设置高峰设置 |
| 活动高峰 | `/portal/marketing/pas/campaign-budget-recommendation` | `/campaign_day/get_prompt/` | 获取高峰提示 |
| 活动高峰 | `/portal/marketing/pas/campaign-budget-recommendation` | `/campaign_day/stop_prompt/` | 停止高峰提示 |
| 活动高峰 | `/portal/marketing/pas/campaign-budget-recommendation` | `/campaign_surge/list_optimized_campaign_subtype` | 列出优化活动子类型 |
| 活动高峰 | `/portal/marketing/pas/campaign-budget-recommendation` | `/campaign_surge/list_optimized_campaign` | 列出优化活动 |
| 活动加速器 | `/portal/marketing/pas/campaign-accelerator` | `/campaign_accelerator/get/` | 获取活动加速器包和用户设置 |
| 活动加速器 | `/portal/marketing/pas/campaign-accelerator` | `/campaign_accelerator/edit/` | 报名或编辑活动加速器设置 |
| 费用减免（FSS） | `/portal/marketing/pas/fee-waiver-program` | `/fss_program/get/` | 获取 FSS 计划概览（资格、进度、操作） |
| 费用减免（FSS） | `/portal/marketing/pas/fee-waiver-program` | `/fss_program/get_action/` | 获取 FSS 操作数据（充值/创建/预算/ROAS 推荐） |
| 费用减免（FSS） | `/portal/marketing/pas/fee-waiver-program` | `/fss_program/list_history/` | 列出 FSS 计划历史记录 |
| 充值 | `/portal/marketing/pas/top-up` | `/topup/list_available_voucher/` | 列出可用优惠券 |
| 充值 | `/portal/marketing/pas/top-up` | `/topup/claim_voucher/` | 领取优惠券 |
| 充值 | `/portal/marketing/pas/top-up` | `/topup/get_suggest_auto_topup_setting/` | 获取建议自动充值设置 |
| 充值 | `/portal/marketing/pas/top-up` | `/topup/edit_auto_topup_setting/` | 编辑自动充值设置 |
| 充值 | `/portal/marketing/pas/top-up` | `/topup/get_setting/` | 获取充值设置 |
| 充值 | `/portal/marketing/pas/top-up` | `/topup/set_has_seen_auto_topup/` | 设置已查看自动充值 |
| 奖励 | `/portal/marketing/pas/rewards` | `/incentive/query/` | 查询激励计划 |
| 奖励 | `/portal/marketing/pas/rewards` | `/incentive/get_reward_summary/` | 获取奖励摘要 |
| 奖励 | `/portal/marketing/pas/rewards` | `/incentive/modify/` | 修改激励计划 |
| 奖励 | `/portal/marketing/pas/rewards` | `/incentive/check_has_manual_migration/` | 检查手动迁移 |
| 奖励 | `/portal/marketing/pas/rewards` | `/incentive/list_banner/` | 列出奖励 banner |
| 奖励 | `/portal/marketing/pas/rewards` | `/incentive/modify_banner/` | 修改奖励 banner |
| 奖励 | `/portal/marketing/pas/rewards` | `/incentive/batch_modify/` | 批量修改激励 |
| 奖励 | `/portal/marketing/pas/rewards` | `/incentive/accelerate/check_eligibility/` | 检查加速计划资格 |
| 奖励 | `/portal/marketing/pas/rewards` | `/incentive/campaign/list_eligible_item/` | 列出激励可选商品 |
| 奖励 | `/portal/marketing/pas/rewards` | `/incentive/campaign/mass_create/` | 批量创建激励活动 |
| 待办列表 | `/portal/marketing/pas/todolist` | `/todo/list_task/` | 列出待办任务 |
| 待办列表 | `/portal/marketing/pas/todolist` | `/todo/get_task/` | 获取单个待办任务 |
| 待办列表 | `/portal/marketing/pas/todolist` | `/todo/update_task/` | 更新待办任务 |
| 待办列表 | `/portal/marketing/pas/todolist` | `/todo/set_has_seen/` | 设置任务已查看 |
| 待办列表 | `/portal/marketing/pas/todolist` | `/todo/potential_item/list/` | 列出潜力商品 |
| 待办列表 | `/portal/marketing/pas/todolist` | `/todo/potential_item/publish/` | 发布潜力商品广告 |
| 待办列表 | `/portal/marketing/pas/todolist` | `/todo/potential_item/list_overlapping_ads/` | 列出重叠潜力商品广告 |
| 待办列表 | `/portal/marketing/pas/todolist` | `/todo/daily_budget/check_campaign_list/` | 检查每日预算活动列表 |
| 待办列表 | `/portal/marketing/pas/todolist` | `/todo/daily_budget/list_campaign/` | 列出每日预算活动 |
| 待办列表 | `/portal/marketing/pas/todolist` | `/todo/daily_budget/mass_optimize_campaign/` | 批量优化活动预算 |
| 待办列表 | `/portal/marketing/pas/todolist` | `/todo/rcmd_roi_two_target/list_campaign/` | 列出 ROI2 目标活动 |
| 待办列表 | `/portal/marketing/pas/todolist` | `/todo/rcmd_roi_two_target/mass_optimize_campaign/` | 批量优化 ROI2 活动 |
| 待办列表 | `/portal/marketing/pas/todolist` | `/todo/enhance_roas/list/` | 列出 ROAS 提升项 |
| 待办列表 | `/portal/marketing/pas/todolist` | `/todo/enhance_roas/optimize/` | 优化 ROAS |
| 待办列表 | `/portal/marketing/pas/todolist` | `/todo/credit_expiring/get_action_data/` | 获取额度到期操作数据 |
| 钱包 | `/portal/marketing/pas/wallet` | `/wallet/get/` | 获取广告钱包余额 |
| 钱包 | `/portal/marketing/pas/wallet` | `/wallet/list_free_ads_credit/` | 列出免费广告额度 |
| 钱包 | `/portal/marketing/pas/wallet` | `/wallet/list_banner/` | 列出钱包 banner |
| 交易 | `/portal/marketing/pas/wallet` | `/transaction_history/get/` | 获取交易历史 |
| 交易 | `/portal/marketing/pas/wallet` | `/transaction_history/get_csv/` | 获取交易历史 CSV |
| ROAS 保护 | `/portal/marketing/pas/index` | `/rebate/get_overview/` | 获取 ROAS 保护概览 |
| ROAS 保护 | `/portal/marketing/pas/index` | `/rebate/list_campaign_history/` | 列出 ROAS 保护活动历史 |
| ROAS 保护 | `/portal/marketing/pas/index` | `/rebate/campaign_get/` | 获取 ROAS 保护活动详情 |
| 报告 | `/portal/marketing/pas/index` | `/report/get/` | 获取报告数据 |
| 报告 | `/portal/marketing/pas/index` | `/report/update_selected_metric_config/` | 更新指标配置 |
| 报告 | `/portal/marketing/pas/index` | `/report/update_time_config/` | 更新时间配置 |
| 报告 | `/portal/marketing/pas/index` | `/report/get_config/` | 获取报告配置 |
| 报告 | `/portal/marketing/pas/index` | `/report/export_job/list_homepage_result/` | 列出首页导出结果 |
| 报告 | `/portal/marketing/pas/index` | `/report/export_job/trigger/` | 触发导出任务 |
| 报告 | `/portal/marketing/pas/index` | `/report/export_job/get_single_result/` | 获取单个导出结果 |
| 报告 | `/portal/marketing/pas/index` | `/report/export_job/get_download_url/` | 获取导出下载 URL |
| 报告 | `/portal/marketing/pas/index` | `/report/get_time_graph/` | 获取报告时间图表 |
| 报告 | `/portal/marketing/pas/index` | `/report/get_rapid_boost_effect/` | 获取快速助推效果数据 |
| 下载 | `/portal/marketing/pas/index` | `/download/get_csv/` | 下载 CSV |
| QSS | `/portal/marketing/pas/index` | `/qss/sign_up_program/` | QSS 注册计划 |
| QSS | `/portal/marketing/pas/index` | `/qss/mark_as_read/` | QSS 标记已读 |
| QSS | `/portal/marketing/pas/index` | `/qss/get_info/` | 获取 QSS 信息 |
| QSS | `/portal/marketing/pas/index` | `/qss/get_ads_creation_record/` | 获取 QSS 广告创建记录 |
| Banner | `/portal/marketing/pas/index` | `/banner/min_bid_price/get_impacted_ads_csv/` | 下载受最低出价变更影响的广告 CSV |
| Banner | `/portal/marketing/pas/index` | `/banner/manual_prod_min_budget_increase/get_csv` | 下载受最低日预算增加影响的广告 CSV |
| 报告 | `/portal/marketing/pas/index` | `/onboarding/get_csv_budget_migration/` | 获取入门预算迁移 CSV |
| 奖励（旧版） | `/portal/marketing/pas/rewards` | `/incentive/qss_one_month/list_eligible_item/` | 列出 QSS 一月计划可选商品（已弃用） |
| 奖励（旧版） | `/portal/marketing/pas/rewards` | `/incentive/qss_one_month/mass_create/` | QSS 一月计划批量创建（已弃用） |
| 奖励（旧版） | `/portal/marketing/pas/rewards` | `/incentive/basic_item_spending/list_eligible_item/` | 列出基础商品消费可选商品（已弃用） |
| 奖励（旧版） | `/portal/marketing/pas/rewards` | `/incentive/basic_item_spending/mass_create/` | 基础商品消费批量创建（已弃用） |

---

## 本地存储

模块使用 `localStorage` 在会话间持久化 UI 状态。键定义在 `src/constants/app-config.ts`（通过 `StorageKey` 枚举）和 `src/router/index.ts`（页面会话 ID）中：

| 键 | 用途 |
|----|------|
| `SHOP_ADS_V2_UPGRADE_MODAL` | 追踪店铺广告 v2 升级弹窗是否已显示 |
| `SHOP_ADS_V2_VIDEO_MODAL` | 追踪店铺广告 v2 视频弹窗是否已显示 |
| `SHOP_ADS_CREATIVE_TIP` | 追踪店铺广告创意提示是否已显示 |
| `BROAD_MATCH_NEW_INTRO_KEY` | 追踪广泛匹配介绍是否已显示 |
| `SHOPEE_ADS_METRICS_KEY` | 存储选中的指标配置 |
| `DISPLAYED_TARGET_SIMPLE_MODE` | 追踪目标简单模式弹窗是否已显示 |
| `DISPLAYED_TARGET_BUYER_SEGMENT` | 追踪买家细分定向弹窗是否已显示 |
| `DISPLAYED_BUYER_SEGMENT_REPORT` | 追踪买家细分报告弹窗是否已显示 |
| `DISPLAYED_PRICE_LAYER_MODAL` | 追踪价格层级弹窗是否已显示 |
| `DISPLAYED_DETAIL_TARGET_SIMPLE_MODE` | 追踪详情目标简单模式是否已显示 |
| `DISPLAYED_ADS_PROMPT_DAY_INFO` | 追踪广告提示日信息是否已显示 |
| `ADS_HAS_BOOST_USER_KEY` | 追踪用户是否使用过助推功能 |
| `KEYWORD_ADS_ECPC_NEW_TIP_VISIBLE` | 追踪关键词广告 eCPC 新提示是否可见 |
| `SELLER_CENTER_SHOPEE_ADS_PAGE_SESSION_ID` | 页面会话 ID，用于会话关联（每次路由变更时设置；定义在 `src/router/index.ts` 中） |

---

## TMS 埋点追踪

追踪事件从 `src/track/index.ts` 导出。模块使用 `pas-common` 追踪入口的命名导出，遵循以下模式：

- `export *` 仅用于 `sellerCenterShopeeAds`（主入口点）和 `sellerCenterAdsCampaignPage`
- 所有其他追踪入口使用**命名导出**以实现更好的 tree-shaking

**追踪页面和关键事件：**

| 页面 | 入口 | 示例事件 |
|------|------|----------|
| 广告首页 | `sellerCenterShopeeAds` | 模块曝光、区域事件 |
| 广告首页 | `sellerCenterAdsHomepage` | 待办列表轮播、直播广告弹窗、GST 提示、NPA 提示 |
| 活动页（加速器） | `sellerCenterAdsCampaignPage` | 活动页浏览、报名按钮点击 |
| 充值 | `sellerCenterAdsTopup` | 自动充值开关、优惠券使用、套餐点击、前往结算 |
| 待办列表 | `sellerCenterAdsToDoList` | 标签页浏览、应用/更多信息点击、升级 ROAS 提示 |
| 我的账户 | `sellerCenterAdsMyAccountPage` | 钱包浏览、自动充值点击、额度悬停、banner 曝光 |
| 活动预算推荐 | `campaignBudgetRecommendationPage` | 标签页曝光、优化按钮点击 |
| 活动预算推荐 | `sellerCenterCampaignBudgetRecommendationPage` | 页面浏览 |
| 奖励中心 | `sellerCenterShopeeAdsRewardsPage` | 页面浏览、卡片点击、任务弹窗交互 |
| 费用减免（FSS） | `adsFssWaiverLandingPage` | 页面浏览、操作模块曝光、操作按钮点击、查看历史 |
| QSS | `sellerCenterAdsQssEnrolment` | QSS 注册浏览 |
| QSS 引导 | `sellerCenterShopeeAdsQssGuidePage` | 引导页浏览、创建广告、操作按钮 |
| QSS 弹窗 | `qssCreatingYourAdsNowPopup` | 创建广告弹窗浏览、充值点击、更多详情 |
| QSS 弹窗 | `qssUnableToCreateAdsPopup` | 无法创建广告弹窗浏览 |
| 充值奖励 | `sellerCenterTopUp` | 卖家激励奖金条、充值奖励进度条 |
| 查看推荐卡片 | `sellerCenterViewRecommendationCards` | 活动高峰推荐弹窗、授权复选框/按钮 |

---

## 性能监控

模块使用 APMS（通过 MDAP `customReporter.sendData`）检测关键用户路径。指标点定义在 `src/metric/metricMdap.ts` 中：

| 指标键 | Point ID | 描述 |
|--------|---------|------|
| `LEFT_MENU_TO_ADS_MODULE` | `dadbf4325384ec1a810b3631eb3b14a3` | 从侧边栏点击到模块进入的时间 |
| `MARKETING_LOAD_MEASURE` | `cf8e2439755340de965d73062ca85055` | 从模块进入到首页进入的时间 |
| `MARKETING_LOAD_MEASURE_TOTAL` | `945a9b28cf98e3d1f1010a3e0f278995` | 完整加载时间（仅首次冷加载） |
| `ADS_LISTPAGE_FROM_ROUTER_TO_PAGE` | `952654b35cd8ab5f87bf818225eb52c5` | 路由进入到 Index.vue 挂载 |
| `ADS_LISTPAGE_CAMPAIGN_EXPENSE_API` | `cadda73eba35ad8a3ccab690f7491d1f` | 活动费用 API 响应时间 |
| `ADS_LISTPAGE_CAMPAIGN_STATISTICS_API` | `f60eaad1c284ac1a4106435621ade2b5` | 活动统计 API 响应时间 |
| `ADS_LISTPAGE_FROM_ROUTER_TO_TABLE_API` | `ca204ee1e96d7f8164c664e0c4298be3` | 路由到首次表格 API 调用 |
| `ADS_LISTPAGE_FROM_ROUTER_TO_TABLE_RENDERED` | `91e1ce48f5fba80e93438ec394472d21` | 路由到表格完全渲染 |
| `ADS_LEFT_MENU_CAMPAIGN_LIST_API` | `4e52f8509fb24950b15b7fe6a04d7021` | 左侧菜单活动列表 API（已弃用） |
| `ADS_LIST_PAGE_FROM_ROUTER_TO_LEFT_MENU_API` | `b710978f1bab3851e6cdd47251da8d95` | 路由到左侧菜单 API |
| `ADS_LEFT_MENU_FROM_ROUTER_TO_MENU_RENDERED` | `02af73a8ca87403fe264729eebc7b365` | 路由到左侧菜单渲染 |
| `ADS_LIST_PAGE_LINECHART_API` | `d261d56f09ed6eb648bed80761acc317` | 首页折线图 API 响应 |
| `ADS_LIST_PAGE_FROM_ROUTER_TO_LINECHART_API` | `25d71975394da8ae7a994b001c06609b` | 路由到折线图 API |
| `ADS_LIST_PAGE_FROM_ROUTER_TO_LINECHART_RENDERED` | `500f903eca724bd88983d08cf1151f79` | 路由到折线图渲染 |

测量使用浏览器 `performance.mark` / `performance.measure` API。每个指标每个会话仅报告一次（`onlyCountOnce: true`）。

---

## 业务术语表

| 术语 | 全称 | 定义 |
|------|------|------|
| **Ads GMV** | 广告商品交易总额 | 广告产生的总销售额。当用户在点击广告后 7 天内购买时归因。 |
| **CTR** | 点击率 | 广告总点击次数 / 总曝光次数 |
| **CPC** | 每次点击成本 | 每次广告点击的花费 |
| **CR** | 转化率 | 广告订单数 / 广告总点击次数 |
| **ROAS** | 广告支出回报率 | 广告 GMV / 广告收入（ROI 的同义词） |
| **ROI** | 投资回报率 | 广告 GMV / 广告支出 |
| **CIR** | 成本收入比 | 广告收入 / 广告 GMV |
| **CPM** | 千次展示成本 | 每 1,000 次广告展示的成本 |
| **ECPM** | 有效千次展示成本 | 广告总花费 / 总展示次数 |
| **QSS** | 快速启动服务 | 帮助新广告主快速提升广告使用的服务 |
| **SRM** | 卖家关系管理 | 广告团队的端到端卖家管理 |
| **SC** | 卖家中心 | 卖家管理广告、产品等的平台 |
| **PDP** | 产品详情页 | Shopee 上的单个产品页面 |
| **DD** | 每日发现 | 主站底部的"每日发现"广告位 |
| **YMAL** | 猜你喜欢 | 产品详情页下方的广告位 |
| **CPS** | 每次销售成本 | 按销售付费的计费模式（卖家仅在购买时付费） |
| **GMV Max** | — | 自动出价广告产品（Target2.0 / Simple2.0），用于优化 ROAS |
| **NPB** | 新品助推 | 为新上架产品提供独家流量的广告功能 |
| **NPA** | 新品广告 | 潜在新品广告的待办项 |
| **TADS** | 定向广告 | 用于触达特定买家群体的发现广告 |
| **Whitelist** | 白名单 | 使特定卖家能够访问新广告功能的功能开关 |
| **Cold Start** | 冷启动 | 数据不足以进行准确系统预测的广告 |
| **Advv** | 广告主价值 | 平台长期收入增长的衡量指标 |
| **Take-Rate** | 抽成率 | 广告收入 / 平台 GMV；衡量平台变现效率 |
| **ACP** | 广告额度包 | 带有免费广告额度的折扣充值套餐 |
| **ATU** | 自动充值 | 当额度低于阈值时自动充值余额 |
| **GMS** | GMV Max Simple | 产品广告的简单固定消费计划 |
| **OCPM** | 优化千次展示成本 | 基于展示的优化出价模式 |
| **FSS** | 费用补贴服务 | 费用减免计划，符合条件的卖家通过达成目标 Take-Rate（消费额 ÷ GMV）获得广告费减免 |
| **SIP** | Shopee 国际平台 | 跨境电商平台 |
| **COD** | 货到付款 | 买家在收货时付款的支付方式 |

---

## 参考链接

- **项目 GitLab 仓库**：https://git.garena.com/shopee/isfe/ao/pas-index
- **MMC CLI 文档**：https://seller-portal.i.test.shopee.io/mmc-docs/guide/getting-started.html
- **MMC 开发指南**：https://seller-portal.i.test.shopee.io/mmc-docs/guide/basic/development.html
- **MMF 构建与发布**：https://seller-portal.i.test.shopee.io/docs/pages/seller-portal/build-and-release.html
- **Seller Portal 构建页面**：https://seller-portal.i.shopee.io/build/modules-group
- **USF 架构概览**：https://confluence.shopee.io/display/SPAD/%5BUltimate+Setup+Flow%5D%5BTD%5D+Architecture+Overview
- **USF 首页 TD**：https://confluence.shopee.io/display/SPAD/%5BUltimate+Setup+Flow%5D%5BTD%5D+Home+Page
- **付费广告术语表**：https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPAD&title=Paid+Ads+Glossary
- **广告平台概览（SRA）**：https://sra.test.shopee.io/05.Business_Systems/5.3_Ads_Business_and_Architecture_Introduction/5.3.6._ads.platform.html
- **Pas Helper Chrome 扩展**：https://chromewebstore.google.com/detail/pas-helper/nhfhjiehemipamajmeimnnkinhncgpcd
- **Seller Center 测试环境（SG）**：https://seller.test.shopee.sg

---

## 常见问题

**1. 如何首次开始本地开发？**
运行 `yarn run init`（选择 `local-seller-center`），然后 `yarn dev`。在浏览器中打开测试 Seller Center URL，打开 DevTools，运行 `mmfDevtools.enable()` 连接到本地开发服务器。

**2. `pas-index` 和终极设置流程（USF）的关系是什么？**
在 USF 中，`pas-index` 托管**首页**、**充值页面**、**钱包页面**、**待办列表**、**奖励中心**、**活动预算推荐**、**费用减免计划（FSS）** 和**活动加速器**页面。广告创建和详情页面是独立的 MMC 模块。旧流程将所有子页面放在本项目内。新功能应始终面向 USF 开发。

**3. 为什么不能直接从 `eds-vue` 导入？**
所有 EDS Vue 组件必须通过 `pas-common/eds-vue` 导入，以确保广告平台各模块之间的版本一致性和打包优化。禁止直接从 `eds-vue` 导入。

**4. 如何在首页添加新的弹窗/提示？**
遵循弹窗管理系统：(1) 在 `src/pages/homepage/utils/prompt-actions/types.ts` 的枚举中添加新的 `PromptId`；(2) 在 `usePromptsQueue` 中将其添加到适当的触发数组（`urlTriggeredPrompts` 或 `apiTriggeredPrompts`）；(3) 实现带清理逻辑的操作函数。同一时间只显示一个弹窗。

**5. 如何使用 PFB 部署到特定环境？**
在 Seller Portal 构建页面中，选择你的分支，启用 Auto Publish，选择 `local-seller-center` 和 `cb-seller-center` 两个门户、所有区域，并在 **PFB 2.0** 字段中填写你的 PFB 名称。点击 **Build & Publish**。

**6. `feature-flags.js` 控制什么？**
它定义了区域特定的功能开关。例如，`uiAdsTutorialVideos` 默认仅在 TW、MY、VN 和 SG 启用。此文件由 MMC 框架消费，用于按区域条件启用功能。

**7. 如何添加新的追踪事件？**
在 `src/track/index.ts` 中从适当的 `pas-common/tracking/entries/*` 文件添加命名导出。仅对 `sellerCenterShopeeAds` 和 `sellerCenterAdsCampaignPage` 使用 `export *`。对于所有其他追踪入口文件，使用命名导出以实现 tree-shaking。

**8. 卖家处于假期模式时会发生什么？**
`beforeEnter` 路由守卫检测 `app.user.holidayMode`。如果为 true，会显示确认弹窗要求卖家退出假期模式（重定向到 `/portal/settings/shop/general`）或返回门户根路径。广告模块的入口被阻止。

**9. 费用减免计划（FSS）页面如何工作？**
FSS 页面是独立路由 `/portal/marketing/pas/fee-waiver-program`。加载时调用 `/fss_program/get/` 检查资格并获取 Take-Rate 进度。不符合条件的卖家被重定向到首页。符合条件的卖家可查看当前 Take-Rate（消费额 ÷ GMV）与目标的对比，并获取操作建议。可从 CMT 活动页面通过 `?type=FSS_FEE_WAIVER_PROGRAM` 进入。

**10. 活动加速器页面如何工作？**
活动加速器页面是独立路由 `/portal/marketing/pas/campaign-accelerator`。通过 `szAdsCampaignAccelerator` 功能开关控制——不可用时重定向到首页。页面调用 `/campaign_accelerator/get/` 获取当前包和用户设置。卖家可在报名期内报名，触发费率/ROI 配置弹窗和可选的自动托管设置。报名后显示 `PostSignUp` 视图。

<!-- Generated by ads-workspace/skills/ads-readme-generate | checked: f9a9f96383ca71663d2eab3400ae57ca7a6b2d8c | spec: 76fce5f679f9550b -->
