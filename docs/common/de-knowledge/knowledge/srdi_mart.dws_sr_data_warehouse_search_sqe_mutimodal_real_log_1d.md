<!-- ads-workspace-gdoc-sync: gdoc_id=1slZBzWbU5kkyKkPEBCpMdgMhUEidenbNxsWNhvHNatA gdoc_url=https://docs.google.com/document/d/1slZBzWbU5kkyKkPEBCpMdgMhUEidenbNxsWNhvHNatA/edit -->

# srdi_mart.dws_sr_data_warehouse_search_sqe_mutimodal_real_log_1d

**分层：** dws_search（数据仓库服务层 - 搜索域）
**主键：** `request_id` + `item_id`（联合唯一标识一次搜索请求中的单个商品曝光记录）
**分区：** `grass_region`（大区）/ `grass_date`（日期）
**更新频率：** 每日覆盖写入（INSERT OVERWRITE，T+1）
**引用频次 / 访问频次：** 118

---

## 业务描述

本表是搜推数仓搜索域的 **多模态搜索（图搜 / 语音搜索）SQE 日志宽表**，粒度为 **每日 × 大区 × 搜索请求 × 商品曝光**。

表的核心业务场景如下：

- **多模态搜索质量评估（SQE）**：专门针对图片搜索（`search_mid LIKE 'image%'`）和语音搜索（`search_mid = 'voice_search'`）场景，聚合前端曝光日志、后端排序日志、Query 处理日志及 AI 搜索序列信息，为搜索相关性、排序效果评估提供基础数据。
- **多模态搜索链路分析**：打通图搜图片 URL / 裁剪框坐标、语音搜索音频 URL、算法意图文本、连续搜索序列信息（上一张图 md5 / 裁剪框 / 关键词），支持对多轮图搜、语音搜索全链路的分析。
- **搜索相关性与排序分析**：包含 ES 召回分、排序分及相关性三路分数（`rel_raw`、`rel_lx`、`rel_add`），可用于模型效果评估和离线相关性分析。
- **关键词分析**：关联关键词搜索量分位类型、关键词类目归因、Query 聚类，支持对不同频次关键词的表现分层分析。

**适合回答的典型问题：**
- 图搜 / 语音搜索的搜索请求中，各商品的曝光排序及相关性分布如何？
- 图搜连续交互（refinement）中，用户上一张图与本次搜索的关键词变化情况？
- 某关键词类目下，广告与自然结果的排序分布差异？
- 多模态搜索场景下，不同平台、地区的商品曝光分布？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 SG、MY、TH 等），分区写入，查询必须指定 |
| `grass_date` | date | 数据日期（本地日期），分区写入，查询必须指定 |

### 维度：搜索请求与用户标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `request_id` | string | 搜索请求唯一 ID，联合主键之一 |
| `search_session_id` | string | 搜索会话 ID，用于串联同一会话内的多次请求 |
| `user_id` | bigint | 用户 ID |
| `search_mid` | string | 搜索入口标识（如 `image_*` 表示图搜，`voice_search` 表示语音搜索），仅保留多模态入口 |
| `platform` | string | 客户端平台（如 iOS、Android 等） |

### 维度：商品与店铺

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，联合主键之一 |
| `shop_id` | bigint | 店铺 ID，来自商品维度表关联 |
| `content_id` | string | 内容 ID（视频 / 直播等内容类卡片的内容标识） |
| `card_type` | string | 卡片类型（`item`=普通商品, `video`=视频, `livestream`=直播），由后端日志 card_type 字段映射转换 |
| `is_ads` | boolean | 是否为广告 |
| `sub_product_type` | string | 广告子产品类型，来自广告维度表关联 |

### 维度：搜索行为与筛选条件

| 字段 | 类型 | 说明 |
|---|---|---|
| `keyword` | string | 搜索关键词（已做 trim + lower 标准化处理） |
| `keyword_type` | string | 关键词搜索量分位类型（`0%-20%`、`20%-50%`、`50%-80%`、`80%-100%`），基于近 30 天搜索量累计百分位 |
| `sort_type` | string | 排序类型（如综合排序、价格排序等） |
| `with_filter` | boolean | 本次搜索是否使用了筛选条件 |
| `search_filter` | array\<string\> | 搜索筛选条件列表，每个元素为包含 filter_type/filter_name/filter_option 的 JSON 字符串 |
| `imp_time` | bigint | 商品曝光时间戳（毫秒级） |
| `item_position` | int | 商品在搜索结果页中的曝光位置 |

