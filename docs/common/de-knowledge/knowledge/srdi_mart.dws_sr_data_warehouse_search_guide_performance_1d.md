<!-- ads-workspace-gdoc-sync: gdoc_id=1R1r7qO1TEW4JY0kDAhCcmaJoFcYJFrNpqtd0nDV8bIQ gdoc_url=https://docs.google.com/document/d/1R1r7qO1TEW4JY0kDAhCcmaJoFcYJFrNpqtd0nDV8bIQ/edit -->

# srdi_mart.dws_sr_data_warehouse_search_guide_performance_1d

**分层：** dws_search
**主键：** platform, search_entrance, page_type, feature, grass_region, local_date
**分区：** grass_region, local_date
**更新频率：** 每日（T+1）
**引用频次 / 访问频次：** 1128

---

## 业务描述

本表是搜索引导（Search Guide）功能的每日综合性能汇总表，面向 SRDI 搜推数仓 DWS 层。  
表按照 **地区、日期、平台、搜索入口、页面类型、功能特征（feature）** 四个维度进行 GROUPING SETS 聚合，覆盖展示、点击、页面访问、下单及全链路归因下单等核心行为指标。

**核心业务场景：**
- 分析搜索引导模块（搜索建议页、预搜索页、创作者搜索页、全局搜索入口等）的曝光、点击和转化漏斗表现。
- 评估不同搜索入口（如首页搜索栏、PDP 搜索栏、YMAL 卡片等）带来的 GMV 及订单贡献，包含 Omni 归因口径（`global_search_*`）。
- 监控关键词品类多样性（L3 类目数量）以衡量搜索引导的覆盖广度。
- 结合内容场景（视频/直播）DAU 计算搜索引导在内容生态中的渗透率。

**适合回答的问题：**
- 某功能特征（feature）在指定地区/平台/入口的每日曝光量、点击率、转化率是多少？
- 搜索引导各入口带来的 GMV 与 Omni 归因 GMV 差异如何？
- 搜索建议词或热搜词的 L3 类目多样性（人均覆盖品类数）趋势如何？
- 视频搜索和直播搜索的内容场景 DAU 是多少？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/地区，如 `SG`、`MY`、`TH` 等 |
| `local_date` | date | 本地日期，数据统计日期（T 日） |

### 维度：搜索功能标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 终端平台，如 `ios_app`、`android_app`；汇总行为 `__ALL__` |
| `search_entrance` | string | 搜索入口，如 `homepage_search_bar`、`pdp_search_bar`；汇总行为 `__ALL__` |
| `page_type` | string | 页面类型，如 `global_search`、`pre_search`、`search_suggest_page` 等；内容场景汇总行为 `__ALL__`、Omni 归因口径固定为 `search` |
| `feature` | string | 搜索引导功能特征标签，由 feature mapping 维表展开，如 `srp-sdp-search_prefill`、`srp-home-search_bar` 等 |

### 指标：展示行为

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 搜索引导模块的曝光次数（impression 操作的 operation_cnt 之和） |
| `imp_uu` | bigint | 曝光去重用户数（按 user_id 去重） |
| `imp_feature_cnt` | bigint | 曝光的内容单元（civ_id）去重数，即功能特征曝光的物料数 |

### 指标：点击行为

| 字段 | 类型 | 说明 |
|---|---|---|
| `click_cnt` | bigint | 点击次数（click 操作的 operation_cnt 之和） |
| `click_uu` | bigint | 点击去重用户数（按 user_id 去重） |

### 指标：页面访问行为

| 字段 | 类型 | 说明 |
|---|---|---|
| `page_view_cnt` | bigint | 页面访问次数（view 操作的 operation_cnt 之和） |
| `page_view_uu` | bigint | 页面访问去重用户数（按 user_id 去重） |
| `search_volume` | bigint | 搜索词级别的去重搜索量（按 user_id + device_id + keyword 三元组去重）；仅对 feature 前缀为 `sdp`、`sup`、`srp` 的行填充，其余为 NULL |

### 指标：下单转化（直接归因）

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 下单数（order 操作的 operation_cnt 之和，来自搜索行为日志直接归因） |
| `order_uu` | bigint | 下单去重用户数（按 user_id 去重，且 operation_cnt > 0） |
| `gmv` | double | 下单 GMV（place_order_gmv 之和，直接归因口径，单位与上游一致） |
| `pc2_gmv` | double | PC2 口径 GMV（pc2_gmv 之和，直接归因口径） |

### 指标：全链路归因下单（Omni 归因）

