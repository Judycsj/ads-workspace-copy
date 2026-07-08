<!-- ads-workspace-gdoc-sync: gdoc_id=1efEfwkscw-5lbEa6Iw4hXkub2-MwWtiDeiZBPF_pz70 gdoc_url=https://docs.google.com/document/d/1efEfwkscw-5lbEa6Iw4hXkub2-MwWtiDeiZBPF_pz70/edit -->

# srdi_mart.ads_sr_data_warehouse_homepage_ad_revenue_exp_1d

**分层：** ADS（应用数据层）
**主键：** `exp_group_id` + `search_entrance` + `grass_region` + `local_date`
**分区：** `grass_region`（站点大区）, `local_date`（业务日期）
**更新频率：** 每日全量覆写（INSERT OVERWRITE，按分区）
**引用频次 / 访问频次：** 1380

---

## 业务描述

本表用于支撑**首页广告收入 A/B 实验分析**场景，聚焦以下核心业务问题：

- 从**首页 DD 卡片（homepage_dd_card）** 和 **YMAL 卡片（cart_ymal_card / mpp_ymal_card / osp_ymal_card / pdp_ymal_card）** 引导至搜索的广告，其带来的广告收益（美元）是多少？
- 在不同 **A/B 实验分组（exp_group_id）** 下，上述两类搜索广告收入的差异如何？
- 全量用户（`__ALL__`）与各实验分组用户在搜索广告收入上的对比。

典型使用场景：
1. 评估首页卡片类广告对搜索侧收入的拉动效果；
2. 对比 A/B 实验各组在首页广告收入维度的实验效果；
3. 分站点、分日期的广告收入趋势监控。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区，如 `SG`、`MY` 等，每个分区写入对应大区数据 |
| `local_date` | date | 业务日期，数据对应当天的广告表现数据 |

### 维度：实验与搜索入口

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | string | A/B 实验分组 ID；`__ALL__` 表示全量用户汇总，其余值为具体实验分组 ID |
| `search_entrance` | string | 搜索广告入口类型，包含 `homepage_dd_card`（首页 DD 卡片）、`cart_ymal_card`、`mpp_ymal_card`、`osp_ymal_card`、`pdp_ymal_card`（各场景 YMAL 卡片） |

### 指标：广告收入（美元）

| 字段 | 类型 | 说明 |
|---|---|---|
| `dd_to_search_card_ads_revenue_usd` | double | 由首页 DD 卡片（entrance 3/25/31/32）曝光的商品、通过搜索 `homepage_dd_card` 入口产生的广告消耗，换算为美元后按分组汇总 |
| `ymal_to_search_card_ads_revenue_usd` | double | 由首页 YMAL 卡片（entrance 4）曝光的商品、通过搜索 YMAL 类入口产生的广告消耗，换算为美元后按分组汇总；仅在对应 `search_entrance` 行有值，其余行为 NULL |
| `to_search_card_ads_revenue_usd` | double | 搜索卡片广告收入美元总额（根据字段命名及上下文，为两类收入的综合汇总口径，具体以下游使用为准） |

> ⚠️ 注意：`dd_to_search_card_ads_revenue_usd` 与 `ymal_to_search_card_ads_revenue_usd` 在同一行中仅其中一个有实际值（由 UNION ALL 结构决定），另一个为 NULL，请勿将两列直接相加汇总。

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，该字段为分区键，缺少此条件将触发全分区扫描，严重影响性能。
- **`local_date`**：必须指定，该字段为分区键，建议精确指定单日或明确日期范围。