### 维度：Query 处理信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `query_correct` | string | Query 纠错结果（优先取 wsrp 纠错，其次取 nsrp 纠错） |
| `query_rewrite` | array\<string\> | Query 改写 / 扩展词列表 |
| `query_cluster` | string | 关键词所属搜索聚类（cluster） |
| `query_category` | struct\<L1:struct\<cat_id:int,cat_name:string\>,L2:struct\<cat_id:int,cat_name:string\>,L3:struct\<cat_id:int,cat_name:string\>\> | 关键词归因类目（L1/L2/L3 层级，取各层级最高占比类目） |
| `predict_query_category` | array\<bigint\> | Query 处理服务预测的类目 ID 列表 |
| `default_variables` | array\<struct\<name:string,value:string\>\> | Query 处理服务返回的默认变量列表（已过滤掉 `attr_catid` 字段） |

### 维度：多模态搜索专属信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `image_url` | string | 图搜上传图片的 CDN URL（由 `ai_search_info_md5` 拼接构建） |
| `image_bounding_box` | string | 图搜裁剪框坐标（从 `ai_search_info_box` 中提取的 box_xy JSON 字符串） |
| `audio_url` | string | 语音搜索的音频文件 URL |
| `user_intention` | string | 多模态搜索算法推断的用户意图信息（来自后端日志的 `multimodal_user_intention_info`） |
| `algo_intent_search_txt` | string | AI 搜索场景中算法生成的意图文本（来自 AI 搜索宽表） |
| `last_md5` | string | 连续图搜场景中上一张图片的 MD5 标识（从 srp_seq_info 最后一个元素提取） |
| `last_box_xy` | array\<int\> | 连续图搜中上一张图片的裁剪框坐标数组 |
| `last_keyword` | string | 连续图搜中上一次搜索使用的关键词 |
| `imp_image_url` | string | 平台侧记录的商品曝光图片 URL（由大区域名 + image_id 拼接构建，无曝光记录则为 NULL） |

### 指标：排序与相关性分数

| 字段 | 类型 | 说明 |
|---|---|---|
| `es_score` | double | Elasticsearch 召回阶段的相关性分数，**不可直接 SUM** |
| `ranking_score` | double | 精排阶段综合排序分数（原字段 `rank_score`），**不可直接 SUM** |
| `rel_raw` | double | 原始相关性分数（raw relevance score），**不可直接 SUM** |
| `rel_lx` | int | 相关性 lx 档位分（离散化相关性标签），**不可直接 SUM** |
| `rel_add` | double | 附加相关性分数（additional relevance），**不可直接 SUM** |

### 指标：广告与排序辅助字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `rule_ids` | array\<int\> | 命中的搜索规则 ID 列表（如置顶、降权等规则） |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region` 和 `grass_date` 两个分区字段**，否则将触发全表扫描，资源消耗极大。
- 示例：
  ```sql
  WHERE grass_region = 'SG'
    AND grass_date = '2024-01-01'
  ```
- `grass_date` 类型为 `date`，过滤时建议使用 `DATE '2024-01-01'` 或与引擎兼容的日期字面量格式。

### 不可直接 SUM 的字段

以下字段为分数、离散标签或派生指标，**不具备可加性，禁止直接 SUM 聚合**：

| 字段 | 原因 |
|---|---|
| `es_score` | 召回阶段分数，属于单条记录分值，无加和意义 |
| `ranking_score` | 精排综合分，属于单条记录分值，无加和意义 |
| `rel_raw` | 原始相关性分，属于单条记录分值，无加和意义 |
| `rel_lx` | 相关性离散档位，为标签值，直接 SUM 无业务意义 |
| `rel_add` | 附加相关性分，属于单条记录分值，无加和意义 |
| `predict_query_category` | 数组类型，需 EXPLODE 后按业务逻辑使用 |
| `query_rewrite` | 数组类型，需 EXPLODE 后分析 |
| `default_variables` | 复杂嵌套类型，需按 name 展开后使用 |
| `last_box_xy` | 数组类型，坐标数据不可直接聚合 |
| `rule_ids` | 数组类型，需 EXPLODE 后统计各规则命中情况 |
| `search_filter` | 数组类型，需 EXPLODE 后解析 JSON 使用 |

分析相关性分数时，建议使用 `AVG`、`PERCENTILE_APPROX`、分布统计等方式。

### 时效性说明

