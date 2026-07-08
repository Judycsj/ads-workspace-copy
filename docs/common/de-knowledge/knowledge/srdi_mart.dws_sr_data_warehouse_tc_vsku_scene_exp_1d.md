<!-- ads-workspace-gdoc-sync: gdoc_id=17wHkZ17cDmvjoVwe7PGY6w5D0-CNPAMSsjPO7qrVEqY gdoc_url=https://docs.google.com/document/d/17wHkZ17cDmvjoVwe7PGY6w5D0-CNPAMSsjPO7qrVEqY/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_vsku_scene_exp_1d

**分层：** DWS（数据服务层）
**主键：** `grass_region` + `local_date` + `scene` + `exp_group_id` + `is_ads` + `is_video_card`
**分区：** `grass_region`（站点区域）、`local_date`（业务日期）
**更新频率：** 每日全量覆盖（INSERT OVERWRITE）
**访问频次：** 411 次

---

## 业务描述

本表用于支撑搜索与推荐（Search & RCMD）A/B 实验效果分析，以**虚拟 SKU（vsku/vitem）在各场景下的曝光、点击、下单及 GMV 表现**为核心指标，结合实验分组（exp_group_id）、场景（scene）、是否广告（is_ads）、是否视频卡片（is_video_card）等维度，提供细粒度的日级聚合数据。

**核心业务场景：**

- A/B 实验分组效果对比：在 Search 和 RCMD 场景下，评估不同实验分组对 vitem 曝光率、转化率、GMV 的影响；
- vitem 覆盖率分析：通过 vitem 与 cspu、场景整体的曝光/订单比率，衡量 vsku 模型的覆盖深度；
- 广告 vs 自然流量对比：通过 `is_ads` 维度拆分广告与非广告流量的 vitem 指标表现；
- 视频卡片效果分析：通过 `is_video_card` 维度评估视频卡片对 vitem 指标的贡献。

**适合回答的典型问题：**

- 某实验分组在 Search 场景下，vitem 的曝光渗透率（vitem_scene_imp_ratio）较对照组是否有显著提升？
- 广告流量中 vitem 的 GMV 贡献如何？
- 视频卡片场景下 vitem 下单量占 cspu 下单量的比例是多少？
- 平台整体下单量与 vitem 下单量的关系如何？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/区域标识，如 `MY`、`TH` 等，用于多站点数据隔离 |
| `local_date` | date | 业务日期，数据所属的本地自然日 |

### 维度：实验与场景标识

| 字段名 | 类型 | 说明 |
|---|---|---|
| `scene` | string | 流量场景，枚举值：`Search`（全站搜索）、`Daily Discover`（首页发现）、`You May Also Like`（猜你喜欢）、`Post Purchase`（下单后推荐）；RCMD 场景下还会出现 `RCMD`（聚合推荐） |
| `exp_group_id` | int | A/B 实验分组 ID，来源于实验白名单用户分组表 |
| `is_ads` | string | 是否广告流量；`true` 表示广告，`false` 表示自然流量，`__ALL__` 表示全量聚合（CUBE 产生的汇总行） |
| `is_video_card` | string | 是否视频卡片；`1` 表示视频卡片，`0` 表示非视频卡片，`__ALL__` 表示全量聚合（CUBE 产生的汇总行） |

### 指标：vitem（虚拟 SKU）曝光与点击

| 字段名 | 类型 | 说明 |
|---|---|---|
| `vitem_omni_scenario_imp_cnt` | bigint | vitem（虚拟 SKU）在该场景下的全渠道曝光次数；仅统计命中 vitem 列表的 item |
| `vitem_omni_scenario_click_cnt` | bigint | vitem 在该场景下的全渠道点击次数 |

### 指标：cspu 曝光与点击

| 字段名 | 类型 | 说明 |
|---|---|---|
| `cspu_omni_scenario_imp_cnt` | bigint | cspu（标准商品单元）在该场景下的全渠道曝光次数；仅统计命中 cspu-item 映射的 item |
| `cspu_omni_scenario_click_cnt` | bigint | cspu 在该场景下的全渠道点击次数 |

### 指标：场景及平台整体曝光

| 字段名 | 类型 | 说明 |
|---|---|---|
| `scene_omni_scenario_imp_cnt` | bigint | 该场景（scene）下全部商品的全渠道曝光总次数，作为场景级分母基准 |
| `platform_omni_scenario_imp_cnt` | bigint | 平台整体（不区分场景）的全渠道曝光总次数，来自 platform_level_imp 聚合 |

### 指标：订单量与 GMV

| 字段名 | 类型 | 说明 |
|---|---|---|
| `vitem_order_cnt` | double | vitem 贡献的订单量；跨场景归因合并（含 source1、source2 归因链路） |
| `cspu_order_cnt` | double | cspu 贡献的订单量 |
| `scene_order_cnt` | double | 该场景下全部商品的订单总量，作为场景级订单分母基准 |
| `platform_order_cnt` | double | 平台整体（不区分场景）的订单总量，来自 platform_level_order 聚合 |
| `vitem_gmv` | double | vitem 贡献的 GMV（成交金额） |

