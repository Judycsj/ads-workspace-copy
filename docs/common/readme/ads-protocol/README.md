<!-- ads-workspace-gdoc-sync: gdoc_id=1yHOn7e4u1G7BZ8MVM_UNAKZcsIl4NJzSU2hN5pUiDec gdoc_url=https://docs.google.com/document/d/1yHOn7e4u1G7BZ8MVM_UNAKZcsIl4NJzSU2hN5pUiDec/edit -->

## Structure

`ads-protocol` is a mono repo for protocol source, but it is not a mono Go package.

```text
proto/<leaf>       # source .proto files
gen/go/<leaf>      # generated Go leaf package or module
```

Top-level leaves such as `sku`, `affiliate`, and `item_cache` remain separate
Go modules. Migrated tracking/report definitions share the `gen/go` module
because they reference each other, while each protocol remains a leaf package:

```text
proto/tracking/ads_data
gen/go                  # module for migrated tracking/report packages
gen/go/tracking/ads_data # leaf package
gen/go/report/ads_report # leaf package
```

Consumers should import only the leaf module they need, for example:

```go
import "git.garena.com/shopee/deep/ads-protocol/gen/go/sku"
import "git.garena.com/shopee/deep/ads-protocol/gen/go/tracking/ads_data"
```

Do not add a root Go module, aggregate `gen/go/all` package, or `all.pb.go`.
Keeping protocol definitions in leaf packages prevents services from compiling
unrelated generated code into their dependency graph, while the shared `gen/go`
module avoids cross-leaf release/tag resolution problems inside this protocol
batch.

## install plugins:
```bash
cd ~/
export GO111MODULE=on \
                   go get github.com/golang/protobuf/protoc-gen-go@v1.3.2 \
                   google.golang.org/grpc/cmd/protoc-gen-go-grpc
```

## build proto:
```bash
make help
make all
make test
```

## installed versions:
    protoc-gen-go v1.3.2
    protoc        v3.11.4
