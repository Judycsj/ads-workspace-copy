# ads-autoresearch 技能使用指南 / ads-autoresearch Skill Guide

> **Contributors**: chenjiawei ｜ **最后更新**：2026-06-05 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/guides/common/ads-autoresearch.zh-CN.md)

`ads-autoresearch` 串联 `ads-ar-planner` → `ads-ar-ego` → `ads-ar-conclusion`，
为内容广告（Content Ads）模型调研提供一个端到端的"规划→训练→结论"循环，
每一轮结束后询问是否继续下一轮。

---

## 前提条件 / Prerequisites

### 一次性初始化 / One-time bootstrap

每台工作站只需执行一次，可重复运行（幂等）：

```bash
bash skills/common/ads-autoresearch/scripts/bootstrap-autoresearch.sh
```

脚本会向 `~/.config/sra/credentials.json` 写入：
- **`ego` 配置块** — EGO token 与 Content Ads 默认值（driver `10.168.130.21`、
  HDFS dev 路径在 `mkplpaidads_brand_ads`、Spark 队列 `mkplpaidads-search-dev`），
  其中 `<user_name>` 自动用你的 LDAP 替换。
- **`autoresearch` 配置块** — 编排器策略默认值（`ego_region=sg`、
  `ego_scope=1`、`ego_project=ads_algo`、`trd_team=00.paid-ads-dev`）。

随后会测试 `smc toc <driver_host>` 连通性。**测试失败时请先修复 smc / 网络，
再启动技能** — 脚本会打印具体报错。

EGO token 获取：ego-portal → 右上角头像 → **User Profile → Copy Token**。

### 其它前提

- 已通过 `ads-okr-epic-td` 创建 KP 目录，路径形如
  `docs/team/<trd_team>/10.trd-prd-td-list/<quarter>/<objective>/<kr-kp-YYYYMMDDHHMM>/`
- 已克隆 `/tmp/ego-openapi-v1/`（编排器会通过 `ads-ar-ego` 调用 `ads-ego-training`）
- （可选）`algolab.space_token` + `algolab.user_email` 同样配置在该文件中 —
  仅在循环中需要查询特征 / Slot 时（由 `ads-afp` 处理）才必填

若 KP 目录不存在，技能会中止并提示先运行 `/ads-okr-epic-td`。

---

## 快速开始 / Quick Start

```
/ads-autoresearch
```

编排器以 **KP 为唯一输入单元**：技能会先 `Read` `epic-file.md` 和已有的
`research/round-*/` 产出，再逐项与你确认：

1. **KP 目录** —— KP id（如 `o1-kr2-kp3`）或完整路径，技能会校验
   `epic-file.md` 存在。
2. **基线模型** —— 从 `epic-file.md`（KP 元信息、5.3 关键发现、KA 描述）
   提取；若为 `N >= 2`，额外参考上一轮 `metrics.md` 的 winner。你确认或
   覆盖 `model_id` / `version_id` / `job_id`。
3. **研究方向** —— 从 `epic-file.md` 2.5 方案思路（终版）、KA 描述、
   5.5 下一步计划 以及上一轮 `metrics.md` 的 "Action for next round"
   提取。你确认或调整。
4. **补充材料** —— 论文（PDF）、arxiv 链接、在线搜索关键词、内部文档，
   任意组合或跳过。
5. **上一轮配置沿用**（仅 `N >= 2`） —— 上一轮 `training.md` /
   `metrics.md` 中的集群、训练天数、国家筛选、镜像、优先级、关注指标。
   你确认或指出本轮需要调整的项。
6. **语言偏好** —— `English`、`Chinese`、或 `Both`（单文件双语交错，
   保持现有默认）。作用于本轮所有产出（`plan.md`、`training.md`、
   `metrics.md`）。

随后执行三个阶段，并在每轮结束询问是否继续下一轮。每一轮都会重新走一遍
上面的握手，所以可以按轮调整方向或语言。

在第 2 阶段（训练）中，每个提交的 EGO job —— Round-1 重训基线、每个变体、
以及多日流水线每天的 job —— 都会登记到有效性表
`dev_mkplpaidads_discovery_ads.ad_algos_job_infos`，避免被配额执行器中途
kill（由 `ads-ar-ego` 接入，详见其指南）。

---

## 产出目录 / Output Layout

```
<KP-dir>/
├── research/
│   ├── round-1/
│   │   ├── plan.md             # 来自 ads-ar-planner
│   │   ├── codes/              # Git 跟踪的入口文件副本（来自 ads-ar-planner）
│   │   │   ├── baseline/<entry>.py
│   │   │   ├── variant-a/<entry>.py
│   │   │   └── variant-a.diff
│   │   ├── training.md         # 来自 ads-ar-ego
│   │   └── metrics.md          # 来自 ads-ar-conclusion
│   ├── round-2/
│   └── ...
├── MEMORY.md                   # 每次 Stage 3 结束后由 ads-ar-conclusion 追加一行
└── memory/
    └── YYYY-MM-DD-<user>.md    # 每个阶段结束后由对应子技能追加
```

每一轮都会把基线和变体的**入口文件**（如 `model_all_features.py`）以及 unified diff
持久化到 `codes/`，因此即使 `/tmp` 被清理，整轮调研仍然可以从 Git 中复查。完整代码 zip
可通过 `plan.md` 中由 `ads-ar-ego` 回填的 `model_version_id` 从 EGO 重新拉取。

**路径纪律**：`plan.md` / `training.md` / `metrics.md` 中所有链接都使用
KP 目录内的同级相对路径（如 `codes/variant-a/model_all_features.py`）。
EGO 提交时用的 `/tmp/ads-ar/round-N/` 工作副本**不会**出现在任何提交的
文档里。

---

## 参考资料 / References

- [SKILL.md](../../skills/common/ads-autoresearch/SKILL.md)
- [ads-ar-planner SKILL.md](../../skills/common/ads-ar-planner/SKILL.md)
- [ads-ar-ego SKILL.md](../../skills/common/ads-ar-ego/SKILL.md)
- [ads-ar-conclusion SKILL.md](../../skills/common/ads-ar-conclusion/SKILL.md)
- [ads-ego-training 指南](../team/03.content-algo/ads-ego-training.zh-CN.md)
- [ads-ego-multiday-pipeline 指南](../team/03.content-algo/ads-ego-multiday-pipeline.zh-CN.md)
