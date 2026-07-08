<!-- ads-workspace-gdoc-sync: gdoc_id=1D6lvSHvWHpAlPlsqQQJYbLbWL29vk4Px2Re4YpAa6eQ gdoc_url=https://docs.google.com/document/d/1D6lvSHvWHpAlPlsqQQJYbLbWL29vk4Px2Re4YpAa6eQ/edit -->

# srdi_mart.dws_sr_data_warehouse_search_guide_user_benchmark_1d

**分层：** dws_search（数据仓库服务层 - 搜索域）
**主键：** user_id + device_id + platform + union_page_type + search_entrance + feature_tag + keyword（分区内联合唯一）
**分区：** grass_region（站点/区域）、local_date（业务日期）
**更新频率：** 每日全量覆盖写入（INSERT OVERWRITE，按分区）
**引用频次 / 访问频次：** 716

---

## 业务描述

本表是搜索导购（Search Guide）场景下的**用户行为基准宽表**，以「用户 × 设备 × 平台 × 页面类型 × 搜索入口 × 功能标签 × 关键词」为粒度，汇聚每自然日内的曝光、点击、浏览、成单及 GMV 等核心指标。

**核心业务场景：**
- 评估各搜索导购功能（搜索建议、预搜、搜索框联想等）的用户转化漏斗表现；
- 支持按功能标签（feature_tag）、搜索入口（search_entrance）、页面类型（union_page_type）分层拆解，分析不同场景的流量质量；
- 作为用户级别基准表，为搜索导购相关的 A/B 实验、策略评估、ROI 分析提供数据底座；
- 结合 keyword 维度，支持热词、长尾词的转化路径分析。

**适合回答的典型问题：**
- 特定搜索入口（如全局搜索、PDP 内搜索）在某日的用户曝光、点击及成单情况如何？
- 各搜索导购功能标签对应的 GMV 贡献分别是多少？
- 某关键词在不同平台和页面类型下的用户转化漏斗对比；
- 搜索导购模块的用户级别每日行为基线数据拉取。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/区域标识（如 ID、MY、TH 等），用于物理分区隔离各市场数据 |
| `local_date` | date | 业务日期（本地时区），对应数据统计的自然日，ETL 每日按此分区覆盖写入 |

### 维度：用户与设备标识

| 字段名 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 登录用户 ID；ETL 已过滤 `user_id > 0`，仅包含已登录用户 |
| `device_id` | string | 设备唯一标识，配合 user_id 用于跨登录状态的用户行为归因 |

### 维度：流量与场景属性

| 字段名 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 客户端平台（如 iOS、Android、PC 等）；原始为空时填充为 `'NA'` |
| `union_page_type` | string | 经功能映射表标准化后的页面类型（来源于 `dim_search_feature_mapping` 的 `final_page_type`），统一了多来源页面类型的口径 |
| `search_entrance` | string | 搜索入口标识（如搜索框、推荐词等）；原始为空时填充为 `'NA'` |
| `keyword` | string | 用户搜索关键词，已做 `trim(lower(...))` 标准化处理（小写、去首尾空格） |

### 维度：功能标签

| 字段名 | 类型 | 说明 |
|---|---|---|
| `feature_tag` | array\<string\> | 搜索导购功能标签数组，来源于 `dim_sr_data_warehouse_search_feature_tags_mapping_v2` 中 `feature_type = 'search_guide'` 的规则匹配结果，用于标识该行为归属的具体导购功能模块 |

### 指标：用户行为漏斗

| 字段名 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数（operation = 'impression' 的汇总计数） |
| `click_cnt` | bigint | 点击次数（operation = 'click' 的汇总计数） |
| `view_cnt` | bigint | 有效浏览次数（operation = 'view' 且 `is_back = false` 的汇总计数，排除返回页浏览） |
| `order_cnt` | double | 成单次数（operation = 'order' 的汇总计数）；涵盖直接成单及 source1/source2 归因成单 |
| `gmv` | double | 下单 GMV（place_order_gmv，operation = 'order' 时累加），单位与上游一致 |
| `pc2_gmv` | double | PC2 口径 GMV（pc2_gmv，operation = 'order' 时累加），为特定归因口径下的 GMV 指标 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须作为分区过滤条件，避免全表扫描。示例：`WHERE grass_region = 'ID'`
- **`local_date`**：必须明确指定日期或日期范围，避免跨分区大扫描。示例：`AND local_date = '2024-01-01'`
- 两个分区字段应**同时**出现在 WHERE 子句中，尤其在生产查询和调度任务中。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `feature_tag` | 类型为 `array<string>`，不可直接聚合；需先 EXPLODE 展开后再分组统计 |
| `gmv`、`pc2_gmv` | 用户粒度已按多来源（直接成单 + source1 + source2 归因）UNION ALL 聚合，跨行求和可能造成**归因重叠双计**，使用时须明确去重逻辑或仅在单一来源场景下汇总 |
| `order_cnt` | 同 gmv/pc2_gmv，包含多归因路径合并结果，跨粒度累加需注意口径一致性 |

### 时效性说明

