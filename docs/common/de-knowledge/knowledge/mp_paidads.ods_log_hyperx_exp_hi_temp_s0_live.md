<!-- ads-workspace-gdoc-sync: gdoc_id=1VnD_mlZ657RAvGZ7CT5NIIYzMHOAc0Slyc2t7Qs48fA gdoc_url=https://docs.google.com/document/d/1VnD_mlZ657RAvGZ7CT5NIIYzMHOAc0Slyc2t7Qs48fA/edit -->

# mp_paidads.ods_log_hyperx_exp_hi_temp_s0_live

**分层**: ODS（操作数据存储层）

## Kafka 数据源

| 属性 | 值 |
|---|---|
| Topic | `mkplpaidads_discovery_ads.hyperx_exp_log_us` |
| Consumer Group | `paid_ads_data_warehouse_us` |
| Brokers | `di-kafka-da01-bg1-bootstrap01-dallas-us.data-infra.shopee.io:9093,di-kafka-da01-bg1-bootstrap02-dallas-us.data-infra.shopee.io:9093,di-kafka-da01-bg1-bootstrap03-dallas-us.data-infra.shopee.io:9093` |
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
