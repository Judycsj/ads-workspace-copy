<!-- ads-workspace-gdoc-sync: gdoc_id=112flT-AJ1hIJYOe-dyv5sQYSoYPdrNGQhPMaxOE6ovE gdoc_url=https://docs.google.com/document/d/112flT-AJ1hIJYOe-dyv5sQYSoYPdrNGQhPMaxOE6ovE/edit -->

# srdi_mart.dim_sr_data_warehouse_tc_biz_project

**分层：** DIM（维度层）
**主键：** `project_id`（注意：`project_id` 非全局唯一键，同一项目可跨 region 存在多条记录，联合 `grass_region` 使用）
**分区：** `grass_region` / `regional_date` / `regional_hour`
**更新频率：** 按小时全量覆写（INSERT OVERWRITE）
**引用频次 / 访问频次：** 0

---

## 业务描述

本表是搜推数仓（SRDI）流量管控（Traffic Control）业务项目（Project）的维度表，记录每个业务项目的基本属性、生效时间窗口、关联规则及场景信息。数据来源于 ODS 层项目原始表与规则维度表，经过聚合加工后形成以项目为粒度的宽表快照。

**核心业务场景：**
- 查询各大区（region）下业务项目的配置详情，包括项目名称、描述、负责人、成员及状态；
- 关联规则维度，分析项目下挂载的规则集合（`rule_ids`、`local_rule_ids`）及规则覆盖的业务场景（`scenes`）；
- 确定项目的生效时间范围（`start_time`、`end_time`），支持时效性过滤；
- 作为搜推流量管控链路中项目维度的标准查询入口，供下游指标层或应用层 JOIN 使用。

**适合回答的问题：**
- 某大区某时刻下，哪些业务项目处于启用/禁用状态？
- 某项目关联了哪些规则，覆盖哪些流量场景？
- 某项目的生效起止时间是什么？
- 某项目由谁创建，当前有哪些成员参与？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 SG、MY、TH 等），分区键，查询必须指定 |
| `regional_date` | date | 数据所属业务日期，分区键 |
| `regional_hour` | int | 数据所属业务小时（0~23），分区键 |

### 维度：项目基本属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `project_id` | bigint | 项目 ID；注意非全局唯一键，同一项目可跨 region 存在，需结合 `grass_region` 联合定位 |
| `pname` | string | 项目名称 |
| `pdesc` | string | 项目描述 |
| `pics` | string | 项目图片（原始字段注释标注为 pic/pics，存储图片资源标识） |
| `members` | string | 项目成员列表 |
| `creator` | string | 项目创建人 |
| `state` | int | 项目状态（具体枚举值参考业务定义，规则层 state=3 表示场景启用） |
| `is_deleted` | int | 软删除标识，1 表示已删除，0 表示有效 |
| `uniq_priority` | bigint | 项目唯一优先级 |
| `layer_ids` | string | 项目关联的层级 ID 列表 |
| `create_time` | bigint | 项目创建时间（Unix 时间戳，毫秒） |
| `update_time` | bigint | 项目最近更新时间（Unix 时间戳，毫秒） |

### 维度：规则与场景关联

| 字段 | 类型 | 说明 |
|---|---|---|
| `scenes` | string | 项目下状态为启用（state=3）的规则所覆盖的业务场景集合，多个场景以逗号拼接（来源：`dim_sr_data_warehouse_tc_rule.scenes` 展开后按 project_id 聚合） |
| `local_rule_ids` | string | 当前 grass_region 下项目关联的规则 ID 列表，逗号分隔（从本 region 规则表聚合） |
| `rule_ids` | string | 全量规则 ID 列表（不限 region，从规则表全量聚合），逗号分隔 |
| `start_time` | bigint | 项目下所有规则的最早生效开始时间（取 min(start_time)，Unix 时间戳） |
| `end_time` | bigint | 项目下所有规则的最晚生效结束时间；若存在永久规则（end_time=-1）则整体取 -1，否则取 max(end_time)（Unix 时间戳） |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定，否则将扫描所有大区分区，造成大量冗余数据扫描。
- **`regional_date`**：必须指定，推荐使用最新业务日期。
- **`regional_hour`**：必须指定，推荐使用最新小时分区。三个分区字段应同时使用，示例：
  ```sql
  WHERE grass_region = 'SG'
    AND regional_date = '2026-05-18'
    AND regional_hour = 10
  ```
