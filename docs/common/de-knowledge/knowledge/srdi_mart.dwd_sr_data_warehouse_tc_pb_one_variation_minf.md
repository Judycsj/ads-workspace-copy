<!-- ads-workspace-gdoc-sync: gdoc_id=1CFm55hcip7vZVvima4rNp2s8X8t8ZY4K42mYtXetkTM gdoc_url=https://docs.google.com/document/d/1CFm55hcip7vZVvima4rNp2s8X8t8ZY4K42mYtXetkTM/edit -->

# srdi_mart.dwd_sr_data_warehouse_tc_pb_one_variation_minf

**分层：** DWD（明细数据层）
**主键：** `grass_region` + `regional_date` + `regional_hour` + `regional_minute` + `cspu_id` + `model_id`
**分区：** `grass_region` / `regional_date` / `regional_hour` / `regional_minute`
**更新频率：** 分钟级准实时更新
**引用频次/访问频次：** 215,652

---

## 业务描述

本表记录搜推（SR）业务中 **Pricebook（PB）场景下每个 CSPU 的唯一胜出模型（One Variation）** 在分钟粒度上的明细快照数据。每条记录对应某一分钟内，一个 CSPU 在特定大区下的最优/最低价模型信息，并附带商家类型、广告、电商效果等丰富标签。

**核心业务场景：**
- 搜推排序特征工程：为搜索/推荐模型提供实时 Buybox/Winner/Cheapest 状态特征。
- 价格竞争力分析：识别各 CSPU 当前胜出模型（Winner/Cheapest）及其商家类型（SCS/非SCS）。
- 广告与 ECPM 联合分析：结合 ROI2 广告活跃状态与 ECPM 标签，支持排序效果评估。
- Buybox 冷启动监控：通过 `cspu_buybox_boost_weeks` 和 `is_buybox` 评估 Buybox 新品加热时长与状态。

**适合回答的问题：**
- 当前时刻哪些 CSPU 处于 Winner/Cheapest/Buybox 状态？
- 各 SCS 店铺的胜出商品分布情况如何？
- 特定商品的 ECPM 标签和广告状态是什么？
- 某 CSPU 的 Buybox 冷启动已持续多少周？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 大区标识，如 SG、MY、TH、PH、TW 等，所有查询必须指定 |
| `regional_date` | date | 当地日期分区，格式 yyyy-MM-dd |
| `regional_hour` | int | 当地小时分区，取值 0~23 |
| `regional_minute` | int | 当地分钟分区，取值 0~59，表级最细粒度 |

### 维度：商品与模型标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `cspu_id` | bigint | CSPU（标准商品单元）ID，One Variation 的聚合主键 |
| `model_id` | bigint | 当前 CSPU 对应的胜出 Model ID（即最优/最低价 SKU） |
| `item_id` | bigint | Model 所属的商品 Item ID |
| `shop_id` | bigint | Model 所属店铺 ID |
| `ads_id` | bigint | 该商品关联的活跃广告 ID（来源于 ROI2 广告位 placement 40/50），无广告时为 null |

### 维度：状态与类型标签

| 字段 | 类型 | 说明 |
|------|------|------|
| `is_winner` | int | 是否为 Winner 模型（business_type in (3,4) 为 1，否则为 0；美区固定为 0） |
| `is_buyer_cheapest` | int | 是否为 Buyer Cheapest 模型（business_type in (1,2) 且 CSPU 近1日有效订单时为 1；美区逻辑：cspu_l1d_order_cnt 为 null 或 >0 时恒为 1） |
| `is_buybox` | int | 该 model_id 是否命中 Buybox vsku 映射表（1=命中，0=未命中） |
| `main_model_type` | int | 模型类型标签：2=SCS Winner、3=普通 Winner、5=Cheapest（含SCS Cheapest）；美区：2=SCS Cheapest、5=普通 Cheapest |
| `main_item_type` | int | Item 级别类型标签，取同一 item_id 下所有 model 的 `main_model_type` 最小值（即最优类型） |
| `shop_scs_type` | string | 店铺 SCS 类型：`scs-local`、`scs-cb`，非 SCS 店铺填充为 `non-scs` |

### 指标：CSPU 与商品效果指标

