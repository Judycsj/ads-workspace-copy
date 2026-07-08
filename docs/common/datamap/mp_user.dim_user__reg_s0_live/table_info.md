<!-- ads-workspace-gdoc-sync: gdoc_id=1JRc07bvPZllrtPySrrmx7IcglRmBLtBWAnujbRqJ83U gdoc_url=https://docs.google.com/document/d/1JRc07bvPZllrtPySrrmx7IcglRmBLtBWAnujbRqJ83U/edit -->

# mp_user.dim_user__reg_s0_live

## Description

- **Desc:** 用户维度快照表，存储 Shopee 平台用户的基本画像信息（注册信息、身份、人口属性），按天全量分区。由用户数据团队（mp_user 库）维护，Ads 侧作为上游依赖表消费。
- **Granularity:** daily x user (按 grass_date 分区，每行一个 user_id)
- **Use Case:**
  - 广告主维度表构建 — 关联 user_id 获取 user_name、is_seller 等账号信息
  - 广告维度表构建 — 关联 user_id 获取广告创建者的 username
  - 广告用户画像分析 — 按 gender、age（通过 birthday 计算）分析不同用户群的广告表现
  - Search Ads 用户特征 — 复制用户 ID 列表到 search ads feature store
  - 品牌广告登录用户分析 — 按 tz_type='local' 查询特定区域的活跃用户
- **Update Frequency:** Daily (上游 mp_user 维护)

## Key Metrics

此表为维度表，不直接承载业务指标。消费方主要使用以下用户属性：
- **身份属性**: is_seller, is_cb_shop, status, shop_id
- **人口属性**: gender, birthday (衍生 age), language
- **账号属性**: user_id, user_name, registration_datetime

## Key Dimensions

- **分区**: grass_date (日分区), grass_region (地区)
- **主键**: user_id
- **时区**: tz_type ('local' / 'regional')
- **人口**: gender, is_seller, status

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | SG, TH, ID, BR, VN, PH, MY, TW, MX, AR, CO, CL (从代码中推断) |
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

- Studio Tasks References: 63 files (0 write, 63 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
