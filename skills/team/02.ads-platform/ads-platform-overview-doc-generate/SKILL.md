---
name: ads-platform-overview-doc-generate
description: >
  Ads Platform Overview Doc Generate (投放平台结构化文档自动化生成器) — run Seller Center Shopee Ads
  route inspection and collect function screenshots.
  TRIGGER when: user asks to automate Seller Center Shopee Ads documentation,
  refresh the platform frontend section 4.1, collect Seller Center Ads
  function screenshots, run
  "ads-platform-overview-doc-generate", or mentions "投放平台文档自动化",
  "Seller Center Shopee Ads 巡检", "自动截图生成文档".
  DO NOT TRIGGER when: user wants Ads Platform backend architecture docs,
  Ads Engine/Bidding architecture generation, generic Ads Q&A, or inspection
  for non-Seller Center platforms.
category: workflow
tags: [ads, platform, seller-center, documentation, screenshot, playwright]
---

# Ads Platform Overview Doc Generate

Seller Center Shopee Ads 结构化文档自动化：登录 → 按路由采集截图 → 同步写入 core-knowledge。

## Workflow

1. 配置路由和凭证（首次或路由变更时）：
   - 编辑 `scripts/routes.json`（凭证直接写在 `login.account` / `login.password`）

2. 执行截图（首次运行自动安装 Chromium，无需手动操作）：

```bash
uv run scripts/executor.py [--route <name>] [--headed] [--dry-run]
```

3. 同步截图到文档：

```bash
uv run scripts/sync.py --run-id latest
```

## Route Config

`scripts/routes.json` 采用统一对象结构：顶层 `login` + `routes`。

`login` 仅支持环境变量配置；`route` 不支持单独覆盖登录配置。
执行器先完成一次共享登录，再依次访问各 route。

`route.doc` 控制文档同步（可选）：

```json
{
  "login": {
    "account": "your_account",
    "password": "your_password"
  },
  "routes": [
    {
      "name": "seller_center_homepage",
      "url": "https://seller.test.shopee.sg/portal/marketing/pas/index",
      "custom_css": ".ads-banner { display: none !important; }",
      "doc": {
        "section_id": "4.1.1.1",
        "images": [{ "source": "overview_module", "caption": "Ads homepage overview" }]
      }
    }
  ]
}
```

说明：
- 文档定位只使用 `section_id`，不做标题文本匹配。
- 文档中使用一对标记控制每个截图的注入位置，脚本完整替换标记区间内容：

```
<!-- AUTO_SCREENSHOT_START ADS_INTRO_4_1:image:4.1.2:overview_module -->
...脚本维护此区间...
<!-- AUTO_SCREENSHOT_END -->
```

`source` 与 `route.doc.images[*].source` 对应。
- `custom_css`（可选）：注入到当前 route 页面中的样式，仅对该 route 生效（页面导航后可继承当前 route 的 DOM，不会影响其他 route）。
- `custom_css` 建议用于隐藏干扰元素（如弹窗、toast、浮层），避免影响截图；支持标准 CSS 文本（可多行）。

执行器不默认生成初始截图；如需请在 `steps` 中显式添加 `type: "screenshot", name: "initial"`。

Step 类型支持：`screenshot`、`click`、`fill`、`navigate`、`wait`。

Screenshot step 配置示例：

```json
{
  "name": "overview_module",
  "type": "screenshot",
  "screenshot": true,
  "screenshot_height": 1050,
  "screenshot_name": "01-overview-module",
  "selector": "section[data-testid='overview-module']",
  "highlight": [
    { "selector": "section[data-testid='overview-module']", "label": "A" },
    { "selector": "div[data-testid='main-chart']", "label": "B" }
  ]
}
```

说明：
- `selector`：截图目标元素，为空时截当前视口。
- `screenshot_height`（可选）：截图高度（像素）。有 selector 时高度至少为元素高度并向下延伸；无 selector 时截从当前滚动位置起的指定高度区域。
- `highlight`（可选）：临时高亮标注，截图后自动清理。支持单个对象或数组，`label` 显示为标签（A/B/C…）。

## CLI

```bash
uv run scripts/executor.py \
  [--route <name>]      # 可重复，默认执行全部路由
  [--run-id <id>]       # 输出目录 scripts/.tmp/<id>，默认 latest
  [--env-file <file>]   # 凭证文件，默认 scripts/.env
  [--dry-run]           # 只输出执行计划，不运行浏览器
  [--headed]            # 有头模式（可见浏览器窗口）
  [--debug]             # 有头 + devtools + slow_mo

uv run scripts/sync.py \
  [--run-id <id>]       # 使用 .tmp/<id>/results.json，默认 latest
  [--include-failed]    # 失败路由若有截图也同步
  [--dry-run]           # 只打印计划，不写文件
```

## Scripts

- `scripts/executor.py` — 路由执行 CLI（Playwright Python）
- `scripts/sync.py` — 将截图同步写入 `docs/common/core-knowledge/04.ads-platform/01.platform-frontend.md` 和 `docs/common/core-knowledge/04.ads-platform/01.platform-frontend.zh-CN.md`
- `scripts/routes.json` — 路由配置

## Source Notes

- 优先调整路由配置，仅在配置无法满足时修改脚本。
- 不添加非 Seller Center 平台的巡检逻辑。
