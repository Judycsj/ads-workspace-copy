<!-- ads-workspace-gdoc-sync: gdoc_id=1GqiKHevZRXlj7wJmZn5EqrDOHuqMjV1rDTYr3jIe8vk gdoc_url=https://docs.google.com/document/d/1GqiKHevZRXlj7wJmZn5EqrDOHuqMjV1rDTYr3jIe8vk/edit -->

# srdi_mart.ads_sr_data_warehouse_homepage_user_attribute_level_1d

**分层：** ADS（应用数据服务层）
**主键：** `grass_region` + `local_date` + `platform` + `item_click_level` + `dd_click_level` + `major_app_version` + `app_version`
**分区：** `grass_region`（站点区域）、`local_date`（业务日期）
**更新频率：** 每日（T+1）
**引用频次/访问频次：** 187

---

## 业务描述

本表是 Shopee 搜推数仓首页（Homepage）模块的 ADS 层日粒度用户属性分层宽表，面向业务分析师和报表系统提供"开箱即用"的聚合指标。

**核心业务场景：**
- 按用户属性分层（平台、App 版本、近 30 天商品点击活跃度、近 30 天 Daily Discover 点击活跃度）分析首页各模块的曝光、点击、购买转化和 GMV 表现。
- 支持 Daily Discover（DD）整体及其下各卡片类型（普通 Item Card、Mini Feed Card、Video Card、Live Card）的效果拆分，并区分自然流量（Organic）与广告流量（Ads）。
- 提供平台整体 DAU、首页 DAU、DD DAU 等用户规模基准指标，便于计算渗透率与转化率。

**适合回答的典型问题：**
- 不同活跃度分层用户在 Daily Discover 上的曝光 → 点击 → 购买漏斗各站点表现如何？
- 广告卡片与自然卡片在各 App 版本/平台的 GMV 贡献差异？
- Mini Feed Card / Video Card / Live Card 在不同用户分层中的渗透与转化情况？
- 首页 DAU 与平台 DAU 的比值（首页渗透率）随时间的变化趋势？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域，如 SG、MY、TH 等，用于物理分区过滤 |
| `local_date` | date | 业务日期（本地时区），用于物理分区过滤 |

### 维度：用户属性分层

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 客户端平台（如 iOS / Android），包含汇总值 `__ALL__` |
| `item_click_level` | string | 用户近 30 天商品点击活跃度分层：`0-5` / `6-39` / `40-149` / `150+`，包含汇总值 `__ALL__` |
| `dd_click_level` | string | 用户近 30 天 Daily Discover 点击活跃度分层：`0-2` / `3-7` / `8-23` / `24+`，包含汇总值 `__ALL__` |
| `major_app_version` | string | App 版本号前两段（如 `3.28`），包含汇总值 `__ALL__` |
| `app_version` | string | 完整 App 版本号，包含汇总值 `__ALL__` |

