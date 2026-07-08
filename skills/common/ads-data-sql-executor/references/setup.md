# Setup / 环境准备

## Prerequisites / 前置条件

- Have a Python interpreter that already has `dataservice` installed.
  需要一个已经安装 `dataservice` 的 Python 解释器。
- Have a valid personal Presto token and the matching Shopee email.
  需要有效的 personal Presto token，以及与之匹配的 Shopee 邮箱。
- Know the default Presto queue, IDC region, and priority you want to use.
  需要知道默认使用的 Presto queue、IDC region 和 priority。

## Environment Setup / Python 环境准备

Prepare a dedicated Python environment for the built-in personal-presto runner. The `python_bin`
you put into config must be able to `import dataservice`.

为内置 personal-presto 执行器准备一个独立的 Python 环境。填入配置文件中的 `python_bin`
必须能够成功执行 `import dataservice`。

Recommended flow / 推荐流程:

1. Create or reuse a Python environment.
   创建或复用一个 Python 环境。
2. Install `dataservice` into that environment using your team's standard package source.
   通过团队常用的包源，在该环境中安装 `dataservice`。
3. Verify the interpreter can import `dataservice`.
   验证该解释器能够成功导入 `dataservice`。
4. Put that interpreter path into `config.json` as `python_bin`.
   将这个解释器路径填入 `config.json` 的 `python_bin` 字段。

Example / 示例:

```bash
python3 -m venv /path/to/text2da-presto-venv
source /path/to/text2da-presto-venv/bin/activate
python -m pip install --upgrade pip
# Install dataservice from your normal company package source or mirror.
python -m pip install dataservice
python -c "import dataservice; print('dataservice ok')"
```

If your environment does not provide `dataservice` from the default package index, use your
company's internal installation method instead, then rerun the import check above.

如果默认包源无法安装 `dataservice`，请改用团队内部的安装方式或标准 bootstrap 流程，
然后重新执行上面的 import 检查。

## Config File / 配置文件

Create `~/.config/text2da/config.json` from `references/config.example.json`.

使用 `references/config.example.json` 作为模板，创建 `~/.config/text2da/config.json`。

Required fields / 必填字段:

- `python_bin`: absolute path to the Python interpreter that can import `dataservice`
  `python_bin`：能够导入 `dataservice` 的 Python 解释器绝对路径
- `personal_token`: personal query token
  `personal_token`：personal query token
- `end_user`: your Shopee email
  `end_user`：你的 Shopee 邮箱
- `presto_queue`: default Presto queue such as `mkplpaidads-adhoc`
  `presto_queue`：默认使用的 Presto queue，例如 `mkplpaidads-adhoc`
- `idc_region`: IDC region such as `SG`
  `idc_region`：IDC region，例如 `SG`
- `priority`: query priority such as `25`
  `priority`：查询优先级，例如 `25`

Optional ClickHouse config / 可选 ClickHouse 配置:

- `clickhouse`: ClickHouse direct query config used by `scripts/run_clickhouse_query.py`
  `clickhouse`：`scripts/run_clickhouse_query.py` 使用的 ClickHouse 直查配置
- `clickhouse.clusters.sg.auth`: SG ClickHouse Basic Auth in `UserName-ClusterName:password` format
  `clickhouse.clusters.sg.auth`：SG ClickHouse Basic Auth，格式为 `UserName-ClusterName:password`
- `clickhouse.clusters.us_va2.auth`: US-VA2 ClickHouse Basic Auth in `UserName-ClusterName:password` format
  `clickhouse.clusters.us_va2.auth`：US-VA2 ClickHouse Basic Auth，格式为 `UserName-ClusterName:password`

This follows the same local `~/.config/text2da/config.json` pattern as personal-presto. Environment variables such as `TEXT2DA_CLICKHOUSE_AUTH` are intended only for temporary overrides. If direct ClickHouse config is unavailable or direct HTTP fails, `scripts/run_clickhouse_query.py` automatically tries DataSuite ClickHouse engine 34 using local DataSuite login state from `~/.config/sra/data-studio/refresh_token`, `cookies.json`, or Chrome cookies. This is still a ClickHouse path, not a Hive or Presto fallback.

