<!-- ads-workspace-gdoc-sync: gdoc_id=1nFyBJi537hzq_dUWBuytMwZNx4E2HLvMgvjd9G9aHag gdoc_url=https://docs.google.com/document/d/1nFyBJi537hzq_dUWBuytMwZNx4E2HLvMgvjd9G9aHag/edit -->

# srdi_mart.dws_sr_data_warehouse_search_state_srp_layout_instant_filter_metrics_1d

**分层：** dws_search  
**主键：** grass_region + local_date + address_state + local_hour + use_instant_filter_type + layout_type + card_type  
**分区：** grass_region, local_date  
**更新频率：** 每日全量覆盖（INSERT OVERWRITE）  
**引用频次/访问频次：** 44  

---

## 业务描述

本表是搜索结果页（SRP）即时筛选（Instant Filter）专项数仓汇总表，以**天**为粒度，按地区（`address_state`）、小时（`local_hour`）、即时筛选使用类型（`use_instant_filter_type`）、结果页布局类型（`layout_type`）、卡片类型（`card_type`）多个维度对搜索关键指标进行 CUBE 预聚合，`'__ALL__'` 代表该维度的汇总值。

**核心业务场景：**

- **即时筛选（Instant Filter）效果评估：** 衡量"即时配送"/"快速配送"筛选按钮的曝光、点击、使用情况，以及使用该筛选后的搜索成功率和 GMV 转化。
- **搜索无结果分析：** 追踪因即时筛选导致的无结果次数及搜索量，辅助优化筛选策略。
- **SRP 布局效果对比：** 区分 shop 布局（layout_type=3）与常规布局，分析商品坑位填充率及 shop 卡展现情况。
- **广告收入归因：** 计算搜索场景下广告展现带来的广告收入（ads_rev）。
- **平台与全局搜索 GMV/订单宏观对比：** 提供平台整体订单量/GMV 与全局搜索贡献量，用于占比分析。

**适合回答的问题：**

- 某地区/某小时段内，即时筛选的使用率和使用人数是多少？
- 使用即时筛选的用户搜索成功率（直接/宽泛）是否高于未使用的用户？
- 即时筛选是否加剧了无结果（no_results）的发生？
- shop 布局下商品坑位填充率如何？空 shop 展现次数多少？
- 搜索广告在不同筛选状态和布局下的收入贡献如何？
- 全局搜索 GMV 占平台 GMV 的比例是多少？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 国家/地区标识，如 `ID`、`TH`、`PH` 等，每次写入覆盖对应分区 |
| `local_date` | date | 业务本地日期，数据统计日期（每日一分区） |

---

### 维度：地址与时间

| 字段 | 类型 | 说明 |
|---|---|---|
| `address_state` | string | 用户收货地址所属州/省级行政区；`'__ALL__'` 表示所有地区汇总，`'NULL'` 表示地址无法映射 |
| `local_hour` | string | 本地时区小时（0–23 的字符串）；`'__ALL__'` 表示全天汇总 |

---

### 维度：搜索行为分类

| 字段 | 类型 | 说明 |
|---|---|---|
| `use_instant_filter_type` | string | 是否使用了即时筛选（instant filter）：`'true'` 表示使用，`'false'` 表示未使用，`'__ALL__'` 表示汇总 |
| `layout_type` | string | SRP 结果页布局类型，`'2'` 为常规布局，`'3'` 为 shop 布局；`'__ALL__'` 表示汇总 |
| `card_type` | string | 结果卡片类型，对应 `target_type`（如 `item`、`video`、`livestream`、`shop` 等）；`'__ALL__'` 表示汇总 |

---

### 指标：搜索量基础指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_uu` | bigint | 发起搜索的去重用户数（`operation=view` 且页面类型为 global_search/search_in_pdp/search_prefill） |
| `search_volume` | bigint | 搜索次数（按 user_id + device_id + keyword 去重） |

---

### 指标：即时筛选核心指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `instant_filter_uu` | bigint | 点击了即时筛选（instant_delivery/fast_delivery）的去重用户数 |
| `instant_filter_using_cnt` | bigint | 即时筛选被点击的总次数（不去重） |
| `instant_filter_imp_uu` | bigint | 即时筛选按钮被曝光的去重用户数 |
| `instant_filter_imp_cnt` | bigint | 即时筛选按钮的总曝光次数 |