### 指标：平台整体基准

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform_dau` | bigint | 平台 DAU，与 Shopee 官方 DAU 口径对齐，基于 traffic view 和 auto_view 事件计算 |
| `platform_omni_imp_cnt` | bigint | 平台全站商品曝光总数 |
| `platform_ppv_cnt` | bigint | 平台 PPV（商品详情页浏览）总数 |
| `platform_order_cnt` | double | 平台订单数 |

### 指标：首页（Homepage）

| 字段 | 类型 | 说明 |
|---|---|---|
| `homepage_dau` | bigint | 首页 DAU（访问首页的去重用户数） |
| `homepage_stay_time` | bigint | 首页停留时长（单位：毫秒）；**DataMap 标注暂时不建议使用** |

### 指标：Daily Discover 整体

| 字段 | 类型 | 说明 |
|---|---|---|
| `dd_dau` | bigint | Daily Discover 曝光去重用户数（DAU 口径） |
| `dd_stay_time` | bigint | Daily Discover 停留时长（单位：毫秒） |
| `dd_card_imp_cnt` | bigint | DD 全部卡片入口曝光数 |
| `dd_card_click_cnt` | bigint | DD 全部卡片入口点击数 |
| `dd_card_omni_imp_cnt` | bigint | DD 卡片带来的全部商品曝光数（含入口 item + landing 页商品曝光） |
| `dd_card_omni_click_cnt` | bigint | DD 卡片带来的全部商品点击数（含入口 item + landing 页商品点击） |
| `dd_ppv_cnt` | bigint | DD 带来的商品详情页浏览数（PPV） |
| `dd_order_cnt` | double | DD 带来的订单数 |
| `dd_gmv` | double | DD 带来的 GMV |

### 指标：Daily Discover 自然流量（Organic）

| 字段 | 类型 | 说明 |
|---|---|---|
| `dd_organic_card_imp_cnt` | bigint | DD 自然卡片入口曝光数 |
| `dd_organic_card_click_cnt` | bigint | DD 自然卡片入口点击数 |
| `dd_organic_card_omni_imp_cnt` | bigint | DD 自然卡片带来的全部商品曝光数 |
| `dd_organic_card_omni_click_cnt` | bigint | DD 自然卡片带来的全部商品点击数 |
| `dd_organic_ppv_cnt` | bigint | DD 自然流量带来的 PPV |
| `dd_organic_order_cnt` | double | DD 自然流量带来的订单数 |
| `dd_organic_gmv` | double | DD 自然流量带来的 GMV |

### 指标：Daily Discover 广告流量（Ads）

| 字段 | 类型 | 说明 |
|---|---|---|
| `dd_ads_card_imp_cnt` | bigint | DD 广告卡片入口曝光数 |
| `dd_ads_card_click_cnt` | bigint | DD 广告卡片入口点击数 |
| `dd_ads_card_omni_imp_cnt` | bigint | DD 广告卡片带来的全部商品曝光数 |
| `dd_ads_card_omni_click_cnt` | bigint | DD 广告卡片带来的全部商品点击数 |
| `dd_ads_ppv_cnt` | bigint | DD 广告流量带来的 PPV |
| `dd_ads_order_cnt` | double | DD 广告流量带来的订单数 |
| `dd_ads_gmv` | double | DD 广告流量带来的 GMV |

### 指标：DD Item Card（商品卡片）

| 字段 | 类型 | 说明 |
|---|---|---|
| `dd_item_card_imp_cnt` | bigint | DD 商品卡片曝光数（omni 口径） |
| `dd_item_card_click_cnt` | bigint | DD 商品卡片点击数（omni 口径） |
| `dd_item_card_ppv_cnt` | bigint | DD 商品卡片带来的 PPV |
| `dd_item_card_order_cnt` | double | DD 商品卡片带来的订单数 |
| `dd_item_card_gmv` | double | DD 商品卡片带来的 GMV |
| `dd_organic_item_card_imp_cnt` | bigint | DD 自然商品卡片曝光数 |
| `dd_organic_item_card_click_cnt` | bigint | DD 自然商品卡片点击数 |
| `dd_organic_item_card_ppv_cnt` | bigint | DD 自然商品卡片带来的 PPV |
| `dd_organic_item_card_order_cnt` | double | DD 自然商品卡片带来的订单数 |
| `dd_organic_item_card_gmv` | double | DD 自然商品卡片带来的 GMV |
| `dd_ads_item_card_imp_cnt` | bigint | DD 广告商品卡片曝光数 |
| `dd_ads_item_card_click_cnt` | bigint | DD 广告商品卡片点击数 |
| `dd_ads_item_card_ppv_cnt` | bigint | DD 广告商品卡片带来的 PPV |
| `dd_ads_item_card_order_cnt` | double | DD 广告商品卡片带来的订单数 |
| `dd_ads_item_card_gmv` | double | DD 广告商品卡片带来的 GMV |

### 指标：DD Mini Feed Card（信息流卡片）

| 字段 | 类型 | 说明 |
|---|---|---|
| `dd_mini_feed_card_imp_cnt` | bigint | DD Mini Feed 卡片入口曝光数 |
| `dd_mini_feed_card_click_cnt` | bigint | DD Mini Feed 卡片入口点击数 |
| `dd_mini_feed_card_omni_imp_cnt` | bigint | DD Mini Feed 卡片带来的全部商品曝光数 |
| `dd_mini_feed_card_omni_click_cnt` | bigint | DD Mini Feed 卡片带来的全部商品点击数 |
| `dd_mini_feed_card_ppv_cnt` | bigint | DD Mini Feed 卡片带来的 PPV |
| `dd_mini_feed_card_order_cnt` | double | DD Mini Feed 卡片带来的订单数 |
| `dd_mini_feed_card_gmv` | double | DD Mini Feed 卡片带来的 GMV |

### 指标：DD Video Card（视频卡片）

| 字段 | 类型 | 说明 |
|---|---|---|
| `dd_video_card_imp_cnt` | bigint | DD 视频卡片入口曝光数 |
| `dd_video_card_click_cnt` | bigint | DD 视频卡片入口点击数 |
| `dd_video_card_omni_imp_cnt` | bigint | DD 视频卡片带来的全部商品曝光数 |
| `dd_video_card_omni_click_cnt` | bigint | DD 视频卡片带来的全部商品点击数 |
| `dd_video_card_ppv_cnt` | bigint | DD 视频卡片带来的 PPV |
| `dd_video_card_order_cnt` | double | DD 视频卡片带来的订单数 |
| `dd_video_card_gmv` | double | DD 视频卡片带来的 GMV |

### 指标：DD Live Card（直播卡片）

| 字段 | 类型 | 说明 |
|---|---|---|
| `dd_live_card_imp_cnt` | bigint | DD 直播卡片入口曝光数 |
| `dd_live_card_click_cnt` | bigint | DD 直播卡片入口点击数 |
| `dd_live_card_omni_imp_cnt` | bigint | DD 直播卡片带来的全部商品曝光数 |
| `dd_live_card_omni_click_cnt` | bigint | DD 直播卡片带来的全部商品点击数 |
| `dd_live_card_ppv_cnt` | bigint | DD 直播卡片带来的 PPV |
| `dd_live_card_order_cnt` | double | DD 直播卡片带来的订单数 |
| `dd_live_card_gmv` | double | DD 直播卡片带来的 GMV |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region` 和 `local_date` 两个分区字段**，否则将触发全表扫描，消耗极大计算资源并可能导致查询超时。

