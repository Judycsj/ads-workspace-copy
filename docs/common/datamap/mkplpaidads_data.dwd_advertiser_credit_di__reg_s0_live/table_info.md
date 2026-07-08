<!-- ads-workspace-gdoc-sync: gdoc_id=12DQSjmHsjvUNK2nEek-qu-1Ss_jfBu7KovJVgQuo46c gdoc_url=https://docs.google.com/document/d/12DQSjmHsjvUNK2nEek-qu-1Ss_jfBu7KovJVgQuo46c/edit -->

# mkplpaidads_data.dwd_advertiser_credit_di__reg_s0_live

## Description

- **Desc:** 广告主信用余额日表（DWD 层），记录每个广告主（user_id + shop_id）每天的信用订单（order_id）和账户余额快照。包含每笔充值/信用授予的金额（top_up_amount）和当日起始余额（start_of_day_balance）、日终余额（end_of_day_balance），同时提供等值 USD 金额。采用 SOD（start of day）→ EOD（end of day）两步写入策略：先写入临时分区 dt="9999-01-01" 存储起始余额，EOD 步骤再读取 SOD 分区与当日最新数据合并写入正式日期分区。
- **Granularity:** daily x order_id (nullable for balance-only rows) x user_id x shop_id x grass_region
- **Use Case:** Advertiser credit balance daily tracking, credit top-up monitoring and reconciliation, advertiser credit financial audit, exchange rate conversion (local currency to USD), credit balance change investigation, daily balance reconciliation against transaction logs
- **Update Frequency:** Daily (SOD at H+1 of day T, EOD at H+0 of day T+1 by timezone)

## Key Metrics

- Credit Top-up: top_up_amount (local currency), top_up_amount_usd (USD)
- Balance Snapshot: start_of_day_balance / start_of_day_balance_usd (beginning balance), end_of_day_balance / end_of_day_balance_usd (ending balance)

## Key Dimensions

- Partition: dt (date string), grass_region
- Advertiser Entity: user_id (advertiser account), shop_id (shop)
- Credit Order: order_id, order_type, main_type (credit main type)
- Temporal: credit_expiry_time (unix timestamp of credit expiration)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | dt, grass_region |
| HDFS Path | ${path} (SG cluster); hdfs://D2/projects/data_paidadsmart/hive/mp_paidads/dwd_advertiser_credit_di (US cluster via distcp) |
| Retention | Permanent |
| Column Count | 12 |
| Region Coverage | UTC+8: SG, MY, PH, TW; UTC+7: TH, VN, ID; UTC-3: AR, BR; UTC-5: CO; UTC-6: MX; UTC-4: CL (11 regions total; US regions via distcp from SG) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | Marketplace - Paid Ads |
| DW Layer | DWD |

## Popularity

- Studio Tasks References: 21 files (20 write in workflows, 1 read in manual_tasks)
- L7D Query Count: -
- Completeness: -
- Popularity: -
