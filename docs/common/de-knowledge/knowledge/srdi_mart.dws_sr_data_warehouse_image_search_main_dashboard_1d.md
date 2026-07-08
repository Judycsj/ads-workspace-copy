<!-- ads-workspace-gdoc-sync: gdoc_id=1l8g-ejd1aaKgr92oExKUtICboUSL-5d1g6Y-Oxeu8I8 gdoc_url=https://docs.google.com/document/d/1l8g-ejd1aaKgr92oExKUtICboUSL-5d1g6Y-Oxeu8I8/edit -->

# srdi_mart.dws_sr_data_warehouse_image_search_main_dashboard_1d

**分层：** DWS（数据服务层 / dws_search）
**主键：** `grass_region` + `local_date` + `platform` + `is_ads`
**分区：** `grass_region`（string）、`local_date`（date）
**更新频率：** 每日（T+1 全量覆盖写，`INSERT OVERWRITE`）
**引用频次 / 访问频次：** 59

---

## 业务描述

本表为**图片搜索（以图搜货）主看板日粒度汇总表**，面向搜推数仓的 BI 报表与业务监控场景。

表中每一行代表特定地区（`grass_region`）、日期（`local_date`）、平台（`platform`）及是否广告流量（`is_ads`）组合下，图片搜索全链路的关键业务指标汇总。当前 `platform` 固定取值 `__ALL__`（即全平台汇总），`is_ads` 支持 `true`/`false`/`__ALL__` 三类维度切片。

**核心业务场景：**
- 图片搜索日常核心指标监控（用户规模、曝光、转化漏斗、GMV）
- 图片搜索广告 vs 非广告流量对比分析
- 图片搜索结果质量追踪（Top1 相似度、点击/加购位置均值）
- 图片搜索流量健康度监控（有结果量 vs 无结果量、搜索次数）

**适合回答的问题：**
- 某地区某日图片搜索的 DAU、相机唤起 UU 是多少？
- 图片搜索的曝光→点击→加购→下单各环节转化 UU 情况如何？
- 广告与自然流量在 GMV 和订单量上的差异？
- Top1 结果相似度趋势如何？无结果率是否异常？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 业务大区（如 SG、MY、TH 等），分区键 |
| `local_date` | date | 业务日期（本地时间），分区键 |

### 维度：平台与流量类型

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 平台维度，当前固定为 `__ALL__`（全平台汇总） |
| `is_ads` | string | 是否广告流量；取值：`true`（广告）、`false`（非广告）、`__ALL__`（全量汇总，对应 GROUPING SETS 的总计行） |

### 指标：用户规模

| 字段 | 类型 | 说明 |
|---|---|---|
| `dau` | bigint | 图片搜索 DAU；`image_search_pv > 0` 的去重用户数 |
| `camera_uu` | bigint | 相机/图搜入口唤起 UU；`image_search_button_click_cnt > 0` 的去重用户数 |
| `landing_rate_dau` | bigint | 从特定入口（搜索结果页、首页、商城等）进入图片搜索的去重用户数，用于计算着陆率分母 |

### 指标：曝光与浏览

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 图片搜索商品曝光总次数（`image_search_item_imp_cnt` 求和） |
| `imp_uu` | bigint | 有商品曝光的去重用户数（`image_search_item_imp_cnt > 0`） |
| `ppv_cnt` | bigint | 商品详情页（PDP）浏览总次数（`pdp_pv` 求和） |
| `ppv_uu` | bigint | 有 PDP 浏览的去重用户数（`pdp_pv > 0`） |

### 指标：转化漏斗

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | double | 加购总次数（`cart_cnt` 求和） |
| `cart_uu` | bigint | 有加购行为的去重用户数（`cart_cnt > 0`） |
| `order_cnt` | double | 下单总次数（`order_cnt` 求和） |
| `order_uu` | bigint | 有下单行为的去重用户数（`order_cnt > 0`） |
| `gmv` | double | 图片搜索带来的 GMV（`gmv` 求和） |
| `eff_trans_uu` | bigint | 有效交互用户数；`image_search_item_click_cnt > 0 OR pdp_like_button_click_cnt > 0 OR cart_cnt > 0` 的去重用户数 |

### 指标：搜索质量

| 字段 | 类型 | 说明 |
|---|---|---|
| `avg_top1_similarity` | double | Top1 结果平均相似度；`sum(top1_similarity_sum) / sum(top1_item_impression_cnt)`，预聚合比率，**不可直接 SUM** |
| `avg_click_location` | double | 平均点击位置；`sum(click_location_sum) / sum(image_search_item_click_cnt)`，预聚合比率，**不可直接 SUM** |
| `avg_atc_location` | double | 平均加购位置；ETL 中对应 `avg_cart_location`，即 `sum(atc_location_sum) / sum(cart_cnt)`，预聚合比率，**不可直接 SUM** |

