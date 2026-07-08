<!-- ads-workspace-gdoc-sync: gdoc_id=1PS-5UpJozjtsf8COpbdpKgUGOAuzfKxlzcRyhHxHtG4 gdoc_url=https://docs.google.com/document/d/1PS-5UpJozjtsf8COpbdpKgUGOAuzfKxlzcRyhHxHtG4/edit -->

# mp_paidads.dwd_trace_bidding_hyperx_hi

**分层**：DWD（明细数据层）
**主键**：无单一主键；记录粒度为 `(grass_region, grass_date, h, biz_type, project_name, strategy_name, version, event_timestamp)`
**分区**：`grass_region` / `grass_date` / `h` / `biz_type`
**更新频率**：逐小时调度（实时准实时，按小时分区写入）
**引用频次**：0（末端 ADS 层宽表，当前未被其他候选表直接引用）

---

## 业务描述

本表是付费广告智能竞价系统（HyperX）的**竞价策略追踪明细宽表**，记录竞价决策引擎在每个小时分区内产生的完整事件日志。表中整合了直播（livestream）、店铺（shop）、视频（video）、品牌（brand）、商品（product）五种广告业务形态的竞价行为，为广告主、算法工程师及数据分析师提供跨业务线的统一视角。

核心使用场景包括：① 竞价策略版本（`version`）与项目（`project_name`）的归因分析，追踪不同策略的实际表现；② 实时/小时级的 ROI 管控验证，通过 `target_roi`、`mpc_e_cost_ratio` 等字段回溯竞价时刻的控制参数；③ 广告投放系统的 Debug 与故障排查，结合 `debug_info_json` 和 `extra_json` 还原决策现场；④ 预算消耗节奏分析，通过 `rt_remain_budget`、`daily_budget`、`account_balance` 评估预算健康度。

由于 product 类型的数据来源（`ods_log_hyperx_exp_hi_temp_s0_live`）比其他业务线更为丰富，包含完整的算法参数字段（`coef_array`、`pid_coef`、`mpc_e_*` 系列等），其余四种 `biz_type` 的上述字段当前固定为 `NULL`，查询时需特别注意业务类型差异。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 地区标识，如 `SG`、`MY`、`ID` 等；各地区通过调度参数 `${region}` 参数化写入，表覆盖所有上线地区 |
| `grass_date` | date | 业务日期（各地区按本地时区参数化调度），格式 `yyyy-MM-dd` |
| `h` | tinyint | 小时分区（0–23），与 `grass_date` 共同定位小时级分区 |
| `biz_type` | string | 广告业务类型，枚举值：`livestream`（直播广告）、`shop`（店铺广告）、`video`（视频广告）、`brand`（品牌广告）、`product`（商品广告）；由 ETL 按来源表硬编码写入 |

### 维度：项目与策略标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `project_name` | string | 竞价策略所属项目名称，用于区分不同算法实验或业务项目 |
| `strategy_name` | string | 具体策略名称，与 `project_name` 共同标识一条竞价策略链路 |
| `version` | string | 策略版本号，用于追踪策略迭代与 A/B 实验对比 |
| `campaign_id` | bigint | 广告计划 ID；⚠️ 仅 `biz_type = 'product'` 时有值，其余业务类型固定为 NULL |

### 维度：事件信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `event_type` | string | 竞价事件类型，如 bid request、bid response 等，标识日志所处的竞价生命周期阶段 |
| `emission_timestamp` | bigint | 日志发射（上报）时间戳，单位毫秒（Unix epoch） |
| `event_timestamp` | bigint | 竞价事件实际发生时间戳，单位毫秒（Unix epoch）；⚠️ 与 `emission_timestamp` 可能存在延迟差，排序或去重时应以此字段为准 |

### 维度：策略参数（Map/复合类型）

| 字段 | 类型 | 说明 |
|------|------|------|
| `group_key_map` | map<string,string> | 竞价分组键映射，标识竞价请求所属的分组维度，由 `map_from_entries` 转换自原始数组结构；⚠️ 存储为 Map 类型，不可直接聚合，需通过 `group_key_map['key']` 访问子字段 |
| `initial_agent_params` | map<string,string> | 策略 Agent 初始参数快照，记录竞价决策开始时的输入参数；⚠️ 存储为 Map 类型，子字段含义需结合算法文档解读 |
| `updated_agent_params` | map<string,string> | 策略 Agent 更新后的参数，记录本次竞价后 Agent 状态变化；⚠️ 存储为 Map 类型，与 `initial_agent_params` 对比可观察参数漂移 |
| `output_param` | map<string,string> | 竞价引擎输出参数，包含最终出价相关的决策输出；⚠️ 存储为 Map 类型，需按 key 拆解使用 |
| `flag_params` | map<string,string> | 策略标志位参数，记录各类开关、实验标识等布尔/枚举型配置；⚠️ 存储为 Map 类型 |
| `reward_output` | map<string,string> | 竞价奖励信号输出，记录强化学习或反馈机制中的 reward 计算结果；⚠️ 存储为 Map 类型，仅在支持 reward 反馈的策略链路中有意义 |

