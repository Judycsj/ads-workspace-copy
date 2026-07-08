<!-- ads-workspace-gdoc-sync: gdoc_id=12qB4nsAnieMUquLzWG4sq-8s5lgST8wVRQ3e0XIbqQk gdoc_url=https://docs.google.com/document/d/12qB4nsAnieMUquLzWG4sq-8s5lgST8wVRQ3e0XIbqQk/edit -->

# srdi_mart.dws_sr_data_warehouse_vsku_vitem_nd

**分层：** DWS（数据汇总层）
**主键：** `vitem_id`
**分区：** `grass_region`（大区）、`local_date`（业务日期）
**更新频率：** 每日一次（T+0 当日全量覆盖写入）
**访问频次：** 3,014 次

---

## 业务描述

本表为搜推数仓（SRDI）中虚拟 SKU 维度商品（vitem）的每日汇总宽表，以 `vitem_id` 为核心粒度，汇聚当日曝光、点击、下单等核心行为指标，同时维护滚动累计下单量（nd 窗口）。

**核心业务场景：**
- 监控各大区各虚拟商品在搜推场景下的每日曝光量、点击量及转化下单量。
- 基于滚动 N 日累计订单量（`order_cnt_nd`）评估商品近期综合销售势能，辅助推荐排序与召回策略优化。
- 支持搜推效果报表、商品健康度分析及实时/离线双轨数据校验等场景。

**适合回答的问题：**
- 某大区某日某虚拟商品的曝光量/点击量/当日订单量是多少？
- 某虚拟商品近 N 日的累计订单量趋势如何？
- 各大区虚拟商品的 CTR、CVR 等漏斗指标（需二次计算）。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 业务大区（如 MY、TH、VN 等），与订单、曝光数据的 grass_region 对齐 |
| `local_date` | date | 业务日期（本地时区），每日分区覆盖写入 |

### 维度：虚拟商品维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `vitem_id` | bigint | 虚拟商品 ID（vsku item ID），来源于 `dim_sr_data_warehouse_vsku_vitem` 的 `vitem_id` / 订单表的 `spu_vsku_item_id`，为本表主键 |

### 指标：当日行为指标（1d）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt_1d` | bigint | 当日曝光次数，来源于 `dwd_sr_data_warehouse_platform`，operation = 'impression' 的汇总 |
| `click_cnt_1d` | bigint | 当日点击次数，来源于 `dwd_sr_data_warehouse_platform`，operation = 'click' 的汇总 |
| `order_cnt_1d` | double | 当日订单量（分数订单，非整单），来源于 `dwd_spu_vsku_order_item_df__reg_live` 的 `order_fraction` 汇总 |

### 指标：滚动 N 日累计指标（nd）

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt_nd` | double | 滚动 N 日累计订单量，由前一日快照的 `order_cnt_nd` 与当日新增订单量累加得出（`coalesce(昨日order_cnt_nd, 0) + coalesce(今日order_cnt, 0)`），为预聚合滚动累计值，**不可直接跨行 SUM** |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region` 和 `local_date` 分区字段**，否则将触发全表扫描，引发严重性能问题。
  ```sql
  WHERE grass_region = 'MY'
    AND local_date = '2024-06-01'
  ```
- `grass_region` 为字符串类型，需用单引号括起；`local_date` 为 date 类型，建议使用标准日期格式 `'YYYY-MM-DD'`。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `order_cnt_nd` | 滚动 N 日累计预聚合值，已在 ETL 中逐日叠加，跨行 SUM 会导致重复计数；如需多商品汇总可 SUM，但**不可跨日期 SUM** |
| CTR / CVR（派生） | 需用 `sum(click_cnt_1d) / sum(imp_cnt_1d)` 等方式二次计算，不可对比率直接求和 |

### 时效性说明

