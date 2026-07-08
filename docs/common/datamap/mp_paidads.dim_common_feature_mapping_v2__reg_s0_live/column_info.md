<!-- ads-workspace-gdoc-sync: gdoc_id=19LT_goNROe4wGuA3pRl7AsYmZxL86V9nFoqbFj4ESmA gdoc_url=https://docs.google.com/document/d/19LT_goNROe4wGuA3pRl7AsYmZxL86V9nFoqbFj4ESmA/edit -->

# Columns: mp_paidads.dim_common_feature_mapping_v2

## Column Usage Notes

### 枚举值映射 (Value Mappings)

该表本身即为一组 entrance 到 common_feature 的映射。下游 SQL 中常见的 COALESCE 后备值：

| Column | Value | Meaning |
|--------|-------|---------|
| common_feature | 'Others' | 当 entrance 未在映射表中匹配时的默认值 (COALESCE fallback) |
| common_feature | 'Platform' | 全平台汇总视图（UNION ALL 分支直接硬编码，不经过映射表） |

### 常见 WHERE 值 (Common Filter Values)

- 无 WHERE 过滤：dim 表作为维度查找，每次均全表扫描（无分区过滤）
- 下游使用 `coalesce(common_feature_mapping1.common_feature, 'Others') as common_feature` 处理未匹配的 entrance
- 部分查询过滤 `where common_feature != 'Others'` 排除未分类数据

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| entrance | int/bigint | 入口点代码 (entry point code)，JOIN 键 | - | - |
| common_feature | string | 特征类别名称，如 Search Shop、You May Also Like 等 | - | - |