```sql
-- 正确示例
WHERE grass_region = 'SG'
  AND local_date = '2025-05-16'
```

### 维度组合与 `__ALL__` 汇总值

- `platform`、`item_click_level`、`dd_click_level`、`major_app_version`、`app_version` 均包含 `__ALL__` 汇总行，来自上游 DWS 层的预聚合结果。
- **跨维度查询时须明确指定所需粒度**，避免将明细行与 `__ALL__` 行混合 SUM，导致重复计数。例如，若需要全平台汇总，应过滤 `platform = '__ALL__'`，而不是对所有 `platform` 值求和。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `platform_dau`、`homepage_dau`、`dd_dau` | DAU 为去重用户数（UV），不同分层的 DAU 不可加总，存在用户重叠 |
| `homepage_stay_time` | DataMap 标注**暂时不建议使用**，数据质量存疑，请勿用于报表和分析 |
| 所有 `_gmv`、`_order_cnt` 字段 | 类型为 `double`，为预聚合值，跨维度叠加前需确认分层是否互斥 |

### 时效性说明

- 本表为 **T+1** 日粒度表，每天更新前一天的数据。
- 分区 `local_date` 使用**本地时区**日期，各站点时区不同，请注意与 UTC 时区数据源对齐时的时差问题。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `dws_sr_data_warehouse_platform_user_attribute_level_1d` | 提供平台整体 DAU、平台全站商品曝光数、PPV 及订单数等平台基准指标，按用户属性分层 |
| `dws_sr_data_warehouse_homepage_user_attribute_level_1d` | 提供首页及 Daily Discover 各模块（整体、Item Card、Mini Feed Card、Video Card、Live Card）的曝光、点击、PPV、订单、GMV 指标，同时区分 Organic 与 Ads 流量；`module` / `object` 字段用于切分不同卡片类型 |

