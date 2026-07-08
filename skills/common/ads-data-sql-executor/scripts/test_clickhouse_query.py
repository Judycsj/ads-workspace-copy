#!/usr/bin/env python3
import base64
import json
import tempfile
import unittest
from pathlib import Path
from unittest import mock

import run_clickhouse_query


class ClickHouseQueryTest(unittest.TestCase):
    def test_load_config_uses_text2da_env_auth_first(self):
        config = run_clickhouse_query.load_clickhouse_config(
            env={
                "TEXT2DA_CLICKHOUSE_AUTH": "text2da-user:secret",
                "CLICKHOUSE_SG_AUTH": "legacy-user:secret",
            },
            config_path=None,
            legacy_config_path=None,
            cluster="sg",
        )

        self.assertEqual(config["auth"], "text2da-user:secret")
        self.assertEqual(config["url"], run_clickhouse_query.DEFAULT_SG_URL)
        self.assertEqual(config["timeout_seconds"], 30.0)

    def test_load_config_reads_clickhouse_section_from_text2da_config(self):
        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as handle:
            json.dump(
                {
                    "python_bin": "/path/to/python",
                    "personal_token": "token",
                    "end_user": "user@shopee.com",
                    "presto_queue": "queue",
                    "idc_region": "SG",
                    "priority": "25",
                    "clickhouse": {
                        "clusters": {
                            "sg": {
                                "url": "https://clickhouse.example.test",
                                "username": "mkplpaidads_search_ads-cluster",
                                "password": "pw",
                                "timeout_seconds": 7,
                            }
                        }
                    },
                },
                handle,
            )
            path = Path(handle.name)

        config = run_clickhouse_query.load_clickhouse_config(
            env={},
            config_path=path,
            legacy_config_path=None,
            cluster="sg",
        )

        self.assertEqual(config["url"], "https://clickhouse.example.test")
        self.assertEqual(config["auth"], "mkplpaidads_search_ads-cluster:pw")
        self.assertEqual(config["timeout_seconds"], 7.0)

    def test_load_config_alias_matches_presto_runner_shape(self):
        config = run_clickhouse_query.load_config(
            path=None,
            env={"TEXT2DA_CLICKHOUSE_AUTH": "text2da-user:secret"},
            legacy_config_path=None,
            cluster="sg",
        )

        self.assertEqual(config["auth"], "text2da-user:secret")

    def test_build_effective_config_applies_cli_timeout_override(self):
        args = mock.Mock(timeout_seconds=12)
        config = {
            "url": "https://clickhouse.example.test",
            "auth": "user:pass",
            "timeout_seconds": 30,
        }

        effective = run_clickhouse_query.build_effective_config(args, config)

        self.assertEqual(effective["timeout_seconds"], 12)
        self.assertEqual(config["timeout_seconds"], 30)

    def test_load_config_ignores_presto_only_config_and_uses_legacy_fallback(self):
        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as primary:
            json.dump(
                {
                    "python_bin": "/path/to/python",
                    "personal_token": "token",
                    "end_user": "user@shopee.com",
                    "presto_queue": "queue",
                    "idc_region": "SG",
                    "priority": "25",
                },
                primary,
            )
            primary_path = Path(primary.name)

        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as legacy:
            json.dump({"auth": "legacy-user:legacy-pw"}, legacy)
            legacy_path = Path(legacy.name)

        config = run_clickhouse_query.load_config(
            path=primary_path,
            env={},
            legacy_config_path=legacy_path,
            cluster="sg",
        )

        self.assertEqual(config["auth"], "legacy-user:legacy-pw")

    def test_validate_read_only_sql_rejects_mutation(self):
        with self.assertRaises(run_clickhouse_query.ConfigError):
            run_clickhouse_query.validate_read_only_sql(
                "INSERT INTO table_name SELECT * FROM other_table"
            )

    def test_parse_json_each_row(self):
        rows = run_clickhouse_query.parse_json_each_row('{"a":1}\n{"a":2}\n')
        self.assertEqual(rows, [{"a": 1}, {"a": 2}])

    def test_run_clickhouse_sql_sends_basic_auth_and_json_each_row(self):
        captured = {}

        class FakeResponse:
            def __enter__(self):
                return self

            def __exit__(self, exc_type, exc, tb):
                return False

            def read(self):
                return b'{"one":1}\\n'

        def fake_urlopen(request, timeout):
            captured["url"] = request.full_url
            captured["data"] = request.data.decode()
            captured["headers"] = dict(request.header_items())
            captured["timeout"] = timeout
            return FakeResponse()

        with mock.patch("urllib.request.urlopen", side_effect=fake_urlopen):
            raw = run_clickhouse_query.run_clickhouse_sql(
                "SELECT 1",
                {
                    "url": "https://clickhouse.example.test",
                    "auth": "user:pass",
                    "timeout_seconds": 9,
                },
            )

        expected_auth = base64.b64encode(b"user:pass").decode()
        self.assertEqual(raw, '{"one":1}\\n')
        self.assertEqual(captured["url"], "https://clickhouse.example.test")
        self.assertIn("FORMAT JSONEachRow", captured["data"])
        self.assertEqual(captured["headers"]["Authorization"], f"Basic {expected_auth}")
        self.assertEqual(captured["timeout"], 9)

    def test_clickhouse_cluster_name_from_sql_reads_cluster_function(self):
        sql = """
        SELECT *
        FROM cluster(
            'cluster_mkplpaidads_mkplpaidads_search_ads_online',
            'mkplpaidads_search_ads_ads_debug',
            'ads_roi3_strategy_algo_metrics_clickhouse_1d__reg_s0_live'
        )
        """

        cluster_name = run_clickhouse_query.clickhouse_cluster_name_from_sql(sql)

        self.assertEqual(
            cluster_name,
            "cluster_mkplpaidads_mkplpaidads_search_ads_online",
        )

    def test_datasuite_result_to_rows_converts_header_body_and_numbers(self):
        result = {
            "header": ["grass_date", "exp_tag", "advv", "row_count", "missing"],
            "columnTypes": ["STRING", "STRING", "DOUBLE", "BIGINT", "STRING"],
            "body": [["2026-05-11", "656433", "12.5", "3", "%null%"]],
        }

        rows = run_clickhouse_query.datasuite_result_to_rows(result)

        self.assertEqual(
            rows,
            [
                {
                    "grass_date": "2026-05-11",
                    "exp_tag": "656433",
                    "advv": 12.5,
                    "row_count": 3,
                    "missing": None,
                }
            ],
        )

    def test_fetch_rows_with_fallback_uses_datasuite_clickhouse_when_direct_config_missing(self):
        args = mock.Mock(
            config="/tmp/missing-text2da.json",
            cluster="sg",
            timeout_seconds=None,
            datasuite_project="mkplpaidads_search_ads",
            datasuite_hadoop_account="data_paidadsmart",
            datasuite_idc_region="SG",
            datasuite_cluster_name="cluster_mkplpaidads_mkplpaidads_search_ads_online",
            datasuite_result_limit=100000,
        )

        with mock.patch(
            "run_clickhouse_query.load_config",
            side_effect=run_clickhouse_query.ConfigError("missing direct auth"),
        ), mock.patch(
            "run_clickhouse_query.fetch_rows_via_datasuite_clickhouse",
            return_value=[{"ok": 1}],
        ) as datasuite_fetch, mock.patch("run_clickhouse_query.fetch_rows") as direct_fetch:
            rows = run_clickhouse_query.fetch_rows_with_fallback("SELECT 1", args)

        self.assertEqual(rows, [{"ok": 1}])
        direct_fetch.assert_not_called()
        datasuite_fetch.assert_called_once()
        datasuite_config = datasuite_fetch.call_args.args[1]
        self.assertEqual(datasuite_config["project_code"], "mkplpaidads_search_ads")
        self.assertEqual(datasuite_config["hadoop_account"], "data_paidadsmart")
        self.assertEqual(
            datasuite_config["cluster_name"],
            "cluster_mkplpaidads_mkplpaidads_search_ads_online",
        )

    def test_fetch_rows_with_fallback_uses_datasuite_clickhouse_when_direct_request_fails(self):
        args = mock.Mock(
            config="/tmp/text2da.json",
            cluster="sg",
            timeout_seconds=17,
            datasuite_project="",
            datasuite_hadoop_account="",
            datasuite_idc_region="",
            datasuite_cluster_name="",
            datasuite_result_limit=100000,
        )

        with mock.patch(
            "run_clickhouse_query.load_config",
            return_value={"url": "https://clickhouse.example.test", "auth": "u:p", "timeout_seconds": 30},
        ), mock.patch(
            "run_clickhouse_query.fetch_rows",
            side_effect=RuntimeError("ClickHouse request failed"),
        ), mock.patch(
            "run_clickhouse_query.fetch_rows_via_datasuite_clickhouse",
            return_value=[{"ok": 1}],
        ) as datasuite_fetch:
            rows = run_clickhouse_query.fetch_rows_with_fallback(
                "SELECT * FROM cluster('cluster_x', 'db', 'tbl')",
                args,
            )

        self.assertEqual(rows, [{"ok": 1}])
        datasuite_config = datasuite_fetch.call_args.args[1]
        self.assertEqual(datasuite_config["cluster_name"], "cluster_x")


if __name__ == "__main__":
    unittest.main()