### 维度：扩展信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `extra_json` | string | 扩展字段，JSON 字符串格式，存储各业务线个性化的附加信息；⚠️ 需使用 `get_json_object` 或 `json_tuple` 函数解析，直接 SELECT 无法利用子字段 |
| `debug_info_json` | string | Debug 调试信息，JSON 字符串格式，记录竞价决策过程中的中间状态；⚠️ 仅 `biz_type = 'product'` 时有值，其余业务类型固定为 NULL；用于问题排查，不建议用于常规指标计算 |
| `budget_tag` | string | 预算标签，用于标识广告计划所处的预算状态或类型分组；⚠️ 仅 `biz_type = 'product'` 时有值，其余业务类型固定为 NULL |

### 指标：ROI 控制与算法参数

| 字段 | 类型 | 说明 |
|------|------|------|
| `target_roi` | double | 竞价时刻的目标 ROI 设定值；⚠️ 仅 `biz_type = 'product'` 时有值，其余业务类型固定为 NULL；为比率指标，不可直接 SUM |
| `pid_coef` | double | PID 控制器系数，反映竞价调节算法对 ROI 偏差的修正力度；⚠️ 仅 `biz_type = 'product'` 时有值，其余业务类型固定为 NULL；为调节系数，不可直接 SUM，应取均值或按时序分析 |
| `coef_array` | array<double> | 竞价模型系数数组，存储多维度调节参数；⚠️ 仅 `biz_type = 'product'` 时有值，其余业务类型固定为 NULL；为数组类型，需使用 `coef_array[index]` 按位取值，不可直接聚合 |

### 指标：MPC 预测成本与 GMV（24h 窗口）

| 字段 | 类型 | 说明 |
|------|------|------|
| `mpc_e_gmv_24h` | bigint | MPC 算法预测的滚动 24 小时 GMV（最小货币单位，如分）；⚠️ 仅 `biz_type = 'product'` 时有值；为预测值，跨行 SUM 无业务意义，应结合时序对比使用 |
| `mpc_e_cost_24h` | bigint | MPC 算法预测的滚动 24 小时花费（最小货币单位）；⚠️ 仅 `biz_type = 'product'` 时有值；为预测值，跨行 SUM 无业务意义 |

### 指标：MPC 预测成本与 GMV（当日累计）

| 字段 | 类型 | 说明 |
|------|------|------|
| `mpc_e_gmv_daily` | bigint | MPC 算法预测的当日累计 GMV（最小货币单位）；⚠️ 仅 `biz_type = 'product'` 时有值；为预测快照值，同一天内每小时均有记录，直接 SUM 会导致重复累计，应取最新小时的值 |
| `mpc_e_cost_daily` | bigint | MPC 算法预测的当日累计花费（最小货币单位）；⚠️ 仅 `biz_type = 'product'` 时有值；同 `mpc_e_gmv_daily`，为快照值，不可跨小时 SUM |
| `mpc_e_cost_ratio` | double | MPC 预测成本比率（`mpc_e_cost_daily` 的派生比率）；⚠️ 仅 `biz_type = 'product'` 时有值；为预计算比率，不可直接 SUM，需用分子/分母重新计算 |

### 指标：当日实际花费与 GMV（预测/归因）

| 字段 | 类型 | 说明 |
|------|------|------|
| `p_gmv_daily` | double | 当日预测/归因 GMV（货币单位，浮点）；⚠️ 仅 `biz_type = 'product'` 时有值；为快照型累计指标，跨小时 SUM 会重复计算，应取最新分区值 |
| `p_cost_daily` | double | 当日预测/归因花费（货币单位，浮点）；⚠️ 仅 `biz_type = 'product'` 时有值；同 `p_gmv_daily`，为快照值，不可跨小时 SUM |

### 指标：每日广告绩效明细

