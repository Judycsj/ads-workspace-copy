<!-- ads-workspace-gdoc-sync: gdoc_id=1N0ZDijtWD43GbNxDi4jz1EJET5vx0hy7v22eWQB2Jdk gdoc_url=https://docs.google.com/document/d/1N0ZDijtWD43GbNxDi4jz1EJET5vx0hy7v22eWQB2Jdk/edit -->

# Columns: mp_foa.dim_search_domain_map__reg_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

未检测到（纯维度表，代码中使用 GROUP BY scenario_key, mapped_page_type 去重读取）

### 枚举值映射 (Value Mappings)

未检测到（代码中未对该表的列做 CASE-WHEN 转换）

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: upper('${region}') — 标准 11 区 (BR, CL, CO, ID, MX, MY, PH, SG, TH, TW, VN)
- `grass_date`: 子查询取 `max(grass_date)`，始终读取最新分区 (~100% 查询)

## All Columns

以下列名从代码引用中推断。完整 DDL 列清单需运行 `--source from-di` 补充。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| scenario_key | string | 搜索场景标识键 | - | - |
| mapped_page_type | string | 映射后的页面类型 | - | - |
| grass_date | date | 分区日期 | - | - |
| grass_region | string | 分区区域 | - | - |
