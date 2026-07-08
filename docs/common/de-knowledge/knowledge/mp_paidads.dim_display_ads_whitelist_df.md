<!-- ads-workspace-gdoc-sync: gdoc_id=10sai4-FP0FwJwY3scTuhkm7usrPNMEcUzgU1oCOF780 gdoc_url=https://docs.google.com/document/d/10sai4-FP0FwJwY3scTuhkm7usrPNMEcUzgU1oCOF780/edit -->

# mp_paidads.dim_display_ads_whitelist_df

**分层**：DIM（维度层）
**主键**：`shop_id`（按地区分区后唯一标识一条白名单记录）
**分区**：`grass_region`（地区代码，如 BR / ID / MY / PH / SG / TH / TW / VN）
**更新频率**：每日全量覆盖（`insert overwrite`，`_df` 后缀表）
**引用频次**：0（末端 ADS 层维表，未被其他候选表引用）

---

## 业务描述

本表记录 Shopee 展示广告（Display Ads）白名单的维度信息，用于标识哪些店铺具有使用展示广告产品的资格。白名单机制是展示广告准入管控的核心手段，运营团队通过后台系统对店铺进行加白或取消加白（dewhitelist）操作，本表是该操作结果在数仓中的持久化映射。

本表的核心使用场景包括：① 判断某店铺当前是否在展示广告白名单内（通过 `status` 字段）；② 追溯白名单变更历史，审计某店铺何时被加白或移除，以及操作人信息；③ 与广告投放事实表 JOIN，过滤出合规的白名单店铺进行后续分析。

作为维度层（DIM）表，本表不包含广告绩效指标，仅提供店铺维度的白名单状态与元数据，是展示广告相关分析报表的基础维度来源。各地区数据通过统一的 ETL 流程聚合至同一张表中，以 `grass_region` 作为分区字段实现地区隔离，查询时须明确指定分区以避免全表扫描。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 地区代码，如 `BR`、`ID`、`MY`、`PH`、`SG`、`TH`、`TW`、`VN`。每次查询**必须**指定此字段作为过滤条件，否则将触发全分区扫描。 |

### 维度：主键与店铺属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺唯一标识符（shopid）。在同一 `grass_region` 分区内为主键，标识一个白名单店铺。 |
| `shop_name` | string | 店铺名称，通过 LEFT JOIN `mp_user.dim_shop__reg_s0_live` 补全。⚠️ 源系统白名单表中店铺名为空串，依赖 dim_shop 维表补全，若 dim_shop 中无对应记录则该字段为空，使用时需注意空值处理。 |
| `operator` | string | 操作人邮箱地址，记录执行白名单加白或取消加白操作的运营人员账号，可用于审计追溯。 |
| `status` | bigint | 白名单状态标识。标记该店铺当前的白名单状态（加白或取消加白，即 Whitelist or Dewhitelist）。⚠️ 具体枚举值含义（如 1=加白、0=取消加白）需参照业务系统文档确认，查询时勿直接以非零即真方式使用。 |

### 维度：时间属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `create_timestamp` | bigint | 记录创建时间，Unix 时间戳（秒级），原始字段为源库中的 `ctime`，以 UTC 存储。⚠️ 为 Unix 时间戳，直接展示需使用 `from_unixtime` 转换；跨地区时间比较时注意时区差异。 |
| `modified_timestamp` | bigint | 记录最后修改时间，Unix 时间戳（秒级），原始字段为源库中的 `mtime`，以 UTC 存储。⚠️ 为 Unix 时间戳，直接展示需使用 `from_unixtime` 转换；跨地区时间比较时注意时区差异。 |
| `create_datetime` | string | 记录创建时间的本地时间字符串，格式为 `YYYY-MM-DD HH:MM:SS`，已按各地区本地时区转换。⚠️ 为字符串类型，范围过滤时需注意格式一致性；各地区时区不同（如 BR 为 America/Araguaina，ID/TH/VN 为 Asia/Jakarta，SG/MY/PH/TW 为 Asia/Singapore），跨地区汇总时不可直接进行字符串比较。 |
| `modified_datetime` | string | 记录最后修改时间的本地时间字符串，格式为 `YYYY-MM-DD HH:MM:SS`，已按各地区本地时区转换。⚠️ 同 `create_datetime`，为字符串类型且时区因地区而异，跨地区汇总比较时须注意。 |

---

## 查询使用须知

**本表为维度表，通常直接 SELECT 或与事实表 JOIN 使用，无复杂聚合场景。**

### 必须包含的过滤条件

每次查询**必须**指定 `grass_region` 分区字段，否则将扫描全部地区分区，造成不必要的计算资源消耗：

```sql
WHERE grass_region = 'SG'   -- 替换为目标地区代码
```

支持的地区代码：`BR`、`ID`、`MY`、`PH`、`SG`、`TH`、`TW`、`VN`。

若需多地区数据，建议显式列出：

```sql
WHERE grass_region IN ('SG', 'MY', 'TH')
```

### 不可直接 SUM 的字段

- **`status`**：为状态枚举值，不具备数值加和含义，统计白名单店铺数量时应使用 `COUNT(shop_id) WHERE status = <加白枚举值>` 而非 `SUM(status)`。
- **`create_timestamp` / `modified_timestamp`**：Unix 时间戳字段，不应被 SUM；如需时间范围过滤，应使用范围比较（`BETWEEN`）而非聚合。

