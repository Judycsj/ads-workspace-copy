<!-- ads-workspace-gdoc-sync: gdoc_id=11Qq5c-3hZQW3knrrUKf7gaTOVFabs_1toh0UYOWqcrY gdoc_url=https://docs.google.com/document/d/11Qq5c-3hZQW3knrrUKf7gaTOVFabs_1toh0UYOWqcrY/edit -->

# srdi_mart.dwd_sr_data_warehouse_platform_fe_join_be_source

**分层：** DWD（明细数据层）
**主键：** `request_id` + `item_id` + `operation` + `grass_region` + `local_date`（联合唯一，FE 与 BE 日志 JOIN 后的行级明细）
**分区：** `grass_region` / `local_date` / `local_hour` / `operation` / `regional_date` / `regional_hour`
**更新频率：** 每日按分区覆盖写入（INSERT OVERWRITE）
**引用频次 / 访问频次：** 542

---

## 业务描述

本表是搜推（Search & Recommendation）数仓的核心 DWD 明细表，通过将**前端行为日志（FE）** 与**后端推荐/搜索服务日志（BE）** 进行关联，生成包含完整上下文的单行曝光 + 转化明细记录。

**核心业务场景：**
- 搜推效果归因分析：将用户的下单（order）、加购（cart）、商品详情页浏览（ppv）行为与 BE 侧的排序打分、召回信息、模型信息进行精确对齐；
- 推荐模型效果评估：分析 `final_score`、`rank_score_named`、`rerank_score_named`、`roughrank_score_named` 等多阶段模型分数与最终转化的关系；
- TC（Traffic Control）规则效果分析：通过 `tc_rule_id`、`tc_item_group_id`、`tc_boost_weight` 评估流量干预规则的实际影响；
- 广告效果分析：结合 `is_ads`、`ads_id`、`ecpm_score`、`ecpm_weight`、`ads_extra_names`/`ads_extra_values` 进行广告归因；
- 多场景覆盖：支持首页推荐（home）、商品详情页关联推荐（pdp）、搜索（search/global_search）、购物车（cart）等多个流量入口。

**适合回答的问题：**
- 某推荐位/队列（`queue`/`feature_detail`）的下单 GMV 和加购率如何？
- TC 规则对转化率的提升/抑制幅度是多少？
- 某模型版本（`ranker_id`/`roughranker_id`）上线后对核心指标的影响？
- 广告商品与自然商品在各指标上的差异？
- 召回通道（`recall_info_list`/`recall_info_list_v2`）对转化的贡献分析？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 国家/地区标识，如 ID、MY、TH 等，分区键之一 |
| `local_date` | date | 事件发生的本地日期（按目标地区时区），主分区键 |
| `local_hour` | int | 事件发生的本地小时（0–23），分区键之一 |
| `operation` | string | 用户行为类型，值为 `order`（下单）、`cart`（加购）、`ppv`（商品详情页浏览） |
| `regional_date` | date | 区域统一日期（可能与 `local_date` 不同，用于跨时区汇总对齐） |
| `regional_hour` | int | 区域统一小时，与 `regional_date` 配合使用 |

### 维度：事件与请求标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `request_id` | string | 后端服务请求 ID，FE 与 BE 关联的核心 JOIN Key |
| `event_id` | string | 前端事件 ID，唯一标识一次前端上报事件 |
| `session_id` | string | 用户会话 ID |
| `event_timestamp` | bigint | 前端事件发生时间戳（毫秒级 Unix 时间戳） |
| `log_timestamp` | bigint | 日志落地时间戳 |
| `order_id` | bigint | 订单 ID，`operation=order` 时有值 |

### 维度：用户与设备

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 登录用户 ID；未登录时为 null 或 0 |
| `device_id` | string | 设备唯一标识 |
| `platform` | string | 客户端平台，如 android、ios、web 等 |

### 维度：商品与店铺

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，FE 行为侧商品，经 SPU/vSKU 逻辑处理后与 BE 关联 |
| `shop_id` | bigint | 店铺 ID |
| `l1_cate_id` | int | 商品一级类目 ID，来自 BE 日志 |
| `l2_cate_id` | int | 商品二级类目 ID，来自 BE 日志 |
| `l3_cate_id` | int | 商品三级类目 ID，来自 BE 日志 |
| `price` | double | 商品价格，来自 BE 日志 |

