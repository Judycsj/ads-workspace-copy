# 模板 / Templates

新技能的脚手架模板。复制到合适的 scope 后开始开发。

## 现有模板

| 模板 | 内容 | 适用场景 |
|------|------|----------|
| `skill-template/` | 含必填 frontmatter 的 `SKILL.md` 骨架 | 任意新技能 |

## 使用方法

```bash
# 复制到目标 scope
cp -r templates/skill-template skills/common/ads-<your-skill>
cp -r templates/skill-template skills/team/01.ads-engineering/ads-<your-skill>
cp -r templates/skill-template skills/personal/<email>/ads-<your-skill>

# 然后编辑 SKILL.md：填写 name、description（含 TRIGGER when / DO NOT TRIGGER when）和正文
```

> 不要直接在 `templates/` 下创建技能——这里的内容不会被 project-local mirror 或 `sra-skills` 发现。

## 添加新模板

在此目录下新增顶层目录即可（如 `templates/agent-template/`）。
模板保持最小化——详细规范请参考 `CLAUDE.md` 和 `skills/README.zh-CN.md`。
