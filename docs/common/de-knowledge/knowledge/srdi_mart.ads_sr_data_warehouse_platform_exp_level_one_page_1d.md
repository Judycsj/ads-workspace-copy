<!-- ads-workspace-gdoc-sync: gdoc_id=1qiVRcwolWQ9yttYvsNk6lS19Ld-rvgmlAeo488B9L10 gdoc_url=https://docs.google.com/document/d/1qiVRcwolWQ9yttYvsNk6lS19Ld-rvgmlAeo488B9L10/edit -->

# srdi_mart.ads_sr_data_warehouse_platform_exp_level_one_page_1d

**分层：** ADS（应用数据层）
**主键：** `grass_region` + `local_date` + `platform` + `is_ads` + `feature_detail` + `scenario_tag` + `exp_group_id` + `exp_type` + `target_type`
**分区：** `local_date`（日期分区）、`grass_region`（地区分区）
**更新频率：** 每日（T+1）全量覆盖写入（`INSERT OVERWRITE`）
**访问频次：** 6431 次

---

## 业务描述

本表是搜推数仓平台维度的实验（A/B Test）一级页面效果汇总表，按天粒度聚合各实验分组（`exp_group_id`）在不同平台、广告标识、功能特征、场景标签下的曝光、点击、加购、下单及 GMV 等核心电商指标。

**核心业务场景：**
- 搜索/推荐算法实验效果评估：对比不同实验组在同一自然日的流量漏斗表现
- 平台级别（`platform`）、广告/自然流量（`is_ads`）维度的效果拆分
- 功能特征（`feature_detail`）和场景标签（`scenario_tag`）的分层分析
- 广告负载（`ads_load`）等平台健康指标的日常监控

**适合回答的问题：**
- 某实验组相较对照组的点击率、转化率、GMV 提升情况如何？
- 特定平台/地区在某天的曝光-点击-加购-成交漏斗各层数据是多少？
- 当日加购行为的 3 日内成交 GMV 与 GMV 总量的差距有多大？
- 各场景标签下的页面浏览（PPV）及去回跳 PPV 表现如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `local_date` | date | 数据统计日期（业务本地日期），作为分区键，查询时必须指定 |
| `grass_region` | string | 地区/站点标识（如 SG、MY、TH 等），作为分区键，查询时必须指定 |

### 维度：实验与平台维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 客户端平台，如 Android、iOS、PC 等 |
| `is_ads` | string | 是否广告流量标识，区分广告位与自然搜推位 |
| `feature_detail` | string | 功能特征明细，标识具体的算法或产品特征维度 |
| `scenario_tag` | string | 业务场景标签，如首页推荐、搜索结果页等 |
| `exp_group_id` | int | 实验分组 ID，对应 A/B 实验中的具体桶（实验组/对照组） |
| `exp_type` | string | 实验类型，标识实验的类别或层级 |
| `target_type` | string | 实验目标类型，标识实验优化的目标方向（如点击、转化等） |

### 指标：曝光与点击指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_uu` | bigint | 曝光去重用户数（UV），同一用户多次曝光只计一次 |
| `imp_cnt` | bigint | 曝光总次数（PV） |
| `imp_login_cnt` | bigint | 登录用户曝光次数 |
| `click_uu` | bigint | 点击去重用户数（UV） |
| `click_cnt` | bigint | 点击总次数（PV） |
| `click_login_cnt` | bigint | 登录用户点击次数 |
| `item_imp_uu` | bigint | 商品曝光去重用户数 |
| `item_imp_cnt` | bigint | 商品曝光总次数 |
| `item_imp_login_cnt` | bigint | 登录用户商品曝光次数 |
| `item_click_uu` | bigint | 商品点击去重用户数 |
| `item_click_cnt` | bigint | 商品点击总次数 |
| `item_click_login_cnt` | bigint | 登录用户商品点击次数 |
| `ads_load` | double | 广告负载率，广告曝光量占总曝光量的比例，不可直接 SUM |