### 维度：页面与推荐位

| 字段 | 类型 | 说明 |
|---|---|---|
| `feature_detail` | string | 推荐/搜索场景标识，格式为 `<page>-<module>-<type>`，如 `home-daily_discover-match_mix_feed_card`、`product-you_may_also_like-item` |
| `target_type` | string | 目标类型，标识推荐目标的类型（商品、视频等） |
| `page_type` | string | 页面类型，如 `global_search`、`search_prefill`、`search_in_pdp` 等 |
| `page_section` | array\<string\> | 页面分区信息，标识商品在页面中所属的 section |
| `location` | int | 商品在推荐列表中的位置（曝光位次） |
| `offset` | int | 商品在返回结果中的偏移量，来自 BE 日志 |
| `queue` | string | 商品所属队列名称（取 `queuelist` 第一个元素） |
| `queuelist` | array\<string\> | 商品所属所有队列名称列表 |
| `section_key_from_be` | string | 来自 BE 日志的 section key 标识 |
| `keyword` | string | 搜索关键词，搜索场景下有值 |
| `contextitems` | array\<struct\<shop_id:int,item_id:bigint\>\> | PDP 场景下的上下文商品列表（`server_log_tag='pdp'` 时填充，其余场景为 null） |
| `data_type_from_be` | string | 来自 BE 日志的数据类型标识，如 `fashion_match`、`video` 等 |

### 维度：广告信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_ads` | boolean | 是否为广告商品，来自 FE 日志 |
| `ads_id` | bigint | 广告 ID，来自 BE 日志 |
| `ads_id_fe` | bigint | 广告 ID，来自 FE 日志（与 `ads_id` 可用于一致性校验） |
| `ads_extra_names` | array\<string\> | 广告附加信息字段名列表，来自 BE 日志 |
| `ads_extra_values` | array\<double\> | 广告附加信息字段值列表，与 `ads_extra_names` 一一对应 |
| `roi_item_type` | string | 广告 ROI 商品类型标识，来自 BE 日志 |

### 维度：标签与实验

| 字段 | 类型 | 说明 |
|---|---|---|
| `label_name` | array\<string\> | 商品标签名称列表（如促销标签等），仅搜索 BE 来源有值 |
| `label_text` | array\<string\> | 商品标签文本列表，与 `label_name` 对应，仅搜索 BE 来源有值 |
| `exp_group_ids` | array\<int\> | 实验分组 ID 列表，来自 FE 日志 |
| `ab_sign` | array\<int\> | AB 实验标识数组，仅搜索 BE 来源有值；推荐 BE 来源为 null |
| `server_log_tag` | string | BE 日志来源标签，取值：`dd`（每日发现）、`pdp`（商品详情页）、`cart`（购物车）、`misc`（其他）、`search`（搜索） |
| `params_search_tag` | array\<string\> | 搜索参数 tag 数组，来自 BE 日志 |
| `item_group_types` | array\<string\> | 商品组类型标识数组，来自 BE 日志 |
| `target_item_tags` | array\<string\> | 目标商品标签数组，来自 BE 日志 |

### 维度：TC（流量干预）规则

| 字段 | 类型 | 说明 |
|---|---|---|
| `tc_rule_id` | bigint | TC 规则 ID（经 `tc_boost_weight` 阈值过滤后保留的有效规则 ID，权重在 (0,1) 或 ≥1.0001 或 <0 时保留） |
| `tc_item_group_id` | string | TC 商品组 ID（同上过滤逻辑） |
| `tc_rule_id_untreated` | bigint | TC 规则 ID 原始值（未经权重过滤） |
| `tc_item_group_id_untreated` | string | TC 商品组 ID 原始值（未经权重过滤） |
| `tc_boost_weight` | string | TC 规则 boost 权重 JSON 字符串，包含 `pid_weight`、`match_weight`、`loss_weight` 等字段 |

### 维度：替换与相似商品

