<!-- ads-workspace-gdoc-sync: gdoc_id=1jPBDSoB_uar1XD7e3PrdgDJWBzceyQp448my5laD2d0 gdoc_url=https://docs.google.com/document/d/1jPBDSoB_uar1XD7e3PrdgDJWBzceyQp448my5laD2d0/edit -->

# mp_paidads.dwd_ads_request_performance_di

**分层**：DWD（明细数据层）
**主键**：`grass_date` + `grass_region` + `request_id` + `ads_id` + `user_id` + `entrance` + `placement`
**分区**：`grass_date`（本地日期）、`grass_region`（地区）
**更新频率**：每日增量 MERGE（当日新增 + 近 7 天归因回溯）
**引用频次**：0（末端 ADS 层表，未被其他候选表直接引用）

---

## 业务描述

本表是广告请求粒度的每日绩效明细表，以一次广告曝光/点击请求为最小粒度，汇聚广告投放全链路的核心指标：曝光、点击、扣费、订单转化与 GMV。每条记录唯一标识一次广告请求在特定用户、商品、广告计划、入口及投放位置上的当日表现，可支持广告效果分析、ROI 核算、投放策略优化等多种业务场景。

表中同时提供直接订单（Direct Order）和宽泛订单（Broad Order）两套归因口径，并按不同归因窗口（1h、24h、4d、7d）分别存储，方便在不同时间维度评估广告效果。此外，付费订单（Paid Order）口径进一步区分实际付款行为，三套口径互为补充，满足不同业务方对归因窗口的差异化需求。

表采用 Apache Hudi MERGE 模式写入，支持增量更新与历史回溯修正。通过 `acct_cnt` 字段可识别当天是否存在回溯写入（值 > 1 表示该分区经历过回溯），保障数据可追溯性。USD 金额字段均通过当日汇率表实时换算，各地区按本地时区参数化调度。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_date` | date | 数据分区日期（本地时区）。对于有订单归因的记录，取点击/曝光时间戳对应的本地日期；对于纯曝光/点击记录，取原始 `grass_date` |
| `grass_region` | string | 地区编码，如 `ID`、`TH`、`MY` 等，各地区独立调度 |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `request_id` | string | 广告请求唯一标识（主键之一） |
| `ads_id` | bigint | 广告计划 ID（主键之一） |
| `campaign_id` | bigint | 广告活动 ID |
| `item_id` | bigint | 广告关联商品 ID |
| `user_id` | bigint | 用户 ID（主键之一） |
| `shop_id` | bigint | 店铺 ID |
| `entrance` | bigint | 广告入口（主键之一），如搜索、首页、商品详情页等 |
| `entrance_group` | string | 入口分组，入口的聚合分类描述 |
| `placement` | bigint | 广告投放位置（主键之一） |
| `pricing_type` | int | 广告计费类型，如 CPC、CPM 等 |
| `target_type` | string | 广告定向类型 |
| `page_type` | string | 广告所在页面类型 |
| `keyword` | string | 搜索关键词（适用于搜索广告场景） |
| `query` | string | 用户实际搜索词 |
| `raw_request_id` | string | 原始请求 ID |

---

### 维度：商品与店铺属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_price` | double | 商品价格（已除以 100000），来自 tracking，取 `max(item_price)` ⚠️ 为 max 聚合值，非加总指标，不可直接 SUM |
| `item_price_shop` | double | 店铺内商品的估计平均价格（已除以 100000）⚠️ 为模型预估值，不可直接 SUM |
| `organic_location` | bigint | 商品在包含广告和自然结果的完整列表中的排名位置，从 0 开始 |
| `sold_cnt_per_order` | bigint | 每单销售商品数量，来自 tracking 的 `max(sold_cnt_per_order)`，**已废弃**（deprecated）⚠️ 字段已废弃，请勿用于新开发 |
| `level1_global_be_category` | string | 全球一级后端类目名称（当前版本 ETL 中为 null，暂未填充）⚠️ 当前为 null，暂不可用 |
| `level1_global_be_category_id` | bigint | 全球一级后端类目 ID（当前版本 ETL 中为 null）⚠️ 当前为 null，暂不可用 |
| `level2_global_be_category` | string | 全球二级后端类目名称（当前版本 ETL 中为 null）⚠️ 当前为 null，暂不可用 |
| `level2_global_be_category_id` | bigint | 全球二级后端类目 ID（当前版本 ETL 中为 null）⚠️ 当前为 null，暂不可用 |
| `avg_sold_cnt_item` | double | 单商品维度平均销量（当前版本 ETL 中固定为 0）⚠️ 当前为 0，暂不可用 |
| `avg_sold_cnt_shop` | double | 店铺维度平均销量（当前版本 ETL 中固定为 0）⚠️ 当前为 0，暂不可用 |
| `image_id` | string | 广告图片 ID |
| `video_id` | string | 广告视频 ID |