这沿用 personal-presto 的同一个本地 `~/.config/text2da/config.json` 配置模式。`TEXT2DA_CLICKHOUSE_AUTH` 等环境变量只用于临时覆盖。如果直连 ClickHouse 配置不可用或直连 HTTP 失败，`scripts/run_clickhouse_query.py` 会自动用 `~/.config/sra/data-studio/refresh_token`、`cookies.json` 或 Chrome cookies 中的 DataSuite 登录态，通过 DataSuite ClickHouse engine 34 执行。这仍然是 ClickHouse 路径，不是 Hive 或 Presto fallback。

## How To Get Personal Token / 如何获取 Personal Token

To get `personal_token`:

获取 `personal_token` 的方式：

1. Log in to `https://datasuite.shopee.io/dataservice/ds_api_management`
   登录 `https://datasuite.shopee.io/dataservice/ds_api_management`
2. Click the three-line menu icon in the top-right corner, to the left of your profile avatar
   点击右上角“个人头像”左边的三条横线菜单图标
3. Find `personal token` in the menu
   在菜单中找到 `personal token`

Reference / 参考文档:

- `https://confluence.shopee.io/x/7RBDrg`

## Usage / 使用方式

Dry-run first:

先跑一次 dry-run：

```bash
python3 SKILL_DIR/scripts/run_personal_presto_query.py --sql "select 1" --dry-run
```

Recommended validation order / 推荐校验顺序:

1. `python -c "import dataservice"` succeeds in the target environment
   先确认目标环境里 `python -c "import dataservice"` 可以成功执行
2. `config.json` is filled with that environment's `python_bin`
   再把该环境的解释器路径填进 `config.json` 的 `python_bin`
3. `--dry-run` succeeds
   然后确认 `--dry-run` 能成功
4. Then run a real query
   最后再执行真实查询

Run a query / 执行查询:

```bash
python3 SKILL_DIR/scripts/run_personal_presto_query.py --sql "select 1"
```

Run a query from file / 从文件执行查询:

```bash
python3 SKILL_DIR/scripts/run_personal_presto_query.py --sql-file /path/to/query.sql
```

Run a ClickHouse query / 执行 ClickHouse 查询:

```bash
python3 SKILL_DIR/scripts/run_clickhouse_query.py --sql "select 1" --dry-run
python3 SKILL_DIR/scripts/run_clickhouse_query.py --sql "select 1" --format json
```

Write CSV / 导出 CSV:

```bash
python3 SKILL_DIR/scripts/run_personal_presto_query.py --sql "select 1" --format csv --output /tmp/query.csv
```

## Troubleshooting / 常见问题

`Config file not found`:
Create `~/.config/text2da/config.json`.

`Config file not found`：
创建 `~/.config/text2da/config.json`。

`missing required field(s)`:
Fill every required field in the config file. The script prints the missing field names directly.

`missing required field(s)`：
补齐所有必填字段，脚本会直接打印缺失字段名。

`dataservice is not available in the active interpreter`:
Point `python_bin` at a Python environment where `dataservice` is installed. The script re-executes itself with that interpreter before importing the SDK.

`dataservice is not available in the active interpreter`：
将 `python_bin` 指向一个已安装 `dataservice` 的 Python 环境。脚本会先切换到这个解释器，再导入 SDK。

`pip install dataservice` does not work:
Use your team's internal package source or standard environment bootstrap method, then verify with
`python -c "import dataservice"`.

`pip install dataservice` 不生效：
请使用团队内部包源或标准环境准备方式，然后重新执行
`python -c "import dataservice"` 验证。

Query execution failures:
Check SQL syntax, table permissions, queue, region, and whether the personal token is still valid.

查询执行失败：
检查 SQL 语法、表权限、queue、region，以及 personal token 是否仍然有效。
