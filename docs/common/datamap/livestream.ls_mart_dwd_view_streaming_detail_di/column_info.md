<!-- ads-workspace-gdoc-sync: gdoc_id=1cHCQxEtdVrTduhXQC15-5suXsOE5iCT5dEeuQv2foxc gdoc_url=https://docs.google.com/document/d/1cHCQxEtdVrTduhXQC15-5suXsOE5iCT5dEeuQv2foxc/edit -->

# Columns: livestream.ls_mart_dwd_view_streaming_detail_di

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

*未识别到非累加字段（from-code 分析中未发现 SUM(DISTINCT) 模式）*

### 枚举值映射 (Value Mappings)

*未识别到枚举映射（from-code 分析中未发现 2+ 文件重复出现的 CASE-WHEN 映射）*

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (100% 查询使用)
- `grass_date`: `date('${grass_date}')` (分区裁剪)
- `grass_region`: `upper('${region}')` (单地区过滤)

## All Columns

*仅 from-code 提取，列名来源 SQL 引用（非 DDL），description/query frequency/MAX 待 from-di 补充*

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | - | 数据日期（分区列） | - | - |
| grass_region | - | 地区（分区列） | - | - |
| tz_type | - | 时区类型 | - | - |
| viewer_id | - | 观看者用户 ID | - | - |
| view_event_id | - | 观看事件 ID，用于 JOIN session 表 | - | - |
| duration_b | - | 观看时长（秒） | - | - |