- 本表为 **每日（`_1d`）** 全量覆盖写入表，数据时效为 **T+1**（当日数据于次日写入）。
- `grass_date` 表示本地日期（local_date），已完成时区转换，非 UTC 日期。
- 关键词类目数据（`query_category`、`query_cluster`）来源于近 7 天关键词类目表（按周对齐，取上一个周日前 14 天的快照），存在 **最长约 14 天的数据滞后**，查询时须注意。
- `keyword_type` 来源于近 30 天关键词指标表，同样存在窗口数据滞后。

### 多模态场景限制

- 本表 **仅包含图搜和语音搜索场景**的数据（ETL 在 `fe_log` 阶段已过滤：`search_mid LIKE 'image%' OR search_mid = 'voice_search'`），不包含文本搜索数据。
- 语音搜索记录中 `image_url`、`image_bounding_box`、`last_md5`、`last_box_xy`、`algo_intent_search_txt` 等图搜专属字段通常为 NULL。
- 图搜记录中 `audio_url` 通常为 NULL。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_search_request_item_metrics_1d` | 主驱动表：搜索前端请求 × 商品粒度曝光日志，提供基础维度和行为字段 |
| `srdi_mart.dwd_sr_data_warehouse_search_be_log` | 后端排序日志：提供排序分、相关性分数、卡片类型、用户意图等字段 |
| `mp_paidads.dim_advertise__reg_s0_live` | 广告维度表：关联获取广告子产品类型（`sub_product_type`） |
| `srdi_mart.dwd_fp_search_query_service_request_log_1h` | Query 处理服务日志：提供 Query 改写、纠错、类目预测、默认变量等字段 |
| `srdi_mart.dws_sr_data_warehouse_search_keyword_level_metrics_30d` | 关键词 30 天搜索量指标：提供关键词搜索量分位类型（`keyword_type`） |
| `search_algo.ads_query_cat_7d` | 关键词类目归因表：提供各层级类目信息（`query_category`） |
| `mkplsearch_data_product.global_category_cluster_mapping` | 类目聚类映射表：提供类目所属搜索聚类（`query_cluster`） |
| `srdi_mart.dws_sr_data_warehouse_voice_search_session_level_metrics_1d` | 语音搜索会话指标表：提供语音搜索音频 URL（`audio_url`） |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维度表：关联获取店铺 ID（`shop_id`） |
| `srdi_mart.dws_sr_data_warehouse_ai_search_wide_metrics_1d` | AI 搜索宽表：提供算法意图文本及连续图搜序列信息 |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 平台曝光日志：提供商品曝光图片 ID（用于构建 `imp_image_url`） |
| `search_data.dim_tmp_region_domain_map` | 大区域名映射表：提供各大区的 CDN 域名（用于构建 `imp_image_url`） |

---

## ETL 逻辑摘要

### 数据流

```
dws_search_request_item_metrics_1d (多模态过滤)
        │ fe_log（主表）
        ├── LEFT JOIN be_log（后端排序 × 广告维度）     → 排序分、相关性、卡片类型、用户意图
        ├── LEFT JOIN dim_item                          → shop_id
        ├── LEFT JOIN kw_type                           → keyword_type
        ├── LEFT JOIN keyword_cat（× category_cluster） → query_category、query_cluster
        ├── LEFT JOIN deduplicated_qp_log               → 改写、纠错、类目预测、default_variables
        ├── LEFT JOIN audio_url                         → audio_url（语音搜索）
        ├── LEFT JOIN ai_search_srp_seq_info            → algo_intent_search_txt、last_md5/last_box_xy/last_keyword
        ├── LEFT JOIN imp_image_id                      → imp_image_url
        └── LEFT JOIN web_domain（BROADCAST）           → CDN 域名（构建 image_url / imp_image_url）
                                                              ↓
                    INSERT OVERWRITE dws_..._mutimodal_real_log_1d