---

### 维度：模型与算法属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `pctr` | double | 预估点击率（pCTR），来自 tracking `max(item_json_data.pCTR)`⚠️ 为模型预估比率，不可直接 SUM；当前 ETL 固定填 0，来自 tracking 的实际值仅在其他来源写入时更新 |
| `pcr` | double | 预估转化率（pCR），来自 tracking `max(item_json_data.pCR)`⚠️ 为模型预估比率，不可直接 SUM |
| `direct_pcr` | double | 直接转化率预估，来自 tracking `max(item_json_data.extra_json.direct_pcr)`⚠️ 为模型预估比率，不可直接 SUM |
| `broad_pcr` | double | 宽泛转化率预估，来自 tracking `max(item_json_data.broad_pcr)`⚠️ 为模型预估比率，不可直接 SUM |
| `pcr_1d` | double | 预估值：当天点击并购买同款商品的转化率⚠️ 为模型预估比率，不可直接 SUM |
| `pcr_delay` | double | 预估值：6 天前点击、当日购买同款商品的转化率⚠️ 为模型预估比率，不可直接 SUM |
| `pcr_shop` | double | 预估值：点击同店铺广告后在店内购买其他商品的转化率⚠️ 为模型预估比率，不可直接 SUM |
| `rank` | bigint | 广告排名，来自 tracking `max(item_json_data.rank)` ⚠️ 为 max 聚合值，不可直接 SUM |
| `rank_score` | double | 广告排序分数，来自 tracking `max(item_json_data.rank_score)` ⚠️ 为 max 聚合值，不可直接 SUM |
| `target_cir` | double | 目标 CIR（Cost Income Ratio），来自 tracking `max(target_cir)` ⚠️ 为目标比率值，不可直接 SUM |
| `sub_entrance` | bigint | 子入口，来自 tracking `max(sub_entrance)` |
| `algo_json_data` | string | 算法 JSON 数据，来自 tracking（当前 ETL 版本为 null）⚠️ 当前为 null，暂不可用 |
| `uni_pcr_model_name` | string | 统一 pCR 模型名称（当前 ETL 版本为 null）⚠️ 当前为 null，暂不可用 |
| `pid_coef` | double | PID 系数（当前 ETL 版本为 null）⚠️ 当前为 null，暂不可用 |
| `ab_sign` | string | AB 实验标识（当前 ETL 版本为 null）⚠️ 当前为 null，暂不可用 |
| `plan_bucket_list` | array\<bigint\> | 计划桶列表，使用 max 聚合，非累加字段 ⚠️ 为数组类型，不可直接 SUM；MERGE 时以 source 值覆盖 target |
| `page_view` | bigint | 页面浏览量（注：ETL 中此字段被聚合进 `pdp_view`，本字段来自上游原始值） |
| `is_ocpm` | boolean | 是否为 oCPM 计费模式 |
| `bid_rerank_trace` | string | 竞价重排序追踪信息（当前 ETL 版本为 null）⚠️ 当前为 null，暂不可用 |
| `deduction_reason` | string | 扣费原因说明 |
| `deduct_unique_id` | string | 扣费唯一标识 |
| `new_product_boost_coef` | double | 新品加速系数，来自 tracking `max(new_product_boost_coef)` ⚠️ 为 max 聚合值，不可直接 SUM |
| `new_product_boost_stage` | bigint | 新品加速阶段，来自 tracking `max(new_product_boost_stage)` ⚠️ 为 max 聚合值，不可直接 SUM |
| `new_product_boost_tier` | bigint | 新品加速档位，来自 tracking `max(item_json_data.new_product_boost_stage)`（当前 ETL 版本固定为 0）⚠️ 当前为 0，暂不可用 |
| `first_impression_timestamp` | bigint | 首次曝光时间戳（当前 ETL 版本为 null）⚠️ 当前为 null，暂不可用 |
| `first_click_timestamp` | bigint | 首次点击时间戳（当前 ETL 版本为 null）⚠️ 当前为 null，暂不可用 |

