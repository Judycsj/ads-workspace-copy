<!-- ads-workspace-gdoc-sync: gdoc_id=1RRf5WVFCK3nz1jeUdrwuVzMPhOUhC2vd-VLET73Uwg4 gdoc_url=https://docs.google.com/document/d/1RRf5WVFCK3nz1jeUdrwuVzMPhOUhC2vd-VLET73Uwg4/edit -->

# Columns: mp_paidads.ods_shopee_ads_srm_db__incentive_node_tab_rt__reg_s0_live

## Column Usage Notes

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| node_name | sspd_signup | Signup spending — seller signed up for the task |
| node_name | sspd_spend | Signup spending — seller met spending target |
| node_name | sspd_handout | Signup spending — reward issued to seller |
| node_name | sfr_spend | Simple fixed reward — seller met spending target |
| node_name | sfr_handout | Simple fixed reward — reward handed out |
| node_name | sfr_claim | Simple fixed reward — seller claimed reward |
| node_name | sfr_seq | Simple fixed reward — sequence/staging node |
| node_name | camo_objective | Campaign optimization — seller participated |
| node_name | camo_handout | Campaign optimization — reward handed out |
| node_status | 2 | Completed / success |

### 常见 WHERE 值 (Common Filter Values)

- `node_status`: always filtered to `= 2` (completed/accepted status)
- `node_name`: most commonly filtered to `'sspd_signup'`, `'sspd_spend'`, `'sspd_handout'` for signup spending analysis
- `node_name IN ('sfr_spend', 'sfr_seq', 'sfr_handout', 'sfr_claim')` for simple fixed reward programs
- `node_name IN ('sspd_signup')` for uplift model signup rate DA

### JOIN 模式

- 主 JOIN 键: `(grass_region, incentive_id)` with `mp_paidads.dwd_advertiser_program_incentive_credit_df__reg_s0_live`
- 多层 LEFT JOIN: 同一表不同 node_name 别名多次 JOIN 获取不同节点状态

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_region | string | Region (ID,SG,BR,VN,PH,TH,TW,MY) | - | - |
| incentive_id | string | Incentive program instance ID | - | - |
| node_name | string | Node/task name in incentive workflow | - | - |
| node_status | int | Node status (2=completed) | - | - |
| extinfo | string | Extended info JSON (contains spending targets, reward configs) | - | - |