| 字段 | 类型 | 说明 |
|---|---|---|
| `global_search_order_cnt` | double | Omni 归因下单数（基于 ATC 旅程归因，含 first_touchpoint 加权，可为小数） |
| `global_search_order_uu` | bigint | Omni 归因下单去重用户数 |
| `global_search_gmv` | double | Omni 归因 GMV（gmv_usd × atc_prorate × first_touchpoint_item 之和） |
| `global_search_pc2` | double | Omni 归因 PC2 GMV（pc2_usd × atc_prorate × first_touchpoint_item 之和） |

### 指标：内容场景活跃用户

| 字段 | 类型 | 说明 |
|---|---|---|
| `content_scenario_dau` | bigint | 内容场景 DAU；仅在 platform = `__ALL__`、search_entrance = `__ALL__` 时与对应 feature（`video_search`、`all_livesearch`、`all_content_search`）关联填充 |

### 指标：关键词品类多样性（人均 L3 类目数）

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_l3_cat_per_uu` | double | 曝光用户人均覆盖 L3 关键词品类数（`SUM(imp_l3_cnt) / COUNT(有曝光用户)`，为比率，不可直接 SUM） |
| `clk_l3_cat_per_uu` | double | 点击用户人均覆盖 L3 关键词品类数（`SUM(clk_l3_cnt) / COUNT(有点击用户)`，为比率，不可直接 SUM） |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须指定 `grass_region` 和 `local_date` 分区过滤**，否则会触发全表扫描，消耗大量资源。示例：

  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-01'
  ```

- 若需要汇总所有平台或入口，应筛选 `platform = '__ALL__'` 或 `search_entrance = '__ALL__'`，避免重复计算（表已通过 GROUPING SETS 预聚合了各维度组合）。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_l3_cat_per_uu` | 比率指标（人均 L3 品类数），跨行 SUM 无业务意义，需重新以分子/分母汇总后计算 |
| `clk_l3_cat_per_uu` | 同上 |
| `global_search_order_cnt` | 含 atc_prorate × first_touchpoint 加权，为小数，跨 feature 维度累加存在重复归因风险 |
| `global_search_gmv` | 同 `global_search_order_cnt`，跨 feature 累加存在重复归因 |
| `global_search_pc2` | 同上 |
| `imp_uu` / `click_uu` / `order_uu` / `page_view_uu` / `global_search_order_uu` | 去重用户数，跨 feature 或跨维度组合不可直接相加，需回溯明细层去重 |
| `imp_feature_cnt` | 物料（civ_id）去重计数，跨维度不可累加 |
| `search_volume` | 基于三元组去重的搜索量，跨维度不可累加 |
| `content_scenario_dau` | 去重 DAU，仅在特定维度组合下有值，跨行累加无意义 |

### 时效性说明

- 本表为 **每日（1d）** 快照表，统计 T 日本地时区数据，通常在 T+1 产出。
- 无滚动窗口（非 `_nd` / `_td`），如需多日趋势，需在外层按 `local_date` 聚合。
- `global_search_*` 指标依赖 `traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live`，该表为准实时流水，历史回刷可能导致数值轻微变动。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_search` | 搜索行为明细（impression / click / view / order），提供曝光、点击、浏览、订单基础事件 |
| `srdi_mart.dim_sr_data_warehouse_search_feature_tags_mapping_v2` | 搜索引导 feature 标签映射维表，定义各页面/操作/条件组合对应的 feature tag |
| `traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live` | Omni 全链路归因订单明细，提供搜索引导的 Omni GMV / 订单归因数据 |
| `video.video_mart_ads_user_active_wide_ntl_1d` | 视频活跃用户宽表，用于计算视频搜索场景 DAU |
| `livestream.ls_mart_dwd_viewer_view_detail_di` | 直播观看明细，用于计算直播搜索场景 DAU |
| `srdi_mart.dws_sr_data_warehouse_search_guide_user_benchmark_1d` | 搜索引导用户基准表（含关键词级别曝光/点击），用于计算 L3 品类多样性指标 |
| `srdi_mart.dim_sr_data_warehouse_keyword_di` | 关键词 L3 品类映射维表，用于关联关键词对应的三级品类 ID |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_search  ──┐
                                ├──> dwd_search_page
dim_search_feature_mapping     ──┤
                                └──> dwd_search_with_feature ──> dws_imp_click (曝光/点击/直接归因订单)
                                                              └──> dwm_view ──> dws_view (页面访问/搜索量)

dwd_order_item_atc_journey_di  ──> omni_search_order
                                ──> omni_search_order_with_feature ──> dws_omni_search (Omni 归因)

video_mart_ads_user_active     ──> dws_video_user ──┐
ls_mart_dwd_viewer_view_detail ──> dws_live_user  ──┴──> dws_content_user (内容 DAU)

dws_search_guide_user_benchmark ──> search_guide ──┐
dim_sr_data_warehouse_keyword   ──> dim_keyword_l3 ──┴──> search_guide_with_l3 ──> dws_keyword_l3 (L3 比率)

