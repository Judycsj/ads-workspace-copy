<!-- ads-workspace-gdoc-sync: gdoc_id=14PhvkIg-zzzWoDMWzYv3-wGADbu2M5jOhbGZOsoY8i4 gdoc_url=https://docs.google.com/document/d/14PhvkIg-zzzWoDMWzYv3-wGADbu2M5jOhbGZOsoY8i4/edit -->

# srdi_mart.dim_sr_data_warehouse_user_label

**分层：** DIM（维度层）
**主键：** `user_id`（在同一分区内唯一）
**分区：** `grass_region`（大区）/ `local_date`（本地日期）
**更新频率：** 每日一次（覆盖写入当日分区）
**访问频次：** 9,701 次

---

## 业务描述

本表为搜推数仓（SRDI）核心用户标签维度表，以用户为粒度，汇聚用户在全平台及各推荐场景（Daily Discover、You May Also Like、Search）下的行为特征、消费能力、人口属性等多维标签，供搜索与推荐系统的策略分析、人群圈选及模型特征工程使用。

**核心业务场景：**

- **人群画像与分层：** 基于活跃度（`active_level`）、下单水平（`order_level`）、购物车均价（`backet_level`）、生命周期（`life_cycle`）等标签对用户分群。
- **场景归因分析：** 区分用户在 Daily Discover、YMAL、Search 三大场景下的点击、活跃、下单和 GMV 贡献，支持场景效率评估。
- **消费能力评估：** 通过 ABS（平均购物篮尺寸）分位档（`abs_tier_180d`）、收入水平（`income_level`）、180 天 GMV（`gmv_180d`）等综合刻画用户消费层次。
- **平台 vs. 搜索渗透分析：** 基于 180 天 GMV 分位分桶（`platform_gmv_180d_pct_category`、`search_gmv_180d_pct_category`）和时长分位分桶（`platform_duration_180d_pct_category`、`search_duration_180d_pct_category`）衡量用户在平台整体与搜索场景的相对价值。

**适合回答的典型问题：**

- 某大区近 30 天高活跃用户（`active_level = '26-30'`）的 GMV 贡献如何？
- Daily Discover 场景下不同点击档位用户的转化率差异是什么？
- 成熟买家（`life_cycle = 'mature'`）在 Search 场景的 30 天订单量分布？
- 不同 ABS 分位档用户的复购率及平台留存情况？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 大区标识，如 `BR`、`TH` 等；所有查询必须指定此分区 |
| `local_date` | date | 本地日期（用户所在地区时区），对应数据快照日期；所有查询必须指定此分区 |

---

### 维度：用户基础属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | bigint | 用户唯一标识，来源于 `dim_sr_data_warehouse_user`，分区内主键 |
| `gender` | int | 用户性别，来源于用户基础信息表 |
| `age` | int | 用户年龄，来源于用户基础信息表 |
| `is_new_user` | int | 是否新用户标识（1=是，0=否） |
| `income_level` | string | 预测收入水平，来源于 `mpi_data_mart.dws_a180_user_basic_predict_tags_df`；无数据时填充空字符串 |
| `user_purchase_type` | int | 用户购买类型（0=无购买记录，1=有 MP 或 DP 新用户标记），来源于 `mpi_data_mart.dws_all_user_segmentation_tags_df` |
| `platform` | string | 用户最近一次操作所使用的平台（如 iOS、Android 等） |
| `app_version` | string | 用户最近一次操作时的 App 完整版本号 |
| `app_version_prefix` | string | App 版本号前两段（如 `3.5`），取 `app_version` 按 `.` 分割的前两部分 |
| `life_cycle` | string | 用户生命周期阶段：`new`（历史累计订单 0）、`early`（1–4 单）、`mature`（≥5 单） |

---

### 维度：全平台行为分级标签（近 30 天）

| 字段 | 类型 | 说明 |
|------|------|------|
| `active_level` | string | 全平台活跃天数分级：`0` / `1-7` / `8-15` / `16-25` / `26-30` |
| `item_click_level` | string | 全平台商品点击量分级：`0-5` / `6-39` / `40-149` / `150+` |
| `order_level` | string | 全平台下单量分级：`0` / `1-3` / `4-6` / `7-10` / `11+` |
| `backet_level` | string | 全平台购物篮均价分级：`0` / `(0, 0.8]` / `(0.8, 4.5]` / `(4.5, +)` |
| `dd_active_level` | string | Daily Discover 场景活跃天数分级，规则同 `active_level` |
| `dd_click_level` | string | Daily Discover 场景点击量分级：`0-2` / `3-7` / `8-23` / `24+` |

---

### 维度：ABS（平均购物篮尺寸）分位档（近 180 天）

