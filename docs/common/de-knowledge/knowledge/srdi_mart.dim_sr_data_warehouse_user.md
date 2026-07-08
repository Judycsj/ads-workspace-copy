<!-- ads-workspace-gdoc-sync: gdoc_id=1xa5JcFbeOSmNx_fv44DVhlUaSEWvYvjDalVWFJ_1kL8 gdoc_url=https://docs.google.com/document/d/1xa5JcFbeOSmNx_fv44DVhlUaSEWvYvjDalVWFJ_1kL8/edit -->

# srdi_mart.dim_sr_data_warehouse_user

**分层：** DIM（维度层）
**主键：** `user_id`
**分区：** `grass_region`（大区）、`local_date`（业务日期）
**更新频率：** 每日全量覆写（INSERT OVERWRITE）
**访问频次：** 783 次

---

## 业务描述

本表是搜推数仓（SRDI）的用户维度表，存储平台用户的基本属性快照信息。每日按大区（`grass_region`）和业务日期（`local_date`）分区全量刷新，对应当日在平台注册并处于活跃状态的用户画像。

**核心业务场景：**
- 为搜索、推荐相关指标表关联用户属性，支持用户分群分析（性别、年龄、地域等）
- 区分新老用户行为差异（`is_new_user`）
- 区分买家与卖家用户（`is_seller`）
- 分析用户注册时间分布与用户状态

**适合回答的问题：**
- 某大区某日活跃用户的年龄/性别/地域分布是怎样的？
- 当日新注册用户数有多少？
- 某用户的默认收货地址在哪个省市区？
- 卖家用户与买家用户的数量占比如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 大区标识，如 `ID`、`TH` 等，对应 Shopee 各运营大区 |
| `local_date` | date | 业务日期，即数据快照对应的本地日期 |

### 维度：用户标识与基本信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | bigint | 用户唯一标识，表主键 |
| `user_name` | string | 用户名称 |
| `user_status` | int | 用户账号状态，源自上游 `status` 字段（具体枚举值参考上游数据字典） |
| `registration_datetime` | string | 用户注册时间（含时分秒的时间字符串） |
| `is_new_user` | int | 是否新用户标识，1 表示新用户，0 表示老用户 |
| `is_seller` | tinyint | 是否为卖家，1 表示卖家，0 表示买家 |

### 维度：用户人口属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `gender` | int | 用户性别，具体枚举值参考上游数据字典（如 1=男，2=女） |
| `birthday` | date | 用户生日 |
| `age` | int | 用户年龄（岁），由 ETL 计算得出：`datediff(grass_date, birthday) / 365.25`，取整后存储 |

### 维度：用户默认收货地址

| 字段 | 类型 | 说明 |
|------|------|------|
| `default_delivery_address_state` | string | 用户默认收货地址所在省/州 |
| `default_delivery_address_city` | string | 用户默认收货地址所在城市 |
| `default_delivery_address_district` | string | 用户默认收货地址所在区/县 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region` 和 `local_date` 两个分区字段**，否则将触发全分区扫描，导致查询性能严重下降，甚至引发资源超限。
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2025-01-01'
  ```
- 若需查询多个大区，使用 `IN` 列表而非省略分区条件：
  ```sql
  WHERE grass_region IN ('ID', 'TH')
    AND local_date = '2025-01-01'
  ```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|------|------|
| `age` | 派生计算字段（浮点除法后取整），聚合均值时应使用 `AVG(age)`，不应直接 `SUM` 后二次除 |
| `gender` | 枚举整型，无加和意义，应使用 `COUNT` + `GROUP BY` |
| `user_status` | 枚举整型，无加和意义 |
| `is_new_user` | 仅作标识位（0/1），SUM 可用于计数，但跨分区（多日）SUM 会导致用户重复计数 |
| `is_seller` | 同上，跨分区使用需去重 |

### 时效性说明

- 本表为**每日全量快照**，数据反映 `local_date` 当日的用户属性状态。
- 历史日期分区保留快照数据，不代表用户当前最新状态；如需最新用户信息，请使用最新 `local_date` 分区。
- ETL 完成时间通常在次日凌晨，当日最新数据以实际调度完成时间为准。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_user.dim_user__reg_s0_live` | 用户维度主源，提供用户基本属性、注册信息、性别、生日、地址、卖家标识等全量字段；按 `grass_date` 和 `grass_region` 过滤对应分区数据 |

---

## ETL 逻辑摘要

### 数据流

```
mp_user.dim_user__reg_s0_live
    （过滤 grass_date = ${local_date} 且 grass_region IN (${grass_region})）
        ↓
    字段重命名 + age 派生计算
        ↓
srdi_mart.dim_sr_data_warehouse_user
    PARTITION(grass_region = ${grass_region}, local_date = ${local_date})
```

### 关键步骤

1. **分区过滤**：从上游 `mp_user.dim_user__reg_s0_live` 中按 `grass_date = ${local_date}` 和 `grass_region IN (${grass_region})` 过滤当日当大区数据。
2. **字段映射**：将上游 `status` 字段重命名为 `user_status`，其余字段直接透传。
3. **年龄计算**：通过 `datediff(grass_date, birthday) / 365.25` 计算用户年龄（以儒略年为单位，结果为浮点数，写入 `int` 类型字段时隐式截断取整）。
4. **分区覆写**：以 `INSERT OVERWRITE TABLE ... PARTITION(grass_region, local_date)` 方式全量覆写目标分区，保证幂等性。

### 注意事项

- **单 Writer**：本表仅有 1 个 ETL 文件写入，无 multi-writer 风险。
- **分区覆写幂等**：每次调度均使用 `INSERT OVERWRITE` 覆盖对应 `(grass_region, local_date)` 分区，重跑安全。
- **age 字段精度**：`age` 由浮点计算（`/ 365.25`）后写入 `int` 列，存在截断而非四舍五入，查询时需注意边界用户（如生日当天前后）的年龄误差。
- **草地日期与本地日期对齐**：ETL 中 `grass_date` 与目标分区 `local_date` 保持一致，确保快照数据的时间语义正确。
- **上游依赖**：本表强依赖 `mp_user.dim_user__reg_s0_live` 的当日分区就绪，调度时需确认上游分区已完成。

---

*文档生成时间：2026-05-17*