- 本表为 **`*_nd` 滚动累计表**，`order_cnt_nd` 表示截至 `local_date` 的近 N 日滚动累计，N 的窗口大小由上游业务配置决定（ETL 中通过每日叠加前一天快照实现）。
- 当日数据在当天 ETL 任务完成后方可使用，**曝光/点击使用离线 DWD 数据**，订单来源使用 `reg_live` 层（接近实时），两者存在轻微口径差异。
- 每日以 `INSERT OVERWRITE` 方式写入，历史分区数据不回刷，如需历史对比请按 `local_date` 分区逐日查询。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_vsku_vitem_nd` | 读取前一日（`local_date - 1`）同分区快照，获取历史滚动累计订单量 `order_cnt_nd`，用于 nd 指标的链式累加 |
| `mp_order.dwd_spu_vsku_order_item_df__reg_live` | 提供当日实时/准实时订单明细，按 `spu_vsku_item_id` 汇总 `order_fraction` 得到当日订单量 |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 提供当日搜推平台曝光（impression）与点击（click）行为明细，按 `item_id` 汇总 |
| `srdi_mart.dim_sr_data_warehouse_vsku_vitem` | 虚拟商品维度表，用于过滤出当日有效的 vitem_id，确保曝光/点击数据 join 范围的准确性 |

---

## ETL 逻辑摘要

### 数据流

```
[昨日快照]                          [当日行为数据]
dws_sr_data_warehouse_vsku_vitem_nd  mp_order.dwd_spu_vsku_order_item_df__reg_live
(local_date - 1)                         ↓ sum(order_fraction)
       ↓                           today_order_{region}
before_data_{region}                     ↓
(vitem_id, order_cnt_nd)          dwd_sr_data_warehouse_platform
                                   × dim_sr_data_warehouse_vsku_vitem
                                         ↓ sum(imp/click)
                                   today_imp_{region}
                                         ↓
                                   today_data_{region}
                                   (vitem_id, imp_cnt, click_cnt, order_cnt)
       ↓                                 ↓
       └─────── FULL OUTER JOIN ─────────┘
                       ↓
    INSERT OVERWRITE dws_sr_data_warehouse_vsku_vitem_nd
    partition(grass_region, local_date)
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| Step 1 | `before_data_{region}` | 从本表前一日分区读取 `vitem_id` 和 `order_cnt_nd`，作为历史 nd 累计基数 |
| Step 2 | `today_order_{region}` | 从订单 reg_live 层读取当日分数订单，按 `spu_vsku_item_id` 汇总为 `order_cnt` |
| Step 3 | `today_imp_{region}` | 从平台行为 DWD 表读取当日数据，inner join 维度表过滤有效 vitem，分别汇总曝光量和点击量 |
| Step 4 | `today_data_{region}` | UNION ALL 合并 Step 2、Step 3，按 `vitem_id` 二次聚合，得到当日完整行为汇总 |
| Step 5 | INSERT OVERWRITE | `before_data` FULL OUTER JOIN `today_data`，计算最终字段并覆盖写入目标分区 |

**nd 字段计算逻辑：**
```sql
order_cnt_nd = coalesce(before_data.order_cnt_nd, 0) + coalesce(today_data.order_cnt, 0)
```
即在前一日累计值基础上叠加当日新增订单量，实现滚动累计。

### 注意事项

1. **自引用写入风险：** ETL Step 1 读取的是目标表自身的前一日分区（`local_date - 1`），若前一日数据缺失或写入失败，会导致 `order_cnt_nd` 断链（退化为仅当日订单量），需关注上游依赖的时效保障。
2. **Single Writer：** `multi_writer = false`，仅一个 ETL 文件写入本表，无并发写入冲突风险，但同一任务中 `grass_region` 参数化执行时需注意分区隔离（各 region 独立分区写入）。
3. **FULL OUTER JOIN 空值处理：** 使用 `if(a.vitem_id is not null, a.vitem_id, b.vitem_id)` 保留仅在订单或仅在曝光中出现的 vitem；当某侧为 NULL 时，对应指标以 `coalesce(..., 0)` 补零，使用时需注意部分商品可能仅有 nd 历史值而无当日 1d 指标（或反之）。
4. **曝光/点击与订单的数据源差异：** 曝光点击来自离线 DWD 层，订单来自 `reg_live` 准实时层，两者入库时效存在轻微差异，汇总口径略有不同，跨指标联合分析时需注意。
5. **dim 表过滤范围：** `today_imp` 通过 INNER JOIN `dim_sr_data_warehouse_vsku_vitem` 限定 vitem 范围，若某 vitem 当日未在维度表中则其曝光/点击数据会被过滤掉，以维度表当日有效数据为准。

---

*文档生成时间：2026-05-17*