| 字段 | 类型 | 说明 |
|---|---|---|
| `replaced_item_id` | bigint | 被替换的原始商品 ID，来自 BE 日志 |
| `has_replacement_candidate` | string | 是否有替换候选商品，仅搜索 BE 来源有值 |
| `eligible_to_replace` | string | 当前商品是否符合替换条件，仅搜索 BE 来源有值 |
| `cheapest_replacement` | string | 最便宜替换商品信息，仅搜索 BE 来源有值 |
| `similar_product_replace_info` | string | 相似商品替换详细信息，来自 BE 日志 |
| `video_replace_info` | string | 视频商品替换信息，来自 BE 日志 |

### 维度：模型与召回信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `ranker_id` | string | 精排模型 ID，来自 BE 日志 `item_model_info` 字段 |
| `roughranker_id` | string | 粗排模型 ID，来自 BE 日志 |
| `subranker_id` | string | 子排序模型 ID，来自 BE 日志 |
| `ranker_model_infos` | array\<string\> | 精排模型详细信息列表，来自 BE 日志 |
| `bundle` | string | BE 服务 bundle 名称（已过滤 `vitem_selection`、`vitem_selection_rcmd`），来自 BE 日志 |
| `recall_info_list` | array\<struct\<Index:int,Name:string,Score:double,trigger_item_ids:array\<bigint\>\>\> | 召回通道信息列表 V1，推荐 BE 来源为 null，当前版本保留字段 |
| `recall_info_list_v2` | array\<struct\<Index:int,global_queue_id:int,Score:double,trigger_item_ids:array\<bigint\>\>\> | 召回通道信息列表 V2，推荐 BE 来源有值，搜索 BE 来源为 null |
| `rec_info_exp_list` | string | 推荐信息实验列表（JSON 字符串），来自 BE 日志 |
| `expansion_info` | string | 扩展信息，来自 BE 日志 |
| `mix_rank_info` | string | 混排信息，来自 BE 日志 |
| `smart_image_info` | string | 智能图片信息，仅推荐 BE 来源有值 |
| `cali_scores_info` | array\<string\> | 校准分数信息列表，来自 BE 日志 |

### 指标：转化与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `place_order_gmv` | double | 下单 GMV（美元或统一货币），来自 FE 行为日志 |
| `place_order_gmv_local` | double | 下单 GMV（本地货币），来自 FE 行为日志 |
| `operation_cnt` | double | 行为计数（通常为 1.0），用于统计 order/cart/ppv 次数 |

### 指标：排序与打分

