<!-- ads-workspace-gdoc-sync: gdoc_id=1w5k1l8fFLMp4eSnGT4Q0YQDXB0SddLApoRlmt7zzH1o gdoc_url=https://docs.google.com/document/d/1w5k1l8fFLMp4eSnGT4Q0YQDXB0SddLApoRlmt7zzH1o/edit -->

# Columns: traffic_omni_oa.dim_atlas_feature_business_details_map__reg_live

## Column Usage Notes

### 常见 WHERE 值 (Common Filter Values)

- `operation`: `'impression'` — 所有代码引用均过滤此值
- `page_section`: `'*'` (通配/兜底映射), `!='*'` (特定页面 section 映射) — 两种场景各占约 50%
- `grass_date`: `date('${grass_date}')` — 按调度日期过滤

### JOIN 模式

此表通过 LEFT JOIN 关联到中间特征视图，作为最后一步映射：

```sql
-- 精确匹配 (page_section 非通配)
LEFT JOIN omimi_mapping omini
    ON rs.mapped_page_type = omini.mapped_page_type
    AND COALESCE(CONCAT_WS('-', rs.page_section), '') = COALESCE(omini.page_section, '')
    AND rs.target_type = omini.target_type

-- 通配匹配 (page_section = '*', 不参与 JOIN)
LEFT JOIN omimi_mapping_1 omini_1
    ON rs.mapped_page_type = omini_1.mapped_page_type
    AND rs.target_type = omini_1.target_type
```

下游使用 `COALESCE(omini.reporting_business_line, omini_1.reporting_business_line)` 优先取精确匹配，兜底取通配匹配。

## All Columns

以下列名和类型从代码 SQL 引用反推，非完整 DDL：

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | DATE | 分区日期 | - | - |
| mapped_page_type | string | 经域名映射后的页面类型 | - | - |
| page_section | string | 页面 Section（'*'=通配兜底） | - | - |
| target_type | string | 目标类型（如 'item'） | - | - |
| operation | string | 操作类型（impression/click 等） | - | - |
| reporting_business_line | string | 报表业务线（如 'Homepage'） | - | - |
| reporting_module | string | 报表模块（如 'Daily Discover'） | - | - |

> **注意**: 此列清单从代码引用推测，非完整 DDL。实际表可能有更多列。请运行 `--source from-di` 获取完整列清单和 DataMap 元信息。
