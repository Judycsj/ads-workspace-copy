<!-- ads-workspace-gdoc-sync: gdoc_id=1Aiy0Xloy-ud3OIkrL7h19t1FVS0HwFL-qg8q8CXlVZI gdoc_url=https://docs.google.com/document/d/1Aiy0Xloy-ud3OIkrL7h19t1FVS0HwFL-qg8q8CXlVZI/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_state_level_metrics_1d

**分层：** dws_search  
**主键：** `grass_region` + `local_date` + `exp_group_id` + `state`  
**分区：** `grass_region`（大区）, `local_date`（业务日期）  
**更新频率：** 每日（T+1）  
**引用频次/访问频次：** 168

---

## 业务描述

本表为搜索域 A/B 实验**州/省级别**日粒度汇总宽表，面向搜索推荐实验效果分析场景。

表按 **大区（grass_region）× 日期（local_date）× 实验分组（exp_group_id）× 地理州/省（state）** 四个维度组合，聚合搜索流量、转化、GMV、广告及 EDT（预计送达时间）等核心指标，同时支持 **`__ALL__`** 汇总行（state = `__ALL__`），以实现全量与分州对比分析。

当前仅为 **BR（巴西）** 和 **VN（越南）** 构建了 state 维度映射，其他区域 state 字段默认为 `NULL`。

**核心业务场景：**
- 搜索 A/B 实验效果评估：对比不同实验分组的搜索搜索用户数、曝光、点击、下单及 GMV 表现；
- 州/省级别差异分析：分析巴西圣保罗/里约热内卢、越南各大区的实验效果是否存在地域差异；
- 广告健康度监控：基于实验分组评估广告加载率、广告 ROI（宽口径/窄口径）及广告收入；
- GMV 异常值过滤分析：通过 99.5 分位截断对 GMV 进行去极值处理，减少异常订单对实验结论的干扰。

**适合回答的问题举例：**
- 某实验分组在越南南部大区的搜索 GMV 是否显著高于对照组？
- 巴西圣保罗州各实验组的广告 ROI 差异如何？
- 去极值后（995 分位截断），实验组与对照组的人均 GMV 差异是否收窄？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `BR`、`VN`；分区字段，查询时必须指定 |
| `local_date` | date | 业务本地日期（T 日）；分区字段，查询时必须指定 |

### 维度：实验元数据

| 字段 | 类型 | 说明 |
|---|---|---|
| `scene_id` | bigint | 实验场景 ID，来自 `dim_sr_data_warehouse_abtest_group` |
| `scene_name` | string | 实验场景名称 |
| `layer_id` | bigint | 实验层 ID |
| `layer_name` | string | 实验层名称 |
| `experiment_id` | bigint | 实验 ID |
| `experiment_name` | string | 实验名称 |
| `exp_group_id` | bigint | 实验分组 ID（主键组成部分），仅包含搜索白名单（`is_search_whitelist = 1`）的分组 |
| `exp_group_name` | string | 实验分组名称（如对照组、实验组） |

### 维度：地理维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `state` | string | 用户所在州/省。BR：`Sao Paulo`、`Rio de Janeiro`、`others`；VN：按主要大区映射；汇总行为 `__ALL__`；无映射时为 `NULL`（以 `'NULL'` 字符串存储） |

### 指标：搜索流量与转化

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_uu` | bigint | 实验分组内发生搜索浏览行为（operation=view）的去重用户数（UU）；**不可直接 SUM 跨分组** |
| `imp_cnt` | bigint | 搜索结果页商品/视频/直播曝光次数之和 |
| `click_cnt` | bigint | 搜索结果页商品/视频/直播点击次数之和 |
| `order_cnt` | double | 搜索归因下单数（含 source1/source2 多路径归因） |
| `gmv` | double | 搜索归因 GMV（美元），未经异常值过滤的原始值 |

### 指标：GMV 99.5 分位截断（全量用户 ABS 口径）

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv_995` | double | 过滤掉人均 ABS（平均订单 GMV）超过 99.5 分位阈值的用户后，剩余用户的搜索 GMV 之和（美元） |
| `gmv_uu_995` | double | `gmv_995` 除以去重有效曝光用户数（ABS ≤ 阈值 且 imp_cnt>0 的 distinct 用户数）；**为比率，不可直接 SUM** |
| `pc2_gmv_995` | double | 过滤超 99.5 分位 ABS 用户后的 PC2（二类结算）GMV 之和（美元） |
| `pc2_gmv_uu_995` | double | `pc2_gmv_995` 除以去重有效曝光用户数；**为比率，不可直接 SUM** |

### 指标：GMV 99.5 分位截断 V2（订单维度品类分层口径）

