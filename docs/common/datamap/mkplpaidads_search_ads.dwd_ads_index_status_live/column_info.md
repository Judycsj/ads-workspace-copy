<!-- ads-workspace-gdoc-sync: gdoc_id=1ZtzXpQ8nVxE_dVOl-bOm2hCZuhLkFuYTkQsXt5ZZ68k gdoc_url=https://docs.google.com/document/d/1ZtzXpQ8nVxE_dVOl-bOm2hCZuhLkFuYTkQsXt5ZZ68k/edit -->

# Columns: mkplpaidads_search_ads.dwd_ads_index_status_live

## Column Usage Notes

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| type | 1 | ads 粒度 |
| type | 2 | item 粒度（仅 status=7 商品状态异常） |
| type | 3 | campaign 粒度（status=4 计划异常, status=1 预算修改, status=2 troi修改） |
| type | 4 | shop 粒度（仅 status=8 店铺状态异常） |
| status | 0 | 正在在投 |
| status | 1 | 预算修改（来自 campaign_audit, audit_event=8） |
| status | 2 | TROI 修改（来自 campaign_audit, audit_event=50） |
| status | 3 | 流量控制异常（anti_fraud_block 或 deboost） |
| status | 4 | 计划状态异常 |
| status | 5 | 广告状态异常 |
| status | 6 | 算法状态异常 |
| status | 7 | 商品状态异常 |
| status | 8 | 店铺状态异常 |
| operation | INDEX | 索引/上线操作 |
| operation | DELETE | 删除/下线操作 |
| visible | 0 | 不可见（DELETE 操作或异常状态） |
| visible | 1 | 可见（正常在投或预算/TROI 修改事件） |

### reason 文本模式 (Reason Patterns)

`reason` 为自由文本字段，下游通过 LIKE 或 regexp_extract 解析：

**status=4 (计划状态异常):**
- `campaign status expected%`, `campaign end time expected%`, `campaign start time expected%`, `campaign remaining daily quota%`
- `campaign_status_abnormal`（来自 audit_event=1）, `campaign_status_normal`（来自 audit_event=2）
- `%ADS_PAUSED%`（卖家主动暂停）, `%ADS_CLOSED%`（卖家主动停止）

**status=1 (预算修改):**
- `change_budget old_budget={old} new_budget={new}`（数值单位: 原始值/100000）
- budget=0 表示无限预算

**status=2 (TROI修改):**
- `change roi two target roi old_value={old} new_value={new}`

**status=3 (流量控制异常):**
- `anti_fraud_block_prob_{prob}`, `deboost_prob_{prob}_scene_{dd|ymal|search}`

**status=5:** `advertise status expected%`
**status=6:** `Algo status expected%`
**status=7:** `item stock expected%`, `no item and image embedding%`, `item is blacklisted%`, `item status not normal%`, `no valid phrase match keywords%`, `has invisible keyword%`, `item with no shipping%`, `no visible keyword%`, `item flag unlisted%`, `no valid keywords%`
**status=8:** `account money not enough%`, `shop on holiday%`, `account's status not normal%`, `account inactive%`, `account's phone didn't verified%`

### 常见 WHERE 值 (Common Filter Values)

- `type`: 3 (campaign 粒度，占下游 ~90% 查询)
- `status`: 1,2 (预算/TROI修改), 4 (计划异常)
- `operation`: 'INDEX', 'DELETE'
- `grass_region`: 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN','BR')

### id 字段语义 (Multi-meaning ID)

`id` 列的含义取决于 `type`：
- type=1: id = ads_id
- type=2: id = item_id
- type=3: id = campaign_id
- type=4: id = shop_id

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| id | bigint | 实体 ID（含义取决于 type） | 121/243/529 | - |
| type | int | 粒度类型: 1=ads, 2=item, 3=campaign, 4=shop | 121/243/529 | - |
| visible | int | 可见性: 0=不可见, 1=可见 | 65/131/289 | - |
| reason | string | 状态变更原因文本 | 121/243/529 | - |
| operation | string | 索引操作: INDEX/DELETE | 121/243/529 | - |
| timestamp | bigint | 事件时间戳（秒级，统一处理） | 121/243/529 | - |
| hour | int | 事件对应小时数 (0-23) | 65/131/289 | - |
| status | int | 状态分类: 0-8 | 121/243/529 | - |
| grass_date | string | [PARTITION] 日期分区 | 121/243/529 | - |
| grass_region | string | [PARTITION] 地域分区 (partition key) | 121/243/529 | - |

## 查询频率分析

- 10 列中 8 列 L30D 查询次数 529 次（日均 ~16 次查询），2 列（visible, hour）查询频率较低（289 次），说明下游查询通常使用 `SELECT *` 或 `SELECT id, type, status, reason, operation, timestamp`
- visible 和 hour 查询频率较低，说明这两个字段不常被单独用作过滤条件或 SELECT 列
- DataMap Completeness 仅 12.00（列描述缺失），但 Popularity 83.60 说明该表使用活跃