---

### 维度：Voucher（优惠券）相关

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_voucher` | struct<...> | 商品优惠券详情，来自 tracking `max(item_voucher)`，包含最优券信息、折扣金额、有效期等⚠️ 为复杂 struct 类型，需展开子字段使用，不可直接聚合 |
| `display_ads_voucher_label` | int | 广告优惠券展示标签（当前 ETL 版本固定为 0） |
| `ads_voucher_auto_claimed` | bigint | 广告自动领券数量；MERGE 时以 source 值覆盖（非累加）⚠️ MERGE 策略为覆盖而非累加，与其他计数字段不同 |
| `is_auto_claimed_just_now` | int | 是否为刚刚自动领取的优惠券（当前 ETL 版本固定为 0） |
| `bid_voucher_id` | bigint | ROI3 Voucher 对应的竞价优惠券 ID，来自 tracking（当前 ETL 版本固定为 0）⚠️ 当前为 0，暂不可用 |
| `pcr_v` | double | ROI3 Voucher 场景的 pCR，来自 tracking（当前 ETL 版本固定为 0）⚠️ 为模型预估比率，当前为 0 |
| `pctr_v` | double | ROI3 Voucher 场景的 pCTR，来自 tracking（当前 ETL 版本固定为 0）⚠️ 为模型预估比率，当前为 0 |
| `broad_pcr_v` | double | ROI3 Voucher 场景的宽泛 pCR，来自 tracking（当前 ETL 版本固定为 0）⚠️ 为模型预估比率，当前为 0 |
| `bid_price_0` | double | ROI3 Voucher 场景竞价价格（已除以 100000），来自 tracking（当前 ETL 版本固定为 0）⚠️ 当前为 0，暂不可用 |
| `deduction_price_0` | double | ROI3 Voucher 场景扣费价格（已除以 100000），来自 tracking（当前 ETL 版本固定为 0）⚠️ 当前为 0，暂不可用 |
| `voucher_deduction_price` | double | ROI3 Voucher 场景优惠券扣费金额（已除以 100000），来自 tracking（当前 ETL 版本固定为 0）⚠️ 当前为 0，暂不可用 |

---

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|------|------|------|
| `impression_cnt` | bigint | 原始曝光次数（当前 ETL 版本固定为 0，由其他流程填充）⚠️ 当前 ETL 版本固定为 0，请确认数据来源 |
| `dedup_impression_cnt` | bigint | 去重曝光次数（当前 ETL 版本固定为 0）⚠️ 当前 ETL 版本固定为 0，请确认数据来源 |
| `deduct_impression_cnt` | bigint | 有效扣费曝光次数（CPM 计费时触发扣费的曝光量） |
| `click_cnt` | bigint | 原始点击次数（当前 ETL 版本固定为 0，由其他流程填充）⚠️ 当前 ETL 版本固定为 0，请确认数据来源 |
| `dedup_click_cnt` | bigint | 去重点击次数（当前 ETL 版本固定为 0）⚠️ 当前 ETL 版本固定为 0，请确认数据来源 |
| `deduct_click_cnt` | bigint | 有效扣费点击次数（CPC 计费时实际触发扣费的点击量） |
| `cps_dedup_click` | bigint | CPS 去重点击次数 |
| `deduplicated_click` | bigint | 去重后的点击量 |
| `pdp_view` | bigint | 商品详情页（PDP）浏览次数，由上游 `page_view` 字段聚合而来 |
| `bidprice` | double | 竞价价格（已除以 100000），来自 tracking `max(internal.deduction_info.bidprice)`⚠️ 为 max 聚合值，不可直接 SUM |
| `deduction_price` | double | 实际扣费单价（已除以 100000），来自 tracking `max(internal.deduction_info.deduction_price)`⚠️ 为 max 聚合值，不可直接 SUM |

---

### 指标：广告花费

| 字段 | 类型 | 说明 |
|------|------|------|
| `expenditure_amt_local` | double | 广告扣费金额（本地货币），由上游 `expenditure_amt_local` 或 `expense_by_cpm` 合并计算 |
| `expenditure_amt_usd` | double | 广告扣费金额（USD），由本地货币除以当日汇率换算⚠️ 依赖当日汇率表，跨日比较需注意汇率波动 |
| `deduct_order_cnt` | bigint | 扣费订单数量 |

---

### 指标：直接订单（Direct Order，7 天归因窗口）

| 字段 | 类型 | 说明 |
|------|------|------|
| `direct_order_cnt` | bigint | 直接订单数（7 天归因窗口）：用户点击广告商品后 7 天内购买该商品的订单数 |
| `direct_item_cnt` | bigint | 直接订单商品件数 |
| `direct_gmv_amt_local` | double | 直接订单 GMV（本地货币）；GMV 使用订单价格，仅含商品折扣和捆绑促销，不含运费、平台补贴、优惠券等 |
| `direct_gmv_amt_usd` | double | 直接订单 GMV（USD）⚠️ 依赖当日汇率换算 |
| `direct_order_cnt_1h` | bigint | 点击后 1 小时内的直接订单数 |
| `direct_order_gmv_local_1h` | double | 点击后 1 小时内的直接订单 GMV（本地货币） |
| `direct_order_gmv_usd_1h` | double | 点击后 1 小时内的直接订单 GMV（USD） |
| `direct_order_cnt_24h` | bigint | 点击后 24 小时内的直接订单数 |
| `direct_order_gmv_local_24h` | double | 点击后 24 小时内的直接订单 GMV（本地货币） |
| `direct_order_gmv_usd_24h` | double | 点击后 24 小时内的直接订单 GMV（USD） |
| `direct_order_cnt_4d` | bigint | 点击后 4 天内的直接订单数 |
| `direct_order_gmv_local_4d` | double | 点击后 4 天内的直接订单 GMV（本地货币） |
| `direct_order_gmv_usd_4d` | double | 点击后 4 天内的直接订单 GMV（USD） |

---

### 指标：宽泛订单（Broad Order，7 天归因窗口）

| 字段 | 类型 | 说明 |
|------|------|------|
| `broad_order_cnt` | bigint | 宽泛订单数（7 天归因窗口）：用户点击广告后在同一店铺购买任意商品的订单数，口径详见 Confluence |
| `broad_item_cnt` | bigint | 宽泛订单商品件数 |
| `broad_gmv_amt_local` | double | 宽泛订单 GMV（本地货币） |
| `broad_gmv_amt_usd` | double | 宽泛订单 GMV（USD）⚠️ 依赖当日汇率换算 |
| `broad_order_1d` | bigint | 当天点击当天成交的宽泛订单数（同日归因） |
| `broad_order_cnt_1h` | bigint | 点击后 1 小时内的宽泛订单数 |
| `broad_order_gmv_local_1h` | double | 点击后 1 小时内的宽泛订单 GMV（本地货币） |
| `broad_order_gmv_usd_1h` | double | 点击后 1 小时内的宽泛订单 GMV（USD） |
| `broad_order_cnt_24h` | bigint | 点击后 24 小时内的宽泛订单数 |
| `broad_order_gmv_local_24h` | double | 点击后 24 小时内的宽泛订单 GMV（本地货币） |
| `broad_order_gmv_usd_24h` | double | 点击后 24 小时内的宽泛订单 GMV（USD） |
| `broad_order_cnt_4d` | bigint | 点击后 4 天内的宽泛订单数 |
| `broad_order_gmv_local_4d` | double | 点击后 4 天内的宽泛订单 GMV（本地货币） |
| `broad_order_gmv_usd_4d` | double | 点击后 4 天内的宽泛订单 GMV（USD） |

---

### 指标：付费订单（Paid Order）

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_order_cnt` | bigint | 付费订单数（实际付款口径） |
| `paid_order_cnt_24h` | bigint | 点击/曝光后 24 小时内完成付款的订单数 |
| `paid_order_gmv_local` | double | 付费订单 GMV（本地货币） |
| `paid_order_gmv_usd` | double | 付费订单 GMV（USD）⚠️ 依赖当日汇率换算 |
| `paid_order_gmv_local_24h` | double | 24 小时内付款的订单 GMV（本地货币） |
| `paid_order_gmv_usd_24h` | double | 24 小时内付款的订单 GMV（USD）⚠️ 依赖当日汇率换算 |
| `paid_broad_order_cnt` | bigint | 付费宽泛订单数 |
| `paid_broad_order_gmv_local` | double | 付费宽泛订单 GMV（本地货币） |
| `paid_broad_order_gmv_usd` | double | 付费宽泛订单 GMV（USD） |