```

### 关键步骤

1. **`fe_log`**（Temporary View）：从 `dws_sr_data_warehouse_search_request_item_metrics_1d` 过滤多模态搜索记录（`search_mid LIKE 'image%' OR search_mid = 'voice_search'`），按 `request_id / user_id / device_id / item_id / content_id` 分组聚合，标准化关键词（trim + lower），并将 `search_filter_string` 数组转换为 JSON 字符串列表。

2. **`dim_ads`**（Temporary View）：从广告维度表获取最新 `sub_product_type`，使用 `ROW_NUMBER` 去重（按 `ads_id + grass_region` 分组，取 placement 最大行）。

3. **`be_log`**（Temporary View）：从后端搜索日志过滤 `multimodal_user_intention_info IS NOT NULL` 的记录，LEFT JOIN 广告维度获取 `sub_product_type`，对不存在 ads_id 的记录使用负数伪键避免错误 JOIN，按 `request_id / item_id / sub_product_type` 聚合排序分和相关性分。将 card_type 数字映射为可读文本（1→item, 6→video, 7→livestream）。

4. **`category_cluster` & `keyword_cat`**（Temporary View）：从全局类目聚类映射和关键词类目归因表构建关键词 → L1/L2/L3 类目及所属 cluster 的映射，关键词类目数据取 `date_sub(next_day(local_date, 'sunday'), 14)` 时间点的快照（周对齐，约 14 天延迟）。

5. **`kw_type`**（Temporary View）：从 30 天关键词指标表读取关键词搜索量累计百分位，映射为 4 段区间标签。

6. **`qp_log` & `deduplicated_qp_log`**（Temporary View）：从 Query 处理服务小时日志读取跨日数据（`dt BETWEEN local_date AND local_date+1`），完成时区转换过滤出本地日期的记录，使用 `RANK()` 按 `unique_key DESC` 去重保留最新记录（`offset_rank = 1`），提取 Query 改写、纠错、类目预测及 default_variables（过滤 `attr_catid`）。

7. **`audio_url`**（Temporary View）：从语音搜索会话指标表按 `user_id / request_id / search_session_id` 聚合获取音频 URL。

8. **`dim_item`**（Temporary View）：从商品维度表获取 `item_id → shop_id` 映射。

9. **`ai_search_srp_seq_info_last_element`**（Temporary View）：从 AI 搜索宽表聚合获取算法意图文本，并使用 `ELEMENT_AT(..., -1)` 取连续图搜序列（`srp_seq_info`）的最后一个元素，用于提取 `last_md5`、`last_box_xy`、`last_keyword`。

10. **`imp_image_id`**（Temporary View）：从平台曝光日志过滤搜索页面真实曝光记录，按 `request_id / item_id / location` 聚合获取曝光图片 ID，用于构建 `imp_image_url`。

11. **`web_domain`**（Temporary View）：查询大区域名映射表，获取各大区的 CDN 域名，在 INSERT 阶段以 BROADCASTJOIN 方式 JOIN（小表广播）。

12. **`INSERT OVERWRITE`**（最终写入）：以 `fe_log` 为主表，依次 LEFT JOIN 上述所有中间视图，计算并写入目标表的对应分区（`grass_region` + `grass_date`）。关键派生逻辑：
    - `image_url`：`concat('https://search-dl-ws-latam.img.susercontent.com/', ai_search_info_md5)`
    - `image_bounding_box`：`GET_JSON_OBJECT(ai_search_info_box, '$.box_xy')`
    - `imp_image_url`：`CONCAT('https://cf.', region_domain, '/file/https://cf.', region_domain, '/file/', imp_image_id)`（imp_image_id 为 NULL 时返回 NULL）
    - `last_md5 / last_box_xy / last_keyword`：从 `srp_seq_info_last_element` JSON 中提取

### 注意事项

- **单文件单分区写入**：本表为单 ETL 文件、非 multi-writer 场景，每次执行 INSERT OVERWRITE 覆盖目标分区，无并发写入冲突风险。
- **参数化分区**：SQL 中所有分区条件均通过 `${grass_region}` / `${local_date}` / `${grass_region_without_quote}` 参数化注入，每次执行处理单个大区单日数据。
- **be_log 的 ads 伪键逻辑**：对 `ads_id` 全为 NULL 的记录使用 `xxhash64` 生成负数伪键，避免 NULL JOIN NULL 导致的错误匹配，阅读 SQL 时不要误解为数据异常。
- **qp_log 跨日读取**：Query 处理服务日志按 UTC 写入小时分区，因此需读取 `[local_date, local_date+1]` 两天数据后通过时区转换过滤，确保本地日期数据完整性。
- **keyword_cat 数据存在固定延迟**：类目归因数据对应周日对齐快照，最长滞后约 14 天，不反映最新类目变化。
- **`sub_product_type` 字段来源**：优先取 `be_log` 中通过广告维度关联到的值，与 `fe_log` 中被注释掉的同名字段逻辑不同，使用时须注意来源。
- **`image_url` CDN 域名硬编码**：当前 `image_url` 使用了 latam 地区的 CDN 前缀（`search-dl-ws-latam.img.susercontent.com`），非大区动态适配，使用时须注意是否符合目标大区预期。

---

*文档生成时间：2026-05-17*