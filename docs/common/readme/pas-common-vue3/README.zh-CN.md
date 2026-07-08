<!-- ads-workspace-gdoc-sync: gdoc_id=1CCthvyGkRi7NVzKNsS3tTnuYjkgxUcE7POMki_oGJjs gdoc_url=https://docs.google.com/document/d/1CCthvyGkRi7NVzKNsS3tTnuYjkgxUcE7POMki_oGJjs/edit -->

# pas-common

> Shopee 付费广告（卖家中心广告）共享模块联邦提供方

## 目录

- [项目概述](#项目概述)
- [核心功能](#核心功能)
- [项目架构](#项目架构)
- [目录结构](#目录结构)
- [快速开始](#快速开始)
  - [环境要求](#环境要求)
  - [配置说明](#配置说明)
  - [安装依赖](#安装依赖)
  - [构建](#构建)
  - [本地开发](#本地开发)
  - [部署发布](#部署发布)
- [API 文档](#api-文档)
- [本地存储](#本地存储)
- [TMS 埋点追踪](#tms-埋点追踪)
- [性能监控](#性能监控)
- [业务术语词汇表](#业务术语词汇表)
- [参考资料](#参考资料)
- [常见问题解答](#常见问题解答)

---

## 项目概述

`pas-common` 是一个基于 Vue 3 + TypeScript 的模块联邦（Module Federation）提供方，为所有 Shopee 付费广告业务模块（`pas-index`、`pas-product`、`pas-display`、`pas-livestream`）提供共享组件、工具函数、类型定义、埋点逻辑及框架兼容层。项目作为远程组件提供方（MMC 模块 id：`404`）运行在多模块框架（MMF）中，通过 `pas-common` 别名向各广告类型模块暴露资源，部署于 Shopee 卖家中心。

---

## 核心功能

- **55+ 共享 Vue 3 组件** — 业务组件（预算编辑、商品选择、目标 ROAS、广告诊断、ROI 控制、自动充值、自动托管、智能优惠券提示、GMS 排除商品、快速加速效果、复合任务卡片）及 UI 组件（头像、抽屉、轮播、指标图表、状态弹窗、操作日志），均提供完整的 Props/Emits 类型定义。
- **完整工具函数库** — 格式化（货币、日期、数字、字符串）、广告活动逻辑、CSV 导出、ACL 权限控制、事件总线、折扣计算、奖励、目标 ROAS 计算、LRU 缓存及页面滚动锁定、最低预算校验辅助函数（`min-budget/`，由功能开关 `szLimitMinBudgetAutoIncrease` 控制）。
- **完备的类型定义** — 广告活动、联盟、关键词、指标、货币、时间、报告、奖励及待办事项类型，供所有消费方模块共享。
- **统一请求工厂** — `createRequest()` 工厂函数，内置限流处理、安全防机器人/签名/DFP 集成及可配置响应拦截器，通过 `./request` MF 入口暴露。
- **TMS 埋点集成** — 通过 `tracking import` CLI 命令生成 42 个页面级埋点入口文件，配有 Vue 指令（`useTrackingDirective`）和包含会话 ID 增强的集中式 `report()` 函数。
- **框架兼容层** — 对卖家门户 `framework`（i18n、路由、店铺、环境、时间服务、弹窗、过滤器）进行统一封装，供所有消费方模块使用，并支持 BD 用户降级处理和 MCN 支持。
- **EDS Vue 组件统一导出** — 集中导出 40+ EDS Vue 设计系统组件和类型（`EdsTable`、`EdsButton`、`EdsModal`、`EdsForm`、`EdsSelector` 等），统一锁定版本（`5.0.36`）。
- **Webpack/Rspack 模块联邦** — 配置 `echarts`、`eds-vue`、`tracking`、`vendors` 及组件入口的代码分割，优化加载性能。同时支持 webpack 和 rsbuild。
- **共享组合式函数（Composables）** — `useVoucherEstimation`（防抖优惠券估算，含 LRU 缓存和 provide/inject）、`usePositiveOperationBoost`（操作加速横幅）、`useGenericPollExport`（通用轮询导出）。
- **组件文档系统** — 基于 VuePress + `vue-docgen` 的文档平台，支持 Props/Events/Slots 自动生成表格及 Demo 组件。

---

## 项目架构

```
┌─────────────────────────────────────────────────────────────────────┐
│                       卖家中心门户                                   │
│           (seller.{test|uat|prod}.shopee.{CID})                    │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ MMF 运行时
         ┌─────────────────────┼──────────────────────┐
         │                     │                       │
    pas-index             pas-product          pas-display / pas-livestream
    （MF 消费方）           （MF 消费方）          （MF 消费方）
         │                     │                       │
         └─────────────────────┼───────────────────────┘
                               │ 模块联邦（pas-common 别名）
                    ┌──────────▼────────────┐
                    │      pas-common        │
                    │   （MF 提供方）         │
                    │   MMC 模块 id: 404     │
                    │   端口: 8001           │
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

**关键架构决策：**
- `pas-common` 是**模块联邦提供方**（`consumer: false`），自身不消费其他模块。
- `eds-vue` 声明为**单例共享依赖**（版本 `5.0.36`，强制版本），防止多实例冲突。
- 代码分割将 `echarts`、`eds-vue`、`tracking`、`vendors`、首页入口及共享工具独立为不同 chunk，优化缓存效果。
- TypeScript 类型通过 `@shopee/module-federation-typescript`（`FederatedTypesPlugin`）生成，消费方项目通过 `@mf-types/pas-common/_types/` 使用。
- 通过 `mmc.config.js` 中的 `rsbuild` 配置，开发模式同时支持 webpack 和 rsbuild。

---

## 目录结构

```
pas-common/
├── mmc.config.js               # MMC/模块联邦配置（id: 404，端口: 8001）
├── package.json                # 依赖：eds-vue 5.0.36、echarts、vuelidate 等
├── .pas.tracking.config.js     # TMS 埋点 CLI 配置
├── .gitlab-ci.yml              # CI：lint、code_review、release_verify、自动部署 test/uat
├── eslintrc.js                 # ESLint 配置（继承 @shopee/pas-module-config）
├── commitlint.config.js        # Commit 消息规范检查
├── vuepress-docs/              # 组件文档（VuePress + vue-docgen）
└── src/
    ├── bootstrap.ts            # 模块启动入口
    ├── index.ts                # 根导出
    ├── components/             # 55+ 共享 Vue 3 组件
    │   ├── index.ts            # 完整组件导出（./components MF 入口）
    │   ├── homepage.ts         # 首页专用导出（./components/homepage MF 入口）
    │   ├── chart.ts            # 指标图表导出（./components/metric-chart MF 入口）
    │   ├── _shared/            # 共享资源、请求工具、SCSS 样式
    │   ├── ads-creation-sv-notice-modal/  # 广告创建时智能优惠券提示弹窗
    │   ├── ads-diagnosis/      # 广告健康诊断组件
    │   ├── auto-budget-increase/   # 自动增加预算弹窗
    │   ├── auto-escrow-drawer/ # 自动托管设置抽屉
    │   ├── auto-top-up-settings/   # 自动充值配置
    │   ├── avatar/             # 广告活动/店铺头像展示
    │   ├── back-home/          # 返回首页导航组件
    │   ├── bid-price-edit-popover/ # 关键词出价内联编辑
    │   ├── blank-modal/        # 通用空白弹窗包装器
    │   ├── brand-date-picker/  # 品牌广告日历日期选择器
    │   ├── bread-crumb/        # 面包屑导航
    │   ├── budget-edit-popover/    # 广告活动预算内联编辑
    │   ├── budget-input/       # 预算金额输入框
    │   ├── campaign-status-action/ # 广告活动暂停/恢复/结束操作
    │   ├── carousel/           # 图片轮播
    │   ├── common-card/        # 通用卡片布局
    │   ├── currency-input/     # 货币输入框
    │   ├── custom-eds-toast/   # 动态 Toast 通知
    │   ├── date-range-popover/ # 日期范围选择弹出框
    │   ├── drawer/             # 侧滑抽屉面板
    │   ├── ellipsis-text/      # 带 Tooltip 的文字截断
    │   ├── empty-ads/          # 广告列表空状态
    │   ├── export-report-button/   # 报告下载按钮
    │   ├── gmv-metric-switch/  # GMV/ROAS 指标切换
    │   ├── gms-exclude-product-drawer/  # GMS 排除商品管理抽屉
    │   ├── growth-tooltip/     # 增长指标提示
    │   ├── keyword-action-group/   # 关键词批量操作（出价、匹配类型）
    │   ├── keyword-list/       # 关键词展示列表
    │   ├── keyword-selector/   # 关键词搜索与选择
    │   ├── link-toast/         # 带链接的 Toast
    │   ├── loadable-list/      # 带加载状态的列表
    │   ├── manual-ads-migration/   # 手动广告迁移到 ROI2 控件
    │   ├── match-type-popover/ # 关键词匹配类型选择
    │   ├── metric-chart/       # 基于 ECharts 的绩效图表
    │   ├── modal-template/     # 状态弹窗模板（StatusModal）
    │   ├── multiple-cascader-select/ # 多级级联选择器
    │   ├── npa-bidding/        # NPA（非商品广告）出价控件
    │   ├── number-input/       # 数字输入组件
    │   ├── operation-entrance/ # 操作入口展示
    │   ├── operation-log/      # 审计/操作日志查看器
    │   ├── product-avatar/     # 商品图片头像
    │   ├── product-list/       # 商品广告列表（支持批量）
    │   ├── product-selector/   # 商品搜索与选择
    │   ├── rapid-boost-effect/ # 快速加速效果弹出框和图表
    │   ├── rec-action-panel/   # 推荐操作面板
    │   ├── remove-optimise-warning-banner/ # 优化移除警告横幅
    │   ├── render-unit/        # 通用渲染单元包装器
    │   ├── result-modal/       # 操作结果弹窗
    │   ├── rewards-center/     # 奖励/激励中心组件
    │   ├── roas-cold-start-prompt/ # ROAS 冷启动引导
    │   ├── roi/                # ROI/ROAS 出价控件（创建、编辑、弹窗）
    │   ├── scroll-toast/       # 滚动触发 Toast
    │   ├── secure-session/     # 安全会话处理
    │   ├── select-affiliates/  # 联盟选择组件
    │   ├── select-metrics/     # 指标列选择器
    │   ├── simple-pagination/  # 轻量分页组件
    │   ├── target-audience/    # 目标受众/TADS 受众弹窗
    │   ├── target-roas/        # 目标 ROAS 配置
    │   ├── time-edit-popover/  # 广告活动时段设置编辑
    │   ├── to-do-mini-card/    # 迷你待办卡片组件
    │   ├── ult-on-boarding/    # 引导横幅与公告
    │   └── warning-modal/      # 警告确认弹窗
    ├── utils/                  # 共享工具函数（./utils MF 入口）
    │   ├── index.ts
    │   ├── acl/                # 权限控制（ACCESS_KEYS 权限检查）
    │   ├── budget-input/       # 预算输入验证辅助
    │   ├── campaign/           # 广告活动业务逻辑工具
    │   ├── csv/                # CSV 导出工具
    │   ├── currency/           # 货币格式化与换算
    │   ├── date/               # 日期格式化工具
    │   ├── discount/           # 折扣计算工具
    │   ├── event-bus/          # 跨模块事件总线
    │   ├── fixed-card/         # 固定卡片布局工具
    │   ├── lru-cache/          # LRU 缓存（有界 Map；供 useVoucherEstimation 使用）
    │   ├── min-budget/         # 最低预算校验辅助函数（szLimitMinBudgetAutoIncrease 功能开关）
    │   ├── number/             # 数字格式化、convertServerNumber/convertClientNumber
    │   ├── number-adjustments/ # 数字调整辅助
    │   ├── prevent-body-scroll/# 页面滚动锁定工具
    │   ├── report/             # 报告生成工具
    │   ├── rewards/            # 奖励中心工具
    │   ├── string/             # 字符串操作工具
    │   ├── target-roas/        # 目标 ROAS 计算（openColdStartPrompt）
    │   ├── to-do-list/         # 待办事项工具
    │   ├── track/              # 埋点辅助工具
    │   └── util/               # 通用辅助函数
    ├── types/                  # 共享 TypeScript 类型定义（./types MF 入口）
    │   ├── index.ts
    │   ├── affiliate/          # 联盟程序类型
    │   ├── base/               # 基础/原始类型
    │   ├── campaign/           # 广告活动实体类型
    │   ├── common/             # 公共共享类型
    │   ├── currency/           # 货币类型
    │   ├── keyword/            # 关键词类型
    │   ├── metrics/            # 广告指标类型
    │   ├── number/             # 数字类型
    │   ├── report/             # 报告类型
    │   ├── rewards/            # 奖励类型
    │   ├── time/               # 时间/排期类型
    │   └── to-do-list/         # 待办事项类型
    ├── framework/              # 卖家门户框架桥接层（./framework MF 入口）
    │   ├── index.ts            # 导出：translate、app、shop、region、environment、
    │   │                       #       timeService、modal、filters、formatDate、
    │   │                       #       cdnFile、formatNumber、language、isBDUser、
    │   │                       #       shopSwitcher、sellerOrigin、Currency、AccountType
    │   └── currency.ts         # 货币工具类
    ├── eds-vue/                # EDS Vue 组件统一导出（./eds-vue MF 入口）
    │   └── index.ts            # 40+ 组件：EdsTable、EdsButton、EdsModal、
    │                           #   EdsSelector、EdsForm、createModalInstance 等
    ├── api/                    # 共享 API 函数（./api MF 入口）
    │   ├── index.ts
    │   ├── product/            # 商品广告 API 类型和函数
    │   ├── setup-helper/       # 设置助手 API 类型和函数
    │   ├── smart-voucher/      # 智能优惠券估算 API
    │   └── rewards-center/     # 奖励中心 API
    ├── request/                # 统一请求工厂（./request MF 入口）
    │   ├── index.ts            # createRequest()、getSkipError()
    │   └── types.ts            # BASE_PREFIX、REQUEST_METHOD、APIError、RequestOptions、CoreRequestFunction
    ├── tracking/               # TMS 埋点定义（./tracking MF 入口）
    │   ├── index.ts            # 导出：useTrackingDirective、TrackingProps
    │   ├── report.ts           # report()、getSharedComponentTrackingTrigger()
    │   ├── track.tpl.ejs       # 自动生成埋点文件的 EJS 模板
    │   ├── useTrackingDirective.ts  # Vue v-tracking 指令
    │   └── entries/            # 42 个页面级埋点入口目录
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
    │       ├── sellerCenterShopeeAds/  # 150+ 子模块，含 smartVoucher、spendingTask、escrow、GMS 等
    │       └── ...（共 42 个）
    ├── constants/              # 共享常量（不直接暴露为 MF 入口）
    │   └── index.ts            # BROAD_MATCH_PRICE_MULTIPLIER、Region、ACCESS_KEYS、
    │                           # API_ERROR_CODE_TO_MESSAGE、noop
    ├── composables/            # 共享组合式函数
    │   ├── index.ts
    │   ├── useGenericPollExport.ts     # 通用轮询导出组合式函数
    │   ├── useVoucherEstimation.ts     # 防抖优惠券估算，含 LRU 缓存和 provide/inject
    │   └── usePositiveOperationBoost.ts # 积极操作加速横幅组合式函数
    ├── filters/                # Vue 过滤器兼容层
    │   ├── cdn-formatter/
    │   ├── currency-formatter/
    │   ├── date-formatter/
    │   └── number-formatter/
    ├── polyfill/               # 框架 Polyfill
    │   └── _polyfill-event-bus.ts   # 事件总线 Polyfill
    └── ads-remote/             # ads-remote 模块消费的再导出
        ├── api.ts
        ├── components.ts
        ├── framework.ts
        ├── tracking.ts
        ├── types.ts
        └── utils.ts
```

---

## 快速开始

### 环境要求

| 要求 | 版本 |
|---|---|
| Node.js | >= 16.14.0（推荐 20） |
| pnpm | >= 8.0.0（安装 MMC 必须） |
| MMC CLI（`@shopee/multi-module-cli`） | 最新 v3.x |
| npm 仓库 | `https://npm.shopee.io/` |

全局安装 MMC（仅需一次）：

```bash
pnpm i -g @shopee/multi-module-cli

# 安装后运行配置
mmc setup

# 验证安装（应显示 4 个版本号）
mmc -V
```

### 配置说明

`pas-common` 配置为 MMC 模块 id `404`（门户 id `21` = local-seller-center），在 `mmc.config.js` 中设定：

```js
module.exports = {
  id: 404,
  port: 8001,
  type: "module",
  tech: "vue3",
  // ...
};
```

`eds-vue` 声明为单例共享依赖——`pas-common` 与所有消费方模块**必须**使用 `eds-vue@5.0.36`。

### 安装依赖

首次开发前运行一次：

```bash
yarn run init
# 弹出提示时选择 "local-seller-center"
```

> **注意：** 如果需要与消费方模块（如 `pas-product`）同时开发，两个项目都需执行 `yarn run init` 并选择**相同的门户选项**。

### 构建

```bash
# 本地构建
yarn build

# 仅类型检查
yarn type:check

# 查看 webpack 配置
yarn inspect
```

### 本地开发

**第一步：启动开发服务器**

```bash
yarn dev
```

该命令并行运行 `mmc dev`（携带 `LOCAL_DEV=1`）和 `vue-tsc -w` 进行类型监听。

WebStorm 用户请使用：

```bash
yarn dev:webstorm
```

**第二步：连接到开发服务器**

在浏览器中打开目标卖家中心测试环境：

```
https://seller.{test|uat}.shopee.{CID}
```

在浏览器 DevTools 控制台中启用开发模式：

```js
mmfDevtools.enable()
```

刷新页面，控制台出现 `[MMF_DEVTOOLS]` 和 `[HMR] connected` 表示开发服务器已连接。

**第三步：与消费方模块联调**

如需同时调试 `pas-common` 和消费方模块（如 `pas-product`），在两个项目分别执行 `yarn dev`，MMF 会同时连接两个本地开发服务器。

**代码检查：**

```bash
yarn lint           # 运行 ESLint + Stylelint
yarn lint:es:fix    # 自动修复 ESLint 问题
yarn lint:style:fix # 自动修复样式问题
yarn prettier       # 使用 Prettier 格式化代码
```

### 部署发布

生产部署通过 **Seller Portal** 构建系统管理。

**快速部署步骤：**

1. 打开 [Seller Portal 构建页面](https://seller-portal.i.shopee.io/build/modules-group)
2. 选择 **Shopee Ads (Seller center)** → **Pas Common** → 目标分支
3. 选择目标环境（test / UAT / 生产）
4. 选择 **Auto Publish** → 在门户中选择 `local-seller-center` 和 `cb-seller-center` → 选择全部地区
5. 如需功能分支部署，填写 **PFB 2.0** 字段
6. 点击 **Build & Publish**

**CI/CD（`.gitlab-ci.yml`）：**

| 阶段 | 触发时机 | 操作 |
|---|---|---|
| `lint` | 合并请求 | `yarn lint` |
| `code_review` | 合并请求 | AI 代码审查 |
| `release_verify` | 合并请求 | 部署平台验证 |
| `auto_deploy` | 推送到 `master` | `yarn deploy -e test && yarn deploy -e uat` |
| `pages` | 手动（`web`） | 构建 VuePress 文档 |

---

## API 文档

所有 API 端点使用版本前缀（通常为 `/api/pas/v1`）加上下表中列出的路径字符串。**页面**列指示定义该端点的组件或模块。

| 页面 | 页面路径 | API 端点 | 描述 |
|---|---|---|---|
| 设置助手 | `src/api/setup-helper/` | `/setup_helper/get_recommended_roi_two_target/` | 获取推荐的 ROI2 目标值 |
| 目标 ROAS | `src/components/target-roas/api/` | `/setup_helper/get_recommended_target_roi/` | 获取推荐的目标 ROAS 配置 |
| 关键词选择器 | `src/components/keyword-selector/api/` | `/setup_helper/list_keyword_hint/` | 获取关键词自动补全提示 |
| 关键词选择器 | `src/components/keyword-selector/api/` | `/setup_helper/list_recommended_keyword/` | 获取推荐关键词列表 |
| 关键词选择器 | `src/components/keyword-selector/api/` | `/setup_helper/search_keyword/` | 按查询搜索关键词 |
| 商品选择器 | `src/components/product-selector/api/` | `/setup_helper/product_selector/list_by_item_id/` | 按商品 ID 列表查询商品 |
| 商品选择器 | `src/components/product-selector/api/` | `/setup_helper/get_category_tree/` | 获取商品分类树 |
| 商品选择器 | `src/components/product-selector/api/` | `/category/page_active_collection_list/` | 获取活跃商品合集列表 |
| 商品选择器 | `src/components/product-selector/api/` | `/public/category/tree/` | 获取公共分类树 |
| 自动增加预算 | `src/components/budget-edit-popover/api/` | `/auto_budget_increase/edit/` | 编辑自动增加预算设置 |
| 自动增加预算 | `src/components/budget-edit-popover/api/` | `/auto_budget_increase/get/` | 获取自动增加预算设置 |
| 自动充值设置 | `src/components/auto-top-up-settings/api/` | `/topup/check_cncb_subaccount_password/` | 校验 CNCB 子账户密码 |
| 自动充值设置 | `src/components/auto-top-up-settings/api/` | `/topup/edit_auto_topup_setting/` | 编辑自动充值设置 |
| 自动充值设置 | `src/components/auto-top-up-settings/api/` | `/topup/get_auto_topup_setting/` | 获取自动充值设置 |
| 自动充值设置 | `src/components/auto-top-up-settings/api/` | `/topup/get_setting/` | 获取充值设置 |
| 自动充值设置 | `src/components/auto-top-up-settings/api/` | `/topup/get_suggest_auto_topup_setting/` | 获取建议的自动充值设置 |
| 自动充值设置 | `src/components/auto-top-up-settings/api/` | `/topup/set_has_seen_auto_topup/` | 标记已查看自动充值 |
| 自动托管抽屉 | `src/components/auto-escrow-drawer/api/` | `/topup/auto_escrow/edit_setting/` | 编辑自动托管设置 |
| 自动托管抽屉 | `src/components/auto-escrow-drawer/api/` | `/topup/auto_escrow/get_eligibility/` | 获取自动托管资格 |
| 自动托管抽屉 | `src/components/auto-escrow-drawer/api/` | `/topup/auto_escrow/get_estimated_auto_ads_data/` | 获取预估自动广告数据 |
| 自动托管抽屉 | `src/components/auto-escrow-drawer/api/` | `/topup/auto_escrow/get_estimated_topup_data/` | 获取预估充值数据 |
| 自动托管抽屉 | `src/components/auto-escrow-drawer/api/` | `/topup/auto_escrow/get_setting/` | 获取自动托管设置 |
| 手动广告迁移 | `src/components/manual-ads-migration/api/` | `/homepage/trigger_async_upgrade/` | 触发异步手动转 ROI2 升级 |
| 奖励中心 | `src/api/rewards-center/` | `/incentive/campaign/mass_optimize/` | 批量优化激励广告活动 |
| 奖励中心 | `src/api/rewards-center/` | `/incentive/list_banner/` | 获取奖励横幅列表 |
| 奖励中心 | `src/api/rewards-center/` | `/incentive/modify/` | 修改奖励计划 |
| 奖励中心 | `src/api/rewards-center/` | `/incentive/modify_banner/` | 修改奖励横幅 |
| 操作日志 | `src/components/operation-entrance/api/` | `/operation_log/query/` | 查询操作日志 |
| 操作日志 | `src/components/operation-entrance/api/` | `/operation_log/query_result_count/` | 获取操作日志结果数量 |
| 商品 API | `src/api/product/` | `/product/edit/` | 批量编辑商品广告活动 |
| 商品 API | `src/api/product/` | `/product/get_roi_two_uplift/` | 获取 ROI2 提升数据 |
| 商品 API | `src/api/product/` | `/product/gms/get_campaign_id/` | 获取 GMS 广告活动 ID |
| 商品 API | `src/api/product/` | `/product/list_estimated_simple_roi_two_data/` | 获取预估简单 ROI2 数据 |
| 商品 API | `src/api/product/` | `/product/list_overlapping_ads_for_roi_two/` | 获取 ROI2 重叠广告列表 |
| 商品 API | `src/api/product/` | `/product/list_recommended_roi_two_target/` | 获取推荐 ROI2 目标列表 |
| 手动广告迁移 | `src/components/manual-ads-migration/api/` | `/product/get_budget_data_for_creation/` | 获取创建预算数据 |
| 手动广告迁移 | `src/components/manual-ads-migration/api/` | `/product/get_estimated_data/` | 获取 ROI2 预估数据 |
| 手动广告迁移 | `src/components/manual-ads-migration/api/` | `/product/get_single_manual_upgrade_data/` | 获取单个手动升级数据 |
| QSS | `src/api/rewards-center/` | `/qss/sign_up_program/` | 注册 QSS 计划 |
| 导出报告 | `src/components/export-report-button/api/` | `/report/export_job/download/` | 下载报告（CRM） |
| 导出报告 | `src/components/export-report-button/api/` | `/report/export_job/get_download_url/` | 获取报告下载链接 |
| 导出报告 | `src/components/export-report-button/api/` | `/report/export_job/get_single_result/` | 获取单个报告结果状态 |
| 导出报告 | `src/components/export-report-button/api/` | `/report/export_job/trigger_or_get_previous/` | 触发报告导出或获取上次结果 |
| 操作日志导出 | `src/components/operation-entrance/api/` | `/report/export_job/get_operation_log_result/` | 获取操作日志导出结果 |
| 操作日志导出 | `src/components/operation-entrance/api/` | `/report/export_job/trigger_operation_log/` | 触发操作日志导出 |
| 品牌日期选择器 | `src/components/brand-date-picker/api/` | `/search_brand/get_calendar_info/` | 获取品牌广告日历信息 |
| 智能优惠券 | `src/api/smart-voucher/` | `/smart_voucher/list_voucher_estimation/` | 获取广告创建/编辑流程中的优惠券估算金额 |
| 目标受众 | `src/components/target-audience/` | `/target_audience/get_group_estimated_result/` | 获取受众群体预估结果 |
| 目标受众 | `src/components/target-audience/` | `/target_audience/list_available_option/` | 获取可用受众选项列表 |

### 模块联邦端点

消费方模块通过以下 MF 路径从 `pas-common` 导入资源：

| MF 入口 | 导入路径 | 内容 |
|---|---|---|
| `./components` | `pas-common/components` | 全部 55+ 共享组件 |
| `./components/homepage` | `pas-common/components/homepage` | 首页专用组件子集 |
| `./components/metric-chart` | `pas-common/components/metric-chart` | 仅指标图表组件 |
| `./utils` | `pas-common/utils` | 所有工具函数 |
| `./types` | `pas-common/types` | 所有类型定义 |
| `./framework` | `pas-common/framework` | 门户框架桥接层 |
| `./eds-vue` | `pas-common/eds-vue` | EDS Vue 组件和类型 |
| `./api` | `pas-common/api` | 共享 API 函数 |
| `./request` | `pas-common/request` | 统一请求工厂（`createRequest`、`BASE_PREFIX`、类型） |
| `./tracking` | `pas-common/tracking` | 埋点指令和类型 |
| `./tracking/entries/{page}` | `pas-common/tracking/entries/{page}` | 按页面划分的埋点函数 |

### 关键导出

**框架层（`pas-common/framework`）**

```typescript
import { translate, app, shop, region, environment, timeService, modal,
         formatDate, cdnFile, formatNumber, language, isBDUser,
         shopSwitcher, sellerOrigin, Currency, AccountType,
         EdsToastInstance, modalInstance, particularApp, TriggerOptions,
         bindVueFilters, filters } from "pas-common/framework";
```

**请求层（`pas-common/request`）**

```typescript
import { createRequest, getSkipError, BASE_PREFIX, REQUEST_METHOD } from "pas-common/request";
import type { RequestOptions, APIError, APIExternalResponse, CreateRequestConfig, CoreRequestFunction } from "pas-common/request";

const v1Request = createRequest({ version: BASE_PREFIX.V1 });
const data = await v1Request<ReqType, ResType>("/product/get/", { params: payload });
```

**工具函数（`pas-common/utils`）**

主要导出包括：
- `convertServerNumber(v)` / `convertClientNumber(v)` — 数值膨胀/缩小（÷/× 100,000）
- 货币、日期、数字、字符串格式化函数
- `useAcl` — 基于 `ACCESS_KEYS` 枚举的 ACL 权限检查
- 广告活动业务逻辑工具
- `openColdStartPrompt` — 目标 ROAS 冷启动提示

**常量（`pas-common/constants`）**

```typescript
import { BROAD_MATCH_PRICE_MULTIPLIER, Region, ACCESS_KEYS,
         API_ERROR_CODE_TO_MESSAGE, noop } from "pas-common/constants";
```

**智能优惠券 API（`src/api/smart-voucher/`）**

```typescript
import { listVoucherEstimation } from "src/api/smart-voucher";
// 根据 campaignType 和每个广告活动的 ROI/预算设置，返回优惠券估算金额
// （gainedVoucherAmount、roasGainedVoucherAmount、budgetGainedVoucherAmount）
```

**数值转换说明**

后端将数值膨胀 100,000 倍以规避浮点精度问题：

```typescript
// 在 pas-common 自身的 API 文件中：
import { convertServerNumber, convertClientNumber } from "src/utils";

// 在消费方模块中：
import { convertServerNumber, convertClientNumber } from "pas-common/utils";
```

---

## 本地存储

pas-common 使用以下浏览器存储键用于埋点会话管理：

| 存储类型 | 键名 | 用途 |
|---|---|---|
| `localStorage` | `SELLER_CENTER_SHOPEE_ADS_PAGE_SESSION_ID` | 页面会话 ID，通过 `report()` 注入到所有埋点数据中 |
| `sessionStorage` | `HC_SESSION_ID` | JSON 对象，包含 `sessionId` 用于用户会话追踪 |

这些键由 `src/tracking/report.ts` 读取，并自动注入到通过 `report()` 函数发送的每个埋点事件中。

---

## TMS 埋点追踪

### 概述

pas-common 集成 TMS（流量管理系统）进行行为分析埋点。`tracking/` 目录包含：

- **`report.ts`** — 核心 `report(params)` 函数，在调用 `app.tracker.trigger()` 前自动注入 `pageSessionId`（来自 `localStorage`）和 `userSessionId`（来自 `sessionStorage`）。
- **`useTrackingDirective.ts`** — Vue 指令 `v-tracking`，用于声明式埋点事件。
- **`entries/`** — 42 个自动生成的页面级埋点目录，每个均作为独立 MF 入口暴露（`./tracking/entries/{pageName}`）。

### 埋点入口

| 入口名称 | 描述 |
|---|---|
| `adsFssWaiverLandingPage` | FSS 豁免落地页 |
| `brandAdsDetail` | 品牌广告详情页 |
| `brandMaxAdsDetail` | 品牌 Max 广告详情页 |
| `campaignBudgetRecommendationPage` | 广告活动预算推荐 |
| `createBrandAds` | 品牌广告创建 |
| `createDisplayAds` | 展示广告创建 |
| `createLiveAds` | 直播广告创建 |
| `createNewProductAds` | 新商品广告创建 |
| `createProductAds` | 商品广告创建 |
| `createShopAds` | 店铺广告创建 |
| `editBrandMaxAds` | 品牌 Max 广告编辑 |
| `productAdsDetail` | 商品广告详情 |
| `qssCreatingYourAdsNowPopup` | QSS 创建广告弹窗 |
| `qssUnableToCreateAdsPopup` | QSS 无法创建广告弹窗 |
| `searchBrandAdDetails` | 搜索品牌广告详情 |
| `sellerCenterAdsCampaignPage` | 卖家中心广告活动页 |
| `sellerCenterAdsDetails` | 卖家中心广告详情 |
| `sellerCenterAdsHomepage` | 卖家中心广告首页 |
| `sellerCenterAdsMyAccountPage` | 卖家中心广告我的账户 |
| `sellerCenterAdsQssEnrolment` | 卖家中心 QSS 注册 |
| `sellerCenterAdsToDoList` | 卖家中心广告待办事项 |
| `sellerCenterAdsTopup` | 卖家中心广告充值 |
| `sellerCenterCampaignBudgetRecommendationPage` | 卖家中心广告活动预算推荐 |
| `sellerCenterCreateBrandAds` | 卖家中心创建品牌广告 |
| `sellerCenterCreateDisplayAds` | 卖家中心创建展示广告 |
| `sellerCenterCreateLiveAds` | 卖家中心创建直播广告 |
| `sellerCenterCreateProductAds` | 卖家中心创建商品广告 |
| `sellerCenterCreateShopAds` | 卖家中心创建店铺广告 |
| `sellerCenterDisplayAdDetail` | 卖家中心展示广告详情 |
| `sellerCenterEditDisplayAds` | 卖家中心编辑展示广告 |
| `sellerCenterLivestreamAdDetail` | 卖家中心直播广告详情 |
| `sellerCenterProductAdDetail` | 卖家中心商品广告详情 |
| `sellerCenterRestartLivestreamAd` | 卖家中心重启直播广告 |
| `sellerCenterRestartProductAd` | 卖家中心重启商品广告 |
| `sellerCenterRestartShopAd` | 卖家中心重启店铺广告 |
| `sellerCenterShopAdDetail` | 卖家中心店铺广告详情 |
| `sellerCenterShopeeAds` | 卖家中心 Shopee 广告主页（150+ 子模块，含 smartVoucher、smartVoucherDrawer、spendingTaskCreatePopup、spendingTaskDrawer、escrowFeeRatePopup、escrowRewardPopup、gmsCreatePopup、gmsProductManage、adsRewards、allAdsListGms、ocpmNoticePopup、takeRateRoasPopup、aiReportDrawer、brandMaxAdsLaunchPopUpV2 等） |
| `sellerCenterShopeeAdsQssGuidePage` | 卖家中心 QSS 引导页 |
| `sellerCenterShopeeAdsRewardsPage` | 卖家中心奖励页 |
| `sellerCenterTopUp` | 卖家中心充值页 |
| `sellerCenterViewRecommendationCards` | 卖家中心查看推荐卡片 |
| `shopAdsDetail` | 店铺广告详情页 |

### 导入埋点入口

使用 `tracking` CLI 从 TMS 工单自动生成入口文件：

```bash
tracking import -t {ticket-id}
```

该命令在 `src/tracking/entries/{pageName}/` 下生成：
- `types.ts` — TypeScript 埋点接口
- `index.ts` — 埋点函数（基于 `track.tpl.ejs` 模板）

**如果命令报鉴权错误**，请更新 TMS Token：

1. 访问 [https://trafficsuite.shopee.io/tms](https://trafficsuite.shopee.io/tms)
2. 打开 DevTools → Application → Cookies → `https://trafficsuite.shopee.io`
3. 复制 `_oauth2_proxy_mesos` Cookie 的值
4. 粘贴到 `.pas.tracking.tms.token` 文件中（该文件已 git-ignore）

### 埋点配置（`.pas.tracking.config.js`）

- TMS 组 ID：`0`
- Token 来源：`.pas.tracking.tms.token` 文件
- 输出按 `page` 和 `section` 字段分组
- 名称缩写规则：`Impression→Imp`、`SellerCenter→SC`、`Product→Prod`、`Keyword→Kw` 等

### 在消费方模块中使用埋点

```typescript
// 导入页面级埋点函数
import { trackClickSomething } from "pas-common/tracking/entries/createProductAds";

// 使用 v-tracking 指令
import { useTrackingDirective } from "pas-common/tracking";

// 使用共享组件埋点触发器
import { getSharedComponentTrackingTrigger } from "pas-common/tracking";
```

---

## 性能监控

### Webpack 代码分割

`mmc.config.js` 为生产环境配置以下 chunk 分组：

| Chunk 名称 | 内容 | 最小体积 |
|---|---|---|
| `echarts` | `echarts` + `zrender` 包 | 30 KB |
| `eds-vue` | `eds-vue`、`@eds-vue/*`（不含 svg）、`src/eds-vue` | 30 KB |
| `vendors` | 其他所有 `node_modules` | 50 KB |
| `tracking` | `src/tracking/` | 120 KB |
| `homepage-entry` | `src/components/homepage.ts` | 1 KB |
| `shared-entry` | `src/components/index.ts` | 1 KB |
| `shared` | `src/framework`、`src/api`、`src/utils`、`src/types` | 30 KB |

**模块优化设置：**
- `concatenateModules: true` — 作用域提升（Scope Hoisting）
- `chunkIds: "deterministic"` — 生产环境稳定 chunk ID
- `maxInitialRequests: 25`，`maxAsyncRequests: 25`

### 开发模式代码定位插件

开发模式下启用 `code-inspector-plugin`，支持从浏览器点击元素跳转到编辑器对应源码位置。编辑器通过 `EDITOR` 环境变量配置（默认为 `cursor`）：

```bash
yarn dev:webstorm   # 设置 EDITOR=webstorm
```

---

## 业务术语词汇表

代码库中常用业务术语：

| 术语 | 定义 |
|---|---|
| **ROAS / ROI** | 广告支出回报率 / 投资回报率。广告 GMV ÷ 广告收入。代码库中互用（`roi/`、`target-roas/`）。 |
| **CIR** | 成本收入比。广告收入 ÷ 广告 GMV。ROAS 的倒数。 |
| **CPC** | 每次点击成本。广告花费 ÷ 点击次数。 |
| **CTR** | 点击率。点击数 ÷ 展示数。 |
| **CPM** | 每千次展示成本。 |
| **CR** | 转化率。广告订单数 ÷ 广告总点击数。 |
| **ECPM** | 有效千次展示成本。广告总花费 ÷ 总展示数。 |
| **Take-Rate** | 广告收入 ÷ 平台 GMV。衡量 Shopee 通过广告实现商业化的效率。 |
| **oCPC / 简单模式** | 优化 CPC——系统自动选词并调整出价。 |
| **目标 ROAS** | 卖家设定的 ROAS 目标值；系统调整出价以达成目标。 |
| **广泛匹配** | 关键词匹配类型，相关查询可触发广告（乘数：`BROAD_MATCH_PRICE_MULTIPLIER = 1.2`）。 |
| **精确匹配** | 关键词匹配类型，仅完全相同的查询才触发广告。 |
| **QSS** | 快速启动服务。帮助新广告主快速启用广告。 |
| **TADS / DADS** | 定向广告/发现广告。基于受众细分的展示广告。 |
| **NPA** | 非商品广告。品牌/店铺广告的出价类型。 |
| **自动充值（ATU）** | 广告余额不足时自动充值。 |
| **托管（Escrow）** | 自动托管（ATU）——自动扣费的费率配置。 |
| **Smart Voucher（智能优惠券）** | 在广告创建时显示的优惠券估算和激励功能，基于卖家的 ROI 目标和每日预算设置展示预计获得的优惠券金额。 |
| **GMS** | 商品交易总额（Gross Merchandise Sales）广告类型。`GmsExcludeProductDrawer` 管理 GMS 广告活动的排除商品。 |
| **Rapid Boost（快速加速）** | 短期广告加速功能，通过对比加速前后的累计广泛匹配 GMV 曲线来衡量效果。 |
| **PFB** | 按功能分支部署，用于隔离测试。 |
| **GMV** | 商品交易总额。总交易金额。 |
| **ACL** | 访问控制列表。使用 `ACCESS_KEYS` 枚举进行权限门控。 |
| **SC** | 卖家中心——卖家管理广告的平台。 |
| **SIP** | Shopee 国际平台。 |
| **冷启动（Cold Start）** | 数据不足以进行准确预测的广告。 |
| **MCN** | 多频道网络。特殊卖家类型，对应代码中的 `isMCN` 标志。 |
| **SRM** | 卖家关系管理。组织卖家数据进行细分。 |
| **COD** | 货到付款。 |
| **MMC** | 多模块 CLI（`@shopee/multi-module-cli`）。模块联邦模块的构建和开发工具链。 |
| **MMF** | 多模块框架。连接卖家中心内 MF 提供方和消费方模块的运行时。 |

---

## 参考资料

- [GitLab 仓库](https://git.garena.com/shopee/isfe/ao/pas-common-vue3)
- [MMC 文档](https://seller-portal.i.test.shopee.io/mmc-docs/guide/getting-started.html)
- [Seller Portal 构建与发布](https://seller-portal.i.shopee.io/build/modules-group)
- [广告平台概览（SRA 文档）](https://sra.test.shopee.io/05.Business_Systems/5.3_Ads_Business_and_Architecture_Introduction/5.3.6._ads.platform.html)
- [TMS 平台](https://trafficsuite.shopee.io/tms)
- [Paid Ads 术语词汇表（Confluence）](https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPAD&title=Paid+Ads+Glossary)
- [组件文档（VuePress）](http://localhost:8080/isfe/ao/pas-common/) — 本地执行 `yarn docs:dev`
- [MMC DOD 支持](https://dod.shopee.io/team?id=296)

---

## 常见问题解答

**1. `yarn run init` 为什么要选择门户选项，应该选哪个？**

MMC 通过模块 id（`404`）从 Seller Portal 拉取测试环境配置（路由、参数）。标准开发选择 `local-seller-center`（门户 id `21`）。`pas-common` 和任何同时开发的消费方模块**必须选择相同的选项**，否则模块联邦连接会失败。

**2. 如何向 pas-common 新增共享组件？**

在 `src/components/{component-name}/` 下创建目录，包含 `index.ts`、`types.ts` 和 `.vue` 文件。在 `index.ts` 导出组件及类型，然后将导出添加到 `src/components/index.ts`（如首页也需使用，同步添加到 `homepage.ts`）。避免添加仅适用于单一广告类型的业务逻辑。

**3. 如何在消费方模块中使用 pas-common 的导出？**

使用 `pas-common` 别名导入：
```typescript
import { ProductSelector } from "pas-common/components";
import { convertServerNumber } from "pas-common/utils";
import { translate } from "pas-common/framework";
import { createRequest, BASE_PREFIX } from "pas-common/request";
```
TypeScript 类型在消费方项目中通过 `@mf-types/pas-common/_types/` 获取。

**4. `convertServerNumber` / `convertClientNumber` 的数值转换机制是什么？**

后端将货币和比率值膨胀 100,000 倍以避免浮点精度问题。接收 API 响应时使用 `convertServerNumber(v)`（除以 100,000），向 API 发送数据时使用 `convertClientNumber(v)`（乘以 100,000）。在 `pas-common` 自身的 API 文件中从 `src/utils` 导入；在消费方模块中从 `pas-common/utils` 导入。

**5. 如何为页面新增埋点入口？**

执行 `tracking import -t {ticket-id}`，其中 `{ticket-id}` 为 TMS 工单号。该命令自动在 `src/tracking/entries/{pageName}/` 下生成 `types.ts` 和 `index.ts`。`mmc.config.js` 通过 `fs.readdirSync` 动态读取 entries 目录，新入口会自动作为新 MF 端点（`./tracking/entries/{pageName}`）暴露。

**6. `homepage.ts` 导出与 `index.ts` 有何区别？**

`src/components/homepage.ts` 是 `src/components/index.ts` 的子集——只导出 `pas-index`（首页模块）也需要的组件。这种分离使首页能加载更小的初始包体。如果组件同时被首页和其他模块使用，需在两个文件中都导出。

**7. i18n 中何时用 `translate()`，何时用 `$t()`？**

Vue 模板中使用 `$t("key")`；TypeScript 文件和 Vue `<script setup>` 中使用 `translate("key")`（从 `pas-common/framework` 导入）。不要直接使用 `i18n.t()`。

**8. `useVoucherEstimation` 如何工作，何时使用？**

`useVoucherEstimation(options)` 是一个组合式函数，用于在广告创建/编辑流程中获取智能优惠券估算数据。它具备 500ms 防抖、最多 100 条的 LRU 缓存和过期请求取消机制。通过 provide/inject 模式，父组件调用 `useVoucherEstimation` 提供数据，子组件调用 `useVoucherEstimationInject()` 访问同一上下文。当构建需要基于卖家 ROI 目标和每日预算输入实时展示优惠券奖励估算的广告创建表单时，使用该 composable。

**9. 如何使用统一请求工厂（`createRequest`）？**

`./request` MF 入口暴露 `createRequest()`，返回一个支持 POST/GET/PUT 的统一请求函数，内置限流处理和安全集成：
```typescript
import { createRequest, BASE_PREFIX } from "pas-common/request";
const v1Request = createRequest({ version: BASE_PREFIX.V1 });
const data = await v1Request<ReqType, ResType>("/product/get/", { params: payload });
```

**10. 推送到 `master` 分支后会发生什么？**

CI 流水线通过 `yarn deploy -e test && yarn deploy -e uat`（使用 `release-bot`）自动部署到 **test** 和 **uat** 环境，对应 `.gitlab-ci.yml` 中的 `auto_deploy` 阶段。

<!-- Generated by ads-workspace/skills/ads-readme-generate | checked: 099987f8a94b84119c0d18417a1c54bf558bd726 | spec: 76fce5f679f9550b -->
