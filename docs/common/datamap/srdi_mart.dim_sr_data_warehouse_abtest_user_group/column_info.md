<!-- ads-workspace-gdoc-sync: gdoc_id=1PtxJHazI7kPVe6WrcWpx2d5ra1eJshGsr41OMmc-eqU gdoc_url=https://docs.google.com/document/d/1PtxJHazI7kPVe6WrcWpx2d5ra1eJshGsr41OMmc-eqU/edit -->

# Columns: srdi_mart.dim_sr_data_warehouse_abtest_user_group

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

无。本表为维表，所有列为维度属性，不存在 SUM(DISTINCT) 聚合模式。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| is_assignment_log | 1 | 用户命中该实验组分配 |
| is_assignment_log | 0 | 用户未命中 |
| is_dim_join | 1 | D&D/YMAL 场景的实验分配（用于 entrance in (3,4,8,9,10,11)） |
| is_dim_join | 0 | 非 D&D/YMAL 场景 |
| is_search_whitelist | 1 | Search 领域白名单用户 |
| is_rcmd_whitelist | 1 | RCMD 领域白名单用户 |
| is_rcmd_service | 1 | RCMD 服务白名单用户 |
| is_ads_whitelist | 1 | Ads 领域白名单用户 |
| project_name | 'Ads' | 广告项目（最常用过滤值） |
| scene_id | 1361 | paidads universal（通用广告场景，最常用） |
| scene_id | 588 | Video 场景（D&D/YMAL 中需要排除） |
| scene_id | 171 | 另一个 Video 场景（D&D/YMAL 中需要排除） |

### 常见 WHERE 值 (Common Filter Values)

- `local_date`: 通常为 `${grass_date}` 或 `${start_date}` ~ `${end_date}` 范围
- `grass_region`: 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN','BR')，常用 `upper('${region}')`
- `is_assignment_log = 1`: 几乎全部查询都使用此过滤
- `is_search_whitelist = 1`: Search 领域实验专用
- `is_rcmd_whitelist = 1 and is_rcmd_service = 1`: RCMD_Ads 领域实验
- `is_ads_whitelist = 1`: Ads 领域实验
- `is_dim_join = 1`: D&D/YMAL 推荐场景实验
- `project_name = 'Ads'`: 限定广告项目
- `scene_id = 1361`: 限定通用广告场景
- `layer_id`: 实验层 ID，各实验不同（如 158805, 162131, 164284, 138080）

## All Columns

> 列类型从 SQL 使用模式推断，非 DDL 提取。运行 `--source from-di` 可获取完整 column description 和 query frequency。

| Column Name | Type | Description |
|-------------|------|-------------|
| local_date | date [PARTITION] | 实验日期分区 |
| grass_region | string | 区域（如 ID, MY, PH, SG, TH, TW, VN, BR） |
| user_id | bigint | 用户 ID |
| exp_group_id | bigint | 实验组 ID（group_id），标识用户所属的实验桶 |
| is_assignment_log | int | 是否为实验分配日志（1=是） |
| is_dim_join | int | 是否为 D&D/YMAL 维表 JOIN 分配（1=是，用于推荐场景） |
| is_search_whitelist | int | 是否在 Search 白名单中（1=是） |
| is_rcmd_whitelist | int | 是否在 RCMD 白名单中（1=是） |
| is_rcmd_service | int | 是否在 RCMD 服务白名单中（1=是） |
| is_ads_whitelist | int | 是否在 Ads 白名单中（1=是） |
| project_name | string | 项目名称（如 'Ads'） |
| scene_id | bigint | 实验场景 ID |
| layer_id | bigint | 实验层 ID |
