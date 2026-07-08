<!-- ads-workspace-gdoc-sync: gdoc_id=1mt-eJdHAM5067frSrMgTqZgnMo3HKM-qhf2UPm9lxbI gdoc_url=https://docs.google.com/document/d/1mt-eJdHAM5067frSrMgTqZgnMo3HKM-qhf2UPm9lxbI/edit -->

# srdi_mart.ads_sr_data_warehouse_tc_ni_rcmd_exp_1d

**分层：** ADS（应用数据层）
**主键：** `grass_region` + `local_date` + `exp_group_id` + `mapping_general` + `target_type` + `is_ads` + `is_vsku`
**分区：** `grass_region`（站点区域）, `local_date`（业务日期）
**更新频率：** 每日全量覆盖（`INSERT OVERWRITE PARTITION`）
**引用频次/访问频次：** 1029

---

## 业务描述

本表为搜推数仓（SR Data Warehouse）推荐场景下**新品（New Item）曝光实验分析**的 ADS 层日粒度汇总宽表，面向 A/B 实验效果评估。

**核心业务场景：**
- 针对推荐业务（Rcmd）中的三个核心场景——**You May Also Like（猜你喜欢）**、**Post Purchase（购后推荐）**、**Daily Discover（每日发现首页）**，按 A/B 实验组（`exp_group_id`）维度汇总用户行为漏斗指标；
- 同时区分**全量商品**、**30 天新品**（`new_item_30d_*`）和 **90 天新品**（`new_item_90d_*`）三个商品新鲜度口径，支持评估推荐系统对新品扶持的效果；
- 支持按广告属性（`is_ads`）、虚拟 SKU 属性（`is_vsku`）、流量来源类型（`target_type`）进行下钻分析；
- 仅统计白名单内有效分流用户（`is_rcmd_whitelist = 1`）的行为数据，保证实验纯净度。

**适合回答的问题：**
- 某实验组与对照组在推荐场景下的曝光、点击、加购、下单、GMV 表现差异如何？
- 推荐场景中 30 天/90 天新品的流量分配和转化效果如何？
- 广告商品（`is_ads`）和虚拟 SKU（`is_vsku`）在各实验组的漏斗指标有何差异？
- 各推荐场景（You May Also Like / Post Purchase / Daily Discover）的实验组效果对比。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域标识，如 `ID`、`MY`、`PH` 等，查询时必须指定 |
| `local_date` | date | 业务日期（本地时区），每日一个分区，查询时必须指定 |

### 维度：实验与场景维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | bigint | A/B 实验组 ID，来源于 `dim_sr_data_warehouse_abtest_user_group`，仅含有效分流且在推荐白名单内的用户组 |
| `mapping_general` | string | 推荐场景可读名称，由 `scenario_tag` 映射而来：`'You May Also Like'`、`'Post Purchase'`、`'Daily Discover'`；汇总时可为 `NULL`（原始 tag 无法命中映射） |
| `target_type` | string | 流量来源子类型，取自 `feature_detail` 末段（`SPLIT(feature_detail, '-')` 最后一个元素），无法解析时为 `'others'`；汇总维 `GROUPING SETS` 下可为 `'__ALL__'`（全维汇总） |
| `is_ads` | string | 是否广告商品，`'true'` / `'false'`，GROUPING SETS 全汇总时为 `'__ALL__'` |
| `is_vsku` | string | 是否虚拟 SKU（vsku），`'1'`（是）/ `'0'`（否），来源于 `dim_sr_data_warehouse_vsku_vitem`，GROUPING SETS 全汇总时为 `'__ALL__'` |

### 指标：全量场景行为漏斗指标（scene）

| 字段 | 类型 | 说明 |
|---|---|---|
| `scene_imp_cnt` | bigint | 场景曝光 PV 总量（所有用户，含重复） |
| `scene_imp_uu` | bigint | 场景曝光 UV（有曝光行为的用户数，`user_id > 0` 计为 1） |
| `scene_click_cnt` | bigint | 场景点击 PV 总量 |
| `scene_click_uu` | bigint | 场景点击 UV |
| `scene_ppv_cnt` | double | 场景商品详情页浏览（PPV）PV 总量 |
| `scene_ppv_uu` | bigint | 场景 PPV UV |
| `scene_cart_cnt` | double | 场景加购 PV 总量 |
| `scene_cart_uu` | bigint | 场景加购 UV |
| `scene_order_cnt` | double | 场景下单量 |
| `scene_order_uu` | bigint | 场景下单 UV |
| `scene_gmv` | double | 场景 GMV（全口径成交金额） |
| `scene_pc2_gmv` | double | 场景 PC2 GMV（特定归因口径成交金额） |

### 指标：30 天新品行为漏斗指标（new_item_30d）

> 商品创建时间距统计日期 ≤ 30 天（即 `item_tag = '0d_30d'`）的商品子集对应指标。

