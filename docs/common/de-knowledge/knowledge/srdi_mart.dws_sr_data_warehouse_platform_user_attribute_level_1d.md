<!-- ads-workspace-gdoc-sync: gdoc_id=1owAAAXuLE8K8ntyx2Xn_OcYA9qKbZzn1HdWSHogY080 gdoc_url=https://docs.google.com/document/d/1owAAAXuLE8K8ntyx2Xn_OcYA9qKbZzn1HdWSHogY080/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_user_attribute_level_1d

**分层：** DWS（数据汇总层）
**主键：** `platform` + `item_click_level` + `dd_click_level` + `major_app_version` + `app_version` + `grass_region` + `local_date`
**分区：** `grass_region`（区域）、`local_date`（日期）
**更新频率：** 每日一次（T+1）
**访问频次：** 168 次

---

## 业务描述

本表是搜推数据仓库平台的用户属性分层汇总宽表，按 **平台、用户点击层级、App 版本** 等维度组合，对每日活跃用户数（DAU）及核心行为指标（曝光、页面浏览、下单）进行多维预聚合。

核心业务场景：
- 分析不同平台（Android / iOS / Web 等）下各用户点击层级（`item_click_level`、`dd_click_level`）的流量与转化漏斗；
- 按 App 大版本（`major_app_version`）或精确版本（`app_version`）拆分，评估版本上线效果及用户分布；
- 通过 `GROUPING SETS` 预先生成版本"全量汇总"行（值为 `__ALL__`），支持跨版本聚合查询而无需二次去重；
- 为搜推业务 BI 报表、日常运营监控及 A/B 实验分析提供底层数据支撑。

适合回答的典型问题：
- 某区域某日各平台的日活用户数及下单量是多少？
- 各 App 版本间的全站曝光和 PPV 表现差异如何？
- 不同用户点击层级（`item_click_level` / `dd_click_level`）下的流量分配情况？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 区域标识（如 `'SG'`、`'MY'` 等），每个分区对应一个站点 |
| `local_date` | date | 数据日期，每次 ETL 按天覆盖写入 |

### 维度：用户属性与平台信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 客户端平台，如 `android`、`ios`、`web` 等；无数据时填充空字符串 `''` |
| `major_app_version` | string | App 主版本号（取 `app_version` 去掉末级段后的前缀，如 `2.94`）；汇总行取值为 `__ALL__` |
| `app_version` | string | App 完整版本号（如 `2.94.15`）；汇总行取值为 `__ALL__` |
| `item_click_level` | string | 用户商品点击层级标签，来自用户标签维表；无标签时填充空字符串 `''` |
| `dd_click_level` | string | 用户 DD（直播/频道）点击层级标签，来自用户标签维表；无标签时填充空字符串 `''` |

### 指标：用户活跃与行为量

| 字段 | 类型 | 说明 |
|---|---|---|
| `dau` | bigint | 当日活跃用户数（DAU），对满足 `is_dau_data=1`（来自流量事件流）的 `user_id` 去重计数；**不可直接 SUM** |
| `omni_imp_cnt` | bigint | 全域曝光次数（operation='omni_impression'），汇总自 DWD 平台表 |
| `ppv_cnt` | bigint | 页面浏览次数（operation='ppv' 且非回退行为），汇总自 DWD 平台表 |
| `order_cnt` | double | 下单次数（operation='order'），汇总自 DWD 平台表 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region` 和 `local_date`**，否则将扫描全量分区，严重影响查询性能：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2025-01-01'
  ```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `dau` | 本表已对 `user_id` 做 `COUNT(DISTINCT)`，跨维度组合行的 `dau` 存在用户重叠，直接 SUM 会导致重复计数 |

> **版本汇总行说明**：`major_app_version = '__ALL__'` 且 `app_version = '__ALL__'` 的行对应所有版本合并的汇总，`major_app_version != '__ALL__'` 且 `app_version = '__ALL__'` 的行对应该大版本下所有子版本汇总。跨 Grouping Sets 层级混合查询时请确保过滤条件一致，避免重复统计。

### 时效性说明

