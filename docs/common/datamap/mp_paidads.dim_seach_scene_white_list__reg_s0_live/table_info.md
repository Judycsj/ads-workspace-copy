<!-- ads-workspace-gdoc-sync: gdoc_id=1Z0gd83jx278pEbvtwzV4kF8Le1s046rDg29I1EV9fJ0 gdoc_url=https://docs.google.com/document/d/1Z0gd83jx278pEbvtwzV4kF8Le1s046rDg29I1EV9fJ0/edit -->

# mp_paidads.dim_seach_scene_white_list__reg_s0_live

## Description

- **Desc:** 搜索场景白名单维度表。存储被认定为搜索相关场景的 scene_id 和 layer_id，用于在 AB 实验中过滤出搜索类入口的实验组用户。涵盖 Global Search、Image Search、Shop Game、Games、Search Shop 等搜索相关场景。
- **Granularity:** one row per (scene_id, layer_id) — 维度表，无时间粒度
- **Use Case:**
  1. AB 实验用户分群 — 从 AB test hit log / assignment 数据中过滤搜索场景的 group_id 和 user_id
  2. AB 实验层过滤 — 通过 layer_id 识别搜索相关的实验层
- **Update Frequency:** 未知（代码库中未找到生产写入逻辑，可能通过外部流程维护）

## Key Metrics

N/A（维度表，无指标列）

## Key Dimensions

- `scene_id` — 搜索场景标识
- `layer_id` — AB 实验层标识

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | - |
| HDFS Path | - |
| Retention | - |
| Column Count | - |
| Region Coverage | all (reg_s0_live 表，支持全区域) |
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

- Studio Tasks References: 25 files (0 write, 25 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
