<!-- ads-workspace-gdoc-sync: gdoc_id=1CmHEN3ykWuF_P-wUCpp1wne9EZaRWabWyP47umUIWnI gdoc_url=https://docs.google.com/document/d/1CmHEN3ykWuF_P-wUCpp1wne9EZaRWabWyP47umUIWnI/edit -->

# srdi_mart.dim_sr_data_warehouse_curated_activity_module

**分层：** DIM（维度层）
**主键：** `activity_id` + `module_id` + `module_position` + `grass_region` + `local_date`
**分区：** `grass_region`（地区）、`local_date`（本地日期）
**更新频率：** 每日全量覆盖写入（INSERT OVERWRITE）
**访问频次：** 1591 次

---

## 业务描述

本表为搜索推荐数仓中**精选活动模块（Curated Activity Module）**维度表，描述搜索流量干预规则（meddle rule）下各活动所配置的精选模块属性。

**核心业务场景：**
- 记录搜索活动（Campaign）与其关联的精选模块（Curated Module）之间的映射关系，包含模块的展示位置、URL、描述、状态等维度信息；
- 支持对搜索活动的分类分析（如大促、短期活动、常青活动、明星、联合营销等）；
- 支持基于关键词规则或店铺维度的活动圈选分析；
- 可用于排查活动干预模块的配置情况，辅助搜索流量精细化运营。

**适合回答的问题：**
- 某日某地区哪些活动的精选模块处于启用状态？
- 某活动包含哪些关键词，对应哪些精选模块？
- 各活动类别（`activity_category`）下各有多少个模块？
- 某模块在某活动中的展示位置（`module_position`）是什么？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区标识（如 SG、MY、TH 等），来自上游快照表分区 |
| `local_date` | date | 本地日期，对应上游快照日期 `grass_date`，用于每日分区 |

### 维度：活动基础信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `activity_id` | bigint | 活动唯一标识，来源于 meddle rule 主键 |
| `activity_name` | string | 活动名称 |
| `activity_category_id` | bigint | 活动类别 ID，0=Unknown，1=Big Campaign，2=Short Campaign，3=Evergreen Campaign，4=Celebrity，5=Partnership Campaign，6=Digital Product，7=Feature，8=Game |
| `activity_category` | string | 活动类别文字描述，由 `activity_category_id` 映射得出 |
| `activity_status` | bigint | 活动状态（具体枚举值参考业务系统定义） |
| `activity_start_time` | bigint | 活动开始时间（Unix 时间戳） |
| `activity_end_time` | bigint | 活动结束时间（Unix 时间戳） |
| `activity_keyword_list` | array\<string\> | 活动关联的搜索关键词列表，由 `query_rule` 的 `orConditions[0].andConditions[0].valueArray` 解析得出，已统一转小写 |
| `shop_id` | bigint | 活动关联的店铺 ID，由 `item_rule` 的 `orConditions[0].andConditions[0].valueArray` 解析得出 |
| `is_brand` | bigint | 是否品牌活动标志，当前版本固定写入 NULL，预留字段 |

### 维度：精选模块信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `module_id` | bigint | 精选模块唯一标识，来源于 meddle rule 的 `target_ext.curatedModules` 展开 |
| `module_schema_id` | bigint | 模块 Schema 类型 ID，决定模块元素的解析方式（1/2/4 为单元素模式，5 为多元素列表模式） |
| `module_status` | bigint | 模块状态（具体枚举值参考业务系统定义） |
| `module_name` | string | 模块名称，已做标准化处理（trim、转小写、连字符替换为空格） |
| `module_url` | string | 模块跳转链接，已做 trim 和转小写处理 |
| `module_description` | string | 模块描述文本，已做 trim 和转小写处理 |
| `module_position` | int | 模块在活动内的展示位置序号（对应 `schema_id=5` 的多元素拆解后的 position，`schema_id` 为 1/2/4 时固定为 0） |

---

## 查询使用须知

### 必须包含的过滤条件

