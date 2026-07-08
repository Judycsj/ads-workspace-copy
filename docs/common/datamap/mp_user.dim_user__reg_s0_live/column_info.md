<!-- ads-workspace-gdoc-sync: gdoc_id=1z1lxHtIHvUpTg1BZyqBdfyw99pd62DbRZppods4nFcQ gdoc_url=https://docs.google.com/document/d/1z1lxHtIHvUpTg1BZyqBdfyw99pd62DbRZppods4nFcQ/edit -->

# Columns: mp_user.dim_user__reg_s0_live

## Column Usage Notes

### 常见 WHERE 值 (Common Filter Values)

- `grass_date`: 必选分区条件，通常指定单日（`WHERE grass_date = date('...')`）或时间范围
- `grass_region`: 几乎总是与 grass_date 一同使用，取值如 `upper('${region}')` 或 `in ('SG','TH','ID','BR','VN','PH','MY','TW')`。也支持 MX, AR, CO, CL 等拉美区域
- `tz_type`: 'local'（用于发现广告/社交广告用户分析，约 30% 查询） / 'regional'（默认，生产维度构建）

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| is_seller | 0 | 普通买家 |
| is_seller | 1 | 平台商家 |
| status | 0 | 账号异常/不可用 |
| status | 1 | 账号正常 |
| is_cb_shop | 0 | 非 CB 店铺 |
| is_cb_shop | 1 | CB 店铺 |

### 注意事项

- **无 DDL**: 代码库中未找到 CREATE TABLE 语句，列类型从 SQL 使用推断，实际类型以 DataMap 为准
- **无写引用**: 该表不由 Ads 侧生产，由 mp_user 数据团队维护；如需了解数据刷新时间，请运行 `--source from-di`
- **gender 去重**: 在时间窗口查询中，同一 user_id 可能有多条记录，通常使用 `max(gender)` 取最新值
- **birthday 衍生 age**: 常见用法 `date_diff('year', date(birthday), date(now()))` 或 `2022 - cast(year(b.birthday) as int)` 计算年龄
- **注册时间**: registration_datetime 字段在生产表构建中重命名为 create_datetime，用于与 ads 侧的 account 表对齐

## All Columns

*Column types are inferred from SQL usage context. Verify with DataMap.*

| Column Name | Type (Inferred) | Description | L7/14/30D Query | MAX(column) |
|-------------|-----------------|-------------|-----------------|-------------|
| user_id | bigint/string | 用户唯一标识 | - | - |
| shop_id | bigint | 关联店铺 ID | - | - |
| user_name | string | 用户显示名 | - | - |
| status | int | 用户账号状态 (0=异常, 1=正常) | - | - |
| is_seller | int | 是否为商家 (0=否, 1=是) | - | - |
| is_cb_shop | int | 是否为 CB 店铺 (0=否, 1=是) | - | - |
| gender | int | 用户性别 | - | - |
| birthday | string/date | 用户生日（用于推算年龄） | - | - |
| language | string | 语言偏好（代码中多为 NULL） | - | - |
| registration_datetime | string/timestamp | 注册时间 | - | - |
| modify_datetime | string/timestamp | 最后修改时间 | - | - |
| grass_date | date [PARTITION] | 数据分区日期 | - | - |
| grass_region | string | 地区/国家代码 | - | - |
| tz_type | string | 时区类型 (local/regional) | - | - |
