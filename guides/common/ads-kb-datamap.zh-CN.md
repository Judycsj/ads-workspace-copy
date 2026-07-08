# ads-kb-datamap 技能使用指南

> **Contributors**: luka.yang | **最后更新**: 2026-06-16 | [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-kb-datamap.zh-CN.md)

`ads-kb-datamap` 为 Hive 表构建知识库条目，供 `ads-text2da` 等下游技能使用。
从代码库 (`from-code`) 和 DataSuite DataMap UI (`from-di`) 提取表元信息、列定义和 SQL 模式。

---

## 前提条件

- **from-code**: `projects/gitlab/paidads-alg/studio_tasks/` 已克隆到本地
- **from-di**: 浏览器 MCP (Playwright) 已配置，DataSuite 登录会话有效

---

## 何时使用

- 构建或更新 `docs/common/datamap/` 下的表知识库条目
- 为 Hive 表添加 SQL 模式文档
- 用 DataMap UI 数据补充代码提取的元信息（列描述、查询频率等）

---

## 快速开始

```bash
# 单表（默认 from-code）
/ads-kb-datamap mp_paidads.ads_advertiser_mkt_1d__reg_s0_live

# 指定数据源
/ads-kb-datamap mp_paidads.ads_advertiser_mkt_1d__reg_s0_live --source from-code
/ads-kb-datamap mp_paidads.ads_advertiser_mkt_1d__reg_s0_live --source from-di
/ads-kb-datamap mp_paidads.ads_advertiser_mkt_1d__reg_s0_live --source both

# 交互模式（从已有 KB 表中选择）
/ads-kb-datamap
```

---

## 输出文件

每个表在 `docs/common/datamap/{db}.{table_name}/` 下生成三个文件：

| 文件 | 用途 |
|------|------|
| `table_info.md` | 搜索索引 — 表描述、关键指标/维度、技术属性 |
| `column_info.md` | 列参考 — 字段类型、枚举映射、非累加标注 |
| `sql_patterns.md` | 编码上下文 — WHERE/JOIN/聚合模式、SQL 片段、生产血缘 |

---

## 数据源说明

- **from-code**（主）：扫描 `studio_tasks/` 代码库中的 SQL 引用，提取 DDL、查询模式和写血缘
- **from-di**（补）：抓取 DataSuite DataMap UI，补充列描述、查询频率、DQC 状态和业务属性

---

## 使用建议

- 先运行 `from-code` 建立 KB 骨架，再运行 `from-di` 填充 DataMap 专有字段
- 支持逗号分隔多表批量处理
- 幂等运行：`from-code` 覆盖 `sql_patterns.md`，增量更新另外两个文件