| 字段 | 类型 | 说明 |
|------|------|------|
| `daily_metrics_imp` | bigint | 当日累计曝光量；⚠️ 仅 `biz_type = 'product'` 时有值；为快照型累计计数，不可跨小时 SUM，应取当日最新小时记录 |
| `daily_metrics_click` | bigint | 当日累计点击量；⚠️ 仅 `biz_type = 'product'` 时有值；同上，为快照型累计值 |
| `daily_metrics_order` | bigint | 当日累计订单量；⚠️ 仅 `biz_type = 'product'` 时有值；同上，为快照型累计值 |
| `daily_metrics_gmv` | bigint | 当日累计 GMV（最小货币单位）；⚠️ 仅 `biz_type = 'product'` 时有值；同上，为快照型累计值，不可跨小时 SUM |
| `daily_metrics_cost` | bigint | 当日累计广告花费（最小货币单位）；⚠️ 仅 `biz_type = 'product'` 时有值；同上，为快照型累计值 |
| `daily_metrics_advv` | double | 当日累计广告价值（Ads Value，浮点）；⚠️ 仅 `biz_type = 'product'` 时有值；同上，为快照型累计值，不可直接 SUM |

### 指标：预算状态

| 字段 | 类型 | 说明 |
|------|------|------|
| `rt_remain_budget` | bigint | 竞价时刻的实时剩余预算（最小货币单位）；⚠️ 仅 `biz_type = 'product'` 时有值；为瞬时快照值，不可 SUM，应按时序分析或取最新值 |
| `daily_budget` | bigint | 广告计划当日总预算（最小货币单位）；⚠️ 仅 `biz_type = 'product'` 时有值；同一计划在同日多条记录中值相同，跨行 SUM 会重复 |
| `account_balance` | bigint | 广告账户余额（最小货币单位）；⚠️ 仅 `biz_type = 'product'` 时有值；为账户级快照值，不可 SUM，应取最新时刻值 |

### 指标：曝光计数

| 字段 | 类型 | 说明 |
|------|------|------|
| `imp_count` | bigint | 本次竞价请求关联的曝光计数；⚠️ 仅 `biz_type = 'product'` 时有值；此字段可累加求和，但需确认其统计口径是否与 `daily_metrics_imp` 一致，避免重复使用 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下分区条件，否则将触发全表扫描，导致极高的计算资源消耗和查询超时：

```sql
-- 必须指定的分区字段
WHERE grass_region = 'XX'          -- 指定目标地区
  AND grass_date = '2026-04-21'    -- 指定目标日期
  AND h = 10                       -- 指定目标小时（如需单小时分析）
  AND biz_type = 'product'         -- 推荐同时指定业务类型，进一步裁剪数据量
```

- `grass_region`、`grass_date`、`h`、`biz_type` 均为分区字段，遗漏任意一个均会导致跨分区全扫
- 若需分析全天数据，可省略 `h` 条件，但务必保留其余三个分区过滤
- 若需跨 `biz_type` 汇总，省略 `biz_type` 过滤时需特别注意字段的 NULL 分布（见下节）

### 不可直接 SUM 的字段

| 字段 | 类型 | 正确计算方式 |
|------|------|-------------|
| `target_roi` | 比率 | 取均值（`AVG`）或按 `campaign_id` 取最新值，不可 SUM |
| `mpc_e_cost_ratio` | 预计算比率 | 用 `SUM(mpc_e_cost_daily) / SUM(mpc_e_gmv_daily)` 重新计算，不可直接 SUM |
| `pid_coef` | 调节系数 | 取均值或按时序分析，不可 SUM |
| `mpc_e_gmv_daily` | 当日累计快照 | 同一 `campaign_id` 在同天多小时均有记录，应取 `MAX(h)` 对应的值，不可跨小时 SUM |
| `mpc_e_cost_daily` | 当日累计快照 | 同上 |
| `p_gmv_daily` | 当日累计快照 | 同上 |
| `p_cost_daily` | 当日累计快照 | 同上 |
| `daily_metrics_imp` | 当日累计快照 | 同上，取最新小时记录 |
| `daily_metrics_click` | 当日累计快照 | 同上 |
| `daily_metrics_order` | 当日累计快照 | 同上 |
| `daily_metrics_gmv` | 当日累计快照 | 同上 |
| `daily_metrics_cost` | 当日累计快照 | 同上 |
| `daily_metrics_advv` | 当日累计快照 | 同上 |
| `rt_remain_budget` | 实时快照 | 按时序取最新值，不可 SUM |
| `daily_budget` | 计划级常量 | 按 `campaign_id` 去重后使用，不可跨行 SUM |
| `account_balance` | 账户级快照 | 按时序取最新值，不可 SUM |
| `coef_array` | 数组类型 | 使用 `coef_array[index]` 按位取值，不可直接聚合 |
| `group_key_map` 等 Map 类型字段 | Map 类型 | 使用 `field_name['key']` 访问子字段，不可直接聚合 |

