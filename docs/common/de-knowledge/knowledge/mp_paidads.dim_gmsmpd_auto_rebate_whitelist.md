<!-- ads-workspace-gdoc-sync: gdoc_id=17QdVvhULZW8imh2q3dGOMeO987NBhEes9Lb0pfONil4 gdoc_url=https://docs.google.com/document/d/17QdVvhULZW8imh2q3dGOMeO987NBhEes9Lb0pfONil4/edit -->

# mp_paidads.dim_gmsmpd_auto_rebate_whitelist

**分层：** DIM（维度层）
**主键：** `shop_id` + `type` + `grass_region` + `grass_date`
**分区：** `grass_region`（地区）、`grass_date`（日期）
**更新频率：** 每日调度，各地区按本地时区参数化调度
**引用频次：** 1 次（候选表范围内）

---

## 业务描述

本表是付费广告（Paid Ads）体系下的**自动返佣（Auto Rebate）与自动托管（Auto Escrow）白名单维度表**，记录各地区各店铺在不同功能维度上的白名单准入状态及最早生效日期。表中按 `type` 字段区分五类白名单类型，分别对应 GMS 自动返佣（`type=1`）、MPD 白名单（`type=2`）、含 Campaign Tag 的卖家（`type=3`）、自动托管功能（`type=4`）以及周返佣规则（`type=5`）。

该表的核心用途是在广告计费与返佣流程中快速判断某店铺是否具备特定功能的使用资格，并追踪其最早开白时间（`whitelist_date`）。下游系统可通过关联本表，结合 `feature_mode` 字段判断该店铺处于"全量开放"、"白名单"、"黑名单"还是"灰度"状态，从而实施差异化的返佣和托管策略。

本表每日全量刷新，并利用前两日快照（`PREV_2D`）进行"开白日期取历史最早值"的滚动合并，确保 `whitelist_date` 始终保留店铺首次进入白名单的日期，具备较强的历史追溯价值。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 地区标识，大写字母（如 `MY`、`TH`），各地区独立分区存储 |
| `grass_date` | date | 数据日期分区，对应调度执行日期 |

### 维度：主键与白名单属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺 ID，广告主的唯一标识 |
| `type` | int | 白名单类型：`1` = GMS 自动返佣白名单；`2` = MPD 白名单（全量广告主）；`3` = 含 Campaign Tag 的卖家白名单；`4` = 自动托管（Auto Escrow）白名单；`5` = 周返佣规则（Weekly Rebate Rules）白名单 ⚠️ 同一 `shop_id` 在同一分区内可存在多条不同 `type` 的记录，聚合时必须按 `type` 过滤，否则将重复计算店铺 |
| `whitelist_date` | date | 开白日期，即该店铺首次进入对应类型白名单的日期。ETL 逻辑采用 `LEAST(当日, 历史)` 或 `COALESCE(历史, 当日)` 取最早值滚动保留 ⚠️ 此字段为滚动历史最早值，不反映当日新增开白状态；如需判断"当日新增"，需与前日快照比对 |
| `feature_mode` | tinyint | 功能开关模式：`1` = ModeOpenToAll（全量开放）；`2` = ModeWhiteList（白名单模式）；`3` = ModeBlackList（黑名单模式）；`4` = ModeOpenToNone（全量关闭）；`5` = GrayScaleByShopId（按店铺灰度）。`type=3`（Campaign Tag）时该字段为 `NULL` ⚠️ 不同 `type` 下 `feature_mode` 含义相同但来源 feature_key 不同，跨 type 混合使用时需注意区分 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下分区字段**，避免全表扫描：

```sql
WHERE grass_region = '<REGION>'   -- 必须指定，大写地区代码，如 'MY'、'TH'
  AND grass_date   = '<DATE>'     -- 必须指定，对应业务日期
```

遗漏分区过滤将触发全分区扫描，扫描量成倍放大（地区数 × 日期范围），严重影响查询性能并产生额外计算费用。

此外，**几乎所有业务场景均需加 `type` 过滤**，例如：
- 查询 GMS 自动返佣白名单：`AND type = 1`
- 查询 MPD 白名单：`AND type = 2`
- 查询自动托管白名单：`AND type = 4`

### 不可直接 SUM 的字段

| 字段 | 问题原因 | 正确用法 |
|------|----------|----------|
| `whitelist_date` | 为滚动历史最早日期，不具备加和意义 | 使用 `MIN(whitelist_date)` 取最早值，或直接作为维度关联筛选 |
| `feature_mode` | 枚举编码，数值本身无加和意义 | 用 `WHERE feature_mode = <值>` 或 `COUNT(DISTINCT shop_id)` 进行聚合 |
| `type` | 枚举编码，同一店铺多条记录会导致重复计数 | 聚合前必须先按 `type` 过滤或在 `GROUP BY` 中包含 `type` |

### 时效性说明

