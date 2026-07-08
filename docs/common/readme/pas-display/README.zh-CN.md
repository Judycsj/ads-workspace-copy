<!-- ads-workspace-gdoc-sync: gdoc_id=1uiSnznmEpWcdtG6lUlAlnpZQZVlxv3nLb74oDHKsrsg gdoc_url=https://docs.google.com/document/d/1uiSnznmEpWcdtG6lUlAlnpZQZVlxv3nLb74oDHKsrsg/edit -->

# pas-display

> Shopee 广告平台的展示广告、搜索品牌广告和品牌考量广告管理模块

## 目录

- [项目简介](#项目简介)
- [核心功能](#核心功能)
- [项目架构](#项目架构)
- [目录结构](#目录结构)
- [快速开始](#快速开始)
  - [前置条件](#前置条件)
  - [配置说明](#配置说明)
  - [安装依赖](#安装依赖)
  - [构建](#构建)
  - [本地开发](#本地开发)
  - [开发流程](#开发流程)
  - [部署发布](#部署发布)
- [API 文档](#api-文档)
- [本地存储](#本地存储)
- [TMS 埋点追踪](#tms-埋点追踪)
- [性能监控](#性能监控)
- [业务术语词汇表](#业务术语词汇表)
- [参考资料](#参考资料)
- [常见问题](#常见问题)

---

## 项目简介

`pas-display` 是一个基于 Vue 3 + TypeScript 的微前端模块，用于管理 Shopee 广告平台中的展示广告（Display Ads）、搜索品牌广告（Search-Brand Ads）和品牌考量广告（Brand Consideration Ads）。该模块同时运行于卖家中心（SC）和 BD 中心（BDC），通过 Webpack Module Federation 与 `pas-common` 共享组件和工具函数。

---

## 核心功能

- **展示广告创建与管理** — 完整的广告创建流程，包括预约日历、受众群体定向（含自定义受众和受众扩展）、创意素材上传（PC/RN/DD 位置）、计费选项选择，以及带管理员消息历史的广告详情页
- **展示广告日落支持（Display Ads Sunset）** — 通过 `enableDisplayAdsSunset.displayAdsSunset` 开关实现首页轮播（展示广告）版位的平滑下线；通知期内（`displayAdsSunsetNoticePeriod` 为 `true`）在创建页显示日落提醒；日落激活后屏蔽展示广告创建入口
- **搜索品牌广告创建与管理** — 品牌搜索广告创建，支持关键词管理（按核心/别名/市场/套餐/其他分组）、落地页选择、品牌创意上传（图片和视频）、预期效果预测，以及高级权益展示
- **品牌考量广告** — 考量广告的创建/编辑，包含受众流转分析、多位置创意管理（弹窗、每日发现、瘦长横幅、悬浮组件、首页轮播横幅、首页轮播瘦长、DD Shopee Mall 卡片、DD Banner Mall 卡片、Mall 页面横幅、Mall 分类页横幅、分类页横幅）、DD Shopee Mall 卡片编辑时重传校验逻辑、最大预算获取，以及马来西亚（MY）地区专属文案支持（上传截止提示、提交弹窗文案、创意缺失/拒绝管理员消息），通过 `src/_shared/utils/brand-max-transify.ts` 中的 `getBrandMaxTransifyKey()` 实现
- **Brand Max 广告类型选择器** — 当 `szAdsBrandConsideration` 功能开关或展示广告日落激活时，广告创建入口页面从单选按钮组切换为标签卡片 UI，仅展示 Brand Max（考量广告）和搜索品牌广告两种类型
- **效果指标与报告** — 基于时间范围的指标图表（ECharts），支持自定义指标配置、报告配置持久化、受众流转数据，可从各广告类型的详情页访问
- **预算与出价管理** — 基于 Constantine 配置进行预算校验，预算调整提醒 Toast，考量广告最大预算获取，搜索品牌广告建议日预算
- **商品选择** — 搜索品牌广告创建中的商品查询与选择 UI，支持分类/搜索/推荐筛选
- **创意素材管理** — 专用的品牌图片和视频上传组件，Live/App/PC 预览组件，创意规格说明，视频帧提取，以及多横幅管理（最多 4 个横幅）
- **多平台支持** — 适配卖家中心和 BD 中心门户的 UI 和路由逻辑，卖家中心启用 SecureFetch 防机器人保护，BD 中心有独立的面包屑处理

---

## 项目架构

`pas-display` 遵循 **多模块框架（MMC）** 架构：

```
卖家中心 / BD 中心（宿主门户）
       │
       └── pas-display（MMC 模块，id: 129，type: module，tech: vue3）
               │
               ├── Module Federation 消费者
               │       └── pas-common（共享工具、组件、类型）
               │
               ├── Vue 3 路由（通过 app.registerRouterModule 注册）
               │       ├── /portal/marketing/pas/display  （展示广告）
               │       └── /portal/marketing/pas/brand    （搜索品牌/考量广告）
               │
               └── 全局 Store（Vue reactive）
                       ├── Constantine（来自后端的业务配置）
                       └── Meta（功能开关标志：extToggle、adsToggle）
```

**状态管理：**

状态通过 Vue 原生 reactive 对象管理（无 Pinia/Vuex）：

- `src/_shared/store/constantine.ts` — 响应式单例，持有从 `/config/get/` 拉取的完整 `Config` 对象；提供预算上限、创意尺寸约束、货币精度及各广告类型的特有配置（`displayAds`、`searchBrandAds`、`brandConsiderationAds`）
- `src/_shared/store/meta.ts` — 两个响应式 Store：
  - `metaNonAdsDataStore` — 持有 `extToggle`（功能开关，如 `szAdsBrandConsideration`、`szAdsSearchBrandAds`）和 `userShop`
  - `adsMetaDataStore` — 持有 `adsToggle`（标志位，如 `displayAds`、`enableDisplayAdsSunset { displayAdsSunset, displayAdsSunsetNoticePeriod, sunsetDate }`、`brandAdsPackage`）和 `brandAdsPackage`
- `src/_shared/store/page-status/` — 页面级短暂状态（预期效果、已选时间范围、指标选择、报告加载状态）

**路由配置：**

路由通过 `src/_shared/router/index.ts` 中的 `app.registerRouterModule` 注册。所有路由共享一个 `beforeEnter` 守卫，在任何页面渲染前并行预取 Constantine、AdsMeta 和 MetaNonAdsData。

| 路由 | 组件 | 说明 |
|---|---|---|
| `/portal/marketing/pas/display` | `pages/index.vue` | 展示广告列表/首页 |
| `/portal/marketing/pas/display/create` | `pages/create/display-ads/index.vue` | 展示广告创建 |
| `/portal/marketing/pas/display/edit/:campaignId` | `pages/create/display-ads/index.vue` | 展示广告编辑 |
| `/portal/marketing/pas/display/detail/:campaignId` | `pages/detail/display-ads/index.vue` | 展示广告详情 |
| `/portal/marketing/pas/brand` | `pages/index.vue` | 品牌广告列表/首页 |
| `/portal/marketing/pas/brand/create` | `pages/create/index.vue` | 搜索品牌/考量广告创建 |
| `/portal/marketing/pas/brand/search-brand-edit/:campaignId` | `pages/create/index.vue` | 搜索品牌广告编辑 |
| `/portal/marketing/pas/brand/detail/:campaignId` | `pages/detail/search-brand/index.vue` | 搜索品牌广告详情 |
| `/portal/marketing/pas/brand/consideration-edit/:campaignId` | `pages/create/index.vue` | 考量广告编辑 |
| `/portal/marketing/pas/brand/consideration-detail/:campaignId` | `pages/detail/brand-consideration/index.vue` | 考量广告详情 |

**数据流：**
1. 路由守卫（`beforeEnter`）在任何页面渲染前并行预取 `Constantine`、`AdsMeta` 和 `MetaNonAdsData` 三个 Store。
2. 页面从 `Constantine` Store 读取配置（预算限制、创意尺寸约束等）。
3. 功能开关从 `metaNonAdsDataStore.extToggle` 和 `adsMetaDataStore.adsToggle` 读取。
4. `adsToggle` 中的 `enableDisplayAdsSunset` 嵌套开关控制展示广告日落行为：`displayAdsSunset` 屏蔽创建入口；`displayAdsSunsetNoticePeriod` 在创建页显示日落提醒。
5. 当 `szAdsBrandConsideration` 为 `true` 或 `enableDisplayAdsSunset.displayAdsSunset` 为 `true` 时，品牌广告创建入口（`pages/create/index.vue`）渲染标签卡片选择器，仅展示品牌考量广告和搜索品牌广告两种类型。
6. API 响应使用 `BASE_PREFIX.V1`（`/api/pas/v1`）或 `BASE_PREFIX.V3`（`/api/marketing/v3/pas`）。
7. 后端数值扩大了 10^5 倍，必须使用 `pas-common/utils` 中的 `convertServerNumber` / `convertClientNumber` 进行转换。

**关键模式：**
- **按需加载** — 所有页面组件通过 MMC 代码分割；模块入口 `src/index.ts` 仅注册路由
- **Module Federation** — `pas-common` 作为远程模块消费；`eds-vue` 在 `mmc.config.js` 中被显式从共享配置中移除，每个模块单独打包自己版本（`pas-display` 使用 5.0.40）
- **Rsbuild 支持** — `mmc.config.js` 同时提供 webpack 和 rspack（rsbuild）配置；rsbuild 在 dev 模式下用于更快的 HMR

---

## 目录结构

```
pas-display/
├── mmc.config.js                    # MMC 模块配置（id: 129, vue3）
├── package.json
├── src/
│   ├── index.ts                     # 入口文件 – 导入路由注册
│   ├── custom.d.ts                  # 自定义类型声明
│   ├── polyfill/
│   │   └── _polyfill-event-bus.ts   # Vue 3 $on/$off/$emit 兼容层（基于 WeakMap）
│   ├── track/
│   │   ├── index.ts                 # 重新导出 pas-common 中的所有埋点函数
│   │   └── types.ts                 # 埋点类型定义（ProductSelectionMap）
│   ├── _shared/
│   │   ├── api/
│   │   │   ├── base.ts              # BASE_PREFIX 枚举（V1, V3）
│   │   │   ├── common/              # 日历信息、活跃商品检查、店铺数据、事件上报
│   │   │   ├── create-page/         # 展示广告创建 API（计费、预估、受众群体）
│   │   │   │   └── brand/           # 搜索品牌/考量广告创建 API（关键词、预算、创意）
│   │   │   ├── detail-page/         # 展示广告详情 API（创意、消息、报告）
│   │   │   │   ├── brand/           # 搜索品牌广告详情 API（编辑、权限、横幅）
│   │   │   │   └── consideration/   # 品牌考量广告详情 API（编辑、横幅）
│   │   │   ├── meta/                # 配置（Constantine）+ Meta（开关）API 及类型定义
│   │   │   ├── product-selector/    # 商品查询 & 按商品 ID 列表 API
│   │   │   ├── report/              # 时序指标、报告配置、受众流转 API
│   │   │   └── request/             # commonRequest 工厂 + SecureFetch + 验证码处理
│   │   ├── components/
│   │   │   ├── back-button/         # 返回导航
│   │   │   ├── brand-creative-preview/  # App / Live / PC 预览标签页 + 预览提示
│   │   │   ├── brand-cratives-guideline/ # 品牌创意规格说明
│   │   │   ├── brand-creatives-uploader/# 品牌图片上传器
│   │   │   ├── budget-adjust-toast/ # 预算变更提醒 Toast
│   │   │   ├── cascader/            # 自定义级联选择器组件
│   │   │   ├── creatives-guideline/ # 创意规格说明展示
│   │   │   ├── creatives-preview/   # 展示广告创意预览
│   │   │   ├── date-range-picker/   # 自定义日期范围选择器
│   │   │   ├── DateRangePicker/     # 旧版日期选择器（date-picker 子包）
│   │   │   ├── keywords-content/    # 关键词列表展示
│   │   │   ├── landing-page/        # 落地页选择器
│   │   │   ├── location-preview/    # 地理定向预览
│   │   │   ├── metric-chart/        # 基于 ECharts 的折线指标图 + 指标项
│   │   │   ├── navs/                # 导航组件
│   │   │   ├── product-selection/   # 商品选择 UI（含标签页选择）
│   │   │   ├── reserved-keywords-preview/ # 保留关键词预览
│   │   │   ├── simple-modal/        # 通用弹窗封装
│   │   │   ├── video-creatives-uploader/  # 视频创意上传器
│   │   │   └── video-preview/       # 视频预览组件
│   │   ├── composables/
│   │   │   ├── useBrandEstimatedResult.ts # 预期效果文本格式化（导出 useSearchBrandEstimatedTexts）
│   │   │   ├── useBudgetConfig.ts         # 基于 Constantine 的预算配置（最低日预算、输入步长）
│   │   │   ├── useConsiderationBudget.ts  # 考量广告最大预算
│   │   │   ├── useCreativesEditing.ts     # 多横幅创意编辑状态（最多 4 个横幅）
│   │   │   ├── useDuration.ts             # 报告日期范围与时间配置同步
│   │   │   ├── useKeywords.ts             # 关键词获取与分组
│   │   │   ├── useSelectMetrics.ts        # 报告指标选择与持久化
│   │   │   ├── useTable.ts                # 报告表格数据加载与排序
│   │   │   └── useVue.ts                  # useRoute / useRouter / useVueInstance 辅助函数
│   │   ├── constants/
│   │   │   ├── api.ts               # 所有 API 接口路径
│   │   │   ├── campaign.ts          # CampaignStates / PaymentStates 枚举
│   │   │   ├── CDN.ts               # CDN 主机、规格说明/预览图片路径
│   │   │   ├── index.ts             # ToggleInfo 枚举，重新导出 campaign 常量
│   │   │   ├── keyword.ts           # KeywordTabType、KeywordGroupName、分组翻译映射
│   │   │   ├── message.ts           # AdminMessageType 枚举、MessageMap
│   │   │   ├── metric-field.ts      # 指标定义 & 看板配置（默认/品牌/考量）
│   │   │   ├── placement.ts         # DISPLAY_ADS_PLACEMENT = 9
│   │   │   ├── region.ts            # Region 类型、域名后缀、时区区域、RegionCode 枚举
│   │   │   ├── router.ts            # RouterMap 枚举 + RouterPath + 性能标记与测量
│   │   │   └── time.ts              # TimeRanges 枚举、ONE_DAY、DatePickerListItem 类型
│   │   ├── router/
│   │   │   └── index.ts             # 路由注册（展示广告 + 品牌广告路径）、页面会话 ID
│   │   ├── store/
│   │   │   ├── constantine.ts       # 业务配置响应式 Store
│   │   │   ├── meta.ts              # 功能开关响应式 Store（metaNonAdsDataStore + adsMetaDataStore）
│   │   │   └── page-status/         # 页面级状态（预期效果、时间范围、指标、报告状态）
│   │   ├── styles/
│   │   │   ├── constants.scss       # SCSS 变量（自动注入）
│   │   │   └── index.scss           # 全局样式（自动注入）
│   │   ├── types/
│   │   │   ├── index.ts             # PlainType、SummaryDate、ReportLoadStatus 枚举
│   │   │   └── metric-item.ts       # MetricSourceItem、ReportMetricItem 类型扩展
│   │   └── utils/
│   │       ├── brand-max-transify.ts # Brand Max 广告区域感知 transify 键选择器 — getBrandMaxTransifyKey(keyType) 在马来西亚（MY）地区返回带 _my 后缀的键，其他地区返回默认键；覆盖 UPLOAD_DEADLINE、SUBMIT_PROMPT_NOTE_TIPS_2、CREATIVE_MISSING_MSG_TITLE、REJECT_NOTE_BANNER_CONTENT 四类键
│   │       ├── constantine.ts       # getCurrencyPrecision / getCpmCurrencyPrecision / getCpcCurrencyPrecision
│   │       ├── creative-initialization.ts # 创意项 + 校验初始化辅助函数
│   │       ├── domain.ts            # 域名校验与名称辅助函数
│   │       ├── duration.ts          # getTimeRange 报告日期范围封装
│   │       ├── eventBus.ts          # 基于 mitt 的全局事件总线
│   │       ├── formatter/
│   │       │   ├── currency/        # localFormatCurrency、getCurrency、currencySymbol
│   │       │   ├── date/            # createDate、getDate、customFormatDate、时间戳转换
│   │       │   ├── number/          # formatNumber、formatNumberLocalized
│   │       │   └── percentage/      # formatPercentage
│   │       ├── index.ts             # addFilePrefix、removeFilePrefix、textCapitalize、formatRange、formatMsToMinSec
│   │       ├── timezone.ts          # 店铺/浏览器时间偏移转换、displayDateRange
│   │       └── type-guards.ts       # isString、isNumber、isObject、isPlainObject、isFunction、isBoolean
│   └── pages/
│       ├── index.vue                # 共享根页面（展示广告 & 品牌广告首页）
│       ├── create/
│       │   ├── index.vue            # 品牌广告创建入口（Brand Max / 搜索品牌 / 展示广告标签卡片）
│       │   ├── type.ts              # CreativeListItem、FormInstance 类型
│       │   ├── composables/
│       │   │   └── useBrandFormData.ts  # 品牌考量广告编辑表单数据加载
│       │   ├── display-ads/         # 展示广告创建页 + 弹窗
│       │   │   ├── modals/          # audience-type、confirm、creation-form、custom-audience、
│       │   │   │                    # reservation、result-card、time-length、user-guide
│       │   │   ├── mixins/          # BillingBehaviour 混入
│       │   │   ├── constants.ts     # showResult、创建表单常量
│       │   │   └── types.ts         # 展示广告创建类型
│       │   ├── search-brand/        # 搜索品牌广告创建页 + 组件
│       │   │   ├── components/      # brand-budget-setting、creatives-setting、estimated-result、
│       │   │   │                    # premium-benefits、modals（publish-status）
│       │   │   └── constants.ts     # 校验、创意转换、管理员消息映射
│       │   └── components/          # 共享创建组件
│       │       ├── consideration-basic-form/  # 考量广告名称、日期、预算表单
│       │       ├── consideration-creative/    # 按版位创意上传（App + PC）
│       │       ├── consideration-preview/
│       │       ├── consideration-preview-prompt/
│       │       ├── consideration-date-picker.vue
│       │       ├── creatives-uploader/
│       │       ├── estimate-result/
│       │       ├── preview-empty/
│       │       ├── constants.ts     # 位置到横幅映射、创意配置辅助函数
│       │       └── type.ts          # EstimatedResultItem、SelectDateRange
│       └── detail/
│           ├── display-ads/         # 展示广告详情页
│           │   ├── modals/          # ad-creatives、basic-info、creatives-upload、
│           │   │                    # message-history、skeleton、steps
│           │   ├── constant.ts      # 图表指标、受众类型映射
│           │   ├── types.ts         # 详情页类型
│           │   └── utils.ts         # 详情页工具函数
│           ├── search-brand/        # 搜索品牌广告详情页
│           │   ├── components/      # banner、creatives（编辑/查看/视频/管理员消息）、
│           │   │                    # detail-header、message-history、reserved-keywords
│           │   └── constants.ts     # 指标、横幅配置、创意校验器
│           └── brand-consideration/ # 品牌考量广告详情页
│               ├── components/
│               │   ├── audience-movement/  # 汇总卡片、步骤容器
│               │   ├── banner/
│               │   ├── creatives/          # 创意项视图
│               │   ├── detail-header/
│               │   └── performance-detail-table/
│               └── constants.ts     # 考量指标、广告可编辑性判断
```

---

## 快速开始

### 前置条件

| 依赖项 | 版本要求 |
|---|---|
| Node.js | ≥ 16.14.0（推荐 Node 20）|
| Yarn | 任意版本（项目包管理器）|
| pnpm | ≥ 8.0.0（安装 MMC 所需）|
| MMC（`@shopee/multi-module-cli`）| V3.x（本项目使用分支 `zangse/ads-mmc-master-v2-rebase`）|
| Python | 3.10（MMC 原生依赖所需）|

全局安装 MMC：

```bash
pnpm i -g @shopee/multi-module-cli
mmc setup
mmc -V  # 应显示 4 个版本（mmc-core、mmc-vue、mmc-react、mmc-vue3）
```

> **注意**：npm 全局仓库必须设置为 `https://npm.shopee.io/`。

### 配置说明

模块 ID 和门户绑定在 `mmc.config.js` 中定义：

```js
module.exports = {
  id: 129,       // 在 Seller Portal 中注册的模块 ID
  type: "module",
  tech: "vue3",
  // ...
};
```

路由参数和门户绑定存储在 `config/.remote-config.json`（由 `yarn run init` 自动生成，**请勿手动提交**）。

SCSS 变量会自动从以下文件注入：
- `src/_shared/styles/constants.scss`
- `src/_shared/styles/index.scss`

### 安装依赖

在首次开发前（或依赖项变更时）运行**一次**：

```bash
# 卖家中心初始化（门户 ID 21）
yarn run init -p 21

# BD 中心初始化（门户 ID 17）
yarn run init -p 17
```

> `yarn run init` 安装依赖并从 Seller Portal 拉取远端配置。该命令会覆盖 `.browserslistrc`、`.stylelintrc.json` 和 `tsconfig.json`。

### 构建

本地构建（用于检视，非生产用途）：

```bash
yarn build
# 或
mmc build
```

生产构建通过 [Seller Portal](https://seller-portal.i.shopee.io/) 触发（详见[部署发布](#部署发布)）。

### 本地开发

消费 `pas-common` 有两种模式：

#### 本地模式（默认 `yarn dev`）

需要在本地运行 `pas-common` 开发服务器（端口 8001）。先启动 `pas-common` 开发服务器，再运行：

```bash
yarn dev
```

如果 `pas-common` 未在本地运行，将看到以下错误：
```
<e> [FederatedTypesPlugin] Unable to download 'pas-common' remote types index file: connect ECONNREFUSED 127.0.0.1:8001
```

#### 远端模式

无需本地 `pas-common` 服务器，直接使用远端 CDN 上发布的 `master` 分支类型：

```bash
yarn dev:remote
```

使用指定的 `pas-common` 分支：

```bash
yarn dev -b {feature-branch-name}
```

其他脚本命令：

| 脚本 | 用途 |
|---|---|
| `yarn dev:webstorm` | 启动开发服务器（集成 WebStorm 编辑器）|
| `yarn start` | 使用 SC 门户（id 21）初始化，然后启动远端开发模式 |
| `yarn inspect` | 检视 webpack/rspack 配置 |
| `yarn lint` | 运行 ESLint + Stylelint |
| `yarn lint:es:fix` | 自动修复 ESLint 问题 |
| `yarn lint:style:fix` | 自动修复 Stylelint 问题 |
| `yarn type:check` | 运行 vue-tsc 类型检查 |

### 开发流程

启动开发服务器后：

1. 进入所选门户的测试环境：
   - **卖家中心**：[https://seller.test.shopee.sg](https://seller.test.shopee.sg) — 使用 [Pas Helper Chrome 插件](https://confluence.shopee.io/pages/viewpage.action?pageId=1776244098)一键登录
   - **BD 中心**：[https://bd-centre.test.shopee.com/ads-crm/shop](https://bd-centre.test.shopee.com/ads-crm/shop) — 按 Shop ID 搜索店铺并进入展示广告

2. 打开浏览器 DevTools，连接本地开发服务器：
   - 点击 **MMF DevTools** 图标 → **Connect to Dev Server**
   - 或在控制台中运行：`mmfDevtools.enable()`

3. 重新加载页面 — 门户将从本地开发服务器加载资源。控制台中出现 `[MMF_DEVTOOLS]` 和 `[HMR] connected` 表示连接成功。

### 部署发布

生产构建和发布通过 [Seller Portal](https://seller-portal.i.shopee.io/) 管理：

1. **构建**：选择 `pas-display` 所在的模块组，填写构建信息，点击 **Build**。
2. **发布**：构建成功后，在构建记录行点击 **Publish**，填写发布表单（门户、PFB、地区）。
3. **下线**：构建前开启 **Offline Mode**，构建并发布后该模块将下线。

CI 部署命令：

```bash
yarn deploy:ci   # release-bot 自动发布
yarn deploy      # release-bot 自动分支（-a）及 master 分支（-b master）
```

**CI/CD 流水线**（`.gitlab-ci.yml`）：

GitLab CI 流水线运行于 `harbor.shopeemobile.com/seller-center/multi-cli-tool-v3` 镜像，包含以下阶段：

| 阶段 | 任务 | 触发条件 | 描述 |
|---|---|---|---|
| `lint` | `lint_sc` | Merge Request | 使用 SC 门户（id 21）初始化后运行 `yarn lint` |
| `lint` | `lint_bd` | Merge Request | 使用 BD 门户（id 17）初始化后运行 `yarn lint` |
| `parallel_jobs` | `ai-code-review` | Merge Request | 自动化 AI 代码审查（来自 `pas-tech/node-tools` 模板） |
| `release_verify` | `release_verify` | Merge Request | 通过 deploy-platform API 验证发布 |
| `auto_deploy` | `auto_deploy` | 推送到 `master` | 自动部署到 `test` 和 `uat` 环境（通过 `yarn deploy`） |

---

## API 文档

所有 API 接口路径定义在 `src/_shared/constants/api.ts`。请求通过 `src/_shared/api/request/index.ts` 中的 `commonRequest` 发起，该函数封装了 `pas-common` 的 `createRequest`，提供：

- 自动错误处理（频率限制错误码 7 时显示 Toast）
- 默认 `skipError: true`（pas-display 特有默认值）
- SecureFetch 防机器人保护（仅限卖家中心，BD 用户禁用）
- 通过 `bindCaptchaEvent()` 处理验证码弹窗

**API 基础前缀**（`src/_shared/api/base.ts`）：

| 前缀 | 路径 |
|---|---|
| `BASE_PREFIX.V1` | `/api/pas/v1` |
| `BASE_PREFIX.V3` | `/api/marketing/v3/pas` |

| 页面 | 页面 URL | API 接口路径 | 描述 |
|---|---|---|---|
| 配置与 Meta | 所有页面（beforeEnter） | `/config/get/` | 获取 Constantine 业务配置 |
| 配置与 Meta | 所有页面（beforeEnter） | `/meta/get/` | 获取广告 Meta 数据（adsToggle、brandAdsPackage） |
| 配置与 Meta | 所有页面（beforeEnter） | `/meta/get_non_ads_data/` | 获取非广告 Meta 数据（extToggle、userShop） |
| 展示广告创建 | `/portal/marketing/pas/display/create` | `/display/create/` | 创建展示广告 |
| 展示广告创建 | `/portal/marketing/pas/display/create` | `/display/get_calendar_info/` | 获取预约日历信息（含受众扩展） |
| 展示广告创建 | `/portal/marketing/pas/display/create` | `/display/get_estimated_result/` | 获取展示广告预期效果 |
| 展示广告创建 | `/portal/marketing/pas/display/create` | `/display/list_billing_option/` | 列出可用计费选项 |
| 展示广告创建 | `/portal/marketing/pas/display/create` | `/display/list_audience_group/` | 列出受众群体 |
| 展示广告编辑 | `/portal/marketing/pas/display/edit/:campaignId` | `/display/edit/` | 编辑展示广告 |
| 展示广告详情 | `/portal/marketing/pas/display/detail/:campaignId` | `/display/get_single_detail/` | 获取展示广告详情 |
| 展示广告详情 | `/portal/marketing/pas/display/detail/:campaignId` | `/display/upload_creative/` | 上传展示广告创意文件 |
| 展示广告详情 | `/portal/marketing/pas/display/detail/:campaignId` | `/display/update_creative/` | 更新展示广告创意 |
| 展示广告详情 | `/portal/marketing/pas/display/detail/:campaignId` | `/display/cancel/` | 取消展示广告 |
| 展示广告详情 | `/portal/marketing/pas/display/detail/:campaignId` | `/display/list_admin_message/` | 获取管理员消息历史 |
| 展示广告详情 | `/portal/marketing/pas/display/detail/:campaignId` | `/display/close_admin_message/` | 关闭/忽略管理员消息 |
| 搜索品牌广告创建 | `/portal/marketing/pas/brand/create` | `/search_brand/create/` | 创建搜索品牌广告 |
| 搜索品牌广告创建 | `/portal/marketing/pas/brand/create` | `/search_brand/get_estimated_result/` | 获取搜索品牌广告预期效果 |
| 搜索品牌广告创建 | `/portal/marketing/pas/brand/create` | `/search_brand/get_suggest_budget/` | 获取建议日预算 |
| 搜索品牌广告创建 | `/portal/marketing/pas/brand/create` | `/search_brand/product_query/` | 查询商品 |
| 搜索品牌广告创建 | `/portal/marketing/pas/brand/create` | `/search_brand/product_list_by_item_id/` | 按商品 ID 列表查询 |
| 搜索品牌广告创建 | `/portal/marketing/pas/brand/create` | `/brand_ads/list_grouped_keyword/` | 列出分组关键词（核心/别名/市场/套餐/其他） |
| 搜索品牌广告创建 | `/portal/marketing/pas/brand/create` | `/brand_ads/list_reserved_keyword/` | 列出保留关键词 |
| 搜索品牌广告创建 | `/portal/marketing/pas/brand/create` | `/creative/upload/` | 上传品牌创意图片 |
| 搜索品牌广告创建 | `/portal/marketing/pas/brand/create` | `/brand_ads/get_video_meta/` | 提取视频帧元数据 |
| 搜索品牌广告编辑 | `/portal/marketing/pas/brand/search-brand-edit/:campaignId` | `/search_brand/batch_edit/` | 批量编辑搜索品牌广告 |
| 搜索品牌广告详情 | `/portal/marketing/pas/brand/detail/:campaignId` | `/search_brand/get_single_detail/` | 获取搜索品牌广告详情 |
| 搜索品牌广告详情 | `/portal/marketing/pas/brand/detail/:campaignId` | `/search_brand/edit/` | 编辑搜索品牌广告（从详情页） |
| 搜索品牌广告详情 | `/portal/marketing/pas/brand/detail/:campaignId` | `/search_brand/is_updatable/` | 检查搜索品牌广告是否可更新 |
| 搜索品牌广告详情 | `/portal/marketing/pas/brand/detail/:campaignId` | `/search_brand/list_admin_message/` | 获取搜索品牌管理员消息 |
| 搜索品牌广告详情 | `/portal/marketing/pas/brand/detail/:campaignId` | `/search_brand/close_admin_message/` | 关闭搜索品牌管理员消息 |
| 搜索品牌广告详情 | `/portal/marketing/pas/brand/detail/:campaignId` | `/search_brand/event_report/` | 上报搜索品牌事件 |
| 搜索品牌广告详情 | `/portal/marketing/pas/brand/detail/:campaignId` | `/search_brand/event_get/` | 获取搜索品牌事件数据 |
| 考量广告创建 | `/portal/marketing/pas/brand/create` | `/brand_consideration/create/` | 创建品牌考量广告 |
| 考量广告创建 | `/portal/marketing/pas/brand/create` | `/brand_consideration/get_calendar_info/` | 获取考量广告预约日历 |
| 考量广告创建 | `/portal/marketing/pas/brand/create` | `/brand_consideration/get_max_budget/` | 获取考量广告最大预算 |
| 考量广告创建 | `/portal/marketing/pas/brand/create` | `/brand_consideration/get_estimated_and_booking/` | 获取预期效果与预约信息 |
| 考量广告编辑 | `/portal/marketing/pas/brand/consideration-edit/:campaignId` | `/brand_consideration/edit/` | 编辑品牌考量广告 |
| 考量广告详情 | `/portal/marketing/pas/brand/consideration-detail/:campaignId` | `/brand_consideration/get_single_detail/` | 获取品牌考量广告详情 |
| 考量广告详情 | `/portal/marketing/pas/brand/consideration-detail/:campaignId` | `/brand_consideration/close_admin_message/` | 关闭考量广告管理员消息 |
| 报告（所有详情页） | 详情页 | `/report/get/` | 获取带指标的报告数据 |
| 报告（所有详情页） | 详情页 | `/report/get_time_graph/` | 获取时序图表数据 |
| 报告（所有详情页） | 详情页 | `/report/get_config/` | 获取已保存的报告配置 |
| 报告（所有详情页） | 详情页 | `/report/update_time_config/` | 更新时间范围配置 |
| 报告（所有详情页） | 详情页 | `/report/update_selected_metric_config/` | 更新已选指标配置 |
| 报告（所有详情页） | 详情页 | `/report/get_audience/` | 获取受众流转数据 |
| 通用 | 多个页面 | `/shop/check_has_enough_active_item/` | 检查店铺是否有足够的活跃商品 |
| 通用 | 多个页面 | `/shop/get_preview_data/` | 获取店铺预览数据 |

**数值转换：**
后端数值扩大了 10^5 倍，始终需要进行转换：
```typescript
import { convertServerNumber, convertClientNumber } from "pas-common/utils";
// API 响应 → UI
item.budget = convertServerNumber(item.budget);
// UI → API 请求
payload.dailyBudget = convertClientNumber(payload.dailyBudget);
```

---

## 本地存储

| 键名 | 值 | 用途 |
|---|---|---|
| `SELLER_CENTER_SHOPEE_ADS_PAGE_SESSION_ID` | UUID 字符串 | 页面会话 ID，每次路由路径变更时重新生成。用于将同一页面会话中的埋点事件关联起来，供数据分析使用。 |

页面会话 ID 在 `src/_shared/router/index.ts` 中管理。每次路由变更（路径与前一路由不同时），通过 `uuid.v4()` 生成新的 UUID 并存储到 `localStorage`。如果路径未变化（如表单提交或数据刷新），则保留现有会话 ID。

---

## TMS 埋点追踪

所有埋点函数从 `pas-common` 的追踪入口重新导出，位于 `src/track/index.ts`。**禁止直接从 `pas-common/tracking/entries/` 导入**，始终通过 `src/track` 导入：

```typescript
import { reportClickOfBrandAdsDtlPerf } from "src/track";
```

**埋点入口来源：**

| 追踪入口 | 描述 |
|---|---|
| `sellerCenterCreateDisplayAds` | 展示广告创建（卖家中心）|
| `sellerCenterEditDisplayAds` | 展示广告编辑（卖家中心）|
| `sellerCenterDisplayAdDetail` | 展示广告详情（卖家中心）|
| `createDisplayAds` | 展示广告创建事件 |
| `createBrandAds` | 搜索品牌广告创建事件（取消、发布、视频切换、上传、关键词编辑）|
| `brandAdsDetail` | 搜索品牌广告详情事件（创意模板、横幅、效果、视频）|
| `sellerCenterCreateBrandAds` | 搜索品牌广告创建页面曝光（卖家中心）|
| `editBrandMaxAds` | Brand Max 广告编辑事件（曝光、取消、发布）|
| `brandMaxAdsDetail` | Brand Max 广告详情事件（曝光、效果、状态变更、商业洞察）|

---

## 性能监控

`pas-display` 使用 **Web Performance API**（`performance.mark` / `performance.measure`）衡量页面加载时间。标记点和测量工具定义在 `src/_shared/constants/router.ts`。

**性能标记：**

| 常量 | 标记名称 | 用途 |
|---|---|---|
| `PERFORMANCE_MARK_INDEX_ENTER` | `pas_brand_ads_index_enter` | 模块首页路由进入 |
| `PERFORMANCE_MARK_CREATE_ENTER` | `pas_brand_ads_create_enter` | 创建页路由进入 |
| `PERFORMANCE_MARK_DETAIL_ENTER` | `pas_brand_ads_detail_enter` | 详情页路由进入 |
| `PERFORMANCE_MARK_CONSIDERATION_DETAIL_ENTER` | `pas_brand_ads_consideration_detail_enter` | 考量广告详情路由进入 |
| `PERFORMANCE_MARK_CREATE_MOUNTED` | `pas_brand_ads_create_mounted` | 创建页组件挂载完成 |
| `PERFORMANCE_MARK_DETAIL_MOUNTED` | `pas_brand_ads_detail_mounted` | 详情页组件挂载完成 |
| `PERFORMANCE_MARK_CONSIDERATION_DETAIL_MOUNTED` | `pas_brand_ads_consideration_detail_mounted` | 考量广告详情组件挂载完成 |

**测量工具函数：**

```typescript
import {
  generateDetailPerformanceData,
  generateCreatePerformanceData,
  generateConsiderationDetailPerformanceData,
} from "src/_shared/constants/router";

// 在对应页面的 mounted() 钩子中调用
const perfData = generateDetailPerformanceData();
// 返回：{ moduleToEnter, enterToMounted, moduleToMounted }，单位毫秒
```

标记点在路由的 `beforeEnter` 守卫中设置，当模块导航离开展示/品牌广告路径时清除（重置逻辑位于 `src/_shared/router/index.ts`）。

---

## 业务术语词汇表

| 术语 | 释义 |
|---|---|
| **展示广告（Display Ads）** | 基于预约的横幅广告，展示于高流量版位（每日发现、RN、PC）|
| **搜索品牌广告（SBA）** | 出现在搜索结果顶部的品牌搜索广告，针对保留关键词 |
| **品牌考量广告** | 以品牌认知为目标的广告，针对受众细分，位置包括弹窗、每日发现、瘦长横幅、悬浮组件、首页轮播和 Mall 页面横幅 |
| **Brand Max** | 搜索品牌广告的一种套餐类型，具有高级功能和更高的预算层级 |
| **Constantine** | 后端业务配置服务；值在运行时通过接口获取后存储于 `Constantine` 响应式 Store |
| **MetaNonAdsData / AdsMeta** | 功能开关 Store（`extToggle`、`adsToggle`、`brandAdsPackage`）|
| **展示广告日落（Display Ads Sunset）** | 由 `enableDisplayAdsSunset` 开关控制；在通知期内显示日落提醒，日落后屏蔽展示广告（首页轮播）创建入口 |
| **CPM（千次曝光成本）** | 每 1000 次曝光的广告费用 |
| **CPC（单次点击成本）** | 每次点击的广告费用 |
| **CIR（成本收益比）** | 广告收益 / 广告 GMV |
| **ROI / ROAS（投资回报率）** | 广告 GMV / 广告收益 |
| **CTR（点击率）** | 点击次数 / 曝光次数 |
| **CR（转化率）** | 广告订单数 / 点击次数 |
| **ECPM（有效千次曝光成本）** | 总广告花费 / 总曝光次数 |
| **曝光（Impression）** | 广告被用户看到一次 |
| **GMV（商品交易总额）** | 归因于广告的总销售额（归因窗口 7 天）|
| **每日发现（Daily Discovery, DD）** | Shopee App 首页信息流广告位；创意尺寸：531×792 像素 |
| **RN（React Native）** | 移动端横幅广告位；创意尺寸：1200×640 像素 |
| **PC 创意** | 桌面端横幅广告位；创意尺寸：1200×360 像素 |
| **瘦长横幅（Skinny Banner）** | 宽而矮的横幅；创意尺寸：1200×110 像素（PC）/ 1200×360 像素（App）|
| **悬浮组件（Floating Widget）** | 小型悬浮创意；尺寸：360×360 像素 |
| **弹窗（Pop-up）** | 全屏弹窗创意；尺寸：580×720 像素 |
| **BDC / BD 中心** | BD Centre — 内部 CRM 平台，供客户经理管理大型广告主账户 |
| **SC / 卖家中心（Seller Center）** | 卖家管理广告和商品的平台 |
| **QSS（快速启动服务）** | 帮助新广告主快速上手的入门项目 |
| **CampaignStates（广告状态）** | 可能的广告状态：`scheduled`（已排期）、`ongoing`（进行中）、`paused`（已暂停）、`ended`（已结束）、`banned`（已封禁）、`cancelled`（已取消）、`creative_missing`（创意缺失）、`creative_reviewing`（创意审核中）、`creative_rejected`（创意被拒）、`temp_reserved`（临时预留）、`unknown`（未知）|
| **页面会话 ID** | UUID，存储于 `localStorage` 键 `SELLER_CENTER_SHOPEE_ADS_PAGE_SESSION_ID`，每次路由切换时重新生成 |
| **Take-Rate（变现率）** | 广告收益 / 平台 GMV，衡量平台广告变现效率 |
| **广告订单（Ads Order）** | 用户在点击广告后 7 天内下单即计为一个广告订单 |

---

## 参考资料

- [pas-display GitLab 仓库](https://git.garena.com/shopee/isfe/ao/pas-display)
- [pas-common GitLab 仓库](https://git.garena.com/shopee/isfe/ao/pas-common)
- [MMC 文档](https://seller-portal.i.test.shopee.io/mmc-docs/guide/getting-started.html)
- [MMC 开发指南](https://seller-portal.i.test.shopee.io/mmc-docs/guide/basic/development.html)
- [MMC 初始化指南](https://seller-portal.i.test.shopee.io/mmc-docs/guide/basic/initialization.html)
- [Seller Portal 构建与发布](https://seller-portal.i.test.shopee.io/docs/pages/seller-portal/build-and-release.html)
- [Paid Ads 术语表（Confluence）](https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPAD&title=Paid+Ads+Glossary)
- [Pas Helper Chrome 插件](https://confluence.shopee.io/pages/viewpage.action?pageId=1776244098)
- [BD 中心店铺列表](https://bd-centre.test.shopee.com/ads-crm/shop?type=all)
- [Seller Portal（生产环境）](https://seller-portal.i.shopee.io/)

---

## 常见问题

**1. 为什么 `yarn dev` 报错 `ECONNREFUSED 127.0.0.1:8001`？**

默认的 `yarn dev` 命令以本地模式运行，需要在端口 8001 上有一个 `pas-common` 开发服务器。请先启动 `pas-common` 开发服务器，或改用 `yarn dev:remote` 从远端 master 分支加载类型。

**2. `yarn dev` 和 `yarn dev:remote` 有什么区别？**

`yarn dev`（本地模式）从本地运行的 `pas-common` 开发服务器（端口 8001）获取类型，适用于同时修改 `pas-common` 的场景。`yarn dev:remote` 从远端 CDN 上发布的 `master` 分支类型获取，无需本地 `pas-common` 服务器。使用 `yarn dev -b {分支名}` 可指定远端特定分支。

**3. 每次 `yarn dev` 前都需要运行 `yarn run init` 吗？**

不需要。`yarn run init` 只需运行一次（或在依赖项或门户配置发生变化时）。该命令安装依赖并从 Seller Portal 拉取门户配置。之后每天开发只需运行 `yarn dev` 即可。

**4. 如何在浏览器的卖家中心页面访问本地开发服务器？**

运行 `yarn dev` 后，进入卖家中心或 BD 中心的测试环境，打开浏览器 DevTools，在控制台中运行 `mmfDevtools.enable()`，然后重新加载页面。控制台出现 `[MMF_DEVTOOLS]` 和 `[HMR] connected` 即表示本地服务器已连接。

**5. 业务配置值（最低预算、创意尺寸等）从哪里读取？**

所有业务配置值均来自 `Constantine` 响应式 Store（`src/_shared/store/constantine.ts`），通过 `beforeEnter` 路由守卫在每次路由进入前预取。访问方式：
```typescript
import { constantine } from "src/_shared/store/constantine";
constantine?.displayAds?.minBudget;
```

**6. 如何读取功能开关标志？**

功能开关存储于 `metaNonAdsDataStore.extToggle`（非广告类开关）和 `adsMetaDataStore.adsToggle`（广告专属开关）：
```typescript
import { metaNonAdsDataStore, adsMetaDataStore } from "src/_shared/store/meta";
metaNonAdsDataStore?.extToggle?.featureName;
adsMetaDataStore?.adsToggle?.featureName;
// 展示广告日落开关
adsMetaDataStore?.adsToggle?.enableDisplayAdsSunset?.displayAdsSunset;
adsMetaDataStore?.adsToggle?.enableDisplayAdsSunset?.displayAdsSunsetNoticePeriod;
adsMetaDataStore?.adsToggle?.enableDisplayAdsSunset?.sunsetDate;
```

**7. 新增埋点函数应该放在哪里？**

不要在 `pas-display` 中创建新的埋点函数。应在 `pas-common/tracking/entries/` 中定义追踪函数，然后在 `src/track/index.ts` 中重新导出，最后从 `src/track` 导入使用。

**8. 为什么 `mmc.config.js` 要删除 `eds-vue` 的共享配置？**

`pas-display` 需要使用自己独立的 `eds-vue`（版本 5.0.40），而不是与宿主门户共享的版本。`extendPackConfig` 函数从 Module Federation 的 `shared` 配置中移除 `eds-vue`，使得每个模块自行打包各自所需版本。

**9. 页面会话 ID 有什么作用？**

UUID 页面会话 ID 存储于 `localStorage` 键 `SELLER_CENTER_SHOPEE_ADS_PAGE_SESSION_ID`，并在每次路由路径变更时重新生成。用于将同一页面会话中发生的埋点事件关联起来，供数据分析使用。

**10. 如何在 BD 中心（而非卖家中心）上运行该模块？**

运行 `yarn run init -p 17` 以使用 BD 中心门户（门户 ID 17）进行初始化，之后正常启动开发服务器即可。模块会自动检测 `app.bdUser.id`，并相应调整面包屑导航和 SecureFetch 行为。

**11. 展示广告日落功能激活后会发生什么？**

当 `adsMetaDataStore.adsToggle.enableDisplayAdsSunset.displayAdsSunset` 为 `true` 时，展示广告（首页轮播）选项从创建页隐藏，品牌广告创建入口切换为标签卡片，仅展示品牌考量广告和搜索品牌广告。通知期内（`displayAdsSunsetNoticePeriod` 为 `true`），创建页显示含日落日期（`sunsetDate`）的提醒横幅。

**12. 为什么编辑考量广告时无法保存 DD Shopee Mall 卡片的创意改动？**

编辑品牌考量广告时，若 DD Shopee Mall 卡片创意已处于审核通过或审核拒绝状态，且图片未重新上传，则不得仅修改创意文案并提交——必须同时重新上传图片，否则会触发校验错误。此规则防止将未变更的创意重复提审。

<!-- Generated by ads-workspace/skills/ads-readme-generate | checked: ba899929e8c3ad220d49f3871d554342f5ccdecb | spec: 76fce5f679f9550b -->
