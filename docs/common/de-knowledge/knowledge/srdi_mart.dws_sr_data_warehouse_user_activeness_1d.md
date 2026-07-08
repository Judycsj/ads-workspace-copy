<!-- ads-workspace-gdoc-sync: gdoc_id=1zYRTpU2H_bVStwnzXEFy-SqYfdYx0TI4ddNtNefwlH4 gdoc_url=https://docs.google.com/document/d/1zYRTpU2H_bVStwnzXEFy-SqYfdYx0TI4ddNtNefwlH4/edit -->

# srdi_mart.dws_sr_data_warehouse_user_activeness_1d

**分层：** dws_search
**主键：** user_id + grass_region + local_date
**分区：** grass_region, local_date
**更新频率：** 每日一次（T+1 全量覆写当日分区）
**访问频次：** 2254

---

## 业务描述

本表记录 Shopee 各站点用户在**过去 30 天**内（以当日为基准）的平台活跃度与搜索活跃度的画像快照，粒度为「用户 × 站点 × 日期」。

**核心业务场景：**
- 衡量用户在 Shopee 平台整体的活跃程度（近 30 天内的活跃天数及历史记录）
- 衡量用户在搜索场景（全局搜索、PDP 内搜索、预填充搜索）的活跃程度
- 按各站点独立阈值将用户分层为 High / Medium / Low / No 四档活跃度类型，支持精细化运营和人群圈选
- 仅保留在 `local_date` 当天有平台活跃行为的用户（过滤掉历史沉默用户），保证数据新鲜度

**适合回答的问题：**
- 某站点当日有多少用户是高活跃搜索用户（`search_activeness_type = 'High'`）？
- 用户在过去 30 天内共有哪些天进行过搜索/访问平台？
- 某用户是否在当日发生了搜索行为？
- 各活跃度分层（High/Medium/Low/No）用户的分布情况如何？
- 搜索活跃用户与平台整体活跃用户的重叠情况如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域，如 ID、MY、SG、TH、PH、TW、VN、BR、CL、CO、MX 等 |
| `local_date` | date | 数据日期（本地时区），对应 ETL 执行当天，即快照基准日 |

### 维度：用户标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | Shopee 用户 ID，唯一标识用户；仅包含在 `local_date` 当天在平台有活跃行为的登录用户（user_id > 0） |

### 指标：Shopee 平台活跃度（近 30 天）

| 字段 | 类型 | 说明 |
|---|---|---|
| `shopee_activeness_history` | array\<date\> | 用户在过去 30 天内（不含当日）有 Shopee 平台活跃行为的日期列表，按升序排列 |
| `shopee_activeness_days` | int | 用户在过去 30 天内（不含当日）Shopee 平台活跃天数，即 `shopee_activeness_history` 的元素个数；若无历史活跃则为 0 |
| `shopee_activeness_type` | string | 基于 `shopee_activeness_days` 按各站点独立阈值划定的平台活跃度分层：`High` / `Medium` / `Low` / `No`；各站点阈值不同，详见 ETL 逻辑摘要 |

### 指标：搜索活跃度（近 30 天）

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_activeness_history` | array\<date\> | 用户在过去 30 天内（不含当日）有搜索行为的日期列表，按升序排列；搜索行为包含 global_search、search_in_pdp、search_prefill 页面的 view 操作 |
| `search_activeness_days` | int | 用户在过去 30 天内（不含当日）搜索活跃天数，即 `search_activeness_history` 的元素个数；若无搜索历史则为 0 |
| `search_activeness_type` | string | 基于 `search_activeness_days` 按各站点独立阈值划定的搜索活跃度分层：`High` / `Medium` / `Low` / `No`；各站点阈值不同，详见 ETL 逻辑摘要 |
| `if_search` | boolean | 用户在 `local_date` 当日是否有搜索行为；`true` 表示当日有搜索，`false` 或 `null` 表示无搜索 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区过滤必须同时指定 `grass_region` 和 `local_date`**，否则将触发全表扫描，代价极高。

```sql
WHERE grass_region = 'ID'
  AND local_date = '2025-01-01'
