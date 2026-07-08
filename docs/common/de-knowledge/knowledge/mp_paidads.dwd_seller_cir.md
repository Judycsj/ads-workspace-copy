<!-- ads-workspace-gdoc-sync: gdoc_id=1sdI-ckaipr6gKf0K0JRuNPk8zW4gi2oe9cfItwtQ8nk gdoc_url=https://docs.google.com/document/d/1sdI-ckaipr6gKf0K0JRuNPk8zW4gi2oe9cfItwtQ8nk/edit -->

# mp_paidads.dwd_seller_cir

**分层**：DWD（明细数据层）
**主键**：`shop_id` + `ads_id` + `item_id` + `placement` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（各地区按本地时区参数化调度）
**引用频次**：0（末端 ADS 层表，未被其他候选表直接引用）

---

## 业务描述

本表记录卖家在 Shopee 付费广告系统中，针对每个广告单元（`ads_id`）在各投放位（`placement`）上设置的**目标 ROI（ROAS）/ CIR 配置明细**，覆盖商品广告（Search Product、Product Manual、Product Auto）及直播广告（Live Stream）等多种广告类型。核心字段 `cir`（Cost-Income Ratio，成本收入比）即 `1 / target_roas`，反映卖家在该广告单元上愿意承受的广告成本占销售额的比例目标。

本表的主要使用场景包括：分析卖家对平台 ROI 建议值的采纳情况（`status` 字段区分"系统自动值"、"卖家自定义值"、"卖家采纳建议值"三种状态）、追踪每个广告投放位的 CIR 配置历史、以及为智能投放算法提供卖家目标 ROI 的参考输入。

本表整合了广告主台账数据（`advertisement_tab`）、ROI 推荐日志（`target_roi_rcmd_log`、`target_roi_two_rcmd_log`）以及广告活动维表，通过 `UNION ALL` 分别处理商品广告和直播广告的 CIR 配置逻辑，并利用前一日历史数据回填缺失值，是付费广告智能出价策略分析的核心 DWD 明细表。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型。当前写入分区固定为 `'local'`（本地时区）。查询时**必须指定**此字段以避免全表扫描 ⚠️ 目前仅写入 `local` 分区，若直接过滤其他值将返回空结果 |
| `grass_region` | string | 地区编码（大写），如 `'MY'`、`'TH'`、`'VN'` 等，各地区独立调度写入。查询时**必须指定**此字段 |
| `grass_date` | date | 数据日期（本地时区），对应广告配置的快照日期。查询时**必须指定**此字段 |

### 维度：主键与广告归属

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺 ID |
| `user_id` | bigint | 卖家用户 ID |
| `ads_id` | bigint | 广告单元 ID |
| `item_id` | bigint | 广告商品 ID |
| `campaign_id` | bigint | 广告活动 ID |

### 维度：广告类型与投放位

| 字段 | 类型 | 说明 |
|------|------|------|
| `campaign_type` | int | 广告活动类型枚举值：`1`=SEARCH_PRODUCT，`2`=TARGETING，`3`=SHOP_AUTO，`4`=PRODUCT_MANUAL，`5`=PRODUCT_AUTO，`6`=LIVE_STREAM |
| `placement` | bigint | 广告投放位 ID。ETL 中对原始 `placement=8` 展开为 `[802, 805]`，`placement=33` 展开为 `[3327, 3328, 3337, 3338, 3339, 3342, 3348]`（直播广告位），最终写入的是展开后的子投放位 ⚠️ 同一 `ads_id` 可能对应多条不同 `placement` 的记录，不可直接 COUNT(DISTINCT ads_id) 当作广告数 |
| `product_placement` | int | 商品维度的投放位标识，来源于 `dim_product_campaign`；直播广告（placement 33 系列）此字段为 `NULL` |
| `platform` | int | 投放平台标识，来源于 ROI 推荐日志 |
| `suggest_roi_entry_point` | int | ROI 建议值的入口点类型，来源于 `target_roi_two` 日志中的 `entry_point` 字段，标识推荐弹出的场景入口 |

### 维度：CIR 配置状态

