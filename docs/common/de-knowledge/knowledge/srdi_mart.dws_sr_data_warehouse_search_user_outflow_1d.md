<!-- ads-workspace-gdoc-sync: gdoc_id=1-nrfHC7j1ilis5eN6jN7iyyHGXvtAIa7LJiCUedygEw gdoc_url=https://docs.google.com/document/d/1-nrfHC7j1ilis5eN6jN7iyyHGXvtAIa7LJiCUedygEw/edit -->

# srdi_mart.dws_sr_data_warehouse_search_user_outflow_1d

**分层：** dws_search
**主键：** user_id（分区内唯一）
**分区：** grass_region / local_date
**更新频率：** 每日全量覆盖（INSERT OVERWRITE）
**引用频次 / 访问频次：** 786

---

## 业务描述

本表为搜索域**用户级别**的每日聚合宽表，核心目标是刻画用户在**搜索相关页面首次曝光（First View）行为**及**离开搜索页面后的流向（Outflow）分布**。

表中对三类搜索入口页面分别建模：

| 前缀 | 页面类型 | 说明 |
|------|----------|------|
| `srp_` | 搜索结果页（SRP） | `global_search` / `search_in_pdp` / `search_prefill` 统一归类为 `srp` |
| `sdp_` | 搜索默认页（Pre-Search Page） | `pre_search` |
| `sup_` | 搜索建议页（Search Suggest Page） | `search_suggest_page` |

**适合回答的典型问题：**
- 某用户当日在 SRP / SDP / SUP 的首次访问上下文是什么（会话、入口、版本等）？
- 用户从各搜索页面跳转到哪些下游页面（Outflow）？
- 搜索用户在不同搜索入口之间的流转路径分布？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 区域分区，如 ID、MY、TH 等 Shopee 站点代码 |
| `local_date` | date | 数据日期（本地时区），按天分区 |

### 维度：用户标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | bigint | 用户 ID，分区内唯一，仅统计登录用户（user_id > 0） |

### 维度：SRP 首次访问上下文

> 以下字段取用户当日在 SRP 页（`global_search` / `search_in_pdp` / `search_prefill`）中**时间戳最早**的一次 view 事件对应属性。

| 字段 | 类型 | 说明 |
|------|------|------|
| `srp_fv_vid` | string | SRP 首次访问的 event_id（页面 View ID） |
| `srp_fv_search_mid` | string | SRP 首次访问的搜索 mid（关键词标识） |
| `srp_fv_search_entrance` | string | SRP 首次访问的搜索入口来源 |
| `srp_fv_last_lvid` | string | SRP 首次访问时的上一个 view event_id（来源页面追踪） |
| `srp_fv_search_session_id` | string | SRP 首次访问时所属的搜索会话 ID |
| `srp_fv_global_session_id` | string | SRP 首次访问时所属的全局会话 ID |
| `srp_fv_rn_version` | string | SRP 首次访问时的 React Native 版本号 |
| `srp_fv_platform` | string | SRP 首次访问时的平台（iOS / Android 等） |
| `srp_fv_app_version` | string | SRP 首次访问时的 App 版本号 |

### 维度：SDP 首次访问上下文

> 以下字段取用户当日在 SDP 页（`pre_search`）中**时间戳最早**的一次 view 事件对应属性。

| 字段 | 类型 | 说明 |
|------|------|------|
| `sdp_fv_vid` | string | SDP 首次访问的 event_id（页面 View ID） |
| `sdp_fv_search_entrance` | string | SDP 首次访问的搜索入口来源 |
| `sdp_fv_last_lvid` | string | SDP 首次访问时的上一个 view event_id（来源页面追踪） |

### 维度：SUP 首次访问上下文

> 以下字段取用户当日在 SUP 页（`search_suggest_page`）中**时间戳最早**的一次 view 事件对应属性。

| 字段 | 类型 | 说明 |
|------|------|------|
| `sup_fv_vid` | string | SUP 首次访问的 event_id（页面 View ID） |
| `sup_fv_search_entrance` | string | SUP 首次访问的搜索入口来源 |
| `sup_fv_last_lvid` | string | SUP 首次访问时的上一个 view event_id（来源页面追踪） |

