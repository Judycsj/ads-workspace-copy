<!-- ads-workspace-gdoc-sync: gdoc_id=18BPkgpNA-_RI7Tk24qJ-8Yqq0huuJY6Rdk7XsBUSr0Y gdoc_url=https://docs.google.com/document/d/18BPkgpNA-_RI7Tk24qJ-8Yqq0huuJY6Rdk7XsBUSr0Y/edit -->

# paidads-vespa-client

Paidads' wrapper for [vespa-client](https://git.garena.com/shopee/deep/vespa-client).

This library include **load balancer** and **bulk manager** to handle bulk request. 

[![](https://mermaid.ink/img/eyJjb2RlIjoiZmxvd2NoYXJ0IFRCXG4gICAgYm1bQnVsa01hbmFnZXJdXG5cbiAgICBzdWJncmFwaCB3b3JrZXJzXG4gICAgICAgIHcxICYgdzIgJiB3MyAtLT4gc2JbW1NlbmRCdWxrXV1cbiAgICBlbmRcblxuICAgIGJtIC0tLSB3b3JrZXJzICYgYmFsYW5jZXJbQmFsYW5jZXJdXG4gICAgd29ya2VycyAtLT58XCJOZXh0KClcInwgYmFsYW5jZXJcblxuICAgIHN1YmdyYXBoIGNsaWVudHNcbiAgICAgICAgYzEgJiBjMiAmIGMzIC0tLSBoW1toZWFsdGhDaGVja11dXG4gICAgZW5kXG5cbiAgICBzYiAtLT4gY2xpZW50c1xuICAgIHNiIC0tPnxyZXRyeXwgc2JcbiAgICBcbiAgICBiYWxhbmNlciAtLS0gY2xpZW50c1xuICAgIGJhbGFuY2VyIC0tPnxcIlByb2R1Y2UoKVwifCBmYWN0b3J5W0ZhY3RvcnldXG5cbiAgICBVc2VyIC0tPnxcIkRvKClcInwgYm1cblxuIiwibWVybWFpZCI6eyJ0aGVtZSI6ImJhc2UifSwidXBkYXRlRWRpdG9yIjpmYWxzZSwiYXV0b1N5bmMiOnRydWUsInVwZGF0ZURpYWdyYW0iOmZhbHNlfQ)](https://mermaid.live/edit#eyJjb2RlIjoiZmxvd2NoYXJ0IFRCXG4gICAgYm1bQnVsa01hbmFnZXJdXG5cbiAgICBzdWJncmFwaCB3b3JrZXJzXG4gICAgICAgIHcxICYgdzIgJiB3MyAtLT4gc2JbW1NlbmRCdWxrXV1cbiAgICBlbmRcblxuICAgIGJtIC0tLSB3b3JrZXJzICYgYmFsYW5jZXJbQmFsYW5jZXJdXG4gICAgd29ya2VycyAtLT58XCJOZXh0KClcInwgYmFsYW5jZXJcblxuICAgIHN1YmdyYXBoIGNsaWVudHNcbiAgICAgICAgYzEgJiBjMiAmIGMzIC0tLSBoW1toZWFsdGhDaGVja11dXG4gICAgZW5kXG5cbiAgICBzYiAtLT4gY2xpZW50c1xuICAgIHNiIC0tPnxyZXRyeXwgc2JcbiAgICBcbiAgICBiYWxhbmNlciAtLS0gY2xpZW50c1xuICAgIGJhbGFuY2VyIC0tPnxcIlByb2R1Y2UoKVwifCBmYWN0b3J5W0ZhY3RvcnldXG5cbiAgICBVc2VyIC0tPnxcIkRvKClcInwgYm1cblxuIiwibWVybWFpZCI6IntcbiAgICBcInRoZW1lXCI6IFwiYmFzZVwiXG59IiwidXBkYXRlRWRpdG9yIjpmYWxzZSwiYXV0b1N5bmMiOnRydWUsInVwZGF0ZURpYWdyYW0iOmZhbHNlfQ)

## Install

```bash
$ go get git.garena.com/shope/deep/paidads-vespa-client
```

## Getting Started

To use it on your code, simply import it

```go
// for bulk manager
import "git.garena.com/shopee/deep/paidads-vespa-client" 

// for load balancer and http client factory 
import "git.garena.com/shopee/deep/paidads-vespa-client/balancer" 
```

### Quick Start

```go
package main

import (
	"fmt"
	"math/rand"
	"time"

	"git.garena.com/shopee/deep/paidads-vespa-client"
	"git.garena.com/shopee/deep/vespa-client"
)

func main() {
	// default bulk manager
	manager, err := vespaclient.NewBulkManager(&vespaclient.BulkManagerConfig{})
	if err != nil {
		fmt.Printf("fail to init bulk manager -> %s\n", err)
		panic(err)
	}

	// request examples
	requests := []vespa.BatchableRequest{
		vespa.NewCreateBatchRequest().
			Namespace("paidads").
			Scheme("ads_id0").
			ID("test-sample-0").
			Body(map[string]interface{}{
				"name": "testdata",
			}),
	}

	// we use first worker for the request (index 0)
	err = manager.Do(0, requests)
	if err != nil {
		fmt.Printf("fail to dispatch bulk request -> %s\n", err)
		panic(err)
	}

	// since the worker run asynchronously,
	// we need to wait for cycle period and http request
	// the default cycle period is 100ms
	time.Sleep(100 * time.Millisecond)

	// wait for default request timeout of 1000ms
	time.Sleep(1 * time.Second)
}
```

more examples can be found on the [example](./examples) folder

## Bulk Manager

Bulk Manager will handle a list of asynchronous worker to dispatch the batch request. 
Each call to `BulkManager.Do` function will be dispatch to one worker based on the `id`
passed on as the parameter. It is best to fine tune your own configuration value to match
the use case, even though the default value can be used to quickly set up the client and
test the connection. User need to at least set the vespa engine url on the balancer config.

```go
    manager, err := vespaclient.NewBulkManager(&vespaclient.BulkManagerConfig{
        BalancerConfig: &balancer.Config{BaseURLs: []string{"http://10.20.30.40:1234"}},
    })
```

### worker

When initializing a new Bulk Manager, it will spawn a list of worker and set it to run
asynchronously in the background. The worker will check the buffer size on each dispatch
called be the manager. If it reaches the maximum `bulkSize`, the worker will send 
the request. But if it is not, then the worker will wait for the `period` cycle 
to execute the request.

```go
    ticker := time.NewTicker(b.period)
    hasSend := false
    for {
        select {
        case data := <-b.channel:
            b.buffer = append(b.buffer, data)
            if len(b.buffer) >= b.bulkSize {
                b.sendBulk() // send http
                hasSend = true
            }
        case <-ticker.C:
            if len(b.buffer) > 0 && (hasSend == false) {
                b.sendBulk() // send http
            }
            hasSend = false
        }
    }
```

## Balancer

Balancer will be used by the worker to choose which vespa engine instance it will use
to send the batch request. By **default** the balancer will use round-robin strategy
to choose the next client.

```go
    // worker.go
	
    client, err := b.balancer.Next()
    if err != nil {
        log.Errorf("balancer.Next() error -> %s", err)
        return
    }
    
    batchService := vespa.NewBatchService(client)
    for _, request := range b.buffer {
        batchService.Add(request)
    }
```

The `balancer` package have a `Balancer` interface in which the user can also implement
their own balancing strategy and passed it on the config when initialize `BulkManager`.

```go
    manager, err := vespaclient.NewBulkManager(&vespaclient.BulkManagerConfig{
        Balancer: &MyOwnBalancer{}, // your custom balancer
    })
```
The `Balancer` interface only require one method `Next`, to select the next client.
```go
    type Balancer interface {
        Next() (*vespa.Client, error)
    }
```

### Factory

`Factory` is a `http.Client` producer which will be called to produce the http client 
when initializing the balancer. The `Factory` mainly focused on building the 
`http.Transport` for the http client. 

`Factory` is an interface with one method `Produce`.
```go
    type Factory interface {
        Produce() *http.Client
    }
```

The concrete type on the `balancer` package is `ClientFactory`. User can also build their
own `Factory` using existing `ClientFactory`. By **default**, the default balancer will
check for user defined `Factory`, then the HTTP/1.1 transport producer using 
`MaxIdleConnsPerHost`, and lastly the H2C producer.

```go
    if conf.ClientFactory != nil {
        factory = conf.ClientFactory
    } else if conf.MaxIdleConnsPerHost > 0 {
        factory, err = NewClientFactory(SetMaxIdleConnsPerHost(conf.MaxIdleConnsPerHost))
    } else {
        factory, err = NewClientFactory(SetUseH2C(true))
    }
```

The `MaxIdleConnsPerHost` is used to customize the number of idle connection maintained
by each host. We can increase this value to allow more idle connection when the
concurrency is high and reduce the needs to create a new connection. The example 
of using the `MaxIdleConnsPerHost` when creating the `ClientFactory` can be seen above.

The `H2C` is HTTP/2 over clear text. It will use HTTP/2 single connection to send all the
message and reduce the number of connection to the server. H2C is the non-TLS version 
of HTTP/2. It implements the unencrypted request to reduce the connection overhead.
We use the H2C with assumption that the connection between the client and the engine
are using internal network, and it is safe to use a clear text for the request. For other
configuration of HTTP/2 you can provide your own `http.Transport` and passed it to the 
`ClientFactory`, see below for example of passing custom transport.
The example of using the `H2C` when creating the `ClientFactory` can be seen above.

User can also configure their own `ClientFactory` using the available options.
- `SetUseH2C` : to use `H2C` and override other configuration
- `SetDialContext` : to implements you own http `Transport.DialContext`
- `SetDisableKeepAlive` : to disable the keep alive flag and destroy each connection after use
- `SetMaxIdleConns` : to set the maximum idle connection across all host
- `SetMaxIdleConnsPerHost` : to set the maximum idle connection for each host
- `SetIdleConnTimeout` : to set the timer for idle connection before it close itself

example:
```go
    b, err := balancer.NewClientFactory(
        balancer.SetDisableKeepAlive(true),
        balancer.SetIdleConnTimeout(1000),
        balancer.SetMaxIdleConnsPerHost(500))
    if err != nil {
        ...
    }
    manager, err := vespaclient.NewBulkManager(&vespaclient.BulkManagerConfig{
        BalancerConfig: &balancer.Config{ClientFactory: b},
    })
```

It is also possible for user to customize the transport by passing the already 
configured `http.Transport` to the `ClientFactory` using the 
`NewClientFactoryWithTransport`.

```go
    transport := &http.Transport{
        MaxIdleConns:           250,
        MaxConnsPerHost:        500,
    }
    b := balancer.NewClientFactoryWithTransport(transport)
    manager, err := vespaclient.NewBulkManager(&vespaclient.BulkManagerConfig{
        BalancerConfig: &balancer.Config{ClientFactory: b},
    })
```

### Conclusion

It is recommended to use the H2C for the transport as to reduce the number of connection
and remove the connection overhead. So the user only need to provide the slice of base
url of the vespa engine instance. **BUT** it is only recommended if the connection
between the client and the server are secure. Otherwise, please use other secure options.
Either using the HTTP/1.1 or provide your own `http.Transport`.

## Exporter

This library will export two prometheus metrics.
- `paidads_vespa_client_latency` : to record the request latency
- `paidads_vespa_client_error` : to record error occurrence

The latency will be based on the `vespa-client` library latency which will be returned
after each batch request. It will include `0.5`, `0.9`, and `0.99` quantile.

If you want to use this library, make sure you filter the `sdu` on the grafana since there
might be more than one service using this library.