- 本表为**每日全量分区覆盖**（`1d` 后缀），数据延迟为 T+1（当日数据于次日产出）；
- 无滚动窗口（如 `_nd`、`_td`）逻辑，每个 `local_date` 分区仅反映当日行为，多日汇总需在查询层自行累加；
- 数据产出后即静态，不做追溯修正（以 INSERT OVERWRITE 分区覆盖为准）。

### 其他注意事项

- 本表**仅包含已登录用户**（`user_id > 0`），未登录用户行为不在统计范围内；
- `union_page_type` 是经过 `dim_search_feature_mapping` 规则映射后的标准化页面类型，与 DWD 层的原始 `page_type` 存在多对一关系，不应将其与上游原始字段直接对比；
- `feature_tag` 为数组类型，同一行数据可能对应多个功能标签，分析特定功能时请使用 `ARRAY_CONTAINS` 或 `EXPLODE` 展开。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_search` | 搜索行为明细 DWD 层，提供曝光、点击、浏览、成单等原始操作事件及归因字段（source1/source2） |
| `srdi_mart.dim_sr_data_warehouse_search_feature_tags_mapping_v2` | 搜索导购功能标签维表，定义页面类型、入口、平台等多维度条件与 feature_tag 的映射规则（`feature_type = 'search_guide'`） |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_search          dim_sr_data_warehouse_search_feature_tags_mapping_v2
         │                                                │
         ▼                                                ▼
  [Temp View]                                      [Temp View]
dwd_search_page                          dim_search_feature_mapping
（行为事件按维度聚合，                     （规则解析：in/not_in 条件
  UNION ALL 三路来源）                       展开为数组，按 feature_type
                                             = 'search_guide' 过滤）
         │                                                │
         └─────────────── INNER JOIN ────────────────────┘
                          （多条件规则匹配）
                                  │
                                  ▼
          dws_sr_data_warehouse_search_guide_user_benchmark_1d
                    （用户粒度按维度分组 SUM 汇总）
```

### 关键步骤

**Step 1 — 创建功能标签映射 Temp View（`dim_search_feature_mapping`）**
- 从 `dim_sr_data_warehouse_search_feature_tags_mapping_v2` 读取 `feature_type = 'search_guide'` 的规则行；
- 将 `input_type`、`search_mid`、`search_entrance`、`content_mix_frame_tab_name`、`current_page`、`platform` 等字段按 `in!` / `not_in!` 前缀拆解为数组，用于后续 JOIN 时的多值条件匹配；
- `feature_tag` 按 `,` 分割后取 `max`，作为维度组的最终标签。

**Step 2 — 创建搜索行为聚合 Temp View（`dwd_search_page`）**
- **Branch 1（主路径）**：从 DWD 层读取指定日期和区域的搜索行为，过滤 `operation IN ('impression', 'click', 'view', 'order')`，限定 `page_type` 为搜索相关页面，按用户、设备、平台、页面、入口、关键词等维度聚合 imp/click/view/order/gmv/pc2_gmv；
- **Branch 2（source1 归因成单）**：仅取 `operation = 'order'`，使用 `source1_*` 系列字段（source1_page_type、source1_keyword 等）作为归因维度，限定 `source1_page_type` 为核心搜索页面类型（global_search、search_in_pdp、search_prefill），追加归因成单及 GMV；
- **Branch 3（source2 归因成单）**：同 Branch 2，使用 `source2_*` 系列字段进行二级归因；
- 三路通过 `UNION ALL` 合并，形成完整的搜索导购行为事件集合。

**Step 3 — INSERT OVERWRITE 写目标分区**
- 将 `dwd_search_page`（t1）与 `dim_search_feature_mapping`（t2）做 INNER JOIN，匹配条件涵盖 page_type、operation、page_section、target_type、input_type（支持 in/not_in）、if_shop、search_entrance（in）、search_mid（in）、content_mix_frame_tab_name（in/not_in）、current_page（in/not_in）、platform（in）共 11 个维度条件，均支持空值通配（条件字段为空字符串时视为匹配所有）；
- JOIN 结果按用户、设备、平台、`final_page_type`（即 `union_page_type`）、搜索入口、`feature_tag`、关键词分组，SUM 汇总各指标；
- 以 INSERT OVERWRITE + PARTITION(grass_region, local_date) 写入目标表，每次执行覆盖单个分区。

### 注意事项

- **多归因 UNION ALL 导致指标叠加**：Branch 2 和 Branch 3 使用 source1/source2 归因字段，与 Branch 1 的直接成单存在逻辑重叠。同一笔订单可能同时出现在直接路径和归因路径中，跨行汇总 `order_cnt`、`gmv`、`pc2_gmv` 时需明确分析口径，避免双计；
- **INNER JOIN 的过滤效应**：仅有能与功能标签规则表成功匹配的行为数据才会进入结果集，若 DWD 数据中存在规则未覆盖的 page_type 或维度组合，对应行为将被静默丢弃，不会报错；
- **单一写入文件，无 multi-writer 风险**：本表仅由一个 ETL 文件写入，不存在多文件并发写同一分区的风险；
- **规则表变更影响结果**：`dim_sr_data_warehouse_search_feature_tags_mapping_v2` 是动态配置表，规则变更会直接影响历史日期重跑后的 `union_page_type` 和 `feature_tag` 分布，历史数据重刷时需关注规则版本一致性。

---

*文档生成时间：2026-05-17*