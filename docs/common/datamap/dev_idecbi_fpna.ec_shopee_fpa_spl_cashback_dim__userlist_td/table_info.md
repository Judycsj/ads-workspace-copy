<!-- ads-workspace-gdoc-sync: gdoc_id=1b0fLY7gmGuNXRyJs9qhFbshXIysoDJfLCCnRxOM39UY gdoc_url=https://docs.google.com/document/d/1b0fLY7gmGuNXRyJs9qhFbshXIysoDJfLCCnRxOM39UY/edit -->

# dev_idecbi_fpna.ec_shopee_fpa_spl_cashback_dim__userlist_td

## Description

- **Desc:** 印尼 (ID) Shopee FPA Cashback 分桶实验用户名单维度表。存储 Cashback 程序下的 AB 实验用户分组数据，每条记录包含用户在某个实验标识 (identifier) 下的分组标签 (group_name)。数据来源于 IDE CBI FPNA 业务域（非 Ads 团队生产表），被 Smart Voucher blacklist/实验组生成流程大量使用。
- **Granularity:** one row per (start_date, identifier, user_id)
- **Use Case:**
  - Smart Voucher 黑名单用户实验组生成：取最新 start_date 的快照，按 group_name 映射为 control/mp_plus_ads 实验组
  - Upsize Wednesday 测试用户分组：按 identifier='Program - Upsize Wed Test' 筛选指定日期的实验用户
  - 印尼 Cashback DS Model User Group 分桶：按 identifier='Platform - DS Model User Group' 获取定期更新的用户分层
  - 用户名单规模统计：按 start_date, group_name, identifier 聚合 COUNT(DISTINCT user_id)
  - Manual ad-hoc 数据校验：对比不同 region 下的实验分组人数
- **Update Frequency:** Daily (外部 IDE 系统维护，Ads 侧仅读取)

## Key Metrics

- 用户数类: COUNT(DISTINCT user_id)

## Key Dimensions

- 快照维度: start_date
- 实验维度: identifier (实验标识/版本)
- 分组维度: group_name (原始分组名) — 映射为 control / mp_plus_ads
- 用户维度: user_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (未在代码库中找到 DDL) |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | 5+ (从 SQL 使用推断: start_date, identifier, group_name, user_id, treat) |
| Region Coverage | ID (印尼) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | IDE CBI FPNA (外部团队) |
| Business Domain | - |
| DW Layer | DIM (维度表) |

## Popularity

- Studio Tasks References: 13 files (0 write, 13 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