| 字段 | 类型 | 说明 |
|---|---|---|
| `high_gmv_995_v2` | double | 高 GMV 品类下，对单笔订单 GMV 做 99.5 分位截断后的 GMV 汇总（美元） |
| `high_gmv_order_cnt_995_v2` | double | 高 GMV 品类下，GMV 未超过截断阈值的订单数 |
| `high_pc2_gmv_995_v2` | double | 高 GMV 品类下，PC2 GMV 经 99.5 分位截断后的汇总（美元） |
| `low_gmv_995_v2` | double | 低 GMV 品类下，对单笔订单 GMV 做 99.5 分位截断后的 GMV 汇总（美元） |
| `low_gmv_order_cnt_995_v2` | double | 低 GMV 品类下，GMV 未超过截断阈值的订单数 |
| `low_pc2_gmv_995_v2` | double | 低 GMV 品类下，PC2 GMV 经 99.5 分位截断后的汇总（美元） |

### 指标：广告

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_rev` | double | 广告收入（美元），基于搜索场景广告主消耗金额汇总 |
| `ads_load` | double | 广告加载率 = 广告曝光数 / 自然搜索总曝光数；**为比率，不可直接 SUM** |
| `ads_narrow_roi` | double | 广告窄口径 ROI = 广告归因订单 GMV（美元）/ 广告收入；**为比率，不可直接 SUM** |
| `ads_broad_roi` | double | 广告宽口径 ROI = 广告归因大盘 GMV（本地币折算美元）/ 广告收入；**为比率，不可直接 SUM** |

### 指标：物流

| 字段 | 类型 | 说明 |
|---|---|---|
| `avg_edt` | double | 平均预计送达天数（EDT）= 搜索归因订单 edtmax 之和 / 有 EDT 信息的订单数；**为均值，不可直接 SUM** |

---

## 查询使用须知

### 必须包含的过滤条件

- 查询时**必须同时指定** `grass_region` 和 `local_date` 两个分区字段，否则将触发全表扫描，影响性能并可能产生跨区混算；
- 如需分析单实验，额外添加 `experiment_id` 或 `exp_group_id` 过滤；
- 如需全量汇总（不分州）行，添加 `state = '__ALL__'`；如需分州明细，添加 `state != '__ALL__'`。

### 不可直接 SUM 的字段

以下字段为预聚合派生比率或去重指标，**跨分组/跨日期/跨 state 累加将产生错误结果**：

| 字段 | 原因 |
|---|---|
| `gmv_uu_995` | 比率（GMV_995 / 去重曝光 UU），分子分母需分别聚合后再计算 |
| `pc2_gmv_uu_995` | 同上 |
| `ads_load` | 比率（广告曝光 / 自然曝光），需还原分子分母 |
| `ads_narrow_roi` | 比率（窄口径 GMV / 广告收入） |
| `ads_broad_roi` | 比率（宽口径 GMV / 广告收入） |
| `avg_edt` | 均值（EDT 累计 / 有 EDT 订单数） |
| `search_uu` | 去重 UU，跨分组/跨行不可加和 |

### 时效性说明

- 本表为 **日粒度（1d）** 快照表，每日全量覆盖写入（INSERT OVERWRITE），数据反映 T 日的业务状态；
- 上游 EDT 订单信息表（`sls_mart.dwd_edt_order_info_df_${grass_region_without_quote}`）取其最新可用分区，可能存在 **轻微延迟**；
- 汇率采用当日最大汇率（`MAX(exchange_rate)`），广告宽口径 ROI 本地币已换算为美元。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | 实验元数据（场景/层/实验/分组），过滤搜索白名单 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 用户实验分组分配明细，过滤搜索白名单及正式分桶用户 |
| `traffic.dwd_register_di__reg_live` | BR 用户注册州信息；VN 用户注册省份信息 |
| `mp_order.dwd_order_item_all_ent_df__reg_s0_live` | BR 用户最近购物收货地址州信息 |
| `mp_user.dim_user__reg_s0_live` | VN 用户默认收货地址省份信息 |
| `vnbi_mkt.dim_user__address` | VN 用户最近收货省份信息 |
| `vnbi_mkt.shopee_vn_bi_team__vietnam_region_map_details` | 越南省份到大区映射字典 |
| `srdi_mart.dwd_sr_data_warehouse_search` | 搜索行为明细（曝光、点击、下单、浏览及多路径归因） |
| `sls_mart.dwd_edt_order_info_df_${grass_region_without_quote}` | 订单级 EDT（预计送达天数）信息 |
| `srdi_mart.dwd_fp_search_base_1d` | 搜索归因订单基础表，用于计算平均 EDT |
| `srdi_mart.dws_sr_data_warehouse_platform_user_item_keyword_benchmark_1d` | 搜索自然曝光汇总，用于计算广告加载率分母 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告投放明细（曝光、消耗、广告 GMV） |
| `mp_order.dim_exchange_rate__reg_s0_live` | 当日汇率，用于本地币广告 GMV 转换为美元 |
| `srdi_mart.dws_sr_data_warehouse_platform_order_benchmark_1d` | 搜索归因订单维度明细，用于 V2 GMV 995 截断计算 |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维度信息，用于获取 GMV 品类标签（high/low gmv） |
| `srdi_mart.dim_sr_data_warehouse_category_gmv_outlier` | 各品类 GMV 99.5 分位截断阈值，V2 口径异常值过滤基准 |

---

## ETL 逻辑摘要

### 数据流

```
实验元数据 & 用户分组
        ↓
