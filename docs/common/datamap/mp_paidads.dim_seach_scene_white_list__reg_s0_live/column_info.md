<!-- ads-workspace-gdoc-sync: gdoc_id=1AJZPyOgBLuoxOGVMFZO2jG5ppNBtuTTSlAdUhWdzihs gdoc_url=https://docs.google.com/document/d/1AJZPyOgBLuoxOGVMFZO2jG5ppNBtuTTSlAdUhWdzihs/edit -->

# Columns: mp_paidads.dim_seach_scene_white_list__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

N/A（维度表，无指标列）

### 枚举值映射 (Value Mappings)

未在代码库中找到 CASE-WHEN 枚举映射。

### 常见 WHERE 值 (Common Filter Values)

该表在查询中始终以全量形式使用（`SELECT scene_id / layer_id FROM ...`），不施加额外的 WHERE 过滤条件。

## All Columns

> 注意：代码库中未找到 CREATE TABLE DDL，以下列从实际 SQL 查询中推断。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| scene_id | - | 搜索场景 ID，用于 JOIN 过滤 AB test 的搜索场景曝光/点击日志 | - | - |
| layer_id | - | AB 实验层 ID，用于 JOIN 过滤搜索相关的实验层 | - | - |
