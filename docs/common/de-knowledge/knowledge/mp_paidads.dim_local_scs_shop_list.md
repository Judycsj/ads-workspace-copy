<!-- ads-workspace-gdoc-sync: gdoc_id=1iFYWOeZ0XHRAuIUsZYaYnIyulS8zqIrGhzHvcxXsXh4 gdoc_url=https://docs.google.com/document/d/1iFYWOeZ0XHRAuIUsZYaYnIyulS8zqIrGhzHvcxXsXh4/edit -->

# mp_paidads.dim_local_scs_shop_list

**分层**：DIM（维度层）
**主键**：`shop_id`
**分区**：无分区
**更新频率**：手工维护（按需更新）
**引用频次**：2 次（候选表范围内）

---

## 业务描述

本表为付费广告业务域下的**本地 SCS（Sales & Commerce Solutions）店铺白名单维表**，记录由业务团队人工维护的目标店铺列表。表中每条记录代表一个经过业务确认、纳入本地 SCS 项目管理范围的 Shopee 店铺，核心字段为店铺唯一标识 `shop_id`。

该维表的主要使用场景包括：在广告效果分析、ROI 归因或 GMV 统计时，通过关联本表对数据进行店铺维度的范围过滤，确保分析结果仅涵盖 SCS 项目管理的本地店铺，排除无关店铺的噪音干扰。

由于本表通过 Google Sheets 手工维护，店铺名单的新增、下线均由对应业务负责人（`updated_by`）操作并记录变更日期（`modify_date`），可作为店铺资格审核的操作日志使用。

---

## 字段列表

### 维度：主键与店铺标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | string | 店铺唯一标识，对应 Shopee 平台的 shop_id，本表主键 |

### 维度：维护信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `updated_by` | string | 最近一次更新该记录的业务负责人邮箱，用于追溯数据变更责任人 |
| `modify_date` | string | 该条记录最近一次被修改的日期（格式：`YYYY-MM-DD`）⚠️ 存储为 string 类型，日期比较时需显式转换（如 `CAST(modify_date AS DATE)`），直接字符串比较可能产生错误排序 |
| `ingestion_timestamp` | string | 数据从 Google Sheets 同步至数仓的时间戳，反映最近一次同步时间，非业务变更时间 ⚠️ 该字段为系统写入时间，不代表业务口径的数据时效，不应用于业务逻辑判断 |

---

## 查询使用须知

本表为维表，直接 `SELECT` 或 `JOIN` 使用，无聚合场景。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| Google Sheets（手工维护表单） | 业务人员直接在 Sheets 中录入/修改 SCS 店铺名单，由数仓管道定期同步至本表 |

---

## ETL 逻辑摘要

### 维表说明

本表为 **Google Sheets 驱动的手工维护维表**，不存在 SQL ETL 逻辑。数据由业务运营团队（当前主要维护人为 `ella.yuan@shopee.com`）直接在 Google Sheets 中录入和管理，通过数仓的 Sheets 数据接入管道定期拉取同步至 `mp_paidads.dim_local_scs_shop_list`。

**内容结构说明：**

| 字段 | Sheets 对应列 | 维护说明 |
|------|--------------|----------|
| `shop_id` | shop_id | 核心管理字段，需填入有效的 Shopee 店铺 ID |
| `updated_by` | updated_by | 由编辑人填写自身邮箱，用于追踪变更责任人 |
| `modify_date` | modify_date | 由编辑人手动填写修改日期，格式应为 `YYYY-MM-DD` |
| `ingestion_timestamp` | 无对应列 | 由同步管道自动写入，Sheets 中不存在此列 |

**注意事项：**

1. **数据时效性**：表内容以最近一次 Sheets 同步为准，若 Sheets 已更新但同步任务尚未执行，数仓中的数据可能存在延迟，使用前可通过 `ingestion_timestamp` 确认最近同步时间。
2. **数据质量依赖人工**：`shop_id` 的有效性、`modify_date` 的格式正确性均依赖人工录入规范，下游使用时建议做基础校验（如 `shop_id IS NOT NULL`）。
3. **名单变更需主动通知**：若下游任务有 SCS 店铺范围缓存，名单变更后需重新确认同步任务已执行，否则过滤结果可能不一致。

---

*文档生成时间：2026-04-22*