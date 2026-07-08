<!-- ads-workspace-gdoc-sync: gdoc_id=1VT-DLrm5XwPxjGPLF30fz3oS9u3iitXH1f0NoMq5Dq4 gdoc_url=https://docs.google.com/document/d/1VT-DLrm5XwPxjGPLF30fz3oS9u3iitXH1f0NoMq5Dq4/edit -->

# Columns: mp_paidads.dim_campaign_day__reg_s0_live

## Column Usage Notes

### 核心使用模式

本表为维度表，核心用途是**排除大促日**对日常指标的影响。campaign_day 列被下游任务以多种方式引用：

1. **子查询排除** (`NOT IN (SELECT campaign_day FROM dim_campaign_day__reg_s0_live)`) -- 最常用
2. **LEFT JOIN 排除** (`LEFT JOIN ... ON grass_date = campaign_day WHERE campaign_day IS NULL`)
3. **LEFT ANTI JOIN 排除** (`LEFT ANTI JOIN dim_campaign_day ON grass_date = campaign_day`)
4. **LEFT JOIN 标记** (`LEFT JOIN ... ON grass_date = campaign_day` 然后判断 `if(campaign_day IS NOT NULL, 1, 0) AS is_campaign_day`)
5. **COUNT 归一化** (`COUNT(IF(campaign_day BETWEEN ... AND ...))` 用于将分母减去大促天数)

### 读取特点

- 始终读取最新 `grass_date` 分区（`BIZ_YESTERDAY`）
- `campaign_day` 过滤范围通常与下游查询窗口对齐（7D/14D/30D）
- 仅使用 `campaign_day` 列和分区列，其他业务列（id, campaign_name, start_time, end_time）很少被引用

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local'
- `grass_region`: UPPER('${region}') -- 所有区域
- `grass_date`: DATE('${BIZ_YESTERDAY}') -- ~99% 查询
- `campaign_day`: BETWEEN DATE('${PREV_30D}') AND DATE('${BIZ_YESTERDAY}') -- ~80% 查询
- `campaign_day`: BETWEEN DATE('${PREV_7D}') AND DATE('${BIZ_YESTERDAY}') -- ROI2 场景
- `campaign_day`: >= DATE('${PREV_21D}') -- potential product 场景

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| id | bigint | id in campaign_day_tab | - | - |
| campaign_name | string | campaign name | - | - |
| start_time | bigint | campaign start timestamp | - | - |
| end_time | bigint | campaign end timestamp | - | - |
| campaign_day | date | campaign day | - | - |
| tz_type [PARTITION] | string | timezone type | - | - |
| grass_region [PARTITION] | string | partition key | - | - |
| grass_date [PARTITION] | date | partition key, yyyy-MM-dd | - | - |
