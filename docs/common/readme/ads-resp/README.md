<!-- ads-workspace-gdoc-sync: gdoc_id=14JdsvjC8i3LSM33shL1r9aRCCBZWGQOTVRMJDjbtj_Y gdoc_url=https://docs.google.com/document/d/14JdsvjC8i3LSM33shL1r9aRCCBZWGQOTVRMJDjbtj_Y/edit -->

# ads-resp

`ads-resp` is an Ads response orchestration service. It accepts job requests over HTTP, allocates clusters, triggers deployment or experiment workflows, tracks execution state, and receives worker callbacks to update final results.

## What This Service Does

This service sits between request callers and downstream execution systems.

Its main responsibilities are:

- accept job requests for ads-related validation and execution flows
- dispatch jobs to the correct scheduler based on service type
- manage cluster allocation and release through Redis-backed scheduler state
- trigger downstream deployment, scaling, traffic recording, and experiment actions through DAO clients
- expose job status, cluster status, assertion, and callback APIs
- load static, dynamic, and announcement config from Spex config center
- expose operational endpoints such as `/metrics` and `pprof`

## Main Capabilities

The codebase supports several job flows implemented under `pkg/job/` and `pkg/handler/`:

- preliminary jobs
- stress test jobs
- regression jobs
- experiment / AB test jobs
- execute and assertion flows for existing jobs

At startup, the service creates schedulers for these service types:

- `ADS_ENGINE`
- `ADS_INFO`
- `ADS_BIDDING`
- `BIDDING_STORE`
- `RETRIEVAL`
- `RCMD_RETRIEVAL`
- `PRODUCT_VCORE`

## Request Flow

1. The process starts from [server/main.go](server/main.go) and [server/run.go](server/run.go).
2. The service initializes Spex, then loads static config, dynamic config, and announcement config.
3. DAO clients are created for Redis, deployment/open API, AB test platform, and bot notification integrations.
4. Scheduler managers are created from dynamic cluster config.
5. Gin routes are exposed under `/api`.
6. Incoming requests are validated and translated into job operations in `pkg/api/`.
7. Worker callbacks update job results and release or stop resources when needed.

## Project Layout

- `server/`: application entrypoint and bootstrap logic
- `config/`: config parsing plus Spex-backed static, dynamic, and announcement config loading
- `pkg/api/`: service-level API handlers used by HTTP layer
- `pkg/httpserver/`: Gin handlers, routing, health-ish info, metrics hookup
- `pkg/scheduler/`: scheduler manager and cluster scheduling logic
- `pkg/job/`: job lifecycle logic, callback handling, scaling, queueing, and report filling
- `pkg/handler/`: handler implementations for different job types
- `pkg/dao/`: wrappers around Redis, deployment/open API, AB platform, bot, and related external systems
- `pkg/cluster/`: cluster pool models and Redis-backed cluster allocation
- `proto/`: protobuf definitions and generated code
- `internal/paidadsX/`: shared runtime scaffold, CLI app wrapper, version metadata, and utility code
- `deploy/`: deployment assets

## HTTP API

Routes are registered in [pkg/httpserver/router.go](pkg/httpserver/router.go).

Base path: `/api`

### Service Info

- `GET /api`
- `GET /api/`

Returns basic server info such as service name and uptime.

### Job APIs

- `POST /api/job/request`
  Creates a new job request.
- `POST /api/job/status`
  Queries the current status of a job.
- `GET /api/job/cluster/status`
  Returns scheduler cluster status.
- `POST /api/job/execute`
  Executes a job flow directly.
- `POST /api/job/list`
  Lists jobs.
- `POST /api/job/assert`
  Triggers assertion logic for a job.
- `POST /api/job/jobid`
  Resolves a commit ID to a job ID.
- `POST /api/job/worker/callback`
  Receives worker-side callback results.

### Misc

- `GET /api/announcement`
  Returns current announcement config.
- `GET /metrics`
  Prometheus metrics.
- `/debug/pprof/*`
  Gin pprof endpoints.

Request and response schemas live in [proto/schema/schema.proto](proto/schema/schema.proto) and generated files under [proto/schema](proto/schema).

## Configuration