| 字段 | 类型 | 说明 |
|------|------|------|
| `abs_tier_180d` | int | 用户 180 天 ABS（GMV/订单数）所在分位档（1–5），无购买记录时为 0；BR 大区使用 20/35/55/75 百分位，其余大区使用 25/45/65/85 百分位 |

---

### 维度：平台与搜索相对价值分桶（近 180 天）

| 字段 | 类型 | 说明 |
|------|------|------|
| `platform_gmv_180d_pct_category` | int | 用户平台整体 GMV（仅 `is_direct=TRUE` 订单）在有数据用户中的十分位分桶（0–9），NULL 表示无平台直接 GMV |
| `search_gmv_180d_pct_category` | int | 用户搜索场景 GMV 在有数据用户中的十分位分桶（0–9），NULL 表示无搜索 GMV |
| `platform_duration_180d_pct_category` | int | 用户平台整体浏览时长在有数据用户中的十分位分桶（0–9），NULL 表示无记录 |
| `search_duration_180d_pct_category` | int | 用户搜索场景浏览时长在有数据用户中的十分位分桶（0–9），NULL 表示无记录 |

---

### 指标：全平台行为指标（近 30 天）

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_click_cnt_30d` | int | 全平台（`__ALL__` 场景）商品 omni 点击次数（近 30 天），无数据填 0 |
| `active_days_30d` | int | 全平台有曝光的活跃天数（近 30 天），无数据填 0 |
| `order_30d` | double | 全平台下单量（近 30 天），无数据填 0 |
| `gmv_30d` | double | 全平台 GMV（近 30 天，USD），无数据填 0 |
| `backet_size` | double | 全平台购物篮均价（`gmv_30d / order_30d`，近 30 天）；**不可直接 SUM，为比率指标** |
| `total_order` | int | 用户历史累计下单量（截至当日），来源于 `dws_buyer_gmv_td__reg_s0_live` |

---

### 指标：历史累计 & 180 天指标

| 字段 | 类型 | 说明 |
|------|------|------|
| `order_180d` | double | 近 180 天下单量，来源于 `dws_buyer_gmv_nd__reg_s0_live`；用户无购买记录时为 NULL |
| `gmv_180d` | double | 近 180 天 GMV（USD），来源于 `dws_buyer_gmv_nd__reg_s0_live`；用户无购买记录时为 NULL |

---

### 指标：Daily Discover 场景行为指标（近 30 天）

| 字段 | 类型 | 说明 |
|------|------|------|
| `dd_click_cnt_30d` | int | Daily Discover 场景点击次数（`click_cnt`，近 30 天），无数据填 0 |
| `dd_omni_click_cnt_30d` | int | Daily Discover 场景 omni 点击次数（近 30 天），无数据填 0 |
| `dd_active_days_30d` | string | Daily Discover 场景有曝光的活跃天数（近 30 天），无数据填 0；注意字段类型为 string |
| `dd_order_30d` | double | Daily Discover 场景下单量（近 30 天），无数据填 0 |
| `dd_gmv_30d` | double | Daily Discover 场景 GMV（近 30 天，USD），无数据填 0 |
| `dd_backet_size` | double | Daily Discover 场景购物篮均价（`dd_gmv_30d / dd_order_30d`，近 30 天）；**不可直接 SUM，为比率指标** |
| `dd_item_imp_cnt_14d` | bigint | Daily Discover 场景商品曝光次数（`home-daily_discover-item` 及 `home-daily_discover-item_feed_card`，近 14 天），无数据填 0 |

---

### 指标：You May Also Like 场景行为指标（近 30 天）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ymal_omni_click_cnt_30d` | int | YMAL 场景 omni 点击次数（近 30 天），无数据填 0 |
| `ymal_active_days_30d` | int | YMAL 场景有曝光的活跃天数（近 30 天），无数据填 0 |
| `ymal_order_30d` | double | YMAL 场景下单量（近 30 天），无数据填 0 |
| `ymal_gmv_30d` | double | YMAL 场景 GMV（近 30 天，USD），无数据填 0 |
| `ymal_backet_size` | double | YMAL 场景购物篮均价（`ymal_gmv_30d / ymal_order_30d`，近 30 天）；**不可直接 SUM，为比率指标** |

---

### 指标：Search 场景行为指标（近 30 天）

| 字段 | 类型 | 说明 |
|------|------|------|
| `search_omni_click_cnt_30d` | int | 搜索场景 omni 点击次数（近 30 天），无数据填 0 |
| `search_active_days_30d` | int | 搜索场景有曝光的活跃天数（近 30 天），无数据填 0 |
| `search_order_30d` | double | 搜索场景下单量（近 30 天），无数据填 0 |
| `search_gmv_30d` | double | 搜索场景 GMV（近 30 天，USD），无数据填 0 |
| `search_backet_size` | double | 搜索场景购物篮均价（`search_gmv_30d / search_order_30d`，近 30 天）；**不可直接 SUM，为比率指标** |

