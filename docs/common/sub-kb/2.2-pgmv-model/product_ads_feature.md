---
id: product_ads_feature
title: Product Ads UniCR 特征明细
domain: pgmv-model
owner: Product Algo / Model Algo
source_refs:
  - docs/common/sub-kb/2.2-pgmv-model/product-ads-model-kb.md
last_updated: 2026-05-11
last_verified_at: 2026-04-27
confidence: medium
---
<!-- ads-workspace-gdoc-sync: gdoc_id=1JXBff7U7LN8-sRtbLdjteBQV5sbjdkphU8ywzZCt6No gdoc_url=https://docs.google.com/document/d/1JXBff7U7LN8-sRtbLdjteBQV5sbjdkphU8ywzZCt6No/edit -->

# Product Ads 特征明细 / Product Ads Feature Details
> **Contributors**: haibo.di ｜ **最后更新**：2026-05-11 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/sub-kb/2.2-pgmv-model/product_ads_feature.md)

> 本文从 [product-ads-model-kb.md](product-ads-model-kb.md) 拆出，承接 UniCR / pGMV 相关的详细 feature slot 清单、覆盖率、模型使用方式、FSE 链路和特征重要度分析；原模型 KB 仅保留特征概况与核心结论。

## 0. 阅读索引 / Reading Index

- UniCR 模型特征分组：见「1. UniCR 模型特征分组」。
- 全量 slot 明细、覆盖率、数据链路和重要度：见「2. UniCR 全量特征明细」。
- 主模型概览、样本链路、模型架构和校准逻辑：见 [product-ads-model-kb.md](product-ads-model-kb.md)。

---

## 1. UniCR 模型特征分组 / UniCR Model Feature Groups

### 1.1 分组总览 / Group Overview


| 分组           | 变量名                    | Slot 数 | 类型                           | EMB      | 说明      |
| ------------ | ---------------------- | ------ | ---------------------------- | -------- | ------- |
| Dense        | X_DENSE_SLOT           | 2      | dense → AutoDis              | 16       | 统计类连续特征 |
| OneHot       | X_ONEHOT_SLOT          | 5      | dense → OneHotToEmb          | 16       | 离散化统计特征 |
| Sparse       | X_SPARSE_SLOT          | ~316   | sparse emb                   | (1,16)   | ID 类特征  |
| Target       | TARGET_SLOT            | 4      | sparse emb                   | (1,16)   | 目标商品    |
| Query        | X_QUERY_SLOT           | 1      | sparse emb                   | (10,16)  | 搜索词     |
| Click Seq    | X_CLK_500_SLOT         | 4      | sparse emb                   | (500,16) | 点击序列    |
| Cart Seq     | X_CART_128_SLOT        | 4      | sparse emb                   | (128,16) | 加购序列    |
| Order Seq    | X_ORDER_128_SLOT       | 4      | sparse emb                   | (128,16) | 下单序列    |
| Extra        | EXTRA_SLOT             | 46     | sparse emb                   | (1,16)   | 补充特征    |
| Entrance     | ENTRANCE_DENSE_SLOT    | 1      | dense → OneHot → Emb         | 16       | 流量入口    |
| OrgPredict   | ORG_PREDICT            | 2/4    | dense → HardBucket + AutoDis | 16       | 上一轮预估   |
| Price        | ITEM_PRICE_SLOT        | 2      | dense (÷1e5)                 | —        | 商品价格    |
| Sold Cnt     | DIRECT_SOLD_CNT + SHOP | 10+1   | dense → 分段平滑                 | —        | 销量统计    |
| Price Bucket | CATE2_PRICE_BUCKET     | 1      | dense → int index            | —        | 价格桶索引   |


### 1.2 Dense 特征 / Dense Features


| Slot ID | Feature Name                   | 维度  | 说明                  |
| ------- | ------------------------------ | --- | ------------------- |
| 60167   | dense_lt_ub_clk_uc_sz_log3     | 3   | 长期用户行为点击统计 (log)    |
| 60174   | dense_st_ub_cart_ord_cnt_log16 | 16  | 短期用户行为加购/下单统计 (log) |


### 1.3 OneHot 特征 / OneHot Features


| Slot ID | Feature Name                   | 维度  | 说明          |
| ------- | ------------------------------ | --- | ----------- |
| 60192   | onehot_supply_ub_hit_cat32     | 32  | 供给侧用户行为命中类目 |
| 60177   | onehot_ub_multi_action_hit48   | 48  | 用户多行为命中特征   |
| 60135   | onehot_ctxt_item_id_cat_match8 | 8   | 上下文-商品类目匹配  |
| 60136   | onehot_ctxt_ship_lpg_match4    | 4   | 上下文-物流匹配    |
| 60137   | onehot_ctxt_item_price_ctr14   | 14  | 上下文-商品价格CTR |


### 1.4 Target 特征 / Target Features


| Slot ID | Feature Name    | 说明    |
| ------- | --------------- | ----- |
| 60000   | item_id         | 商品 ID |
| 30103   | shop_id         | 店铺 ID |
| 30108   | global_subcat   | 二级类目  |
| 30109   | global_thirdcat | 三级类目  |


### 1.5 行为序列特征 / Behavior Sequence Features


| 分组    | Slot IDs                   | Feature Names                                    | 序列长度 |
| ----- | -------------------------- | ------------------------------------------------ | ---- |
| Click | 31253, 31254, 31331, 31332 | longub_click_{itemid,shopid,subcat,thirdcat}_500 | 500  |
| Cart  | 31327, 31328, 31333, 31334 | longub_cart_{itemid,shopid,subcat,thirdcat}_128  | 128  |
| Order | 31329, 31330, 31335, 31336 | longub_order_{itemid,shopid,subcat,thirdcat}_128 | 128  |


### 1.6 Query 特征 / Query Features


| Slot ID | Feature Name        | 说明           |
| ------- | ------------------- | ------------ |
| 1008    | Context_query_split | 搜索词分词，dim=10 |


### 1.7 OrgPredict 特征 / OrgPredict Features


| Slot ID | Feature Name  | 用途             | 备注                       |
| ------- | ------------- | -------------- | ------------------------ |
| 1003    | I_pctr_online | pCTR (上一轮模型预估) | 仅 entrance=1 (Search) 有效 |
| 1004    | I_pcr_online  | pCR (上一轮模型预估)  | 仅 entrance=1 (Search) 有效 |
| 1227    | —             | pCR_shop       | 训练时额外加入                  |
| 1228    | —             | pCR_broad      | 训练时额外加入                  |


### 1.8 价格与销量特征 / Price and Sold Count Features


| Slot ID | Feature Name          | 说明              |
| ------- | --------------------- | --------------- |
| 1602    | I_price_usd_raw       | 直接购买商品价格 (÷1e5) |
| 1614    | shop_gmv_per_sold     | 店铺购买商品价格 (÷1e5) |
| 65160   | —                     | 优惠券价格           |
| 49092   | I_price_usd_bucket    | 二级类目价格分桶索引      |
| 31245   | I_cate2_avgsoldcnt_q0 | 分价格桶销量 (q0)     |
| 19902   | I_cate2_avgsoldcnt_q1 | 分价格桶销量 (q1)     |
| 8669    | I_cate2_avgsoldcnt_q2 | 分价格桶销量 (q2)     |
| 59320   | I_cate2_avgsoldcnt_q3 | 分价格桶销量 (q3)     |
| 11748   | I_cate2_avgsoldcnt_q4 | 分价格桶销量 (q4)     |
| 14749   | I_cate2_avgsoldcnt_q5 | 分价格桶销量 (q5)     |
| 62955   | I_cate2_avgsoldcnt_q6 | 分价格桶销量 (q6)     |
| 33868   | I_cate2_avgsoldcnt_q7 | 分价格桶销量 (q7)     |
| 64433   | I_cate2_avgsoldcnt_q8 | 分价格桶销量 (q8)     |
| 53832   | I_cate2_avgsoldcnt_q9 | 分价格桶销量 (q9)     |
| 1613    | shop_sold_per_order   | 店铺维度销量统计        |


### 1.9 Entrance 特征 / Entrance Features


| Slot ID | Feature Name | 说明     |
| ------- | ------------ | ------ |
| 1224    | ctx_entrance | 流量入口标识 |


### 1.10 Extra 特征 / Extra Features (46 slots)

Extra 特征为通过 `ego.import_extra_slots` 导入的广告/用户/场景补充特征，slot 列表见 `feature_slots_id.json` 中 `EXTRA_SLOT` 字段（5001-5008, 2001-2035, 4001-4004, 8000-8013 等 46 个 slot），每个 slot 映射为 (1, 16) Embedding。

### 1.11 Sparse 特征概要 / Sparse Feature Summary

Sparse 特征共 ~316 个 slot，每个 slot lookup 为 (1, 16) 的 Embedding。完整 slot 列表及特征名称见 `feature_name_slots.yaml` 和 `feature_slots_id.json`。


---

## 2. UniCR 全量特征明细 / UniCR Full Feature Details



> 整理范围：unicr推全模型（截止20260424）。

> 信息来源：`personal/ads-feat-utils/config.yaml`、Google Sheet（`特征汇总/all`）。

> Google Sheet 链接：https://docs.google.com/spreadsheets/d/1nHGLhw2nZhxNSgSl4f50tXnKVmNZAcuVZtIR_kqwXWc/edit?gid=1645208388#gid=1645208388

> 信息截止：2026-04-27



---



### 2.1 特征汇总 / Feature Summary

- 特征总数：494（sparse=469, dense=20）

- 本次实时拉取命中特征数：494 / 494

- `分类_场景` 来自 Google Sheet 的规则派生列：同时查看 `fse_tb` 和 `upstream_node_lis`，命中 `search/query/kw/sq` 归为 `search`，否则命中 `rcmd` 归为 `rcmd`，否则归为 `shared`。
- `分类_点击转化` 来自 Google Sheet 的规则派生列：查看 `upstream_node_lis`，命中 `ctr/click` 归为 `click`，否则命中 `order/cvr/conversion/pcr` 归为 `order`，否则归为 `others`。
- 以上两列均基于关键词规则自动分类，只用于快速分析与分桶参考，结果可能不完全准确。

#### 2.1.1 特征总表 / UniCR Feature Table

