<!-- ads-workspace-gdoc-sync: gdoc_id=1NHQNv-u01Dt7ikFiB-K8E0y1nBqEtmRX7xcF0Hjdgws gdoc_url=https://docs.google.com/document/d/1NHQNv-u01Dt7ikFiB-K8E0y1nBqEtmRX7xcF0Hjdgws/edit -->

# srdi_mart.dwd_sr_data_warehouse_search_unify_full_link_log_1h

**分层：** DWD（明细数据层）
**主键：** `request_id` + `item_id`（联合唯一标识一条召回/排序链路记录）
**分区：** `regional_date`（日期分区）、`regional_hour`（小时分区）、`country`（国家/地区分区）
**更新频率：** 每小时覆盖写入（INSERT OVERWRITE，小时级准实时）
**引用频次/访问频次：** 6825 次
**字段数：** 67

---

## 业务描述

本表是搜索全链路（Full Link Log）的统一明细宽表，以**小时粒度**记录搜索请求中每个候选商品/广告在各个排序阶段的处理信息，覆盖召回（Recall）、预排序（PreRank）、精排（Rank）、混排（MixRank）、下发（Dispatch）五大阶段。

**核心业务场景：**
- 搜索漏斗分析：追踪每个 item 在各阶段的进入/淘汰情况，计算各阶段通过率
- 排序模型效果评估：对比各阶段的 pCTR、pCVR、eCPM、相关性分数等预估值
- 广告全链路追踪：关联广告竞价、扣费、召回扩展信息，分析广告在搜索漏斗中的表现
- AB 实验分析：结合 `ab_sign` 对不同实验组的搜索效果进行对比
- 虚拟商品/店铺映射分析：通过 `ritem_id`、`rshop_id` 等字段追踪虚拟商品链路

**适合回答的问题：**
- 某小时内指定国家的搜索召回量、预排序量、精排量、下发量各为多少？
- 特定 query 下，商品在各排序阶段的分数分布如何？
- 广告商品在混排阶段的 eCPM 及 pCTR 表现如何？
- 某次请求（request_id）中，每个候选商品经历了哪些排序阶段？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `regional_date` | date | 数据所属区域日期（按 country 时区归一化），分区键 |
| `regional_hour` | string | 数据所属区域小时（格式如 `'00'`～`'23'`），分区键 |
| `country` | string | 国家/地区标识（如 `SG`、`MY` 等），分区键 |

### 维度：请求与用户信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `request_id` | string | 搜索请求唯一标识，与 `item_id` 共同构成行级主键 |
| `session_id` | string | 用户会话 ID |
| `user_id` | bigint | 用户 ID |
| `query` | string | 用户搜索关键词（来源：`biz_info.search_info.keyword`） |
| `ab_sign` | array\<int\> | AB 实验分组标识数组，用于实验效果区分 |

### 维度：商品与店铺信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_id` | bigint | 候选商品 ID |
| `shop_id` | bigint | 商品所属店铺 ID |
| `item_type` | string | 商品类型标识 |
| `ctx_item_type` | int | 上下文商品类型（虚拟商品场景使用） |
| `ritem_id` | bigint | 虚拟商品对应的真实商品 ID |
| `rshop_id` | int | 虚拟商品对应的真实店铺 ID（int 版本） |
| `rshop_id_v2` | bigint | 虚拟商品对应的真实店铺 ID（bigint 升级版本） |
| `rmodel_id` | bigint | 虚拟商品对应的真实模型 ID |
| `vmodel_id` | bigint | 虚拟模型 ID（当前 ETL 中固定写入 null，待补充） |

### 维度：广告信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告计划 ID |
| `ads_real_item_id` | bigint | 广告实际关联的商品 ID（与 `item_id` 可能不同） |

### 维度：阶段标志位