### 指标：用户搜索页流出信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `srp_outflow_page` | array\<string\> | 用户从 SRP 流出后访问的页面类型去重集合 |
| `srp_outflow_info` | array\<string\> | 用户从 SRP 流出的详细信息，每个元素为 JSON 字符串，包含 `page_type`（目标页）、`outflow_times`（去重跳转次数）、`current_page`（当前页标识集合） |
| `sdp_outflow_page` | array\<string\> | 用户从 SDP 流出后访问的页面类型去重集合 |
| `sdp_outflow_info` | array\<string\> | 用户从 SDP 流出的详细信息，结构同 `srp_outflow_info` |
| `sup_outflow_page` | array\<string\> | 用户从 SUP 流出后访问的页面类型去重集合 |
| `sup_outflow_info` | array\<string\> | 用户从 SUP 流出的详细信息，结构同 `srp_outflow_info` |

---

## 查询使用须知

### 必须指定的过滤条件

```sql
WHERE grass_region = '<region>'
  AND local_date = '<yyyy-MM-dd>'
```

- `grass_region` 和 `local_date` 均为分区字段，**每次查询必须同时指定**，否则将触发全表扫描，导致资源超限或超时。
- 表按天做 INSERT OVERWRITE，**查询当天数据需等 ETL 任务完成后**方可使用。

### 不可直接 SUM / 聚合的字段

| 字段 | 原因 |
|------|------|
| `srp_outflow_info` / `sdp_outflow_info` / `sup_outflow_info` | 数组元素为 JSON 字符串，包含预聚合的去重次数（`outflow_times` 基于 `count(distinct event_id)` 计算），跨用户汇总需先解析 JSON 再重新聚合 |
| `srp_outflow_page` / `sdp_outflow_page` / `sup_outflow_page` | 集合类型（`COLLECT_SET`），跨用户聚合需使用 `array_union` 或 `explode` 后再聚合 |
| `srp_fv_*` / `sdp_fv_*` / `sup_fv_*` 各首访字段 | 均为单用户当日首次访问的属性快照，不具有可加性，汇总分析需 `COUNT(DISTINCT ...)` 或先 GROUP BY user_id |

### 时效性说明

- 本表为 `_1d` 后缀的**天级**聚合表，数据反映**自然日**内用户行为的全量汇总（本地时区）。
- 无实时/准实时能力，依赖 T+1 ETL 产出；**当日数据不可用**。
- 不同 `grass_region` 分区由同一 ETL 任务参数化执行，各区域时效性可能略有差异，请以各区域 ETL 调度完成时间为准。

### array\<string\> 字段解析示例

```sql
-- 解析 srp_outflow_info，获取各目标页面的跳转次数
SELECT
    user_id,
    get_json_object(info_item, '$.page_type') AS target_page,
    get_json_object(info_item, '$.outflow_times') AS outflow_times
FROM srdi_mart.dws_sr_data_warehouse_search_user_outflow_1d
LATERAL VIEW explode(srp_outflow_info) t AS info_item
WHERE grass_region = 'ID'
  AND local_date = '2026-05-16';
```

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `srdi_mart.dwd_sr_data_warehouse_search` | 搜索域 DWD 层明细表，提供搜索页面的 view 事件，用于构建用户首访（First View）信息 |
| `traffic.shopee_traffic_dwd_view_hi__reg_s1_live` | 全平台页面 view 事件流水，用于识别搜索页流出后的下游页面及 last_view_event_id / civ_id 关联 |
| `traffic.shopee_traffic_dwd_click_hi__reg_s1_live` | 全平台点击/行为事件流水，用于补充 `action_app_went_background` 场景（用户将 App 切至后台） |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dwd_sr_data_warehouse_search
        │
        ▼
[dwd_search_page]          ← 过滤搜索页 view 事件，统一页面类型，计算时间排名
        │
        ▼
[dws_search_user_fv]       ← 按 user_id + page_type 取时间排名第一的首访属性
        │
        ▼──────────────────────────────────────────────────┐
                                                           │
traffic.shopee_traffic_dwd_view_hi                         │
traffic.shopee_traffic_dwd_click_hi                        │
        │                                                  │
        ▼                                                  │
[dwd_platform_page]        ← 全平台 view/background 事件，计算用户全局访问排名
[dwd_all_search_event_id]  ← 搜索页 event_id 集合（用于 last_view 关联）
[dwd_all_search_civ_id]    ← 搜索页 civ_id 集合（用于 last_view_civ 关联）
        │
        ▼