- **`is_deleted = 0`**：如需排除已软删除项目，需在查询中手动过滤。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `scenes` | 逗号拼接的字符串集合，需先 `explode` 拆分后再做聚合统计 |
| `local_rule_ids` | 逗号拼接的规则 ID 集合，不可直接 SUM，需拆分处理 |
| `rule_ids` | 同上，逗号拼接的 ID 集合 |
| `layer_ids` | 同上，字符串类型 ID 集合 |
| `start_time` / `end_time` | 语义为时间戳，直接 SUM 无业务意义；`end_time=-1` 表示永久，需特殊处理 |
| `uniq_priority` | 优先级标识，不具备加和语义 |

### 时效性说明

- 本表为**小时级快照表**，每小时全量覆写当前分区（INSERT OVERWRITE），反映该小时的项目配置状态。
- 历史查询需指定对应的 `regional_date` + `regional_hour` 分区组合。
- 数据以 ODS 层最新快照为准，若上游更新延迟，当前小时数据可能滞后。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.ods_sr_data_warehouse_shopee_traffic_mangement_db__project_tab` | 提供项目基础属性（名称、描述、成员、创建人、状态、优先级等），对应 `project_data` 临时视图 |
| `srdi_mart.dim_sr_data_warehouse_tc_rule` | 提供规则维度数据，用于聚合生成项目的场景列表、生效时间范围及规则 ID 列表（分别对应 `rule_data` 和 `rule_ids` 临时视图） |

---

## ETL 逻辑摘要

### 数据流

```
ods_sr_data_warehouse_shopee_traffic_mangement_db__project_tab
        │
        ▼
  project_data（临时视图）─────────────────────────────────┐
                                                            │
dim_sr_data_warehouse_tc_rule                              INNER JOIN（on project_id = id）
        │                                                   │
        ├──► rule_data（临时视图，限 grass_region）          │
        │         │                                         │
        └──► rule_ids（临时视图，全量）                      │
                  │                                         │
                  └─────────────────────────────────────────┘
                                    │
                                    ▼
              dim_sr_data_warehouse_tc_biz_project（INSERT OVERWRITE）
```

### 关键步骤

1. **Statement 1 — `project_data` 临时视图**
   从 ODS 项目原始表中读取当前分区（`regional_date` + `regional_hour`）的项目基础属性，字段包括 id、pname、pdesc、pics、members、state、creator、is_deleted、uniq_priority、layer_ids、create_time、update_time。

2. **Statement 2 — `rule_data` 临时视图（限 region）**
   从 `dim_sr_data_warehouse_tc_rule` 中按当前分区及 `grass_region` 过滤，以 `project_id` 分组聚合：
   - `scenes`：收集 state=3（启用）规则展开后的 scene 值，逗号拼接；
   - `start_time`：取所有规则的 `min(start_time)`；
   - `end_time`：若存在 end_time=-1 的规则，整体返回 -1，否则取 `max(end_time)`；
   - `local_rule_ids`：收集本 region 下所有 rule_id，逗号拼接。
   使用 `lateral view explode(from_json(scenes, 'ARRAY<string>'))` 展开规则的 scenes JSON 数组。

3. **Statement 3 — `rule_ids` 临时视图（全量，不限 region）**
   从 `dim_sr_data_warehouse_tc_rule` 中按当前分区过滤（不加 grass_region 限制），以 `project_id` 分组聚合所有 rule_id，逗号拼接为 `rule_ids`，用于补充跨 region 的完整规则引用。

4. **Statement 4 — INSERT OVERWRITE 写目标表**
   以 `rule_data` 为主表（驱动表），分别与 `project_data`（on project_id = id）和 `rule_ids`（on project_id）做 **INNER JOIN**，输出所有字段后覆写目标表对应 grass_region 分区。
   - 仅在 `rule_data` 和 `project_data` 和 `rule_ids` 三表中均存在的项目才会写入，任意一侧缺失将导致该项目被过滤。

### 注意事项

- **`project_id` 非唯一键**：同一 project_id 可跨 region 存在，必须联合 `grass_region` 作为业务主键，不可单独以 `project_id` 做全局 JOIN 或去重。
- **INNER JOIN 过滤风险**：写入逻辑采用三表 INNER JOIN，若某项目在规则表中无任何记录（即 `rule_data` 或 `rule_ids` 无对应 project_id），则该项目不会出现在目标表中，下游使用时需注意潜在数据缺失。
- **`end_time=-1` 特殊语义**：表示规则永久生效，聚合逻辑中优先返回 -1，下游处理须单独判断，不可与普通时间戳做数值比较。
- **INSERT OVERWRITE 分区覆写**：每次仅覆写当前 `grass_region` + `regional_date` + `regional_hour` 分区，历史分区数据不受影响，但同分区内旧数据将被完全替换。
- **单 Writer**：本表仅有一个 ETL 文件写入，无 multi-writer 并发冲突风险。

---

*文档生成时间：2026-05-18*