| 字段 | 类型 | 说明 |
|------|------|------|
| `status` | int | 卖家对 ROI 建议值的采纳状态：`0`=卖家使用系统自动值（`selected_target_roi_type=1`），`1`=卖家使用自定义值（`selected_target_roi_type=2`），`2`=卖家自定义值恰好等于某个建议值（视为采纳建议） ⚠️ `status=2` 由 ETL 在写入时通过 `array_contains(final_value_list, target_broad_roi)` 条件派生覆盖，并非原始存储值，统计采纳率需注意此逻辑 |

### 维度：时间戳

| 字段 | 类型 | 说明 |
|------|------|------|
| `ctime` | bigint | 广告单元创建时间（Unix 时间戳，秒级） |
| `mtime` | bigint | 广告单元最后修改时间（Unix 时间戳，秒级） |
| `create_datetime` | string | 创建时间的可读格式（`yyyy-MM-dd HH:mm:ss`），由 `from_unixtime(ctime)` 转换，时区为 SGT（Asia/Singapore） ⚠️ 时区为新加坡时间，非卖家本地时区，跨时区分析时需注意 |
| `modify_datetime` | string | 最后修改时间的可读格式（`yyyy-MM-dd HH:mm:ss`），由 `from_unixtime(mtime)` 转换，时区为 SGT ⚠️ 同上，时区为新加坡时间 |

### 指标：CIR 与 ROI 建议值

| 字段 | 类型 | 说明 |
|------|------|------|
| `cir` | double | 成本收入比（Cost-Income Ratio），计算公式为 `1 / target_roas`，即 `1 / target_broad_roi`。值越小表示卖家要求广告效率越高 ⚠️ 为派生比率字段，**不可直接 SUM**；若需汇总店铺层 CIR，需重新以分子分母（花费 / GMV）计算；另需注意直播广告的 `cir` 来源于 `roi_two` 字段，口径略有差异 |
| `final_value_list` | array\<double\> | 系统为该广告单元推荐的 ROI 候选值列表（固定 3 个元素，单位与 `cir` 同量纲，已做 `/100000.0` 归一化）。`status=2` 的判断依赖此字段 ⚠️ 存储为数组类型，**不可直接聚合**；需用 `array_contains` 或 `explode` 展开后使用；若来源日志无数据则可能为 `NULL`（通过 `coalesce` 回填前日数据） |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下三个分区字段**，否则将触发全表扫描，影响查询性能并产生不必要的计算费用：

```sql
WHERE tz_type      = 'local'            -- 目前仅有 local 分区有数据，必填
  AND grass_region = 'MY'               -- 替换为目标地区大写编码
  AND grass_date   = DATE('2026-04-21') -- 替换为目标日期
```

- **`tz_type`**：当前 ETL 固定写入 `'local'` 分区，缺少此条件将扫描所有 tz_type 分区（虽目前只有一个，但仍应显式指定以保证查询剪枝）
- **`grass_region`**：各地区数据独立存储，缺少此条件将全量扫描所有地区数据
- **`grass_date`**：本表为每日快照，缺少日期过滤将扫描全量历史分区

### 不可直接 SUM 的字段

| 字段 | 错误用法 | 正确用法 |
|------|----------|----------|
| `cir` | `SUM(cir)` / `AVG(cir)` 直接聚合 | 需用广告实际花费和 GMV 重新计算加权 CIR：`SUM(spend) / SUM(gmv)` |
| `final_value_list` | 直接 `SUM` 或 `GROUP BY` | 用 `array_contains(final_value_list, value)` 判断包含关系，或 `explode(final_value_list)` 展开后分析 |
| `placement` | `COUNT(DISTINCT ads_id)` 统计广告数 | 同一 `ads_id` 在 ETL 展开后会有多条不同 `placement` 记录，统计广告数需先按 `ads_id` 去重或限定 `placement` 范围 |
| `status` | 直接以原始值统计采纳率 | 注意 `status=2` 是 ETL 派生的，代表"卖家值恰好等于建议值"，统计"采纳建议"行为时应包含 `status=2` |

### 时效性说明