| 字段 | 类型 | 说明 |
|------|------|------|
| `cspu_l1d_order_cnt` | double | CSPU 近1日订单量，来源于 DWS CSPU 汇总表，用于判断 Cheapest 有效性 |
| `cspu_buybox_boost_weeks` | double | CSPU 关联 Vitem 的 Buybox 冷启动加热周数（自 publish_local_date 起至当前日期的完整周数），无法匹配时填充 9999；美区固定为 9999 |
| `ecpm_l1d_tag` | map\<string,array\<double\>\> | Item 近1日 ECPM 标签 Map，key 为标签名，value 为分布数组，来源于 DWS Item ECPM 汇总表 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`** 必须指定，该字段为首个分区键，跨区全扫描会导致严重性能问题。
- **`regional_date`** 通常需要指定，表为分钟级快照，单日数据量极大。
- **`regional_hour`** 和 **`regional_minute`** 按需指定；如需获取某时刻最新状态，应同时指定最新小时和分钟分区。
- 示例过滤：
  ```sql
  WHERE grass_region = 'SG'
    AND regional_date = '2025-05-17'
    AND regional_hour = 10
    AND regional_minute = 30
  ```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|------|------|
| `cspu_buybox_boost_weeks` | 周数度量，无累加业务意义；9999 为缺省占位值，不可参与均值/求和 |
| `cspu_l1d_order_cnt` | 已是 CSPU 级别预聚合值，跨分钟分区 SUM 会造成重复计数 |
| `ecpm_l1d_tag` | map\<string,array\<double\>\> 结构，需按 key 展开后结合业务规则使用，不可直接聚合 |
| `main_item_type` / `main_model_type` | 枚举标签，数值无数学加和含义 |
| `is_winner` / `is_buyer_cheapest` / `is_buybox` | 快照状态标志，跨分区 SUM 会重复计数同一商品的多个时刻状态 |

### 时效性说明

- 本表为 **分钟级快照表**（`*_minf`），每分钟全量覆盖写入（`INSERT OVERWRITE`），每个分区代表该分钟时刻的完整 Pricebook One Variation 状态。
- 上游 CSPU 订单标签（`cspu_l1d_order_cnt`）和 ECPM 标签（`ecpm_l1d_tag`）取各自上游表在 `regional_date` 前最新分区，存在最多1日延迟。
- `cspu_buybox_boost_weeks` 基于 vitem publish_local_date 计算，时间基准为当前 `regional_date` + `regional_hour` 转换到对应大区时区的日期。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `paimon.rcmd_feature.ods_sr_data_warehouse_pb_one_variation` | 主数据源，提供 CSPU 的 cheapest model 快照（model_id、item_id、shop_id、business_type、cspu_tag 等） |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_cspu_level_1d` | 提供 CSPU 近1日订单量（`cspu_l1d_order_cnt`），用于 Cheapest 有效性判断 |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_item_level_ecpm_1d` | 提供 Item 级别近1日 ECPM 标签（`ecpm_l1d_tag`） |
| `srdi_mart.dws_sr_data_warehouse_vsku_vitem_cspu_1d` | 提供 CSPU → Vitem 映射关系，用于计算 Buybox 冷启动周数 |
| `srdi_mart.dim_sr_data_warehouse_vsku_vitem` | 提供 Vitem 的 publish_local_date，用于计算 `cspu_buybox_boost_weeks` |
| `paimon.srdi_mart.ods_sr_data_warehouse_vsku_model_mapping` | 提供 Buybox vsku model 映射，用于判断 `is_buybox`，同时过滤 live test vitem |
| `regds_listing.dim_scs_shop_list_df` | 提供 SCS 店铺类型（scs-local / scs-cb），用于生成 `shop_scs_type` |
| `mp_paidads.dim_active_item__reg_s0_live` | 提供 ROI2 广告位（placement 40/50）活跃商品的 `ads_id` |

---

## ETL 逻辑摘要

### 数据流

```
paimon ODS (pb_one_variation)
        │
        ├── 过滤 model_id>0 且 cspu_tag<>8
        │
        ├── JOIN cspu_label (1d order_cnt)  →  cheapest_model / cheapest_raw
        ├── JOIN shop_type (scs类型)
        ├── JOIN buybox_cspu_tag (冷启动周数)  [仅非US]
        ├── JOIN ads_active_item (广告ID)
        │        ↓
        │   cheapest_tag (cached)
        │        │
        ├── self-join 取 main_item_type (item粒度最小model类型)
        ├── JOIN ecpm_label (item ecpm标签)
        └── JOIN vmodel (is_buybox判断 + live test过滤)
                 ↓
    INSERT OVERWRITE → dwd_sr_data_warehouse_tc_pb_one_variation_minf
    PARTITION(grass_region, regional_date, regional_hour, regional_minute)
