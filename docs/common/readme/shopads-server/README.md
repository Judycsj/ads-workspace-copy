<!-- ads-workspace-gdoc-sync: gdoc_id=15MPSdUnCcwwd3ZmhrbfHsddVKtBlfZjq3AhAHEQ1ZKM gdoc_url=https://docs.google.com/document/d/15MPSdUnCcwwd3ZmhrbfHsddVKtBlfZjq3AhAHEQ1ZKM/edit -->

### shopads-server

main server of shopee paidads search shop-ads product line 

### Related Links

CMDB Service: <https://space.shopee.io/console/cmdb/overview/detail/shopee.mp_search_recommendation_ads.paidads.brand_ads.shopads.server/dashboard>

Spex API:  <https://space.shopee.io/console/cmdb/service_governance/detail/shopee.mp_search_recommendation_ads.paidads.brand_ads.shopads.server/spexProto>

Monitor: <https://monitoring.infra.sz.shopee.io/grafana/d/v-CiAJuVz/shop-ads-server-core-metrics?orgId=39&from=now-3h&to=now>

### How to run it 
```bigquery
make server && ./bin/server 
```
### API 
```bigquery
paidads.shopads.search.get_shop_ads(GetShopAdsRequest, GetShopAdsResponse) Constant.ErrorCode
paidads.shopads.search.get_shop_ads_inspection(GetShopAdsRequest, GetShopAdsInspectionResponse) Constant.ErrorCode
```
### Modularisation 
* QueryProcess
  - pre-process query including steaming,trim,lower case, intention ...
* Recall
  - recall candidate shop from search engine based on different strategy
  - include keyword relevance, knn , intention 
  - vespa is search engine 
* Merge 
  - merge simple mode and manual mode result 
  - get simple mode bidding information 
* Filter 
  - filter item with low relevance and quality 
  - filter shops & ads with invalid condition 
* Ranking 
  - rank candidate shops based on algo rank model
  - rank different activity based on different ranking strategy, like ranking item/shop/voucher 
* Bidding 
  - compute bid price for ads ,including auto mode and manual mode during the campaign 
* Assemble 
  - assemble the response , including basic info, tracking, deduction 
