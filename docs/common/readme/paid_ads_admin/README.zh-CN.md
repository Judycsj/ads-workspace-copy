<!-- ads-workspace-gdoc-sync: gdoc_id=14ofwWi4JzhKdwXFhwT5O91m1lHKWE6kDXVn_RwuDHKc gdoc_url=https://docs.google.com/document/d/14ofwWi4JzhKdwXFhwT5O91m1lHKWE6kDXVn_RwuDHKc/edit -->

# Paid Ads Admin

## 目录

- [项目概述](#项目概述)
- [核心功能](#核心功能)
- [项目架构](#项目架构)
- [目录结构](#目录结构)
- [快速上手](#快速上手)
  - [环境准备](#环境准备)
  - [配置说明](#配置说明)
  - [安装依赖](#安装依赖)
  - [构建](#构建)
  - [本地开发](#本地开发)
  - [开发指南](#开发指南)
  - [部署](#部署)
- [API 文档](#api-文档)
- [部署说明](#部署说明)
  - [前端静态资源（Space CMDB）](#前端静态资源space-cmdb)
  - [BFF（已废弃）](#bff已废弃)
- [业务术语表](#业务术语表)
- [参考资料](#参考资料)
- [常见问题](#常见问题)

---

## 项目概述

Paid Ads Admin 是一个基于 React 18 + Vite 的内部单页应用，为 Shopee 广告运营团队提供统一的广告管理后台。后台支持全类型广告管理（商品广告、店铺广告、直播广告、视频广告、Banner 广告、展示广告、品牌广告）、账单与充值管理、广告创意审核、欺诈/白名单/黑名单工具，以及跨 12 个区域（SG、ID、MY、PH、TH、TW、VN、BR、MX、CO、CL、AR）的广告 CRM 数据监控。

---

## 核心功能

- **商品广告（USF Keyword Ads）** — 总览、报表、操作日志、扣费日志、GMS 广告创建工具、诊断
- **店铺广告（USF Shop Ads）** — 总览、报表、操作日志、扣费日志、关键词白名单
- **直播广告** — 总览、报表、操作日志、扣费日志
- **视频广告** — 总览、报表、操作日志、扣费日志
- **Banner 广告** — 活动配置、总览、报表、操作日志、创意审核、套餐管理、关键词提名
- **展示广告** — 白名单、库存管理、广告管理（创建/编辑）、创意审核、账单与支付、账单信息、展示广告余额日志
- **品牌广告（Brand Consideration Ads）** — 活动总览、报表、操作日志、创意审核、扣费日志、库存分配
- **充值/手动广告余额** — 手动充值、扣款、转账、批量上传/审批历史、广告余额子类型管理
- **余额日志** — 账户余额日志查看
- **欺诈工具** — 欺诈用户管理
- **白名单/黑名单** — 用户白名单管理，支持六种操作模式（批量添加/移除、单个添加/移除、开放全部、关闭全部）；支持特殊白名单类型——ROI 设置（ROI3）、店铺广告 2.0、Escrow 强制费率（5 列 CSV：店铺 ID、固定费率、可选费率变更类型/值、GMS 覆盖标志）以及视频广告（2 列 CSV：userid、subtype KOL/Seller），各类型有专属 CSV 校验逻辑和显示约束；关键词/广告黑名单管理
- **Bad Case 基准测试** — 基准审查与结果分析
- **重建索引工具** — 广告重建索引与审计
- **DB 查看器** — 管理员数据库查看器
- **可视化工具** — 广告实体信息可视化
- **广告 CRM 用户同步（Cron Job Sync）** — CRM 数据同步任务管理
- **账户设置** — 账户功能操作与操作日志
- **线上测试工具** — Flag 标签重置工具
- **返利手动审核** — 返利审核

---

## 项目架构

### 技术栈

| 层次         | 技术                                                            |
| ------------ | --------------------------------------------------------------- |
| 框架         | React 18                                                        |
| 构建工具     | Vite 5                                                          |
| 语言         | TypeScript                                                      |
| 状态管理     | Redux (redux-thunk + `@reduxjs/toolkit`) + Recoil + react-query |
| 路由         | React Router 6（`createBrowserRouter`）                         |
| UI 组件库    | Ant Design 5                                                    |
| CSS 预处理器 | SCSS (sass)                                                     |
| HTTP 客户端  | axios                                                           |
| Protobuf     | ts-proto                                                        |

### 应用入口

```
index.html
└── src/main.tsx           ← ReactDOM.createRoot 入口
    └── src/App.tsx        ← createBrowserRouter、AuthWrapper、PageContext
        └── src/routes/root.tsx  ← Ant Design Layout（Header + Sider + Content）
            └── <Outlet />       ← src/bundle.ts 懒加载的页面组件
```

### 状态管理

Redux store 在 `src/_shared/redux/index.ts` 中通过 `@reduxjs/toolkit` 的 `configureStore` 创建，包含以下 Slice：

| Slice                   | 状态类型                     | 描述                     |
| ----------------------- | ---------------------------- | ------------------------ |
| `balance`               | `BalanceState`               | 余额日志                 |
| `benchmark`             | `BadCaseBenchmarkState`      | Bad Case 基准测试        |
| `blacklistKeywords`     | `BlackListKeywordsState`     | 黑名单关键词             |
| `brandConsiderationAds` | `BrandConsiderationAdsState` | 品牌广告                 |
| `dbViewer`              | `DbViewerState`              | DB 查看器                |
| `displayAds`            | `DisplayAdsState`            | 展示广告                 |
| `inventoryManagement`   | `InventoryManagementState`   | 展示广告库存             |
| `fraudTool`             | `FraudState`                 | 欺诈工具                 |
| `keywordNomination`     | `KeywordNominationState`     | Banner 广告关键词提名    |
| `listFlag`              | `ListFlagState`              | 线上测试 Flag            |
| `manualAdsCredit`       | `ManualAdsCreditState`       | 手动充值/余额            |
| `packageManagement`     | `PackageManagementState`     | Banner 广告套餐          |
| `pageHistory`           | `HistoryState`               | 页面导航历史             |
| `searchBrandAds`        | `SearchBrandAdsState`        | Banner/Search Brand 广告 |
| `usfKeywordAds`         | `UsfKeywordAdsState`         | 商品广告                 |
| `usfShopAds`            | `UsfShopAdsState`            | 店铺广告                 |
| `videoAds`              | `VideoAdsState`              | 视频广告                 |
| `accountSettings`       | `AccountSettingsState`       | 账户设置                 |
| `router`                | `RouterState`                | react-router-redux       |

### 路由

路由以枚举形式定义在 `src/_shared/config/routes.ts`，并在 `src/bundle.ts` 中注册。所有页面通过 `lazyLoad()` 实现**懒加载**。路由的 `basename` 为从 URL 路径提取的 `/<region>`（如 `/sg`）。默认重定向：`/` → `/usfkeyword`。

区域路由过滤由 `src/bundle.ts` 中的 `bundlesFilter()` 实现。主要限制：

- **AR**：无 Boost Ads、Shop Ads、Live Ads、Video Ads、Display Ads、Banner Ads、Cron Job Sync、欺诈工具、可视化工具
- **MX / CO / CL**：无 Banner Ads 配置 / 总览 / 创意审核
- **MX**：无 Boost Ads 变量设置

### API 请求架构

API 请求通过 axios 发送，接口常量定义于 `src/_shared/constant/api.ts`，使用两种路径前缀：

- `/bff/*` — 仍通过遗留 BFF（NestJS，已废弃）代理的接口
- `/api/v2/*` — 已在 MTS-ECP 注册的现行接口

新接口需在请求中设置 `X-Soup-Object-Code` 请求头（区域代码）用于 SOUP 权限校验：

```ts
instance.defaults.headers.post[
  "X-Soup-Object-Code"
] = getLocalRegion()?.toLocaleLowerCase();
```

MTS-ECP 接口管理控制台：https://space.shopee.io/mts/ecpnonlive/domain-listing/endpoint-listing?domain=admin.ads.shopee.io

---

## 目录结构

```
paid_ads_admin/
├── src/
│   ├── _shared/                    # 共享工具与组件
│   │   ├── api/                    # API 调用函数及鉴权
│   │   ├── assets/                 # 静态图片及 SVG
│   │   ├── components/             # 共享 UI 组件
│   │   │   ├── AdsOverviewTemplate/    # 总览页模板（USF 广告）
│   │   │   ├── CsvExport/              # CSV 导出按钮
│   │   │   ├── CsvReader/              # CSV 读取/解析
│   │   │   ├── CustomizeForm/          # 通用搜索表单（日期、输入、下拉等）
│   │   │   ├── DeductionLogTemplate/   # 扣费日志模板
│   │   │   ├── OperationLogTemplate/   # 操作日志模板
│   │   │   ├── PageTemplate/           # 灵活页面模板
│   │   │   ├── PageWrapper/            # 标准页面包装器
│   │   │   ├── ReportingTemplate/      # 报表页模板
│   │   │   ├── WithAuthContext/        # HOC：提供 pageKey
│   │   │   ├── WithLayout/             # HOC：应用布局
│   │   │   ├── WithPermissionWrapper/  # HOC：SOUP 权限校验
│   │   │   └── WithProvider/           # HOC：Redux Provider
│   │   ├── config/
│   │   │   ├── routes.ts               # 路由枚举
│   │   │   └── commonType.ts / constants.ts
│   │   ├── constant/
│   │   │   ├── api.ts                  # 所有 API 接口常量
│   │   │   └── global.ts               # Region 枚举、FormatType、PlatformTypes
│   │   ├── hook/                   # 自定义 React Hooks
│   │   ├── redux/                  # Redux store：reducers、actions、typings
│   │   ├── typings/                # 类型文件（自定义 + proto 生成）
│   │   └── utils/                  # 工具函数（日期、CSV、区域等）
│   ├── 404/                        # 404 页面
│   ├── NoPermissionPage/           # 无平台权限页面
│   ├── accountSettings/            # 账户设置页面
│   ├── balance/                    # 余额日志
│   ├── bannerAds/                  # Banner 广告页面
│   ├── benchmark/                  # Bad Case 基准测试页面
│   ├── blacklistkeyword/           # 黑名单关键词页面
│   ├── boostAds/                   # Boost 广告变量设置
│   ├── brandConsiderationAds/      # 品牌广告页面
│   ├── cronJobSync/                # 广告 CRM 用户同步
│   ├── dbViewer/                   # 数据库查看器
│   ├── displayAds/                 # 展示广告页面
│   ├── featureOperation/           # 功能操作页面
│   ├── fraudTool/                  # 欺诈工具页面
│   ├── liveAds/                    # 直播广告页面
│   ├── liveTestingTool/            # 线上测试工具（Flag 重置）
│   ├── loginCallback/              # SSO 登录回调
│   ├── manualAdsCredit/            # 充值/手动广告余额页面
│   ├── rebateManualReview/         # 返利手动审核
│   ├── reindex/                    # 重建索引工具
│   ├── rootShare/                  # 鉴权、上下文、Hooks、共享组件
│   ├── routes/                     # 应用布局：root.tsx（Header + Sider）
│   ├── usfKeywordAds/              # 商品广告（USF Keyword）页面
│   ├── usfShopAds/                 # 店铺广告（USF Shop）页面
│   ├── videoAds/                   # 视频广告页面
│   ├── visualiser/                 # 广告实体可视化工具
│   ├── whitelist/                  # 白名单管理
│   ├── App.tsx                     # 路由配置、AuthWrapper、PageContext
│   ├── bundle.ts                   # 路由与组件懒加载映射
│   ├── config.ts                   # Kayatoast siteConfig（侧边导航）
│   ├── main.tsx                    # 应用入口
│   └── theme.scss                  # 全局 Ant Design 主题覆盖
├── static/                         # 公共静态资源
├── deploy/                         # 部署脚本
├── index.html                      # HTML 入口
├── vite.config.ts                  # Vite 配置（代理、路径别名、插件）
├── tsconfig.json                   # TypeScript 配置
├── package.json                    # 依赖与脚本
└── commitlint.config.js            # Commitlint 配置
```

---

## 快速上手

### 环境准备

- **Node.js** ≥ 16.0.0
- **yarn**（通过 Homebrew 安装：`brew install yarn` 或使用操作系统包管理器）

### 配置说明

Vite 开发服务器会代理 `/bff` 和 `/api` 路径。在 `package.json` 的 `kayaToast.proxyPath` 中配置：

```json
"kayaToast": {
  "proxyPath": ["/bff", "/api"]
}
```

默认代理目标为 `https://admin.ads.test.shopee.io/`。如需修改目标（例如本地 BFF），编辑 `vite.config.ts`：

```ts
// 取消注释以将 /bff 代理至本地 BFF
// target: path === "/bff" ? "http://localhost:7001/" : "https://admin.ads.test.shopee.io/"
```

如需启用 PFB（转发浏览器 Cookie），创建 `.env` 文件：

```ini
VITE_ENABLE_PFB=true
VITE_PFB=<your_PFB_cookie_value>
```

如需添加新的代理路径前缀，更新 `package.json` 的 `proxyPath` 数组即可（`vite.config.ts` 已动态遍历该数组）。

### 安装依赖

```sh
yarn install
```

### 构建

```sh
# 生产构建
yarn build

# JS 和 CSS lint 检查
yarn lint

# 自动修复 lint 问题
yarn lint:fix

# 代码格式化
yarn format
```

### 本地开发

```sh
yarn start
```

开发服务器运行在 **8888** 端口（`http://localhost:8888`）。所有 `/bff` 和 `/api` 请求自动代理至 `https://admin.ads.test.shopee.io/`。

本地开发需要有效的浏览器 Cookie（SPC_ST、SPC_CDS 等），请先登录 admin.ads.test.shopee.io，再将 Cookie 复制到本地浏览器会话中。

### 开发指南

**添加新页面：**

1. 在 `src/_shared/config/routes.ts` 添加路由常量。
2. 在 `src/bundle.ts` 注册懒加载组件条目。
3. 在 `src/config.ts` 的 `sideNav` 中添加侧边栏导航项。
4. 在 `src/` 下合适的功能目录中创建页面组件。

**添加新 API 接口：**

新接口必须先在 MTS-ECP 注册：

- MTS ECP 控制台（非线上）：https://space.shopee.io/mts/ecpnonlive/domain-listing/endpoint-listing?domain=admin.ads.shopee.io
- 然后在 `src/_shared/constant/api.ts` 中使用 `/api/v2/<path>` 前缀添加接口常量。
- 参考 MTS 集成指南：[Confluence — MTS Portal Integration](https://confluence.shopee.io/display/SPAD/%5BPaid+Ads+-+WebFE%5D+MTS+Portal+integration)

**从 proto 文件生成 TypeScript 类型：**

```sh
# Mac M1 / Apple Silicon
yarn run protoc [proto_file_path]

# 非 M1 / amd64
yarn run protoc2 [proto_file_path]
```

若预编译的 protoc 二进制文件无法运行，请通过 Homebrew 全局安装：

```sh
brew install protobuf
```

**提交信息格式：**

```
{type}[SPPA-xxxx]: {description}
```

合法类型：`chore`、`docs`、`feat`、`fix`、`refactor`、`style`。除 `chore` 类型外，JIRA 工单号为必填项。

示例：

```
feat[SPPA-1234]: add GMS Ads Creation Tool diagnosis tab
chore: update antd to 5.15.3
```

### 部署

前端静态资源通过 Space CMDB 部署（详见[部署说明](#部署说明)）。本地无部署步骤——`yarn build` 生成 `dist/` 目录，由 CI 负责上传。

---

## API 文档

所有 API 接口定义于 `src/_shared/constant/api.ts`。以 `/api/v2/` 为前缀的接口通过 MTS-ECP 路由；以 `/bff/` 为前缀的接口仍通过遗留 BFF 代理。

| 页面                     | 页面路径                                               | API 接口                                                                        | 描述                                |
| ------------------------ | ------------------------------------------------------ | ------------------------------------------------------------------------------- | ----------------------------------- |
| 鉴权                     | `/login-callback`                                      | `/api/v1/auth/info`                                                             | 获取用户登录信息                    |
| 鉴权                     | `/login-callback`                                      | `/api/v1/auth/logout`                                                           | 用户登出                            |
| 账户设置                 | `/accountSettings`                                     | `/api/v2/account_settings/operation_log`                                        | 账户设置操作日志                    |
| 账户设置                 | `/accountSettings`                                     | `/api/v2/account_setting_task_create`                                           | 创建账户设置任务                    |
| 账户设置                 | `/accountSettings`                                     | `/api/v2/account_setting_task_list`                                             | 账户设置任务列表                    |
| 账户设置                 | `/accountSettings`                                     | `/api/v2/account_setting_task_download`                                         | 下载账户设置任务                    |
| 账户设置                 | `/accountSettingsOverview`                             | `/api/v2/account_setting_overview`                                              | 账户设置总览                        |
| 余额日志                 | `/balanceLog`                                          | `/api/v2/balance/get_balance_log`                                               | 获取余额日志                        |
| Banner 广告              | `/bannerAds/*`                                         | `/api/v2/banner/get_shop_reserved_keyword`                                      | 获取店铺预留关键词                  |
| Banner 广告              | `/bannerAds/setUp`                                     | `/api/v2/banner/create_banner`                                                  | 创建 Banner 广告活动                |
| Banner 广告              | `/bannerAds/overview`                                  | `/api/v2/banner/list_banner_campaigns`                                          | 获取 Banner 广告活动列表            |
| Banner 广告              | `/bannerAds/overview`                                  | `/api/v2/banner/get_banners`                                                    | 获取 Banner 广告                    |
| Banner 广告              | `/bannerAds/overview`                                  | `/api/v2/banner/brand_ads_get_detail`                                           | 获取品牌广告详情                    |
| Banner 广告              | `/bannerAds/report`                                    | `/api/v2/banner/reporting`                                                      | 品牌广告报表                        |
| Banner 广告              | `/bannerAds/operationLog`                              | `/api/v2/banner/operation_log`                                                  | Banner 广告操作日志                 |
| Banner 广告              | `/bannerAds/*`                                         | `/api/v2/banner/update_banners`                                                 | 更新 Banner 广告                    |
| Banner 广告              | `/bannerAds/*`                                         | `/api/v2/banner/update_campaign_status`                                         | 更新活动状态                        |
| Banner 广告              | `/bannerAds/packageManagement`                         | `/api/v2/banner/list_search_brand_package`                                      | 搜索品牌套餐列表                    |
| Banner 广告              | `/bannerAds/packageManagement`                         | `/api/v2/banner/batch_upload_search_brand_package`                              | 批量上传搜索品牌套餐                |
| Banner 广告              | `/bannerAds/packageManagement/changeLog`               | `/api/v2/banner/list_search_brand_package_changelog`                            | 套餐管理变更日志                    |
| Banner 广告              | `/bannerAds/packageManagement`                         | `/api/v2/banner/remove_brand_pkg_period`                                        | 移除品牌套餐周期                    |
| Banner 广告              | `/bannerAds/keywordNomination`                         | `/api/v2/banner/list_grouped_keyword`                                           | 分组关键词列表                      |
| Banner 广告              | `/bannerAds/keywordNomination/changelog`               | `/api/v2/banner/list_brand_keyword_change_log`                                  | Banner 广告关键词变更日志           |
| Banner 广告              | `/bannerAds/keywordNomination`                         | `/api/v2/banner/batch_upload_brand_keyword`                                     | 批量上传品牌关键词                  |
| Banner 广告              | `/bannerAds/keywordNomination`                         | `/api/v2/banner/remove_brand_keyword`                                           | 移除品牌关键词                      |
| Banner 广告              | `/bannerAds/creativeReview`                            | `/api/v2/banner/brand_ads_list_creatives`                                       | 品牌创意资产列表                    |
| Banner 广告              | `/bannerAds/creativeReview`                            | `/api/v2/banner/update_creative_status`                                         | 更新品牌创意状态                    |
| Banner 广告              | `/bannerAds/*`                                         | `/api/v2/brand/ads_get_fe_configs`                                              | 获取品牌广告前端配置                |
| Banner 广告              | `/bannerAds/creativeReview/detail`                     | `/api/v2/brand/brand_ads_get_creative_detail`                                   | 获取品牌广告创意详情                |
| 基准测试                 | `/benchmark/review`                                    | `/api/v2/bad_case/bad_case_search`                                              | Bad Case 搜索                       |
| 基准测试                 | `/benchmark/review`                                    | `/api/v2/bad_case/update_bad_case`                                              | 更新 Bad Case                       |
| 广告黑名单               | `/blacklist`                                           | `/api/v2/search/blacklist`                                                      | 获取广告黑名单                      |
| 广告黑名单               | `/blacklist`                                           | `/api/v2/update/blacklist`                                                      | 更新广告黑名单                      |
| 广告黑名单               | `/blacklist/operationLog`                              | `/api/v2/blacklist_log_search/blacklist`                                        | 黑名单操作日志搜索                  |
| 黑名单关键词（遗留 BFF） | `/blacklistkeyword`                                    | `/bff/blacklistKeywords/get_blacklist_keyword`                                  | 获取黑名单关键词                    |
| 黑名单关键词（遗留 BFF） | `/blacklistkeyword`                                    | `/bff/blacklistKeywords/add_blacklist_keyword`                                  | 添加黑名单关键词                    |
| 黑名单关键词（遗留 BFF） | `/blacklistkeyword`                                    | `/bff/blacklistKeywords/update_blacklist_keyword`                               | 更新黑名单关键词                    |
| Boost 广告（遗留 BFF）   | `/boostAds/variableSetting`                            | `/bff/get_item_boost_variable_settings`                                         | 获取 Boost 变量设置                 |
| Boost 广告（遗留 BFF）   | `/boostAds/variableSetting`                            | `/bff/add_item_boost_variable_setting`                                          | 添加 Boost 变量设置                 |
| 品牌广告                 | `/brandConsiderationAds/operation`                     | `/api/v2/brand_consideration_ads/operation_log`                                 | 品牌广告操作日志                    |
| 品牌广告                 | `/brandConsiderationAds/report`                        | `/api/v2/brand_consideration_ads/report`                                        | 品牌广告报表                        |
| 品牌广告                 | `/brandConsiderationAds/overview`                      | `/api/v2/brand_consideration_ads/overview`                                      | 品牌广告总览                        |
| 品牌广告                 | `/brandConsiderationAds/overview`                      | `/api/v2/brand_consideration_ads/update_status`                                 | 更新品牌广告状态                    |
| 品牌广告                 | `/brandConsiderationAds/overview/detail`               | `/api/v2/brand_consideration_ads/get_detail`                                    | 获取品牌广告详情                    |
| 品牌广告                 | `/brandConsiderationAds/deductionLog`                  | `/api/v2/brand_consideration_ads/deduction_log`                                 | 品牌广告扣费日志                    |
| 品牌广告                 | `/brandConsiderationAds/inventoryAllocation`           | `/api/v2/brand_consideration_ads/brand_consideration_list_inventory`            | 库存列表                            |
| 品牌广告                 | `/brandConsiderationAds/inventoryAllocation/changeLog` | `/api/v2/brand_consideration_ads/brand_consideration_list_inventory_change_log` | 库存变更日志                        |
| 品牌广告                 | `/brandConsiderationAds/inventoryAllocation`           | `/api/v2/brand_consideration_ads/brand_consideration_batch_edit_inventory`      | 批量编辑库存分配                    |
| 品牌广告                 | `/brandConsiderationAds/creativeReview`                | `/api/v2/brand_consideration_ads/list_creatives`                                | 品牌广告创意列表                    |
| 品牌广告                 | `/brandConsiderationAds/creativeReview/detail`         | `/api/v2/brand_consideration_ads/creative_detail`                               | 品牌广告创意详情                    |
| 品牌广告                 | `/brandConsiderationAds/creativeReview`                | `/api/v2/brand_consideration_ads/creative_qc`                                   | 创意 QC/审批                        |
| 品牌广告                 | `/brandConsiderationAds/*`                             | `/api/v2/brand_consideration_ads/brand_consideration_get_config`                | 获取品牌广告配置                    |
| Cron Job 同步            | `/cronJobSync`                                         | `/api/v2/cron_job_sync/get`                                                     | 获取 Cron Job 同步状态              |
| Cron Job 同步            | `/cronJobSync`                                         | `/api/v2/cron_job_sync/get_rebate`                                              | 获取返利 Cron Job 同步状态          |
| Cron Job 同步            | `/cronJobSync`                                         | `/api/v2/cron_job_sync/trigger`                                                 | 触发 Cron Job 同步                  |
| Cron Job 同步            | `/cronJobSync`                                         | `/api/v2/cron_job_sync/trigger_rebate`                                          | 触发返利 Cron Job 同步              |
| DB 查看器                | `/dbViewer`                                            | `/api/v2/db_viewer/get_database_viewer_metadata`                                | 获取 DB 查看器元数据                |
| DB 查看器                | `/dbViewer`                                            | `/api/v2/db_viewer/database_viewer`                                             | DB 查看器查询                       |
| 展示广告                 | `/displayAds/*`                                        | `/api/v2/display_ads/get_admin_toggles`                                         | 获取管理员功能开关                  |
| 展示广告                 | `/displayAds/*`                                        | `/api/v2/display_ads/list_audience_group`                                       | 受众分组列表                        |
| 展示广告                 | `/displayAds/inventoryManagement`                      | `/api/v2/display_ads/get_inventory_info`                                        | 获取库存信息                        |
| 展示广告                 | `/displayAds/inventoryManagement`                      | `/api/v2/display_ads/get_display_ads_list_by_date`                              | 按日期获取展示广告列表              |
| 展示广告                 | `/displayAds/inventoryManagement/cpmPricing`           | `/api/v2/display_ads/get_cpm_pricing_list`                                      | 获取 CPM 定价列表                   |
| 展示广告                 | `/displayAds/inventoryManagement`                      | `/api/v2/display_ads/get_block_shop_list_by_date`                               | 按日期获取屏蔽店铺列表              |
| 展示广告                 | `/displayAds/inventoryManagement`                      | `/api/v2/display_ads/block_shop`                                                | 屏蔽店铺                            |
| 展示广告                 | `/displayAds/inventoryManagement`                      | `/api/v2/display_ads/un_block_shop`                                             | 取消屏蔽店铺                        |
| 展示广告                 | `/displayAds/inventoryManagement/cpmPricing`           | `/api/v2/display_ads/upload_cpm_pricing`                                        | 上传 CPM 定价                       |
| 展示广告                 | `/displayAds/*`                                        | `/api/v2/display_ads/get_reason_list_with_prefix`                               | 获取原因列表                        |
| 展示广告                 | `/displayAds/creativeReview`                           | `/api/v2/display_ads/get_creative_list`                                         | 获取创意列表                        |
| 展示广告                 | `/displayAds/creativeReview/detail`                    | `/api/v2/display_ads/get_creative_detail_by_id`                                 | 按 ID 获取创意详情                  |
| 展示广告                 | `/displayAds/creativeReview`                           | `/api/v2/display_ads/approve_creative`                                          | 审批创意                            |
| 展示广告                 | `/displayAds/billingAndPayment`                        | `/api/v2/display_ads/get_billings`                                              | 获取账单                            |
| 展示广告                 | `/displayAds/billingAndPayment`                        | `/api/v2/display_ads/export_ready_for_invoice_billings`                         | 导出待开票账单                      |
| 展示广告                 | `/displayAds/billingAndPayment`                        | `/api/v2/display_ads/update_payment`                                            | 更新支付状态                        |
| 展示广告                 | `/displayAds/billingAndPayment`                        | `/api/v2/display_ads/get_ready_for_invoice_billing_count`                       | 获取待开票账单数量                  |
| 展示广告                 | `/displayAds/whitelist`                                | `/api/v2/display_ads/get_whitelist_shops`                                       | 获取白名单店铺                      |
| 展示广告                 | `/displayAds/whitelist`                                | `/api/v2/display_ads/add_whitelist_shops`                                       | 添加白名单店铺                      |
| 展示广告                 | `/displayAds/whitelist`                                | `/api/v2/display_ads/remove_whitelist_shops`                                    | 移除白名单店铺                      |
| 展示广告                 | `/displayAds/whitelist`                                | `/api/v2/display_ads/get_affect_ads_list_by_un_whitelist`                       | 获取受白名单移除影响的广告列表      |
| 展示广告                 | `/displayAds/inventoryManagement/cpmPricing`           | `/api/v2/display_ads/get_upload_cpm_reminder`                                   | 获取 CPM 上传提醒                   |
| 展示广告                 | `/displayAds/adsManagement`                            | `/api/v2/display_ads/get_display_ads_list`                                      | 获取展示广告列表                    |
| 展示广告                 | `/displayAds/adsManagement`                            | `/api/v2/display_ads/get_shop_name`                                             | 获取店铺名称                        |
| 展示广告                 | `/displayAds/adsManagement`                            | `/api/v2/display_ads/get_display_ads_detail`                                    | 获取展示广告详情                    |
| 展示广告                 | `/displayAds/adsManagement/updateCreative`             | `/api/v2/display_ads/upload_display_ads_creative`                               | 上传展示广告创意                    |
| 展示广告                 | `/displayAds/adsManagement`                            | `/api/v2/display_ads/get_display_ads_calendar_info`                             | 获取展示广告日历信息                |
| 展示广告                 | `/displayAds/adsManagement/create`                     | `/api/v2/display_ads/create_display_ads`                                        | 创建展示广告                        |
| 展示广告                 | `/displayAds/adsManagement/edit`                       | `/api/v2/display_ads/edit_display_ads`                                          | 编辑展示广告                        |
| 展示广告                 | `/displayAds/adsManagement`                            | `/api/v2/display_ads/set_display_ads_status`                                    | 设置展示广告状态                    |
| 展示广告                 | `/displayAds/adsManagement`                            | `/api/v2/display_ads/get_display_ads_cpm_info`                                  | 获取展示广告 CPM 信息               |
| 展示广告                 | `/displayAds/billingInfo`                              | `/api/v2/display_ads/upload_display_shop_billing_info`                          | 上传展示广告账单信息                |
| 展示广告                 | `/displayAds/adsManagement`                            | `/api/v2/display_ads/get_display_ads_company_profiles`                          | 获取公司档案                        |
| 展示广告                 | `/displayAds/adsManagement`                            | `/api/v2/display_ads/get_display_ads_config`                                    | 获取展示广告配置                    |
| 展示广告                 | `/displayAds/inventoryManagement`                      | `/api/v2/display_ads/get_display_ads_premium_rate`                              | 获取溢价比率                        |
| 展示广告                 | `/displayAds/inventoryManagement`                      | `/api/v2/display_ads/set_display_ads_premium_rate`                              | 设置溢价比率                        |
| 展示广告                 | `/displayAds/inventoryManagement`                      | `/api/v2/display_ads/get_display_ads_premium_rate_audits`                       | 获取溢价比率审计                    |
| 展示广告余额             | `/displayAds/creditBalancelog`                         | `/api/v2/display_credit/display_ads_balance_log_overview`                       | 展示广告余额日志总览                |
| 展示广告余额             | `/displayAds/creditBalancelog/detail`                  | `/api/v2/display_credit/display_ads_balance_log_shop_detail`                    | 展示广告余额日志店铺详情            |
| 展示广告（遗留 BFF）     | `/displayAds/adsManagement`                            | `/bff/displayAds/upload_creative_image`                                         | 上传创意图片（遗留 BFF，multipart） |
| 欺诈工具（遗留 BFF）     | `/fraudTool`                                           | `/bff/fraudTool/get_fraud_reasons`                                              | 获取欺诈原因                        |
| 欺诈工具（遗留 BFF）     | `/fraudTool`                                           | `/bff/fraudTool/get_fraud_users`                                                | 获取欺诈用户                        |
| 欺诈工具（遗留 BFF）     | `/fraudTool`                                           | `/bff/fraudTool/add_fraud_users`                                                | 添加欺诈用户                        |
| 欺诈工具（遗留 BFF）     | `/fraudTool`                                           | `/bff/fraudTool/delete_fraud_users`                                             | 删除欺诈用户                        |
| 直播广告                 | `/live`                                                | `/api/v2/live_ads/overview`                                                     | 直播广告总览列表                    |
| 直播广告                 | `/live/detail`                                         | `/api/v2/live_ads/overview_detail`                                              | 直播广告总览详情                    |
| 直播广告                 | `/live/reporting`                                      | `/api/v2/live_ads/reporting`                                                    | 直播广告报表                        |
| 直播广告                 | `/live/reporting/detail`                               | `/api/v2/live_ads/reporting_detail`                                             | 直播广告报表详情                    |
| 直播广告                 | `/live/operationLog`                                   | `/api/v2/live_ads/operation_log`                                                | 直播广告操作日志                    |
| 直播广告                 | `/live/deductionLog`                                   | `/api/v2/live_ads/deduction_log`                                                | 直播广告扣费日志                    |
| 线上测试工具             | `/liveTestingTool/flagTabReset`                        | `/api/v2/flag/list_allowed`                                                     | 获取允许的 Flag 列表                |
| 线上测试工具             | `/liveTestingTool/flagTabReset`                        | `/api/v2/flag/list_overview`                                                    | Flag 总览列表                       |
| 线上测试工具             | `/liveTestingTool/flagTabReset`                        | `/api/v2/flag/update_flag`                                                      | 更新 Flag                           |
| 手动广告余额             | `/manualAdsCredit/topup`                               | `/api/v2/top_up/set_manual_topup`                                               | 手动充值                            |
| 手动广告余额             | `/manualAdsCredit/subtype`                             | `/api/v2/top_up/get_ads_credit_subtypes`                                        | 获取广告余额子类型                  |
| 手动广告余额             | `/manualAdsCredit/subtype`                             | `/api/v2/top_up/set_ads_credit_subtypes`                                        | 设置广告余额子类型                  |
| 手动广告余额             | `/manualAdsCredit/topup`                               | `/api/v2/top_up/set_display_manual_topup`                                       | 设置展示广告手动充值                |
| 手动广告余额             | `/manualAdsCredit/overview`                            | `/api/v2/top_up/get_manual_topup_summary`                                       | 获取手动充值汇总                    |
| 手动广告余额             | `/manualAdsCredit/overview`                            | `/api/v2/top_up/batch_update_manual_topup`                                      | 批量更新手动充值状态                |
| 手动广告余额             | `/manualAdsCredit/topup`                               | `/api/v2/top_up/get_soup_permission_list`                                       | 获取审批人列表                      |
| 手动广告余额             | `/manualAdsCredit/topup`                               | `/api/v2/top_up/get_manual_topup_config`                                        | 获取手动充值配置                    |
| 手动广告余额             | `/manualAdsCredit/history`                             | `/api/v2/top_up/upload_file`                                                    | 上传批量充值文件                    |
| 手动广告余额             | `/manualAdsCredit/history`                             | `/api/v2/top_up/async_batch_set_manual_topup`                                   | 异步批量手动充值                    |
| 手动广告余额             | `/manualAdsCredit/history`                             | `/api/v2/top_up/batch_upload_log`                                               | 批量上传日志                        |
| 手动广告余额             | `/manualAdsCredit/history`                             | `/api/v2/top_up/batch_action_log`                                               | 批量操作日志                        |
| 手动广告余额             | `/manualAdsCredit/history`                             | `/api/v2/top_up/async_batch_update_manual_topup`                                | 异步批量更新手动充值                |
| 手动广告余额             | `/manualAdsCredit/deduction`                           | `/api/v2/deduct/get_credit_summary`                                             | 获取余额汇总                        |
| 手动广告余额             | `/manualAdsCredit/deduction`                           | `/api/v2/deduct/set_manual_deduct`                                              | 手动扣款                            |
| 手动广告余额             | `/manualAdsCredit/deduction`                           | `/api/v2/deduct/async_batch_set_manual_deduct`                                  | 异步批量手动扣款                    |
| 手动广告余额             | `/manualAdsCredit/transfer`                            | `/api/v2/transfer/async_batch_set_manual_transfer`                              | 异步批量手动转账                    |
| 商品广告                 | `/usfkeyword`                                          | `/api/v2/product_ads/overview`                                                  | 商品广告总览                        |
| 商品广告                 | `/usfkeyword/overview/detail`                          | `/api/v2/product_ads/reporting_detail`                                          | 商品广告报表详情                    |
| 商品广告                 | `/usfkeyword/reporting`                                | `/api/v2/product_ads/reporting`                                                 | 商品广告报表                        |
| 商品广告                 | `/usfkeyword/operationLog`                             | `/api/v2/product_ads/operation_log`                                             | 商品广告操作日志                    |
| 商品广告                 | `/usfkeyword/deductionLog`                             | `/api/v2/product_ads/deduction_log`                                             | 商品广告扣费日志                    |
| 商品广告                 | `/usfkeyword/diagnosis`                                | `/api/v2/product_ads/diagnosis_list`                                            | 商品广告诊断列表                    |
| 商品广告（GMS）          | `/usfkeyword/gmsAdsCreationTool`                       | `/api/v2/product_ads/list_system_gms_shop`                                      | GMS 店铺列表                        |
| 商品广告（GMS）          | `/usfkeyword/gmsAdsCreationTool`                       | `/api/v2/product_ads/add_system_gms_shop`                                       | 添加 GMS 店铺                       |
| 商品广告（GMS）          | `/usfkeyword/gmsAdsCreationTool`                       | `/api/v2/product_ads/batch_pause_system_gms`                                    | 批量暂停 GMS                        |
| 商品广告（GMS）          | `/usfkeyword/gmsAdsCreationTool`                       | `/api/v2/product_ads/pause_system_gms`                                          | 暂停 GMS                            |
| 商品广告（GMS）          | `/usfkeyword/gmsAdsCreationTool`                       | `/api/v2/product_ads/resume_system_gms`                                         | 恢复 GMS                            |
| 重建索引                 | `/reindex`                                             | `/api/v2/reindex/reindex_ads`                                                   | 重建广告索引                        |
| 重建索引                 | `/reindex`                                             | `/api/v2/reindex/get_reindex_ads_audit`                                         | 获取重建索引审计                    |
| 重建索引                 | `/reindex`                                             | `/api/v2/reindex/get_reindex_ads_mass_upload_audit`                             | 获取批量上传审计                    |
| 店铺广告                 | `/usfshop`                                             | `/api/v2/shop_ads/overview`                                                     | 店铺广告总览                        |
| 店铺广告                 | `/usfshop/reporting`                                   | `/api/v2/shop_ads/reporting`                                                    | 店铺广告报表                        |
| 店铺广告                 | `/usfshop/reporting/detail`                            | `/api/v2/shop_ads/reporting_detail`                                             | 店铺广告报表详情                    |
| 店铺广告                 | `/usfshop/operationLog`                                | `/api/v2/shop_ads/operation_log`                                                | 店铺广告操作日志                    |
| 店铺广告                 | `/usfshop/deductionLog`                                | `/api/v2/shop_ads/deduction_log`                                                | 店铺广告扣费日志                    |
| 店铺广告关键词白名单     | `/usfshop/keywordsWhitelist`                           | `/api/v2/reserved_keyword_whitelist/get_keywords`                               | 获取预留关键词白名单                |
| 店铺广告关键词白名单     | `/usfshop/keywordsWhitelist`                           | `/api/v2/reserved_keyword_whitelist/get_audits`                                 | 获取关键词白名单审计                |
| 店铺广告关键词白名单     | `/usfshop/keywordsWhitelist`                           | `/api/v2/reserved_keyword_whitelist/set_keywords`                               | 设置预留关键词（需写权限）          |
| 用户白名单               | `/whitelist`                                           | `/api/v2/whitelist/get_whitelist_users`                                         | 获取白名单用户                      |
| 用户白名单               | `/whitelist`                                           | `/api/v2/whitelist/add_whitelist_users`                                         | 添加白名单用户                      |
| 用户白名单               | `/whitelist`                                           | `/api/v2/whitelist/poll_add_whitelist_user`                                     | 轮询白名单添加状态                  |
| 用户白名单（遗留 BFF）   | `/whitelist`                                           | `/bff/whitelist/delete_whitelist_users`                                         | 删除白名单用户                      |
| 用户白名单（遗留 BFF）   | `/whitelist`                                           | `/bff/whitelist/get_whitelist_type`                                             | 获取白名单类型                      |
| 用户白名单（遗留 BFF）   | `/whitelist`                                           | `/bff/soup/get_users_by_name`                                                   | 按姓名获取用户（Banner 广告）       |
| 视频广告                 | `/video`                                               | `/api/v2/video_ads/overview`                                                    | 视频广告总览                        |
| 视频广告                 | `/video/reporting`                                     | `/api/v2/video_ads/reporting`                                                   | 视频广告报表                        |
| 视频广告                 | `/video/operationLog`                                  | `/api/v2/video_ads/operation_log`                                               | 视频广告操作日志                    |
| 视频广告                 | `/video/deductionLog`                                  | `/api/v2/video_ads/deduction_log`                                               | 视频广告扣费日志                    |
| 可视化工具（遗留 BFF）   | `/visualiser`                                          | `bff/api/v1/get_entity_infos`                                                   | 获取广告实体信息                    |

> **注意：** 标注"遗留 BFF"的接口仍通过已废弃的 BFF 代理。所有新接口必须使用 MTS-ECP 注册并采用 `/api/v2/` 前缀。`/api/v1/auth/*` 接口使用 MTS 鉴权，非 BFF。

---

## 部署说明

### 前端静态资源（Space CMDB）

前端静态资源通过 Space CMDB 部署：

- **线上环境：** https://space.shopee.io/console/cmdb/deployment/detail/shopee.mp_search_recommendation_ads.paidads.advertiser_platform.webfe.paid_ads_admin.static

构建命令：`yarn build`

部署后的访问地址：

| 环境 | 地址                              |
| ---- | --------------------------------- |
| 线上 | https://admin.ads.shopee.io/      |
| 测试 | https://admin.ads.test.shopee.io/ |
| UAT  | https://admin.ads.uat.shopee.io/  |

CI/CD 通过 Jenkins 管理：

| 环境     | Jenkins                                                  |
| -------- | -------------------------------------------------------- |
| 线上     | https://jenkins.shopeemobile.com/view/paidadsadmin/      |
| 测试/UAT | https://jenkins.test.shopeemobile.com/view/paidadsadmin/ |

### BFF（已废弃）

遗留 BFF（paid_ads_admin_bff，NestJS）**已不再维护**，仅供历史参考。

- Space CMDB（遗留）：https://space.shopee.io/console/cmdb/deployment/detail/shopee.mp_search_recommendation_ads.paidads.advertiser_platform.webfe.paid_ads_admin.node
- GitLab 仓库（历史参考）：https://git.garena.com/shopee/isfe/ao/paid_ads_admin_bff

新接口**不得**使用 BFF，应在 MTS-ECP 注册并采用 `/api/v2/` 前缀。

---

## 业务术语表

| 术语      | 全称                           | 定义                                                      |
| --------- | ------------------------------ | --------------------------------------------------------- |
| Ads GMV   | Ads Gross Merchandise Value    | 广告带来的成交总额（通常为广告点击后 7 天内的归因成交额） |
| Take-Rate | —                              | 广告收入 / 平台 GMV；衡量 Shopee 广告变现效率             |
| CIR       | Cost-Income-Ratio              | 广告收入 / 广告 GMV                                       |
| ROI       | Return on Investment           | 广告 GMV / 广告收入（CIR 的倒数）；亦称 ROAS              |
| CPC       | Cost Per Click                 | 每次点击花费                                              |
| CPM       | Cost Per Mille                 | 每千次展示费用                                            |
| eCPM      | Effective Cost per Mille       | 广告总花费 / 总展示次数                                   |
| CTR       | Click-Through Rate             | 点击次数 / 展示次数                                       |
| CR        | Conversion Rate                | 广告订单数 / 点击次数                                     |
| Advv      | Advertiser Value               | 广告主价值，平台长期收入增长衡量指标                      |
| TADS      | Targeting Ads                  | 定向广告（与 DADS 同义）                                  |
| oCPC      | Simple Mode                    | 卖家关键词自动优化（优化每次点击成本）                    |
| QSS       | QuickStart Service             | 帮助新广告主快速起量的服务                                |
| SRM       | Seller Relationship Management | 卖家关系管理：卖家数据分析与分层                          |
| 手动充值  | Manual Top-up                  | CB 卖家广告余额充值，需管理员手动审核                     |
| 自动充值  | Auto Top-up                    | 本地卖家广告余额自动充值                                  |
| SVS 充值  | SVS Top-up                     | CB 卖家通过 SVS PDP 页面充值                              |
| 白名单    | Whitelist                      | 已开通特殊功能权限的卖家（如目标 ROI、自定义店铺广告等）  |
| 黑名单    | Blacklist                      | 被屏蔽的关键词或商品 ID                                   |
| BFF       | Backend For Frontend           | 遗留 NestJS 代理层（已废弃，由 MTS-ECP 取代）             |
| MTS       | —                              | Shopee 内部 API 网关/接口配置平台                         |
| SOUP      | —                              | Shopee 内部权限系统，提供基于角色的访问控制               |
| CMDB      | —                              | 配置管理数据库；Space CMDB 管理服务部署                   |

---

## 参考资料

- **GitLab 仓库：** https://git.garena.com/shopee/isfe/ao/paid_ads_admin
- **MTS-ECP 接口管理（非线上）：** https://space.shopee.io/mts/ecpnonlive/domain-listing/endpoint-listing?domain=admin.ads.shopee.io
- **MTS-ECP 接口管理（线上）：** https://space.shopee.io/mts/ecplive/domain-listing/endpoint-listing?domain=admin.ads.shopee.io
- **MTS Portal 集成指南（Confluence）：** https://confluence.shopee.io/display/SPAD/%5BPaid+Ads+-+WebFE%5D+MTS+Portal+integration
- **Space CMDB — 前端静态资源部署：** https://space.shopee.io/console/cmdb/deployment/detail/shopee.mp_search_recommendation_ads.paidads.advertiser_platform.webfe.paid_ads_admin.static
- **Space CMDB — BFF（已废弃）：** https://space.shopee.io/console/cmdb/deployment/detail/shopee.mp_search_recommendation_ads.paidads.advertiser_platform.webfe.paid_ads_admin.node
- **BFF 仓库（仅历史参考）：** https://git.garena.com/shopee/isfe/ao/paid_ads_admin_bff
- **Paid Ads Glossary（Confluence）：** https://confluence.shopee.io/pages/viewpage.action?spaceKey=SPAD&title=Paid+Ads+Glossary
- **Jenkins — 线上：** https://jenkins.shopeemobile.com/view/paidadsadmin/
- **Jenkins — 测试/UAT：** https://jenkins.test.shopeemobile.com/view/paidadsadmin/
- **React：** https://reactjs.org/
- **Vite：** https://vitejs.dev/
- **Ant Design：** https://ant.design/
- **TypeScript：** https://www.typescriptlang.org/

---

## 常见问题

**1. 如何在本地运行后台？**

安装 Node.js ≥ 16 和 yarn，执行 `yarn install && yarn start`。开发服务器启动在 8888 端口。需要来自 admin.ads.test.shopee.io 的有效浏览器 Cookie（SPC_ST、SPC_CDS 等）——先在该地址登录，再将 Cookie 复制到本地浏览器会话中。`/bff` 和 `/api` 的请求会自动代理到测试环境。

**2. 如何添加新页面/路由？**

1. 在 `src/_shared/config/routes.ts` 添加路由常量。
2. 在 `src/bundle.ts` 注册指向新页面组件的懒加载条目。
3. 在 `src/config.ts` 的 `sideNav` 中添加侧边栏导航项。
4. 在 `src/` 下功能目录中创建页面组件。

**3. 如何添加新的 API 接口？**

新接口不再使用 BFF。需先在 MTS-ECP（先非线上，后线上）注册接口，配置 SOUP 权限码和后端服务路由。完成后在 `src/_shared/constant/api.ts` 中使用 `/api/v2/<path>` 前缀添加常量。详细步骤参考 [MTS Portal 集成指南](https://confluence.shopee.io/display/SPAD/%5BPaid+Ads+-+WebFE%5D+MTS+Portal+integration)。

**4. SOUP 权限校验如何工作？**

区域代码（小写）以请求头 `X-Soup-Object-Code: <region>` 的形式发送。MTS-ECP 会针对每个接口的配置权限进行校验。如果校验失败，MTS 返回 403 响应，由前端统一处理。`/api/v2/` 接口无需 BFF 层的 SOUP 逻辑。

**5. 如何调试 MTS-ECP 接口路由问题？**

在请求 URL 中添加 `_show_debug_info=2` 参数（例如：`https://admin.ads.test.shopee.io/api/v2/cron_job_sync/get?_show_debug_info=2`）。响应中会包含 `jaeger_tracing_url`，可用于端到端追踪请求链路。

**6. 如何为本地开发添加新的代理路径前缀？**

更新 `package.json` 的 `kayaToast.proxyPath` 数组（例如：`["/bff", "/api", "/newprefix"]`）。`vite.config.ts` 已动态遍历该数组来配置 Vite 代理，无需额外修改。

**7. 如何从 .proto 文件生成 TypeScript 类型？**

使用 `yarn run protoc [proto_file_path]`（M1/Apple Silicon）或 `yarn run protoc2 [proto_file_path]`（非 M1）。若二进制文件无法运行，通过 `brew install protobuf` 全局安装 `protoc` 后重试 `protoc2`。

**8. 为什么部分接口仍使用 `/bff/` 前缀？**

这些接口尚未迁移到 MTS-ECP。迁移需要在 ECP 控制台注册接口并配置 SOUP 权限——参考 Confluence 指南。在完成迁移前，它们继续通过遗留 NestJS BFF 代理。

**9. 基于区域的路由如何工作？**

URL 的 `basename` 为 `/<region>`（如 `/sg`、`/id`）。启动时 `App.tsx` 会检查 URL 是否包含有效区域前缀；若无则重定向至 `/sg`。区域信息从 URL 路径读取（`src/_shared/utils/region.ts`）。不同区域的功能可用性不同——详见 `src/bundle.ts` 的 `bundlesFilter()` 和 `src/config.ts` 的 `siteConfigFilter()`。

**10. 如何提交 Merge Request？**

所有功能或 Bug 修复都需要同时向 `uat` 和 `master` 分支提交 MR。提交信息必须遵循格式 `{type}[SPPA-xxxx]: {description}`，commitlint hook 会在提交时自动校验。

<!-- Generated by ads-workspace/skills/ads-readme-generate | checked: 147a89af37a84b96263ea5d6eabafda1e8dd5948 | spec: 76fce5f679f9550b -->