| 字段 | 类型 | 说明 |
|---|---|---|
| `new_item_30d_imp_cnt` | bigint | 30 天新品曝光 PV |
| `new_item_30d_imp_uu` | bigint | 30 天新品曝光 UV |
| `new_item_30d_click_cnt` | bigint | 30 天新品点击 PV |
| `new_item_30d_click_uu` | bigint | 30 天新品点击 UV |
| `new_item_30d_ppv_cnt` | double | 30 天新品 PPV PV |
| `new_item_30d_ppv_uu` | bigint | 30 天新品 PPV UV |
| `new_item_30d_cart_cnt` | double | 30 天新品加购 PV |
| `new_item_30d_cart_uu` | bigint | 30 天新品加购 UV |
| `new_item_30d_order_cnt` | double | 30 天新品下单量 |
| `new_item_30d_order_uu` | bigint | 30 天新品下单 UV |
| `new_item_30d_gmv` | double | 30 天新品 GMV |
| `new_item_30d_pc2_gmv` | double | 30 天新品 PC2 GMV |

### 指标：90 天新品行为漏斗指标（new_item_90d）

> 商品创建时间距统计日期 ≤ 90 天（即 `item_tag` 不为 NULL，含 `'0d_30d'` 和 `'30d_90d'`）的商品子集对应指标。

| 字段 | 类型 | 说明 |
|---|---|---|
| `new_item_90d_imp_cnt` | bigint | 90 天新品曝光 PV |
| `new_item_90d_imp_uu` | bigint | 90 天新品曝光 UV |
| `new_item_90d_click_cnt` | bigint | 90 天新品点击 PV |
| `new_item_90d_click_uu` | bigint | 90 天新品点击 UV |
| `new_item_90d_ppv_cnt` | double | 90 天新品 PPV PV |
| `new_item_90d_ppv_uu` | bigint | 90 天新品 PPV UV |
| `new_item_90d_cart_cnt` | double | 90 天新品加购 PV |
| `new_item_90d_cart_uu` | bigint | 90 天新品加购 UV |
| `new_item_90d_order_cnt` | double | 90 天新品下单量 |
| `new_item_90d_order_uu` | bigint | 90 天新品下单 UV |
| `new_item_90d_gmv` | double | 90 天新品 GMV |
| `new_item_90d_pc2_gmv` | double | 90 天新品 PC2 GMV |

---

## 查询使用须知

### 必须指定的过滤条件

- **`grass_region`** 和 **`local_date`** 为分区字段，**每次查询必须同时指定**，否则触发全表扫描，产生大量不必要的计算成本。
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-01-01'
  ```
- 查询特定实验效果时，应额外过滤 `exp_group_id`，避免将多个实验组混合聚合导致结果失真。

### 维度组合与 GROUPING SETS 说明

- 本表通过 `GROUPING SETS` 预聚合了多种维度组合，`is_ads`、`is_vsku`、`target_type` 字段值为 `'__ALL__'` 时表示该维度已被折叠（全汇总口径）。
- **直接对全表 GROUP BY 时需注意去重**，避免不同 GROUPING SETS 组合的数据被重复累加。建议按需筛选特定维度组合，例如：
  ```sql
  WHERE is_ads = '__ALL__' AND is_vsku = '__ALL__' AND target_type = '__ALL__'
  ```
  以获取不区分广告/vsku/target_type 的汇总行。

### 不可直接 SUM 的字段

- **`*_uu` 系列字段**（如 `scene_imp_uu`、`new_item_30d_click_uu` 等）：这些字段是在用户粒度上预聚合的去重 UV，**跨 `exp_group_id` 或跨 `mapping_general` 直接 SUM 会导致重复计数**，如需合并实验组请回溯明细层。
- **`scene_gmv`、`new_item_30d_gmv`、`new_item_90d_gmv`** 等金额指标：在 GROUPING SETS 多行并存场景下，跨维度组合直接 SUM 会导致重复计算，需确认所查询行不存在交叉覆盖。
- **比率类指标**（如 CTR、CVR）：本表未存储比率字段，需自行用 `cnt / imp_cnt` 计算，**不得对 `_cnt` 指标做跨实验组 SUM 后再计算比率**。

### 时效性说明

- 本表为 **`_1d` 日粒度**表，每日 T+1 产出，反映 `local_date` 对应自然日的行为数据。
- `new_item_30d_*` 和 `new_item_90d_*` 的新品判断以 **`local_date` 当天为基准**，跨日对比时新品范围会随日期滚动变化，**不可直接跨天 SUM 累加**作为区间新品指标使用。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_platform_user_item` | 用户-商品粒度行为明细，提供曝光、点击、PPV、加购、下单、GMV 等事件数据，以及场景标签（`scenario_tags`）、`feature_detail`、实验组（`exp_group_ids`）等字段 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | A/B 实验用户分组维度表，用于过滤有效分流用户（`is_assignment_log = 1`）且属于推荐白名单（`is_rcmd_whitelist = 1`）的用户-实验组映射 |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维度表，提供 `item_create_datetime` 用于判断商品新鲜度（30 天 / 90 天新品标签） |
| `srdi_mart.dim_sr_data_warehouse_vsku_vitem` | 虚拟 SKU（vsku）与虚拟商品（vitem）映射维度表，用于判断商品是否为 vsku |