| 字段 | 类型 | 说明 |
|------|------|------|
| `is_recall` | boolean | 该 item 是否进入召回阶段（recall_info 不为 null） |
| `is_prerank` | boolean | 该 item 是否进入预排序阶段（prerank_info 不为 null） |
| `is_rank` | boolean | 该 item 是否进入精排阶段（rank_info 不为 null） |
| `is_mixrank` | boolean | 该 item 是否进入混排阶段（mixrank_info 不为 null） |
| `is_dispatch` | boolean | 该 item 是否最终下发（final_stage = 'DISPATCH'） |
| `is_cached` | boolean | 是否命中缓存（当前 ETL 固定写入 false，逻辑待补充） |
| `is_sampled` | boolean | 是否为广告全链路采样样本（来源：`sample_info.full_link_ads`） |
| `final_stage` | string | item 最终所处的排序阶段名称（如 `DISPATCH`、`RANK` 等） |

### 维度：召回阶段信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `recall_type` | int | 召回来源类型：0=未知，1=纯广告召回，2=纯自然召回，3=广告+自然同时召回 |
| `recall_queues` | array\<int\> | 命中的召回队列 ID 列表（来源：`recall_strategies[].queue_id`） |
| `recall_remove_reason` | string | 召回阶段被过滤的原因（来源：`filtered_reason`） |

### 维度：预排序阶段信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `prerank_position` | int | 预排序阶段的排名位置（来源：rank_server） |
| `prerank_remove_reason` | string | 预排序阶段被过滤的原因（来源：rank_server） |

### 维度：精排阶段信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `rank_position` | int | 精排阶段的排名位置 |
| `rank_remove_reason` | string | 精排阶段被过滤的原因（来源：`filtered_reason`） |

### 维度：混排阶段信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `mixrank_position` | int | 混排阶段的排名位置 |
| `mixrank_remove_reason` | string | 混排阶段被过滤的原因（来源：`filtered_reason`） |

### 维度：下发阶段信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `dispatch_position` | int | 最终下发位置（`dispatch_info.index`） |

### 维度：错误信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_info_api_error` | string | 广告信息接口错误信息（来源：`roi_revert_reason`） |
| `bidding_api_error` | string | 竞价接口错误信息（ETL 中与 `ads_info_api_error` 同源） |
| `deduction_api_error` | string | 扣费接口错误信息（ETL 中与 `ads_info_api_error` 同源） |

### 维度：广告扩展信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_recall_ext` | string | 广告召回扩展信息（protobuf 反序列化，类型 RecallFullLinkExt，来源 `ads_info.recall_ext`） |
| `ads_info_ext` | string | 广告信息扩展字段（protobuf 反序列化，类型 RecallFullLinkExt，来源 `ads_info.info_ext`） |
| `ads_bid_ext` | string | 广告竞价扩展信息（protobuf 反序列化，类型 AdBidFullLinkExt，来源 `bidding_info.bid_ext`） |
| `ads_deduct_ext` | string | 广告扣费扩展信息（protobuf 反序列化，类型 DeductFullLinkExt，来源 `deduction_info.deduct_ext`） |

### 指标：召回阶段评分

| 字段 | 类型 | 说明 |
|------|------|------|
| `queue_scores` | array\<float\> | 召回队列得分数组（当前存储为单元素数组，值为 `recall_info.score`） |

### 指标：预排序阶段预估值

| 字段 | 类型 | 说明 |
|------|------|------|
| `prerank_score` | float | 预排序综合得分（来源：rank_server） |
| `prerank_pctr` | float | 预排序预估点击率（来源：rank_server） |
| `prerank_pcr` | float | 预排序预估转化率（当前 ETL 固定写入 null，待补充） |
| `prerank_relevance_score` | float | 预排序相关性得分（来源：rank_server `prerank_info.relevance_score`） |

### 指标：精排阶段预估值

| 字段 | 类型 | 说明 |
|------|------|------|
| `rank_score` | float | 精排综合得分 |
| `rank_pctr` | float | 精排预估点击率（`rank_info.pctr`） |
| `rank_pcr` | float | 精排预估转化率（`rank_info.pcvr`） |
| `rank_broad_pcr` | float | 精排宽泛预估转化率（`rank_info.broad_pcvr`） |
| `rank_ecpm` | float | 精排预估千次展示收益（`rank_info.ecpm`） |
| `rank_ecpm_weight` | float | 精排 eCPM 权重（来源：`mixrank_info.ecpm_weight`，注意字段来源跨阶段） |
| `rank_estimated_gmv` | float | 精排预估 GMV（`rank_info.estimated_gmv`） |
| `rank_relevance_score` | float | 精排相关性得分（`rank_info.relevance_score`） |
| `rank_item_price` | bigint | 精排阶段商品价格（来源：`price_v2`） |

