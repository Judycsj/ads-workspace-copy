<!-- ads-workspace-gdoc-sync: gdoc_id=14jXVMeBdNphWMGDeEdl25zOtrwV2DAVBnwn10XeeJTI gdoc_url=https://docs.google.com/document/d/14jXVMeBdNphWMGDeEdl25zOtrwV2DAVBnwn10XeeJTI/edit -->

# opa_audiencemanager_crm_analystics.dim_crm_user_task_view_vn

## Description

- **Desc:** CRM 用户任务视图表（越南站），由 OPA Audience Manager 团队维护，用于存储每期用户分群任务的目标用户及标签。Ads 团队将其作为 Smart Voucher 人群黑名单的对照组/实验组用户来源。
- **Granularity:** 单用户级（user_id），以 version_id 区分不同批次的用户任务
- **Use Case:**
  - Smart Voucher AB 实验用户分流：从表中提取 VN 站用户，按 user_label_list / is_target 字段分类为 control 组和 mp_plus_ads 组，写入 `ads_smart_voucher_blacklist_user` 系列表
  - 历史用户分群数据查询：按 version_id 和日期查看各版本任务的目标用户分布
- **Update Frequency:** 按需更新（由 CRM Audience Manager 团队在发起用户任务时写入）
- **Producer:** OPA Audience Manager CRM Team（外部团队，非 Ads 团队生产）

## Key Metrics

{from-code: 无需聚合指标，表仅提供 user_id 维表信息}

- 用户计数: `count(distinct user_id)` 按 grass_date, grass_region, user_label_list 分组

## Key Dimensions

{from-code: 从 WHERE/GROUP BY 归纳}

- 分区/定位: grass_region (固定 'VN'), grass_date
- 任务标识: version_id
- 用户标签: user_label_list (key-value 格式), is_target

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | VN (仅越南站) |
| DQC Status | - |
| Table Size | - |

## Business Properties

{未抓取 DataMap，请运行 --source from-di 补充}

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 15 files (2 workflows, 4 scheduled_tasks, 9 manual_tasks)
- L7D Query Count: -
- Completeness: -
- Popularity: -
