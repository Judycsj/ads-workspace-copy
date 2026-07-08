<!-- ads-workspace-gdoc-sync: gdoc_id=1WZAJM-bCIvthwyK13caB74FckZfW-X1xGdAXrZt8qVE gdoc_url=https://docs.google.com/document/d/1WZAJM-bCIvthwyK13caB74FckZfW-X1xGdAXrZt8qVE/edit -->

# srdi_mart.dws_sr_data_warehouse_platform_exp_state_level_metrics_1d

**分层：** DWS（数据汇总层）
**主键：** `exp_type` + `grass_region` + `local_date` + `state` + `exp_group_id` + `platform` + `is_ads` + `scenario_tag` + `feature_detail` + `target_type`
**分区：** `exp_type` / `grass_region` / `local_date`（三级分区）
**更新频率：** 每日（T+1）
**引用频次/访问频次：** 234

---

## 业务描述

本表是搜推数仓（SRDI）**A/B 实验 × 州/省级地理维度**的每日汇总宽表，服务于搜推（Search & Recommendation）平台的精细化实验分析场景。

**核心业务场景：**

- 在 A/B 实验框架下，按实验分组（`exp_group_id`）、地理州/省（`state`）、平台（`platform`）、场景（`scenario_tag`）、算法特征（`feature_detail`/`target_type`）等维度，统计曝光、点击、浏览、购物车、订单、GMV 等核心业务指标；
- 提供广告（ADS）专项指标，包括广告曝光、点击、广告 GMV、广告收入、宽口径 GMV/订单；
- 提供 99.5% 分位数截尾（995 去极值）指标，用于实验中排除高 GMV 极端用户的干扰；
- 支持搜索（Search）与推荐（Recommendation）多业务线的联合分析。

**适合回答的问题：**

- 某实验组（`exp_group_id`）在特定州（`state`）下的 GMV、订单量、UV 等核心指标如何？
- 不同平台（APP/Web）、是否广告（`is_ads`）下，各推荐场景（`scenario_tag`）的实验效果对比？
- 去除极端用户后（995 指标），各实验组的 GMV 和 UV 表现？
- 广告收入（`revenue_usd`）、广告 GMV（`ads_gmv_usd`）在各实验组和推荐场景的分布？
- 特定地区（BR 巴西、VN 越南）的州级实验效果分析？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_type` | string | 实验类型标识；当前由 ETL 写入固定值 `'dim_join'`，用于区分不同实验归因口径 |
| `grass_region` | string | 国家/地区标识，如 `'BR'`、`'VN'` 等 |
| `local_date` | date | 业务本地日期（当地时区），格式 `yyyy-MM-dd` |

### 维度：实验与业务场景

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | int | A/B 实验分组 ID，对应 `dim_sr_data_warehouse_abtest_user_group` 中的分组标识 |
| `state` | string | 用户归属州/省。BR 优先取最近 30 天买家收货地址州，其次注册州；VN 优先取默认配送地址大区，依次回退最近收货省、注册省；无法识别时填 `'Unknown'` |
| `platform` | string | 用户访问平台，如 `'android'`、`'ios'`、`'web'`；聚合维度时为 `'__ALL__'` |
| `is_ads` | string | 是否广告流量，`'true'` 表示广告，`'false'` 表示自然流量，`'__ALL__'` 表示不区分 |
| `scenario_tag` | string | 推荐/搜索业务场景标签，如 `'DA_Daily Discover'`、`'dpm module Global Search business line Search'`、`'__ALL__'` 等 |
| `feature_detail` | string | 算法特征粒度标签，格式通常为 `'场景-算法-target_type'`；`'__ALL__'` 表示不区分特征 |
| `target_type` | string | 算法目标类型，从 `feature_detail` 拆分第三段（或第二段）得到；`'__ALL__'` 表示不区分 |

### 指标：自然流量核心指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数（PV 级别） |
| `imp_uu` | bigint | 曝光 UV，实验组内有曝光行为的去重用户数 |
| `click_cnt` | bigint | 点击次数 |
| `click_uu` | bigint | 点击 UV，实验组内有点击行为的去重用户数 |
| `ppv_cnt` | bigint | 商品详情页（PDP）访问次数 |
| `ppv_cnt_exclude_isback` | bigint | 排除返回行为后的 PDP 访问次数 |
| `ppv_uu` | bigint | 有 PDP 访问的去重用户数 |
| `cart_cnt` | bigint | 加购次数 |
| `cart_uu` | bigint | 加购 UV，有加购行为的去重用户数 |
| `order_cnt` | double | 订单数 |
| `order_uu` | bigint | 下单 UV，有订单行为的去重用户数 |
| `gmv` | double | 商品交易总额（本地币种，未截尾） |
| `pc2_gmv` | double | PC2 口径 GMV（本地币种，未截尾） |

### 指标：99.5% 分位数截尾（去极值）指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv_995` | double | 对用户 ABS（人均购买额）按 99.5% 分位数截尾后汇总的 GMV，用于剔除极端高 GMV 用户对实验的干扰 |
| `pc2_gmv_995` | double | 截尾后的 PC2 口径 GMV |
| `imp_uu_995` | bigint | 截尾口径下有曝光的去重用户数 |

