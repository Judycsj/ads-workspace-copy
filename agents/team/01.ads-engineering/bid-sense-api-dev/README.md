# bid-sense-api-dev 配置文件/Config Files

> **Contributors**: wanghui.guo ｜ **最后更新**：2026-05-19 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/agents/bid-sense-api-dev/README.md)

使用 `bid-sense-api-dev` agent 前，需要在本地创建以下配置文件（已 gitignore，不会提交）。

## 首次使用 Setup

```bash
cd agents/bid-sense-api-dev

# 1. 复制模板
cp bid-sense-redis.json.template bid-sense-redis.json
cp bid-sense-test-env.json.template bid-sense-test-env.json

# 2. 填入实际值（向 bid-sense 团队获取）
#    bid-sense-redis.json      → roi2 Redis 测试环境地址和密码
#    bid-sense-test-env.json   → test env HTTP endpoint 和 service key
```

## 文件说明

| 文件 | 用途 | 从哪里获取 |
|------|------|----------|
| `bid-sense-redis.json` | roi2 Redis 测试环境连接信息 | bid-sense 团队内部 |
| `bid-sense-test-env.json` | test env HTTP endpoint + service key | bid-sense 团队内部 |
| `bid-sense-fse-schemas.json` | FSE 表 schema | DE 提供后手动创建 |

## bid-sense-fse-schemas.json 格式

DE 提供 FSE 表信息后，按以下格式创建（`.template` 暂未提供，因 schema 因 API 而异）：

```json
{
  "tables": [
    {
      "name": "table_name",
      "primary_key": { "name": "shop_id", "type": "int64" },
      "fields": [
        { "name": "feature_a", "type": "float64" },
        { "name": "feature_b", "type": "int32" }
      ]
    }
  ]
}
```