### 指标：混排阶段预估值

| 字段 | 类型 | 说明 |
|------|------|------|
| `mixrank_score` | float | 混排综合得分（`mixrank_info.score`） |
| `mixrank_pctr` | float | 混排预估点击率（ETL 中复用 `rank_pctr`） |
| `mixrank_pcr` | float | 混排预估转化率（ETL 中复用 `rank_pcr`） |
| `mixrank_broad_pcr` | float | 混排宽泛预估转化率（ETL 中复用 `rank_broad_pcr`） |
| `mixrank_ecpm` | float | 混排预估千次展示收益（`mixrank_info.ecpm`） |
| `mixrank_ecpm_weight` | float | 混排 eCPM 权重（`mixrank_info.ecpm_weight`） |
| `mixrank_estimated_gmv` | float | 混排预估 GMV（ETL 中复用 `rank_estimated_gmv`） |
| `mixrank_porg` | float | 混排自然排序概率（`mixrank_info.porg`） |
| `mixrank_item_price` | bigint | 混排阶段商品价格（来源：`price_v2`） |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定三个分区字段**：`regional_date`、`regional_hour`、`country`，否则将触发全表扫描，消耗极大计算资源。
  ```sql
  WHERE regional_date = '2024-01-01'
    AND regional_hour = '10'
    AND country = 'SG'
  ```
- 跨小时查询时，应通过 `regional_date` + `regional_hour` 组合枚举所需时间范围，避免 `regional_date` 单独范围扫描叠加所有小时分区。

### 不可直接 SUM 的字段

以下字段为**预估概率/分值/比率**，其数值本身不具备直接累加语义，分析时应使用 AVG、分位数或加权聚合：

| 字段 | 原因 |
|------|------|
| `prerank_pctr`、`rank_pctr`、`mixrank_pctr` | 预估点击率（概率值，不可 SUM） |
| `prerank_pcr`、`rank_pcr`、`mixrank_pcr`、`rank_broad_pcr`、`mixrank_broad_pcr` | 预估转化率（概率值，不可 SUM） |
| `rank_score`、`prerank_score`、`mixrank_score`、`prerank_relevance_score`、`rank_relevance_score` | 模型得分（不具备加和语义） |
| `rank_ecpm`、`mixrank_ecpm`、`rank_ecpm_weight`、`mixrank_ecpm_weight` | eCPM 及权重（不可 SUM） |
| `mixrank_porg` | 自然排序概率（概率值，不可 SUM） |
| `queue_scores` | 数组类型召回分，需先展开再聚合 |

### 字段使用注意事项

- **`prerank_pcr`**：当前 ETL 固定写入 `null`，查询时需注意空值处理。
- **`vmodel_id`**：当前 ETL 固定写入 `null`，暂无实际数据。
- **`is_cached`**：当前 ETL 固定写入 `false`，不反映真实缓存命中情况。
- **`rank_ecpm_weight` 与 `mixrank_ecpm_weight`**：两者来源相同（均来自 `mixrank_info.ecpm_weight`），`rank_ecpm_weight` 并非来自 rank 阶段本身，使用时需注意语义。
- **`mixrank_pctr`、`mixrank_pcr`、`mixrank_broad_pcr`、`mixrank_estimated_gmv`**：ETL 中均复用精排阶段对应字段，并非混排阶段独立计算值。
- **`bidding_api_error`、`deduction_api_error`**：两者在 ETL 中均与 `ads_info_api_error` 同源，均来自 `roi_revert_reason`，三个字段值相同。
- **`ads_recall_ext`、`ads_info_ext`、`ads_bid_ext`、`ads_deduct_ext`**：经 `base64_to_protobuf` 函数反序列化，字段类型为 string（protobuf 结构体序列化后的字符串），直接字符串比较可能无意义，需结合 protobuf 解析逻辑使用。

### 时效性说明