### 指标：vitem 覆盖率比率（预计算派生字段）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `vitem_cspu_order_ratio` | double | vitem 订单量占 cspu 订单量的比率，计算公式：`IF(cspu_order_cnt > 0, vitem_order_cnt / cspu_order_cnt, 0)`；反映 vitem 在 cspu 订单中的覆盖率 |
| `vitem_cspu_imp_ratio` | double | vitem 曝光量占 cspu 曝光量的比率，计算公式：`IF(cspu_omni_scenario_imp_cnt > 0, vitem_omni_scenario_imp_cnt / cspu_omni_scenario_imp_cnt, 0)` |
| `vitem_scene_order_ratio` | double | vitem 订单量占场景整体订单量的比率，计算公式：`IF(scene_order_cnt > 0, vitem_order_cnt / scene_order_cnt, 0)` |
| `vitem_scene_imp_ratio` | double | vitem 曝光量占场景整体曝光量的比率，计算公式：`IF(scene_omni_scenario_imp_cnt > 0, vitem_omni_scenario_imp_cnt / scene_omni_scenario_imp_cnt, 0)` |

---

## 查询使用须知

### 必须包含的过滤条件

- 查询时**必须同时指定** `grass_region` 和 `local_date` 两个分区字段，否则将触发全分区扫描，严重影响性能；
- 示例：`WHERE grass_region = 'MY' AND local_date = '2024-01-01'`；
- 若需跨日期聚合，建议明确列出日期范围（`local_date BETWEEN ... AND ...`）。

### 不可直接 SUM 的字段

以下字段为**预计算比率**，已在写入时按行计算，不具备可加性，**禁止跨行直接 SUM 后作为比率使用**：

| 字段名 | 原因 |
|---|---|
| `vitem_cspu_order_ratio` | 比率字段，需用分子/分母原始值重新计算 |
| `vitem_cspu_imp_ratio` | 比率字段，需用分子/分母原始值重新计算 |
| `vitem_scene_order_ratio` | 比率字段，需用分子/分母原始值重新计算 |
| `vitem_scene_imp_ratio` | 比率字段，需用分子/分母原始值重新计算 |

若需跨 scene、exp_group_id 等维度汇总后计算比率，应先 SUM 对应的分子/分母字段，再手动计算比率。

### CUBE 聚合行说明

- `is_ads` 和 `is_video_card` 字段值为 `__ALL__` 的行，是 ETL 中通过 `GROUP BY ... CUBE(is_ads, is_video_card)` 生成的多维汇总行；
- 查询时若只需细粒度明细，需过滤掉 `is_ads != '__ALL__' AND is_video_card != '__ALL__'`；
- 若直接对所有行 SUM，会导致**重复计算**，务必注意。

### 场景范围说明

- 下单归因覆盖三级归因链路（scene、source1_scene、source2_scene），同一订单在不同归因场景下会被计入不同 scene 行，**跨 scene SUM 订单量时存在重复计数风险**；
- `RCMD` 场景是 Daily Discover、You May Also Like、Post Purchase 的聚合归并场景，与三个细分场景存在重叠，跨行汇总时需避免双重统计；
- `platform_order_cnt` 和 `platform_omni_scenario_imp_cnt` 为平台整体指标，通过 LEFT JOIN 附加到每个 scene 行，同一 `exp_group_id + is_ads + is_video_card` 组合下各 scene 行的值相同，**跨 scene SUM 会产生重复**。

### 时效性说明

- 本表为日级（`_1d`）快照表，T+1 产出，反映前一自然日数据；
- 不含近 N 日滚动窗口字段，历史趋势分析需自行跨日期聚合。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取 A/B 实验用户分组信息（exp_group_id），按 Search / RCMD 白名单区分场景 |
| `srdi_mart.dim_sr_data_warehouse_vsku_model_mapping_hf` | vitem 与 cspu 的映射关系，用于判断曝光/点击/订单的 item 是否命中 vitem 列表 |
| `srdi_mart.dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` | cspu 与 item_id、model_id 的映射关系，用于判断 item 是否属于 cspu |
| `srdi_mart.dwm_sr_data_warehouse_tc_ab_all_cards` | 交易卡片 A/B 归因订单明细，包含多级归因场景（scene、source1_scene、source2_scene）和特征信息 |
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 平台用户-商品曝光点击行为明细，用于计算各场景及平台整体的曝光、点击指标 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group
        │ 用户实验分组（Search / RCMD 白名单）
        ▼
user_exp_mapping ──────────────────────────────────────────────┐
                                                               │ JOIN 过滤
dim_sr_data_warehouse_vsku_model_mapping_hf                    │
        │ vitem-cspu 映射                                       │
        ▼                                                      │
vitem_cspu_list ──┐                                            │
                  │                                            │
dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf             │
        │ cspu-item-model 映射                                  │
        ▼                                                      │