| 字段 | 类型 | 说明 |
|---|---|---|
| `final_score` | double | 精排最终综合得分，来自 BE 日志 `item_final_score` 字段 |
| `pmatch_score` | double | 精准匹配分数，来自 BE 日志 |
| `ecpm_score` | double | eCPM 得分（广告预估千次展示收益），来自 BE 日志 |
| `ecpm_weight` | double | eCPM 权重，来自 BE 日志 |
| `cart_score` | string | 加购预估分数（字符串形式），来自 BE 日志 |
| `order_score` | string | 下单预估分数（字符串形式），来自 BE 日志 |
| `click_score` | string | 点击预估分数（字符串形式），来自 BE 日志 |
| `rank_score_named` | map\<string,double\> | 精排各子分数命名 map，key 为分数名，value 为分数值，来自 BE 日志 |
| `rerank_score_named` | map\<string,double\> | 重排各子分数命名 map，来自 BE 日志 |
| `roughrank_score_named` | map\<string,double\> | 粗排各子分数命名 map，来自 BE 日志 |
| `request_item_count` | int | 本次请求的候选商品数量，来自 BE 日志 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，该表为多地区混合分区，不加过滤将触发全量扫描；
- **`local_date`**：必须指定，每日全量覆盖写入，范围查询需明确日期区间；
- **`operation`**：强烈建议指定（`order`/`cart`/`ppv`），不同行为类型语义差异大，混合聚合通常无业务意义；
- 示例：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2026-05-16'
    AND operation = 'order'
  ```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `final_score`、`pmatch_score`、`ecpm_score`、`ecpm_weight` | 排序打分，SUM 无业务意义，应使用 AVG 或分布分析 |
| `cart_score`、`order_score`、`click_score` | 字符串类型预估分，需 CAST 后再聚合，且 SUM 无意义 |
| `rank_score_named`、`rerank_score_named`、`roughrank_score_named` | Map 类型，需先展开子 key 再聚合 |
| `recall_info_list`、`recall_info_list_v2` | 复杂嵌套结构，需 EXPLODE 后使用 |
| `ads_extra_names`/`ads_extra_values` | 并行数组，需配合 POSEXPLODE 对齐后再聚合 |
| `operation_cnt` | 预置计数字段，理论可 SUM，但需确认无重复行（FE 与 BE 为左连接，BE 侧 null 时仍有 FE 行） |
| `place_order_gmv`/`place_order_gmv_local` | 来自 FE 日志，LEFT JOIN 后可能因 BE 匹配不上而保留，聚合时注意去重 `request_id` + `item_id` + `order_id` 避免多行重复计算 |

### 字段可用性说明

| 场景 | 说明 |
|---|---|
| `server_log_tag = 'search'` | 来自搜索 BE 日志，`final_score`、`ranker_id`、`bundle`、`rec_info_exp_list`、`smart_image_info`、`recall_info_list_v2` 等字段为 null；`ab_sign`、`label_name`、`label_text`、`has_replacement_candidate`、`eligible_to_replace`、`cheapest_replacement` 有值 |
| `server_log_tag IN ('dd','pdp','cart','misc')` | 来自推荐 BE 日志，`ab_sign`、`label_name`、`label_text` 为 null；`final_score`、`ranker_id`、`bundle`、`recall_info_list_v2`、`smart_image_info` 等有值 |
| `contextitems` | 仅在 `server_log_tag = 'pdp'` 时填充，其余场景强制为 null |
| `tc_rule_id` vs `tc_rule_id_untreated` | `tc_rule_id` 经过权重有效性过滤（权重在合理干预范围内才保留），`tc_rule_id_untreated` 保留原始值；效果分析时建议使用 `tc_rule_id` |

### 时效性说明

- 本表为 **日级覆盖更新**（INSERT OVERWRITE），当天数据在 ETL 完成后可用；
- 无实时流或小时级增量，历史数据通过分区日期访问；
- 不含 `*_nd`（近 N 天）或 `*_td`（截至今日）预聚合字段，如需时间窗口分析需在查询层自行指定日期范围。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_platform` | FE 前端行为日志源表，提供用户行为事件（order/cart/ppv）、商品 ID、用户/设备信息、页面信息、实验信息等；支持 source1/source2 两路场景关联 |
| `srdi_mart.dwd_sr_data_warehouse_platform_be_log_filtered` | 推荐 BE 日志过滤表，提供推荐服务侧排序打分、模型信息、召回信息、TC 规则、广告信息等；已过滤 `vitem_selection` 相关 bundle |
| `srdi_mart.dwd_sr_data_warehouse_search_be_log` | 搜索 BE 日志表，提供搜索服务侧商品信息、TC 规则、AB 实验标识、商品标签、替换候选信息等 |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_platform (FE行为日志)
    ├── source1_* 字段路径（主场景）
    └── source2_* 字段路径（关联场景）
            ↓ UNION ALL → fe_data 临时视图
            
dwd_sr_data_warehouse_platform_be_log_filtered (推荐BE日志)
    ↓
dwd_sr_data_warehouse_search_be_log (搜索BE日志)
            ↓ UNION ALL → be_data 临时视图

fe_data LEFT JOIN be_data
    ON request_id + join_item_id + join_content_id + item_unique_key
            ↓