### 指标：广告指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_imp_cnt` | bigint | 广告曝光次数 |
| `ads_click_cnt` | bigint | 广告点击次数 |
| `ads_order_cnt` | double | 广告直接归因订单数 |
| `ads_gmv_usd` | double | 广告直接归因 GMV（美元） |
| `ads_broad_order_cnt` | double | 广告宽口径归因订单数 |
| `ads_broad_gmv_usd` | double | 广告宽口径归因 GMV（美元，由本地币种通过汇率换算） |
| `revenue_usd` | double | 广告收入（广告主花费金额，美元） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须全部指定**，否则触发全表扫描，影响性能：
  ```sql
  WHERE exp_type = 'dim_join'
    AND grass_region = 'BR'
    AND local_date = '2024-01-01'
  ```
- `exp_type` 当前仅有 `'dim_join'` 一种取值，查询时务必显式指定。
- `local_date` 为本地日期（当地时区），跨时区对比时需注意与 UTC 日期的差异。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_uu`、`click_uu`、`ppv_uu`、`cart_uu`、`order_uu` | 去重 UV，跨维度或跨 `exp_group_id` 合并时不可直接累加，会重复计数 |
| `imp_uu_995` | 截尾口径的去重 UV，同上 |
| `gmv_995`、`pc2_gmv_995` | 已按用户 ABS 极值过滤后汇总，跨场景合并需重新从用户粒度截尾，直接 SUM 无意义 |
| `ads_broad_gmv_usd` | 宽口径 GMV 经汇率换算，不同日期/地区汇率不同，跨日期 SUM 会引入汇率混淆 |

### 已预聚合的汇总维度

- `platform = '__ALL__'`、`is_ads = '__ALL__'`、`feature_detail = '__ALL__'`、`target_type = '__ALL__'`、`scenario_tag = '__ALL__'`、`state = 'Unknown'` 均为 ETL 预聚合维度，**查询时需注意避免与明细维度重复叠加**。
- `scenario_tag` 中存在聚合虚拟场景，如 `'DA_Cart_Unify'`、`'DA_RCMD Unify'`、`'DA_YMAL_Cart'`，这些是对子场景求和的结果，**不可再与子场景数据叠加求和**。

### 时效性说明

- 本表为 **每日全量覆盖写入**（`INSERT OVERWRITE`），每日 T+1 产出当天数据。
- 数据仅覆盖分配到实验白名单（`is_rcmd_whitelist = 1`）且有实验分组记录（`is_assignment_log = 1`）的用户，**非实验用户不包含在本表中**。
- `state` 州/省映射仅支持 BR 和 VN；其他地区所有用户的 `state` 均为 `'Unknown'`。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取用户的实验分组信息（`exp_group_ids`），用于实验指标归因 |
| `srdi_mart.dws_sr_data_warehouse_platform_user_level_benchmark_1d` | 自然流量用户粒度基准指标，包含曝光、点击、PDP、加购、订单、GMV 等 |
| `traffic.dwd_register_di__reg_live` | BR 用户注册州信息，用于构建巴西用户州映射 |
| `mp_order.dwd_order_item_all_ent_df__reg_s0_live` | 买家近 30 天收货地址州，优先级高于注册州（BR） |
| `mp_user.dim_user__reg_s0_live` | VN 用户默认配送地址及用户基础信息 |
| `vnbi_mkt.shopee_vn_bi_team__vietnam_region_map_details` | 越南省份到大区的映射字典 |
| `vnbi_mkt.dim_user__address` | VN 用户最近收货省份信息 |
| `mp_user.dwd_register_ent_di__vn_s0_live` | VN 用户注册省份信息 |
| `srdi_mart.ads_rcmd_platform_scenario_level_outlier_di` | 各场景 99.5% 分位数 ABS 阈值，用于 GMV 极值截尾 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告投放明细，提供广告曝光、点击、广告 GMV、宽口径 GMV、广告收入等 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率表，用于将广告宽口径 GMV 从本地币种换算为美元 |

---

## ETL 逻辑摘要

### 数据流

```
用户实验分组 (dim_sr_data_warehouse_abtest_user_group)
        │
        ▼
用户州映射 (BR: 注册州←收货州覆盖; VN: 默认配送→最近收货→注册省)
        │
        ├──► 自然流量用户粒度指标 (platform_user_level_benchmark_1d)
        │         │ CUBE(platform × is_ads) + 用户州 JOIN
        │         ├──► 常规指标聚合 (imp/click/ppv/cart/order/gmv)  ──► exp_sum ──► platform_metrics
        │         └──► 995截尾口径聚合 (abs_995_val 过滤极端用户)  ──► exp_sum ──► metrics_995
        │
        ├──► 广告指标 (dwd_advertise_performance_di)
        │         │ entrance→scenario_tag 映射 + 用户州 JOIN + 汇率换算
        │         └──► CUBE(scenario) + 虚拟聚合场景合并           ──► exp_sum ──► ads_metrics_cube
        │
        └──► INSERT OVERWRITE (platform_metrics FULL OUTER JOIN metrics_995 LEFT JOIN ads_metrics_cube)
                  ▼
    dws_sr_data_warehouse_platform_exp_state_level_metrics_1d