| slot_type | 分类_场景 | 分类_点击转化 | 类别 | Slot ID | 特征名 | 说明 | 处理算子 |
|------|------|------|------|------|------|------|------|
| dense | shared | click | item侧 | 1003 | I_Pctr_reader | 商品广告预估点击率 | of_iterable_arrow_feature |
| dense | shared | order | item侧 | 1004 | I_Pcr_reader | 商品广告预估成交率 | of_iterable_arrow_feature |
| sparse | search | click | item侧 | 1006 | I_query_ctr_click_bucket | 商品所属投放国家 | bucket_by_country |
| sparse | search | others | 用户侧 | 1008 | Context_query_split | 用户当前搜索词拆分词项 | split_string |
| sparse | shared | others | item侧 | 1011 | I_Placement_reader | 广告展示位置类型 | of_iterable_arrow_feature |
| sparse | shared | others | item侧 | 1038 | I_threestar_bucket | 商品在当地三星评价分层 | bucket_by_country |
| sparse | shared | others | item侧 | 1044 | I_likedcount_bucket | 商品在当地被点赞量分层 | bucket_by_country |
| sparse | shared | click | item侧 | 1058 | I_ctr_click3d_bucket | 商品近3天点击量分层 | bucket_by_country |
| sparse | search | click | item侧 | 1065 | I_query_ctr_cat3v2click_bucket | 商品在三级类目下点击热度 | bucket_by_country |
| sparse | search | click | item侧 | 1068 | I_query_ctr_click7d_bucket | 商品近7天搜索点击热度 | bucket_by_country |
| sparse | search | click | item侧 | 1069 | I_query_ctr_impression7d_bucket | 商品近7天搜索曝光热度 | bucket_by_country |
| sparse | search | click | item侧 | 1072 | I_query_ctr_impression_bucket | 商品累计搜索曝光热度 | bucket_by_country |
| sparse | search | click | item侧 | 1074 | I_query_ctr_cat1v2impression_bucket | 商品在一级类目下曝光热度 | bucket_by_country |
| sparse | search | order | item侧 | 1078 | I_query_norder_ordercount_bucket | 商品相关搜索下单量热度 | bucket_by_country |
| sparse | search | order | item侧 | 1079 | I_query_norder_soldcount_bucket | 商品相关搜索销量热度 | bucket_by_country |
| sparse | rcmd | click | item侧 | 1084 | I_rcmd_ctr_click_bucket | 推荐场景整体点击量分层 | bucket_by_country |
| sparse | search | click | item侧 | 1093 | Kw_ctr_click3d_bucket | 当前搜索词近3天点击分层 | bucket_by_country |
| sparse | search | click | item侧 | 1094 | Kw_ctr_click14d_bucket | 当前搜索词近14天点击分层 | bucket_by_country |
| sparse | search | click | item侧 | 1095 | Kw_ctr_click_bucket | 当前搜索词历史点击分层 | bucket_by_country |
| sparse | search | click | item侧 | 1097 | Kw_ctr_click7d_bucket | 当前搜索词近7天点击分层 | bucket_by_country |
| sparse | search | click | item侧 | 1098 | Kw_ctr_impression3d_bucket | 当前搜索词近3天曝光分层 | bucket_by_country |
| sparse | search | click | item侧 | 1099 | Kw_ctr_impression14d_bucket | 当前搜索词近14天曝光分层 | bucket_by_country |
| sparse | search | click | item侧 | 1100 | Kw_ctr_impression_bucket | 当前搜索词历史曝光分层 | bucket_by_country |
| sparse | shared | others | item侧 | 1107 | S_overseas_reader | 店铺是否海外发货 | of_iterable_arrow_feature |
| sparse | shared | others | item侧 | 1108 | S_city_reader | 店铺所在城市 | of_iterable_arrow_feature |
| sparse | shared | others | item侧 | 1109 | S_state_reader | 店铺所在州省 | of_iterable_arrow_feature |
| sparse | shared | others | item侧 | 1124 | S_ratingstar_bucket | 店铺平均评分分层 | bucket_by_country |
| sparse | shared | click | item侧 | 1129 | I_s_ctr_click3d_bucket | 商品店铺近3天点击分层 | bucket_by_country |
| sparse | shared | click | item侧 | 1132 | I_s_ctr_click7d_bucket | 商品店铺近7天点击分层 | bucket_by_country |
| sparse | search | click | item侧 | 1138 | I_sq_ctr_click_bucket | 搜索词商品历史点击分层 | bucket_by_country |
| sparse | search | click | item侧 | 1139 | I_sq_ctr_click3d_bucket | 搜索词商品近3天点击分层 | bucket_by_country |
| sparse | search | click | item侧 | 1141 | I_sq_ctr_click14d_bucket | 搜索词商品近14天点击分层 | bucket_by_country |
| sparse | search | click | item侧 | 1143 | I_sq_ctr_impression_bucket | 搜索词商品历史曝光分层 | bucket_by_country |
| sparse | shared | click | item侧 | 1145 | I_sr_ctr_impression_bucket | 搜索结果商品曝光分层 | bucket_by_country |
| sparse | shared | others | 用户侧 | 1154 | U_paymentmethod_reader | 用户常用支付方式 | of_shared_arrow_feature |
| sparse | shared | others | 用户侧 | 1157 | U_state_reader | 用户所在州省 | of_shared_arrow_feature |
| sparse | shared | others | 用户侧 | 1158 | U_emailverified_reader | 用户邮箱验证状态 | of_shared_arrow_feature |
| sparse | shared | others | 用户侧 | 1160 | U_phoneverified_reader | 用户手机验证状态 | of_shared_arrow_feature |
| sparse | shared | others | 用户侧 | 1166 | U_fivestar_bucket | 用户五星评价次数分层 | bucket_by_country |
| sparse | shared | others | 用户侧 | 1167 | U_cartitemcount_bucket | 用户购物车商品数分层 | bucket_by_country |
| sparse | shared | others | 用户侧 | 1174 | U_likedcount_bucket | 用户点赞商品数分层 | bucket_by_country |
| sparse | shared | others | item侧 | 1183 | I_nesv2_reader | 用户消费能力层级 | of_iterable_arrow_feature |
| sparse | shared | click | 用户侧 | 1190 | U_ctr_v2_impression_bucket | 用户历史广告曝光量分层 | bucket_by_country |
| sparse | shared | click | 用户侧 | 1191 | U_ctr_v2_click_bucket | 用户在类目上的点击倾向 | bucket_by_country |
| sparse | shared | others | 用户侧 | 1205 | U_tag_v1_ethnicity_reader | 用户的人群族裔标签 | of_shared_arrow_feature |
| sparse | shared | others | 用户侧 | 1206 | U_tag_v1_mppurchaselevelin30days_reader | 用户近30天购买力等级 | of_shared_arrow_feature |
| sparse | shared | others | 用户侧 | 1207 | U_tag_v1_phoneos_reader | 用户手机操作系统类型 | of_shared_arrow_feature |
| sparse | shared | others | 用户侧 | 1212 | U_tag_v1_accstatus_reader | 用户账号状态等级 | of_shared_arrow_feature |
| sparse | shared | others | item侧 | 1214 | U_tag_v1_shopidview_contain | 用户是否浏览过当前店铺 | check_contain |
| sparse | shared | others | 用户侧 | 1216 | U_tag_v1_mpnewuser_reader | 用户是否为商城新客 | of_shared_arrow_feature |
| sparse | shared | others | item侧 | 1217 | U_tag_v1_shopidcart_contain | 用户是否加购过当前店铺 | check_contain |
| dense | shared | others | 上下文 | 1224 | Context_entrance_reader | 当前流量入口场景 | of_shared_arrow_feature |
| dense | search | others | item侧 | 1227 | user_purchase_power | 用户在该一级类目的消费力 | of_iterable_arrow_feature |
| sparse | shared | others | item侧 | 1600 | I_p_price_bucket | 商品价格分档 | bucket |
| dense | shared | others | item侧 | 1602 | I_p_price_reader | 商品原始价格 | of_iterable_arrow_feature |
| dense | shared | order | item侧 | 1613 | avg_sold_cnt_shop | 同店其他商品近14天均销 | divide |
| dense | shared | order | item侧 | 1614 | item_price_shop | 同店其他商品近14天均价 | divide |
| sparse | shared | others | 用户侧 | 2117 | S_pdp_stay_view_cate_ids_top3recent | 用户最近停留浏览类目前三 | slice_list |
| sparse | rcmd | others | 用户侧 | 2186 | clk_items_within_1h_mod | 用户近1小时点击强度 | bucket_by_country |
| sparse | shared | others | 用户侧 | 2312 | S_ord_items_within_1h_cnt_0 | 用户近1小时下单商品数 | bucket_double |
| sparse | shared | others | 用户侧 | 2503 | rt_user_service_fee_avg | 用户平均服务费水平 | of_shared_arrow_feature |
| sparse | rcmd | others | item侧 | 2504 | S_ord_shops_within_90d_target_cnt_log | 用户近90天在该店下单频次 | log |
| sparse | rcmd | others | item侧 | 2505 | M_clk_shops_within_3d_target_cnt_log | 用户近3天点击该店频次 | log |
| sparse | rcmd | others | 用户侧 | 2506 | cart_timegaps | 用户加购行为时间间隔 | bucket_by_country |
| sparse | rcmd | others | 用户侧 | 2507 | clk_timegaps | 用户点击行为时间间隔 | bucket_by_country |
| sparse | rcmd | others | 用户侧 | 2508 | ord_timegaps | 用户下单行为时间间隔 | bucket_by_country |
| sparse | shared | others | 用户侧 | 2531 | rt_user_voucher_platform_vouchers | 用户可用的平台优惠券情况 | of_shared_arrow_feature |
| sparse | shared | others | 用户侧 | 2532 | rt_user_voucher_unredeemed_platform_vouchers | 用户未使用的平台优惠券情况 | of_shared_arrow_feature |
| sparse | shared | others | 用户侧 | 2534 | rt_user_voucher_total_redeemed_platform_vouchers | 用户累计已使用的平台优惠券数量 | of_shared_arrow_feature |
| sparse | shared | others | 用户侧 | 2541 | rt_user_voucher_redeemed_free_shipping_vouchers | 用户已使用的免运优惠券情况 | of_shared_arrow_feature |
| sparse | shared | others | 用户侧 | 2542 | rt_user_voucher_total_redeemed_free_shipping_vouchers | 用户累计已使用的免运优惠券数量 | of_shared_arrow_feature |
| sparse | shared | others | 用户侧 | 2548 | rt_user_voucher_unredeemed_seller_vouchers_shopid | 用户未使用商家券对应店铺 | of_shared_arrow_feature |
| sparse | rcmd | others | 用户侧 | 2558 | rt_user_voucher_total_redeemed_platform_vouchers_discountpercentage | 用户历史已用平台券折扣力度 | bucket_by_country |
| sparse | search | order | 用户侧 | 4092 | B_query_allnet_rt_order_5h | 用户所在地区该词近5小时下单热度 | bucket_by_country |
| sparse | rcmd | others | item侧 | 5005 | item_payuv14_allnet | 用户所在国家下商品14天支付人数 | bucket_by_country |
| sparse | search | click | item侧 | 5033 | item_ctr30_search | 商品近30天搜索点击率表现 | bucket_by_country |
| sparse | search | others | item侧 | 5071 | item_shop_type | 商品所属店铺类型 | of_iterable_arrow_feature |
| sparse | search | others | item侧 | 5078 | S_cat3orcat2 | 商品所属三级或二级类目 | of_iterable_arrow_feature_integer |
| sparse | search | others | item侧 | 5082 | S_is_cod | 商品是否支持货到付款 | of_iterable_arrow_feature_integer |
| sparse | search | order | item侧 | 5098 | S_icvr30 | 商品近30天成交转化率 | bucket_double |
| sparse | search | others | item侧 | 6174 | realtime_clk | 商品历史被点击次数 | sum |
| sparse | search | others | item侧 | 6175 | realtime_atc | 商品历史被加购次数 | sum |
| sparse | search | order | item侧 | 6176 | realtime_order | 商品历史被下单次数 | sum |
| sparse | rcmd | order | item侧 | 6189 | B_item_allnet_rt_order_12h | 用户所在国家下商品12小时成交单量 | bucket_by_country |
| sparse | rcmd | others | item侧 | 6204 | B_rt_item_product_promotion_type_id_ct | 用户所在国家下商品促销类型数量 | bucket_by_country |
| sparse | rcmd | others | item侧 | 6208 | B_rt_item_product_promotion_id_ct | 用户所在国家下商品促销活动数量 | bucket_by_country |
| sparse | shared | others | item侧 | 6262 | rt_item_status_status | 商品当前售卖状态 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 6270 | B_rt_item_status_price_usd | 用户所在国家下商品当前售价 | bucket_by_country |
| sparse | shared | others | item侧 | 6272 | rt_item_status_shop_status | 商品所属店铺经营状态 | of_iterable_arrow_feature |
| sparse | shared | others | item侧 | 6275 | rt_item_status_first_label | 商品的一级业务标签 | of_iterable_arrow_feature |
| sparse | shared | others | item侧 | 6276 | rt_item_status_second_label | 商品的二级业务标签 | of_iterable_arrow_feature |
| sparse | shared | others | item侧 | 6277 | rt_item_status_seller_location | 商品卖家的所在地区 | of_iterable_arrow_feature |
| sparse | search | others | item侧 | 6281 | B_rt_query_item_price_avg_usd_minus | 商品均价与词均价差 | minus |
| sparse | shared | order | item侧 | 6317 | B_rt_item_status_price_order_avg_usd_minus | 商品价格相对结果均价差 | minus |
| sparse | search | others | item侧 | 6320 | B_rt_item_status_price_query_price_max_usd_minus | 商品实时价格与词最高价差 | minus |
| sparse | rcmd | order | item侧 | 7014 | user_cate1_cvr7_allnet | 用户一级类目七日转化偏好 | bucket_by_country |
| sparse | search | order | item侧 | 7019 | user_cate1_cvr30_search | 用户在一级类目近30天转化倾向 | bucket_by_country |
| sparse | rcmd | order | item侧 | 7035 | user_cate2_cvr7_allnet | 用户二级类目七日转化偏好 | bucket_by_country |
| sparse | rcmd | others | item侧 | 8017 | user_cate1_clk_cnt_1d | 用户近1天一级类目点击次数 | bucket_by_country |
| sparse | rcmd | others | item侧 | 8018 | user_cate1_cart_cnt_3h | 用户近3小时一级类目加购次数 | bucket_by_country |
| sparse | rcmd | others | item侧 | 8019 | user_cate1_cart_cnt_1d | 用户近1天一级类目加购次数 | bucket_by_country |
| sparse | rcmd | others | item侧 | 8024 | user_cate_cart_cnt_3h | 用户近3小时类目加购次数 | bucket_by_country |
| sparse | rcmd | others | item侧 | 8036 | user_item_cart_cnt_3h | 用户近3小时商品加购次数 | bucket_by_country |
| sparse | rcmd | others | item侧 | 8037 | user_item_cart_cnt_1d | 用户近1天商品加购次数 | bucket_by_country |
| sparse | rcmd | others | item侧 | 8047 | user_cate1_clk_cnt_lt | 用户长期一级类目点击次数 | bucket_by_country |
| sparse | rcmd | others | item侧 | 8050 | user_cate1_cart_cnt_lt | 用户长期一级类目加购次数 | bucket_by_country |
| sparse | rcmd | others | item侧 | 8094 | S_pdp_stay_view_item_durations_sum_1h | 用户近1小时商品页停留时长 | bucket_double |
| sparse | rcmd | others | item侧 | 8096 | S_pdp_stay_view_item_durations_sum_1d | 用户近1天商品页停留时长 | bucket_double |
| sparse | rcmd | others | item侧 | 8102 | S_pdp_stay_view_shop_durations_sum_3d | 用户近3天店铺页停留时长 | bucket_double |
| sparse | rcmd | others | item侧 | 8103 | S_pdp_stay_view_shop_durations_sum_1h | 用户近1小时店铺页停留时长 | bucket_double |
| sparse | rcmd | others | item侧 | 8105 | S_pdp_stay_view_item_count | 用户历史商品页浏览次数 | bucket_double |
| sparse | shared | others | item侧 | 8106 | S_pdp_stay_view_item_durations_sum | 用户历史商品页累计停留时长 | bucket_double |
| sparse | rcmd | others | item侧 | 8131 | cart_item_id_cnt | 用户购物车中该商品出现次数 | bucket_by_country |
| sparse | rcmd | others | item侧 | 8132 | clk_items_intersect_i2i_cnt | 用户点击与相似商品重合数 | bucket_by_country |
| sparse | rcmd | others | item侧 | 8140 | S_last_clk_item_time_gap_disc_0 | 用户最近点击该商品距今时长 | bucket_double |
| sparse | search | others | item侧 | 8141 | S_clk_items_intersect_i2i_0 | 用户近期点击商品的相似商品集合 | intersect_list |
| sparse | search | others | item侧 | 8159 | S_ord_cate1_id_cnt_0 | 用户在该一级类目的下单次数 | bucket_double |
| sparse | search | others | item侧 | 8163 | S_clk_items_intersect_i2i_cnt_0 | 用户点击商品与当前商品相似重合数 | bucket_double |
| sparse | search | others | item侧 | 8164 | S_last_clk_cate1_time_gap_disc_0 | 用户最近点击该一级类目的时间间隔 | bucket_double |
| sparse | search | others | item侧 | 8166 | S_last_ord_cate1_time_gap_disc_0 | 用户最近下单该一级类目的时间间隔 | bucket_double |
| dense | shared | order | item侧 | 8669 | cate2_norder_avgsoldcntl2_reader | 商品二级类目平均销量水平 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 9936 | user_last_shop_ord_timegap | 用户最近店铺下单距今时长 | bucket_by_country |
| sparse | rcmd | others | item侧 | 9938 | user_last_cate1_cart_timegap | 用户最近一级类目加购距今时长 | bucket_by_country |
| sparse | rcmd | others | item侧 | 9939 | user_last_shop_cart_timegap | 用户最近店铺加购距今时长 | bucket_by_country |
| sparse | rcmd | others | item侧 | 9940 | user_last_cate1_clk_timegap | 用户最近一级类目点击距今时长 | bucket_by_country |
| sparse | rcmd | others | item侧 | 9969 | S_pdp_stay_view_item_durations_sum_3d | 用户近3天商品页停留时长 | bucket_double |
| sparse | search | order | item侧 | 9971 | S_iorders3 | 商品近3天下单量 | bucket_double |
| sparse | rcmd | others | item侧 | 9980 | S_pdp_stay_view_targetshop_durations_within_90d_sum_log | 用户近90天店铺页停留时长 | log |
| sparse | rcmd | others | item侧 | 9981 | S_last_cart_item_time_gap_log | 用户最近加购该商品距今时长 | log |
| sparse | search | others | item侧 | 9982 | S_pdp_stay_view_primarycate_durations_within_3d_sum_log | 用户近3天浏览同类商品停留时长 | log |
| dense | shared | order | item侧 | 11748 | cate2_norder_avgsoldcntl4_reader | 商品二级类目中高销量水平 | of_iterable_arrow_feature |
| sparse | shared | others | 用户侧 | 12337 | S_cart_items_within_1h_cnt_0 | 用户近1小时加购商品数量 | size_iterable |
| sparse | shared | others | 用户侧 | 12363 | S_impr_items_1d_after_last_buy_cnt_log | 用户上次购买后1天曝光量 | log |
| sparse | shared | others | 用户侧 | 12364 | S_impr_items_15mins_after_last_buy_cnt_log | 用户上次购买后15分钟曝光量 | log |
| sparse | shared | others | 用户侧 | 12381 | S_cart_cate_ids_within_1d_cnt_log | 用户近1天加购类目数量 | log |
| sparse | search | others | item侧 | 12385 | S_cart_cate1_id_target_cnt_log | 用户将该一级类目商品加入购物车次数 | log |
| sparse | shared | others | 用户侧 | 12387 | S_cart_cate_ids_within_3d_cnt_log | 用户近3天加购类目数量 | log |
| sparse | rcmd | others | item侧 | 12395 | S_impr_no_clk_items_30mins_target_cnt_log | 用户近30分钟未点该商品曝光次数 | log |
| sparse | rcmd | others | item侧 | 12403 | S_cart_shop_id_target_cnt_log | 用户近期加购当前店铺次数 | log |
| sparse | shared | others | 用户侧 | 12408 | S_impr_items_15mins_after_last_clk_cnt_log | 用户上次点击后15分钟曝光量 | log |
| dense | shared | order | item侧 | 14749 | cate2_norder_avgsoldcntl5_reader | 商品二级类目高销量水平 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 18152 | S_cart_item_id_cnt_0 | 用户购物车中该商品出现次数 | bucket_double |
| dense | shared | order | item侧 | 19902 | cate2_norder_avgsoldcntl1_reader | 商品二级类目平均销量 | of_iterable_arrow_feature |
| sparse | shared | others | 用户侧 | 23168 | S_ord_items_within_3d_cnt_0 | 用户近3天下单商品活跃度 | bucket_double |
| sparse | shared | others | 用户侧 | 23178 | S_ord_items_within_1d_cnt_0 | 用户近1天下单商品活跃度 | bucket_double |
| sparse | rcmd | others | item侧 | 23748 | S_ord_items_target_cnt_log | 用户历史下单该商品频次 | log |
| sparse | rcmd | others | 用户侧 | 30000 | user_id | 用户身份标识 | of_shared_arrow_feature |
| sparse | rcmd | others | 用户侧 | 30001 | mpi_gender | 用户性别 | of_shared_arrow_feature |
| sparse | rcmd | others | 用户侧 | 30002 | mpi_age_group | 用户年龄段 | of_shared_arrow_feature |
| sparse | rcmd | others | 用户侧 | 30003 | mpi_address | 用户常驻城市 | of_shared_arrow_feature |
| sparse | rcmd | others | 用户侧 | 30004 | mpi_ip_address | 用户近期IP所在城市 | of_shared_arrow_feature |
| sparse | shared | others | 上下文 | 30082 | pdp_item_id | 当前浏览商品标识 | of_shared_arrow_feature |
| sparse | shared | others | 上下文 | 30083 | pdp_item_id | 当前主商品标识 | of_shared_arrow_feature |
| sparse | shared | others | 上下文 | 30084 | pdp_item_id | 当前详情页商品标识 | of_shared_arrow_feature |
| sparse | shared | others | 上下文 | 30085 | pdp_shop_id | 当前浏览店铺标识 | of_shared_arrow_feature |
| sparse | rcmd | others | 上下文 | 30086 | pdp_intention_l0 | 当前商品一级意图类目 | of_shared_arrow_feature |
| sparse | rcmd | others | 上下文 | 30089 | pdp_global_subcat | 当前商品全局二级类目 | of_shared_arrow_feature |
| sparse | rcmd | others | 上下文 | 30090 | pdp_global_thirdcat | 当前商品全局三级类目 | of_shared_arrow_feature |
| sparse | rcmd | others | 用户侧 | 30091 | pdp_rate_bucket | 当前商品评分水平 | bucket |
| sparse | rcmd | others | 用户侧 | 30092 | pdp_thirdcat_price | 当前商品三级类目价格带 | join_string |
| sparse | rcmd | others | 用户侧 | 30093 | pdp_subcat_price | 当前商品二级类目价格带 | join_string |
| sparse | rcmd | order | 用户侧 | 30096 | pdp_item_NOrder30_bucketized | 当前商品近30天下单热度 | bucket |
| sparse | rcmd | others | 用户侧 | 30097 | pdp_item_Price_bucketized | 当前商品价格区间 | bucket |
| sparse | rcmd | others | item侧 | 30102 | item_id | 候选商品标识 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 30103 | shop_id | 候选商品所属店铺 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 30104 | intention_l0 | 候选商品一级意图类目 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 30105 | first_intention_l1 | 候选商品细分意图类目 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 30106 | first_intention_l1 | 候选商品首要细分意图 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 30107 | global_cat | 候选商品全局一级类目 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 30108 | global_subcat | 候选商品全局二级类目 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 30109 | global_thirdcat | 候选商品全局三级类目 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 30110 | rate_bucket | 候选商品评分水平 | bucket |
| sparse | rcmd | others | item侧 | 30111 | thirdcat_price | 候选商品三级类目价格带 | join_string |
| sparse | rcmd | others | item侧 | 30112 | subcat_price | 候选商品二级类目价格带 | join_string |
| sparse | rcmd | others | item侧 | 30113 | l1_price | 候选商品意图类目价格带 | join_string |
| sparse | rcmd | others | item侧 | 30114 | item_discount_bucketized_2 | 候选商品当前折扣力度 | bucket |
| sparse | rcmd | click | item侧 | 30115 | item_NClick7_bucketized | 候选商品近7天点击热度 | bucket |
| sparse | rcmd | order | item侧 | 30116 | item_NOrder7_bucketized | 候选商品近7天下单热度 | bucket |
| sparse | rcmd | click | item侧 | 30117 | item_NClick30_bucketized | 候选商品近30天点击热度 | bucket |
| sparse | rcmd | order | item侧 | 30118 | item_NOrder30_bucketized | 候选商品近30天下单热度 | bucket |
| sparse | rcmd | others | item侧 | 30119 | item_Price_bucketized | 候选商品价格区间 | bucket |
| sparse | rcmd | click | item侧 | 30121 | item_NClick14_bucketized | 候选商品近14天点击热度 | bucket |
| sparse | rcmd | others | item侧 | 30123 | item_NImpression7_bucketized | 候选商品近7天曝光热度 | bucket |
| sparse | rcmd | others | item侧 | 30124 | item_NImpression14_bucketized | 候选商品近14天曝光热度 | bucket |
| sparse | rcmd | click | item侧 | 30126 | item_NCTR7_bucketized | 候选商品近7天点击率水平 | bucket |
| sparse | rcmd | click | item侧 | 30127 | item_NCTR14_bucketized | 候选商品近14天点击率水平 | bucket |
| sparse | rcmd | click | item侧 | 30128 | item_NCTR30_bucketized | 候选商品近30天点击率水平 | bucket |
| sparse | rcmd | click | item侧 | 30129 | item_NCR7_bucketized | 候选商品近7天转化率水平 | bucket |
| sparse | rcmd | click | item侧 | 30130 | item_NCR30_bucketized | 候选商品近30天转化率水平 | bucket |
| sparse | rcmd | others | item侧 | 30143 | recall_type_ctx_globalsubcat | 召回类型与主商品二级类目 | join_strings_string |
| sparse | rcmd | others | item侧 | 30144 | recall_type_ctx_intentionl0 | 召回类型与主商品一级意图 | join_strings_string |
| sparse | rcmd | click | item侧 | 30145 | recall_type_ctx_nclick7bin | 召回类型与近7天点击热度 | join_strings_string |
| sparse | rcmd | others | item侧 | 30146 | recall_type_ctx_ncart7bin | 召回类型与近7天加购热度 | join_strings_string |
| sparse | rcmd | order | item侧 | 30147 | recall_type_ctx_norder7bin | 召回类型与近7天下单热度 | join_strings_string |
| sparse | rcmd | others | item侧 | 30148 | recall_type_ctx_ncomment7bin | 召回类型与近7天评价热度 | join_strings_string |
| sparse | rcmd | click | item侧 | 30149 | recall_type_ctx_nclick30bin | 召回类型与近30天点击热度 | join_strings_string |
| sparse | rcmd | others | item侧 | 30150 | recall_type_ctx_ncart30bin | 召回类型与近30天加购热度 | join_strings_string |
| sparse | rcmd | order | item侧 | 30151 | recall_type_ctx_norder30bin | 召回类型与近30天下单热度 | join_strings_string |
| sparse | rcmd | others | item侧 | 30152 | recall_type_ctx_ncomment30bin | 召回类型与近30天评价热度 | join_strings_string |
| sparse | rcmd | others | item侧 | 30234 | itemitem_itemid | 主商品与候选商品关系 | join_string |
| sparse | rcmd | others | item侧 | 30235 | itemitem_shopid | 主店铺与候选店铺关系 | join_string |
| sparse | rcmd | others | item侧 | 30237 | itemitem_intentionl0 | 主商品与候选一级意图关系 | join_string |
| sparse | rcmd | others | item侧 | 30238 | itemitem_subcat | 主商品与候选二级类目关系 | join_string |
| sparse | rcmd | others | item侧 | 30239 | itemitem_priceBin | 主商品与候选价格带关系 | join_string |
| sparse | rcmd | order | item侧 | 30244 | itemitem_norder30bin | 主商品与候选销量带关系 | join_string |
| sparse | shared | others | 上下文 | 30248 | dump_upstream | 当前请求上游来源 | of_shared_arrow_feature |
| sparse | shared | click | item侧 | 30263 | user_long_term_session_click_itemid_join_sim_l3l2cat | 用户长期点击商品与候选关系 | get_string_list_by_index |
| sparse | shared | click | item侧 | 30279 | user_long_term_session_click_cart_label_attribution_sim_l3l2cat | 用户点击后加购的相似商品 | get_string_list_by_index |
| sparse | shared | click | item侧 | 30283 | user_long_term_session_click_order_label_attribution_sim_l3l2cat | 用户点击后下单的相似商品 | get_string_list_by_index |
| sparse | rcmd | others | item侧 | 30320 | item_shop_subcat_priceBin | 店铺在二级类目下价格带 | join_string |
| sparse | rcmd | others | item侧 | 30321 | item_shop_intentionl0_priceBin | 店铺在一级意图下价格带 | join_string |
| sparse | rcmd | others | item侧 | 30322 | item_shop_intentionl1_priceBin | 店铺在细分意图下价格带 | join_string |
| sparse | rcmd | others | item侧 | 30330 | item_global_thirdcat | 候选商品二三级类目组合 | join_string |
| sparse | rcmd | others | item侧 | 30331 | item_first_intentionl1 | 候选商品首要细分意图 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 30332 | item_intention_l1 | 候选商品细分意图标签 | of_iterable_arrow_feature |
| sparse | shared | others | item侧 | 30333 | item_position | 候选商品当前排序位置 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 30336 | item_impression7_bucket | 候选商品近7天曝光量级 | log |
| sparse | rcmd | click | item侧 | 30337 | item_nclick7_bucket_1 | 候选商品近7天点击量级 | log |
| sparse | rcmd | others | item侧 | 30338 | item_ncart7_bucket_1 | 候选商品近7天加购量级 | log |
| sparse | rcmd | order | item侧 | 30339 | item_norder7_bucket_1 | 候选商品近7天下单量级 | log |
| sparse | rcmd | others | item侧 | 30340 | item_impression30_bucket | 商品近30天曝光次数 | log |
| sparse | rcmd | click | item侧 | 30341 | item_nclick30_bucket_1 | 商品近30天点击次数 | log |
| sparse | rcmd | others | item侧 | 30342 | item_ncart30_bucket_1 | 商品近30天加购次数 | log |
| sparse | rcmd | order | item侧 | 30343 | item_norder30_bucket_1 | 商品近30天下单次数 | log |
| sparse | rcmd | others | item侧 | 30344 | item_price_bucket_1 | 商品当前售价区间 | log |
| sparse | rcmd | others | item侧 | 30345 | item_discount_bucket | 商品当前折扣力度 | log |
| sparse | rcmd | click | item侧 | 30346 | item_ctr7_bucket | 商品近7天点击率 | log |
| sparse | rcmd | others | item侧 | 30347 | item_cr7_bucket | 商品近7天下单转化率 | log |
| sparse | rcmd | order | item侧 | 30348 | item_ctcvr7_bucket | 商品近7天点购转化率 | log |
| sparse | rcmd | click | item侧 | 30349 | item_ctr30_bucket | 商品近30天点击率 | log |
| sparse | rcmd | others | item侧 | 30350 | item_cr30_bucket | 商品近30天下单转化率 | log |
| sparse | rcmd | order | item侧 | 30351 | item_ctcvr30_bucket | 商品近30天点购转化率 | log |
| sparse | rcmd | click | item侧 | 30352 | item_nclick14_bucket_1 | 商品近14天点击次数 | log |
| sparse | rcmd | others | item侧 | 30353 | item_impression14_bucket | 商品近14天曝光次数 | log |
| sparse | rcmd | others | item侧 | 30354 | item_freshness_bucket | 商品上架时长 | log |
| sparse | rcmd | others | item侧 | 30356 | item_freshness_thirdcat | 商品新鲜度与三级类目 | join_string |
| sparse | rcmd | others | item侧 | 30357 | item_freshness_join | 用户与店铺商品新鲜度关系 | join_string |
| sparse | rcmd | click | item侧 | 30358 | item_type_feature_1 | 商品是否本地发货特征 | join_string |
| sparse | rcmd | click | item侧 | 30359 | item_type_feature_2 | 商品本地发货与类目组合 | join_string |
| sparse | rcmd | others | 用户侧 | 30360 | user_mpiage | 用户年龄段 | of_shared_arrow_feature |
| sparse | rcmd | others | 用户侧 | 30361 | user_mpigender | 用户性别 | of_shared_arrow_feature |
| sparse | rcmd | click | 用户侧 | 30363 | user_perfer_global_subcat_topk_string | 用户偏好子类目序列 | join_strings |
| sparse | rcmd | click | 用户侧 | 30364 | user_type_feature_1 | 用户年龄性别偏好组合 | join_string |
| sparse | rcmd | click | item侧 | 30371 | ub_click_upstream_cross_cat_seq | 用户点击商品类目及来源序列 | join_strings_string |
| sparse | rcmd | others | item侧 | 30378 | ub_cart_upstream_cross_cat_seq | 用户加购商品类目及来源序列 | join_strings_string |
| sparse | rcmd | others | item侧 | 30496 | shop_nsold_log | 店铺累计销量 | log |
| sparse | rcmd | others | item侧 | 30497 | shop_nsold30_log | 店铺近30天销量 | log |
| sparse | rcmd | others | item侧 | 30498 | shop_rating_good_rate_1 | 店铺好评率 | log |
| sparse | rcmd | others | item侧 | 30499 | shop_rating_star_1 | 店铺评分星级 | log |
| sparse | rcmd | others | item侧 | 30509 | uid_subcat | 用户与商品子类目偏好组合 | join_string |
| sparse | rcmd | others | item侧 | 30510 | uid_thirdcat_1 | 用户与商品三级类目偏好组合 | join_string |
| sparse | rcmd | others | item侧 | 30511 | uid_intentionl0 | 用户与商品意图类目偏好组合 | join_string |
| sparse | rcmd | others | item侧 | 30512 | uid_shopid | 用户与店铺偏好组合 | join_string |
| sparse | rcmd | others | item侧 | 30516 | ctxt_item_pricebin_join | 当前商品与候选商品价格带组合 | join_string |
| sparse | shared | click | 用户侧 | 30531 | last_itemid | 用户最近一次点击的商品ID | action_queue_get_first_property_with_backup |
| sparse | shared | click | 用户侧 | 30532 | last_shopid | 用户最近一次点击的店铺ID | action_queue_get_first_property_with_backup |
| sparse | shared | click | 用户侧 | 30533 | last_item_global_subcat | 用户最近一次点击的商品子类目 | action_queue_get_first_property_with_backup |
| sparse | shared | click | 用户侧 | 30534 | last_item_global_thirdcat_1 | 用户最近一次点击的商品三级类目 | join_string |
| sparse | shared | click | 用户侧 | 30535 | last_item_intentionl0 | 用户最近一次点击的商品意图类目 | action_queue_get_first_property_with_backup |
| sparse | shared | click | 用户侧 | 30538 | last_item_ratestar_bucket | 用户最近一次点击商品评分档位 | bucket |
| sparse | shared | click | 用户侧 | 30540 | last_item_impression7_bucket | 用户最近一次点击商品7天曝光热度 | log |
| sparse | shared | click | 用户侧 | 30541 | last_item_nclick7_bucket | 用户最近一次点击商品7天点击热度 | log |
| sparse | shared | click | 用户侧 | 30542 | last_item_ncart7_bucket | 用户最近一次点击商品7天加购热度 | log |
| sparse | shared | click | 用户侧 | 30543 | last_item_norder7_bucket | 用户最近一次点击商品7天下单热度 | log |
| sparse | shared | click | 用户侧 | 30544 | last_item_impression30_bucket | 用户最近一次点击商品30天曝光热度 | log |
| sparse | shared | click | 用户侧 | 30545 | last_item_nclick30_bucket | 用户最近一次点击商品30天点击热度 | log |
| sparse | shared | click | 用户侧 | 30546 | last_item_ncart30_bucket | 用户最近一次点击商品30天加购热度 | log |
| sparse | shared | click | 用户侧 | 30547 | last_item_norder30_bucket | 用户最近一次点击商品30天下单热度 | log |
| sparse | shared | click | 用户侧 | 30548 | last_item_price_bucket | 用户最近一次点击商品价格档位 | log |
| sparse | shared | click | 用户侧 | 30549 | last_item_discount_bucket | 用户最近一次点击商品折扣档位 | log |
| sparse | shared | click | 用户侧 | 30550 | last_item_nclick14_bucket | 用户最近一次点击商品14天点击热度 | log |
| sparse | shared | click | 用户侧 | 30551 | last_item_ctr7_bucket | 用户最近一次点击商品7天点击率 | log |
| sparse | shared | click | 用户侧 | 30552 | last_item_cr7_bucket | 用户最近一次点击商品7天转化率 | log |
| sparse | shared | click | 用户侧 | 30553 | last_item_ctcvr7_bucket | 用户最近一次点击商品7天点购转化率 | log |
| sparse | shared | click | 用户侧 | 30554 | last_item_ctr30_bucket | 用户最近一次点击商品30天点击率 | log |
| sparse | shared | click | 用户侧 | 30555 | last_item_cr30_bucket | 用户最近一次点击商品30天转化率 | log |
| sparse | shared | click | 用户侧 | 30556 | last_item_ctcvr30_bucket | 用户最近一次点击商品30天点购转化率 | log |
| sparse | rcmd | others | 用户侧 | 30584 | utp_gender_age | 用户性别与年龄组合 | join_string |
| sparse | rcmd | others | 用户侧 | 30585 | user_country | 用户所在国家 | convert_case |
| sparse | rcmd | others | 用户侧 | 30586 | user_gender | 用户登记性别 | of_shared_arrow_feature |
| sparse | rcmd | others | item侧 | 30601 | item_price_bucket_2 | 商品价格区间 | log |
| sparse | rcmd | others | item侧 | 30602 | item_discount_bucket_1 | 商品折扣力度 | log |
| sparse | rcmd | others | item侧 | 30603 | item_sold_bucket_1 | 商品累计销量 | log |
| sparse | rcmd | others | item侧 | 30608 | shop_id_1 | 商品所属店铺ID | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 30609 | item_main_cat | 商品一级类目 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 30610 | global_subcat_1 | 商品二级类目 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 30611 | global_thirdcat_1 | 商品三级类目 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 30612 | price_sold | 商品价格与销量组合 | join_string |
| sparse | rcmd | others | item侧 | 30613 | discount_sold | 商品折扣与销量区间组合 | join_string |
| sparse | rcmd | others | item侧 | 30614 | price_globcat | 商品一级类目与价格区间组合 | join_string |
| sparse | rcmd | others | item侧 | 30615 | price_globsubcat | 商品二级类目与价格区间组合 | join_string |
| sparse | rcmd | others | item侧 | 30616 | price_globthirdcat | 商品三级类目与价格区间组合 | join_string |
| sparse | rcmd | others | item侧 | 30620 | gender_thirdcat | 用户性别与商品三级类目组合 | join_string |
| sparse | rcmd | others | item侧 | 30622 | uid_subcat_1 | 用户身份与商品二级类目组合 | join_string |
| sparse | rcmd | others | item侧 | 30623 | uid_thirdcat_2 | 用户身份与商品三级类目组合 | join_string |
| sparse | rcmd | others | item侧 | 30625 | discount_user_gender | 用户性别与商品折扣区间组合 | join_string |
| sparse | rcmd | others | item侧 | 30635 | utp_address_item_id | 用户常驻地与当前商品组合 | join_string |
| sparse | rcmd | others | item侧 | 30829 | item_Price_bucketized_1 | 商品价格区间 | bucket |
| sparse | rcmd | order | item侧 | 30837 | item_NOrder30_bucketized_1 | 商品近30天成交热度 | bucket |
| sparse | rcmd | click | item侧 | 30843 | item_NClick30_bucketized_1 | 商品近30天点击热度 | bucket |
| sparse | rcmd | others | item侧 | 30870 | user_category_l1_price_level | 用户在该类目的价格偏好层级 | find_value |
| sparse | rcmd | others | item侧 | 30897 | user_category_l1_price_level_X_global_thirdcat | 用户类目价格偏好与商品三级类目组合 | join_string |
| sparse | rcmd | others | item侧 | 31166 | item_like7_bucket | 商品近7天收藏热度 | log |
| sparse | rcmd | others | item侧 | 31167 | item_rate7_bucket | 商品近7天评价热度 | log |
| sparse | rcmd | others | item侧 | 31168 | item_comment7_bucket | 商品近7天评论热度 | log |
| sparse | rcmd | others | item侧 | 31170 | item_rate30_bucket | 商品近30天评价热度 | log |
| sparse | rcmd | others | item侧 | 31171 | item_comment30_bucket | 商品近30天评论热度 | log |
| sparse | rcmd | others | item侧 | 31172 | uid_shopid_1 | 用户身份与当前店铺组合 | join_string |
| sparse | rcmd | others | item侧 | 31173 | uid_price_bucket | 用户身份与商品价格区间组合 | join_string |
| sparse | rcmd | others | item侧 | 31174 | uid_discount_bucket | 用户身份与商品折扣区间组合 | join_string |
| sparse | shared | others | 上下文 | 31190 | pdp_item_id | 当前详情页商品标识 | of_shared_arrow_feature |
| sparse | shared | others | 上下文 | 31191 | pdp_shop_id | 当前详情页店铺标识 | of_shared_arrow_feature |
| sparse | rcmd | others | 上下文 | 31193 | pdp_intention_l0 | 当前详情页商品顶层意图类目 | of_shared_arrow_feature |
| sparse | rcmd | others | 上下文 | 31197 | pdp_global_subcat | 当前详情页商品二级类目 | of_shared_arrow_feature |
| sparse | rcmd | others | 上下文 | 31198 | pdp_global_thirdcat | 当前详情页商品三级类目 | of_shared_arrow_feature |
| sparse | rcmd | others | 用户侧 | 31199 | pdp_rate_bucket | 当前详情页商品评分星级 | bucket |
| sparse | rcmd | others | 用户侧 | 31200 | pdp_thirdcat_price | 当前详情页三级类目与价格组合 | join_string |
| sparse | rcmd | others | 用户侧 | 31201 | pdp_subcat_price | 当前详情页二级类目与价格组合 | join_string |
| sparse | shared | click | item侧 | 31235 | user_long_term_session_click_shopid_sim_l3l2cat | 用户长期点击相似店铺列表 | get_string_list_by_index |
| dense | shared | order | item侧 | 31245 | cate2_norder_avgsoldcntl0_reader | 商品二级类目平均销量水平 | of_iterable_arrow_feature |
| sparse | shared | click | 用户侧 | 31253 | longub_click_itemid_500 | 用户最近500次点击商品 | slice_list |
| sparse | shared | click | 用户侧 | 31254 | longub_click_shopid_500 | 用户最近500次点击店铺 | slice_list |
| sparse | shared | others | 上下文 | 31263 | pdp_item_id | 当前详情页商品标识 | of_shared_arrow_feature |
| sparse | shared | others | 上下文 | 31272 | pdp_item_id | 当前详情页商品标识 | of_shared_arrow_feature |
| sparse | shared | others | 用户侧 | 31327 | longub_cart_itemid_128 | 用户最近128次加购商品 | slice_list |
| sparse | shared | others | 用户侧 | 31328 | longub_cart_shopid_128 | 用户最近128次加购店铺 | slice_list |
| sparse | shared | order | 用户侧 | 31329 | longub_order_itemid_128 | 用户最近128次下单商品 | slice_list |
| sparse | shared | order | 用户侧 | 31330 | longub_order_shopid_128 | 用户最近128次下单店铺 | slice_list |
| sparse | shared | click | 用户侧 | 31331 | longub_click_subcat_500 | 用户最近点击商品二级类目序列 | slice_list |
| sparse | shared | click | 用户侧 | 31332 | longub_click_thirdcat_500 | 用户最近点击商品三级类目序列 | slice_list |
| sparse | shared | others | 用户侧 | 31333 | longub_cart_subcat_128 | 用户最近加购商品二级类目序列 | slice_list |
| sparse | shared | others | 用户侧 | 31334 | longub_cart_thirdcat_128 | 用户最近加购商品三级类目序列 | slice_list |
| sparse | shared | order | 用户侧 | 31335 | longub_order_subcat_128 | 用户最近下单商品二级类目序列 | slice_list |
| sparse | shared | order | 用户侧 | 31336 | longub_order_thirdcat_128 | 用户最近下单商品三级类目序列 | slice_list |
| sparse | shared | click | item侧 | 31384 | ub_click_hit_itemid_time_decay_bin | 用户近期点击过当前商品的新鲜度 | bucket |
| sparse | shared | others | item侧 | 31385 | ub_cart_hit_itemid_time_decay_bin | 用户近期加购过当前商品的新鲜度 | bucket |
| sparse | shared | order | item侧 | 31386 | ub_order_hit_itemid_time_decay_bin | 用户近期购买过当前商品的新鲜度 | bucket |
| sparse | rcmd | others | item侧 | 31388 | item_id | 当前候选商品标识 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 31401 | user_mpi_gender_price_bin | 用户性别与商品价格区间组合 | join_string |
| sparse | rcmd | others | item侧 | 31402 | user_mpi_age_price_bin | 用户年龄与商品价格区间组合 | join_string |
| sparse | rcmd | others | item侧 | 31404 | mpi_age_discount_bin_1 | 用户年龄与商品折扣区间组合 | join_string |
| sparse | rcmd | others | item侧 | 31406 | mpi_age_subcat | 用户年龄与商品二级类目组合 | join_string |
| sparse | rcmd | others | item侧 | 31408 | mpi_age_thirdcat | 用户年龄与商品三级类目组合 | join_string |
| sparse | rcmd | others | 用户侧 | 31446 | user_address | 用户常驻地与定位地址组合 | join_string |
| sparse | shared | click | item侧 | 31679 | ults_click_feature_detail_sim_l3l2cat | 用户长期点击行为细节标签 | get_string_list_by_index |
| sparse | rcmd | click | 用户侧 | 31715 | user_prefer_top_intentionl0_join | 用户多行为偏好的前五意图 | join_strings |
| sparse | rcmd | click | 用户侧 | 31719 | user_mpi_type_prefer_top_intentionl0_join | 同人群偏好的前五意图 | join_string |
| sparse | rcmd | click | 用户侧 | 31723 | user_mpi_city_prefer_top_intentionl0_join | 同城市偏好的前五意图 | join_string |
| sparse | rcmd | click | item侧 | 31779 | st_ub_click_intentionl0_avgprice_bucket | 用户短期点击意图的平均价格 | log |
| sparse | rcmd | others | item侧 | 31782 | st_ub_cart_intentionl0_avgprice_bucket | 用户短期加购意图的平均价格 | log |
| sparse | rcmd | order | item侧 | 31785 | st_ub_order_intentionl0_avgprice_bucket | 用户短期下单意图的平均价格 | log |
| sparse | rcmd | click | item侧 | 31787 | st_ub_scclick_thirdcat_avgprice_bucket | 用户短期点击三级类目的平均价格 | log |
| sparse | rcmd | click | item侧 | 31788 | st_ub_scclick_intentionl0_avgprice_bucket | 用户短期点击意图类目的平均价格 | log |
| sparse | shared | click | 用户侧 | 32005 | st_ub_click_active_level_d1 | 用户近1天点击活跃度 | bucket |
| sparse | shared | click | 用户侧 | 32006 | st_ub_click_active_level_d3 | 用户近3天点击活跃度 | bucket |
| sparse | shared | click | item侧 | 32173 | lt_ub_click_subcat_rp_1 | 用户二级类目点击重复周期 | bucket |
| sparse | shared | click | item侧 | 32174 | lt_ub_click_thirdcat_rp_1 | 用户三级类目点击重复周期 | bucket |
| sparse | shared | click | item侧 | 32175 | lt_ub_click_price_bucket_rp_1 | 用户价格偏好点击重复周期 | bucket |
| sparse | shared | others | item侧 | 32178 | lt_ub_cart_price_bucket_rp_1 | 用户价格偏好加购重复周期 | bucket |
| sparse | shared | order | item侧 | 32181 | lt_ub_order_price_bucket_rp_1 | 用户价格偏好下单重复周期 | bucket |
| sparse | shared | click | item侧 | 32182 | lt_ub_click_subcat_time_lapse_2 | 用户距上次点击该二级类目的时长 | bucket |
| sparse | shared | click | item侧 | 32183 | lt_ub_click_thirdcat_time_lapse_2 | 用户距上次点击该三级类目的时长 | bucket |
| sparse | shared | order | item侧 | 32186 | lt_ub_order_subcat_time_lapse_2 | 用户距上次下单该二级类目的时长 | bucket |
| sparse | shared | order | item侧 | 32187 | lt_ub_order_thirdcat_time_lapse_2 | 用户距上次下单该三级类目的时长 | bucket |
| sparse | shared | click | 用户侧 | 32232 | lt_ub_click_uncart_7d_indices_size_1 | 用户近7天点击未加购商品数 | log |
| sparse | rcmd | others | item侧 | 32233 | userid_intentionl1 | 用户身份与商品一级兴趣类目组合 | join_string |
| sparse | rcmd | others | item侧 | 32238 | user_mpi_type_itemid | 用户性别年龄与当前商品组合 | join_string |
| sparse | rcmd | others | item侧 | 32244 | user_mpi_type_price_bucket | 用户性别年龄与商品价格区间组合 | join_string |
| sparse | rcmd | others | item侧 | 32246 | user_mpi_city_itemid | 用户城市与当前商品组合 | join_string |
| sparse | rcmd | others | item侧 | 32247 | user_mpi_city_shopid | 用户城市与当前店铺组合 | join_string |
| sparse | rcmd | others | item侧 | 32250 | user_mpi_city_intentionl0 | 用户城市与商品顶层意图组合 | join_string |
| sparse | rcmd | click | item侧 | 32280 | item_ctr7_bucket_1 | 商品近7天点击率水平 | log |
| sparse | rcmd | others | item侧 | 32281 | item_cr7_bucket_1 | 商品近7天成交转化率水平 | log |
| sparse | rcmd | click | item侧 | 32282 | item_ctr30_bucket_1 | 商品近30天点击率水平 | log |
| sparse | rcmd | others | item侧 | 32283 | item_cr30_bucket_1 | 商品近30天成交转化率水平 | log |
| sparse | rcmd | others | item侧 | 32284 | item_discount_bucket_2 | 商品折扣力度区间 | bucket |
| sparse | rcmd | others | item侧 | 32286 | item_l2l3cat_price_bucket | 商品二三级类目与价格组合 | join_string |
| sparse | rcmd | click | item侧 | 32287 | item_l2l3cat_click7_bucket | 商品二三级类目与近7天点击热度组合 | join_string |
| sparse | rcmd | others | item侧 | 32288 | item_l2l3cat_cart7_bucket | 商品二三级类目与近7天加购热度组合 | join_string |
| sparse | rcmd | order | item侧 | 32289 | item_l2l3cat_order7_bucket | 商品二三级类目与近7天成交热度组合 | join_string |
| sparse | rcmd | click | item侧 | 32290 | item_l2l3cat_click30_bucket | 商品二三级类目与近30天点击热度组合 | join_string |
| sparse | rcmd | others | item侧 | 32291 | item_l2l3cat_cart30_bucket | 商品二三级类目与近30天加购热度组合 | join_string |
| sparse | rcmd | order | item侧 | 32292 | item_l2l3cat_order30_bucket | 商品三级类目与近30天销量组合 | join_string |
| sparse | shared | click | 用户侧 | 32315 | lt_ubtop_click_uncart_subcat_7d_indices_1 | 用户近7天点击未加购的偏好二级类目 | join_strings_list |
| sparse | shared | click | 用户侧 | 32320 | lt_ubtop_click_uncart_thirdcat_7d_indices_1 | 用户近7天点击未加购的偏好三级类目 | join_strings_list |
| sparse | rcmd | click | item侧 | 32340 | lt_ubtop_click_uncart_thirdcat_7d_indices_join | 商品三级类目与用户近7天未加购偏好匹配 | join_strings_string |
| sparse | shared | click | item侧 | 32388 | lt_ub_click_l2l3cat_price_bucket_l3l2cat_indices | 用户长周期点击的类目价格偏好 | join_strings_list |
| sparse | shared | others | 用户侧 | 32415 | lt_ub_cart_itemid_0d_indices | 用户近期加购商品列表 | get_string_list_by_index |
| sparse | shared | others | 用户侧 | 32416 | lt_ub_cart_shopid_0d_indices | 用户近期加购店铺列表 | get_string_list_by_index |
| sparse | shared | order | 用户侧 | 32435 | lt_ub_order_itemid_0d_indices | 用户近期下单商品列表 | get_string_list_by_index |
| sparse | shared | order | 用户侧 | 32436 | lt_ub_order_shopid_0d_indices | 用户近期下单店铺列表 | get_string_list_by_index |
| sparse | shared | order | 用户侧 | 32437 | lt_ub_order_subcat_0d_indices | 用户近期下单二级类目列表 | get_string_list_by_index |
| sparse | shared | order | 用户侧 | 32438 | lt_ub_order_thirdcat_0d_indices | 用户近期下单三级类目列表 | get_string_list_by_index |
| sparse | shared | click | 用户侧 | 32455 | lt_ubtop_click_subcat_0d_indices_1 | 用户近期点击最高频二级类目 | join_strings_list |
| sparse | shared | click | 用户侧 | 32456 | lt_ubtop_click_thirdcat_0d_indices_1 | 用户近期点击最高频三级类目 | join_strings_list |
| sparse | shared | click | 用户侧 | 32457 | lt_ubtop_click_l2l3cat_price_bucket_0d_indices_1 | 用户近期点击最高频类目价格组合 | join_strings_list |
| sparse | rcmd | others | item侧 | 32521 | shop_rating_good_rate_bucket | 店铺好评率水平 | log |
| sparse | rcmd | others | item侧 | 32522 | shop_rating_star_bucket | 店铺星级评分 | log |
| sparse | rcmd | others | item侧 | 32523 | shop_nitem_bucket | 店铺在售商品规模 | log |
| sparse | rcmd | others | item侧 | 32524 | shop_nsold_bucket | 店铺累计成交规模 | log |
| sparse | rcmd | others | item侧 | 32525 | shop_nsold7_bucket | 店铺近7天成交规模 | log |
| sparse | rcmd | others | item侧 | 32526 | shop_nsold30_bucket | 店铺近30天成交规模 | log |
| sparse | rcmd | others | item侧 | 32529 | shop_follow_count_bucket | 店铺粉丝规模 | log |
| sparse | rcmd | others | item侧 | 32533 | shop_revisit_rate_bucket | 店铺回访率水平 | bucket |
| sparse | rcmd | order | item侧 | 32534 | shop_conversion_rate_bucket | 店铺成交转化率水平 | bucket |
| sparse | rcmd | others | item侧 | 32535 | shop_repurchase_rate_bucket | 店铺复购率水平 | bucket |
| sparse | rcmd | others | item侧 | 32536 | shop_revisit_itemid | 商品与店铺回访率组合 | join_string |
| sparse | rcmd | others | item侧 | 32539 | shop_revisit_intention | 商品意图与店铺回访率组合 | join_string |
| sparse | rcmd | others | item侧 | 32540 | shop_repurchase_itemid | 商品与店铺复购率组合 | join_string |
| sparse | rcmd | others | item侧 | 32543 | shop_repurchase_intention | 商品意图与店铺复购率组合 | join_string |
| sparse | rcmd | order | item侧 | 32544 | shop_conversion_itemid | 商品与店铺转化率组合 | join_string |
| sparse | rcmd | order | item侧 | 32547 | shop_conversion_intention | 商品意图与店铺转化率组合 | join_string |
| sparse | shared | click | 用户侧 | 32605 | last_item_price_bucket_2 | 用户最近点击商品价格对比当前商品 | bucket |
| sparse | shared | click | 用户侧 | 32611 | last_item_nclick30_bucket_2 | 用户最近点击商品热度对比当前商品 | bucket |
| sparse | shared | click | 用户侧 | 32612 | last_item_NCTR30_bucket_2 | 用户最近点击商品点击率对比当前商品 | bucket |
| sparse | shared | click | 用户侧 | 32613 | last_item_NOrder30_bucket_2 | 用户最近点击商品下单热度对比当前商品 | bucket |
| sparse | shared | click | 用户侧 | 32614 | last_item_NCR30_bucket_2 | 用户最近点击商品下单转化对比当前商品 | bucket |
| sparse | rcmd | others | item侧 | 32770 | shop_official | 店铺是否官方认证 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 32776 | shop_tag | 店铺是否有券或活动 | of_iterable_arrow_feature |
| sparse | search | others | 用户侧 | 33003 | const_str_search | 搜索场景固定标识 | const_string |
| sparse | rcmd | others | item侧 | 33124 | item_repurchase_rate_bucket | 商品复购率水平 | bucket |
| sparse | rcmd | others | item侧 | 33128 | item_repurchase_intention | 商品意图与复购率组合 | join_string |
| sparse | rcmd | others | item侧 | 33189 | st_ub_cart_intentionl0_avgprice_bucket | 用户加购商品在该意图下平均价格 | log |
| sparse | rcmd | order | item侧 | 33192 | st_ub_order_intentionl0_avgprice_bucket | 用户下单商品在该意图下平均价格 | log |
| sparse | rcmd | click | item侧 | 33263 | lt_ub_click_thirdcat_6h_hit_count_1 | 候选商品在用户近6小时点击类目命中强度 | log |
| sparse | rcmd | click | item侧 | 33265 | lt_ub_click_thirdcat_24h_hit_count_1 | 候选商品在用户近24小时点击类目命中强度 | log |
| sparse | rcmd | order | item侧 | 33280 | st_ub_order_avgprice_top_diff_v1_1 | 当前商品价格与用户近期下单均价差异 | bucket |
| sparse | rcmd | others | item侧 | 33319 | st_ub_incart_intentionl0_avgprice_bucket | 用户在购商品该意图平均价格 | log |
| sparse | rcmd | others | item侧 | 33386 | mpp_item_intentionl0_avgprice_bucket | 候选商品意图对应补充商品均价 | log |
| sparse | rcmd | click | item侧 | 33439 | user_long_term_session_click_self_decay_bucket_sim_l3l2cat | 候选商品在用户点击衰减偏好中的匹配度 | get_value_by_index |
| sparse | shared | click | item侧 | 33617 | user_long_term_session_click_itemid_sim_l3l2cat | 用户长周期点击相似类目商品 | get_string_list_by_index |
| sparse | shared | click | item侧 | 33694 | user_long_term_session_click_itemid_join_sim_l3l2cat | 用户长周期点击商品序列 | get_string_list_by_index |
| sparse | shared | click | item侧 | 33789 | user_long_term_session_click_itemid_join_sim_l3l2cat | 用户长周期点击商品序列 | get_string_list_by_index |
| dense | shared | order | item侧 | 33868 | cate2_norder_avgsoldcntl7_reader | 商品二级类目近7天平均销量 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 33944 | item_price_fluc_bucket | 商品价格波动幅度 | bucket |
| sparse | rcmd | others | item侧 | 33947 | item_fluc_price_mpi_join | 商品价格波动与价格水平组合 | join_string |
| sparse | rcmd | others | item侧 | 33951 | promotion_type_1 | 商品促销类型 | of_iterable_arrow_feature |
| sparse | shared | others | 上下文 | 33982 | pdp_shop_id | 当前浏览商品所属店铺 | of_shared_arrow_feature |
| sparse | rcmd | others | item侧 | 34159 | is_preferred | 商品所属店铺是否优选 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 34163 | is_fss_shop | 商品所属店铺是否包邮服务 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 34169 | estimated_days_to_ship_log_bucket | 商品预计发货时长 | log |
| sparse | rcmd | others | item侧 | 34172 | estimated_days_to_ship_intention | 商品意图与预计发货时长组合 | join_string |
| sparse | rcmd | others | item侧 | 34173 | has_lowest_price_guarantee | 商品是否有低价保障 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 34180 | is_cc_instalment | 商品是否支持信用分期 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 34183 | stock_location | 商品发货仓类型 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 34184 | stock_location_uid | 用户与发货仓类型偏好匹配 | join_string |
| sparse | rcmd | others | item侧 | 34187 | is_ccb_shop | 商品所属店铺是否跨境 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 34200 | has_voucher_label | 商品是否带优惠券标识 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 34204 | has_voucher_label_price_bucket | 优惠券标识与商品价格组合 | join_string |
| sparse | rcmd | others | item侧 | 34207 | item_discount_bucketized | 商品折扣力度 | bucket |
| sparse | shared | others | 上下文 | 34263 | pdp_item_id | 当前浏览商品标识 | of_shared_arrow_feature |
| sparse | shared | others | item侧 | 34776 | recall_vote_name_norm_new | 商品召回来源丰富度 | sum |
| sparse | rcmd | others | item侧 | 34831 | item_free_shipping | 商品是否包邮 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 34839 | item_ship_from_domestic | 商品是否本地发货 | of_iterable_arrow_feature |
| sparse | rcmd | order | item侧 | 34915 | uf_order_subcat_hit | 候选商品类目是否命中用户下单偏好 | check_contain |
| sparse | rcmd | order | item侧 | 34917 | uf_order_intentionl0_hit | 候选商品意图是否命中用户下单偏好 | check_contain |
| sparse | rcmd | click | item侧 | 34921 | uf_click_intentionl0_hit | 候选商品意图是否命中用户点击偏好 | check_contain |
| sparse | rcmd | others | item侧 | 35698 | item_createtime | 商品上架创建时间 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 35803 | shop_id_1 | 商品所属店铺标识 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 35875 | global_subcat_1 | 商品二级类目 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 35876 | global_thirdcat_1 | 商品三级类目 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 36333 | intention_l0 | 商品一级意图标签 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 36334 | first_intention_l1 | 商品细分意图标签 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 36335 | item_main_cat | 商品一级类目 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 36336 | global_subcat_1 | 商品二级类目 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 36337 | global_thirdcat_1 | 商品三级类目 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 36338 | price_sold | 商品价格与销量组合 | join_string |
| sparse | rcmd | others | item侧 | 36339 | discount_sold | 商品折扣与销量组合 | join_string |
| sparse | rcmd | others | item侧 | 36340 | price_globcat | 商品类目与价格组合 | join_string |
| sparse | rcmd | others | item侧 | 36341 | price_globsubcat | 商品二级类目与价格组合 | join_string |
| sparse | rcmd | others | item侧 | 36342 | price_globthirdcat | 商品三级类目与价格组合 | join_string |
| sparse | rcmd | click | item侧 | 36343 | item_NCTR30_bucketized | 商品近30天点击率 | bucket |
| sparse | rcmd | click | item侧 | 36344 | item_NClick30_bucketized_1 | 商品近30天点击量 | bucket |
| sparse | rcmd | click | item侧 | 36345 | item_NCR30_bucketized | 商品近30天下单转化率 | bucket |
| sparse | rcmd | others | item侧 | 36346 | item_Price_bucketized_1 | 商品价格区间 | bucket |
| sparse | rcmd | others | item侧 | 36348 | shop_id_1 | 商品所属店铺标识 | of_iterable_arrow_feature |
| dense | shared | others | item侧 | 49092 | I_p_price_usd_bucket | 商品美元价格区间 | bucket |
| sparse | search | order | item侧 | 51080 | S_i_shop_cvr30 | 该商品所属店铺近30天成交转化水平 | bucket_double |
| dense | shared | order | item侧 | 53832 | cate2_norder_avgsoldcntl9_reader | 二级类目长周期平均销量 | of_iterable_arrow_feature |
| dense | shared | order | item侧 | 59320 | cate2_norder_avgsoldcntl3_reader | 二级类目中周期平均销量 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 60000 | item_id | 候选商品标识 | of_iterable_arrow_feature |
| sparse | rcmd | others | item侧 | 60002 | item_id | 候选商品标识 | of_iterable_arrow_feature |
| onehot | rcmd | others | item侧 | 60135 | export_concat_slot_297_tVO6p_DkBtb-a2MKBhx-bw | 候选商品与当前浏览商品相似度 | dense_concat |
| onehot | rcmd | others | item侧 | 60136 | export_concat_slot_298_Wim4U2Dfqlj-OikeQh8ALg | 候选商品与当前商品权益匹配度 | dense_concat |
| onehot | rcmd | click | item侧 | 60137 | export_concat_slot_299_W27NsHNX-qU24ENT8ArqXw | 候选商品与当前商品综合对比 | dense_concat |
| dense | shared | click | 用户侧 | 60167 | export_concat_slot_371_vdqwJ3HbvYTfALVQC5pp8Q | 用户点击未加购数量趋势 | dense_concat |
| sparse | rcmd | others | 用户侧 | 60168 | user_id | 用户标识 | of_shared_arrow_feature |
| sparse | rcmd | others | item侧 | 60169 | shop_id_1 | 店铺标识 | of_iterable_arrow_feature |
| dense | search | click | 用户侧 | 60174 | export_concat_slot_104_wuPPMdMpszjquGPvPzMSsQ | 用户多行为近时窗次数统计 | dense_concat |
| onehot | rcmd | click | item侧 | 60177 | export_concat_slot_251_49q7Y5n7LhUE_fHOz7tlcg | 候选商品与用户全行为偏好匹配度 | dense_concat |
| onehot | rcmd | click | item侧 | 60192 | export_concat_slot_200_DMRxUkKT2oQ-fb3BdObonQ | 商品包邮店铺资质及用户历史命中 | dense_concat |
| sparse | rcmd | others | 用户侧 | 60210 | user_id | 用户身份标识 | of_shared_arrow_feature |
| dense | shared | order | item侧 | 62955 | cate2_norder_avgsoldcntl6_reader | 商品二级类目平均销量水平 | of_iterable_arrow_feature |
| dense | shared | order | item侧 | 64433 | cate2_norder_avgsoldcntl8_reader | 商品二级类目长期平均销量水平 | of_iterable_arrow_feature |


