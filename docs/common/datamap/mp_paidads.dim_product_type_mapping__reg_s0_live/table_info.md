<!-- ads-workspace-gdoc-sync: gdoc_id=1Emg1F4WFem5rl-PUDgqV50CDn60thayBE1BF9CywDns gdoc_url=https://docs.google.com/document/d/1Emg1F4WFem5rl-PUDgqV50CDn60thayBE1BF9CywDns/edit -->

# mp_paidads.dim_product_type_mapping__reg_s0_live

## Description

- **Desc:** 广告产品类型维度映射表，将 (pricing_type, placement) 组合映射到三级产品类型层次结构 (sub_product_type -> product_type -> main_product_type)，供 DWS/ADS 层用于广告分类和指标聚合
- **Granularity:** 全量映射表，无时间/地区分区，粒度 = pricing_type x placement
- **Use Case:**
  - Take Rate 日报：按产品类型聚合收入/GMV/消耗指标
  - Net Revenue 计算：按产品类型分类广告净收入
  - Click Deduction 明细：关联产品类型到每次点击扣费事件
  - Discovery/Search Ads 成本分析：按 main_product_type 计算各产品线消耗占比
  - ROI3 Campaign Surge 分析：通过 product_type 区分 Manual Mode / ROI2.0
- **Update Frequency:** 未在代码库中找到生产逻辑（外部加载/手动维护）

## Key Metrics

该表为纯维度映射表，不包含指标字段。

## Key Dimensions

- 复合键: (pricing_type, placement)
- 产品分类: main_product_type, product_type, sub_product_type

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - (全量表，无分区) |
| HDFS Path | - |
| Retention | - |
| Column Count | 5 |
| Region Coverage | All regions |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充。

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | dim |

## Popularity

- Studio Tasks References: 199 files (0 write, 199 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