- 本表数据为**每日快照**，`grass_date` 为当天本地日期的广告配置状态
- ETL 在处理时会将 `grass_date` 前一日（`PREV_2D`）的历史数据作为回填来源（`left join dwd_seller_cir__reg_s0_live where grass_date = date('${PREV_2D}')`），因此当天日志缺失的字段（如 `final_value_list`、`platform` 等）会用前日值补全
- 若需分析卖家**当前最新**的 CIR 配置，取最新 `grass_date` 分区即可；若需分析配置变化趋势，需按 `grass_date` 跨分区比较

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.shopee_ads_${region}_db__advertisement_tab__reg_continuous_s0_live` | 广告主台账原始数据，提供广告单元的 `placement`、`ctime`、`mtime`、`target_broad_roi`（从 `_decoded_extinfo` JSON 解析）等核心字段 |
| `mp_paidads.ods_log_target_roi_rcmd_log_hi__reg_s0_live` | 商品广告 ROI 推荐日志（小时级），提供系统推荐的 ROI 候选值列表、用户选择的 ROI 及采纳类型 |
| `mp_paidads.ods_log_target_roi_two_rcmd_log_hi__reg_s0_live` | 直播/活动维度 ROI 推荐日志（小时级），提供活动级别的 ROI 推荐值及入口点信息 |
| `mp_paidads.dim_campaign__reg_s0_live` | 广告活动维表，提供 `roi_two`（直播广告目标 ROI）、预算等活动级别信息 |
| `mp_paidads.dim_product_campaign__reg_s0_live` | 商品-活动关联维表，提供 `product_placement` 字段 |
| `mp_paidads.dim_advertise_roi_exp__reg_s0_live` | 广告 ROI 实验维表，用于 `target_roi_two` CTE 中将活动级别的推荐值关联到具体 `ads_id` |
| `mp_paidads.dwd_seller_cir__reg_s0_live`（自身前日分区） | 回填数据源，当天日志缺失时用前日（`PREV_2D`）的 `final_value_list`、`platform`、`status`、`cir` 等字段补全 |

---

## ETL 逻辑摘要

### 数据流

```
shopee_ads_${region}_db__advertisement_tab          ods_log_target_roi_rcmd_log_hi
(原始广告台账，含 extinfo JSON)                        (商品广告 ROI 推荐日志)
         │                                                      │
         ▼                                                      ▼
  [advertise_tab_df]                                    [target_roi]
  解析 extinfo，展开 placement,                    取最新推荐记录(rank=1)，
  计算 cir = 1/target_broad_roi                    构造 final_value_list 数组
         │                                                      │
         │                    ods_log_target_roi_two_rcmd_log_hi │
         │                     (直播广告 ROI 推荐日志)            │
         │                              │                        │
         │                              ▼                        │
         │                      [target_roi_two]                 │
         │                  取活动级最新推荐(rank=1)               │
         │                  关联 dim_advertise_roi_exp           │
         │                  获取 ads_id 粒度数据                  │
         │                              │                        │
         ├──────────────────────────────┴────────────────────────┤
         │            UNION ALL(target_roi + target_roi_two)     │
         │                              │                        │
         │   dim_product_campaign       │   dim_campaign         │
         │   (product_placement)        │   (roi_two, budget)    │
         │          │                   │         │              │
         ▼          ▼                   ▼         ▼              ▼
    ┌─────────────────────────────────────────────────────────────┐
    │              主 SELECT（UNION ALL 两路）                      │
    │  路径1: placement IN (4,802,805,40) → 商品广告               │
    │         left join target_roi∪target_roi_two on ads_id       │
    │         left join dim_product_campaign on campaign_id       │
    │                                                             │
    │  路径2: placement IN (3327..3348) → 直播广告                 │
    │         left join target_roi on user_id+campaign_id         │
    │         left join target_roi_two on shop_id+campaign_id     │
    │         left join campaign_tab on campaign_id               │
    └─────────────────────────────────────────────────────────────┘
                              │
                              │  left join（回填缺失值）
                              ▼
              dwd_seller_cir__reg_s0_live（前日分区 PREV_2D）
                              │
                              ▼
              dwd_seller_cir__reg_s0_live（当日写入）
              PARTITION(tz_type='local', grass_region, grass_date)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `dim_product_campaign` | `mp_paidads.dim_product_campaign__reg_s0_live` | 去重取最早修改时间的商品-活动关联记录（`rank=1`），提供 `product_placement` |