- **查询时必须同时指定 `grass_region` 和 `local_date` 两个分区字段**，否则将触发全分区扫描，严重影响性能。
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-01'
  ```
- 如需跨日期分析，建议限定合理的日期范围（如最近 7 天）。

### 不可直接 SUM 的字段

- `activity_start_time`、`activity_end_time`：时间戳字段，不具备累加语义，仅用于时间范围过滤和格式转换。
- `module_position`：位置序号，不可累加，用于排序或过滤。
- `activity_status`、`module_status`：枚举状态值，不可直接聚合，应用于分组或过滤。
- `is_brand`：当前版本恒为 NULL，使用时注意 NULL 处理。

### 粒度说明

- 本表的数据粒度为 **活动 × 精选模块 × 模块展示位置 × 地区 × 日期**。
- 同一 `activity_id` 可对应多个 `module_id`（一个活动包含多个模块）；
- 同一 `module_id` 在 `module_schema_id=5` 时会按元素位置拆开为多行（`module_position` 不同），统计模块数量时需注意去重。
- `activity_keyword_list` 和 `shop_id` 仅反映 `query_rule` / `item_rule` 第一个 `orConditions[0].andConditions[0]` 条件的内容，不覆盖全部条件组合。

### 时效性说明

- 本表为**每日快照表**，每次运行以 INSERT OVERWRITE 全量刷新对应 `(grass_region, local_date)` 分区，数据反映当日上游 meddle rule 的配置状态。
- 历史分区数据在写入后不会自动更新，若上游规则被追溯修正需关注 ETL 是否重跑历史分区。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `mp_search.ods_shopee_search_traffic_meddle_db__meddle_rule_v2_tab_snapshot` | 搜索流量干预规则快照表，提供活动基础信息（活动 ID、名称、时间、状态、类别）、关键词规则（`query_rule`）、商品规则（`item_rule`）以及精选模块配置（`target_ext.curatedModules`） |

---

## ETL 逻辑摘要

### 数据流

```
ods_shopee_search_traffic_meddle_db__meddle_rule_v2_tab_snapshot
    │  过滤当日 (grass_date=local_date)、当地区 (grass_region)、本地时区 (tz_type='local')
    ▼
curated_search_data_0  -- 活动基础字段提取 + JSON 解析（关键词、shop_id、模块列表）
    ▼
curated_search_data_1  -- 展开 curatedModules 列表（explode）+ 解析每个模块 JSON
    ▼
curated_search_data_2  -- 按 module_schema_id 组装模块元素数组（elements）
    ▼
curated_search_data_3  -- 展开 elements（explode）+ 提取 url/image/icon/description/position
    ▼
srdi_mart.dim_sr_data_warehouse_curated_activity_module  -- INSERT OVERWRITE 写入目标分区
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| Statement 1 | `curated_search_data_0` | 从上游快照表读取当日当区数据；使用嵌套 `from_json` 解析 `query_rule` 得到 `activity_keyword_list`；解析 `item_rule` 得到 `shop_id`；解析 `target_ext.curatedModules` 得到模块列表 `module_data_list`；映射 `activity_category_id` 为 `activity_category` 文字描述 |
| Statement 2 | `curated_search_data_1` | 对 `module_data_list` 执行 `explode` 展开为单条模块记录；解析模块 JSON 得到 `module_schema_id`、`module_status`、`module_name` 及各多链接元素字段（icon1-4、text1-4、link1-4）；构建 `module_elements`（通用）和 `module_elements1~4`（多元素模式） |
| Statement 3 | `curated_search_data_2` | 依据 `module_schema_id` 组装 `elements` 数组：`schema_id=5` 时动态拼接最多 4 个元素子数组（按非空判断截断）；`schema_id` 为 1/2/4 时使用单元素数组；其他情况填充 NULL 占位 |
| Statement 4 | `curated_search_data_3` | 对 `elements` 执行 `explode` 展开，从每个 element 数组中提取 `module_url`（index 0）、`module_image`（index 1）、`module_icon`（index 2）、`module_description`（index 3）、`module_position`（index 4） |
| Statement 5 | 目标表写入 | INSERT OVERWRITE 写入指定 `(grass_region, local_date)` 分区；`activity_keyword_list` 统一转小写（`transform(..., x -> lower(x))`）；`shop_id` 转 BIGINT；`is_brand` 固定写 NULL |

### 注意事项

- **multi-writer：** 本表仅由单个 ETL 文件写入，不存在多写并发风险。
- **分区写入：** 采用 INSERT OVERWRITE PARTITION 模式，每次执行覆盖当日当区分区，幂等性良好，可安全重跑。
- **JSON 解析容错：** `query_rule` 和 `item_rule` 的解析链路较深（三层嵌套 from_json），若上游数据格式不规范或字段缺失，对应字段会返回 NULL，不会导致任务失败，但数据可能不完整。
- **shop_id 解析限制：** ETL 仅提取 `item_rule` 第一个 orCondition 第一个 andCondition 的 valueArray 的第一个值，若活动配置多店铺规则，其余 shop_id 不会体现在本表中。
- **is_brand 字段：** 当前版本固定写入 NULL，为预留字段，下游使用时需做 NULL 判断，不可直接依赖该字段过滤。
- **module_position 与行粒度：** `schema_id=5` 的模块会被拆为多行，下游 JOIN 时需注意行数膨胀，统计 `module_id` 数量时应在 `module_position` 维度上去重。

---

*文档生成时间：2026-05-17*