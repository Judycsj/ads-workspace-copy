<!-- ads-workspace-gdoc-sync: gdoc_id=17_12fDjBlkshBY-pelJX044yhRfbWrN2rvg0zPVupJg gdoc_url=https://docs.google.com/document/d/17_12fDjBlkshBY-pelJX044yhRfbWrN2rvg0zPVupJg/edit -->

Search Ads Query Processing

How to edit content or upload file for new country:

1. Set file name: `<COUNTRY>_adult_whitelist.txt`
2. Copy file to `10.70.39.117` and `smc-toc` to that server, from home directory.
3. Run following command to copy file to s3: `./mc cp <COUNTRY>_adult_whitelist.txt s3/paidads-sg-live/search-ads/whitelist_query`
4. Check that file already uploaded by: `./mc ls s3 s3/paidads-sg-live/search-ads/whitelist_query`
5. Go to [space](https://space.shopee.io/cloud/cmdb/service/1bf02876003f37bf/spex_config_management/live) config and add `whitelist_category` config if upload new file; or increase `reload` version if modify file content.
6. Check the service log to see if everything is loaded:
```
{"lvl":"info","@t":"2022-02-16T12:07:14.368","caller":"index/config.go:52","msg":"updated new config: map[BR:{WhiteListOnly:[23139 25073 100140 100141 100142 100143 100144] Category:[tag_type:\"adult\" list_type:\"whitelist\" category:23139 category:25073 category:100140 category:100141 category:100142 category:100143 category:100144 ] XXX_NoUnkeyedLiteral:{} XXX_unrecognized:[] XXX_sizecache:0} MX:{WhiteListOnly:[100140 100141 100142 100143 100144] Category:[tag_type:\"adult\" list_type:\"whitelist\" category:100140 category:100141 category:100142 category:100143 category:100144 ] XXX_NoUnkeyedLiteral:{} XXX_unrecognized:[] XXX_sizecache:0} MY:{WhiteListOnly:[100140 100141 100142 100143 100144] Category:[tag_type:\"adult\" list_type:\"whitelist\" category:100140 category:100141 category:100142 category:100143 category:100144 ] XXX_NoUnkeyedLiteral:{} XXX_unrecognized:[] XXX_sizecache:0} PH:{WhiteListOnly:[100140 100141 100142 100143 100144] Category:[tag_type:\"adult\" list_type:\"whitelist\" category:100140 category:100141 category:100142 category:100143 category:100144 ] XXX_NoUnkeyedLiteral:{} XXX_unrecognized:[] XXX_sizecache:0} SG:{WhiteListOnly:[100140 100141 100142 100143 100144] Category:[tag_type:\"adult\" list_type:\"whitelist\" category:100140 category:100141 category:100142 category:100143 category:100144 ] XXX_NoUnkeyedLiteral:{} XXX_unrecognized:[] XXX_sizecache:0} TW:{WhiteListOnly:[100141 100142 100143 100144 100387] Category:[tag_type:\"adult\" list_type:\"whitelist\" category:100141 category:100142 category:100143 category:100144 category:100387 ] XXX_NoUnkeyedLiteral:{} XXX_unrecognized:[] XXX_sizecache:0}]"}
{"lvl":"info","@t":"2022-02-16T12:07:14.368","caller":"s3/client.go:63","msg":"Downloading search-ads/whitelist_query/TW_adult_whitelist.txt"}
{"lvl":"info","@t":"2022-02-16T12:07:18.402","caller":"s3/client.go:63","msg":"Downloading search-ads/whitelist_query/BR_adult_whitelist.txt"}
{"lvl":"info","@t":"2022-02-16T12:07:20.057","caller":"s3/client.go:63","msg":"Downloading search-ads/whitelist_query/MY_adult_whitelist.txt"}
{"lvl":"info","@t":"2022-02-16T12:07:27.192","caller":"s3/client.go:63","msg":"Downloading search-ads/whitelist_query/MX_adult_whitelist.txt"}
{"lvl":"info","@t":"2022-02-16T12:07:28.254","caller":"s3/client.go:63","msg":"Downloading search-ads/whitelist_query/PH_adult_whitelist.txt"}
{"lvl":"info","@t":"2022-02-16T12:07:32.544","caller":"s3/client.go:63","msg":"Downloading search-ads/whitelist_query/SG_adult_whitelist.txt"}
{"lvl":"info","@t":"2022-02-16T12:07:33.948","caller":"index/index.go:82","msg":"loaded new index"}
```