---

### 指标：当日订单（Daily，点击当日归因）

| 字段 | 类型 | 说明 |
|------|------|------|
| `daily_order_cnt` | bigint | 与点击同日发生的直接订单数 |
| `daily_item_cnt` | bigint | 与点击同日发生的直接订单商品件数 |
| `daily_gmv_amt_local` | double | 与点击同日发生的直接订单 GMV（本地货币） |
| `daily_gmv_amt_usd` | double | 与点击同日发生的直接订单 GMV（USD）⚠️ 依赖当日汇率换算 |

---

### 指标：数据质量与回溯标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `acct_cnt` | bigint | 分区写入累计次数标识。值为 1 表示首次正常写入；值 > 1 表示该分区存在回溯（重跑）⚠️ 不代表业务计数，不可用于指标计算；仅作数据质量监控用途 |

---

### Hudi 内部字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `_hoodie_commit_time` | string | Hudi 提交时间戳，框架内部字段 |
| `_hoodie_commit_seqno` | string | Hudi 提交序列号，框架内部字段 |
| `_hoodie_record_key` | string | Hudi 记录主键，框架内部字段 |
| `_hoodie_partition_path` | string | Hudi 分区路径，框架内部字段 |
| `_hoodie_file_name` | string | Hudi 文件名，框架内部字段 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须指定分区过滤条件**，否则将触发全表扫描，造成严重资源浪费：