#### 2.1.2 cali Slot 速查表 / Cali Slot Quick Reference

| Slot ID | 代码变量名 | 维度 | 数据来源 | 更新频率 | 用途 |
|---------|-----------|------|---------|---------|------|
| **SIR 10 桶 — Direct** |
| 16501 | `DIRECT_AVG_GMV_7D_ALL_SLOT_10[0]` | 11 | FSE 离线管线 | 1h | SIR y 轴 (GMV/click) |
| 16504 | `DIRECT_AVG_GMV_7D_ALL_SLOT_10[1]` | 11 | FSE 离线管线 | 24h | SIR y 轴 |
| 16502 | `DIRECT_AVG_PGMV_7D_ALL_SLOT_10[0]` | 11 | FSE 离线管线 | 1h | SIR x 轴 (pGMV/click) |
| 16505 | `DIRECT_AVG_PGMV_7D_ALL_SLOT_10[1]` | 11 | FSE 离线管线 | 24h | SIR x 轴 |
| **SIR 10 桶 — Shop** |
| 16507 | `SHOP_AVG_GMV_7D_ALL_SLOT_10[0]` | 11 | FSE 离线管线 | 1h | SIR y 轴 |
| 16510 | `SHOP_AVG_GMV_7D_ALL_SLOT_10[1]` | 11 | FSE 离线管线 | 24h | SIR y 轴 |
| 16508 | `SHOP_AVG_PGMV_7D_ALL_SLOT_10[0]` | 11 | FSE 离线管线 | 1h | SIR x 轴 |
| 16511 | `SHOP_AVG_PGMV_7D_ALL_SLOT_10[1]` | 11 | FSE 离线管线 | 24h | SIR x 轴 |
| **SIR 5 桶 — Direct** |
| 16513 | `DIRECT_AVG_GMV_7D_ALL_SLOT_5[0]` | 6 | FSE 离线管线 | 1h | SIR y 轴 (SG/TH) |
| 16516 | `DIRECT_AVG_GMV_7D_ALL_SLOT_5[1]` | 6 | FSE 离线管线 | 24h | SIR y 轴 |
| 16514 | `DIRECT_AVG_PGMV_7D_ALL_SLOT_5[0]` | 6 | FSE 离线管线 | 1h | SIR x 轴 |
| 16517 | `DIRECT_AVG_PGMV_7D_ALL_SLOT_5[1]` | 6 | FSE 离线管线 | 24h | SIR x 轴 |
| **SIR 5 桶 — Shop** |
| 16519 | `SHOP_AVG_GMV_7D_ALL_SLOT_5[0]` | 6 | FSE 离线管线 | 1h | SIR y 轴 |
| 16522 | `SHOP_AVG_GMV_7D_ALL_SLOT_5[1]` | 6 | FSE 离线管线 | 24h | SIR y 轴 |
| 16520 | `SHOP_AVG_PGMV_7D_ALL_SLOT_5[0]` | 6 | FSE 离线管线 | 1h | SIR x 轴 |
| 16523 | `SHOP_AVG_PGMV_7D_ALL_SLOT_5[1]` | 6 | FSE 离线管线 | 24h | SIR x 轴 |
| **Item 粒度** |
| 6136 | `DIRECT_AVG_GMV_7D_ALL_SLOT_ITEM[0]` | 1 | FSE 离线管线 | 1d | ItemCali scale 分子 |
| 6177 | `DIRECT_AVG_GMV_7D_ALL_SLOT_ITEM[1]` | 1 | FSE 离线管线 | 3d | ItemCali scale 分子 |
| 6137 | `DIRECT_AVG_PGMV_7D_ALL_SLOT_ITEM[0]` | 1 | FSE 离线管线 | 1d | ItemCali scale 分母 |
| 6178 | `DIRECT_AVG_PGMV_7D_ALL_SLOT_ITEM[1]` | 1 | FSE 离线管线 | 3d | ItemCali scale 分母 |
| 6138 | `SHOP_AVG_GMV_7D_ALL_SLOT_ITEM[0]` | 1 | FSE 离线管线 | 1d | ItemCali scale 分子 |
| 6179 | `SHOP_AVG_GMV_7D_ALL_SLOT_ITEM[1]` | 1 | FSE 离线管线 | 3d | ItemCali scale 分子 |
| 6139 | `SHOP_AVG_PGMV_7D_ALL_SLOT_ITEM[0]` | 1 | FSE 离线管线 | 1d | ItemCali scale 分母 |
| 6180 | `SHOP_AVG_PGMV_7D_ALL_SLOT_ITEM[1]` | 1 | FSE 离线管线 | 3d | ItemCali scale 分母 |
| 6181 | `DIRECT_ORDER_CNT_SLOT` | 1 | FSE 离线管线 | 3d | 订单数门控 |
| 6182 | `SHOP_ORDER_CNT_SLOT` | 1 | FSE 离线管线 | 3d | 订单数门控 |
| 6990 | `ZERO_ORDER_DAYS_CNT_SLOT` | 1 | FSE 离线管线 | 5d | 零单衰减（当前未生效） |
| **上下文 & 大促** |
| 46354 | region | 1 | FSE (rcmd) | 实时 | Region 编码 |
| 8888 | cur_time | 1 | Context | 实时 | 当前请求时间戳 |
| 1224 | entrance | 1 | Context | 实时 | 流量入口 |
| 6200 | start_time_base | 1 | FSE (运营 SQL) | 大促前更新 | 大促基准时间戳 |
| 6201 | prom_scale | 1 | FSE (运营 SQL) | 大促前更新 | 大促强度系数 |


