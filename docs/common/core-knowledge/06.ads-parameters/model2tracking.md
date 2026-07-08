<!-- ads-workspace-gdoc-sync: gdoc_id=115hjfbOcm4zn5bE370Y_ZXSgD8aK__7dQS5R8BHKfN0 gdoc_url=https://docs.google.com/document/d/115hjfbOcm4zn5bE370Y_ZXSgD8aK__7dQS5R8BHKfN0/edit -->


## 模型输出核心必填字段到bid_rerank_trace 供出价使用

| 字段                | 含义                                                                 | 使用     | product | shop | live | video |
| ----------------- | ------------------------------------------------------------------ | ------ | ------- | ---- | ---- | ----- |
| Pctr              | org侧的pctr预估值                                                       | 用于校准   | ✅       |      |      |       |
| DirectPcr_7D      | 点击后7d内的direct order预估值                                             | 用于校准   | ✅       |      | ✅    | ✅     |
| DirectPgmv_7D     | 点击后7d内的direct gmv预估值                                               | 用于校准   | ✅       |      |      |       |
| ShopPgmv_7D       | 点击后7d内的shop gmv预估值                                                 | 用于校准   | ✅       |      |      |       |
| BroadPgmv_7D      | 点击后7d内的broad gmv预估值                                                | 用于校准   | ✅       |      |      |       |
| CaliDirectPgmv_7D | 点击后7d内的cali direct gmv预估值                                          | 用于校准评估 | ✅       |      |      |       |
| CaliShopPgmv_7D   | 点击后7d内的cali shop gmv预估值                                            | 用于校准评估 | ✅       |      |      |       |
| CaliBroadPgmv_7D  | 点击后7d内的cali broad gmv预估值                                           | 用于校准评估 | ✅       |      |      |       |
| Pgmv              | 点击后7d内的最终的gmv预估值(出价使用的)                                            | 出价使用   | ✅       |      | ✅    | ✅     |
| PayPgmv           | 点击后7d内的最终的pay gmv预估值(出价使用的)                                        | 出价使用   | ✅       |      | ✅    | ✅     |
| FeedbackRatio_1H  | 最终的gmv 1h回流率预估值                                                    | 出价使用   | ✅       |      |      |       |
| FeedbackRatio_3H  | 最终的gmv 3h回流率预估值                                                    | 出价使用   | ✅       |      |      |       |
| FeedbackRatio_24H | 最终的gmv 24h回流率预估值                                                   | 出价使用   | ✅       |      |      |       |
| FeedbackRatio_72H | 最终的gmv 72h回流率预估值                                                   | 出价使用   | ✅       |      |      |       |
| ShopPcr_7D        | 点击后7d内的shop pcr预估值(包含了direct和非direct的prduct ads需要把broad的字段进行一下改动 ) | 出价使用   |         |      | ✅    | ✅     |
| Pcr_0             | shop pcr实时预估值                                                      | 弃用     |         | ✅    |      |       |
|                   |                                                                    |        |         |      |      |       |

所有出价使用的字段，在出价的rule进行落到bid_rerank_trace