The runtime config model is defined in [config/config.go](config/config.go). The local bootstrap file points the service to Spex config.

### Local Bootstrap Config

The CLI reads `config.yml` by default, or a path passed with `--config`.

Important fields in the bootstrap config:

- `spex-config.server-name`
- `spex-config.region`
- `spex-config.env`
- `spex-config.tag`
- `spex-config.deployment`
- `spex-config.config-key`
- `spex-config.rule`

`config/files/local.yml` is ignored by Git and can be used for local overrides.

### Spex Config Keys

The service loads these keys from Spex:

- `static_config`
- `resp_enum`
- `dynamic_config`
- `announcement_config`

### Static Config

Defined in [config/static_config.go](config/static_config.go):

- Redis config
- OPS gateway credential config
- Kafka config

### Dynamic Config

Defined in [config/dynamic_config.go](config/dynamic_config.go):

- cluster info by service type
- generic service type to cluster info mapping (`ServiceTypeToClusterInfo`)
- API type to service type mapping
- API type to topic mapping
- service type to live pipeline name mapping
- Spex service name to service type mapping for worker callbacks
- service type to CID mapping
- service type to IDC mapping
- deployment timeout
- scale timeout

Dynamic config is watched and refreshed at runtime. Scheduler cluster pools are also refreshed when `dynamic_config` changes, and a new scheduler is created for any service type added through `ServiceTypeToClusterInfo`.

### Resp Enum Config

Defined in [config/resp_enum_config.go](config/resp_enum_config.go):

- service type value to name mapping
- API type value to name mapping
- API type to service type mapping
- command to API type mapping for campaign traffic templates

The `resp_enum` key is optional for compatibility. If it is missing, the service falls back to the protobuf enum definitions. Values not present in the generated protobuf enums can be defined in `resp_enum` and used by dynamic config without a code release.

### Announcement Config

Defined in [config/announcement_config.go](config/announcement_config.go):

- disable flag
- announcement content
- bot app credentials
- group IDs for notifications

This config is also watched dynamically.

## Running Locally

### Prerequisites

- Go toolchain matching [go.mod](go.mod)
- access to private Go modules under `git.garena.com`
- access to required Spex config and downstream infra

### Start The Service

```bash
go run ./server --config config.yml
```

If you want the binary build path used by the project:

```bash
make svc
```

The built binary is:

```bash
bin/ads_resp.linux
```

### Useful CLI Flags

Common flags are defined in [internal/paidadsX/server/run.go](internal/paidadsX/server/run.go).

- `--config`, `-c`: config file path
- `--dump`: print parsed config
- `--info`: print build info
- `--signal stop`: stop a running daemonized process
- `--daemon`: run as daemon
- `--pid-dir`: pid file directory
- `--log-prefix`: log file prefix
- `--spex-config-key`: Spex config key
- `--spex-service-name`: Spex service name
- `--env`: runtime environment
- `--port`: HTTP port flag exposed by the scaffold

Note: the current service code starts HTTP on `:8080` directly in [server/run.go](server/run.go), so the scaffold `--port` flag is not wired into the HTTP listener yet.

## Development Commands

```bash
make fmt
make vet
make test
make ci
make svc
```

Additional proto-related targets:

```bash
make install_protoc-gen-go
make proto
make protolint
make protolint-fix
```

## Verification

Format code:

```bash
gofmt -w .
```

Run targeted tests:

```bash
go test ./pkg/api ./pkg/httpserver ./server
```

If your machine blocks the default Go cache path, use a workspace-local cache:

```bash
GOCACHE=$(pwd)/.cache/go-build GOFLAGS=-mod=readonly go test ./...
```

## Operational Notes

- logs are written under `log/`
- build/version info is exported on startup
- Prometheus metrics are registered on process start
- scheduler state depends on Redis and dynamic config
- some flows call external deployment and AB test systems, so full local end-to-end validation usually requires internal infrastructure access

## Known Caveats

- `README` usage examples describe the code as it exists today, but some local config sample files in `config/files/` are empty placeholders
- the CLI scaffold exposes a `--port` flag, but the HTTP server currently binds to `8080` in code
- there are currently no repository test files for most packages, so validation is mostly build and targeted runtime verification