#### 2.1.3 不同 Region 模型的特征差异 / Regional Feature Differences

对比 `ego_models/model_modules/unicr_l2_v3` 与 `ego_models/model_modules/unicr_v3` 后，主干特征集合基本一致：dense、one-hot、query、target、click/cart/order sequence、price、sold count、org predict 和 calibration 相关 slot 均无差异。

差异主要集中在 region 专用配置：

- `unicr_l2_v3` 的 region 模型额外保留 `REGION_SPARSE_SLOT=30585`（`user_country`）和 `REGION_DENSE_SLOT=46354`（`user_country_dense`），并在模型中将 `region_indicator` 传入 `HardBucketizeLayer` / `AutoDisLayer(num_regions=8)`，使 pctr/pcr bucket embedding 与 AutoDis 参数具备 region-conditioned 行为。
- `unicr_v3` 不再保留单独的 `REGION_*` 配置和 region-conditioned 分支；`30585` 仍作为普通 sparse slot 参与统一 sparse 输入。
- `unicr_v3` 的 `X_SPARSE_SLOT` 配置中直接包含新增的 136 个 ID/实时/行为类 sparse slot；`unicr_l2_v3/delf_other_region_prob.py` 会在代码里追加同一批 `feav136`，并将旧的 `DELETE_SLOTS=[31231,30370,30460,30431,30438,30647,30762]` 置零。因此以有效输入看，当前主入口的 sparse 特征集合与 `unicr_v3` 基本一致。
- `EXTRA_SLOT` 上 `unicr_v3` 比 `unicr_l2_v3` 少 `30460`、`30647`，这两个 slot 在 L2 region 入口中属于待删除/置零的旧特征，不构成当前有效主干特征差异。