- 本表为**小时级准实时表**，每小时触发一次 INSERT OVERWRITE 写入，数据延迟通常在 1 小时以内。
- 每次写入覆盖当前 `(regional_date, regional_hour, country)` 分区，历史分区数据不被重刷（除非手动触发回刷）。
- 不包含累计（`_td`）或近 N 天（`_nd`）窗口数据，所有数据均为当前小时原始明细。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_rt.ods_fll_search` | 搜索全链路主日志，提供召回、精排、混排、下发等各阶段的候选商品明细，以及广告相关扩展信息；通过 `lateral view explode(data)` 展开每个候选商品为独立行 |
| `srdi_rt.ods_fll_search_rank` | 搜索预排序（PreRank）服务日志，提供每个候选商品的预排序阶段得分、位置、pCTR、相关性分数及过滤原因；通过 `lateral view explode(data)` 展开 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_rt.ods_fll_search          srdi_rt.ods_fll_search_rank
       │ lateral view explode             │ lateral view explode
       ▼                                  ▼
  CTE: search_server              CTE: rank_server
  （主链路宽表，含召回/               （预排序阶段信息，
    精排/混排/下发/广告）              含prerank各维度得分）
       │                                  │
       └──────────── LEFT JOIN ───────────┘
                  ON request_id + item_id
                         │
                         ▼
    INSERT OVERWRITE srdi_mart.dwd_sr_data_warehouse_search_unify_full_link_log_1h
          partition(regional_date, regional_hour, country)
```

### 关键步骤

1. **CTE `search_server`（来自 `ods_fll_search`）**
   - 按 `(regional_date, regional_hour, country)` 分区过滤 ODS 原始日志
   - 通过 `lateral view explode(t.data)` 将每个请求的候选商品列表展开为行级数据
   - 提取召回（recall_info）、精排（rank_info）、混排（mixrank_info）、下发（dispatch_info）各阶段字段
   - 使用 `base64_to_protobuf` 函数对广告召回扩展、信息扩展、竞价扩展、扣费扩展进行 protobuf 反序列化

2. **CTE `rank_server`（来自 `ods_fll_search_rank`）**
   - 同样按相同分区条件过滤，通过 `lateral view explode(t.data)` 展开候选商品
   - 提取预排序阶段的得分（prerank_score）、位置（prerank_position）、pCTR（prerank_pctr）、相关性分数、过滤原因

3. **最终 INSERT OVERWRITE**
   - 以 `search_server` 为主表，LEFT JOIN `rank_server`（关联键：`request_id` + `item_id`）
   - 构造 `is_recall`、`is_prerank`、`is_rank`、`is_mixrank`、`is_dispatch` 等布尔标志位
   - 构造 `recall_type`（根据 from_organic / from_ads 组合枚举）
   - 将 `recall_strategies` 中 queue_id 转换为 `recall_queues` 数组
   - 部分混排字段（pctr、pcr、broad_pcr、estimated_gmv）复用精排阶段值
   - `prerank_pcr`、`vmodel_id`、`is_cached` 三个字段当前写入固定值（null / false）
   - 覆盖写入目标分区 `(regional_date, regional_hour, country)`

### 注意事项

- **单 Writer**：本表为单一 ETL 文件写入（`multi_writer: false`），无多文件并发写入风险。
- **LEFT JOIN 语义**：`rank_server` 以 LEFT JOIN 形式接入，意味着未进入预排序阶段的 item 也会保留在结果集中，但 prerank 相关字段为 null（`is_prerank = false`）。
- **字段跨阶段复用风险**：混排阶段的 pctr、pcr、broad_pcr、estimated_gmv 直接复用精排字段，`rank_ecpm_weight` 实际来自 mixrank_info，分析时需注意字段语义与阶段的对应关系，避免误解。
- **三个错误字段同源**：`ads_info_api_error`、`bidding_api_error`、`deduction_api_error` 均来自同一源字段 `roi_revert_reason`，当前设计暂未区分竞价和扣费独立错误来源。
- **固定 null/false 字段**：`prerank_pcr`、`vmodel_id` 为 null，`is_cached` 为 false，后续 ETL 升级时需关注这些字段的数据补全情况。
- **分区覆盖写入**：每次执行覆盖当前小时分区，若同一分区内上游数据发生重跑，目标分区会被完整替换。

---

*文档生成时间：2026-05-17*