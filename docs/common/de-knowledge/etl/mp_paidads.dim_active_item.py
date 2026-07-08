import sys
import datetime
import requests
import json
import time
import threading
import multiprocessing
from concurrent.futures import ThreadPoolExecutor
from kafka import KafkaProducer

def on_send_success(record_metadata):
    print(record_metadata.topic)
    print(record_metadata.partition)
    print(record_metadata.offset)

def on_send_error(excp):
    print(str(excp))

def ads_info_producer(messages):
    producer = KafkaProducer(
            bootstrap_servers='di-kafka-at01-bg1-bootstrap01-airtrunk-sg.data-infra.shopee.io:9093,di-kafka-at01-bg1-bootstrap02-airtrunk-sg.data-infra.shopee.io:9093,di-kafka-at01-bg1-bootstrap03-airtrunk-sg.data-infra.shopee.io:9093',
            security_protocol='SASL_PLAINTEXT',
            sasl_mechanism='PLAIN',
            sasl_plain_username='mkplpaidads_data',
            sasl_plain_password='t6E70nte5x5c',
            retries=5,
            acks='all',
            batch_size=32 * 1024,
            linger_ms=10,
            max_in_flight_requests_per_connection=5
        )

    for message in messages:
        producer.send('shopee_ads_roi2_active_item', value=json.dumps(message).encode('utf-8')) \
                .add_errback(on_send_error)
    producer.flush()

def get_ads_info(region):
    get_ads_info_url = "https://http-gateway.spex.shopee.sg/sprpc/paidads.valar.gateway.get_ads_info"
    headers = {"X-Sp-Sdu":"adsdataservice.adssellercenter.global.live.master.gw",\
            "X-Sp-Servicekey":"5152c8220c3a1a3011c0a7f6e1cb3a77",\
            "X-Sp-Timeout": "10000","Content-Type":"application/json"}

    headers["shopee-baggage"] = "CID="+region
    params = {"info_types":[1], "identifier":{"placements":[40,50]}, "limit":500}
    result = []
    start_time = time.time()
    unique_set = set([])
    while(True):
        res = requests.post(url=get_ads_info_url, data = json.dumps(params), headers = headers)
        json_res = json.loads(res.text)
        if("ads_info" in json_res):
            for origin_ads_info in json_res["ads_info"]:
                simple_ads_info = {}
                simple_ads_info["ads_id"] = origin_ads_info["ads_id"]
                unique_set.add(origin_ads_info["item_id"])
                simple_ads_info["item_id"] = origin_ads_info["item_id"]
                simple_ads_info["campaign_id"] = origin_ads_info["campaign_id"]
                simple_ads_info["shop_id"] = origin_ads_info["shop_id"]
                simple_ads_info["placement"] = origin_ads_info["placement"]
                simple_ads_info["update_time"] = int(start_time)
                simple_ads_info["grass_region"] = region.upper()
                simple_ads_info["operation"] = "+I"
                result.append(simple_ads_info)

        if("node_cursors" not in json_res or len(json_res["node_cursors"]) == 0):
            break
        params["node_cursors"] = json_res["node_cursors"]

    #ads_info_producer(result)

    #with open("./init.txt", "w") as f:
    #    for line in result:
    #        f.write( str(line) + "\n")

    print(len(result))
    print(len(unique_set))
    end_time = time.time()
    print(end_time - start_time)


def get_ads_info_changes(start_timestamp, end_timestamp, region):
    get_ads_info_url = "https://http-gateway.spex.shopee.sg/sprpc/paidads.valar.gateway.get_ads_info_changes"
    headers = {"X-Sp-Sdu":"adsdataservice.adssellercenter.global.live.master.gw",\
            "X-Sp-Servicekey":"5152c8220c3a1a3011c0a7f6e1cb3a77",\
            "X-Sp-Timeout": "10000","Content-Type":"application/json"}

    #for test
    #get_ads_info_url = "https://http-gateway.spex.test.shopee.sg/sprpc/paidads.valar.gateway.get_ads_info_changes"
    #headers = {"X-Sp-Sdu":"adsdataservice.adssellercenter.global.test.master.gw",\
    #        "X-Sp-Servicekey":"2193d8e0acb4ea6068a0b10db842d026",\
    #        "X-Sp-Timeout": "10000","Content-Type":"application/json"}

    headers["shopee-baggage"] = "CID=" + region

    result = []

    params = {"from_time":start_timestamp,"end_time":end_timestamp, "identifier":{"placements":[40,50]}}
    start_time = time.time()
    res = requests.post(url=get_ads_info_url, data = json.dumps(params), headers = headers)
    issue = []
    json_res = json.loads(res.text)
    if("results" in json_res):
        for ele in json_res["results"]:
            origin_ads_info = ele["ads_info"]
            simple_ads_info = {}
            simple_ads_info["ads_id"] = origin_ads_info["ads_id"]
            simple_ads_info["item_id"] = origin_ads_info["item_id"]
            simple_ads_info["campaign_id"] = origin_ads_info["campaign_id"]
            simple_ads_info["shop_id"] = origin_ads_info["shop_id"]
            simple_ads_info["placement"] = origin_ads_info["placement"]
            simple_ads_info["update_time"] = start_timestamp
            simple_ads_info["grass_region"] = region.upper()
            if ele["operation"] == 1:
                simple_ads_info["operation"] = "+I"
            elif ele["operation"] in (3,4):
                simple_ads_info["operation"] = "-D"
            result.append(simple_ads_info)
    #for test
    #with open("./output"+str(start_timestamp)+".txt", "w") as f:
    #    for line in result:
    #        f.write( str(line) + "\n")
    ads_info_producer(result)

    end_time = time.time()
    print(end_time - start_time)
    return result

#for test
def worker(st, et, region):
    print(st)
    print(et)
    print(region)

def produce(current_time, region):
    dt = datetime.datetime.strptime(current_time, "%Y-%m-%d %H:%M:%S")
    start_ts = int(time.mktime(dt.timetuple()))

    index_ts = [start_ts + i for i in range(0, 61, 5)]
    params = [(a, b, region) for a, b in zip(index_ts[:-1], index_ts[1:])]
    print(params)

    pool = multiprocessing.Pool(processes=12)
    latencies = pool.starmap(get_ads_info_changes, params)
    pool.close()
    pool.join()

if __name__ == '__main__':
    mode = sys.argv[1]
    current_time =  sys.argv[2]
    region = sys.argv[3]

    if mode == 'init':
        get_ads_info(region)
    elif mode == 'update':
        produce(current_time, region)
    else:
        print("mode error, should be init or update")