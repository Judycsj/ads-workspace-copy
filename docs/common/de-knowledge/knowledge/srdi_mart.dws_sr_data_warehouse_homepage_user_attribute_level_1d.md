<!-- ads-workspace-gdoc-sync: gdoc_id=1cqiXZT-T7AV9P4GzuQTd0_AF71G3fSFBSdCVPwd3mPs gdoc_url=https://docs.google.com/document/d/1cqiXZT-T7AV9P4GzuQTd0_AF71G3fSFBSdCVPwd3mPs/edit -->

# srdi_mart.dws_sr_data_warehouse_homepage_user_attribute_level_1d

**分层**：DWS（数据服务层）
**主键**：`platform` + `item_click_level` + `dd_click_level` + `major_app_version` + `app_version` + `module` + `object` + `grass_region` + `local_date`
**分区**：`grass_region`（站点大区）/ `local_date`（业务日期）
**更新频率**：每日全量覆盖写入（`INSERT OVERWRITE`）
**引用频次 / 访问频次**：537

---

## 业务描述

本表是 Shopee 首页（Homepage）用户属性分层汇总宽表，以**日粒度**对首页各模块的流量与转化指标按**用户画像维度**进行预聚合。

核心业务场景：

- **首页模块效果分析**：按 `module`（模块）、`object`（模块内对象）下钻，查看各模块的曝光、点击、购买、GMV 表现。
- **用户分层对比**：结合用户点击活跃度分层（`item_click_level`、`dd_click_level`），分析不同价值用户群体在首页的行为差异。
- **广告 vs. 自然流量拆分**：所有核心指标均拆分为 `organic_*`（自然流量）和 `ads_*`（广告流量）两个口径，支持广告效果评估。
- **全渠道 (Omni) 指标追踪**：提供 `omni_imp_cnt`、`omni_click_cnt` 等全渠道口径指标，满足跨渠道统一归因需求。
- **App 版本分析**：支持按 `app_version` / `major_app_version` 追踪版本上线后首页指标变化。
- **平台级订单基线**：补充 `platform_order_cnt`、`platform_gmv` 作为平台整体成交基线，方便首页贡献率计算。

适合回答的典型问题：

- 某大区昨日首页推荐模块（module=recommend）的点击用户数和点击率是多少？
- 高活跃用户（item_click_level=high）与低活跃用户在广告曝光和购买上有何差异？
- iOS 最新版本上线后，首页 GMV 较上一版本变化了多少？
- 首页自然流量 GMV 占平台总 GMV 的比例是多少？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区标识，如 `ID`、`MY`、`TH` 等；所有查询必须指定此分区 |
| `local_date` | date | 业务日期（本地时区），格式 `yyyy-MM-dd`；所有查询必须指定此分区 |

### 维度：用户画像分层

| 字段名 | 类型 | 说明 |
|---|---|---|
| `item_click_level` | string | 用户商品点击活跃度分层，来源于 `dim_sr_data_warehouse_user_label`；`'__ALL__'` 表示全量汇总 |
| `dd_click_level` | string | 用户 DD（日常发现）点击活跃度分层，来源于 `dim_sr_data_warehouse_user_label`；`'__ALL__'` 表示全量汇总 |

### 维度：设备与版本

| 字段名 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 客户端平台，如 `iOS`、`Android`；`'__ALL__'` 表示全渠道汇总 |
| `app_version` | string | App 完整版本号；`'__ALL__'` 表示跨版本汇总 |
| `major_app_version` | string | App 主版本号（取版本号最后一个 `.` 前的部分）；`'__ALL__'` 表示跨主版本汇总 |

### 维度：首页模块与对象

| 字段名 | 类型 | 说明 |
|---|---|---|
| `module` | string | 首页模块标识，如 `flash_sale`、`recommend_collection`；`'__ALL__'` 表示全模块汇总 |
| `object` | string | 模块内对象标识（如具体坑位或内容 ID）；`'__ALL__'` 表示模块级别汇总 |

### 指标：用户数（去重）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `view_uu` | bigint | 有页面浏览行为（view_cnt > 0）的去重用户数 |
| `imp_uu` | bigint | 有曝光行为（imp_cnt > 0）的去重用户数 |
| `click_uu` | bigint | 有点击行为（click_cnt > 0）的去重用户数 |

### 指标：曝光

| 字段名 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 总曝光次数（impression） |
| `organic_imp_cnt` | bigint | 自然流量曝光次数 |
| `ads_imp_cnt` | bigint | 广告曝光次数 |
| `omni_imp_cnt` | bigint | 全渠道曝光次数（omni_impression 事件） |
| `organic_omni_imp_cnt` | bigint | 自然流量全渠道曝光次数 |
| `ads_omni_imp_cnt` | bigint | 广告全渠道曝光次数 |

### 指标：点击

