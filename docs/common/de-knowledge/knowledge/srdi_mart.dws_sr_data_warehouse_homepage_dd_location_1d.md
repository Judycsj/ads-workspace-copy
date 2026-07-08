<!-- ads-workspace-gdoc-sync: gdoc_id=1pKndCP_7wDc-8dwEC6JErzuw2XBOmFGfXz-X-KPBu24 gdoc_url=https://docs.google.com/document/d/1pKndCP_7wDc-8dwEC6JErzuw2XBOmFGfXz-X-KPBu24/edit -->

# srdi_mart.dws_sr_data_warehouse_homepage_dd_location_1d

**分层：** DWS（数据服务层）
**主键：** `grass_region` + `local_date` + `location` + `card_type` + `is_ads` + `user_purchase_type` + `platform`
**分区：** `grass_region`（地区）、`local_date`（本地日期）
**更新频率：** 每日一次（天级调度，覆盖写入）
**访问频次：** 1014 次

---

## 业务描述

本表是首页推荐（Daily Discover）**按坑位（location）维度**汇聚的日粒度数据仓库宽表，记录各地区、平台、用户购买类型、卡片类型、是否广告等组合维度下，每个坑位的曝光、点击、浏览、下单、GMV 及广告收入等核心指标。

**核心业务场景：**

- 分析首页各坑位（Feed 流位置）的流量分布与转化漏斗（曝光 → 点击 → 下单）
- 对比广告坑位与自然坑位的曝光占比（广告填充率）、收入及转化效率
- 按卡片类型（混合卡、视频卡等）拆分首页各位置的表现
- 区分买家（buyer）与非买家（non-buyer）在不同坑位的行为差异
- 多维度 GROUPING SETS 预聚合，支持平台、用户类型、坑位的灵活组合下钻分析

**适合回答的问题：**

- 首页第 N 个坑位的曝光量、点击率、转化率是多少？
- 广告填充率（ads_load）在各坑位的分布如何？
- 不同卡片类型在同一坑位的 GMV 占比差异？
- 买家与非买家在各坑位的点击行为有何差异？
- 各坑位的广告收入（ads_revenue）贡献？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区分区键，如 `SG`、`MY` 等，查询时必须指定 |
| `local_date` | date | 本地日期分区键，格式 `yyyy-MM-dd`，查询时必须指定 |

### 维度：坑位与内容类型

| 字段 | 类型 | 说明 |
|---|---|---|
| `location` | int | 首页 Daily Discover Feed 流中的坑位编号，最大值截断至 200（`least(location, 200)`）；-1 表示位置缺失，-999 为广告内流占位符 |
| `card_type` | string | 卡片类型，从 `feature_detail` 中解析；`__ALL__` 表示该行为所有卡片类型的聚合汇总 |
| `is_ads` | string | 是否广告坑位，取值 `'true'`、`'false'`、`'__ALL__'`；`__ALL__` 表示广告与自然流量合并汇总 |

### 维度：用户与平台

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_purchase_type` | string | 用户购买类型，取值 `'buyer'`（历史买家）、`'non-buyer'`（非买家）、`'__ALL__'`（全用户汇总）；源自 `dim_sr_data_warehouse_user_label` |
| `platform` | string | 用户使用的客户端平台；`'NULL'` 表示标签缺失，`'__ALL__'` 表示全平台汇总 |

### 指标：流量计数指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数（impression 操作的 operation_cnt 累加） |
| `click_cnt` | bigint | 点击次数（click 操作的 operation_cnt 累加） |
| `omni_imp_cnt` | bigint | 全链路曝光次数（omni_impression 操作累加，含归因上游模块） |
| `omni_click_cnt` | bigint | 全链路点击次数（omni_click 操作累加） |
| `ppv_cnt` | bigint | 商品详情页浏览次数（ppv 操作且 `is_back = false`） |
| `order_cnt` | double | 下单次数（order 操作的 operation_cnt 累加） |
| `gmv` | double | 下单 GMV（place_order_gmv 累加，单位与源表一致） |
| `pc2_gmv` | double | PC2 口径 GMV（pc2_gmv 累加） |

### 指标：去重用户数

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_uu` | bigint | 有曝光行为的去重用户数（`imp_cnt > 0` 的 `count(distinct user_id)`） |
| `click_uu` | bigint | 有点击行为的去重用户数（`click_cnt > 0` 的 `count(distinct user_id)`） |
| `order_uu` | bigint | 有下单行为的去重用户数（`order_cnt > 0` 的 `count(distinct user_id)`） |