### 时效性说明

本表为每日全量覆盖（`insert overwrite`），存储的是当日白名单快照，**不保留历史分区**（无日期分区）。`status` 字段反映的是最新一次操作后的状态，如需历史变更追踪，应结合 `modified_timestamp` / `modified_datetime` 字段判断变更时序，或查询上游 continuous 流表。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.shopee_ads_br_db__display_ads_whitelist_tab__reg_continuous_s0_live` | 巴西（BR）展示广告白名单源表，提供 shopid、status、ctime、mtime、operator |
| `mp_paidads.shopee_ads_id_db__display_ads_whitelist_tab__reg_continuous_s0_live` | 印尼（ID）展示广告白名单源表 |
| `mp_paidads.shopee_ads_th_db__display_ads_whitelist_tab__reg_continuous_s0_live` | 泰国（TH）展示广告白名单源表 |
| `mp_paidads.shopee_ads_vn_db__display_ads_whitelist_tab__reg_continuous_s0_live` | 越南（VN）展示广告白名单源表 |
| `mp_paidads.shopee_ads_sg_db__display_ads_whitelist_tab__reg_continuous_s0_live` | 新加坡（SG）展示广告白名单源表 |
| `mp_paidads.shopee_ads_my_db__display_ads_whitelist_tab__reg_continuous_s0_live` | 马来西亚（MY）展示广告白名单源表 |
| `mp_paidads.shopee_ads_ph_db__display_ads_whitelist_tab__reg_continuous_s0_live` | 菲律宾（PH）展示广告白名单源表 |
| `mp_paidads.shopee_ads_tw_db__display_ads_whitelist_tab__reg_continuous_s0_live` | 台湾（TW）展示广告白名单源表 |
| `mp_user.dim_shop__reg_s0_live` | 店铺维表，用于补全 shop_name，取前一业务日 local 时区分区数据 |

---

## ETL 逻辑摘要

### 数据流

```
各地区 display_ads_whitelist_tab (continuous 流表)
┌─────────────────────────────────────────────────────────────┐
│  shopee_ads_br_db__display_ads_whitelist_tab  (UTC-3, BR)   │
│  shopee_ads_id_db__display_ads_whitelist_tab  (UTC+7, ID)   │
│  shopee_ads_th_db__display_ads_whitelist_tab  (UTC+7, TH)   │
│  shopee_ads_vn_db__display_ads_whitelist_tab  (UTC+7, VN)   │
│  shopee_ads_sg_db__display_ads_whitelist_tab  (UTC+8, SG)   │
│  shopee_ads_my_db__display_ads_whitelist_tab  (UTC+8, MY)   │
│  shopee_ads_ph_db__display_ads_whitelist_tab  (UTC+8, PH)   │
│  shopee_ads_tw_db__display_ads_whitelist_tab  (UTC+8, TW)   │
└─────────────────┬───────────────────────────────────────────┘
                  │ UNION ALL + 本地时区转换
                  │ from_utc_timestamp(from_unixtime(ctime/mtime), <timezone>)
                  ▼
           子查询 a（8个地区合并）
                  │
                  │ LEFT JOIN (on shopid = shop_id)
                  ▼
  mp_user.dim_shop__reg_s0_live                     
  (tz_type='local', grass_date=前一业务日)           
  → 补全 shop_name                                  
                  │
                  ▼
  INSERT OVERWRITE
  dim_display_ads_whitelist_df__reg_s0_live
  PARTITION (grass_region)
```

### 注意事项

1. **`shop_name` 可能为空**：源库白名单表中 `shop_name` 字段为空串（`'' as shop_name`），依赖 LEFT JOIN `mp_user.dim_shop__reg_s0_live` 补全。若 dim_shop 中无对应记录，`shop_name` 将保持为 NULL，下游使用时需做空值兜底处理。

2. **本地时区转换逻辑**：`create_datetime` 和 `modified_datetime` 均由 `from_utc_timestamp(from_unixtime(ctime/mtime), <local_tz>)` 计算得出，各地区时区如下：
   - BR：`America/Araguaina`（UTC-3）
   - ID / TH / VN：`Asia/Jakarta`（UTC+7）
   - SG / MY / PH / TW：`Asia/Singapore`（UTC+8）
   
   跨地区汇总时，`create_datetime` / `modified_datetime` 字符串不具备直接可比性，建议改用 UTC 时间戳（`create_timestamp` / `modified_timestamp`）进行时间对齐。

3. **ETL SQL 中存在字段映射笔误**：注释 SQL 中将 `modified_timestamp`（mtime 的本地化字符串）写入了 `modified_datetime` 列的位置，实际 DDL 中两者类型不同（bigint vs string），建议核实当前生产数据中 `modified_datetime` 的实际内容是否为格式化字符串。

4. **全量覆盖无日期分区**：本表采用 `insert overwrite` 全量刷新，每次调度会覆盖所有地区分区的全量数据，不保留历史快照。若需要历史白名单状态，须查询上游 continuous 流表。

5. **`dim_shop` 依赖**：JOIN `mp_user.dim_shop__reg_s0_live` 时固定取 `tz_type = 'local'` 且 `grass_date = 前一业务日` 的数据，店铺名称反映的是前一天的维度快照，存在极低概率的店铺名滞后风险。

---

*文档生成时间：2026-04-22*