cspu_mapping → cspu_item_model_list                            │
                  │                                            │
dwm_sr_data_warehouse_tc_ab_all_cards                          │
        │ 订单归因（3级场景 × 3归因链路）                        │
        ▼                                                      │
order_raw → scene_order_union / rcmd_order_union               │
        → scene_level_order_step1 → scene_level_order ─────────┤
        → platform_level_order_step1 → platform_level_order ───┤
                                                               │
dwm_sr_data_warehouse_platform_user_item                       │
        │ 用户曝光点击明细                                       │
        ▼                                                      │
imp_base → rcmd_imp                                            │
        → scene_level_imp ─────────────────────────────────────┤
        → platform_level_imp ──────────────────────────────────┤
                                                               │
scene_level_imp + scene_level_order                            │
        → scene_level_imp_and_order ←──────────────────────────┘
                  │ LEFT JOIN platform_level_order
                  │ LEFT JOIN platform_level_imp
                  ▼
dws_sr_data_warehouse_tc_vsku_scene_exp_1d（INSERT OVERWRITE）
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| 1 | `user_exp_mapping` | 从实验用户分组表读取当日 Search / RCMD 白名单用户，赋予对应 scene 标签 |
| 2 | `vitem_cspu_list` | 读取 vitem-cspu 映射，后续用于判断 item 是否命中 vitem |
| 3 | `cspu_mapping` | 读取 cspu-item-model 映射 |
| 4 | `cspu_item_model_list` | 关联上两张映射表，得到 item_id / model_id 维度的 cspu 覆盖集合 |
| 5 | `order_raw` | 从订单归因明细表读取当日 item 卡片订单，拆解出 scene、source1_scene、source2_scene，并标记视频卡片 |
| 6 | `scene_order_union` | 对订单进行三级归因 UNION，确保同一订单按其每个归因场景分别计入（Scene 细粒度） |
| 7 | `rcmd_order_step1` / `rcmd_order_union` | 同上，将 Daily Discover / YMYL / Post Purchase 三级场景归并为 RCMD 后进行 UNION |
| 8 | `scene_level_order_step1` | 合并 scene_order_union 与 rcmd_order_union，关联 vitem/cspu 标记，按用户级聚合订单量和 GMV |
| 9 | `scene_level_order` | 关联实验用户分组，按 scene × exp_group_id × CUBE(is_ads, is_video_card) 聚合 vitem/cspu/场景订单量 |
| 10 | `platform_level_order_step1` / `platform_level_order` | 计算平台整体订单量，不区分 scene，按 exp_group_id × CUBE(is_ads) 聚合 |
| 11 | `imp_base` | 从平台用户-商品曝光表读取 omni_impression / omni_click 记录，匹配场景标签，标记 vitem/cspu/视频卡片 |
| 12 | `rcmd_imp` | 将 imp_base 中 RCMD 子场景（Daily Discover / YMYL / Post Purchase）归并为 RCMD 场景 |
| 13 | `scene_level_imp` | 合并 imp_base 与 rcmd_imp，关联实验用户分组，按 scene × exp_group_id × CUBE(is_ads, is_video_card) 聚合曝光点击指标 |
| 14 | `platform_level_imp` | 计算平台整体曝光量，按 exp_group_id × CUBE(is_ads, is_video_card) 聚合 |
| 15 | `scene_level_imp_and_order` | 通过 UNION ALL + GROUP BY 将 scene_level_imp 与 scene_level_order 合并为统一的场景级指标集 |
| 16 | **INSERT OVERWRITE** | 以 scene_level_imp_and_order 为主表，LEFT JOIN platform_level_order 和 platform_level_imp，计算 4 个比率字段，写入目标分区 |

### 注意事项

1. **CUBE 产生多维汇总行**：`GROUP BY ... CUBE(is_ads, is_video_card)` 会生成 4 种维度组合（明细 + 各维度小计 + 总计），`is_ads` 或 `is_video_card` 为 `NULL` 时用 `COALESCE(..., '__ALL__')` 替换为 `__ALL__`，查询时需注意过滤逻辑；
2. **RCMD 场景与细分场景重叠**：`rcmd_order_union` / `rcmd_imp` 将三个细分场景聚合为 `RCMD`，与 `scene_order_union` / `imp_base` 中的细分行同时存在于最终表中，跨 scene 聚合时需避免双重计数；
3. **三级归因链路 UNION 去重**：`scene_order_union` 中 source1_scene 和 source2_scene 分别过滤掉与主 scene 重复的记录，但跨行 SUM 订单量仍可能存在同一订单被多个归因场景各计一次的情况；
4. **单 Writer 单分区写入**：本表为单 ETL 文件写入，无 multi-writer 风险，每次按 `(grass_region, local_date)` 分区全量覆盖；
5. **参数化站点执行**：SQL 中使用 `${grass_region}`、`${local_date}`、`${grass_region_without_quote}` 等参数，需由调度框架按站点逐一传入执行。

---

*文档生成时间：2026-05-17*