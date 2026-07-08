<!-- ads-workspace-gdoc-sync: gdoc_id=1eh2KxK3rPBLevzdulYf7wTAftrnmDhh4EpbaLA_eeqg gdoc_url=https://docs.google.com/document/d/1eh2KxK3rPBLevzdulYf7wTAftrnmDhh4EpbaLA_eeqg/edit -->

# mp_paidads.ods_log_target_roi_rcmd_log_hi

**分层**: ODS（操作数据存储层）

## Kafka 数据源

| 属性 | 值 |
|---|---|
| Topic | `target-roi-recommendation-log-global-live` |
| Consumer Group | `paidads-target-roi-rcmd-log-a1786b` |
| Brokers | `kafka.common03.ap-sg-1-general-c.live.mq.shopee.io:9092` |
| Proto 定义 | [target_roi_rcmd_log.proto](https://git.garena.com/shopee/deep/data-platform/dw/paidads-data-pipeline-protobuf/-/blob/master/src/main/proto/log/target_roi_rcmd_log.proto) |

## 分区字段（ODS 系统字段，不在 Proto 中）

| 字段名 | 说明 |
|---|---|
| `grass_date` | 日期分区 |
| `grass_region` | 地区分区 |
| `h` | 小时分区（hi 表） |

## Schema（Proto: `TargetRoiRecommendedValue`）

### TargetRoiRecommendedValue（顶层消息）

| field# | 字段名 | Proto 类型 | ODS 类型 |
|---|---|---|---|
| 1 | `algo_value` | int64 | bigint |
| 2 | `final_value` | int64 | bigint |
| 3 | `percentile` | int32 | int |
