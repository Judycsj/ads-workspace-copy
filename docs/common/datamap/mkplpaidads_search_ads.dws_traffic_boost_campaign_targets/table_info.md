<!-- ads-workspace-gdoc-sync: gdoc_id=1HgE6RmkWg-NhxO6lyClhwI2xPJoa0vwzIpMANK7iMR4 gdoc_url=https://docs.google.com/document/d/1HgE6RmkWg-NhxO6lyClhwI2xPJoa0vwzIpMANK7iMR4/edit -->

# mkplpaidads_search_ads.dws_traffic_boost_campaign_targets

## Description

- **Desc:** Traffic Boost 补贴目标表，记录各 campaign 在每天的目标达成状态 (orders/gmv)、剩余订单/天数，用于 budget allocation solver 和 reward model 校准训练数据生成。
- **Granularity:** daily x campaign x tag_bit x target_type x grass_region (one campaign can have multiple target rows per tag_bit per type)
- **Use Case:**
  1. Budget allocation solver 输入 (s02 discretiser_input): 为每个 campaign 提供 remaining_day_cnt 和 target 指标
  2. Reward model 校准数据生成 (reward_cali_data): 从历史 snapshot 反查 campaign 是否达成目标 (meet_target)
  3. Training data 生成 (get_training_data): 为 LGBM 模型提供 label 和 progress features
  4. Daily campaign progress tracking (causal_boost): 追踪 campaign 每日剩余订单/天数和达成进度
  5. Ad-hoc 排查 (manual_tasks): 临时查询个别 campaign 的目标状态
- **Update Frequency:** Daily (T+1 batch, insertInto overwrite by grass_date partition)

## Key Metrics

| Category | Metrics |
|----------|---------|
| 目标类 | target (统一目标值), orders_target (订单目标数), days_target (目标天数), gmv_target (GMV目标值) |
| 进度类 | days_remaining (剩余天数), orders_remaining (剩余订单数) |
| 历史表现 | rev_local/usd (l7d支出), broad_order_cnt (l7d broad订单), direct_order_cnt (l7d direct订单), l14d_broad_order_cnt, l14d_direct_order_cnt |
| GMV基线 | avg_direct_gmv_local, avg_broad_gmv_local, avg_direct_gmv_usd, avg_broad_gmv_amt_usd (l7d日均GMV) |

## Key Dimensions

- **分区**: grass_date (daily snapshot date, T-1)
- **业务**: grass_region (标准8区), campaign_id, shop_id, tag_bit (biz_tag), target_type (broad_order/direct_order/gmv)
- **标记**: ad_tag_contain_biz_tag (是否命中特定biz_tag), ad_tag (campaign下ads的ad_tag位掩码)

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Hive Managed (由 Spark insertInto 自动管理) |
| Partition Columns | grass_date (DATE/STRING) |
| HDFS Path | 由 Hive warehouse 管理 |
| Retention | - |
| Column Count | 26 (inferred from DataFrame schema in target_calculation.py) |
| Region Coverage | SG, TH, MY, ID, PH, TW, VN, BR (标准 8 区) |
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

- Studio Tasks References: 50 files (1 write, 49 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