- 本表每日全量刷新，**取最新 `grass_date` 分区**即可获得当日白名单快照。
- `whitelist_date` 字段通过与 `${PREV_2D}`（前两日）分区做 `COALESCE` / `LEAST` 合并，存在最多 **2 天的数据链路依赖延迟**。若当日调度失败或前两日数据缺失，`whitelist_date` 可能退化为当日日期而非历史最早值，需关注上游数据完整性。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dim_advertiser__reg_s0_live` | 获取全量有效广告主（`shop_id`），作为 MPD 白名单（type=2）、GMS 白名单 open-to-all/blacklist 判断及 escrow 资格过滤的基础集合 |
| `mp_paidads.dim_campaign__reg_s0_live` | 获取含 `campaign_tag=1` 的店铺，构建 Campaign Tag 白名单（type=3） |
| `mp_paidads.dim_gmsmpd_auto_rebate_whitelist__reg_s0_live`（自身前两日快照） | 读取 `grass_date = PREV_2D` 的历史白名单，用于滚动保留 `whitelist_date` 历史最早值 |
| `mp_paidads.dim_roi2_auto_rebate_blacklist__reg_s0_live` | ROI2 黑名单，用于从 GMS 白名单（type=1）中剔除黑名单店铺 |
| `marketplace.shopee_seller_feature_toggle_db__feature_toggle_info_tab__${region}_df` | 获取功能开关（feature_key）的状态及模式（`feature_mode`），覆盖 `product_ads_gms_auto_rebate`、`ads_atu_escrow`、`weekly_rebate_rules` 三个 key |
| `marketplace.shopee_seller_feature_toggle_db__feature_toggle_tag_mapping_tab__${region}_df` | 获取功能开关与 Tag 的映射关系，用于将功能开关与店铺关联 |
| `marketplace.shopee_seller_shop_tag_mapping_latam_${region}_db__shop_tag_mapping_tab__reg_continuous_s0_live` | 获取店铺与 Tag 的映射关系，用于识别处于白名单/黑名单/灰度 Tag 的店铺 |

---

## ETL 逻辑摘要

### 数据流

```
dim_advertiser__reg_s0_live ──────────────────────────────────────────────────────────┐
                                                                                       │
dim_campaign__reg_s0_live ─────────────────── [campaign_tag CTE] ─────────────────────┤
                                                                                       │
feature_toggle_info_tab                                                                │
        +                                                                              │
feature_toggle_tag_mapping_tab  ──── [toggle 三表关联] ──────────────────────────────── │
        +                                                                              │
shop_tag_mapping_tab                                                                   │
                                                                                       ▼
dim_roi2_auto_rebate_blacklist ────────────────────────── UNION ALL (5 个 type 分支) ──►
                                                                                       │
dim_gmsmpd_auto_rebate_whitelist (PREV_2D 自身快照) ──── whitelist_date 滚动合并       │
                                                                                       ▼
                             INSERT OVERWRITE dim_gmsmpd_auto_rebate_whitelist__reg_s0_live
                                        (PARTITION grass_region, grass_date)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `campaign_tag` | `mp_paidads.dim_campaign__reg_s0_live` | 筛选当日含 `campaign_tag=1`、`tz_type='local'` 的广告活动，按 `shop_id` + `grass_date` 去重，作为 type=3 白名单的店铺来源 |

### 注意事项

1. **UNION ALL 五分支结构**：INSERT 语句由 5 个 `UNION ALL` 分支组成，各分支分别对应 `type` 值 2、1、3、4、5，写入同一分区。查询时必须通过 `type` 过滤，否则同一 `shop_id` 最多返回 5 条记录。

2. **whitelist_date 滚动逻辑差异**：
   - `type=2`（MPD）：使用 `LEAST(当日, 历史)` 取两者最小值
   - `type=1/3/4/5`：使用 `COALESCE(历史, 当日)` 优先取历史值
   - 两种逻辑效果等价（均保留历史最早日期），但实现方式不同。

3. **自身依赖 PREV_2D**：ETL 读取自身前两日（`PREV_2D`）分区作为历史快照，若前两日分区缺失或数据异常，`whitelist_date` 将降级为当日日期，导致历史最早开白信息丢失，需监控上游数据完整性。

4. **feature_mode 来源差异**：
   - GMS 白名单（type=1）中，`feature_mode=1`（open to all）的记录来源于 `is_auto_escrow_enabled=1` 的广告主，而非 feature_toggle 表
   - `feature_mode=3`（blacklist）的判断逻辑为：全量广告主 LEFT JOIN 黑名单，取 `blacklist.shop_id IS NULL` 的部分（即不在黑名单中的店铺标记为 blacklist mode，代表该模式下所有不在黑名单的店铺均开放）

5. **`tz_type = 'local'` 过滤**：`campaign_tag` CTE 从 `dim_campaign` 读取数据时指定了 `tz_type = 'local'`，确保使用本地时区口径的广告活动数据，避免跨时区重复计数。

6. **时区转换**：白名单开白时间（`ctime`）从 `Asia/Singapore`（SGT）转换到各地区本地时区（`${timezone}` 参数），再提取日期作为 `whitelist_date`，各地区按本地时区参数化调度。

---

*文档生成时间：2026-04-22*