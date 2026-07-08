--drop table dws_shop_performance_1d__reg_s0_live;
create table if not exists dws_shop_performance_1d__reg_s0_live
(
    shop_id bigint,
    total_order_cnt bigint,
    total_gmv decimal(38,10),
    checkout_cnt bigint,
    direct_ads_order bigint,
    direct_ads_gmv decimal(38,10),
    broad_ads_order bigint,
    broad_ads_gmv decimal(38,10),
    ads_expense decimal(38,10),

    ads_expense_mtd decimal(38,10),
    take_rate_mtd decimal(38,10),
    sku_with_ads_expense_mtd bigint,
    sku_with_ads_expense_ratio_mtd decimal(38,10),
    sku_with_ads_expense_search_mtd bigint,
    sku_with_ads_expense_discovery_mtd bigint,
    shop_total_gmv_mtd decimal(38,10),
    active_item_cnt bigint
)
comment 'table for dws_shop_performance_1d__reg_s0_live'
partitioned by
(
     tz_type                        string          comment               'timezone type'
    ,grass_region                   string          comment               'partition key'
    ,grass_date                     date            comment               'partition key, yyyy-MM-dd'
)
STORED AS PARQUET
location '${HIVE_PATH}/dws_shop_performance_1d__reg_s0_live';

CREATE OR REPLACE TEMPORARY VIEW shop_all_order as
select shop_id, count(distinct order_id) as total_order_cnt, sum(seller_gmv) as total_gmv
FROM mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live
where tz_type='local' and grass_date='${grass_date}'
and grass_region in (upper('${regions}')) and is_placed=1
group by shop_id;

CREATE OR REPLACE TEMPORARY VIEW shop_ads_performance as
select a.shop_id,checkout_cnt,direct_ads_order,direct_ads_gmv,broad_ads_order,broad_ads_gmv,
COALESCE(ads_expense, 0) + COALESCE(display_ads_expense, 0) as ads_expense
from (
    select shop_id, sum(checkout_cnt) as checkout_cnt,
        sum(order_cnt) as direct_ads_order,
        sum(ads_order_gmv_local) as direct_ads_gmv,
        sum(broad_order_cnt) as broad_ads_order,
        sum(broad_gmv_amt_local) broad_ads_gmv,
        sum(expenditure_amt_local) as ads_expense
    FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live
    where tz_type='local' and grass_date='${grass_date}'
    and grass_region in (upper('${regions}'))
    group by shop_id
) a
left join
(
    select shop_id, sum(display_ads_expense) as display_ads_expense
    from (
        select
            shop_id
            ,ads_id
            ,round(cpm_local * impression_cnt / 100000 / 1000, 2) as display_ads_expense
        from (
            select
                shop_id
                ,ads_id
                ,sum(impression_cnt) as impression_cnt
                ,max(cpm) as cpm_local
            FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live
            where tz_type='local' and grass_date='${grass_date}'
            and grass_region in (upper('${regions}'))
            and placement = 9
            and slot_id is not null
            group by shop_id,ads_id
        )
    ) group by shop_id
) b
on a.shop_id = b.shop_id;

CREATE OR REPLACE TEMPORARY VIEW shop_active_item_cnt as
select shop_id, active_item_cnt
FROM mp_item.dws_shop_listing_td__reg_s0_live
where tz_type='local' and grass_date='${grass_date}'
and grass_region in (upper('${regions}'));

CREATE OR REPLACE TEMPORARY VIEW shop_total_gmv_mtd as
select shop_id, sum(seller_gmv) as shop_total_gmv_mtd
FROM mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live
where tz_type='local'
and grass_date between trunc('${grass_date}', 'MM') and '${grass_date}'
and grass_region in (upper('${regions}')) and is_placed = 1
group by shop_id;

CREATE OR REPLACE TEMPORARY VIEW shop_ads_performance_mtd as
select a.shop_id,
COALESCE(ads_expense_mtd, 0) + COALESCE(display_ads_expense_mtd, 0) as ads_expense_mtd,
sku_with_ads_expense_mtd,
sku_with_ads_expense_search_mtd,
sku_with_ads_expense_discovery_mtd
from
(
    select shop_id,
    sum(expenditure_amt_local) as ads_expense_mtd,
    count(distinct(case when expenditure_amt_local>0 then item_id else null end)) as sku_with_ads_expense_mtd,
    count(distinct(case when expenditure_amt_local>0 and entrance in (1,23) then item_id else null end)) as sku_with_ads_expense_search_mtd,
    count(distinct(case when expenditure_amt_local>0 and
        entrance in (3,4,7,8,9,10,11,20,14,15,16,17,18,19,22,31,32,33,34,29,41,25) then item_id else null end))
            as sku_with_ads_expense_discovery_mtd
    FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live
    where tz_type='local'
    and grass_date between trunc('${grass_date}', 'MM') and '${grass_date}'
    and grass_region in (upper('${regions}'))
    group by shop_id
) a
left join
(
    select shop_id, sum(display_ads_expense) as display_ads_expense_mtd
    from (
        select
            shop_id
            ,ads_id
            ,grass_date
            ,round(cpm_local * impression_cnt / 100000 / 1000, 2) as display_ads_expense
        from (
            select
                shop_id
                ,ads_id
                ,grass_date
                ,sum(impression_cnt) as impression_cnt
                ,max(cpm) as cpm_local
            FROM mp_paidads.dwd_advertise_performance_di__reg_s0_live
            where tz_type='local'
            and grass_date between trunc('${grass_date}', 'MM') and '${grass_date}'
            and grass_region in (upper('${regions}'))
            and placement = 9
            and slot_id is not null
            group by shop_id,grass_date,ads_id
        )
    ) group by shop_id
) b
on a.shop_id = b.shop_id;
;

INSERT OVERWRITE TABLE dws_shop_performance_1d__reg_s0_live PARTITION (tz_type='local', grass_region ,grass_date)
select coalesce(a.shop_id,b.shop_id,c.shop_id,d.shop_id,e.shop_id) as shop_id,
    total_order_cnt,
    total_gmv,
    checkout_cnt,
    direct_ads_order,
    direct_ads_gmv,
    broad_ads_order,
    broad_ads_gmv,
    ads_expense,

    ads_expense_mtd,
    ads_expense_mtd / shop_total_gmv_mtd as take_rate_mtd,
    sku_with_ads_expense_mtd,
    sku_with_ads_expense_mtd / active_item_cnt as sku_with_ads_expense_ratio_mtd,
    sku_with_ads_expense_search_mtd,
    sku_with_ads_expense_discovery_mtd,
    shop_total_gmv_mtd,
    active_item_cnt,
    upper('${regions}') as grass_region,
    DATE('${grass_date}') as grass_date
from
shop_all_order a

FULL JOIN
shop_ads_performance b
ON a.shop_id = b.shop_id

FULL JOIN
shop_active_item_cnt c
ON a.shop_id = c.shop_id

FULL JOIN
shop_total_gmv_mtd d
ON a.shop_id = d.shop_id

FULL JOIN
shop_ads_performance_mtd e
ON a.shop_id = e.shop_id
;
