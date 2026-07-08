<!-- ads-workspace-gdoc-sync: gdoc_id=1ge_F6j_CRtF_p30Qoc3uNqQEasfKl0wp4cyhY3-ykrI gdoc_url=https://docs.google.com/document/d/1ge_F6j_CRtF_p30Qoc3uNqQEasfKl0wp4cyhY3-ykrI/edit -->

# Columns: sgbi_general.smart_abt_user_split

## Column Usage Notes

### 枚举值映射 (Value Mappings)

exp_group 到 group_name 的映射（2+ 文件确认）：

| Column | Value | Meaning |
|--------|-------|---------|
| exp_group | Smart ABT Group | mp_plus_ads (treatment) |
| exp_group | ABT Group | mp_plus_ads (treatment, variant) |
| exp_group | Global Control | control |
| exp_group | Local Sandbox | control |

### 常见 WHERE 值 (Common Filter Values)

- `grass_date`: 固定日期 `DATE '2026-04-01'` / `DATE '2026-05-01'` / `DATE '2026-06-01'`，或动态分区 `max(grass_date) WHERE date(...) >= grass_date`
- `exp_group`: IN ('Smart ABT Group'), IN ('Global Control', 'Local Sandbox')

### 非累加字段 (Non-Additive Fields)

- `user_id` -- 跨 exp_group / grass_date 聚合时必须用 `COUNT(DISTINCT user_id)`

### 分区策略

- 有一个姊妹表 `sgbi_general.smart_abt_user_split_25sss` 用于每月 25 号的数据补丁（`WHERE day(grass_date) IN (25)`），主表和 25sss 表通过 UNION 组合获取完整用户分片

## All Columns

DDL 未在代码库中找到，以下列为从实际 SQL 使用中推断。完整列清单请运行 `--source from-di` 补充。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | date | AB test split date (partition column) | - | - |
| exp_group | string | Experiment group name (Smart ABT Group / Global Control / Local Sandbox) | - | - |
| user_id | string | User identifier | - | - |