### 指标：搜索流量

| 字段 | 类型 | 说明 |
|---|---|---|
| `query_cnt` | bigint | 图片搜索总请求次数（`query_cnt` 求和） |
| `image_search_result_volume` | bigint | 有搜索结果的请求量（`image_search_result_volume` 求和） |
| `image_search_non_result_volume` | bigint | 无搜索结果的请求量（`image_search_non_result_volume` 求和） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区裁剪**：查询时务必同时过滤 `grass_region` 和 `local_date`，否则将触发全表扫描：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2025-01-01'
  ```
- **is_ads 过滤**：若只关注全量汇总，需加 `AND is_ads = '__ALL__'`；若需广告/非广告拆分，则分别过滤 `'true'`/`'false'`，**避免重复计算**（`__ALL__` 行与 `true`/`false` 行均存在，对同一天数据求和会导致重复）。

### 不可直接 SUM 的字段

以下字段为**预聚合比率/均值**，跨行 SUM 无业务意义，如需多日汇总须回溯上游明细表重新计算：

| 字段 | 原因 |
|---|---|
| `avg_top1_similarity` | `sum(top1_similarity_sum) / sum(top1_item_impression_cnt)` 的商 |
| `avg_click_location` | `sum(click_location_sum) / sum(image_search_item_click_cnt)` 的商 |
| `avg_atc_location` | `sum(atc_location_sum) / sum(cart_cnt)` 的商 |

以下字段为**去重 UU 类指标**，跨分区（多日、多地区）SUM 会造成重复计数：

`dau`、`camera_uu`、`landing_rate_dau`、`imp_uu`、`ppv_uu`、`cart_uu`、`order_uu`、`eff_trans_uu`

### 时效性说明

- 本表为 **`_1d` 日粒度**汇总表，每日 T+1 产出，反映前一自然日数据。
- 采用 `INSERT OVERWRITE` 分区写入，同一分区每日仅有一次写入，无增量追加风险。
- 不包含实时或准实时数据，不适用于当日数据查询。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_image_search_entrance_user_metrics_1d` | 图片搜索用户粒度日明细指标表，提供每用户的曝光、点击、加购、下单、GMV、相似度等行为指标，经聚合后写入本表 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_image_search_entrance_user_metrics_1d
    （按 grass_region、local_date 过滤，用户粒度明细）
        ↓ GROUPING SETS((is_ads), ()) 聚合
    临时视图 image_search_main_aggregated_${grass_region_without_quote}
        ↓ is_ads 类型转换 + platform 常量补全
    srdi_mart.dws_sr_data_warehouse_image_search_main_dashboard_1d
        （按 grass_region、local_date 分区 OVERWRITE）
```

### 关键步骤

**Step 1 — 创建临时聚合视图**

从上游用户指标明细表中按 `is_ads` 以 `GROUPING SETS((is_ads), ())` 分组聚合，一次产出两类行：
- `is_ads = true/false`：广告与非广告分别汇总
- `is_ads = NULL`（总计行）：全量汇总

聚合内容包括：去重 UU 类指标（`COUNT DISTINCT`）、累加类指标（`SUM`）、及比率分子分母相除得到均值字段。

**Step 2 — INSERT OVERWRITE 写目标表**

从临时视图读取数据，补充以下处理后写入目标分区：
- `platform` 固定赋值为 `'__ALL__'`（全平台）
- `is_ads` 将布尔类型转换为字符串：`true → 'true'`、`false → 'false'`、`NULL → '__ALL__'`
- 以 `grass_region`、`local_date` 为分区键执行 `INSERT OVERWRITE`，每次运行全量覆盖该分区数据

### 注意事项

- **单写入源**：本表仅有 1 个 ETL 文件，无 multi-writer 风险，每次只覆盖当次参数指定的分区。
- **GROUPING SETS 导致行重叠**：目标表同一 `grass_region + local_date` 下同时存在 `is_ads = '__ALL__'` 的全量汇总行与 `'true'`/`'false'` 明细行，查询时必须指定 `is_ads` 维度，避免多行相加导致指标虚高。
- **字段名差异**：ETL 中聚合字段为 `avg_cart_location`，DataMap 中对应字段名为 `avg_atc_location`，两者为同一指标，使用时以 DataMap 字段名为准。
- **参数化分区**：ETL 通过 `${grass_region}`、`${local_date}` 等 Shell 变量控制分区范围，每次调度仅处理单一地区单一日期，历史数据补跑需按分区逐一回刷。

---

*文档生成时间：2026-05-17*