```sql
-- 必须同时指定 grass_date 和 grass_region
WHERE grass_date = '2024-01-15'
  AND grass_region = 'ID'
```

| 过滤字段 | 说明 | 遗漏后果 |
|----------|------|----------|
| `grass_date` | 必须指定具体日期或日期范围 | 扫描全量历史分区，性能极差且费用极高 |
| `grass_region` | 必须指定地区编码 | 跨地区数据混合，指标口径错误 |

> **注意**：本表不存在 `tz_type` 字段（该字段已在上游 `dwd_advertise_performance_di` 中过滤为 `local` 后写入本表），无需在本表再次过滤时区类型。

---

### 不可直接 SUM 的字段

以下字段为模型预估值、max 聚合值或特殊存储格式，**不得直接 SUM**：

| 字段 | 类型 | 正确使用方式 |
|------|------|-------------|
| `pctr`、`pcr`、`direct_pcr`、`broad_pcr`、`pcr_1d`、`pcr_delay`、`pcr_shop`、`pcr_v`、`pctr_v`、`broad_pcr_v` | 预估比率 | 按业务逻辑使用加权平均，分子=实际转化，分母=实际曝光/点击 |
| `target_cir` | 目标比率 | 直接读取单行值，不做跨行 SUM |
| `bidprice`、`deduction_price`、`bid_price_0`、`deduction_price_0`、`voucher_deduction_price` | 单次 max 价格 | 分析均值时应 `AVG()`，不可 `SUM()` |
| `item_price`、`item_price_shop` | 单商品价格/店铺均价 | 分析时应 `AVG()` 或与件数相乘后汇总 |
| `rank`、`rank_score` | max 排名/评分 | 分析时应 `AVG()` 或 `MIN()`，不可 `SUM()` |
| `new_product_boost_coef` | max 系数 | 分析时应 `AVG()`，不可 `SUM()` |
| `new_product_boost_stage`、`new_product_boost_tier` | max 枚举值 | 按枚举分组使用，不可 `SUM()` |
| `item_voucher` | struct 复杂类型 | 需使用 `.` 访问子字段，不可聚合整体字段 |
| `plan_bucket_list` | array 类型 | 需 `EXPLODE()` 展开后使用 |
| `acct_cnt` | 回溯计数 | 仅用于数据质量判断（值 > 1 表示有回溯），不参与业务指标计算 |
| `ads_voucher_auto_claimed` | MERGE 覆盖字段 | MERGE 策略为 source 覆盖 target（非累加），跨分区 SUM 时需注意语义 |

---

### 时效性说明

本表采用 **MERGE 增量写入 + 近 7 天归因回溯**机制，存在以下时效性注意事项：

1. **归因窗口回溯**：某一天点击产生的订单，可能在点击后 7 天内陆续归因回写到点击日的分区，因此**近 7 天的历史分区数据仍处于持续更新状态**。建议分析近期数据时以 **T-8 及更早**的分区数据为准，确保归因完整。