---

## 查询使用须知

### 必须包含的过滤条件

```sql
WHERE grass_region = '<大区>'
  AND local_date = '<快照日期>'
```

- **`grass_region` 和 `local_date` 均为分区字段，查询时必须同时指定**，否则将触发全表扫描，严重影响性能并产生高额计算成本。
- `local_date` 使用本地日期（用户所在大区时区），非 UTC 日期，跨时区对比时需注意对齐。

### 不可直接 SUM 的字段（比率 / 预计算派生指标）

以下字段为预聚合比率，对多个用户汇总时**不能直接使用 SUM**，需用原始分子/分母重新计算：

| 字段 | 计算逻辑 | 正确聚合方式 |
|------|----------|-------------|
| `backet_size` | `gmv_30d / order_30d` | `SUM(gmv_30d) / NULLIF(SUM(order_30d), 0)` |
| `dd_backet_size` | `dd_gmv_30d / dd_order_30d` | `SUM(dd_gmv_30d) / NULLIF(SUM(dd_order_30d), 0)` |
| `ymal_backet_size` | `ymal_gmv_30d / ymal_order_30d` | `SUM(ymal_gmv_30d) / NULLIF(SUM(ymal_order_30d), 0)` |
| `search_backet_size` | `search_gmv_30d / search_order_30d` | `SUM(search_gmv_30d) / NULLIF(SUM(search_order_30d), 0)` |

以下字段为分位分桶结果，**不可直接 SUM/AVG**，应作为分组维度使用：

- `abs_tier_180d`（分位档，0–5）
- `platform_gmv_180d_pct_category`（十分位，0–9，NULL 表示无数据）
- `search_gmv_180d_pct_category`（十分位，0–9，NULL 表示无数据）
- `platform_duration_180d_pct_category`（十分位，0–9，NULL 表示无数据）
- `search_duration_180d_pct_category`（十分位，0–9，NULL 表示无数据）

### 时效性与窗口说明

- 本表为**每日快照表**，`local_date` 代表数据快照日期，不保存历史变动明细。
- `*_30d` 指标为过去 30 天滚动窗口（`date_sub(local_date, 29)` 至 `local_date`）。
- `*_180d` 指标为过去 180 天滚动窗口（`date_sub(local_date, 179)` 至 `local_date`）。
- `dd_item_imp_cnt_14d` 为过去 14 天窗口（`date_sub(local_date, 13)` 至 `local_date`）。
- `total_order` 为**历史累计值**（td），非滚动窗口。
- `platform` / `app_version` / `app_version_prefix` 取用户当日**最后一次**操作记录，代表快照日期当天的最新状态。
- `order_180d` / `gmv_180d` / `abs_tier_180d` 字段仅对当日有购买记录（`placed_order_cnt_180d > 0`）的用户填充，无记录用户对应字段为 NULL（`abs_tier_180d` 填 0）。

### 其他注意事项