| 字段名 | 类型 | 说明 |
|---|---|---|
| `click_cnt` | bigint | 总点击次数 |
| `organic_click_cnt` | bigint | 自然流量点击次数 |
| `ads_click_cnt` | bigint | 广告点击次数 |
| `omni_click_cnt` | bigint | 全渠道点击次数（omni_click 事件） |
| `organic_omni_click_cnt` | bigint | 自然流量全渠道点击次数 |
| `ads_omni_click_cnt` | bigint | 广告全渠道点击次数 |

### 指标：浏览与停留

| 字段名 | 类型 | 说明 |
|---|---|---|
| `ppv_cnt` | bigint | 商品详情页浏览次数（PPV，pdp page view） |
| `organic_ppv_cnt` | bigint | 自然流量 PPV 次数 |
| `ads_ppv_cnt` | bigint | 广告 PPV 次数 |
| `stay_time` | bigint | 页面停留总时长（单位：毫秒，来源于 `page_stay_duration` 之和） |

### 指标：订单与 GMV（首页归因）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 首页归因总订单数 |
| `organic_order_cnt` | double | 首页归因自然流量订单数 |
| `ads_order_cnt` | double | 首页归因广告订单数 |
| `gmv` | double | 首页归因总 GMV |
| `organic_gmv` | double | 首页归因自然流量 GMV |
| `ads_gmv` | double | 首页归因广告 GMV |

### 指标：平台整体订单与 GMV（基线）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `platform_order_cnt` | double | 平台级别总订单数（来源于 `dwd_sr_data_warehouse_platform`，非首页归因），可用于计算首页贡献率 |
| `platform_gmv` | double | 平台级别总 GMV（来源于 `dwd_sr_data_warehouse_platform`，非首页归因），可用于计算首页 GMV 贡献率 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：站点大区分区字段，查询时必须显式指定，否则将触发全分区扫描，严重影响性能。
- **`local_date`**：日期分区字段，必须显式指定或限定范围。跨日期汇总需手动 SUM 聚合。
- 示例：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2026-05-16'
  ```

### 维度汇总层级说明（`__ALL__` 值）

本表通过 `GROUPING SETS` 预聚合了多个维度的汇总层，`'__ALL__'` 字符串代表该维度的全量汇总行，**不是实际取值**。使用时需注意：

| 维度组合 | 说明 |
|---|---|
| `module = '__ALL__'` 且 `object = '__ALL__'` | 全模块汇总行 |
| `module != '__ALL__'` 且 `object = '__ALL__'` | 模块级汇总行 |
| `module != '__ALL__'` 且 `object != '__ALL__'` | 模块+对象最细粒度行 |
| `app_version = '__ALL__'` | 跨版本汇总行 |
| `major_app_version = '__ALL__'` | 跨主版本汇总行 |

**使用时必须明确指定 `__ALL__` 过滤或排除，避免重复计算数据。**

### 不可直接 SUM 的字段

以下字段在跨维度聚合时不能直接 SUM，否则会重复计算：

| 字段 | 原因 |
|---|---|
| `view_uu`、`imp_uu`、`click_uu` | 去重用户数，跨维度 SUM 会导致同一用户被多次计数 |
| `platform_order_cnt`、`platform_gmv` | 平台基线指标，在不同 `module`/`object`/`item_click_level` 等维度下重复存储，直接 SUM 必然重复 |

### 时效性说明

- 本表为 **T+1** 日更新，`local_date` 对应的数据通常在次日 ETL 完成后可用。
- 表名后缀 `_1d` 表示单日粒度快照，**不含** N 日累计窗口（如需多日趋势，需按 `local_date` 区间查询后自行聚合）。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_homepage_user_item` | 首页用户-商品级别行为明细（曝光、点击、omni、ppv、订单、GMV），是首页归因指标的核心来源 |
| `srdi_mart.dim_sr_data_warehouse_user_label` | 用户画像标签维表，提供 `item_click_level`（商品点击活跃度）和 `dd_click_level`（DD 点击活跃度）分层标签 |
| `srdi_mart.dwd_sr_data_warehouse_platform` | 平台级别订单明细，用于计算平台整体订单数（`platform_order_cnt`）和 GMV（`platform_gmv`）基线 |

---

## ETL 逻辑摘要

### 数据流

```
dwm_sr_data_warehouse_homepage_user_item  ──►  detail_data（行为明细，含 organic/ads 拆分）
                                                      │
dim_sr_data_warehouse_user_label          ──►  dim（用户分层标签）
                                                      │
                               user_data（用户级聚合）─► join_data（关联用户标签）
                                                                │
                                                     cube_data（platform/item_click_level/dd_click_level 多维 CUBE）
                                                                │
                                              version_roll_up_data（major/app_version ROLLUP）
                                                                │
                                             homepage_metrics（module/object ROLLUP + UU 去重计算）
                                                                │
dwd_sr_data_warehouse_platform  ──►  platform_order_agg  ──►  platform_order_cube
                                                                │
                               homepage_metrics FULL OUTER JOIN platform_order_cube
                                                                │
                              INSERT OVERWRITE  dws_sr_data_warehouse_homepage_user_attribute_level_1d
```