2. **回溯识别**：通过 `acct_cnt > 1` 可判断某个分区是否发生过数据回溯重写，可用于数据质量监控。

3. **1h / 24h / 4d 多窗口字段**：这些字段是按归因事件时间戳与点击时间的差值在 ETL 中预计算的，反映的是不同归因窗口的截面数据，不存在相互包含的累加关系。如需计算 ROI，推荐使用 `direct_order_cnt`（7 天全窗口）作为主指标，短窗口字段仅用于实时效果监控。

4. **USD 字段汇率**：所有 `_usd` 后缀字段均使用**写入当日汇率**换算，跨日或跨月比较时需注意汇率波动可能带来的扰动。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告绩效明细宽表，提供点击、曝光、订单、GMV 等所有核心业务指标的原始明细数据 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供各地区当日本地货币对 USD 的汇率，用于换算 USD 金额字段 |

---

## ETL 逻辑摘要

### 数据流

```
mp_order.dim_exchange_rate__reg_s0_live
     (当日汇率，按地区过滤)
              │
              │  LEFT JOIN on grass_region
              ▼
mp_paidads.dwd_advertise_performance_di__reg_s0_live
     (tz_type='local', 当日分区, item_id IS NOT NULL)
     (过滤条件: 点击/曝光/订单归因事件)
              │
              │  GROUP BY (ads_id, campaign_id, item_id, user_id,
              │            request_id, shop_id, entrance, pricing_type,
              │            placement, grass_date_derived, grass_region)
              │
              ▼  source CTE（汇率换算 + 字段标准化 + 时间窗口预计算）
              │
              │  MERGE INTO（主键匹配则 UPDATE 累加，否则 INSERT）
              ▼
mp_paidads.dwd_ads_request_performance_di__reg_s0_live
     (Hudi MOR 表，按 grass_date / grass_region 分区)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `exchange_rate` | `mp_order.dim_exchange_rate__reg_s0_live` | 获取指定地区当日汇率，供后续 USD 金额换算 |
| `source`（内嵌子查询） | `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 按主键维度聚合原始明细数据，计算各时间窗口（1h/24h/4d/7d）订单指标，JOIN 汇率后生成待 MERGE 的标准化数据集 |

### 注意事项

1. **归因日期的特殊派生逻辑**：`grass_date` 字段在 ETL 中并非直接取上游的分区日期，而是根据记录是否含有订单归因事件动态派生：
   - 若记录含有宽泛订单、付费订单或 `deduct_order > 0` 等归因事件，则 `grass_date` 取点击/曝光时间戳对应的本地日期（`from_unixtime(click_timestamp, 'yyyy-MM-dd')`）；
   - 若记录仅含曝光/点击行为（无订单归因），则 `grass_date` 直接取上游分区的 `grass_date`。
   - **实际影响**：同一批次数据会写入不同日期分区，尤其归因回溯场景下会出现一个上游分区的数据写入最近 7 天的不同目标分区。

2. **上游过滤条件口径**：ETL 从上游表过滤时要求 `tz_type = 'local'`，即本表所有数据均为本地时区口径。此外，订单归因事件要求点击/曝光时间戳在 `grass_date` 之前 7 天以内，避免引入过远历史归因数据。

3. **MERGE 策略差异**：大多数指标字段采用累加（`target + source`）更新，但以下字段例外：
   - `ads_voucher_auto_claimed`：以 source 值**覆盖** target，非累加；
   - `plan_bucket_list`：以 source 值**覆盖** target，非累加；
   - Hudi 内部字段（`_hoodie_*`）在 source CTE 中初始化为 null，由 Hudi 框架自动维护。

4. **多个字段当前为占位零值或 null**：包括 `pctr`、`pcr`、`rank`、`item_price` 等来自 tracking 的模型字段，以及 `level1/level2_global_be_category*` 等类目字段，在当前 ETL 版本中均固定为 0 或 null，由其他流程（tracking 路径）负责填充，使用时需注意数据完整性。

5. **`click_cnt` 与 `impression_cnt` 固定为 0**：本 ETL 流程仅处理来自 OA（订单归因）路径的数据，原始曝光/点击计数由独立流程写入，本表中这两个字段固定为 0，实际曝光/点击应使用 `deduct_impression_cnt` 和 `deduct_click_cnt`。

---

*文档生成时间：2026-05-20*