- `dd_active_days_30d` 的 DataMap 类型为 **string**，与其他 `*_active_days_*` 字段（int）不一致，数值比较前需显式 CAST。
- `platform_gmv_180d_pct_category`、`search_gmv_180d_pct_category`、`platform_duration_180d_pct_category`、`search_duration_180d_pct_category` 为 NULL 时表示用户在对应维度无行为数据，查询时建议使用 `IS NOT NULL` 过滤或 `COALESCE` 处理。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dim_sr_data_warehouse_user` | 用户基础属性（`user_id`、`gender`、`age`、`is_new_user`），作为用户驱动表（LEFT JOIN 基础） |
| `srdi_mart.dws_sr_data_warehouse_platform_user_level_benchmark_1d` | 全平台及各场景（DD、YMAL、Search）近 30 天用户行为聚合（点击、活跃、下单、GMV） |
| `mp_order.dws_buyer_gmv_nd__reg_s0_live` | 用户近 180 天下单量、GMV，用于计算 ABS 及分位档 |
| `mp_order.dws_buyer_gmv_td__reg_s0_live` | 用户历史累计下单量（`total_order`），用于生命周期判断 |
| `mpi_data_mart.dws_a180_user_basic_predict_tags_df` | 用户预测收入水平（`income_level`） |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 用户最近一次操作的平台与 App 版本信息 |
| `mpi_data_mart.dws_all_user_segmentation_tags_df` | 用户购买类型标签（MP/DP 新用户标记） |
| `srdi_mart.dws_sr_data_warehouse_platform_order_benchmark_1d` | 用户近 180 天平台整体及搜索场景 GMV，用于 GMV 十分位分桶 |
| `srdi_mart.dwd_sr_data_warehouse_view_page_duration_di` | 用户近 180 天平台整体及搜索场景浏览时长，用于时长十分位分桶 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_user          ──┐
dws_sr_..._benchmark_1d (行为)      ──┤
dws_buyer_gmv_nd (180d)             ──┤  12 个 Temporary View
dws_buyer_gmv_td (累计)             ──┤  （分步聚合 + 分位计算）
dws_a180_user_basic_predict_tags_df ──┤
dwd_sr_..._platform (版本)          ──┤         ↓
dws_all_user_segmentation_tags_df   ──┤   INSERT OVERWRITE
dws_sr_..._order_benchmark_1d       ──┤   dim_sr_data_warehouse_user_label
dwd_sr_..._view_page_duration_di    ──┘   partition(grass_region, local_date)
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|------|---------------|------|
| 1 | `user_{region}` | 从 `dim_sr_data_warehouse_user` 获取用户基础属性（`user_id`、`gender`、`age`、`is_new_user`） |
| 2 | `user_abs_180d_{region}` | 从订单宽表获取用户 180 天下单量、GMV，计算 ABS（GMV/订单数），仅保留有购买记录用户 |
| 3 | `abs_pct_{region}` | 基于 ABS 值计算全局百分位数组（BR 使用 20/35/55/75，其他大区使用 25/45/65/85 百分位） |
| 4 | `user_info_{region}` | 从 `dws_sr_..._benchmark_1d` 按场景 tag 聚合近 30 天用户行为（点击、活跃天数、下单、GMV、各场景分拆），计算 DD 14 天曝光 |
| 5 | `buyer_info_{region}` | 从订单宽表获取用户历史累计下单量 |
| 6 | `income_info_{region}` | 获取用户预测收入水平 |
| 7 | `user_level_platform_app_version_{region}` | 从 DWD 平台日志取用户当日最后一次操作的平台和 App 版本（ROW_NUMBER 取 `log_timestamp` 最大值） |
| 8 | `user_purchase_type_{region}` | 从用户分群标签表判断用户是否有 MP 或 DP 购买记录（NULL 替换处理） |
| 9 | `user_platform_and_search_gmv_{region}` | 从 `dws_sr_..._order_benchmark_1d` 聚合近 180 天平台直接 GMV 与搜索场景 GMV |
| 10 | `user_platform_and_search_gmv_pct_category_{region}` | 对步骤 9 结果分别用 NTILE(10) 计算 GMV 十分位分桶（仅对有数据用户分桶） |
| 11 | `user_platform_and_search_duration_{region}` | 从 `dwd_sr_..._view_page_duration_di` 聚合近 180 天平台整体与搜索场景浏览时长 |
| 12 | `user_platform_and_search_duration_pct_category_{region}` | 对步骤 11 结果用 NTILE(10) 计算时长十分位分桶（仅对有数据用户分桶） |
| 13 | **INSERT OVERWRITE** | 以 `user_{region}` 为驱动表，LEFT JOIN 以上所有中间视图，计算分级标签后写入目标表对应分区 |

### 注意事项

1. **单 writer，多 statement pipeline：** 本表由单个 ETL 文件的 13 条 Spark SQL statement 串行执行，`--sql_divide_splitter--` 为语句分隔符，前 12 条均为 Temporary View 创建，第 13 条为 `INSERT OVERWRITE`，属于同一 pipeline 的连续步骤。
2. **参数化大区：** 所有 Temporary View 名称和分区条件均通过 `${grass_region}` / `${grass_region_without_quote}` 参数化，每次调度针对单一大区写入，不同大区之间不互相干扰。
3. **分位计算的 CROSS JOIN 语义：** `abs_pct_{region}` 视图为单行结果（包含百分位数组），通过 `ON abs.abs_180d IS NOT NULL` 条件与用户数据做 CROSS JOIN 广播，无购买记录的用户 `abs_tier_180d` 统一赋值为 0。
4. **NTILE 分桶的 NULL 隔离：** `platform_gmv_180d_pct_category` 等四个十分位分桶字段使用 `PARTITION BY (column IS NOT NULL)` 将 NULL 用户与有数据用户隔离，NULL 用户不参与分桶，最终输出为 NULL。
5. **`dd_active_days_30d` 类型不一致：** ETL 计算该字段逻辑与其他活跃天数字段完全相同（int），但 DataMap 中登记为 string，使用时需注意类型兼容性。
6. **INSERT OVERWRITE 覆盖写入：** 每日调度对目标分区执行全量覆盖，重跑历史日期分区时会覆盖原有数据，需确认上游数据在历史日期的可用性，尤其是 `dws_buyer_gmv_nd` 和 `dws_buyer_gmv_td` 等实时/准实时表。

---

*文档生成时间：2026-05-17*