dwd_sr_data_warehouse_platform_fe_join_be_source
```

### 关键步骤

**Step 1 — 构建 `fe_data` 临时视图**

从 `dwd_sr_data_warehouse_platform` 抽取 `operation IN ('order','cart','ppv')` 的行为数据，执行两路 UNION ALL：
- **source1 路径**：使用 `source1_*` 系列字段（`source1_request_id`、`source1_feature_detail`、`source1_location` 等），过滤条件为 `source1_feature_detail != feature_detail`（排除与主 feature_detail 重复的场景）；
- **source2 路径**：使用 `source2_*` 系列字段，过滤条件为 `source2_feature_detail != source1_feature_detail AND source2_feature_detail != feature_detail`（避免与 source1 重复）；
- 两路均计算 `join_item_id`（SPU/vSKU 归一化逻辑）、`join_content_id`（视频/fashion_match 场景内容 ID）、`item_unique_key`（搜索及 PDP 商品唯一键）用于后续 JOIN；
- 队列信息：`split(queues, ',')[0]` 取第一个队列为 `queue`，完整数组为 `queuelist`。

**Step 2 — 构建 `be_data` 临时视图**

合并推荐 BE 与搜索 BE 两路日志，执行 UNION ALL：
- **推荐 BE 路径**（`dwd_sr_data_warehouse_platform_be_log_filtered`）：提供 `final_score`、`ranker_id`（来自 `item_model_info`）、`rec_info_exp_list`、`rank_score_named`/`rerank_score_named`/`roughrank_score_named`、`recall_info_list_v2`、`smart_image_info`、`expansion_info` 等丰富模型信息；`ab_sign`、`label_text`、`label_name`、`recall_info_list` 为 null；已排除 `bundle in ('vitem_selection','vitem_selection_rcmd')`；`tc_weight` 由 `tc_boost_weight` JSON 中三个子权重相乘计算；`join_content_id` 根据 `item_data_type` 决定取 `match_id` 或 `content_id`；
- **搜索 BE 路径**（`dwd_sr_data_warehouse_search_be_log`）：`server_log_tag` 固定为 `'search'`；提供 `ab_sign`、`label_name`、`label_text`、`has_replacement_candidate`、`eligible_to_replace`、`cheapest_replacement`、`replaced_item_id`；大部分模型打分字段为 null；`join_content_id` 固定为空字符串。

**Step 3 — FE LEFT JOIN BE 写入目标表**

```sql
INSERT OVERWRITE TABLE ... PARTITION (grass_region, local_date, local_hour, regional_date, regional_hour, operation)
SELECT ...
FROM fe_data a
LEFT JOIN be_data b
  ON a.request_id = b.request_id
  AND a.join_item_id = b.item_id
  AND a.join_content_id = b.join_content_id
  AND (a.item_unique_key IS NULL OR a.item_unique_key = b.item_unique_key)
```

- 采用 LEFT JOIN 保留所有 FE 行为记录，BE 侧未匹配时相关字段为 null；
- `tc_rule_id`/`tc_item_group_id` 经过权重有效性二次过滤（`tc_weight >= 1.0001 OR tc_weight BETWEEN 0.0001 AND 0.9999 OR tc_weight < 0`），确保仅保留实际生效的干预规则；同时保留 `tc_rule_id_untreated`/`tc_item_group_id_untreated` 原始值；
- `contextitems` 字段仅在 `server_log_tag = 'pdp'` 时取 FE 侧 `ctx_items`，其余场景为 null；
- `grass_region`、`local_date` 作为静态分区值写入，`local_hour`、`regional_date`、`regional_hour`、`operation` 作为动态分区值。

### 注意事项

1. **LEFT JOIN 多匹配风险**：若 BE 侧存在同一 `(request_id, item_id, join_content_id)` 的多条记录，LEFT JOIN 将产生行膨胀，导致 `place_order_gmv` 等 FE 指标被重复计算；聚合 GMV 前应先验证 BE 侧唯一性或使用 `DISTINCT`；
2. **source1 / source2 双路 UNION**：同一次用户行为在 FE 表中可能同时存在 source1 和 source2 路径，UNION ALL 后同一 `order_id` 可能出现多行；按 `order_id` 统计订单数时需去重；
3. **分区写入**：`grass_region` 和 `local_date` 为静态分区，ETL 参数化执行；单次 ETL 仅覆盖特定 region + date 的分区，不影响其他分区历史数据；
4. **`operation` 过滤差异**：source1 路径 WHERE 条件为 `operation IN ('order','cart',' ppv')`（注意 `' ppv'` 含前导空格，疑似 ETL SQL 原始笔误），source2 路径为 `('order','cart','ppv')`（无空格）；实际数据中 `ppv` 的 source1 路径数据可能存在缺失，使用时需关注；
5. **BE 字段 null 差异**：推荐 BE 与搜索 BE 两路数据字段可用性差异显著（见查询使用须知），下游分析时应先按 `server_log_tag` 分组处理，避免混合聚合导致结果失真；
6. **单文件写入**：本表为单 ETL 文件写入（`multi_writer=false`），无多文件并发写入风险。

---

*文档生成时间：2026-05-17*