<!-- ads-workspace-gdoc-sync: gdoc_id=1wW-G08eLihN8dxfh4rRfp7B1wsm6bsj4hmxCNtkieyc gdoc_url=https://docs.google.com/document/d/1wW-G08eLihN8dxfh4rRfp7B1wsm6bsj4hmxCNtkieyc/edit -->

# srdi_mart.dwd_sr_data_warehouse_pb_rcmd_replace_pruning_v3_hf

**分层：** DWD（明细层）
**主键：** `grass_region` + `regional_date` + `regional_hour` + `exp_tag` + `cspu_id` + `item_id`
**分区：** `grass_region`（大区）/ `regional_date`（日期）/ `regional_hour`（小时）
**更新频率：** 小时级（Hourly，准实时滚动更新）
**引用频次 / 访问频次：** 5848

---

## 业务描述

本表是搜推（SR）数仓中，**商品推荐替换链路（Replace Recommendation）的剪枝标记明细宽表**，记录了每个 CSPU 下各商品（item）在不同实验策略（exp_tag）下的剪枝状态（pruning_tag）及其版本信息。

**核心业务场景：**

1. **推荐替换剪枝管理**：在商品推荐替换场景（pb_rcmd_replace）中，对候选商品进行剪枝（pruning），区分"明显优质（obvious_good）"商品与需要经过质检筛选的商品，控制哪些商品可进入推荐替换候选集。
2. **增量 + 存量融合更新**：每小时任务在当前最优价格候选列表基础上，与历史最近一次有效分区的剪枝数据做全外连接合并，保证历史剪枝状态持续累积传递，同时对新进商品补充最新剪枝标记。
3. **多实验策略并行**：通过 `exp_tag`（当前版本为 T1、T2）支持多套实验策略并行运行，不同实验下剪枝逻辑可独立维护。
4. **版本化追溯**：`version_date` 记录剪枝标记最后一次更新时间，支持线上系统追溯剪枝信息的时效性。

**适合回答的问题：**

- 某大区（grass_region）、某小时分区下，哪些 item 在实验 T1/T2 中被剪枝？剪枝标记是什么？
- 某 cspu_id 下，各 item 的剪枝状态是否为最新版本（version_date）？
- 当前推荐替换候选集中，各商品的质检剪枝结果如何随小时滚动更新？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 SG、MY 等，用于物理分区隔离 |
| `regional_date` | date | 业务日期（大区本地时区），分区粒度为天 |
| `regional_hour` | int | 业务小时（0~23，大区本地时区），分区粒度为小时 |

### 维度：商品与实验策略标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_id` | bigint | 标准商品单元 ID（CSPU，Canonical SPU），关联最优价格模型中的商品聚合单元 |
| `item_id` | bigint | 商品明细 ID，推荐替换场景中的候选商品 |
| `exp_tag` | string | 实验策略标签，当前版本取值为 `T1`、`T2`；不同实验策略下剪枝逻辑独立 |

### 指标：剪枝状态与版本

| 字段 | 类型 | 说明 |
|---|---|---|
| `pruning_tag` | string | 剪枝标记。`T1` 实验策略下取自维表 `dim_sr_data_warehouse_pb_rcmd_replace_pruning_tag_df`；`T2` 等其他策略下新进商品赋值为 `obvious_good`；历史存量商品延续上一分区值 |
| `version_date` | int | 剪枝标记版本日期（格式：`YYYYMMDD` 整型）。商品首次写入或剪枝标记有更新时，赋值为当前运行日期；历史存量且无需更新时延续原值；无质检信息时为 `null` |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须全部指定**：查询时务必同时过滤 `grass_region`、`regional_date`、`regional_hour` 三个分区字段，否则将触发全表扫描，影响性能并产生高额计算费用。
- 示例：
  ```sql
  WHERE grass_region = 'SG'
    AND regional_date = '2024-06-01'
    AND regional_hour = 10
  ```
- 若需查询最新分区，建议先通过子查询确认当前最新可用分区，避免读到空分区或正在写入的分区。

### 不可直接 SUM / 聚合的字段

| 字段 | 原因 |
|---|---|
| `pruning_tag` | 枚举型标签，统计应使用 `COUNT`/`COUNT DISTINCT` 或 `GROUP BY` 而非 `SUM` |
| `version_date` | 版本日期整型，直接 `SUM` 无业务意义；应使用 `MAX` 获取最新版本或 `GROUP BY` 统计分布 |
| `exp_tag` | 枚举标签，跨 exp_tag 聚合前须明确是否需要按实验分组，避免将 T1/T2 数据混合统计 |

### 时效性说明