因此，若讨论“不同 region 模型”之间的有效特征差异，主要应关注 region 专用配置和 region-conditioned 参数使用方式，而不是主干 slot 集合本身。


### 2.2 特征覆盖率分析 / Feature Coverage Analysis



基于本次实时拉取的 Google Sheet 字段 `zero_rate` / `empty_rate` 分桶统计。



#### 2.2.1 零值率（zero_rate）分桶 / Zero Rate Buckets



| 区间 | 特征数 | Slot 列表 |

|------|------|------|

| [0.0, 0.1) | 481 | 1006, 1008, 1011, 1038, 1044, 1058, 1065, 1068, 1069, 1072, 1074, 1078, 1079, 1084, 1093, 1094, 1095, 1097, 1098, 1099, 1100, 1107, 1108, 1109, 1124, 1129, 1132, 1138, 1139, 1141, 1143, 1145, 1154, 1157, 1158, 1160, 1166, 1167, 1174, 1183, 1190, 1191, 1205, 1206, 1207, 1212, 1214, 1216, 1217, 1224, 1600, 1602, 1613, 1614, 2117, 2186, 2312, 2503, 2504, 2505, 2506, 2507, 2508, 2531, 2532, 2534, 2541, 2542, 2548, 2558, 4092, 5005, 5033, 5071, 5078, 5082, 5098, 6174, 6175, 6176, 6189, 6204, 6208, 6262, 6270, 6272, 6275, 6276, 6277, 6281, 6317, 6320, 7014, 7019, 7035, 8017, 8018, 8019, 8024, 8036, 8037, 8047, 8050, 8094, 8096, 8102, 8103, 8105, 8106, 8131, 8132, 8140, 8141, 8159, 8163, 8164, 8166, 9936, 9938, 9939, 9940, 9969, 9971, 9980, 9981, 9982, 12337, 12363, 12364, 12381, 12385, 12387, 12395, 12403, 12408, 18152, 23168, 23178, 23748, 30000, 30001, 30002, 30003, 30004, 30082, 30083, 30084, 30085, 30086, 30089, 30090, 30091, 30092, 30093, 30096, 30097, 30102, 30103, 30104, 30105, 30106, 30107, 30108, 30109, 30110, 30111, 30112, 30113, 30114, 30115, 30116, 30117, 30118, 30119, 30121, 30123, 30124, 30126, 30127, 30128, 30129, 30130, 30143, 30144, 30145, 30146, 30147, 30148, 30149, 30150, 30151, 30152, 30234, 30235, 30237, 30238, 30239, 30244, 30248, 30263, 30279, 30283, 30320, 30321, 30322, 30330, 30331, 30332, 30333, 30336, 30337, 30338, 30339, 30340, 30341, 30342, 30343, 30344, 30345, 30346, 30347, 30348, 30349, 30350, 30351, 30352, 30353, 30354, 30356, 30357, 30358, 30359, 30360, 30361, 30363, 30364, 30371, 30378, 30496, 30497, 30498, 30499, 30509, 30510, 30511, 30512, 30516, 30531, 30532, 30533, 30534, 30535, 30538, 30540, 30541, 30542, 30543, 30544, 30545, 30546, 30547, 30548, 30549, 30550, 30551, 30552, 30553, 30554, 30555, 30556, 30584, 30585, 30586, 30601, 30602, 30603, 30608, 30609, 30610, 30611, 30612, 30613, 30614, 30615, 30616, 30620, 30622, 30623, 30625, 30635, 30829, 30837, 30843, 30870, 30897, 31166, 31167, 31168, 31170, 31171, 31172, 31173, 31174, 31190, 31191, 31193, 31197, 31198, 31199, 31200, 31201, 31235, 31253, 31254, 31263, 31272, 31327, 31328, 31329, 31330, 31331, 31332, 31333, 31334, 31335, 31336, 31384, 31385, 31386, 31388, 31401, 31402, 31404, 31406, 31408, 31446, 31679, 31715, 31719, 31723, 31779, 31782, 31785, 31787, 31788, 32005, 32006, 32173, 32174, 32175, 32178, 32181, 32182, 32183, 32186, 32187, 32232, 32233, 32238, 32244, 32246, 32247, 32250, 32280, 32281, 32282, 32283, 32284, 32286, 32287, 32288, 32289, 32290, 32291, 32292, 32315, 32320, 32340, 32388, 32415, 32416, 32435, 32436, 32437, 32438, 32455, 32456, 32457, 32521, 32522, 32523, 32524, 32525, 32526, 32529, 32533, 32534, 32535, 32536, 32539, 32540, 32543, 32544, 32547, 32605, 32611, 32612, 32613, 32614, 32770, 32776, 33003, 33124, 33128, 33189, 33192, 33263, 33265, 33280, 33319, 33386, 33439, 33617, 33694, 33789, 33944, 33947, 33951, 33982, 34159, 34163, 34169, 34172, 34173, 34180, 34183, 34184, 34187, 34200, 34204, 34207, 34263, 34776, 34831, 34839, 34915, 34917, 34921, 35698, 35803, 35875, 35876, 36333, 36334, 36335, 36336, 36337, 36338, 36339, 36340, 36341, 36342, 36343, 36344, 36345, 36346, 36348, 49092, 51080, 60000, 60002, 60135, 60136, 60137, 60167, 60168, 60169, 60174, 60177, 60192, 60210 |