```

### 关键步骤

**ETL Source 1（非美区通用逻辑）：**

| 步骤 | Temporary View / 操作 | 说明 |
|------|-----------------------|------|
| 1 | `shop_type` | 从 SCS 店铺维表取 shop_id → scs-local/scs-cb 映射 |
| 2 | `cspu_label` | 取 CSPU 近1日订单量，分区取 `regional_date` 前最新 local_date |
| 3 | `ecpm_label` | 取 Item ECPM 标签，分区取 `regional_date` 前最新 regional_date |
| 4 | `ads_active_item` | 取 placement 40/50 活跃广告商品，按 item_id 取最大 ads_id |
| 5 | `buybox_cspu_tag` | CSPU→Vitem 映射后 JOIN vitem 维表，计算冷启动周数（CEIL(天数/7)），同一 CSPU 多 vitem 取最大值，无匹配填9999 |
| 6 | `cheapest_raw` | 从 Paimon ODS 取原始 cheapest 数据，过滤删除项和 cspu_tag=8 |
| 7 | `cheapest_model` | JOIN cspu_label，计算 `is_winner`（business_type 3/4）和 `is_buyer_cheapest`（business_type 1/2 且订单量有效） |
| 8 | `cheapest_tag`（cached） | 整合 shop_scs_type、buybox 周数、ads_id，生成 `main_model_type`（TW 区用 is_buyer_cheapest 判断 SCS winner，其他区用 is_winner），过滤无效 cheapest |
| 9 | `vmodel` | 从 Paimon vsku mapping 取有效 Buybox model，排除 PH/TH 特定 live test vitem |
| 10 | **INSERT OVERWRITE** | cheapest_tag self-join 取 main_item_type → JOIN ecpm_label → JOIN vmodel 判断 is_buybox，写入目标表分区，REPARTITION(100) |

**ETL Source 2（美区 US 专属逻辑）：**

| 步骤 | Temporary View / 操作 | 说明 |
|------|-----------------------|------|
| 1~4 | 同 Source 1 对应步骤 | shop_type、cspu_label、ecpm_label、ads_active_item 逻辑相同 |
| 5 | `cheapest_model` | 直接从 Paimon ODS 取数，不区分 business_type，不计算 is_winner/is_buyer_cheapest |
| 6 | `cheapest_tag`（cached） | 无 buybox_cspu_tag JOIN（`cspu_buybox_boost_weeks` 固定为 9999）；main_model_type 简化为：SCS 店铺=2，否则=5；过滤条件为 `cspu_l1d_order_cnt is null or >0` |
| 7 | `vmodel` | 同 Source 1 |
| 8 | **INSERT OVERWRITE** | `is_winner` 固定输出 0，`is_buyer_cheapest` 固定输出 1，其余逻辑同 Source 1 |

### 注意事项

1. **Multi-writer 风险**：本表由两个独立 ETL 文件写入，Source 1 负责非美区大区，Source 2 负责美区（US）。两者均使用 `INSERT OVERWRITE`，按分区隔离，不存在相互覆盖问题，但需确保调度时序正确，避免同一分区被两个 job 并发写入。
2. **分区全量覆盖**：每次写入均为 `INSERT OVERWRITE` 特定 `(grass_region, regional_date, regional_hour, regional_minute)` 分区，同一分区重跑幂等安全。
3. **上游最新分区依赖**：`cspu_label`、`ecpm_label`、`buybox_cspu_tag`、`dim_sr_data_warehouse_vsku_vitem` 均通过 `data_infra.max_pt()` 动态取 `regional_date` 前最新分区，存在上游数据未就绪时回退到更早分区的风险。
4. **TW 区特殊逻辑**：台湾区的 `main_model_type` 判断使用 `is_buyer_cheapest` 而非 `is_winner` 来识别 SCS Winner，与其他大区存在差异，使用时需注意。
5. **美区字段语义差异**：US 分区的 `is_winner` 恒为 0，`cspu_buybox_boost_weeks` 恒为 9999，`main_model_type` 枚举仅含 2 和 5，与非美区语义不完全一致，跨区联合分析时需特别处理。
6. **Live test 过滤**：vmodel 视图对 PH、TH 大区硬编码排除了特定 vitem_id，属于业务侧 A/B 测试数据隔离逻辑。

---

*文档生成时间：2026-05-17*