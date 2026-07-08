<!-- ads-workspace-gdoc-sync: gdoc_id=1JGqo3OHWEcC0Q2bwTFp88YdM2IMpA3jozobjlrkDhC4 gdoc_url=https://docs.google.com/document/d/1JGqo3OHWEcC0Q2bwTFp88YdM2IMpA3jozobjlrkDhC4/edit -->

# Columns: mp_paidads.dim_entry_point_mapping

> **Contributors**: luka.yang ｜ **最后更新**：2026-06-16 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/datamap/mp_paidads.dim_entry_point_mapping/column_info.md)

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

此表为维度映射表，不含度量字段，无非累加问题。

### 枚举值映射 (Value Mappings)

此表本身即为枚举映射表，核心功能是将 `(entrance, sub_entrance)` 组合映射到 `entry_point`。

**sub_entrance 语义**（从代码中提取）:

| sub_entrance 值 | 含义 | 代码引用 |
|----------------|------|---------|
| 0, NULL, '' | 主入口映射（对应 entrance 的唯一 entry_point） | `WHERE sub_entrance IS NULL OR sub_entrance = ''` |
| > 0 | 子入口映射（同一 entrance 下细分场景） | `WHERE sub_entrance > 0` |
| 310103 | Video 广告子入口 | `ods_log_translog_event_hi` JOIN 中硬编码 |

**JOIN 时 COALESCE 优先级模式**:
```sql
-- 优先用 sub_entrance 精确匹配，fallback 到 entrance-only 匹配，最后回退到 'Undefined'
COALESCE(b.entry_point, c.entry_point, 'Undefined') AS entry_point
```

### 常见 WHERE 值 (Common Filter Values)

- `sub_entrance > 0`: 子入口映射过滤（maintaining sub_entrance mapping view）
- `(sub_entrance IS NULL OR sub_entrance = '')`: 主入口映射过滤（maintaining entrance mapping view）
- `GROUP BY entry_point, entrance, sub_entrance`: 去重组合

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| entrance | string/int | 广告入口数值 ID，核心 JOIN 键，join 时通常 `cast(entrance as int)` 或 `cast(target.entrance as varchar)` | - | - |
| sub_entrance | string/bigint | 子入口标识，> 0 表示有子入口细分，为 NULL/0/'' 时表示主入口。join 时通常 `cast(sub_entrance as bigint)` | - | - |
| entry_point | string | 入口可读名称（如 "Search", "Daily Discover"），通过 `CAST(entrance AS int)` 和 sub_entrance 联合查询 | - | - |

*注：列名和类型从代码中 SELECT/JOIN 推断，未找到 DDL。完整列信息请运行 `--source from-di` 补充。*
