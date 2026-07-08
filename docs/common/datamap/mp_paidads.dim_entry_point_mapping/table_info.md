<!-- ads-workspace-gdoc-sync: gdoc_id=151mQjklAnihgv9Rm-cC11p66jkxC4_2kMRK3SJQOrHM gdoc_url=https://docs.google.com/document/d/151mQjklAnihgv9Rm-cC11p66jkxC4_2kMRK3SJQOrHM/edit -->

# mp_paidads.dim_entry_point_mapping

> **Contributors**: luka.yang ｜ **最后更新**：2026-06-16 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/datamap/mp_paidads.dim_entry_point_mapping/table_info.md)

## Description

- **Desc:** 广告入口映射维度表（旧版），将数值型 entrance ID + sub_entrance ID 映射到可读的 entry_point 名称。与 `dim_entry_point_mapping_v2` 的核心区别为此表支持 sub_entrance 级别的精细映射，而 `_v2` 引入了 `traffic_type` 但去掉了 sub_entrance 解析能力。在多数 workflow 中两表同时使用：先通过旧表做 sub_entrance 精确匹配，再通过 `_v2` 补充 traffic_type。
- **Granularity:** entrance + sub_entrance 级别，一个 entrance 可能对应多个 sub_entrance 映射
- **Use Case:** Take Rate v1 报表入口映射、Revenue 计算中 sub_entrance 级入口匹配、Organic Metrics 入口归类、任何需要区分同一 entrance 下不同 sub_entrance 的场景
- **Update Frequency:** 低频更新（维度表，新增入口时更新）

## Key Metrics

此表为纯维度映射表，不含度量指标。

## Key Dimensions

- 映射维度: entrance, sub_entrance, entry_point

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | 无分区（维度表） |
| HDFS Path | - |
| Retention | - |
| Column Count | 3 (entrance, sub_entrance, entry_point) |
| Region Coverage | 全局（不按地域分区） |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DIM |

## Popularity

- Studio Tasks References: ~60 files (纯旧版引用) + ~80 files (与 _v2 同时引用)
- L7D Query Count: -
- Completeness: -
- Popularity: -

## 与 dim_entry_point_mapping_v2 的关系

| 特性 | dim_entry_point_mapping | dim_entry_point_mapping_v2 |
|------|------------------------|---------------------------|
| sub_entrance 映射 | 支持（`sub_entrance > 0`） | 不解析（`sub_entrance IS NULL OR = ''` 过滤） |
| traffic_type 映射 | 不支持 | 支持 |
| 使用场景 | sub_entrance 级别精细匹配 + 主入口匹配 | traffic_type 分类 + 主入口匹配 |
| 推荐用法 | COALESCE(sub_entrance_mapping.entry_point, entrance_mapping.entry_point, 'Undefined') | COALESCE(entry_point_v2, 'Undefined'); 再取 traffic_type |