---

### 指标：无结果指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `no_results_cnt` | bigint | 搜索无结果的展现总次数（含无召回页面的 impression 事件数） |
| `no_results_volume` | bigint | 搜索无结果的去重搜索量（按 user_id + device_id + keyword 去重） |
| `instant_filter_no_results_cnt` | bigint | 因使用即时筛选导致无结果的展现次数（target_type=try_diff_address 或 no_recall_with_filter 且有筛选信息） |
| `instant_filter_no_results_volume` | bigint | 因使用即时筛选导致无结果的去重搜索量 |

---

### 指标：搜索成功率

| 字段 | 类型 | 说明 |
|---|---|---|
| `direct_search_success_volume` | bigint | 直接搜索成功量：用户点击了商品/视频/直播流结果的去重搜索次数（page_section IS NULL，target_type IN item/video/livestream） |
| `broad_search_success_volume` | bigint | 宽泛搜索成功量：点击了任意结果（含 shop/creator 等）的去重搜索次数 |
| `shop_search_volume` | bigint | 进入 shop 布局（layout_type=3）的去重搜索量（按 user_id+device_id+keyword 去重） |

---

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 搜索结果卡片总曝光次数 |
| `imp_item_cnt` | bigint | 商品卡片（target_type=item）的曝光次数 |
| `imp_uu` | bigint | 曝光去重用户数 |
| `click_cnt` | bigint | 搜索结果卡片总点击次数 |
| `click_uu` | bigint | 点击去重用户数 |
| `empty_shop_imp_cnt` | bigint | shop 布局（layout_type=3）中 shop 卡片的商品坑位不足3个（空坑）的曝光次数 |

---

### 指标：转化与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 搜索归因订单数（含 source1/source2 归因，operation_cnt>0） |
| `order_uu` | bigint | 下单去重用户数 |
| `gmv` | double | 搜索归因 GMV（place_order_gmv 之和，含多级归因） |
| `avg_edt` | double | 搜索归因订单的平均预计配送时间（单位：天），关联 `dwd_edt_order_info` 计算，**不可直接 SUM** |
| `ads_rev` | double | 搜索广告收入（USD），通过 request_id+item_id 关联广告系统，含未归因部分并入 `__ALL__` |
| `shop_item_fill_rate` | double | shop 布局中商品坑位填充率，计算公式为 `item曝光数 / (shop曝光数 × 3.0)`，**不可直接 SUM**，仅在 layout_type='3' 且 card_type='__ALL__' 时有值 |

---

### 指标：全局与平台宏观指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `global_search_order_cnt` | double | 全局搜索（reporting_module='Global Search'）贡献的订单数，**仅在 address_state='\_\_ALL\_\_'、use_instant_filter_type='\_\_ALL\_\_'、layout_type='\_\_ALL\_\_'、card_type='\_\_ALL\_\_' 时有值** |
| `global_search_gmv` | double | 全局搜索贡献的 GMV，**仅在上述全汇总维度组合时有值** |
| `platform_order_cnt` | double | 平台整体订单数（来自 dwd_sr_data_warehouse_platform），**仅在全汇总维度组合时有值** |
| `platform_gmv` | double | 平台整体 GMV，**仅在全汇总维度组合时有值** |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region` 和 `local_date` 分区字段**，避免全表扫描：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2025-05-16'
  ```
- 查询特定维度组合时，建议显式过滤 `address_state`、`local_hour`、`use_instant_filter_type`、`layout_type`、`card_type`，注意使用 `'__ALL__'` 取全量汇总值，避免重复累加。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `avg_edt` | 均值指标，预聚合计算，不同行直接 SUM 无意义 |
| `shop_item_fill_rate` | 比率指标（item_imp / shop_imp × 3.0），不可叠加 |
| `ads_rev` | 含未关联广告收入特殊处理逻辑，跨行 SUM 会导致重复计算 |
| `global_search_order_cnt` / `global_search_gmv` / `platform_order_cnt` / `platform_gmv` | 仅在全汇总维度（`__ALL__`）行有值，非全汇总行为 NULL，不适合跨维度 SUM |
| `click_uu` / `imp_uu` / `order_uu` / `instant_filter_uu` / `instant_filter_imp_uu` / `search_uu` | 去重用户数（UV），多行直接 SUM 不等于总 UV |
| `search_volume` / `direct_search_success_volume` / `broad_search_success_volume` / `no_results_volume` / `instant_filter_no_results_volume` / `shop_search_volume` | 按 (user_id, device_id, keyword) 去重的搜索量，多行 SUM 会重复 |

