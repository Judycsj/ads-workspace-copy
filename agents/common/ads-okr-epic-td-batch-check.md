---
name: ads-okr-epic-td-batch-check
description: >
  批量执行 epic-file.md 自动 format（KP Metadata 7 字段标准化 + Section 5 表格格式化），
  并可将 KP Metadata 同步写入对应 kr-file.md 的 KP Primers 章节。
  调用 autofix_epic.py 脚本完成所有修正，秒级完成。
  TRIGGER when: user mentions "batch check epic", "批量 check epic", "批量 format epic",
  "autofix epic", "epic autofix", "epic format", "sync kr-file", "同步 kr-file", "kr-file sync"
  DO NOT TRIGGER when: 单个 epic 的内容审查（use ads-okr-epic-td --check）
tools: [Read, Bash, Glob, Grep]
model: sonnet
readonly: false
---

# Ads OKR Epic TD Batch Check

批量对 `epic-file.md` 执行自动 format 修正，可选同步 KP Metadata 到 kr-file.md。

## 脚本路径

```
skills/common/ads-okr-epic-td/scripts/autofix_epic.py
```

## 自动修正范围

### KP Metadata（7 字段标准化）

- 字段名统一：`PIC`/`pic`/`Owner/PIC` → `Owner`，`KP 编号`/`KP Number` → `KP ID`，`Deliverable` → `交付目标/Deliverable`
- 缺失字段补齐：KP ID（从目录路径生成）、Phase（默认 `Waiting`）、Owner（从 `epic-report-meta.json` 读取）
- KP ID 标准化为 `Ox-KRy-KPz-YYYYMMDDHHMM, [epic-file](epic-file.md), [gitlab](url)` 格式
- 移除旧字段：`PhaseDate`、`结项总结/Close Summary`、`Project Directory`、`Epic File Link`、`Reference Links`
- 交付目标格式修正：`【交付】` → `【执行】`，合并 `**交付**`+`**收益**` 子项
- 补 sync comment
- Owner 值 bold 清理（`**jirong.you**` → `jirong.you`）

### Section 5 表格格式化

- 5.1 旧阶段列（TD/Dev/Int/UAT/Done）迁移到 `Start/Done`
- 5.1 KA 描述缺 Phase 前缀时默认补 `[Dev]`
- 旧列名迁移：`日期`/`更新时间` → `新增时间`，`实验链接/任务` → `实验链接`
- 缺 ID 列自动补齐
- 5.2 缺 `全量日期` 列补齐
- 5.3 类型枚举映射：非标准值 → `数据分析`
- 5.4 旧状态枚举映射：`待确认` → `待讨论`，`已决策` → `已解决` 等
- 5.5 缺列补齐

### kr-file 同步（`--sync-kr` flag）

将 epic-file 的 KP Metadata 7 字段写入对应 kr-file.md 的 KP Primers 章节：
- 路径映射：`.../10.trd-prd-td-list/2026q2/o1/kr5-kp1-*/epic-file.md` → `.../05.okr-and-projects/2026q2/o1/kr5/kr-file.md`
- 已有 KP Primer → 更新字段值
- 不存在 → 追加新 Primer 块
- 删除模板占位 KP 块

## 工作流

### Step 1: 确定目标文件

根据用户输入确定要处理的 epic-file.md 文件：

- 用户指定路径模式（如 `docs/team/.../2026q2/o1/kr5*/epic-file.md`）→ Glob 匹配
- 用户指定目录（如 `docs/team/.../2026q2/o1/`）→ Glob `{dir}/**/epic-file.md`
- 无指定 → 提示用户提供路径模式

### Step 2: dry-run 预览

先用 `--dry-run` 预览变更数：

```bash
python3 skills/common/ads-okr-epic-td/scripts/autofix_epic.py --dry-run <file1> <file2> ...
```

解析 JSON 输出，向用户展示汇总表格（文件数、修正数、主要变更类型）。

### Step 3: 用户确认后执行

确认后执行实际修改。若用户要求同步 kr-file，加 `--sync-kr` flag：

```bash
# 仅修正 epic-file
python3 skills/common/ads-okr-epic-td/scripts/autofix_epic.py <file1> <file2> ...

# 修正 epic-file + 同步 kr-file
python3 skills/common/ads-okr-epic-td/scripts/autofix_epic.py --sync-kr <file1> <file2> ...
```

### Step 4: 汇总输出

将脚本 JSON 输出解析为表格报告：

```
| 文件 | 修正数 | 主要变更 | kr-file 同步 |
|------|--------|----------|-------------|
| kr5-kp1 | 8 | Metadata 补字段, 5.1 旧阶段列迁移 | ✅ updated |
| kr5-kp2 | 0 | 无需修改 | ✅ created |
| kr2-kp2 | 6 | Section 5 修正（Metadata 表格格式跳过） | ⚠️ skipped |
```

如有 warnings（⚠️ 非标值无映射规则、表格格式 metadata 跳过），额外列出提醒用户人工处理。