---

## ETL 逻辑摘要

### 数据流

```
dwm_sr_data_warehouse_platform_user_item
        │  过滤目标场景 scenario_tags & operation
        ▼
  user_item_raw（含 source1/source2 归因路径 union）
        │
        ▼
  user_item_union（三路 UNION ALL：直接路径 + source1 归因 + source2 归因）
        │
        ├── join dim_sr_data_warehouse_abtest_user_group（白名单用户过滤）
        ▼
  base_exp（用户-实验组-商品粒度行为数据，提取 target_type）
        │
        ├── left join dim_sr_data_warehouse_item（新品标签）
        ├── left join dim_sr_data_warehouse_vsku_vitem（vsku 标签）
        ▼
  base_exp_explode（LATERAL VIEW EXPLODE scenario_tags，GROUPING SETS 多维预聚合）
        │
        ▼
  base_aggr（scenario_tag → mapping_general 映射，UV 计算，最终聚合）
        │
        ▼
INSERT OVERWRITE ads_sr_data_warehouse_tc_ni_rcmd_exp_1d PARTITION(grass_region, local_date)
```

### 关键步骤

| 步骤 | Temporary View | 核心逻辑 |
|---|---|---|
| Step 1 | `user_item_raw` | 从 DWM 行为明细表过滤目标场景（3 个 scenario_tag）和目标操作（impression/click/ppv/cart/order），对 traffic_vsku_item_id 做 coalesce 回退至 item_id |
| Step 2 | `user_item_union` | 三路 UNION ALL：①直接路径（有 scenario_tags 且 size≥1）；②source1 归因路径（feature_detail 不同，operation 仅 ppv/cart/order）；③source2 归因路径（排除 source1 重复，operation 仅 ppv/cart/order）；imp/click 仅计直接路径 |
| Step 3 | `exp_filter` | 从 ABTest 用户分组维度表抽取当天有效白名单用户的 user_id→exp_group_id 映射 |
| Step 4 | `base_exp` | user_item_union INNER JOIN exp_filter，限定为白名单用户；提取 `target_type`（feature_detail 末段） |
| Step 5 | `item_tag` | 从商品维度表计算新品标签：创建日距统计日 ≤30 天标记 `'0d_30d'`，≤90 天标记 `'30d_90d'`，超过 90 天不纳入 |
| Step 6 | `vitem` | 从 vsku-vitem 维度表获取所有 vitem_id 集合，用于判断商品是否为虚拟 SKU |
| Step 7 | `base_exp_explode` | base_exp LEFT JOIN item_tag、vitem；LATERAL VIEW EXPLODE scenario_tags 展开场景标签；按 8 种 GROUPING SETS 组合（含 is_vsku 维度）做多维预聚合，`__ALL__` 代替汇总维度 |
| Step 8 | `base_aggr` | 将 scenario_tag 原始字符串映射为 `mapping_general` 可读名称；对用户粒度数据做 SUM 聚合计算总量（`*_cnt`），并通过 `if(xxx_cnt > 0 and user_id > 0, 1, 0)` 计算 UV（`*_uu`） |
| Step 9 | 目标表写入 | `INSERT OVERWRITE PARTITION(grass_region, local_date)` 将 base_aggr 写入目标表 |

### 注意事项

- **单 Writer，无 multi-writer 风险**：本表仅由单个 ETL SQL 文件写入，无并发写入冲突风险。
- **GROUPING SETS 多行**：同一 `exp_group_id` + `mapping_general` 组合会因维度展开存在多行，下游使用时必须明确指定所需的维度组合，避免重复累加。
- **归因路径三路合并**：source1/source2 归因路径仅贡献 ppv/cart/order/gmv/pc2_gmv，不计入 imp_cnt 和 click_cnt（固定填 0），与直接路径在 user_item_union 中通过 UNION ALL 合并，需理解此归因逻辑避免对 imp/click 指标产生误解。
- **新品口径滚动性**：`item_tag` 基于 `local_date` 动态计算，历史分区中的新品范围不同，跨日期聚合新品指标无意义。
- **白名单用户过滤**：`exp_filter` 使用 INNER JOIN，仅保留 `is_assignment_log = 1 AND is_rcmd_whitelist = 1` 的用户，非白名单用户的行为数据不计入本表，与全量流量统计口径存在差异。

---

*文档生成时间：2026-05-17*