用户-州映射（BR/VN 双路，优先使用收货地址州，回退注册州）
        ↓
搜索行为明细（三路 UNION，涵盖主路径及 source1/source2 多归因路径）
        ↓
┌─────────────────────────────────────────────────┐
│  主指标聚合          广告指标聚合      EDT 指标聚合  │
│  (曝光/点击/下单/GMV) (收入/加载/ROI)  (avg_edt)   │
│           +995截断(ABS口径)                       │
│           +995截断V2(订单×品类口径)               │
└─────────────────────────────────────────────────┘
        ↓
按 exp_group_id × state + GROUPING SETS（含 __ALL__ 汇总行）
        ↓
JOIN 实验维度表 → INSERT OVERWRITE 目标表
```

### 关键步骤

1. **实验维度构建（`dim_exp`）**：从 `dim_sr_data_warehouse_abtest_group` 拉取当日搜索白名单实验的场景/层/实验/分组元数据。

2. **用户实验映射（`user_exp_mapping`）**：从 `dim_sr_data_warehouse_abtest_user_group` 获取当日正式分桶（`is_assignment_log=1`）且在搜索白名单的用户-分组映射。

3. **用户州映射（`user_state_mapping`）**：
   - **BR**：以注册州为底表，用最近 30 天内最新收货地址州覆盖，州值规范化为 `Sao Paulo` / `Rio de Janeiro` / `others`；
   - **VN**：优先取默认收货地址省份映射的大区，其次取最近收货省份，最后取注册省份，均通过越南省份-大区字典表转换；
   - UNION ALL 合并形成统一的 `user_state_mapping`。

4. **搜索行为聚合（`dwd_search_join_state` → `dws_search_metrics`）**：通过三路 UNION 覆盖主路径、source1、source2 归因链路，过滤范围限定为 `global_search`/`search_in_pdp`/`search_prefill` 场景，按 user_id × state 聚合曝光、点击、下单、GMV。

5. **搜索 UU（`dws_search_uu_metric`）**：对 view 操作的用户与实验分组做 JOIN，使用 `GROUPING SETS` 生成分州及 `__ALL__` 两级 distinct UU 数。

6. **EDT 指标（`dws_edt_metric` → `dwm_main_metrics`）**：关联搜索归因订单与 EDT 信息表，计算各用户 EDT 分子（edtmax 之和）与分母（有效订单数），最终在聚合时得到 `avg_edt`。

7. **ABS 995 阈值计算（`global_search_abs995_benchmark`）**：按用户计算总订单 GMV / 总订单数得到人均 ABS，取 99.5 分位值作为截断阈值（CACHE TABLE 广播）；据此计算 `gmv_995`、`gmv_uu_995`、`pc2_gmv_995`、`pc2_gmv_uu_995`。

8. **广告指标（`dwd_ads_load_denominator` + `dwd_ads` → `dwm_ads` → `dws_ads`）**：分别拉取搜索场景自然曝光（分母）及广告表现数据（分子），通过 FULL JOIN 合并，用当日汇率换算广告宽口径 GMV，再 JOIN 用户实验映射并按 GROUPING SETS 聚合得到广告加载率、ROI 及广告收入。

9. **GMV 995 V2 分品类截断（`gmv995_v2_*`）**：从订单基准表拉取搜索归因订单，关联商品维度获取品类标签（`high gmv` / `low gmv`），使用 CUBE(state) 生成分州及汇总行，再 JOIN 各品类的 99.5 分位截断阈值进行订单维度截断，最终汇总形成 `high_gmv_995_v2`、`low_gmv_995_v2` 等六个指标。

10. **最终 INSERT OVERWRITE**：将主指标、搜索 UU、广告指标、实验维度、V2 GMV 995 指标五路 LEFT JOIN 合并，按 `grass_region`/`local_date` 分区覆盖写入目标表。

### 注意事项

- **单 Writer**：本表由单个 ETL 文件写入，不存在多 Writer 竞争风险，但每次执行为全量 `INSERT OVERWRITE` 该分区，重跑时需确认上游数据已就绪。
- **GROUPING SETS 双行**：`state = '__ALL__'` 为聚合汇总行，与各州明细行同时存在于表中；统计全量指标时应显式过滤 `state = '__ALL__'`，避免与分州行重复计算。
- **BR/VN 专属 State**：`user_state_mapping` 仅覆盖 BR 和 VN，其他大区的用户 state 将为 `'NULL'`（字符串），在 `__ALL__` 汇总行中仍包含这部分用户的数据。
- **EDT 上游分区依赖**：`sls_mart.dwd_edt_order_info_df_${grass_region_without_quote}` 使用 `MAX(grass_date)` 动态获取最新分区，若该表更新延迟，`avg_edt` 可能反映非当日数据。
- **ABS 阈值广播**：`global_search_abs995_benchmark` 使用 `CACHE TABLE` + `BROADCASTJOIN` 优化，若数据量异常增大需关注广播内存压力。
- **汇率使用 MAX 值**：当日存在多条汇率记录时取最大值，与其他表使用汇率方式不同，跨表对比时需注意口径一致性。

---

*文档生成时间：2026-05-17*