<!-- ads-workspace-gdoc-sync: gdoc_id=1XG2v_zngF22eJ67TKm6TCoWTHvPTabcRxVWAl52myXk gdoc_url=https://docs.google.com/document/d/1XG2v_zngF22eJ67TKm6TCoWTHvPTabcRxVWAl52myXk/edit -->

# Columns: opa_audiencemanager_crm_analystics.dim_crm_user_task_view_vn

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

{from-code: 未发现 SUM(DISTINCT) 或 MAX 等非累加模式}

此表仅用于提取用户 ID 列表（`select distinct user_id`），所有字段均为用户属性，不涉及跨维度聚合。

### 枚举值映射 (Value Mappings)

{from-code: 从 CASE-WHEN 和 WHERE 子句提取，2+ 文件出现}

**user_label_list 字段格式**（键值对，逗号分隔）：

| Column | Value | Meaning |
|--------|-------|---------|
| user_label_list | Is_Target:false,Treatment_Group:C | 对照组 C |
| user_label_list | Is_Target:false,Treatment_Group:A | 对照组 A |
| user_label_list | Is_Target:true,Treatment_Group:B | 实验组 B |
| is_target | 'true' | 目标用户（实验组） |
| is_target | 'false' | 非目标用户（对照组） |

**注意**: `user_label_list` 和 `is_target` 是不同 version_id 下使用的不同字段体系：
- 较新版本 (version_id >= 10969): 使用 `user_label_list` 字段（格式: `Is_Target:<bool>,Treatment_Group:<A/B/C>`）
- 较旧版本 (version_id 10554/10571): 两者混用（同一天有的用 `user_label_list`，有的用 `is_target`）

### 常见 WHERE 值 (Common Filter Values)

{from-code: 从 WHERE 子句提取}

- `grass_region`: 始终为 'VN'（此表仅含越南站数据）
- `date(grass_date)`: 按 version_id 对应的固定日期过滤（非范围查询）
- `version_id`: 精确匹配某个版本号
  - 11788 (2026-05-22)
  - 11390 (2026-04-22)
  - 10969 (2026-03-26)
  - 10571 (2026-02-25)
  - 10554 (2026-02-24)

## All Columns

{from-code 无 DDL，列名从 SQL 引用中提取}

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_region | - | 国家/区域（固定 'VN'） | - | - |
| grass_date | - | 数据日期（分区列） | - | - |
| user_id | - | 用户 ID | - | - |
| version_id | - | 任务版本号 | - | - |
| user_label_list | - | 用户标签列表（键值对格式，逗号分隔） | - | - |
| is_target | - | 是否目标用户（'true'/'false'） | - | - |