- 本表为 **日粒度（`_1d`）** 表，每天覆盖写入当天数据（`INSERT OVERWRITE PARTITION`）；
- 数据通常于次日（T+1）产出，不适用于实时或小时级分析场景；
- `omni_imp_cnt`、`ppv_cnt`、`order_cnt` 均已在用户粒度预聚合后再汇总，跨行 SUM 可直接使用。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_user_label` | 用户标签维表，提供 `item_click_level`、`dd_click_level` 两个用户层级标签 |
| `traffic.shopee_traffic_dwd_event_stream_hi__reg_s1_live` | 流量事件流明细表，筛选 `view`/`auto_view` 事件，用于识别 DAU 用户及获取 `platform`、`app_version` 信息 |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 搜推平台 DWD 行为明细表，提供 `omni_impression`、`ppv`、`order` 三类操作的汇总量 |

---

## ETL 逻辑摘要

### 数据流

```
traffic.shopee_traffic_dwd_event_stream_hi__reg_s1_live  ──┐
                                                            ├──► user_data（用户粒度聚合）
srdi_mart.dwd_sr_data_warehouse_platform ──────────────────┘
                                                            ├──► base_data（关联用户标签）
srdi_mart.dim_sr_data_warehouse_user_label ────────────────┘
                                                            ├──► cube_data（维度预聚合）
                                                            │
                                                            └──► INSERT OVERWRITE 目标表（GROUPING SETS 汇总）
```

### 关键步骤

1. **Statement 1 — `dim_<region>` 临时视图**
   从用户标签维表按 `grass_region` 和 `local_date` 过滤，获取每个用户的 `item_click_level` 和 `dd_click_level`。

2. **Statement 2 — `user_data_<region>` 临时视图**
   通过 `UNION ALL` 合并两路数据：
   - **路径 A（DAU 识别）**：从流量事件流中筛选 `view`/`auto_view` 事件，标记 `is_dau_data=1`，行为指标置 `null`；
   - **路径 B（行为指标）**：从 DWD 平台表中筛选 `omni_impression`、`ppv`（非回退）、`order` 事件，汇总各操作计数。
   合并后按 `platform`、`app_version`、`major_app_version`、`user_id` 分组，`is_dau_data` 取 `max`，指标取 `sum`。

3. **Statement 3 — `base_data_<region>` 缓存表**
   将 `user_data` 与 `dim`（用户标签）按 `user_id` 做 `LEFT JOIN`，填充 `item_click_level`、`dd_click_level`（空值填充为 `''`）；`is_dau_data=0` 的用户 `user_id` 置为 `null`（不参与 DAU 计数）。结果缓存到内存+磁盘（`MEMORY_AND_DISK_SER`）。

4. **Statement 4 — `cube_data_<region>` 缓存表**
   在 `base_data` 基础上，按模板占位符（`${fields_placeholder}`、`${groupby_placeholder}`）动态展开维度，对 `platform`、`item_click_level`、`dd_click_level` 进行 Cube 展开，并在用户粒度内对 `omni_imp_cnt`、`ppv_cnt`、`order_cnt` 求和。结果同样缓存。

5. **Statement 5 — INSERT OVERWRITE 写目标表**
   从 `cube_data` 按 `platform`、`item_click_level`、`dd_click_level`、`major_app_version`、`app_version` 分组，使用 `GROUPING SETS` 生成三个层级的汇总行：
   - 层级 1：仅平台+点击层级（版本均为 `__ALL__`）；
   - 层级 2：大版本+平台+点击层级（`app_version` 为 `__ALL__`）；
   - 层级 3：完整版本+平台+点击层级。
   `dau` 由 `COUNT(DISTINCT user_id)` 计算，各指标累加求和后覆盖写入目标分区。

### 注意事项

- **单 writer**：本表仅有 1 个 ETL 文件写入，不存在多 writer 并发覆盖风险；
- **动态模板占位符**：ETL SQL 中包含 `${fields_placeholder}`、`${groupby_placeholder}` 等模板变量，实际执行时由调度框架注入，用于生成 Cube 展开逻辑，代码维护时需关注模板渲染正确性；
- **`__ALL__` 汇总行**：`major_app_version` 和 `app_version` 为 `__ALL__` 的行由 `GROUPING SETS` 生成，下游查询时若不做版本层级过滤，需注意避免将汇总行与明细行混合聚合；
- **DAU 的空值处理**：`is_dau_data=0` 的用户 `user_id` 被置为 `null`，仅贡献行为指标而不计入 DAU，保证 DAU 口径与 DAU 事件流定义一致；
- **`ppv_cnt` 口径**：仅统计 `is_back=FALSE` 的 PPV，即去除回退行为触发的页面浏览，确保与前向页面访问量保持一致。

---

*文档生成时间：2026-05-17*