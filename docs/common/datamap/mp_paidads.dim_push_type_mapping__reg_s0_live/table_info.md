<!-- ads-workspace-gdoc-sync: gdoc_id=10Vm-r0e5Bce1sKZQCVs2-yctFLaiUc60tLztevFpV6k gdoc_url=https://docs.google.com/document/d/10Vm-r0e5Bce1sKZQCVs2-yctFLaiUc60tLztevFpV6k/edit -->

# mp_paidads.dim_push_type_mapping__reg_s0_live

## Description

- **Desc:** 推金类型映射表，将 `sub_push_type`（上游 credit_topup 生成的子推金类型）映射为分类 `push_type`（ads_push / non_ads_push），用于广告收入分析中区分广告推金与非广告推金。
- **Granularity:** sub_push_type 级别（每行一个 sub_push_type 到 push_type 的映射）
- **Use Case:**
  - `dws_advertise_net_ads_revenue_1d` 收入聚合：通过 LEFT JOIN 将推金子类型映射为 push_type，生成 `CASE WHEN push_type IS NULL THEN 'non_ads_push' ELSE 'ads_push' END`
  - 广告收入拆解：区分 ads_push 和 non_ads_push 收入占比
- **Update Frequency:** 由上游服务维护（非 Studio Tasks 调度）

## Key Metrics

- 无聚合指标（DIM 表仅用于映射）

## Key Dimensions

- 查询维度: sub_push_type
- 输出维度: push_type

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | 2 |
| Region Coverage | All regions (全量 DIM 表) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 30 files
- L7D Query Count: -
- Completeness: -
- Popularity: -