[dwd_attribute_search_page] ← 归因：通过 last_view_event_id / last_view_civ_id 将
                              下游页面关联回搜索来源页，补充 home 页的 PATH_ROOT 场景
        │
        ▼
[dws_search_outflow]        ← 按 (user_id, source_page_type, page_type) 聚合流出次数
        │
        ▼
[dws_search_outflow_res]    ← 按 user_id 透视为 srp/sdp/sup 三类流出字段
        │
        ▼──────────────────────────────────────────────────┘
              FULL OUTER JOIN on user_id
                    │
                    ▼
    srdi_mart.dws_sr_data_warehouse_search_user_outflow_1d
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 核心逻辑 |
|------|----------------------|----------|
| 1 | `dwd_search_page` | 从 DWD 搜索表过滤当日区域的 view 事件（仅搜索相关页），将 `global_search`/`search_in_pdp`/`search_prefill` 统一映射为 `srp`；使用 `RANK()` 按 `(user_id, page_type, event_timestamp)` 计算页面内访问顺序 |
| 2 | `dws_search_user_fv` | 按 `user_id` 聚合，`WHERE time_rank = 1` 保留首次访问，`max(if(page_type = 'srp', field, NULL))` 透视三类页面的首访属性 |
| 3 | `dwd_platform_page`（CACHE） | 从流量 view 表读取全平台页面访问事件，`UNION ALL` 补充 App 进入后台事件；`last_view_event_id` / `last_view_civ_id` 为空时用随机盐值填充以避免错误 JOIN；按 `(user_id, event_timestamp)` 全局计算 `time_rank` |
| 4 | `dwd_all_search_event_id` | 从流量 view 表收集搜索页 event_id 集合，用于后续 last_view 归因 |
| 5 | `dwd_all_search_civ_id` | 从流量 view 表收集搜索页 civ_id 集合，用于后续 last_view_civ 归因 |
| 6 | `dwd_attribute_search_page` | 将全平台页面通过 `last_view_event_id` / `last_view_civ_id` LEFT JOIN 搜索事件，识别"从搜索页流出"的目标页面；额外通过相邻 `time_rank` INNER JOIN 补充从 SDP/SUP 直接返回 home（`PATH_ROOT_FIRST`）的场景 |
| 7 | `dws_search_outflow` | `LATERAL VIEW explode(source_page_types)` 展开来源页面类型，按 `(user_id, source_page_type, page_type)` 聚合，计算 `count(distinct event_id)` 作为流出次数，并收集 `current_page` 集合，序列化为 JSON |
| 8 | `dws_search_outflow_res` | 按 `user_id` 聚合，透视为 `srp_outflow_*` / `sdp_outflow_*` / `sup_outflow_*` 三组字段 |
| 9 | INSERT OVERWRITE | `dws_search_user_fv` FULL OUTER JOIN `dws_search_outflow_res` on `user_id`，写入目标表指定分区 |

### 注意事项

1. **单文件写入，无 multi-writer 风险**：本表仅由单个 ETL 文件写入，不存在多 writer 并发覆盖问题。
2. **CACHE TABLE 使用**：`dwd_platform_page` 使用 `CACHE TABLE` 缓存，该视图被后续多个 statement 复用；若 Spark 集群内存不足，可能导致 cache 失效并触发重算，需关注资源配置。
3. **随机盐值填充**：`last_view_event_id` 和 `last_view_civ_id` 为空时填充随机盐值（`salt_<rand>`），目的是防止 NULL 值在 JOIN 时出现大量 NULL-NULL 匹配；下游使用时无需关注此处理细节，但不应对这两个字段的原始值做语义解析。
4. **FULL OUTER JOIN 导致 user_id 可能来自任意一侧**：最终 SELECT 使用 `COALESCE(a.user_id, b.user_id)` 合并两侧 user_id，确保首访信息或流出信息仅有其一的用户也被保留。
5. **`outflow_times` 基于去重 event_id 计算**：`srp/sdp/sup_outflow_info` 中的 `outflow_times` 字段是 `count(distinct event_id)` 的预聚合结果，**跨行直接相加会导致重复计数**，多用户汇总需重新从明细层聚合。
6. **分区参数化执行**：ETL 通过 `${grass_region}` / `${local_date}` / `${grass_region_without_quote}` 参数化，支持按区域独立调度，不同区域的数据互不干扰。

---

*文档生成时间：2026-05-17*