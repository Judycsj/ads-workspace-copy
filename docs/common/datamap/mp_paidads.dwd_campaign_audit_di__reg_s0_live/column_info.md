<!-- ads-workspace-gdoc-sync: gdoc_id=1DR3HCQpf1VG-121BrEwkq2SWo1_RWX92nUK4POdrgHQ gdoc_url=https://docs.google.com/document/d/1DR3HCQpf1VG-121BrEwkq2SWo1_RWX92nUK4POdrgHQ/edit -->

# Columns: mp_paidads.dwd_campaign_audit_di__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

以下字段不能直接 SUM 聚合，必须使用 DISTINCT 或取特定事件的值：

- `event_id` — 每个审计事件的唯一标识，跨维度聚合时必须用 `COUNT(DISTINCT event_id)` 计数
- `roi_two_target_value_old` — 变更前的 ROI 值，属于事件级别的快照值，需用 `MAX`/`MIN` 或限定具体 audit_event
- `roi_two_target_value_new` — 变更后的 ROI 值，同上
- `current_target_roi` — 当前时刻的 snapshot 值，需用 `MAX`/`MIN`
- `last1_day_target_roi` / `last7_day_target_roi` — 历史 snapshot 值，需用 `MAX`/`MIN`
- `old_data` / `new_data` — JSON 格式的变更前后完整数据，只能按事件读取。$.daily_quota 字段在源表中为 bigint (100000 scale)，需除以 100000 得到实际货币值
- `old_data_extinfo` / `new_data_extinfo` — JSON 扩展信息，同上。通过 protobuf 解码得到，包含 $.roiTwo.targetValue、$.targetBroadRoi.value 等字段

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| audit_event | 1 | Pause campaign |
| audit_event | 2 | Resume campaign / campaign status normal (used in index_status) |
| audit_event | 3 | Start campaign (ADS_EVENT_START) |
| audit_event | 4 | Create campaign (ADS_EVENT_CREATE) / budget change (new campaign setup) |
| audit_event | 5 | Stop campaign (ADS_EVENT_STOP) |
| audit_event | 6 | Restart campaign (ADS_EVENT_RESTART) |
| audit_event | 8 | Budget change (old_data/new_data: $.daily_quota, scale=100000 in source) |
| audit_event | 9 | Pause campaign (alternative code) |
| audit_event | 49 | Budget change (variant code, used in fraud detection) |
| audit_event | 50 | Target ROI change (roi_two_target_value_old → roi_two_target_value_new) |
| audit_event | 63 | Budget change (variant code, used in fraud detection) |
| audit_event | 64 | Budget change (variant code, used in fraud detection) |
| audit_event | 90 | Rapid Boost Toggle ON (value_before=0, value_after=1) |
| audit_event | 91 | Rapid Boost Toggle OFF (value_before=1, value_after=0) |
| platform | 98 | API / platform-based operation (e.g. upgrade via creationEntryPoint) |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (几乎所有查询都使用)
- `grass_region`: in ('BR','ID','MY','PH','SG','TH','TW','VN') (标准 8 区)
- `audit_event`:
  - in (8, 50, 90, 91) — 激励/wide_table 场景（预算、ROI、Boost 操作）
  - in (1, 5, 9) — 诊断场景（暂停/停止）
  - = 50 — ROI 变更专项分析
- `operator NOT LIKE 'System'` — 排除系统自动操作，只保留手动操作
- `platform = 98` — API/平台操作（如升级 manual → ROI2）
- `audit_event in (4, 49, 8, 63, 64)` — 欺诈检测场景（所有预算相关事件）
- `new_data_extinfo like '%"creationEntryPoint": 8%'` — 特定创建入口点
- JSON 提取:
  - `get_json_object(old_data, '$.daily_quota')` — 提取变更前预算（源表值需除以 100000）
  - `get_json_object(new_data, '$.daily_quota')` — 提取变更后预算
  - `get_json_object(new_data_extinfo, '$.roiTwo.targetValue')` — 提取 ROI 目标值
  - `get_json_object(new_data_extinfo, '$.targetBroadRoi.value')` — 提取 Broad ROI 值
  - `get_json_object(decode(extinfo, 'utf-8'), '$.auto_budget_increase.current_target_roi')` — 自动预算调整当前 ROI
  - `get_json_object(decode(extinfo, 'utf-8'), '$.auto_budget_increase.float_last1_day_target_roi')` — 历史 ROI 快照

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| id | bigint | Primary key / row identifier | - | - |
| event_id | bigint | Unique audit event identifier (non-additive) | - | - |
| campaign_id | bigint | Campaign ID | - | - |
| user_id | bigint | User/account ID who triggered the audit | - | - |
| shop_id | bigint | Shop ID | - | - |
| campaign_status | bigint | Campaign status at time of event | - | - |
| audit_event | bigint | Audit event type code (see Value Mappings) | - | - |
| target_broad_roi | double | Target broad-match ROI value | - | - |
| operator | string | Operator name who performed the action ("System" for auto) | - | - |
| operator_id | bigint | Operator user ID | - | - |
| platform | tinyint | Platform code (98 = API/platform-based) | - | - |
| event_timestamp | bigint | Unix timestamp of the event | - | - |
| event_datetime | string | Formatted datetime string of the event | - | - |
| old_data | string | JSON: full snapshot before the change (包含 $.daily_quota 等) | - | - |
| new_data | string | JSON: full snapshot after the change | - | - |
| roi_two_target_value_old | double | Target ROI value before change (non-additive) | - | - |
| roi_two_target_value_new | double | Target ROI value after change (non-additive) | - | - |
| current_target_roi | double | Current target ROI at event time (non-additive) | - | - |
| last1_day_target_roi | double | Last 1 day target ROI snapshot (non-additive) | - | - |
| last7_day_target_roi | double | Last 7 days target ROI snapshot (non-additive) | - | - |
| new_data_extinfo | string | JSON: extended info after change (包含 $.roiTwo.targetValue, $.productGms.estimate 等) | - | - |
| old_data_extinfo | string | JSON: extended info before change | - | - |
| ad_audit_event_extinfo | string | JSON: additional audit event extension info | - | - |
| grass_region | string | Region code (BR/ID/MY/PH/SG/TH/TW/VN) [PARTITION] | - | - |
| grass_date | date | Date of the event [PARTITION] | - | - |
