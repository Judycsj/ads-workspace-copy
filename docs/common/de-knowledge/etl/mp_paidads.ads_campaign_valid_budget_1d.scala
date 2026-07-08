package com.shopee.paidads.data.spark

import com.shopee.paidads.data.utils.Arg
import org.apache.spark.sql.functions.{col, round}
import org.apache.spark.sql.{DataFrame, SparkSession}
import org.slf4j.LoggerFactory
import java.io.File

//有效预算 PRD: https://confluence.shopee.io/pages/viewpage.action?pageId=2210788142


object ROI2ValidBudgetJob{
  def main(args: Array[String]): Unit = {
    val grass_date = args(0)
    val grass_region = args(1)
    val output_table = args(2)
    val hive_path = args(3)
    val scheme = args(4)
    val warehouseLocation = new File("spark-warehouse").getAbsolutePath
    val spark = SparkSession.builder()
      .appName("ROI2ValidBudget")
      .config("spark.sql.warehouse.dir", warehouseLocation)
      .config("spark.sql.adaptive.enabled", "true")
      .config("spark.sql.adaptive.coalescePartitions.enabled", "true")
      .config("spark.sql.sources.commitProtocolClass", "org.apache.spark.sql.hive.execution.CompactFilesCommitProtocol")
      .config("spark.hadoop.mapreduce.fileoutputcommitter.algorithm.version", 1)
      .config("spark.compact.smallfile.size", "368435456")
      .config("spark.compact.size", "1073741824")
      .enableHiveSupport()
      .getOrCreate()
    val logger = LoggerFactory.getLogger(ROI2ValidBudgetJob.getClass)
    // Import campaign data from Hive table
    val campaignDF = spark.sql(
      s"""
        |SELECT
        |  campaign_id
        |  ,campaign_status
        |  ,shop_id
        |  ,campaign_daily_quota_usd
        |  ,campaign_total_quota_usd
        |  ,campaign_start_datetime
        |  ,campaign_end_datetime
        |  ,case
        |       when campaign_daily_quota_usd > 0 then campaign_daily_quota_usd
        |       when (campaign_daily_quota_usd = 0 and campaign_total_quota_usd > 0 and campaign_end_datetime is not null) then (campaign_total_quota_usd/(datediff(campaign_end_datetime, campaign_start_datetime) + 1))
        |       else 9999999999
        |   END AS budget_usd
        |  ,is_cb_seller
        |  ,seller_type
        |  ,seller_type_1p
        |  ,is_cb_sip_affiliated
        |  ,is_local_sip_affiliated
        |  ,grass_region
        |  ,grass_date
        |  ,SUM(COALESCE(ads_expenditure_amt_usd, 0)) AS ads_expenditure_usd
        |  ,max(is_ads_active) as has_ads_active
        |  ,max(pricing_type) as pricing_type
        |  ,if(max(pricing_type) in (9,10,14,19), 1, 0) as is_live_ads
        |  ,max(main_product_type) as main_product_type
        |  ,max(product_type) as product_type
        |  ,max(sub_product_type) as sub_product_type
        |FROM
        |  mp_paidads.ads_advertise_mkt_1d__reg_s0_live
        |WHERE
        |  grass_date = date('$grass_date')
        |  AND grass_region = '$grass_region'
        |  AND tz_type = 'local'
        |  AND date(COALESCE(campaign_end_datetime, '9999-01-01')) >= date('$grass_date')
        |  AND (impression_cnt > 0 or click_cnt > 0 or ads_expenditure_amt_local > 0 or (campaign_status = 1 and is_ads_active = 1))
        |GROUP BY
        |  1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 ,14, 15
        |""".stripMargin)
    campaignDF.createOrReplaceTempView("campaign")

    // Import all data from Hive table
    val baseDF = spark.sql(
      s"""
         |select
         |    campaign_id
         |   ,campaign_status
         |   ,shop_id
         |   ,is_auto_topup_enabled
         |   ,has_ads_active
         |   ,budget_usd
         |   ,ads_expenditure_usd
         |   ,expired_amt_usd
         |   ,topup_amt_usd
         |   ,account_balance_usd
         |   ,account_balance_last1d_usd
         |   ,account_expenditure_usd
         |   ,account_available_fees
         |   ,campaign_valid_budget_usd
         |   ,agg_campaign_valid_budget
         |   ,GREATEST(LEAST(account_available_fees, agg_campaign_valid_budget), account_expenditure_usd) as account_valid_budget_usd
         |   ,split_budget
         |   ,account_campaign_cnt
         |   ,remainning_available_fees
         |   ,remainning_expenditure
         |   ,sys_budget_usd
         |   ,campaign_total_budget_usd
         |   ,GREATEST(ads_expenditure_usd, if(sys_budget_usd > 0, LEAST(sys_budget_usd, campaign_valid_budget_usd), campaign_valid_budget_usd)) as campaign_strategy_valid_budget_usd
         |   ,grass_region
         |   ,grass_date
         |from
         |(
         |    select
         |       campaign.campaign_id
         |       ,campaign.campaign_status
         |       ,campaign.shop_id
         |       ,is_auto_topup_enabled
         |       ,has_ads_active
         |       ,budget_usd
         |       ,ads_expenditure_usd
         |       ,expired_amt_usd
         |       ,topup_amt_usd
         |       ,account_balance_usd
         |       ,account_balance_last1d_usd
         |       ,account_expenditure_usd
         |       ,account_expenditure_usd + account_balance_usd as account_available_fees
         |       ,GREATEST(LEAST(ads_expenditure_usd + account_balance_usd, budget_usd), ads_expenditure_usd) as campaign_valid_budget_usd
         |       ,sum(GREATEST(LEAST(ads_expenditure_usd + account_balance_usd, budget_usd), ads_expenditure_usd)) over(partition by campaign.shop_id) as agg_campaign_valid_budget
         |       ,0 as split_budget
         |       ,account_campaign_cnt
         |       ,account_expenditure_usd + account_balance_usd as remainning_available_fees
         |       ,account_expenditure_usd as remainning_expenditure
         |       ,campaign_total_quota_usd as campaign_total_budget_usd
         |       ,if(is_live_ads = 1 and campaign_daily_quota_usd = 0, default_cap_usd, sys_budget_usd) as sys_budget_usd
         |       ,campaign.grass_region
         |       ,grass_date
         |    from campaign
         |    left join
         |    (
         |       select
         |          shop_id
         |          ,sum(ads_expenditure_usd) as account_expenditure_usd
         |          ,count(*) as account_campaign_cnt
         |       from campaign
         |       where grass_date = '$grass_date'
         |        and grass_region = '$grass_region'
         |        group by shop_id
         |    ) account
         |    on campaign.shop_id = account.shop_id
         |    left join
         |    (
         |        select
         |            campaign_id
         |            ,sum(cast(quota_split.daily_available_quota as bigint) * 1.00000 / 100000 / exchange_rate) as sys_budget_usd
         |        from mp_paidads.dim_campaign__reg_s0_live dim
         |        LEFT JOIN mp_order.dim_exchange_rate__reg_s0_live ex
         |        ON dim.grass_region = ex.grass_region
         |        lateral view explode(quota_splits)  as quota_split
         |        where
         |            dim.grass_region = '$grass_region'
         |            and ex.grass_region = '$grass_region'
         |            and dim.grass_date = '$grass_date'
         |            and ex.grass_date = '$grass_date'
         |        group by campaign_id
         |    ) dim_campaign
         |    on campaign.campaign_id = dim_campaign.campaign_id
         |    left join
         |    (
         |        select
         |            cap.grass_region
         |            ,cast(default_cap as bigint) * 1.00000 / exchange_rate as default_cap_usd
         |        from mp_paidads.dim_live_ads_default_cap__reg_s0_live cap
         |        LEFT JOIN mp_order.dim_exchange_rate__reg_s0_live ex
         |        ON cap.grass_region = ex.grass_region
         |        where
         |            cap.grass_region = '$grass_region'
         |            and ex.grass_region = '$grass_region'
         |            and ex.grass_date = '$grass_date'
         |    )default_cap
         |    on campaign.grass_region = default_cap.grass_region
         |    left join
         |    (
         |       select
         |          shop_id
         |          ,is_auto_topup_enabled
         |       from mp_paidads.dim_advertiser__reg_s0_live
         |       where grass_date = '$grass_date'
         |        and grass_region = '$grass_region'
         |
         |    ) dim_advertiser
         |    on campaign.shop_id = dim_advertiser.shop_id
         |    left join(
         |       select
         |          shop_id
         |          ,sum(if((credit_topup_expiry_end_timestamp is not NULL) and (credit_topup_expiry_end_timestamp > 0) AND (date(credit_topup_expiry_end_datetime) = date('$grass_date')),topup_amt_usd,0)) as expired_amt_usd
         |          ,sum(if(date(topup_create_datetime) = date('$grass_date'), topup_amt_usd, 0)) as topup_amt_usd
         |       FROM mp_paidads.dwd_advertiser_credit_topup_df__reg_s0_live
         |    WHERE grass_region = '$grass_region'
         |      AND grass_date = '$grass_date'
         |      group by shop_id
         |    ) credit_expiry
         |    on campaign.shop_id = credit_expiry.shop_id
         |    left join
         |    (
         |        SELECT
         |          shop_id
         |         , total_eod_balance_usd_td as account_balance_usd
         |        FROM mp_paidads.dws_advertiser_balance_td__reg_s0_live
         |        WHERE grass_region = '$grass_region'
         |        AND grass_date = date'$grass_date'
         |    ) balance
         |    on campaign.shop_id = balance.shop_id
         |    left join
         |    (
         |        SELECT
         |          shop_id
         |         , total_eod_balance_usd_td as account_balance_last1d_usd
         |        FROM mp_paidads.dws_advertiser_balance_td__reg_s0_live
         |        WHERE grass_region = '$grass_region'
         |        AND grass_date = date'$grass_date'- INTERVAL '1' DAY
         |    ) balance_last1d
         |    on campaign.shop_id = balance_last1d.shop_id
         |)
         |where remainning_available_fees >= 0
         |""".stripMargin)

    // filter (account_budget > account_expenditure + account_balance) need to split budget
    val unprocessedDF = baseDF.filter(round(col("agg_campaign_valid_budget"),4) > round(col("account_available_fees"),4))
    // others no need to process
    val processedDF = baseDF
      .filter(round(col("agg_campaign_valid_budget"),4) <= round(col("account_available_fees"),4) )
      .drop("agg_campaign_valid_budget")
    var mergeDF = processedDF.selectExpr(processedDF.columns: _*)

    // split budget
    def collectValidBudget(df: DataFrame): DataFrame = {
      // 1. calculate split_budget
      // (remainning_available_fees - remainning_expenditure) / account_campaign_cnt + ads_expenditure_usd as split_budget
      df
        .withColumn("split_budget", (col("remainning_available_fees") - col("remainning_expenditure")) / col("account_campaign_cnt") + col("ads_expenditure_usd"))
        .createOrReplaceTempView("unprocess_table")
      // 2. calculate campaign_valid_budget_usd, remainning_available_fees, remainning_expenditure, campaign_strategy_valid_budget_usd
//      LEAST(split_budget, GREATEST(budget_usd, ads_expenditure_usd)) as campaign_valid_budget_usd
      val collectDF = spark.sql(
        s"""
           |select *,  case when (abs(split_budget - remainning_available_fees) > 0.1) then 1 else 0 end as diff
           |from
           |(
           |select
           |   campaign_id
           |   ,campaign_status
           |   ,shop_id
           |   ,is_auto_topup_enabled
           |   ,has_ads_active
           |   ,budget_usd
           |   ,ads_expenditure_usd
           |   ,expired_amt_usd
           |   ,topup_amt_usd
           |   ,account_balance_usd
           |   ,account_balance_last1d_usd
           |   ,account_expenditure_usd
           |   ,account_available_fees
           |   ,campaign_valid_budget_usd
           |   ,account_valid_budget_usd
           |   ,split_budget
           |   ,account_campaign_cnt - sum(processed_campaign_cnt) over (partition by shop_id) as account_campaign_cnt
           |   ,remainning_available_fees - sum(processed_budget) over (partition by shop_id) as remainning_available_fees
           |   ,remainning_expenditure
           |   ,sys_budget_usd
           |   ,campaign_total_budget_usd
           |   ,GREATEST(ads_expenditure_usd, if(sys_budget_usd > 0, LEAST(sys_budget_usd, campaign_valid_budget_usd), campaign_valid_budget_usd)) as campaign_strategy_valid_budget_usd
           |   ,grass_region
           |   ,grass_date
           |from
           |(
           |   select
           |      campaign_id
           |      ,campaign_status
           |      ,shop_id
           |      ,is_auto_topup_enabled
           |      ,has_ads_active
           |      ,budget_usd
           |      ,ads_expenditure_usd
           |      ,expired_amt_usd
           |      ,topup_amt_usd
           |      ,account_balance_usd
           |      ,account_balance_last1d_usd
           |      ,account_expenditure_usd
           |      ,account_available_fees
           |      ,GREATEST(budget_usd, ads_expenditure_usd) as campaign_valid_budget_usd
           |      ,account_valid_budget_usd
           |      ,0 as split_budget
           |      ,account_campaign_cnt
           |      ,remainning_available_fees
           |      ,GREATEST(budget_usd, ads_expenditure_usd) as processed_budget
           |      ,0 as remainning_expenditure
           |      ,1 as processed_campaign_cnt
           |      ,sys_budget_usd
           |      ,campaign_total_budget_usd
           |      ,grass_region
           |      ,grass_date
           |   from unprocess_table
           |   where round(split_budget, 4) >= round(GREATEST(budget_usd, ads_expenditure_usd), 4)
           |   union all
           |   select
           |      campaign_id
           |      ,campaign_status
           |      ,shop_id
           |      ,is_auto_topup_enabled
           |      ,has_ads_active
           |      ,budget_usd
           |      ,ads_expenditure_usd
           |      ,expired_amt_usd
           |      ,topup_amt_usd
           |      ,account_balance_usd
           |      ,account_balance_last1d_usd
           |      ,account_expenditure_usd
           |      ,account_available_fees
           |      ,split_budget as campaign_valid_budget_usd
           |      ,account_valid_budget_usd
           |      ,sum(split_budget) over (partition by shop_id) as split_budget
           |      ,account_campaign_cnt
           |      ,remainning_available_fees
           |      ,0 as processed_budget
           |      ,sum(ads_expenditure_usd) over (partition by shop_id) as remainning_expenditure
           |      ,0 as processed_campaign_cnt
           |      ,sys_budget_usd
           |      ,campaign_total_budget_usd
           |      ,grass_region
           |      ,grass_date
           |   from unprocess_table
           |   where round(split_budget, 4) < round(GREATEST(budget_usd, ads_expenditure_usd), 4)
           |)
           |)
           |""".stripMargin)

      // 3. filter split_budget >= budget_usd and
      // stop loop when sum(split_budget) for all campaign equal to account_available_fees
      val unprcsDF = collectDF.filter((col("split_budget") > 0) && (col("diff") === 1)).drop("diff")
      val prcsDF = collectDF.filter((col("split_budget") === 0) || (col("diff") === 0)).drop("diff")
      mergeDF = mergeDF.select(mergeDF.columns.map(col): _*).union(prcsDF.select(prcsDF.columns.map(col): _*))


////      调试代码
//      var unprs_count = unprcsDF.count()
//      var prs_count = prcsDF.count()
//      var merge_count = mergeDF.count()
//      logger.info(s"unprocessedDF 的行数为: $unprs_count")
//      logger.info(s"processedDF 的行数为: $prs_count")
//      logger.info(s"mergeDF 前的行数为: $merge_count")
//      if (unprs_count < 10){
//        logger.info(s"unprocessedDF 剩余数据为:")
//        logger.info(unprcsDF.showString(10, 20, false))
//      }

      if (unprcsDF.count() > 0) {
        // Continue to process unprocessedDF
        collectValidBudget(unprcsDF)
      }
      else{
        mergeDF
      }
    }


    val resultDF = collectValidBudget(unprocessedDF)


//    write to parquet
    resultDF.join(campaignDF.as("campaign"), Seq("campaign_id"),"left")
      .select(
        resultDF("*"),
        col("campaign.campaign_start_datetime"),
        col("campaign.campaign_end_datetime"),
        col("campaign.pricing_type"),
        col("campaign.is_cb_seller"),
        col("campaign.seller_type"),
        col("campaign.seller_type_1p"),
        col("campaign.is_cb_sip_affiliated"),
        col("campaign.is_local_sip_affiliated"),
        col("campaign.main_product_type"),
        col("campaign.product_type"),
        col("campaign.sub_product_type")
      )
      .drop( "account_available_fees", "split_budget", "account_campaign_cnt","remainning_available_fees", "remainning_expenditure", "sys_budget_usd")
      .write
      .mode("overwrite")
      .parquet(s"$hive_path/ads_campaign_valid_budget_1d/tz_type=local/grass_region=$grass_region/grass_date=$grass_date")

    spark.sql(
      s"""
         |ALTER TABLE $scheme.ads_campaign_valid_budget_1d__reg_s0_live
         |ADD IF NOT EXISTS PARTITION (tz_type='local', grass_region='$grass_region', grass_date='$grass_date')
           """.stripMargin)
    spark.sql(
      s"""
         |ALTER TABLE $output_table
         |ADD IF NOT EXISTS PARTITION (grass_date='$grass_date')
           """.stripMargin)

  }
}