### 维度组合注意事项

- CUBE 预聚合导致各维度取值为实际值或 `'__ALL__'`，查询时务必通过 `'__ALL__'` 取全量汇总；若与其他维度混合过滤，需小心双重计数。
- `global_search_*` 和 `platform_*` 字段**仅在 `address_state='__ALL__'` 且 `use_instant_filter_type='__ALL__'` 且 `layout_type='__ALL__'` 且 `card_type='__ALL__'` 时填充**，其余行均为 NULL。
- `shop_item_fill_rate` **仅在 `layout_type='3'` 且 `card_type='__ALL__'` 时有值**。
- `address_state='NULL'` 表示用户地址无法映射到州级别，非缺失数据。

### 时效性说明

- 本表为 `_1d` 日汇总表，T+1 更新（覆盖当日分区），不适用于实时或小时级别的实时监控。
- `local_hour` 字段保留小时维度，可分析日内分布，但完整数据需等待当日 ETL 完成。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_search` | 主要事件明细表，提供搜索的 view/click/impression/order 事件，包含关键词、筛选信息、布局类型、归因字段（source1/source2）等 |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 平台整体订单明细，用于计算 `platform_order_cnt`、`platform_gmv`、`global_search_order_cnt`、`global_search_gmv` |
| `mp_user.dim_user_address__reg_s0_live` | 用户地址维度表，用于将 address_id 映射为州/省级别（address_state） |
| `sls_mart.dwd_edt_order_info_df_${grass_region_without_quote}` | 订单预计配送时间明细，用于计算 `avg_edt` |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告绩效明细，提供广告支出金额（expenditure_amt_usd），用于计算 `ads_rev` |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_search
    ├──> dws_search_volume (搜索量基础指标)
    ├──> dwd_instant_filter_click_imp -> explode -> dws_instant_filter_click_imp (筛选曝光点击)
    ├──> dwd_no_results_metrics -> explode -> dws_no_results_metrics (无结果指标)
    ├──> dwd_direct_broad_search_volume -> explode -> dws_direct_broad_search_volume (搜索成功率)
    └──> dwd_click_imp_order_metrics (含source1/source2归因, UNION ALL)
              └──> explode
                    ├──> dws_click_imp_order_other_metrics (曝光/点击/订单/GMV)
                    ├──> dws_shop_item_fill_rate (填充率)
                    ├──> dwm_avg_edt_dim -> dws_avg_edt (平均配送时效)
                    └──> dwm_ads_revenue_link -> dws_ads_revenue (广告收入)

mp_user.dim_user_address -> user_address_state_mapping (地址映射, LEFT JOIN 于各explode view)
sls_mart.dwd_edt_order_info -> dwd_edt_order_info (配送时效, JOIN avg_edt)
mp_paidads.dwd_advertise_performance -> dwd_ads_revenue -> dwm_ads_revenue (广告收入)
dwd_sr_data_warehouse_platform -> global_search_and_platform_metrics (平台宏观)

各指标 view 经多路 FULL JOIN 合并 -> dws_main_metrics
dws_main_metrics + dws_no_results_metrics + dws_instant_filter_click_imp
  + dws_search_volume + global_search_and_platform_metrics + dws_shop_item_fill_rate
  -> INSERT OVERWRITE 目标表
```

### 关键步骤

1. **`user_address_state_mapping`**：从用户地址维表按 `grass_region`、`local_date` 提取 user_id→address_id→address_state 映射，用于后续所有指标的地址维度 JOIN。

2. **`dws_search_volume`**：从搜索明细表统计 `search_uu`、`search_volume`（`operation=view`），按 `local_hour` CUBE 生成小时及全天汇总，其余维度固定为 `'__ALL__'`。

3. **`dwd_instant_filter_click_imp` → `explode` → `dws_instant_filter_click_imp`**：抽取含即时筛选（instant_delivery/fast_delivery）的点击和曝光事件，EXPLODE 筛选数组后关联地址映射，按 `address_state + local_hour` CUBE 聚合得到 `instant_filter_uu`、`instant_filter_using_cnt`、`instant_filter_imp_uu`、`instant_filter_imp_cnt`。

