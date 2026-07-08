<!-- ads-workspace-gdoc-sync: gdoc_id=1crSTa6QFSmL2DiLmlekW04WHaSdvBCCeDmggyuSDlh0 gdoc_url=https://docs.google.com/document/d/1crSTa6QFSmL2DiLmlekW04WHaSdvBCCeDmggyuSDlh0/edit -->

# mp_paidads.ods_log_live_ads_bidding_hyperx_hi

**分层**: ODS（操作数据存储层）

## Kafka 数据源

| 属性 | 值 |
|---|---|
| Topic | `liveads-ultrav-core-bidding-global-live` |
| Consumer Group | `mp_search_recommendation_ads-paidads-datawarehouse-cc7ce5` |
| Brokers | `kafka.ks_paidads_live.ap-sg-1-general-a.live.mq.shopee.io:9092` |
| Proto 定义 | [hyperx_log.proto](https://git.garena.com/shopee/deep/data-platform/dw/paidads-data-pipeline-protobuf/-/blob/master/src/main/proto/hyperx/hyperx_log.proto) |

## 分区字段（ODS 系统字段，不在 Proto 中）

| 字段名 | 说明 |
|---|---|
| `grass_date` | 日期分区 |
| `grass_region` | 地区分区 |
| `h` | 小时分区（hi 表） |

## Schema（Proto: `HyperXLog`）

### HyperXLog（顶层消息）

| field# | 字段名 | Proto 类型 | ODS 类型 |
|---|---|---|---|
| 69 | `coef_array` | double | double |