### 关键步骤

1. **`dim_*`（Temporary View）**：从 `dim_sr_data_warehouse_user_label` 按分区过滤，提取用户 `item_click_level`、`dd_click_level` 标签。

2. **`detail_data_*`（Temporary View）**：从 `dwm_sr_data_warehouse_homepage_user_item` 读取用户行为明细，依据 `is_ads` 标志将 `imp_cnt`、`click_cnt`、`omni_*`、`ppv_cnt`、`order_cnt`、`gmv` 等拆分为 `organic_*` 和 `ads_*` 两个口径。同时通过 UNION ALL 处理 `source1_module`/`source1_object` 和 `source2_module`/`source2_object` 的多归因场景（omni 类事件可能归属多个 module/object），并过滤掉"see_more_link"等非商品曝光的 impression 行为。

3. **`user_data_*`（Temporary View）**：对 `detail_data` 按 `platform`、`app_version`、`major_app_version`、`module`、`object`、`user_id` 做用户级聚合（SUM），同时过滤掉游客（`user_id <= 0`）及 `find_similar_products` 场景的行为。

4. **`join_data_*`（Cached Table）**：将 `user_data` 与 `dim` 通过 `user_id` LEFT JOIN，关联用户画像分层标签（`item_click_level`、`dd_click_level`），缺失标签补充为空字符串。结果缓存至 `MEMORY_AND_DISK_SER`。

5. **`cube_data_*`（Cached Table）**：对 `join_data` 在 `platform`、`item_click_level`、`dd_click_level` 三个维度上进行 CUBE 预聚合（通过模板变量 `${fields_placeholder}`/`${groupby_placeholder}` 实现），保留用户粒度（含 `user_id`），为后续去重 UU 计算奠定基础。结果缓存。

6. **`version_roll_up_data_*`（Cached Table）**：在 `cube_data` 基础上，对 `major_app_version`、`app_version` 做 ROLLUP（三个 GROUPING SET），生成版本全量汇总行（`'__ALL__'`）。结果缓存。

7. **`homepage_metrics_*`（Temporary View）**：在 `version_roll_up_data` 基础上，对 `module`、`object` 做 ROLLUP（三个 GROUPING SET），同时通过 `COUNT(DISTINCT IF(..., user_id, NULL))` 计算 `view_uu`、`imp_uu`、`click_uu` 等去重用户数，缺失的 `module`/`object` 用 `'__ALL__'` 填充。

8. **`platform_order_agg_*`（Temporary View）**：从 `dwd_sr_data_warehouse_platform` 过滤出 `operation = 'order'` 的记录，按 `platform`、`app_version` 聚合平台级订单数和 GMV；`major_app_version` 由正则提取自 `app_version`。

9. **`platform_order_cube_*`（Temporary View）**：对 `platform_order_agg` 在 `platform`、`major_app_version`、`app_version` 三个维度做 GROUPING SETS，生成与 `homepage_metrics` 维度对齐的汇总行；`item_click_level`、`dd_click_level`、`module`、`object` 固定为 `'__ALL__'`。

10. **最终 INSERT OVERWRITE**：将 `homepage_metrics` 与 `platform_order_cube` 通过全量 FULL OUTER JOIN（按 `platform`、`item_click_level`、`dd_click_level`、`major_app_version`、`app_version`、`module`、`object` 七个维度关联）写入目标表分区，缺失指标以 `COALESCE(..., 0)` 补零。

### 注意事项

- **单 Writer，无多文件并发写入风险**：本表仅有一个 ETL 文件（`multi_writer = false`），不存在多 writer 写同一物理表的冲突。
- **GROUPING SETS 产生重叠行**：表中同时存在不同汇总粒度的行（`__ALL__` 汇总行 + 明细行），查询时若不过滤汇总层级，直接 SUM 所有行将严重重复计算，务必明确指定 `module`、`object`、`app_version`、`major_app_version`、`platform`、`item_click_level`、`dd_click_level` 各维度的取值（或明确选择某一汇总层级）。
- **多归因 omni 事件 UNION ALL**：`detail_data` 通过三段 UNION ALL 处理 omni 类事件的多归因（`source1_module`/`source1_object`、`source2_module`/`source2_object`），同一用户事件可能被计入多个 `module`/`object` 组合，这是业务设计的全渠道归因逻辑，并非数据错误。
- **模板变量**：SQL 中存在 `${fields_placeholder}`、`${groupby_placeholder}`、`${grass_region}`、`${grass_region_without_quote}` 等运行时模板变量，实际执行时由调度框架动态替换为对应站点和 CUBE 组合参数。
- **平台指标仅对齐到 `__ALL__` 维度**：`platform_order_cnt`、`platform_gmv` 仅在 `item_click_level = '__ALL__'`、`dd_click_level = '__ALL__'`、`module = '__ALL__'`、`object = '__ALL__'` 的行中有值，其余维度组合下为 0。

---

*文档生成时间：2026-05-17*