| [0.1, 0.2) | 0 | |

| [0.2, 0.3) | 0 | |

| [0.3, 0.4) | 12 | 1003, 1004, 8669, 11748, 14749, 19902, 31245, 33868, 53832, 59320, 62955, 64433 |

| [0.4, 0.5) | 0 | |

| [0.5, 0.6) | 0 | |

| [0.6, 0.7) | 0 | |

| [0.7, 0.8) | 0 | |

| [0.8, 0.9) | 0 | |

| [0.9, 1.0] | 0 | |



#### 2.2.2 空值率（empty_rate）分桶 / Empty Rate Buckets



| 区间 | 特征数 | Slot 列表 |

|------|------|------|

| [0.0, 0.1) | 493 | 1003, 1004, 1006, 1008, 1011, 1038, 1044, 1058, 1065, 1068, 1069, 1072, 1074, 1078, 1079, 1084, 1093, 1094, 1095, 1097, 1098, 1099, 1100, 1107, 1108, 1109, 1124, 1129, 1132, 1138, 1139, 1141, 1143, 1145, 1154, 1157, 1158, 1160, 1166, 1167, 1174, 1183, 1190, 1191, 1205, 1206, 1207, 1212, 1214, 1216, 1217, 1224, 1600, 1602, 1613, 1614, 2117, 2186, 2312, 2503, 2504, 2505, 2506, 2507, 2508, 2531, 2532, 2534, 2541, 2542, 2548, 2558, 4092, 5005, 5033, 5071, 5078, 5082, 5098, 6174, 6175, 6176, 6189, 6204, 6208, 6262, 6270, 6272, 6275, 6276, 6277, 6281, 6317, 6320, 7014, 7019, 7035, 8017, 8018, 8019, 8024, 8036, 8037, 8047, 8050, 8094, 8096, 8102, 8103, 8105, 8106, 8131, 8132, 8140, 8141, 8159, 8163, 8164, 8166, 8669, 9936, 9938, 9939, 9940, 9969, 9971, 9980, 9981, 9982, 11748, 12337, 12363, 12364, 12381, 12385, 12387, 12395, 12403, 12408, 14749, 18152, 19902, 23168, 23178, 23748, 30000, 30001, 30002, 30003, 30004, 30082, 30083, 30084, 30085, 30086, 30089, 30090, 30091, 30092, 30093, 30096, 30097, 30102, 30103, 30104, 30105, 30106, 30107, 30108, 30109, 30110, 30111, 30112, 30113, 30114, 30115, 30116, 30117, 30118, 30119, 30121, 30123, 30124, 30126, 30127, 30128, 30129, 30130, 30143, 30144, 30145, 30146, 30147, 30148, 30149, 30150, 30151, 30152, 30234, 30235, 30237, 30238, 30239, 30244, 30248, 30263, 30279, 30283, 30320, 30321, 30322, 30330, 30331, 30332, 30333, 30336, 30337, 30338, 30339, 30340, 30341, 30342, 30343, 30344, 30345, 30346, 30347, 30348, 30349, 30350, 30351, 30352, 30353, 30354, 30356, 30357, 30358, 30359, 30360, 30361, 30363, 30364, 30371, 30378, 30496, 30497, 30498, 30499, 30509, 30510, 30511, 30512, 30516, 30531, 30532, 30533, 30534, 30535, 30538, 30540, 30541, 30542, 30543, 30544, 30545, 30546, 30547, 30548, 30549, 30550, 30551, 30552, 30553, 30554, 30555, 30556, 30584, 30585, 30586, 30601, 30602, 30603, 30608, 30609, 30610, 30611, 30612, 30613, 30614, 30615, 30616, 30620, 30622, 30623, 30625, 30635, 30829, 30837, 30843, 30870, 30897, 31166, 31167, 31168, 31170, 31171, 31172, 31173, 31174, 31190, 31191, 31193, 31197, 31198, 31199, 31200, 31201, 31235, 31245, 31253, 31254, 31263, 31272, 31327, 31328, 31329, 31330, 31331, 31332, 31333, 31334, 31335, 31336, 31384, 31385, 31386, 31388, 31401, 31402, 31404, 31406, 31408, 31446, 31679, 31715, 31719, 31723, 31779, 31782, 31785, 31787, 31788, 32005, 32006, 32173, 32174, 32175, 32178, 32181, 32182, 32183, 32186, 32187, 32232, 32233, 32238, 32244, 32246, 32247, 32250, 32280, 32281, 32282, 32283, 32284, 32286, 32287, 32288, 32289, 32290, 32291, 32292, 32315, 32320, 32340, 32388, 32415, 32416, 32435, 32436, 32437, 32438, 32455, 32456, 32457, 32521, 32522, 32523, 32524, 32525, 32526, 32529, 32533, 32534, 32535, 32536, 32539, 32540, 32543, 32544, 32547, 32605, 32611, 32612, 32613, 32614, 32770, 32776, 33003, 33124, 33128, 33189, 33192, 33263, 33265, 33280, 33319, 33386, 33439, 33617, 33694, 33789, 33868, 33944, 33947, 33951, 33982, 34159, 34163, 34169, 34172, 34173, 34180, 34183, 34184, 34187, 34200, 34204, 34207, 34263, 34776, 34831, 34839, 34915, 34917, 34921, 35698, 35803, 35875, 35876, 36333, 36334, 36335, 36336, 36337, 36338, 36339, 36340, 36341, 36342, 36343, 36344, 36345, 36346, 36348, 49092, 51080, 53832, 59320, 60000, 60002, 60135, 60136, 60137, 60167, 60168, 60169, 60174, 60177, 60192, 60210, 62955, 64433 |

