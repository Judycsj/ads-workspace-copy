<!-- ads-workspace-gdoc-sync: gdoc_id=1LVueaiKOLKvlvo3VXJlCfeOmOqQFZhh1Q0yynEX4ugY gdoc_url=https://docs.google.com/document/d/1LVueaiKOLKvlvo3VXJlCfeOmOqQFZhh1Q0yynEX4ugY/edit -->

# mp_paidads.ods_log_finance_deduction_event_hi__ph_s0_live

## Description

- **Desc:** 财务扣费事件原始日志表（ODS 层），记录每次广告扣费的完整事件信息。包含 translog（事务日志结构体）、cost_details（费用明细数组）等核心字段，是扣费数据的原始入口。
- **Granularity:** 事件级 (event-level)，一条记录 = 一次扣费事件（由 translog.deduct_unique_id 唯一标识）
- **Use Case:**
  1. 按 deduct_unique_id / adsid 定位单次扣费详情（调试、对账）
  2. OCPM 曝光数据分析：从 cost_details 中提取 pCTR 等出价信号，统计 OCPM 曝光数
  3. 新旧上报系统对账：比较 ods_log_finance_deduction_event 与 ods_log_ads_report 的 ls_session_id 差异
  4. 扣费失败诊断：按 error_type 和 status 分析异常扣费事件
  5. 入口组信息提取：从 cost_details.json_data 提取 entrance_group
- **Update Frequency:** Hourly（_hi_ 表，按小时增量写入）

## Key Metrics

从 cost_details 结构化数组中可提取的指标：
- OCPM 曝光类: ocpm_exposure_cnt, ocpm_exposure_with_valid_pctr_cnt, ocpm_sum_pctr, ocpm_avg_pctr
- 扣费金额类: adjusted_cost（调整后扣费金额）
- 扣费状态: status (STATUS_OK / STATUS_PARTIAL_OK / NULL 表示失败)

## Key Dimensions

- 分区: grass_date (日期分区), h (小时分区)
- 扣费标识: translog.deduct_unique_id, translog.adsid, translog.userid
- 扣费类型: translog.operation (11=deduction), translog.placement (40=ROI2, 50=SIMPLE_ROI2)
- 扣费状态: status, error_type
- 地域: grass_region (通过 country 字段映射)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - (未在代码库中找到 DDL) |
| Partition Columns | grass_date (date), h (hour, inferred from SQL patterns) |
| HDFS Path | - |
| Retention | - |
| Column Count | - (未在代码库中找到 DDL，请运行 --source from-di 补充) |
| Region Coverage | PH (Philippines, from _ph suffix) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 6 files (6 read, 0 write)
- L7D Query Count: -
- Completeness: -
- Popularity: -