| `campaign_tab` | `mp_paidads.dim_campaign__reg_s0_live` | 获取当日活动维度信息（`roi_two`、预算等），仅取 `tz_type='local'` 分区 |
| `advertise_tab_df` | `shopee_ads_${region}_db__advertisement_tab__reg_continuous_s0_live` | 解析广告台账原始 JSON（`_decoded_extinfo`），展开多值 `placement`（8→[802,805]，33→[3327...3348]），计算 `cir = 1/target_broad_roi` |
| `target_roi` | `mp_paidads.ods_log_target_roi_rcmd_log_hi__reg_s0_live` | 商品广告 ROI 推荐明细，按 `shop_id+item_id+ads_id+user_id+campaign_id` 取最新推荐（`rank=1`），构造 3 元素 `final_value_list` |
| `target_roi_two` | `mp_paidads.ods_log_target_roi_two_rcmd_log_hi__reg_s0_live` + `dim_advertise_roi_exp` | 活动级 ROI 推荐明细，按 `shop_id+campaign_id` 取最新推荐（`rank=1`），关联实验维表获取 `ads_id` |

### 注意事项

1. **`placement` 展开导致行数膨胀**：原始 `placement=8` 会展开为 2 条记录（802、805），`placement=33` 会展开为 7 条记录（3327~3348 系列）。统计广告数时需注意去重，不可直接用记录数代替广告数。

2. **`cir` 字段的两路口径差异**：
   - 商品广告（路径1）：`cir = 1 / decoded_extinfo.target_broad_roi`（来自广告台账 extinfo，scaling factor `/100000.0`）
   - 直播广告（路径2）：`cir = 1 / coalesce(target_roi.selected_target_roi/100000.0, roi2.selected_target_roi/100000.0, roi_two)`（优先取推荐日志，再取活动维表 `roi_two`）
   - 两路 `cir` 计算逻辑不同，混合分析时需区分 `campaign_type=6`（直播）与其他类型。

3. **前日回填机制**：当天推荐日志未覆盖的广告（如卖家未触发 ROI 建议弹窗），其 `final_value_list`、`status`、`cir`、`platform` 等字段会用 `PREV_2D`（前日）数据回填（`coalesce(a.xxx, d.xxx)`）。因此 `grass_date` 当天的数据并非全部来自当天日志，历史遗留值可能沿用多日。

4. **`status=2` 派生逻辑**：最终 `status` 的写入逻辑为 `CASE WHEN array_contains(coalesce(a.final_value_list, d.final_value_list), coalesce(a.target_broad_roi, d.target_broad_roi)) THEN 2 ELSE coalesce(a.status, d.status) END`，即当卖家当前目标 ROI 恰好命中推荐候选值之一时，强制将 `status` 置为 `2`，覆盖原始状态值。

5. **时区处理**：广告台账过滤条件使用 `ctime < UNIX_TIMESTAMP(FROM_UTC_TIMESTAMP(TO_UTC_TIMESTAMP(DATE_ADD(DATE'${grass_date}', 1), '${timezone}'), 'Asia/Singapore'))` 将本地日期边界转换为 SGT 时间戳，各地区按本地时区参数化调度，时区转换正确性依赖调度参数 `${timezone}`。

6. **`suggest_roi_entry_point` 仅来自 `target_roi_two`**：商品广告路径（路径1）的 `suggest_roi_entry_point` 来源于 `target_roi_two.entry_point`；直播广告路径（路径2）同样来源于 `roi2.entry_point`。`target_roi`（小时日志）不提供此字段，若该广告未命中 `target_roi_two` 日志则此字段为 `NULL`。

---

## 数据来源

（详见上方"数据来源"章节）

---

*文档生成时间：2026-04-22*