- 本表为**小时级滚动更新表**（`_hf` 后缀，Hourly Fresh），每小时覆盖写入对应分区。
- ETL 逻辑依赖**自身历史分区**做增量合并（回溯最近 7 天内最近一个可用历史分区），因此数据具有时序累积性，**同一 item 的最新剪枝状态应以最新小时分区为准**。
- 任务设计为**单并发度**执行，避免多 writer 并发写入同一分区导致数据不一致，查询时若发现最新分区数据量异常偏低，可能为任务尚未完成。
- `version_date` 可能为 `null`，表示该商品尚未获取到质检信息，使用时需做空值处理。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_pb_one_variation_model_minf` | 提供当前小时最优价格候选商品列表（cspu_id + item_id），作为本次更新的"新增候选集"基础，并通过 explode 按实验策略数量复制 |
| `srdi_mart.dwd_sr_data_warehouse_pb_rcmd_replace_pruning_v3_hf`（自身） | 读取近 7 天内最近一个可用历史分区，获取存量剪枝状态，与新候选集做全外连接，实现增量累积更新；同时用于动态计算上一有效分区位置 |
| `srdi_mart.dim_sr_data_warehouse_pb_rcmd_replace_pruning_tag_df` | 剪枝标记维表，提供 `T1` 实验策略下各 item 的最新质检剪枝结果（`pruning_tag`），取当日之前最新可用分区 |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_pb_one_variation_model_minf（当前小时最优价格候选）
        │  explode × exp_tag（T1, T2）
        ▼
cheapest_list（当前候选商品 × 实验策略）
        │
        │          dwd_sr_data_warehouse_pb_rcmd_replace_pruning_v3_hf（自身，近7天历史）
        │                  │ 取最近一个有效历史分区
        │                  ▼
        │          last_pruning（上一分区存量剪枝数据）
        │                  │
        └──── full outer join ────┘
                        ▼
              accumulated_pruning_list（候选集 + 存量，全量合并）
                        │
                        │    dim_sr_data_warehouse_pb_rcmd_replace_pruning_tag_df（T1剪枝标记维表）
                        │                  │ left join on item_id + exp_tag
                        └──── left join ───┘
                                    ▼
                    INSERT OVERWRITE → dwd_sr_data_warehouse_pb_rcmd_replace_pruning_v3_hf（当前分区）
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| Step 1 | `cheapest_list` | 从最优价格模型表取当前小时 cspu_id + item_id，通过 `explode(array('T1','T2'))` 按实验策略数量复制，生成候选集 |
| Step 2 | `SET last_partition` | 动态计算近 7 天内、早于当前运行小时的最大有效历史分区（格式：`date_str_HH`），兼做数据质量门控（版本日期集中在当日/昨日超 5% 则报错） |
| Step 3 | `last_pruning` | 从自身表读取上一有效分区的存量剪枝数据（exp_tag, cspu_id, item_id, version_date, pruning_tag） |
| Step 4 | `accumulated_pruning_list` | `last_pruning` full outer join `cheapest_list`，合并存量与新增候选；新增商品 version_date/pruning_tag 为 null，标记待更新 |
| Step 5 | `pruning_exp` | 从维表读取 T1 实验策略下最新剪枝标记（取 regional_date 之前最新 local_date 分区，仅 exp_tag='T1'） |
| Step 6 | `INSERT OVERWRITE` | 对合并结果 left join 剪枝维表，按 `update_flag`（version_date is null）判断是否需要更新：需要更新则写入维表新 pruning_tag 及当日 version_date；T2 等其他实验新进商品赋 `obvious_good`；无质检信息则 version_date 置 null；存量商品延续历史值 |

### 注意事项

1. **单并发度限制**：ETL 注释明确要求该任务以单并发度运行，以避免自引用（Step 2 读自身历史分区）与写入目标分区之间的数据竞争。生产调度需确保同一 `grass_region` 的小时任务不并发执行。
2. **自引用风险**：Step 2 和 Step 3 均读取目标表自身，若任务异常导致历史分区数据质量下降，可能影响后续小时的增量合并结果，需关注分区数据量监控。
3. **分区覆盖写入**：使用 `INSERT OVERWRITE ... PARTITION(grass_region, regional_date, regional_hour)`，仅覆盖当前运行的分区，不影响历史分区；但重跑时需注意历史分区（last_pruning）来源是否仍为预期版本。
4. **version_date 空值传播**：当维表无对应质检信息时，`version_date` 写入 null，且下次运行仍会触发 `update_flag=true` 尝试重新获取，属于设计预期行为，查询时需过滤或处理 null。
5. **实验策略扩展**：当前 explode 数组硬编码为 `array('T1','T2')`，新增实验策略时需同步修改 ETL SQL，否则新策略商品不会进入候选集。

---

*文档生成时间：2026-05-17*