| [0.1, 0.2) | 0 | |

| [0.2, 0.3) | 0 | |

| [0.3, 0.4) | 0 | |

| [0.4, 0.5) | 0 | |

| [0.5, 0.6) | 0 | |

| [0.6, 0.7) | 0 | |

| [0.7, 0.8) | 0 | |

| [0.8, 0.9) | 0 | |

| [0.9, 1.0] | 0 | |



---



### 2.3 模型特征使用方式 / Model Feature Usage


模型入口：`personal_model/id_atc_nocali_search_inc/pgmv_order2pay_id_prob_sir.py`



#### 2.3.1 UniCR 主模型输入结构与 Slot 使用方式 / UniCR Main Model Slot Usage



| 输入的模型结构 | slot_lis | 使用方式 |

|------|------|------|

| dense_inputs + AutoDis | 60167, 60174 | get_dense_feature -> concat(dense_inputs) -> AutoDisLayer(EMB=16) |

| onehot_inputs + OneHotEmb | 60192, 60177, 60135, 60136, 60137 | get_dense_feature -> reshape(field,2) -> OneHotToEmbeddingLayer(EMB=16) |

| sparse_inputs | 30000, 30001, 30002, 30003, 30004, 30082, 30083, 30084, 30085, 30086, 30089, 30090, 30091, 30092, 30093, 30096, 30097, 30248, 30360, 30361, 30363, 30364, 30531, 30532, 30533, 30534, 30535, 30538, 30540, 30541, 30542, 30543, 30544, 30545, 30546, 30547, 30548, 30549, 30550, 30551, 30552, 30553, 30554, 30555, 30556, 30584, 30585, 30586, 31190, 31191, 31193, 31197, 31198, 31199, 31200, 31201, 31263, 31272, 31446, 31715, 31719, 31723, 32005, 32006, 32232, 32315, 32320, 32415, 32416, 32435, 32436, 32437, 32438, 32455, 32456, 32457, 32605, 32611, 32612, 32613, 32614, 33003, 33982, 34263, 60168, 60210, 30102, 30104, 30105, 30106, 30107, 30110, 30111, 30112, 30113, 30114, 30115, 30116, 30117, 30118, 30119, 30121, 30123, 30124, 30126, 30127, 30128, 30129, 30130, 30143, 30144, 30145, 30146, 30147, 30148, 30149, 30150, 30151, 30152, 30234, 30235, 30237, 30238, 30239, 30244, 30263, 30279, 30283, 30320, 30321, 30322, 30330, 30331, 30332, 30333, 30336, 30337, 30338, 30339, 30340, 30341, 30342, 30343, 30344, 30345, 30346, 30347, 30348, 30349, 30350, 30351, 30352, 30353, 30354, 30356, 30357, 30358, 30359, 30371, 30378, 30496, 30497, 30498, 30499, 30509, 30510, 30511, 30512, 30601, 30602, 30603, 30608, 30609, 30610, 30611, 30612, 30613, 30614, 30615, 30616, 30620, 30622, 30623, 30625, 30635, 30829, 30837, 30843, 30870, 30897, 31166, 31167, 31168, 31170, 31171, 31172, 31173, 31174, 31235, 31384, 31385, 31386, 31388, 31401, 31402, 31404, 31406, 31408, 31679, 31779, 31782, 31785, 31787, 31788, 32173, 32174, 32175, 32178, 32181, 32182, 32183, 32186, 32187, 32233, 32238, 32244, 32246, 32247, 32250, 32280, 32281, 32282, 32283, 32284, 32286, 32287, 32288, 32289, 32290, 32291, 32292, 32340, 32388, 32521, 32522, 32523, 32524, 32525, 32526, 32529, 32533, 32534, 32535, 32536, 32539, 32540, 32543, 32544, 32547, 32770, 32776, 33124, 33128, 33189, 33192, 33263, 33265, 33280, 33319, 33386, 33439, 33617, 33694, 33789, 33944, 33947, 33951, 34159, 34163, 34169, 34172, 34173, 34180, 34183, 34184, 34187, 34200, 34204, 34207, 34776, 34831, 34839, 34915, 34917, 34921, 35698, 35803, 35875, 35876, 36333, 36334, 36335, 36336, 36337, 36338, 36339, 36340, 36341, 36342, 36343, 36344, 36345, 36346, 36348, 60002, 60169, 1065, 1068, 1069, 6189, 12337, 1078, 1079, 1600, 2117, 1094, 1095, 1098, 12363, 12364, 1099, 1100, 1109, 12381, 12385, 12387, 12395, 1132, 1138, 12403, 1139, 1141, 1143, 12408, 1145, 6270, 23168, 1154, 1157, 1158, 1160, 6281, 2186, 23178, 1167, 1183, 6317, 1205, 1206, 1207, 1212, 1214, 1216, 1217, 23748, 9936, 9938, 9939, 9940, 18152, 9969, 9980, 9982, 2312, 8017, 8019, 8024, 7019, 8047, 8050, 7035, 8094, 8096, 8102, 8103, 8105, 8106, 8131, 8132, 8140, 8141, 8159, 8164, 8166, 2534, 2541, 1006, 2542, 1011, 4092, 2558, 1058, 1190, 1191, 51080, 5033, 5098, 5005, 1166, 1038, 9971, 1044, 30516, 1174, 5078, 5082, 1084, 8163, 1124, 1093, 7014, 2531, 2532, 1097, 1129, 5071, 1072, 6320, 1074, 1107, 1108, 8018, 2548, 6175, 6174, 6176, 2503, 2506, 2507, 2508, 8037, 8036, 9981, 2504, 2505, 6275, 6276, 6277, 6272, 6262, 6208, 6204 | get_slots dims=(1,16), TILE_NF -> concat(sparse_inputs) |