```sql
-- 推荐写法
WHERE grass_region = 'SG'
  AND local_date = '2025-01-01'
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `dd_to_search_card_ads_revenue_usd` | 已按 `exp_group_id` + `search_entrance` 预聚合；跨实验分组 SUM 时，`__ALL__` 与各分组数据存在用户重叠，直接累加会重复计算 |
| `ymal_to_search_card_ads_revenue_usd` | 同上；UNION ALL 结构导致该列在 `dd_to_search_card` 对应行为 NULL，跨行 SUM 需确认语义 |
| `to_search_card_ads_revenue_usd` | 综合汇总字段，跨 `exp_group_id` 聚合时同样存在 `__ALL__` 与分组重叠问题 |

### 实验分组使用说明

- `exp_group_id = '__ALL__'` 为全量用户汇总，适用于整体收入监控；
- 比较实验效果时，应筛选具体 `exp_group_id` 值，避免混入 `__ALL__` 汇总行。

### 时效性说明

- 本表为 **`_1d` 日粒度快照表**，每日凌晨 ETL 完成后写入前一自然日数据；
- 数据时效通常延迟 **T+1**，不适用于实时或准实时需求。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告曝光与消耗明细，提供商品 ID、入口、消耗金额（本地货币）等核心字段 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维度表，用于将广告消耗本地货币金额换算为美元 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | A/B 实验用户分组维度表，提供用户与实验分组的对应关系 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_advertise_performance_di__reg_s0_live
    ├──► [ad_item] 筛选曝光商品（entrance 3/4/25/31/32）
    └──► [dwd_advertise_performance] 筛选搜索侧广告消耗（entrance=1）× [fx_rate] 换算美元
              │
              ▼
       [dws_user_revenue] 按商品关联曝光来源，分 DD 卡片 / YMAL 卡片两路 UNION ALL
              │
              ├── 全量汇总（__ALL__）
              └── × [user_exp_raw] 实验分组关联
                        │
                        ▼
    ads_sr_data_warehouse_homepage_ad_revenue_exp_1d（INSERT OVERWRITE）
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| Step 1 | `ad_item` | 从广告曝光明细中，筛选在首页（entrance 3/25/31/32）和 YMAL（entrance 4）位置有曝光的商品 ID 去重列表，item_id 为空则设为 -1 并过滤掉 |
| Step 2 | `fx_rate` | 按站点和日期取当日汇率（取 `first`），用于本地货币转美元 |
| Step 3 | `dwd_advertise_performance` | 筛选搜索入口（entrance=1）、指定 search_entrance 类型的广告消耗明细，按用户+商品+入口聚合本地消耗后，JOIN 汇率表换算为美元 |
| Step 4 | `dws_user_revenue` | **UNION ALL 两路：** ① DD 卡片路径：ad_item（entrance 3/25/31/32）JOIN search_entrance='homepage_dd_card' 的消耗，按用户+入口 SUM 得 `dd_to_search_card_ads_revenue_usd`；② YMAL 路径：ad_item（entrance 4）JOIN YMAL 类入口消耗，按用户+入口 SUM 得 `ymal_to_search_card_ads_revenue_usd` |
| Step 5 | `user_exp_raw` | 从实验用户分组表获取当日有效分配记录（is_assignment_log=1） |
| Step 6 | INSERT OVERWRITE | **UNION ALL 两路写入目标表：** ① 全量汇总：不关联实验分组，`exp_group_id` 固定为 `'__ALL__'`，按 search_entrance SUM；② 实验分组汇总：LEFT JOIN 实验分组表，按 exp_group_id + search_entrance SUM；写入当日当区分区 |

### 注意事项

1. **`__ALL__` 与分组数据重叠**：最终 UNION ALL 写入的两路数据中，`__ALL__` 行与各 `exp_group_id` 行均包含同一批用户，跨 `exp_group_id` 汇总时必须明确过滤，避免重复计算。
2. **LEFT JOIN 实验分组**：Step 6 中实验分组关联使用 LEFT JOIN，若用户不在实验分组表中，`exp_group_id` 将为 NULL，查询时需注意 NULL 分组行的处理。
3. **UNION ALL 字段对齐**：`dws_user_revenue` 中两路 UNION ALL 的第三列分别命名为 `dd_to_search_card_ads_revenue_usd` 和 `ymal_to_search_card_ads_revenue_usd`，但 UNION ALL 合并后列名以第一路为准，第二路数据实际存储在同一列，需结合 `search_entrance` 值区分语义。
4. **单 writer 无并发冲突**：本表为单 ETL 文件写入，无多 writer 并发风险，但每次执行为全分区 OVERWRITE，重跑安全。
5. **参数化分区执行**：SQL 通过 `${grass_region}` / `${local_date}` 参数化，每次调度仅处理单一站点单日数据，多站点需多次调度执行。

---

*文档生成时间：2026-05-17*