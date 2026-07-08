<!-- ads-workspace-gdoc-sync: gdoc_id=1RX_c_uUiVjHN20y7Alg1wk_9KRNIM1NJ7Vib0lCQOPs gdoc_url=https://docs.google.com/document/d/1RX_c_uUiVjHN20y7Alg1wk_9KRNIM1NJ7Vib0lCQOPs/edit -->

# Columns: traffic.shopee_traffic_dws_abtest_hit_log_di__reg_live

> DDL 未在 paidads-alg 代码库中找到（该表由 Traffic 团队维护，paidads-alg 仅有读引用）。以下列信息从 SQL 引用中提取，可能不完整。运行 `--source from-di` 可补全完整列清单和描述。

## Column Usage Notes

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 'ID','MY','PH','SG','TH','TW','VN','BR' (标准 8 区，所有 4 个引用均使用)
- `experiment_id`: 特定实验 ID（如 6293, 4577）
- `grass_date`: 通常为实验期区间，如 7-10 天范围
- `exp_version`: >= 阈值（如 79640），用于过滤未清除缓存的用户，仅在特殊分析中使用（1/4 文件）
- `group_id`: 未在 WHERE 中直接过滤，在 SELECT 中作为维度输出

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | date | 分区日期 | - | - |
| grass_region | string | 地区（如 ID, MY, PH 等） | - | - |
| experiment_id | bigint | 实验 ID | - | - |
| group_id | bigint | 实验分组 ID | - | - |
| user_id | bigint | 用户 ID | - | - |
| exp_version | bigint | 实验版本号，用于过滤客户端缓存 | - | - |

> 上述 6 列为从 4 个 SQL 引用中实际使用的列。完整列清单请运行 `--source from-di`。