```

- 若需跨日期对比，务必显式枚举或使用范围过滤，并注意每个 `local_date` 分区为独立快照。

### 不可直接 SUM / AVG 的字段

| 字段 | 原因 |
|---|---|
| `shopee_activeness_history` | Array 类型，不可直接聚合；如需计数请用 `size()` 函数，等价于 `shopee_activeness_days` |
| `search_activeness_history` | 同上，不可直接聚合；如需计数请用 `size()` 函数，等价于 `search_activeness_days` |
| `shopee_activeness_type` / `search_activeness_type` | 分层枚举值，跨站点的阈值定义不一致，禁止跨 `grass_region` 汇总后直接比较分层结果 |
| `shopee_activeness_days` / `search_activeness_days` | 统计窗口为近 30 天（不含当日），跨日期分区直接 SUM 无业务意义，须注意窗口重叠 |

### 时效性说明

- 本表为 **T+1 日级快照表**（`_1d` 后缀），每日覆写当日 `grass_region × local_date` 分区。
- 每个分区记录的活跃度窗口为 **`local_date` 前 30 天（含当日）**，其中历史字段和天数均**排除当日**，`if_search` 和 `base_user` 逻辑来自当日数据。
- 表中用户范围仅限于在 `local_date` **当日在平台有活跃行为**的用户，历史沉默用户不会出现。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `traffic.shopee_traffic_dws_active_user_1d__reg_s1_live` | 提供近 30 天用户级平台活跃日期明细，用于计算 Shopee 整体活跃度；过滤本地时区（`tz_type = 'local'`）及有效用户（`user_id > 0`） |
| `srdi_mart.dwd_sr_data_warehouse_search` | 提供近 30 天用户级搜索行为日期明细（page_type 为 global_search / search_in_pdp / search_prefill，operation = view），用于计算搜索活跃度 |

---

## ETL 逻辑摘要

### 数据流

```
traffic.shopee_traffic_dws_active_user_1d__reg_s1_live  ──┐
  （近 30 天平台活跃记录）                                   │
                                                           ├──► user_overall_activeness
srdi_mart.dwd_sr_data_warehouse_search  ─────────────────┘         （LEFT JOIN）
  （近 30 天搜索行为记录）                                              │
                                                                      ▼
                              srdi_mart.dws_sr_data_warehouse_user_activeness_1d
                                        （INSERT OVERWRITE 目标分区）
```

### 关键步骤

1. **Statement 1 — `dws_active_user`（临时视图）**
   从平台活跃表中取近 30 天内、当前站点、本地时区、有效用户的活跃记录，按 `user_id + grass_date` 去重。

2. **Statement 2 — `user_shopee_activeness_history`（临时视图）**
   对上一步结果按用户聚合：收集除当日外的所有活跃日期（`shopee_activeness_history`，升序排列）；统计总行数减 1 作为历史活跃天数（`shopee_activeness_days`，即排除当日）；标记用户当日是否有活跃行为（`base_user`）。

3. **Statement 3 — `user_shopee_activeness_history_filter`（临时视图）**
   过滤仅保留 `base_user = true` 的用户，即当日在平台有活跃记录的用户，排除历史沉默用户。

4. **Statement 4 — `dwd_platform`（临时视图）**
   从搜索 DWD 表中取近 30 天内、当前站点、有效用户、指定 page_type（global_search / search_in_pdp / search_prefill）、operation = view 的搜索记录，按 `user_id + local_date` 去重。

5. **Statement 5 — `user_search_activeness_history`（临时视图）**
   对搜索记录按用户聚合：收集除当日外的搜索日期（`search_activeness_history`，升序排列）；统计历史搜索天数（`search_activeness_days`，排除当日）；标记用户当日是否有搜索（`if_search`）。

6. **Statement 6 — `user_overall_activeness`（临时视图）**
   以平台活跃用户集（`user_shopee_activeness_history_filter`）为主表，LEFT JOIN 搜索活跃用户集（`user_search_activeness_history`），合并两类活跃度指标；搜索相关字段对无搜索用户默认填 0（`search_activeness_days`），`if_search` 和 `search_activeness_history` 对无搜索用户为 null/false。

7. **Statement 7 — INSERT OVERWRITE（写目标表）**
   从 `user_overall_activeness` 读取数据，按站点独立阈值通过多路 CASE WHEN 计算 `shopee_activeness_type` 和 `search_activeness_type`，写入目标表指定分区（`grass_region + local_date`）。

### 注意事项

- **单 Writer，无并发冲突风险**：本表仅由一个 ETL 文件写入，无多路 Writer 竞争问题。
- **INSERT OVERWRITE 全量覆盖**：每次运行会完整覆写 `grass_region × local_date` 对应分区，历史分区数据保持不变。
- **活跃度分层阈值为硬编码**：`shopee_activeness_type` 和 `search_activeness_type` 的分层阈值直接内嵌于 SQL CASE WHEN，各站点阈值不同，阈值变更需修改 ETL 代码并重刷历史分区方可生效。
- **CO 站点 `search_activeness_type` 无 Low 档**：根据 ETL 逻辑，CO 站点搜索活跃度分层仅有 High（≥4天）、Medium（≥1天）、No（0天）三档，缺少 Low 档，与其他站点不一致，使用时需注意。
- **历史字段排除当日**：`shopee_activeness_history` 和 `search_activeness_history` 均**不包含** `local_date` 当日，对应天数字段同理；当日行为仅通过 `if_search` 字段体现（搜索）或用于 `base_user` 过滤（平台活跃）。
- **用户范围限制**：表中只包含在 `local_date` 当天有平台活跃记录的用户，不在当日活跃的历史用户不会出现在当日分区，使用时勿误将缺失记录理解为用户不存在。

---

*文档生成时间：2026-05-17*