4. **`dwd_no_results_metrics` → `explode` → `dws_no_results_metrics`**：抽取无结果页面（no_recall_general / no_recall_with_filter / try_diff_address）的曝光事件，EXPLODE 筛选信息后关联地址，CUBE 聚合得到 `no_results_cnt`、`no_results_volume`、`instant_filter_no_results_cnt`、`instant_filter_no_results_volume`。

5. **`dwd_direct_broad_search_volume` → `explode` → `dws_direct_broad_search_volume`**：抽取搜索点击事件，EXPLODE 后标记 `use_instant_filter_type`（true/false），按 `address_state + local_hour + use_instant_filter_type + layout_type` CUBE 聚合得到直接/宽泛搜索成功量。

6. **`dwd_click_imp_order_metrics`**：通过三路 UNION ALL 合并直接归因（主 page_type）与 source1/source2 间接归因的 impression/click/order 事件，统一字段格式后 EXPLODE 筛选数组，生成 `use_instant_filter_type` 标记。

7. **`dws_click_imp_order_other_metrics`**：在 EXPLODE 结果上关联地址映射，按 `address_state + local_hour + use_instant_filter_type + layout_type + target_type` CUBE 聚合核心指标（曝光/点击/订单/GMV/shop 相关）。

8. **`dws_shop_item_fill_rate`**：从上一步结果中，取 `layout_type='3'` 的 item 和 shop 曝光量，计算坑位填充率（`item_imp / (shop_imp × 3.0)`）。

9. **`dwm_avg_edt_dim` + `dwd_edt_order_info` → `dws_avg_edt`**：先按维度 CUBE 提取 order_id 去重列表，再关联订单配送时效表计算 `avg_edt`，避免重复 JOIN 放大。

10. **`dwm_ads_revenue_link` + `dwd_ads_revenue` → `dwm_ads_revenue` → `dws_ads_revenue`**：通过 item_id+request_id 关联搜索事件与广告绩效，未能关联的广告收入（NULL 维度）并入 `'__ALL__'` 汇总行，防止丢失。

11. **`global_search_and_platform_metrics`**：从平台订单表按 reporting_module 区分全局搜索与全平台的 order_cnt 和 GMV，按 `local_hour` CUBE 聚合。

12. **`dws_main_metrics`**：将步骤 7/9/10 产生的各 view 按五维键（address_state、local_hour、use_instant_filter_type、layout_type、card_type）FULL JOIN 合并，聚合所有主要指标。

13. **最终 INSERT OVERWRITE**：将 `dws_main_metrics`（步骤12）与 `dws_no_results_metrics`（步骤4）、`dws_instant_filter_click_imp`（步骤3）、`dws_search_volume`（步骤2）四路 FULL JOIN；再 LEFT JOIN `global_search_and_platform_metrics`（仅限 address_state='\_\_ALL\_\_' 全汇总行）和 `dws_shop_item_fill_rate`（仅限 layout_type='3' 且 card_type='\_\_ALL\_\_'），写入目标表分区。

### 注意事项

- **multi_writer = false**：仅单一 ETL 文件写入，无并发写入风险。
- **CUBE 预聚合**：多个维度组合使用 `CUBE`，所有维度的全汇总行均以 `'__ALL__'` 标识，查询时须明确区分具体维度值与汇总值，避免重复计数。
- **ads_rev 特殊归因逻辑**：未能关联到搜索事件的广告收入（NULL 维度行）被强制归入 `'__ALL__'` 聚合行，保证全汇总行的广告收入完整，但各具体维度行的 ads_rev 可能偏低（不含未关联部分）。
- **global_search / platform 指标稀疏性**：`global_search_*` 和 `platform_*` 字段通过 LEFT JOIN 且限制 address_state='\_\_ALL\_\_' 等全汇总条件，非汇总维度行均为 NULL，使用时注意 NULL 值的语义。
- **地址映射缺失**：`address_state='NULL'` 的行是正常的业务数据（地址无法定位到州级），不是数据质量问题。
- **order 三路 UNION ALL**：订单事件通过主归因 + source1 + source2 三路合并，确保跨页面归因的订单不遗漏，但 impression/click 仅来自主归因路径。

---

*文档生成时间：2026-05-17*