### 指标：点击/转化率（比率，不可直接 SUM）

| 字段 | 类型 | 说明 |
|---|---|---|
| `ctr` | double | 点击率，`click_cnt / imp_cnt`；`imp_cnt = 0` 时取 0 |
| `cr` | double | 点击转化率，`order_cnt / click_cnt`；`click_cnt = 0` 时取 0 |
| `co` | double | 曝光转化率，`order_cnt / imp_cnt`；`imp_cnt = 0` 时取 0 |
| `uv_ctr` | double | UV 点击率，`click_uu / imp_uu`；`imp_uu = 0` 时取 0 |
| `uv_cr` | double | UV 点击转化率，`order_uu / click_uu`；`click_uu = 0` 时取 0 |
| `uv_co` | double | UV 曝光转化率，`order_uu / imp_uu`；`imp_uu = 0` 时取 0 |

### 指标：占比与千次指标（比率，不可直接 SUM）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_perc` | double | 当前行曝光量占同坑位（`card_type='__ALL__'` & `is_ads='__ALL__'`）汇总曝光的比例 |
| `click_perc` | double | 当前行点击量占同坑位汇总点击的比例 |
| `order_perc` | double | 当前行下单量占同坑位汇总下单的比例 |
| `gmv_perc` | double | 当前行 GMV 占同坑位汇总 GMV 的比例 |
| `pc2_perc` | double | 当前行 PC2 GMV 占同坑位汇总 PC2 GMV 的比例 |
| `ads_load` | double | 广告填充率，广告曝光量占该 `user_purchase_type` + `platform` 组合下全坑位总曝光的比例 |
| `opm` | double | 千次曝光下单数，`order_cnt * 1000 / imp_cnt`；`imp_cnt = 0` 时取 0 |
| `gpm` | double | 千次曝光 GMV，`gmv * 1000 / imp_cnt`；`imp_cnt = 0` 时取 0 |

### 指标：广告收入

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_revenue` | double | 广告收入（美元），来源于广告平台日志 `dwd_advertise_performance_di__reg_s0_live`；`entrance=3` 时按实际坑位记录，其他外流入口统一记录为 `location=-999` |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须同时指定**，否则触发全表扫描：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2025-05-16'
  ```

### 维度取值约定

- `card_type = '__ALL__'`、`is_ads = '__ALL__'`、`platform = '__ALL__'`、`user_purchase_type = '__ALL__'` 均为该维度的**全量汇总行**，与明细行**共存于同一分区**，查询时须根据分析粒度明确过滤，避免重复计数。
- `user_purchase_type` 在源表为整型（0/1/-1），写入时已转换为字符串：`'non-buyer'`、`'buyer'`、`'__ALL__'`。
- `platform = 'NULL'` 表示无法关联到用户标签的情况，非 SQL NULL。
- `location = -1` 表示坑位信息缺失；`location = -999` 为广告内流 revenue 的占位符坑位，仅在 `ads_revenue` 指标中出现。

### 不可直接 SUM 的字段

以下字段为**预计算比率或依赖分母的派生指标**，跨行累加无业务意义，需回溯基础指标重新计算：

- `ctr`、`cr`、`co`（点击/转化率系列）
- `uv_ctr`、`uv_cr`、`uv_co`（UV 点击/转化率系列）
- `imp_perc`、`click_perc`、`order_perc`、`gmv_perc`、`pc2_perc`（占比系列）
- `ads_load`（广告填充率）
- `opm`、`gpm`（千次曝光指标）

去重指标 `imp_uu`、`click_uu`、`order_uu` 在跨维度聚合时同样**不可直接 SUM**（已在预聚合阶段通过 `count(distinct)` 计算，跨 `grouping set` 累加会导致重复）。

### 时效性说明

- 本表为 **`_1d` 天级快照表**，每日覆盖写入（INSERT OVERWRITE），当天数据通常在次日产出。
- 历史日期数据不会自动回刷，如需历史对比须自行按日期分区扫描。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | 首页行为事件明细（曝光、点击、下单等操作及归因模块信息） |
| `srdi_mart.dim_sr_data_warehouse_user_label` | 用户维度标签（购买类型、平台信息） |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告平台投放日志（广告收入 `expenditure_amt_usd`，按入口类型过滤） |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_platform          dim_sr_data_warehouse_user_label
      （行为明细，过滤 Daily Discover）           （用户购买类型 & 平台）
              ↓                                          ↓
    dwd_user_location（用户级坑位汇总）  ──LEFT JOIN──→  dwd_user_location_joined
              ↓
    user_location_cube_pre（GROUPING SETS 多维预聚合 + count(distinct) UU 计算）
              ↓
    user_location_cube_final（UNION ALL 追加跨 user_purchase_type / platform 的汇总维）
              ↓
    traffic_metrics（LEFT JOIN 自关联补充坑位基准值，计算各比率指标）
              ↓                                          ↓