---

## ETL 逻辑摘要

### 数据流

```
dws_sr_data_warehouse_platform_user_attribute_level_1d   ──┐
                                                            ├──► base_data (临时视图, UNION ALL 对齐宽表结构)
dws_sr_data_warehouse_homepage_user_attribute_level_1d   ──┘        │
  (module='__ALL__' / 'Daily Discover' × object 多切片)             │
                                                                     ▼
                                        ads_sr_data_warehouse_homepage_user_attribute_level_1d
                                        (GROUP BY 维度 + MAX 折叠 → INSERT OVERWRITE 目标分区)
```

### 关键步骤

1. **变量初始化（Statement 1–6）**
   定义多组"零值占位"SQL 片段（`platform_home_zreo_statement`、`dd_zero_statement`、`dd_item_card_zero_statement`、`dd_mini_feed_card_zero_statement`、`dd_video_card_zero_statement`、`dd_live_card_zero_statement`），用于在各数据源不涉及的指标列上填充 `0`，保证 UNION ALL 中列结构对齐。

2. **临时视图构建（Statement 7）：`base_data_${grass_region_without_quote}`**
   通过 8 路 `UNION ALL` 将不同数据源和不同 `module/object` 切片拼接为统一宽表结构：
   - **第 1 路**：来自平台 DWS 表，填充 `platform_dau`、`platform_omni_imp_cnt`、`platform_ppv_cnt`、`platform_order_cnt`，其余 DD 指标置 0。
   - **第 2 路**：来自首页 DWS 表（`module='__ALL__'`），填充 `homepage_dau`、`homepage_stay_time`，其余置 0。
   - **第 3 路**：来自首页 DWS 表（`module='Daily Discover'`，`object='__ALL__'`），填充 DD 整体及 Organic/Ads 汇总指标。
   - **第 4 路**：来自首页 DWS 表（`module='Daily Discover'`，`object='item card'`），填充 DD Item Card 指标。
   - **第 5 路**：来自首页 DWS 表（`module='Daily Discover'`，`object='mini_feed_item_card'`），填充 DD Mini Feed Card 指标。
   - **第 6 路**：来自首页 DWS 表（`module='Daily Discover'`，`object='video card'`），填充 DD Video Card 指标。
   - **第 7 路**：来自首页 DWS 表（`module='Daily Discover'`，`object='live card'`），填充 DD Live Card 指标。

3. **最终写入（Statement 8）**
   对 `base_data` 按 5 个维度字段（`platform`、`item_click_level`、`dd_click_level`、`major_app_version`、`app_version`）分组，对每个指标列取 `MAX`，将多路 UNION ALL 中同一维度组合下各路的非零值"折叠"到同一行，执行 `INSERT OVERWRITE` 写入目标分区。

### 注意事项

- **`MAX` 折叠语义**：ETL 使用 `MAX` 而非 `SUM` 进行聚合，原因是各路 UNION ALL 数据同一维度组合下仅有一路指标非零、其余路为 0，`MAX` 能准确取得唯一非零值。该设计依赖各数据路的指标互斥性，若上游数据出现同一维度组合在同一路中有多行，则 `MAX` 不等于 `SUM`，需关注上游数据质量。
- **单一 Writer**：`multi_writer = false`，本表仅由一个 ETL 文件写入，无并发写分区冲突风险。
- **`INSERT OVERWRITE` 分区覆盖**：每次运行对指定 `grass_region + local_date` 分区执行全量覆盖，重跑幂等。
- **`homepage_stay_time` 字段**：DataMap 注释明确标注"暂时不建议使用"，下游分析应回避该字段，直至数据质量问题修复。
- **参数化分区**：SQL 使用 `${grass_region}`、`${local_date}` 等运行时参数，同一脚本可复用于不同站点和日期的调度任务。

---

*文档生成时间：2026-05-17*