<!-- ads-workspace-gdoc-sync: gdoc_id=1dyWJuJTO1GkyYZ7syBWPNK0nvMbJRSzgsAnOSIuqWiM gdoc_url=https://docs.google.com/document/d/1dyWJuJTO1GkyYZ7syBWPNK0nvMbJRSzgsAnOSIuqWiM/edit -->

# mp_paidads.ods_log_translog_unsuccessful_event_deduction_hi

**分层**: ODS（操作数据存储层）

## Kafka 数据源

| 属性 | 值 |
|---|---|
| Topic | `deduct_unsuccessful_event_sg_live,deduct_unsuccessful_event_us_live` |
| Consumer Group | `paidads-dw-sink-datax` |
| Brokers | `kafka.ks_ads_live-01.ap-sg-1-general-a.live.mq.shopee.io:9092` |
| Proto 定义 | [deduct_unsuccessful_event.proto](https://git.garena.com/shopee/deep/data-platform/dw/paidads-data-pipeline-protobuf/-/blob/master/src/main/proto/log/deduction/deduct_unsuccessful_event.proto) |

## 分区字段（ODS 系统字段，不在 Proto 中）

| 字段名 | 说明 |
|---|---|
| `grass_date` | 日期分区 |
| `grass_region` | 地区分区 |
| `h` | 小时分区（hi 表） |

## Schema（Proto: `AdsAccount`）

### AdsAccount（顶层消息）

| field# | 字段名 | Proto 类型 | ODS 类型 |
|---|---|---|---|
| 1 | `accountid` | int64 | bigint |
| 2 | `userid` | int64 | bigint |
| 3 | `balance` | int64 | bigint |
| 4 | `ctime` | int64 | bigint |
| 5 | `mtime` | int64 | bigint |
| 6 | `status` | int32 | int |
| 7 | `overdue_limit` | int64 | bigint |
| 8 | `extinfo` | bytes | binary |
| 9 | `display_ads_balance` | int64 | bigint |
