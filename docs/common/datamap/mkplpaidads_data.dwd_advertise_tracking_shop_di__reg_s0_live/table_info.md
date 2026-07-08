<!-- ads-workspace-gdoc-sync: gdoc_id=1Jziy0ra9cOvBec0ulFe_Nv4FOObnDH3RBAuz91KFpDw gdoc_url=https://docs.google.com/document/d/1Jziy0ra9cOvBec0ulFe_Nv4FOObnDH3RBAuz91KFpDw/edit -->

# mkplpaidads_data.dwd_advertise_tracking_shop_di__reg_s0_live

## Description

- **Desc:** Shop Ads 日级埋点追踪 VIEW，从小时级表 `dwd_advertise_tracking_shop_hi__reg_s0_live` 按天生成。记录用户在搜索、推荐等场景中对 Shop Ads 的交互行为（曝光 1001、点击 1002），包含广告投放信息、店铺信息、模型特征（bid_rerank_trace, shop_json_data）等字段。grass_date 通过 grass_region 的本地时区转换得出。
- **Granularity:** event-level (per request_id x operation x ads_id x ads_placement)
- **Use Case:**
  - 反作弊/反欺诈分析 -- 与 `dwd_advertise_tracking_item_di__reg_s0_live` UNION ALL 进行联合反欺诈检测
  - Shop Ads 基线指标 (baseline) 计算 -- 按 placement 维度统计曝光、点击、GMV，用于 adstype baseline 生产
  - Tracking vs Performance 差异对比 -- 与 `dwd_advertise_performance_di__reg_s0_live` 对比 tracking 数据一致性
  - 品牌词/类目词订单归因 -- 与 reserved keywords 表关联，区分品牌词点击
- **Update Frequency:** Daily (从 hi 表 VIEW 生成)

## Key Metrics

无直接业务指标列（该表为事件追踪表）。核心事件计数：

- 曝光: `operation = 1001` (SHOP_IMPRESSION)
- 点击: `operation = 1002` (SHOP_CLICK)

常用聚合方式: `SUM(IF(operation=N, 1, 0))` 或 `COUNT(1)` / `COUNT(*)`

## Key Dimensions

- 分区: grass_date, grass_region
- 业务: operation, ads_placement, ads_entrance, tracking_placement, pricing_type
- 实体: user_id, shop_id, ads_id, ads_request_id, unique_id

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | VIEW (不占用物理存储，CREATE OR REPLACE VIEW) |
| Partition Columns | grass_date, grass_region (上游 hi 表分区) |
| HDFS Path | N/A (VIEW) |
| Retention | N/A (VIEW) |
| Column Count | 78 (VIEW 定义列数) |
| Region Coverage | SG, MY, ID, PH, TH, VN, TW, BR, MX, CO, CL (全区域覆盖) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | DWD |

## Popularity

- Studio Tasks References: 34 files (6 write/view, 28 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
