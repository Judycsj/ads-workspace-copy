<!-- ads-workspace-gdoc-sync: gdoc_id=1GkRdYyvZUmdS0KtL5-PlAc20h5FxVyvYafFW-7Vja-Y gdoc_url=https://docs.google.com/document/d/1GkRdYyvZUmdS0KtL5-PlAc20h5FxVyvYafFW-7Vja-Y/edit -->

# Columns: dev_idecbi_fpna.ec_shopee_fpa_spl_cashback_dim__userlist_td

## Column Usage Notes

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| group_name | Combo_Control | 控制组 (Combo) |
| group_name | Combo_Local | 本地区域控制组 |
| group_name | Combo_MP | MP 流量实验组 |
| group_name | Combo_Ads | Ads 流量实验组 |
| group_name | Combo_Reg | Regional 流量实验组 |
| identifier | Platform - DS Model User Group | DS 模型用户分组（常规版本） |
| identifier | Platform - DS Model User Group v2 | DS 模型用户分组（v2 版本，临时使用） |
| identifier | Program - Upsize Wed Test | Upsize 周三测试实验 |
| identifier | Program - Upsize Wed Test v2 | Upsize 周三测试实验（v2 版本，临时使用） |
| identifier | Special - Peakday Test | 特殊大促日测试实验 |

### 常见 WHERE 值 (Common Filter Values)

- `identifier`: 'Platform - DS Model User Group' (~60% 查询) / 'Program - Upsize Wed Test' (~30% 查询)
- `start_date`: 固定快照 `date('2026-03-02')` (早期版本) / MAX(start_date) 取最新快照 (当前主流模式)
- `day_of_week(start_date) = 2`: 筛选周二快照 (仅 kaiyu.zhang 的手动任务)
- `identifier IN ('Platform - DS Model User Group', 'Program - Upsize Wed Test')`: 同时选中两个实验

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| start_date | date | 快照生效日期，实验用户名单的版本标识 | - | - |
| identifier | string | 实验标识符，区分不同实验/测试 | - | - |
| group_name | string | 用户在 Cashback 程序中的原始分组名（Combo_Control/Combo_Local/Combo_MP/Combo_Ads/Combo_Reg） | - | - |
| user_id | bigint | 用户 ID | - | - |
| treat | string | 处理/对照组标记（仅一个文件使用，具体值未完全明确） | - | - |

**说明**: 以上列名和类型从 SQL 查询中推断。代码库中未找到此表的 CREATE TABLE DDL，完整列定义请通过 `--source from-di` 从 DataMap 补充。