dwd_advertise_performance_di__reg_s0_live    dim_sr_data_warehouse_user_label
      （广告收入，按 entrance 过滤）                （用户标签 JOIN）
              ↓
    ads_revenue_base → ads_revenue_joined → ads_metrics（GROUPING SETS 多维汇总）
              ↓
traffic_metrics FULL OUTER JOIN ads_metrics（按维度键对齐合并广告收入）
              ↓
INSERT OVERWRITE dws_sr_data_warehouse_homepage_dd_location_1d
```

### 关键步骤

| 步骤 | Temporary View / 中间表 | 说明 |
|---|---|---|
| Step 1 | `dwd_user_location` | 从 `dwd_sr_data_warehouse_platform` 过滤 Daily Discover 模块，提取用户级坑位行为计数；location 截断至 200，is_ads 转字符串 |
| Step 2 | `dim_user_label` | 从 `dim_sr_data_warehouse_user_label` 获取用户购买类型与平台信息 |
| Step 3 | `dwd_user_location_joined` | Step1 LEFT JOIN Step2，补全用户维度标签，缺失时 `user_purchase_type` 默认 0（non-buyer），platform 默认 `'NULL'` |
| Step 4 | `user_location_cube_pre`（CACHE） | 对 Step3 做 GROUPING SETS 多维聚合，同时计算 `count(distinct user_id)` 的 UU 指标和 `ads_imp_cnt` |
| Step 5 | `user_location_cube_final` | UNION ALL Step4 与额外 GROUPING SETS 汇总（`user_purchase_type=-1` 全用户、`platform='__ALL__'` 全平台），补全跨维度合计行 |
| Step 6 | `traffic_metrics` | Step5 自关联获取坑位基准分母（`card_type='__ALL__' AND is_ads='__ALL__'` 行），计算 ctr/cr/co/uv_* 及 perc 系列比率；再 JOIN 全坑位汇总计算 `ads_load` |
| Step 7 | `ads_revenue_base` | 从广告日志提取 Daily Discover 相关入口（`entrance in (3,25,31,32,34,56)`）的广告收入，按 entrance 映射 card_type |
| Step 8 | `ads_revenue_joined` | Step7 LEFT JOIN 用户标签，补全 platform 和 user_purchase_type |
| Step 9 | `ads_metrics`（CACHE） | 对 Step8 做 8 种 GROUPING SETS 多维汇总，生成广告收入的各维度组合 |
| Step 10 | INSERT OVERWRITE | traffic_metrics FULL OUTER JOIN ads_metrics（广告指标扩展为 `is_ads='true'` 和 `is_ads='__ALL__'` 两行），维度字段整型转字符串，NULL COALESCE 为 0，写入目标分区 |

### 注意事项

1. **GROUPING SETS 多维展开导致行数膨胀**：同一 `location` 下存在多个维度组合的聚合行（明细行 + 汇总行并存），查询时务必明确指定所有维度过滤条件，避免将明细行与汇总行混合 SUM。
2. **UU 指标跨 GROUPING SET 的近似性**：`user_location_cube_final` 中追加的跨 `user_purchase_type`/`platform` 汇总行的 UU 通过 `sum(imp_uu)` 实现（非重新 `count(distinct)`），存在用户在多个子组重叠时高估的可能，与 Step4 中精确去重口径不同。
3. **`ads_revenue` 的坑位口径差异**：仅 `entrance=3`（外流）的广告 revenue 携带真实 location，其他入口（`25/31/32/34/56`）统一记为 `location=-999`，跨坑位分析广告收入时需注意此差异。
4. **CACHE TABLE 依赖**：`user_location_cube_pre` 和 `ads_metrics` 使用 Spark CACHE，后续多次引用性能依赖缓存命中，大流量日期需关注 Executor 内存压力。
5. **单 writer，分区覆盖写入**：本表仅有 1 个 ETL 文件，无 multi-writer 风险；但每次执行为 INSERT OVERWRITE 指定分区，重跑时会覆盖该 `(grass_region, local_date)` 分区全量数据。

---

*文档生成时间：2026-05-17*