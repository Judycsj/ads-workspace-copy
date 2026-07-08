<!-- ads-workspace-gdoc-sync: gdoc_id=1LCOB7SuMmgZjN3mp1rSS0r0f3wHfQRfP74zCqsbCFt0 gdoc_url=https://docs.google.com/document/d/1LCOB7SuMmgZjN3mp1rSS0r0f3wHfQRfP74zCqsbCFt0/edit -->

# srdi_mart.dwd_sr_data_warehouse_tc_all_cspu_link_df

**分层：** DWD（明细数据层）
**主键：** `model_id`（结合 `grass_region`、`local_date` 分区唯一定位一条 CSPU-Model 关联记录）
**分区：** `grass_region`（站点/地区）、`local_date`（本地日期）
**更新频率：** 每日全量覆盖（INSERT OVERWRITE）
**访问频次：** 6,502 次

---

## 业务描述

本表是搜推数仓（SRDI）中 **CSPU（Canonical SPU）与 Model 关联关系的明细宽表**，将 CSPU-Model 映射关系与商品模型维度、商品维度、店铺 SCS 类型、CSPU 价格档位标签以及订单履约数据整合在一条记录中，形成以 Model 为粒度的 CSPU 全量链路快照。

**核心业务场景：**
- 搜推系统中 CSPU 归因与候选集构建，支持基于 CSPU 的模型召回与排序；
- 评估每个 Model 的商品健康度（上下架状态、库存、价格有效性），过滤无效候选；
- 提供 CSPU 维度的价格档位（`cspu_pr_rate`）、评分、销量、订单量等特征，供特征工程使用；
- 分析 SCS 店铺（本地 SCS / 跨境 SCS）在 CSPU 体系中的覆盖分布。

**适合回答的问题：**
- 某 CSPU 下有哪些有效 Model（`is_valid_model=1`）？
- 某站点下 CSPU 候选集的价格分布、评分、历史销量如何？
- 某 Model 属于哪个 CSPU，其所在店铺是否为 SCS 类型？
- 截至某日，各 CSPU 的累计下单量（`placed_order_cnt_td`）情况？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/地区标识，如 `TH`、`ID`、`MY` 等，用于数据隔离 |
| `local_date` | date | 数据快照的本地日期，与上游维度表日期对齐 |

### 维度：CSPU-Model 关联标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_id` | bigint | CSPU（Canonical SPU）唯一标识；`biz_tag` 不包含 winner/cheapest 标记时为 null，已在 ETL 过滤 |
| `model_id` | bigint | Model（SKU）唯一标识，为本表核心粒度字段 |
| `item_id` | bigint | 商品（Item/SPU）唯一标识 |
| `shop_id` | bigint | 店铺唯一标识 |
| `biz_tag` | bigint | CSPU-Model 关联的业务标签位掩码。当前入表条件：`biz_tag & 1 > 0`（winner）、`biz_tag & 4 > 0` 或 `biz_tag & 8 > 0`；`biz_tag=256` 表示含退场的 newnew CSPU，`biz_tag=512` 表示不含退场的 newnew CSPU |

### 维度：店铺类型

| 字段 | 类型 | 说明 |
|---|---|---|
| `shop_scs_type` | string | 店铺 SCS 类型，取值为 `scs-local`（本地 SCS）或 `scs-cb`（跨境 SCS）；非 SCS 店铺为 null |

### 维度：CSPU 标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_pr_rate` | string | CSPU 价格档位标签（Price Rate），来源于 `dws_sr_data_warehouse_tc_pb_cspu_level_1d`，表示该 CSPU 在品类中的价格竞争力分层 |

### 维度：Model 状态与库存

| 字段 | 类型 | 说明 |
|---|---|---|
| `model_status` | bigint | Model 上架状态；`1` 表示正常在售 |
| `seller_status` | bigint | 卖家账号状态；`1` 表示正常 |
| `shop_status` | bigint | 店铺状态；`1` 表示正常 |
| `item_status` | bigint | 商品（Item）状态；`1` 表示正常 |
| `model_stock` | bigint | Model 维度库存数量 |
| `item_stock` | bigint | Item 维度库存数量 |
| `is_valid_model` | int | 有效 Model 标记，派生字段。当 `model_status=1 AND seller_status=1 AND shop_status=1 AND item_status=1 AND model_price>0` 时为 `1`，否则为 `0` |

### 指标：价格

| 字段 | 类型 | 说明 |
|---|---|---|
| `model_price` | decimal(25,10) | Model 本地货币价格 |
| `model_price_usd` | decimal(25,10) | Model 美元价格 |
| `item_price` | decimal(25,10) | Item 本地货币价格（通常为最低 Model 价） |
| `item_price_usd` | decimal(25,10) | Item 美元价格 |

### 指标：商品表现

| 字段 | 类型 | 说明 |
|---|---|---|
| `rating_score` | decimal(25,10) | 商品评分，来源于 `dim_item__reg_s0_live`，Item 粒度 |
| `sold_cnt` | bigint | 商品历史销售件数（Item 粒度累计），来源于 `dim_item__reg_s0_live` |
| `placed_order_cnt_td` | bigint | Model 粒度截至当日的累计下单量（Today 累计，`_td` 后缀），来源于 `dws_sku_gmv_td__reg_s0_live`；同一 model 取最大值聚合 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须同时指定**，否则触发全表扫描：
  ```sql
  WHERE grass_region = 'TH'
    AND local_date = '2026-05-17'
  ```
