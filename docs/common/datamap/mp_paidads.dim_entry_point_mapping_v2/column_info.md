<!-- ads-workspace-gdoc-sync: gdoc_id=1yZZ_DuyGLfZybpqog_Gnvzg4K4vzOssg8KxANMbHWkQ gdoc_url=https://docs.google.com/document/d/1yZZ_DuyGLfZybpqog_Gnvzg4K4vzOssg8KxANMbHWkQ/edit -->

# Columns: mp_paidads.dim_entry_point_mapping_v2

> **Contributors**: luka.yang ｜ **最后更新**：2026-06-15 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/datamap/mp_paidads.dim_entry_point_mapping_v2/column_info.md)

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

此表为维度映射表，不含度量字段，无非累加问题。

### 枚举值映射 (Value Mappings)

此表本身即为枚举映射表，其核心功能是将数值型 `entrance` 映射到可读的 `entry_point` 和 `traffic_type`。

**traffic_type 已知值**（从代码中提取）:

| Column | Value | Meaning |
|--------|-------|---------|
| traffic_type | Livestream | 直播广告场景 |
| traffic_type | Brand | 品牌广告场景 |
| traffic_type | Video | 视频广告场景 |
| traffic_type | (其他) | Product Ads 等 |

**entrance 已知值**（从代码中提取的常见入口 ID）:

| entrance | 推测场景 | 来源 |
|----------|----------|------|
| 1 | Search（搜索） | 多处代码注释 + WHERE 条件 |
| 3 | Daily Discover (DD) | 代码注释 |
| 4 | YMAL (You May Also Like) | 代码注释 |
| 5 | Search 相关 | 与 entrance=1 同组 |
| 6, 59 | 未分类 | app_version 过滤 |
| 7,14,15,16,17,18,19,20,22,30,41,47 | Game/Shop/Coins 等 | rn_version 过滤 |
| 8, 9, 10, 11 | Product Page (PP) | 代码注释 |
| 21, 24, 49, 52, 53 | 无版本限制的入口 | 直接列举 |
| 23 | Image Search | 代码注释 |
| 27, 28, 38, 39, 42, 48 | Livestream | 代码注释 |
| 29, 33, 34, 50, 55, 56, 58, 51 | Video | 代码注释 |
| 31, 32, 62, 63, 64, 65, 66, 67, 68, 69, 72, 73, 74 | 新入口（无版本限制） | 直接列举 |
| 37 | Homepage (HP) | 与 entrance=3 同组 |
| 40 | 未分类 | dre_version 过滤 |
| 45 | 未分类 | rn_version + app_version 过滤 |
| 54 | PDP | 代码注释 |
| 57 | Product Page 相关 | 与 8,9,10,11 同组 |
| 60 | Search 相关 | 与 1,5 同组 |

### 常见 WHERE 值 (Common Filter Values)

- `sub_entrance`: 常用 `WHERE (sub_entrance IS NULL OR sub_entrance = '')` 过滤主入口映射
- `entrance`: `IS NOT NULL` 过滤
- `traffic_type`: `IS NOT NULL` 过滤
- `entry_point`: `IS NOT NULL` 过滤

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| entrance | string | 广告入口数值 ID，用于与其他表 JOIN | - | - |
| entry_point | string | 入口可读名称 (如 "Search", "Daily Discover") | - | - |
| traffic_type | string | 流量类型分类 (如 "Livestream", "Brand", "Video") | - | - |
| sub_entrance | string | 子入口标识，为空或 NULL 时表示主入口映射 | - | - |
| common_feature | string | 通用特征标识 | - | - |

*注：列名和类型从代码中 SELECT/JOIN 推断，未找到 DDL。完整列信息请运行 `--source from-di` 补充。*
