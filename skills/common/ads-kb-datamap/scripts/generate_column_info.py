#!/usr/bin/env python3
"""Generate column_info.md from extracted column data and MAX() sample values.

Usage:
    echo '<json>' | python3 generate_column_info.py \\
        --db mp_paidads --table ads_xxx --grass-date 2026-03-25

Input JSON (stdin):
    {
        "columns": [{"name": "col", "type": "bigint", "desc": "...", "query": "7/14/30"}],
        "max_values": {"col": "123", "col2": "%null%"}
    }

Output: Complete column_info.md to stdout.
"""

import argparse
import json
import re
import sys


def parse_l30d(query_str):
    """Extract L30D value from 'L7/L14/L30D' query string."""
    if not query_str:
        return 0
    parts = query_str.split('/')
    if len(parts) >= 3:
        try:
            return int(parts[2])
        except ValueError:
            pass
    # Try last part
    try:
        return int(parts[-1])
    except (ValueError, IndexError):
        return 0


def clean_desc(desc):
    """Clean description text for markdown table compatibility."""
    if not desc:
        return ''
    # Remove trailing "more" link text
    desc = re.sub(r'\s*more\s*$', '', desc).strip()
    # Escape pipe characters for markdown table
    desc = desc.replace('|', '&#124;')
    # Remove newlines
    desc = desc.replace('\n', ' ').replace('\r', '')
    return desc


def clean_max_val(val):
    """Clean MAX() value for markdown table compatibility.

    Handles pipe characters and newlines so JSON strings don't break
    the markdown table layout.
    """
    if not val:
        return ''
    if val == '%null%':
        return 'NULL'
    # Escape pipe characters for markdown table
    val = val.replace('|', '&#124;')
    # Remove newlines
    val = val.replace('\n', ' ').replace('\r', '')
    return val


def process_columns(columns):
    """Process columns: handle PARTITION and Biz Primary Key suffixes, clean descriptions."""
    processed = []
    for col in columns:
        name = col.get('name', '')
        ctype = col.get('type', '')
        desc = col.get('desc', '')
        query = col.get('query', '')

        if name.endswith('PARTITION'):
            name = name.replace('PARTITION', '')
            desc = desc + ' [PARTITION]' if desc else '[PARTITION]'

        if name.endswith('Biz Primary Key'):
            name = name.replace('Biz Primary Key', '')
            desc = desc + ' [BIZ PRIMARY KEY]' if desc else '[BIZ PRIMARY KEY]'

        desc = clean_desc(desc)
        processed.append({
            'name': name,
            'type': ctype,
            'desc': desc,
            'query': query,
            'l30d': parse_l30d(query),
        })
    return processed


def generate_top20(columns, max_values):
    """Generate Top 20 Most Queried Columns section."""
    sorted_cols = sorted(columns, key=lambda x: x['l30d'], reverse=True)
    top20 = sorted_cols[:20]

    lines = []
    lines.append('## Top 20 Most Queried Columns')
    lines.append('')
    lines.append('| # | Column Name | Type | Description | L7/14/30D Query | MAX(column) |')
    lines.append('|---|---|---|---|---|---|')
    for i, col in enumerate(top20, 1):
        max_val = clean_max_val(max_values.get(col['name'], ''))
        lines.append(
            f"| {i} | {col['name']} | {col['type']} | {col['desc']} "
            f"| {col['query']} | {max_val} |"
        )
    lines.append('')
    return lines


def generate_all_columns(columns, max_values):
    """Generate All Columns table with MAX(column) values."""
    lines = []
    lines.append('## All Columns')
    lines.append('')
    lines.append('| Column Name | Type | Description | L7/14/30D Query | MAX(column) |')
    lines.append('|---|---|---|---|---|')

    for col in columns:
        name = col['name']
        max_val = clean_max_val(max_values.get(name, ''))
        lines.append(
            f"| {name} | {col['type']} | {col['desc']} | {col['query']} | {max_val} |"
        )
    lines.append('')
    return lines


def main():
    parser = argparse.ArgumentParser(description='Generate column_info.md')
    parser.add_argument('--db', required=True, help='Database name')
    parser.add_argument('--table', required=True, help='Table name')
    parser.add_argument('--grass-date', required=True, help='Sample data date (YYYY-MM-DD)')
    args = parser.parse_args()

    data = json.load(sys.stdin)
    raw_columns = data.get('columns', [])
    max_values = data.get('max_values', {})

    columns = process_columns(raw_columns)

    lines = []
    lines.append(f'# Columns: {args.db}.{args.table}')
    lines.append('')

    # Top 20
    lines.extend(generate_top20(columns, max_values))

    # Analysis placeholder for Claude to replace
    lines.append('<!-- ANALYSIS_PLACEHOLDER -->')
    lines.append('')

    # MAX() header note
    lines.append(
        f'> MAX(column): MAX() aggregated values from grass_date={args.grass_date}, '
        f'grass_region=SG, tz_type=local (only NULL if ALL rows are NULL)'
    )
    lines.append('')

    # All Columns table
    lines.extend(generate_all_columns(columns, max_values))

    print('\n'.join(lines), end='')


if __name__ == '__main__':
    main()