- 仅需有效候选时，建议同时过滤 `is_valid_model = 1`。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `is_valid_model` | 派生的 0/1 标记，SUM 可得计数但无业务均值意义，聚合时应明确语义 |
| `rating_score` | 评分为均值类指标，不可跨 item 直接 SUM，需加权或取均值 |
| `placed_order_cnt_td` | `_td` 后缀表示截至当日的**累计值**，跨行 SUM 会重复累加；同一 model 在同一分区内已聚合，按 model 汇总时直接使用即可，但跨日期 SUM 无意义 |
| `model_price`、`item_price` 等价格字段 | 不同货币体系下的价格，跨站点不可直接 SUM |
| `biz_tag` | 位掩码字段，不可数值 SUM，应使用位运算（`& 1`、`& 4` 等）判断标签 |

### 时效性说明

- 本表为**每日全量快照**（`df` 后缀），每次写入覆盖当日分区，不保留历史变化轨迹。
- `placed_order_cnt_td` 为 **Today-to-date 累计**（`_td`），反映截至 `local_date` 当日的总下单量，不代表单日增量。
- `sold_cnt` 同为累计销量，非当日新增。
- 数据依赖上游 `grass_date = ${local_date}` 的维度快照，T+1 产出，当日不可用。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `paimon.rcmd_feature.ods_sr_data_warehouse_tc_cspu_model_link` | 提供 CSPU-Model-Item-Shop 映射关系及 `biz_tag`，为驱动表（主事实来源） |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_cspu_level_1d` | 提供 CSPU 价格档位标签 `cspu_pr_rate` |
| `regds_listing.dim_scs_shop_list_df` | 提供店铺 SCS 类型（`scs-local` / `scs-cb`） |
| `mp_item.dim_model__reg_s0_live` | 提供 Model 维度的状态、库存、价格信息 |
| `mp_item.dim_item__reg_s0_live` | 提供 Item 维度的评分（`rating_score`）与销量（`sold_cnt`） |
| `mp_order.dws_sku_gmv_td__reg_s0_live` | 提供 Model 粒度的累计下单量 `placed_order_cnt_td` |

---

## ETL 逻辑摘要

### 数据流

```
ods_sr_data_warehouse_tc_cspu_model_link   (CSPU-Model 映射，过滤有效关联)
        │
        ├─ LEFT JOIN ← dws_sr_data_warehouse_tc_pb_cspu_level_1d  (CSPU 价格档位)
        ├─ LEFT JOIN ← dim_scs_shop_list_df                        (店铺 SCS 类型)
        ├─ LEFT JOIN ← dim_model__reg_s0_live                      (Model 维度属性)
        ├─ LEFT JOIN ← dim_item__reg_s0_live                       (Item 评分/销量)
        └─ LEFT JOIN ← dws_sku_gmv_td__reg_s0_live (聚合 max)     (Model 累计订单量)
                │
                ▼
  dwd_sr_data_warehouse_tc_all_cspu_link_df  [PARTITION BY grass_region, local_date]
```

### 关键步骤

1. **`cspu_model` 临时视图**：从 ODS 层 CSPU-Model 链路表筛选 `status=1`、`cspu_id IS NOT NULL`，且 `biz_tag` 命中 winner（`&1`）、cheapest（`&4`）或其他高质量标记（`&8`）的记录，排除无效关联。

2. **`cspu_label` 临时视图**：从 DWS 层 CSPU 价格档位表按 `cspu_id` 取当日 `cspu_pr_rate` 标签。

3. **`shop_type` 临时视图**：从 SCS 店铺维度表过滤 `type IN ('scs-local', 'scs-cb')`，仅保留 SCS 类型店铺，非 SCS 店铺在主查询中 join 结果为 null。

4. **`dim_model` 临时视图**：从 Model 维度快照表按 `grass_date`、`tz_type='local'` 过滤，取当日 Model 状态、库存、价格快照。

5. **`dim_item` 临时视图**：从 Item 维度快照表取当日 `rating_score` 与 `sold_cnt`。

6. **`model_order` 临时视图**：从 SKU GMV 累计表按 `model_id` 聚合，取 `MAX(placed_order_cnt_td)` 解决可能的重复行问题。

7. **INSERT OVERWRITE**：以 `cspu_model` 为驱动表，对上述 5 张临时视图进行 LEFT JOIN（`shop_type` 使用 BROADCAST hint 加速），派生 `is_valid_model` 字段，按分区 `grass_region`、`local_date` 全量覆盖写入目标表。

### 注意事项

- **单 Writer**：本表仅有一个 ETL 文件写入，无多 Writer 并发覆盖风险。
- **`biz_tag` 过滤逻辑已多次变更**：历史上 `biz_tag=0` 的记录曾被释放入表，当前正式入表条件为 `(biz_tag & 1 > 0) OR (biz_tag & 4 > 0) OR (biz_tag & 8 > 0)`，下游使用时勿对 `biz_tag=0` 的历史数据与当前数据做直接对比。
- **`cspu_pr_rate` 临时方案**：注释标注该字段通过 LEFT JOIN DWS 层表"暂时"获取，后续逻辑可能调整，建议关注上游表变更。
- **全 LEFT JOIN 设计**：Model 状态、价格、评分等维度字段均为 LEFT JOIN，若上游维度表缺数据（如新增 Model 当日未入维度表），对应字段为 null，`is_valid_model` 将为 `0`，需关注维度表产出时效对本表数据质量的影响。
- **分区参数化**：SQL 使用 `${grass_region}`、`${local_date}` 参数化执行，同一套逻辑按站点分别调度，各分区独立覆盖写入。

---

*文档生成时间：2026-05-17*