### 指标：页面浏览（PPV）指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `ppv_uu` | bigint | 页面浏览去重用户数（Page PV UV） |
| `ppv_cnt` | bigint | 页面浏览总次数（含回跳） |
| `ppv_cnt_exclude_isback` | bigint | 排除回跳行为后的页面浏览次数，更能反映真实用户主动访问量 |

### 指标：加购指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_uu` | bigint | 加购去重用户数 |
| `cart_cnt` | bigint | 加购总次数 |

### 指标：订单与 GMV 指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_uu` | bigint | 下单去重用户数 |
| `order_cnt` | double | 下单总笔数 |
| `gmv` | double | 当日成交金额（Gross Merchandise Value） |
| `pc2_gmv` | double | PC2 口径 GMV，按特定业务口径统计的 GMV |
| `atc_same_day_order_cnt` | double | 当日加购行为在同一自然日内转化的订单数 |
| `atc_same_day_order_gmv` | double | 当日加购行为在同一自然日内转化的 GMV |
| `atc_within_3day_order_cnt` | double | 当日加购行为在 3 日内转化的订单数 |
| `atc_within_3day_gmv` | double | 当日加购行为在 3 日内转化的 GMV |

---

## 查询使用须知

### 必须包含的过滤条件

- **`local_date`** 和 **`grass_region`** 均为分区键，查询时**必须同时指定**，避免全表扫描：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2026-05-16'
  ```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `ads_load` | 广告负载率，为比率指标，跨行 SUM 无业务意义；如需汇总应回溯原始曝光量重新计算 |
| `imp_uu` / `click_uu` / `ppv_uu` / `cart_uu` / `order_uu` / `item_imp_uu` / `item_click_uu` | 去重用户数（UV），跨维度/日期累加会导致重复计数；多日 UV 需从明细层重新去重 |
| `atc_same_day_order_cnt` / `atc_within_3day_order_cnt` / `atc_same_day_order_gmv` / `atc_within_3day_gmv` | 加购归因窗口指标，存在跨日窗口重叠，直接跨天 SUM 存在重复计算风险 |

### 时效性说明

- 本表为 **每日全量快照表**（`_1d` 后缀），每天覆盖写入当天分区，通常在 T+1 完成。
- 数据代表**自然日**（`local_date`）的汇总结果，不支持小时级实时查询。
- `atc_within_3day_*` 系列字段存在 **3 日归因窗口**，查看近期数据时需注意窗口末尾数据可能不完整。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_platform_exp_base_metrics_1d` | 平台实验基础指标 DWS 层宽表，提供所有曝光、点击、加购、订单、GMV 等基础指标，本表直接透传并按分区条件筛选 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_platform_exp_base_metrics_1d
        │  （按 grass_region + local_date 分区过滤）
        ▼
srdi_mart.ads_sr_data_warehouse_platform_exp_level_one_page_1d
        （INSERT OVERWRITE 对应分区）
```

### 关键步骤

1. **单 Statement 直写目标表**：本 ETL 仅包含一条 SQL 语句，无中间 Temporary View。
2. **分区过滤**：从上游 DWS 表中按 `grass_region = ${grass_region}` 和 `local_date = ${local_date}` 筛选当日当地区数据。
3. **字段透传**：将 DWS 层的 33 个指标/维度字段直接 SELECT，无额外聚合或计算逻辑，属于 DWS→ADS 的**薄层加工**（直接透传）。
4. **目标写入**：以 `INSERT OVERWRITE` 方式写入目标表的 `(local_date, grass_region)` 分区，保证幂等性。

### 注意事项

- **单 Writer**：`multi_writer = false`，只有一个 ETL 文件写入本表，不存在多 Writer 并发冲突风险。
- **分区覆盖写入**：每次执行仅覆盖传入的 `local_date` + `grass_region` 分区，不影响其他分区历史数据。
- **无聚合逻辑**：本表逻辑极简，所有指标的口径和计算逻辑由上游 `dws_sr_data_warehouse_platform_exp_base_metrics_1d` 决定，若指标口径有疑问应向上追溯至 DWS 层。
- **参数依赖**：ETL 依赖外部传参 `${local_date}` 和 `${grass_region}`，调度时必须正确注入参数，否则会导致写入错误分区或报错。

---

*文档生成时间：2026-05-17*