```

### 关键步骤

1. **用户实验分组视图**（`user_exp_*`）：从 `dim_sr_data_warehouse_abtest_user_group` 读取当日推荐白名单且有分配日志的用户，按 `user_id` 收集所有 `exp_group_id` 列表（`collect_list`）。

2. **用户州映射视图**（`user_state_mapping_*`）：
   - **BR**：以注册州为基础，若用户近 30 天内有收货记录则用最新收货州覆盖注册州；州值标准化为 `'Sao Paulo'`、`'Rio de Janeiro'`、`'others'`。
   - **VN**：以用户默认配送地址省份为主，依次 `COALESCE` 最近收货省、注册省，均无则填 `'Unknown'`；省份通过字典表映射为大区名。
   - 两地区 `UNION ALL` 合并为统一映射表。

3. **自然流量用户粒度指标聚合**（`user_level_metrics_*`）：从 `platform_user_level_benchmark_1d` 读取目标场景用户明细；原始维度 + 对非全量 `feature_detail` 补充聚合为 `'__ALL__'`；与州映射 LEFT JOIN，JOIN 实验用户后使用 `GROUPING SETS` 构建 `platform × is_ads` 的 CUBE；计算各维度组合下的用户级 UU 标识（`imp_uu`/`click_uu`等），通过 `exp_sum` 自定义函数按实验分组汇总，LATERAL VIEW EXPLODE 展开为最终明细行（`platform_metrics_*`）。

4. **99.5% 截尾 GMV 指标**（`metrics_995_*`）：从 `platform_user_level_benchmark_1d` 读取特定推荐场景 GMV 数据，计算用户人均购买额（ABS），与场景级 99.5% 分位数阈值（`ads_rcmd_platform_scenario_level_outlier_di`）比较，过滤掉超阈值极端用户后按实验分组汇总 GMV、PC2 GMV 和 imp_uu（`metrics_995_*`）；该视图维度固定 `platform='__ALL__'`、`feature_detail='__ALL__'`。

5. **广告指标聚合**（`ads_metrics_*`）：从 `dwd_advertise_performance_di` 读取广告投放数据，按 `entrance` 字段映射为 `scenario_tag`；与州映射 JOIN 后再与汇率表 JOIN 将本地币广告宽口径 GMV 换算为美元；通过 `exp_sum` 按实验分组汇总，EXPLODE 展开后使用 `GROUPING SETS`（按 `scenario_tag` 及全聚合）以及对 `DA_Cart_Unify`、`DA_RCMD Unify`、`DA_YMAL_Cart`、`DA_YMAL_Cart` 等虚拟聚合场景的 `UNION ALL` 扩充，构建广告维度全量指标（`ads_metrics_cube_*`）；广告指标固定 `is_ads='true'`、`platform='__ALL__'`、`feature_detail='__ALL__'`、`target_type='__ALL__'`。

6. **最终写入**（`INSERT OVERWRITE`）：以 `platform_metrics_*` 为主表，LEFT JOIN `metrics_995_*` 补充截尾指标，FULL OUTER JOIN `ads_metrics_cube_*` 补充广告专属行（含无自然流量但有广告数据的场景），写入目标表分区 `exp_type='dim_join'`。

### 注意事项

- **单 Writer**：本表仅一个 ETL 文件写入，不存在多 Writer 并发冲突风险。
- **分区覆盖写入**：使用 `INSERT OVERWRITE PARTITION`，每次执行仅覆盖当日当地区分区，历史分区不受影响；重跑时幂等安全。
- **`exp_sum` 自定义函数**：该函数为 SRDI 内部 UDAF，将用户指标数组按 `exp_group_ids` 列表分发到多个实验组，理解其输出结构需参考 SRDI 框架文档；EXPLODE 结果中 `exp_group_id` 为单值，`fields` 为对应指标数组。
- **FULL OUTER JOIN 空值处理**：最终 SELECT 中大量使用 `COALESCE(t1.col, t3.col)` 处理广告独占行（`t1` 为 NULL 时）的维度字段回填。
- **广告宽口径 GMV 汇率**：`ads_broad_gmv_local / avg(fx)` 使用当日汇率换算，跨日期分析时汇率可能不同，不建议跨日聚合后直接比较。
- **越南用户州映射依赖外部字典表** `vnbi_mkt.shopee_vn_bi_team__vietnam_region_map_details`，若字典表更新不及时，可能导致部分用户州映射为 `'Unknown'`。
- **广告场景虚拟聚合**：`DA_Cart_Unify`、`DA_RCMD Unify`、`DA_YMAL_Cart` 是由子场景广告数据求和得到的聚合行，与对应子场景数据存在重叠，查询时**不可与子场景一起 SUM**。

---

*文档生成时间：2026-05-17*