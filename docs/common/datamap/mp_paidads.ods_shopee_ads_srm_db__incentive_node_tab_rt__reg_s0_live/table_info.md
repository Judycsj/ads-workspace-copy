<!-- ads-workspace-gdoc-sync: gdoc_id=1TZY_jOOLXe7WGIQ-SYoory0FS8MKlz4ws9VgZvJNq48 gdoc_url=https://docs.google.com/document/d/1TZY_jOOLXe7WGIQ-SYoory0FS8MKlz4ws9VgZvJNq48/edit -->

# mp_paidads.ods_shopee_ads_srm_db__incentive_node_tab_rt__reg_s0_live

## Description

- **Desc:** Shopee Ads SRM (Seller Relationship Management) incentive program node status tracking table. ODS real-time table synced from the shopee_ads_srm_db.incentive_node_tab source. Tracks the completion status of each node/task within an incentive program (signup, spending, handout, claim, etc.), used by algorithm teams to analyze seller incentive funnel performance.
- **Granularity:** incentive_id x node_name (one row per incentive node per incentive program)
- **Use Case:**
  - Incentive strategy CB/GMS performance analysis (signup spending funnel tracking)
  - Signup spending incentive hit target rate & budget use rate analysis
  - Uplift model task info enrichment (task_info_v2, task_info_sign_up)
  - Incentive AA/AB experiment dashboard (hit_budget_signup_spending)
  - Positive operation / campaign optimization seller funnel analysis
- **Update Frequency:** ODS real-time sync (RT suffix)

## Key Metrics

- 漏斗类: signup_cnt (node_name='sspd_signup' with node_status=2), spend_enough_cnt (node_name='sspd_spend' with node_status=2), reward_issued_cnt (node_name='sspd_handout' with node_status=2)
- 其他 program type 同理: sfr_spend/sfr_handout/sfr_claim (simple_fixed_reward), camo_objective/camo_handout (campaign_optimization)

## Key Dimensions

- 分区: grass_region
- 业务: node_name (sspd_signup, sspd_spend, sspd_handout, sfr_spend, sfr_handout, sfr_claim, sfr_seq, camo_objective, camo_handout)
- 关联键: incentive_id (JOIN key with dwd_advertiser_program_incentive_credit_df)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | 8 regions (ID,SG,BR,VN,PH,TH,TW,MY) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充。

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | ODS |
| Source DB | shopee_ads_srm_db.incentive_node_tab |

## Popularity

- Studio Tasks References: 17 files (17 read, 0 write)
- L7D Query Count: -
- Completeness: -
- Popularity: -
