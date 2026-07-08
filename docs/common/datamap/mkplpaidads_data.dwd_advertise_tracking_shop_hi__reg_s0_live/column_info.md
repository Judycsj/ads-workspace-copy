<!-- ads-workspace-gdoc-sync: gdoc_id=1MRMfUeNqltvk7A6hk-WlQK49KhANt8Jultr0q_y7wPc gdoc_url=https://docs.google.com/document/d/1MRMfUeNqltvk7A6hk-WlQK49KhANt8Jultr0q_y7wPc/edit -->

# Columns: mkplpaidads_data.dwd_advertise_tracking_shop_hi__reg_s0_live

> **注意**: 以下列名为从代码库 SQL 中提取；DDL 未在代码库中找到，列类型为推断值。运行 `--source from-di` 可补充实际类型和描述。

## Column Usage Notes

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| operation | 1001 | Impression (曝光) |
| operation | 1002 | Click (点击) |
| operation_desc | SHOP_IMPRESSION | Impression (曝光) |
| operation_desc | SHOP_CLICK | Click (点击) |
| ads_placement | 3, 20, 2003 | Shop Ads placements |
| ads_placement | 2030 | Game Ads placement |
| ads_placement | 45 | Shop Ads (additional) |

### 常见 WHERE 值 (Common Filter Values)

- `grass_date`: 通常用于范围过滤 (BETWEEN start_date AND end_date) 或精确日期匹配
- `grass_region`: 标准8区 ('SG','TW','MY','ID','VN','PH','TH','BR')，也有单区 'BR'
- `ads_placement`: 3, 20, 2003 (Shop Ads); 2030 (Game Ads); 45
- `operation`: 1001 (impression), 1002 (click) — 最常用
- `operation_desc`: 'SHOP_CLICK', 'SHOP_IMPRESSION' — 用于 Game Ads 场景
- `ads_request_id`: IS NOT NULL — 几乎所有查询都要求非空
- `ads_id` > 0 — AUC 计算场景
- `user_id` > 0 — 关键词样本生成
- `shop_item_id_1/2/3 IS NOT NULL` 且 `items IS NOT NULL` — 关键词相关性采样
- `ab_sign`: regexp_like 管道符匹配 — AB 实验筛选
- `bid_rerank_trace IS NOT NULL` — Game Ads pcr_0 提取

## All Columns

| Column Name | Type | Description |
|-------------|------|-------------|
| grass_date | DATE | 日期分区 |
| grass_region | STRING | 国家/区域分区 |
| ads_placement | INT | 广告位 ID |
| tracking_placement | INT | 追踪广告位 ID (Game Ads 使用) |
| inner_placement | INT | 内部广告位 ID (Game Ads 使用) |
| ads_id | BIGINT | 广告 ID |
| ads_request_id | VARCHAR | 广告请求 ID (用于 JOIN performance 表) |
| shop_id | BIGINT | 店铺 ID |
| user_id | BIGINT | 用户 ID |
| session_id | VARCHAR | 会话 ID |
| operation | INT | 操作类型: 1001=曝光, 1002=点击 |
| operation_desc | VARCHAR | 操作描述: SHOP_IMPRESSION, SHOP_CLICK |
| ab_sign | VARCHAR | AB 实验标签 (管道符分隔)，如 `\|663696\|` |
| ads_entrance | VARCHAR | 广告入口 ID (Game Ads 使用), 如 '24' |
| platform | VARCHAR | 平台 |
| timestamp | BIGINT | Unix 时间戳 |
| shop_json_data | STRING/JSON | 模型预估分数 JSON: `$.pCR`, `$.pCTR` |
| bid_rerank_trace | STRING/JSON | 精排出价追踪 JSON: `$.pcr_0`, `$.adjusted_bid_price`, `$.direct_pcr_7d` |
| query | STRUCT | 查询关键词: `query.keyword` |
| shop_item_id_1 | BIGINT | 推荐店铺商品 ID 1 |
| shop_item_id_2 | BIGINT | 推荐店铺商品 ID 2 |
| shop_item_id_3 | BIGINT | 推荐店铺商品 ID 3 |
| items | ARRAY/? | 推荐商品列表 |

<!-- ANALYSIS_PLACEHOLDER -->
