#!/usr/bin/env python3
"""Generate table_info.md from extracted DataMap JSON.

Usage:
    echo '<json>' | python3 generate_table_info.py --db mp_paidads --table ads_xxx
    # Outputs markdown to stdout
"""

import argparse
import json
import sys

# Technical properties to exclude (covered by sql_patterns.md DDL Summary or low search value)
TECH_EXCLUDE = {
    'HDFS Path', 'Retention', 'Table Type', 'Create Info', 'Last Edited Info', 'Visibility',
    'hdfs path', 'retention', 'table type', 'create info', 'last edited info', 'visibility',
}

# Business properties to exclude (moved or low value)
BIZ_EXCLUDE = {
    'Sensitivity Level', 'sensitivity level',
    'Last 7 Days Query Count', 'last 7 days query count',
}


def normalize_key(key):
    """Normalize key for case-insensitive matching."""
    return key.strip().lower()


def main():
    parser = argparse.ArgumentParser(description='Generate table_info.md from DataMap JSON')
    parser.add_argument('--db', required=True, help='Database name')
    parser.add_argument('--table', required=True, help='Table name')
    args = parser.parse_args()

    data = json.load(sys.stdin)

    lines = []
    lines.append(f'# {args.db}.{args.table}')
    lines.append('')

    # Description
    lines.append('## Description')
    lines.append('')
    desc = data.get('description', '').strip()
    if desc:
        lines.append(desc)
    lines.append('')

    # Technical Properties (filtered)
    tech_props = data.get('technicalProperties', [])
    filtered_tech = [p for p in tech_props if normalize_key(p['key']) not in
                     {k.lower() for k in TECH_EXCLUDE}]
    if filtered_tech:
        lines.append('## Technical Properties')
        lines.append('')
        lines.append('| Property | Value |')
        lines.append('|----------|-------|')
        for prop in filtered_tech:
            key = prop['key'].strip()
            val = prop['value'].strip().replace('|', '&#124;')
            lines.append(f'| **{key}** | {val} |')
        lines.append('')

    # Business Properties (filtered, extract L7D query count)
    biz_props = data.get('businessProperties', [])
    l7d_query_count = ''
    filtered_biz = []
    for prop in biz_props:
        nk = normalize_key(prop['key'])
        if nk == 'last 7 days query count':
            l7d_query_count = prop['value'].strip()
        elif nk not in {k.lower() for k in BIZ_EXCLUDE}:
            filtered_biz.append(prop)
    if filtered_biz:
        lines.append('## Business Properties')
        lines.append('')
        lines.append('| Property | Value |')
        lines.append('|----------|-------|')
        for prop in filtered_biz:
            key = prop['key'].strip()
            val = prop['value'].strip().replace('|', '&#124;')
            lines.append(f'| **{key}** | {val} |')
        lines.append('')

    # Completeness & Popularity (with L7D Query Count)
    completeness = data.get('completeness', '')
    popularity = data.get('popularity', '')
    if completeness or popularity or l7d_query_count:
        lines.append('## Completeness & Popularity')
        lines.append('')
        if completeness:
            lines.append(f'- **Completeness**: {completeness}')
        if popularity:
            lines.append(f'- **Popularity**: {popularity}')
        if l7d_query_count:
            lines.append(f'- **Last 7 Days Query Count**: {l7d_query_count}')
        lines.append('')

    print('\n'.join(lines), end='')


if __name__ == '__main__':
    main()