dws_imp_click + dws_view + dws_omni_search + dws_content_user + dws_keyword_l3
  ──> INSERT OVERWRITE dws_sr_data_warehouse_search_guide_performance_1d
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| 1 | `dim_search_feature_mapping` | 从 feature mapping 维表读取搜索引导 feature 标签规则，解析 include/exclude 条件列表 |
| 2 | `dwd_search_page` | 从搜索行为明细表读取 T 日数据，UNION 三段（主路径 + source1 + source2 归因路径），过滤合法页面类型和操作类型 |
| 3 | `dwd_search_with_feature` | 将搜索行为与 feature mapping 规则 INNER JOIN，按多条件匹配打上 feature_tag，并按用户/设备/关键词聚合 |
| 4 | `dws_imp_click` | 对 feature_tag 做 EXPLODE 展开，按 GROUPING SETS（page_type×feature、platform×…、search_entrance×…、全组合）聚合曝光、点击、直接归因订单指标 |
| 5 | `dwm_view` | 从 `dwd_search_with_feature` 过滤 view 操作，按用户/设备/关键词维度预聚合 |
| 6 | `dws_view` | 对 view 数据按相同 GROUPING SETS 聚合 page_view_cnt、page_view_uu、search_volume（三元组去重） |
| 7 | `omni_search_order` | 从 Omni 归因订单表读取 T 日数据，UNION 主路径 + source1 + source2，计算 atc_prorate × first_touchpoint 加权订单/GMV |
| 8 | `omni_search_order_with_feature` | 对 Omni 订单按 search_mid、target_type、search_entrance 三组 CASE WHEN 规则打 feature_tag，UNION ALL 三段 |
| 9 | `dws_omni_search` | 对 Omni feature_tag EXPLODE 后按相同 GROUPING SETS 聚合 Omni 归因指标 |
| 10 | `dws_video_user` / `dws_live_user` | 分别从视频活跃用户表和直播观看表获取 T 日活跃用户 |
| 11 | `dws_content_user` | UNION 视频/直播用户，计算三类内容场景 DAU（video_search、all_livesearch、all_content_search） |
| 12 | `dim_keyword_l3` | 从关键词品类映射维表获取 T 日关键词对应的 L3 品类 ID（取 MAX 去重） |
| 13 | `search_guide` | 从 `dws_search_guide_user_benchmark_1d` 展开 feature_tag，过滤有曝光/点击的关键词记录 |
| 14 | `search_guide_with_l3` | JOIN 关键词 L3 维表，按 GROUPING SETS 计算每用户的 imp_l3_cnt 和 clk_l3_cnt |
| 15 | `dws_keyword_l3` | 在用户层汇总后计算 `imp_l3_cat_per_uu`（SUM/COUNT）和 `clk_l3_cat_per_uu` |
| 16 | **INSERT OVERWRITE** | 以 `dws_imp_click` 为主表，依次 LEFT JOIN `dws_content_user`、`dws_keyword_l3`，FULL OUTER JOIN `dws_view` 和 `dws_omni_search`，写入目标分区 |

### 注意事项

1. **GROUPING SETS 维度重叠**：表中同一 feature 在不同 platform / search_entrance 维度组合下均有行，查询时需明确指定维度组合，避免重复计算（建议始终显式过滤 platform 和 search_entrance，或仅使用 `__ALL__` 汇总行）。
2. **search_volume 条件填充**：`search_volume` 字段仅对 feature 前缀属于 `sdp`、`sup`、`srp` 的行填充，其他 feature 行该字段为 NULL，不代表无搜索量。
3. **Omni 归因 feature 规则独立维护**：`omni_search_order_with_feature` 中 feature_tag 通过硬编码 CASE WHEN 逻辑打标，与 DWD 侧 feature mapping 维表规则相互独立，两套口径的 feature 覆盖范围可能存在差异，跨口径对比需注意。
4. **content_scenario_dau 稀疏性**：该字段仅在 `platform = '__ALL__'` 且 `search_entrance = '__ALL__'` 且 feature 为 `video_search` / `all_livesearch` / `all_content_search` 的行中有值，其余行均为 NULL。
5. **单 writer 单分区写入**：本表仅有一个 ETL 文件，无 multi-writer 风险；每次执行按 `grass_region` + `local_date` 分区 INSERT OVERWRITE，不影响其他分区历史数据。
6. **Omni 表数据敏感性**：`traffic_omni_oa.dwd_order_item_atc_journey_di__reg_sensitive_live` 含敏感标记（live），历史分区数据可能随归因模型更新而变动，回刷时 `global_search_*` 指标存在轻微波动风险。

---

*文档生成时间：2026-05-17*