> **特别提醒**：`biz_type` 非 `product` 的记录，上述大多数算法参数字段均为 `NULL`，跨 `biz_type` 聚合时需先过滤或使用 `COALESCE`/`NULLIF` 处理。

### 时效性说明

本表按小时分区（`h`）写入，为近实时数据。查询某小时数据时，建议使用 `h = ${BIZ_HOUR}` 精确定位，避免读取未完成写入的最新分区。若分析当日全天趋势，推荐查询 `h <= (当前小时 - 1)` 的已完成分区；对于含 `daily_*` 前缀的快照型累计字段，应取当天**最大已完成小时**（`MAX(h)`）对应的值作为当日汇总结果。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ods_log_live_ads_bidding_hyperx_hi__reg_s0_live` | 直播广告竞价日志（`biz_type = 'livestream'`） |
| `mp_paidads.ods_log_shop_ads_bidding_hyperx_hi__reg_s0_live` | 店铺广告竞价日志（`biz_type = 'shop'`） |
| `mp_paidads.ods_log_video_ads_bidding_hyperx_hi__reg_s0_live` | 视频广告竞价日志（`biz_type = 'video'`） |
| `mp_paidads.ods_log_brand_ads_bidding_hyperx_hi__reg_s0_live` | 品牌广告竞价日志（`biz_type = 'brand'`） |
| `mp_paidads.ods_log_hyperx_exp_hi_temp_s0_live` | 商品广告竞价日志（`biz_type = 'product'`），字段最为完整，包含算法参数与预算状态 |

---

## ETL 逻辑摘要

### 数据流

```
ods_log_live_ads_bidding_hyperx_hi__reg_s0_live   ──┐  biz_type='livestream'（算法字段为NULL）
ods_log_shop_ads_bidding_hyperx_hi__reg_s0_live   ──┤  biz_type='shop'      （算法字段为NULL）
ods_log_video_ads_bidding_hyperx_hi__reg_s0_live  ──┤  biz_type='video'     （算法字段为NULL）
ods_log_brand_ads_bidding_hyperx_hi__reg_s0_live  ──┤  biz_type='brand'     （算法字段为NULL）
ods_log_hyperx_exp_hi_temp_s0_live                ──┘  biz_type='product'   （全量字段）
                         │
                         │  UNION ALL（各分支按 grass_region/grass_date/h 过滤）
                         ▼
          dwd_trace_bidding_hyperx_hi__reg_s0_live
          分区写入：INSERT OVERWRITE PARTITION(grass_region, grass_date, h, biz_type)
          调度引擎：HiveSQL，小时级参数化调度（${BIZ_DT}, ${BIZ_HOUR}, ${grass_region}）
```

### 注意事项

1. **字段覆盖不对称**：`target_roi`、`pid_coef`、`mpc_e_*`、`p_*_daily`、`daily_metrics_*`、`rt_remain_budget`、`daily_budget`、`account_balance`、`imp_count`、`debug_info_json`、`campaign_id`、`budget_tag`、`coef_array` 共 14 类字段，**仅在 `biz_type = 'product'` 分支中取自源表真实值**，其余四种业务类型的上述字段均被硬编码为 `NULL`。这是当前各业务线日志 schema 差异的结果，后续如有字段补全需同步调整 ETL。

2. **Map 类型转换**：所有 Map 类字段（`group_key_map`、`reward_output`、`initial_agent_params`、`updated_agent_params`、`output_param`、`flag_params`）均通过 `map_from_entries()` 函数从原始 ODS 层的 entries 数组结构转换而来，下游使用时以 Map 访问语法为准。

3. **分区覆盖策略**：ETL 采用 `INSERT OVERWRITE` 模式，按 `(grass_region, grass_date, h, biz_type)` 四级分区覆盖写入，同一分区重跑时会全量替换，不存在数据重复累积问题，但重跑期间读取可能获取到中间状态数据。

4. **参数化调度**：`${grass_region}`、`${BIZ_DT}`、`${BIZ_HOUR}` 均为调度系统注入的模板参数，表中数据覆盖所有已上线地区，各地区按本地时区独立调度，不存在时区固定的问题。

5. **product 数据源特殊性**：`biz_type = 'product'` 的数据来自 `ods_log_hyperx_exp_hi_temp_s0_live`（表名含 `exp` 和 `temp`），暗示该数据源可能处于实验或临时状态，使用前建议确认该表的稳定性与 SLA 保障情况。

---

*文档生成时间：2026-04-22*