| query_inputs | 1008 | get_slots dims=(10,16) -> reduce_sum(10 tokens) |

| target_inputs / target_for_cross | 60000, 30103, 30108, 30109 | get_slots dims=(1,16) -> concat -> reshape(-1,4,16) |

| click_500 attention | 31253, 31254, 31331, 31332 | get_slots dims=(500,16) -> SimpleAttentionV3(target, click_seq) |

| cart_128 attention | 31327, 31328, 31333, 31334 | get_slots dims=(128,16)，代码使用 X_CART_128_SLOT[:-1] |

| order_128 attention | 31329, 31330, 31335, 31336 | get_slots dims=(128,16)，代码使用 X_ORDER_128_SLOT[:-1] |

| domain/entrance | 1224 | get_dense_feature(1d) -> OneHotLayer -> domain_emb |

| org_predict(online) | 1003, 1004 | item dense -> HardBucketizeLayer(pctr/pcr) |

| org_predict(train_only) | 1227, 1228 | 仅训练模式补充 |

| sold_cnt selector | 49092, 31245, 19902, 8669, 59320, 11748, 14749, 62955, 33868, 64433, 53832, 1613 | 49092作索引选桶 + 平滑log变换 |

| pgmv_metric price | 1602, 1614 | 1602/1614 读价（/1e5）用于 pgmv 计算 |

#### 2.3.2 Cali 模型输入结构与 Slot 使用方式 / Cali Model Slot Usage

模型入口：`ego_models/model_modules/cali_v1/item_cali_main.py`

| 输入的模型结构 | slot_lis / 输入 | 使用方式 |
|------|------|------|
| uncalibrated pGMV | `direct_pgmv_7d`, `shop_pgmv_7d` | named dense feature，作为 SIR、ItemCali、大促校准的原始分数 |
| SIR 10 桶统计 | 16501, 16504, 16502, 16505, 16507, 16510, 16508, 16511 | get_dense_feature dim=11 -> concat(1h,24h) -> SIR 分桶线性校准；非 TH/SG 使用 |
| SIR 5 桶统计 | 16513, 16516, 16514, 16517, 16519, 16522, 16520, 16523 | get_dense_feature dim=6 -> pad 到 11 维 -> SIR 分桶线性校准；TH/SG 使用 |
| item 粒度 GMV / pGMV | 6136, 6177, 6137, 6178, 6138, 6179, 6139, 6180 | get_dense_feature dim=1 -> concat(1d,3d) -> ItemCali 计算 scale=GMV/pGMV |
| item 校准门控 | 6181, 6182, 6990 | 6181+6182 计算订单数门控，订单数足够且 item scale 异常时融合 ItemCali；6990 当前读取但基本不影响结果 |
| context / 大促 | 46354, 8888, 1224, 6200, 6201 | common dense -> region 选择桶体系/权重/clip；cur_time、entrance、start_time_base、prom_scale 计算大促 ratio |
| label | label_idx=8,10,30,32 | get_label_weight -> direct/shop 7d 训练 label 与 GMV 评估 label，不作为 slot 特征 |
| 输出 | `cali_direct_pgmv_7d_v2`, `cali_shop_pgmv_7d_v2`, `cali_direct_pgmv_7d_prom_v2`, `cali_shop_pgmv_7d_prom_v2` | 普通输出为 SIR 与 ItemCali 按门控融合；prom 输出为 SIR 结果乘大促 ratio；输出前做 clip |

---

### 2.4 数据链路 / Data Pipeline



```

┌─────────────────────────────────────────────────────────────────────────────┐

│ 上游源表 中间/产出表 用途 │

├─────────────────────────────────────────────────────────────────────────────┤

│ │

│ FSE Feature Tables（本次实时拉取） │

│ -> AFP Scope (project_id=11, scope_id=12) │

│ -> DAG 导出 slot 配置（gpu_nsr_atc_v1_id_v0.yaml） │

│ -> 训练样本侧消费（is_in_train_sample=Y） │

│ │

└─────────────────────────────────────────────────────────────────────────────┘

```



本次数据链路统计（来自实时拉取结果）：



| 统计项 | Top 分布 |

|------|------|

| FSE 表来源 Top10 | rcmd_item_feature(201); rcmd_user_feature(71); long_term_user_session_click_behavior(57); paidads_scoring_feature_category_item_v2(27); rcmd_shop_feature(21); 空(19); long_term_user_session_order_behavior(15); long_term_user_session_cart_behavior(11); dws_fp_search_item_feature(10); category_l2_ordercount(10) |

| 处理算子 Top10 | log(86); join_string(80); of_iterable_arrow_feature(65); bucket_by_country(61); bucket(56); of_shared_arrow_feature(44); bucket_double(19); get_string_list_by_index(14); join_strings_string(13); slice_list(13) |

#### 2.4.1 Cali 校准特征 FSE 表汇总 / Cali Feature FSE Tables

| FSE 表 | PrimaryKey | 聚合粒度 | Slots |
|--------|-----------|---------|-------|
| `ads.cali_segment_data_v3` | data_version, pcr_version, model, region, entrance, price_level, cate1, cate2, placement, time_period | region × entrance × placement × time_period | 16501~16523 |
| `ads.cali_item_data_v3_agg_rt` | item_id, country | item × country | 6136~6182 |
| `ads.zero_order_cnt_5d_v2` | item_id, grass_region | item × region | 6990 |
| `ads.mkplpaidads_search_ads_sales_info_for_cali_fse` | grass_region | region | 6200, 6201 |
| `rcmd.rcmd_user_feature` | userid, country | user | 46354 |



---

### 2.5 特征局限性与问题分析 / Feature Limitations and Issues


#### 2.5.1 结构性局限 / Structural Limitations



- **来源集中风险**：`rcmd_item_feature` 占比显著高于其他来源，特征多样性对单表依赖较重，存在上游波动传导风险。

- **算子同质化**：高频算子集中在 `log / join_string / bucket_*`，说明大量特征仍是规则拼接与分桶形态，深层交互表达能力有限。

- **上下文特征稀疏**：从现有结构看，query/context 路径主要依赖少量槽位（如 `X_QUERY_SLOT=1008`、`ENTRANCE_DENSE_SLOT=1224`），上下文建模带宽偏窄。



#### 2.5.2 覆盖率与数据质量问题 / Coverage and Data Quality Issues



- **高零值簇明显**：`zero_rate` 分桶里存在集中高零值特征簇（尤其类目销量分桶相关槽位），容易造成有效梯度不足与训练不稳定。

- **空值率区分度不足**：`empty_rate` 整体偏低且分布集中，虽然说明链路完整，但也可能掩盖“默认值填充导致的信息缺失”问题。

- **槽位语义漂移风险**：同一统计口径在多 slot 版本并存（不同窗口/不同分桶版本）时，若缺少统一治理，容易产生冗余或冲突信号。



#### 2.5.3 模型接入层面的限制 / Model Integration Limits



- **训练/在线口径分叉**：`ORG_PREDICT_DENSE_SLOT` 与 `ORG_PREDICT_DENSE_SLOT_TRAIN` 存在 train-only 槽位（如 `1227/1228`），需持续关注 train-serve gap。

- **序列输入存在显式截断**：`X_CART_128_SLOT[:-1]` 与 `X_ORDER_128_SLOT[:-1]` 只消费前 4 个槽位，最后 1 个槽位未进入序列 attention。

- **强依赖固定结构**：当前主干对 slot 分组和维度假设较强（如 target 固定 4 槽、query 固定 10 token），扩展新特征时改造成本较高。


### 2.6 特征重要度分析 / Feature Importance Analysis

#### 2.6.1 分析方法 / Method

- 参考 EGO Confluence 文档：[How to Evaluate Feature Importance](https://confluence.shopee.io/pages/viewpage.action?spaceKey=MLP&title=How+to+Evaluate+Feature+Importance)（页面版本更新时间：2025-01-17）。

- 核心思路是做 **mask-based feature importance**：在评估阶段对单个特征或一组特征做 masking（如替换为平均值、随机值、或随机打散），观察模型分数下降幅度。特征被 mask 后会打断它与 label 的关系，因此 **AUC 相对 baseline 的下降越大，说明该特征越重要**。

- EGO 操作上，通常需要先在模型定义里配置多轮 `eval_fea_* round`，每一轮只 mask 一个待分析的特征或特征组；之后把这些 round 的 AUC 与 baseline 做对比，得到重要度排序。

- 任务配置上，需要在 `ego-learner.yaml` 中增加 `eval_fea_config`，单独指定评估数据集路径、日期和 `pass_size`。Confluence 示例里 `train_config` 与 `eval_fea_config` 共享同一份样本路径，但评估阶段使用了更大的 `pass_size` 做稳定估计。

- 提交任务时，需使用 `eval_fea` 模式而不是普通训练模式；如果走 `ego-openapi-v1` 脚本，参数应使用 `--job_type=eval_fea` 而不是 `--job_type=train`。

- 注意事项：Confluence 明确说明 **当前 GPU 不支持该 feature importance 评估流程**；如果必须在 GPU 场景下做类似分析，可改用 `Eval Tensor` 方案。

- 参考ego任务：[特征重要性评估任务](https://ego-portal.mlp.shopee.io/model/model_management/Product_Rank_V1:9085/version/tmp_rank_feav2_40:79769/job/list?current=1&pageSize=10)

#### 2.6.2 分析结果（覆盖 326 slots） / Results (326 Slots)

- 数据来源：Google Sheet [特征重要性](https://docs.google.com/spreadsheets/d/1l7HYMjUGVFjNrEMjlLXhe0O985GzXoBwNYG6ZGxZ16E/edit?pli=1&gid=1733452308#gid=1733452308) 中 `汇总` tab。

- `汇总` 页共 326 条 `eval_fea` 结果，与本轮分析覆盖 326 个 slots 一致。

- 结果按 `diff` 排序，`diff` 越大表示 mask 该特征后 AUC 下降越明显，即该特征越重要。从表中多条记录可反推 baseline AUC 约为 `0.814245`。

- 从 Top 结果看，重要特征主要集中在三类：用户近期行为强度（点击/加购/购买时序与次数）、商品价格/转化先验，以及原始排序先验分数（如 `OrgPcr` / `OrgEcpm`）。

代表性结果摘录如下：

| Rank | Round | 特征名 | 算子 | AUC | diff |
|------|------|------|------|------|------|
| 1 | `eval_fea_1191` | `U_ctr_v2_click_bucket` | `bucket_by_country` | `0.804451` | `0.009794` |
| 2 | `eva_fea_1090` | `I_OrgPcrIndex_reader` | - | - | `0.007686` |
| 3 | `eval_fea_1206` | `U_tag_v1_mppurchaselevelin30days_reader` | `of_shared_arrow_feature` | `0.811474` | `0.002769` |
| 4 | `eval_fea_1600` | `I_p_price_bucket` | `bucket` | `0.812365` | `0.001879` |
| 5 | `eva_fea_1091` | `I_OrgEcpmIndex_reader` | - | - | `0.001797` |
| 6 | `eval_fea_9939` | `user_last_shop_cart_timegap` | `bucket_by_country` | `0.813079` | `0.001166` |
| 7 | `eval_fea_5098` | `S_icvr30` | `bucket_double` | `0.813103` | `0.001141` |
| 8 | `eval_fea_8050` | `user_cate1_cart_cnt_lt` | `bucket_by_country` | `0.813280` | `0.000963` |
| 9 | `eval_fea_8047` | `user_cate1_clk_cnt_lt` | `bucket_by_country` | `0.813394` | `0.000849` |
| 10 | `eval_fea_2312` | `S_ord_items_within_1h_cnt_0` | `bucket_double` | `0.813496` | `0.000748` |

补充观察：

- 用户行为侧特征在 Top10 中占比较高，说明 UNICR 当前仍显著依赖用户近期点击、加购、购买强度与时间间隔信号。

- 商品先验与粗排先验仍然重要，尤其是 `I_OrgPcrIndex_reader`、`I_OrgEcpmIndex_reader`、`I_p_price_bucket` 和 `S_icvr30`，说明模型对上游预估分和商品转化统计仍有较强依赖。

- `汇总` 页尾部已出现少量负 `diff`，表示 mask 后 AUC 未下降甚至轻微上升；这类特征通常值得进一步结合覆盖率、零值率和共线性一起排查，优先识别低收益或冗余特征。

---
