<!-- ads-workspace-gdoc-sync: gdoc_id=1CDrg-qG_mF4CiWGLXY9IMLyaR-Sh3jOd80-xLhTxXy0 gdoc_url=https://docs.google.com/document/d/1CDrg-qG_mF4CiWGLXY9IMLyaR-Sh3jOd80-xLhTxXy0/edit -->

# ads-common-cpp

A shared C++ infrastructure library for Shopee Ads services, providing reusable components for Ads microservices.

---

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Architecture](#architecture)
- [Directory Structure](#directory-structure)
- [Development Guidelines](#development-guidelines)
  - [Code Style](#code-style)
  - [Project Structure](#project-structure)
  - [Naming Conventions](#naming-conventions)
  - [Error Handling](#error-handling)
  - [Unit Testing Standards](#unit-testing-standards)
  - [Code Review & Git Workflow](#code-review--git-workflow)
- [Configuration](#configuration)
  - [Config Files](#config-files)
  - [SPEX and spcli Setup](#spex-and-spcli-setup)
- [Deployment](#deployment)
  - [Build for Production](#build-for-production)
  - [Release Process](#release-process)
- [Monitoring](#monitoring)
- [Business Terminology Glossary](#business-terminology-glossary)
- [Additional Resources](#additional-resources)
- [Frequently Asked Questions](#frequently-asked-questions)

---

## Introduction

`ads-common-cpp` is the shared C++ library for Shopee Ads team, delivered as a Bazel `cc_library` target that downstream Ads microservices depend on.

The library encapsulates the following capabilities:

- **Config Center integration**: Wraps `sbase::ConfigCenterSDK` with namespace- and config-item-level hot-reload subscriptions
- **Kafka consumer management**: Consumer manager based on `modern-cpp-kafka` with a built-in concurrent queue and bthread worker pool
- **Redis client management**: Multi-instance Redis client registration and retrieval
- **Service startup framework**: Integrates logger initialization, signal handling, SPEX registration, and brpc server startup
- **Local cache**: In-memory sharded hash map with optional `DoublyBufferedData` for lock-free reads
- **Metric reporting**: Wraps `sbase::mbvar` to provide Counter, Summary, and Request (QPS + latency) metric types
- **Utility libraries**: String handling, JSON serialization/deserialization, and time utilities

---

## Features

### 1. Config Center (`adscommon/config/`)

**Usage**

The recommended approach is to use `BaseConfigTemplate<T>` for typed hot-reload configuration in three steps:

**Step 1: Define your config struct and subclass the template**

```cpp
// Define the config type (must implement nlohmann JSON's from_json)
struct MyConfig {
    int timeout_ms = 1000;
    std::string endpoint;
    NLOHMANN_DEFINE_TYPE_INTRUSIVE_WITH_DEFAULT(MyConfig, timeout_ms, endpoint)
};

// Subclass BaseConfigTemplate and implement deserialization
class MyConfigFetcher : public adscommon::config::BaseConfigTemplate<MyConfig> {
protected:
    std::shared_ptr<MyConfig> deserializeConfigItems(
        const std::unordered_map<std::string, std::string>& values) override {
        // Handle full-namespace update
        auto cfg = std::make_shared<MyConfig>();
        // ... parse values ...
        return cfg;
    }
    std::shared_ptr<MyConfig> deserializeConfigItems(const std::string& value) override {
        // Handle single config-item update
        auto cfg = std::make_shared<MyConfig>();
        utils::jsonutil::FromJson(value, *cfg);
        return cfg;
    }
};
```

**Step 2: Initialize (after ConfigCenterManager is ready)**

```cpp
MyConfigFetcher fetcher;
// Subscribe to a single config item (leave config_item empty to subscribe to the entire namespace)
fetcher.InitOnce("my_namespace", "my_config_item");
```

**Step 3: Read at runtime (lock-free)**

```cpp
auto cfg = fetcher.GetConfig();  // Returns std::shared_ptr<MyConfig>
if (cfg) {
    int timeout = cfg->timeout_ms;
}
```

You can also subscribe directly via `ConfigCenterManager` callbacks:

```cpp
ConfigCenterManagerIns::get()->WatchConfig(ns, item, [](const std::string& val) { /* ... */ });
ConfigCenterManagerIns::get()->WatchNamespace(ns, [](const std::unordered_map<std::string, std::string>& map) { /* ... */ });
```

**Built-in implementations:** `KafkaConsumerConfigFetcher` (→ `MultiConsumerConfig`) and `RedisConfigFetcher` (→ `MultiRedisConfig`) are ready to use out of the box.

**Implementation Details**

`ConfigCenterManager` wraps `sbase::config::ConfigCenterSDK`, connecting to the Config Center and starting long-polling on `InitOnce()`. `BaseConfigTemplate<T>` uses `butil::DoublyBufferedData` for lock-free reads: on update, the write side deserializes and atomically swaps the data; `GetConfig()` on the read side holds no lock.

---

### 2. Kafka Consumer Management (`adscommon/kafkamgr/`)

**Usage**

**Step 1: Implement your message handling logic**

Subclass `KafkaConsumerWorker` and implement `HandleMessage()`:

```cpp
class MyWorker : public adscommon::kafka::KafkaConsumerWorker {
protected:
    bool HandleMessage(std::string&& key, std::string&& msg) override {
        // Process message; return true on success
        return true;
    }
};
```

**Step 2: Configure and start the consumer**

```cpp
adscommon::kafka::KafkaConsumerConfig config;
config.brokers    = "kafka-broker:9092";
config.topics     = {"my-topic"};
config.group_id   = "my-consumer-group";
config.mechanism  = "SCRAM-SHA-256";   // SASL auth (optional)
config.username   = "user";
config.password   = "pass";
config.worker_num = 100;               // Number of parallel bthreads

auto worker = std::make_shared<MyWorker>();
worker->InitOnce(config.worker_num, /*queue_size=*/1000000, /*is_sync=*/false);

adscommon::kafka::KafkaConsumer consumer;
consumer.InitOnce(config, worker);
consumer.StartConsume();
```

**Step 3: Stop**

```cpp
consumer.Stop();
```

Full `KafkaConsumerConfig` fields:

| Field | Description |
|-------|-------------|
| `brokers` | Kafka broker addresses |
| `topics` | Set of topics to subscribe to |
| `group_id` | Consumer group ID |
| `unique_suffix` | Append a unique suffix to `group_id` (for multi-instance deployments) |
| `mechanism` / `username` / `password` | SASL authentication configuration |
| `worker_num` | Number of worker threads (default: 100) |

**Implementation Details**

`KafkaConsumer` wraps `modern-cpp-kafka` (backed by `librdkafka`) and polls messages on a dedicated thread, pushing them into a `moodycamel::ConcurrentQueue`. `KafkaConsumerWorker` maintains a bthread worker pool that dequeues messages and dispatches them to `HandleMessage()`.

---

### 3. Redis Management (`adscommon/redismgr/`)

**Usage**

**Initialization (register instances at service startup):**

```cpp
adscommon::redis::RedisConfig redis_config;
redis_config.naming_service_url = "np://redis-cluster/my_service";
redis_config.timeout_ms         = 100;
redis_config.connection_type    = "single";
redis_config.load_balance_type  = "random";

adscommon::redis::RedisMgrIns::get()->InitOnce();
adscommon::redis::RedisMgrIns::get()->RegisterRedisClient("cache", redis_config);

// Batch registration
adscommon::redis::RedisMgrIns::get()->BatchRegisterRedisClients(redis_conf_map);
```

**Retrieve the client at runtime:**

```cpp
auto client = adscommon::redis::RedisMgrIns::get()->GetRedisClient("cache");
// client is std::shared_ptr<sbase::RedisClient>; call Get/Set/Mget/etc. directly
```

Full `RedisConfig` fields:

| Field | Description |
|-------|-------------|
| `naming_service_url` | Redis address in naming-service format (required) |
| `timeout_ms` | Request timeout, default 1000 ms |
| `connection_type` | Connection type (e.g., `single`) |
| `load_balance_type` | Load-balancing strategy (e.g., `random`) |
| `user_name` / `passwd` | Authentication credentials (optional) |
| `db_index` | Database index |
| `max_retry` | Maximum retry count |

**Implementation Details**

`RedisMgr` is backed by `sbase::Singleton<sbase::InstanceManager<sbase::RedisClient, ...>>`, maintaining multiple named `sbase::RedisClient` instances. `RedisConfig` uses `NLOHMANN_DEFINE_TYPE_INTRUSIVE_WITH_DEFAULT` for automatic JSON deserialization and pairs naturally with `BaseConfigTemplate` for hot-reload support.

---

### 4. Service Startup Framework (`adscommon/service/`)

**Usage**

Call `RunServer()` from `main()`, passing the config path, service method mapping, and a protobuf Service instance:

```cpp
int main(int argc, char* argv[]) {
    gflags::ParseCommandLineFlags(&argc, &argv, true);

    MyRpcServiceImpl service_impl;
    // Overload 1: auto-load ServiceConfig from a YAML file
    return RunServer(FLAGS_conf_dir + "/server-" + FLAGS_env + ".yaml",
                     "MyMethod", &service_impl);

    // Overload 2: build ServiceConfig manually
    // adscommon::config::ServiceConfig cfg = buildConfig();
    // return RunServer(cfg, "MyMethod", &service_impl);
}
```

Required gflags at startup:

| gflag | Description |
|-------|-------------|
| `--port` | Service listening port |
| `--env` | Runtime environment (live/staging/test) |
| `--conf_dir` | Config file directory |
| `--log_dir` / `--log_file` | Log directory and filename |
| `--num_threads` | brpc worker thread count |
| `--brpc_stream_window_size` | HTTP/2 stream window size |
| `--spex_register` | Whether to register with SPEX |

**Implementation Details**

`RunServer()` initializes in order: signal handlers (SIGSEGV/SIGILL/SIGFPE/SIGABRT → print stack trace and re-raise) → async logger (`sbase::AsyncLogSink` + log rotation) → Naming Proxy brpc naming service → Config Center Manager → SPEX instance registration (instance_id format: `{spex_name}.{cid}.{env}.{tag}.{sdu_id}.{trimmed_uuid}`) → brpc Server start.

---

### 5. Local Cache (`adscommon/cache/`)

**Usage**

Create a cache via the factory function and interact through the `ILocalCache<Key, Value>` interface:

```cpp
#include "adscommon/cache/local_cache.hpp"

using namespace adscommon::localcache;

// Create a cache (recommended: 16 shards + AbslFlatMap)
LocalCacheOptions opts;
opts.bucket_size          = 16;
opts.cache_map_type       = CacheMapType::CacheMapType_AbslFlatMap;
opts.enable_doubly_buffer = false;  // Enable for read-heavy workloads

auto cache = CreateLocalCache<std::string, MyData>(opts);

// Write
cache->Set("key1", my_data);
cache->BatchSet({{"key1", d1}, {"key2", d2}});

// Read
MyData val;
bool found = cache->Get("key1", val);

std::vector<std::pair<bool, MyData>> results;
cache->BatchGet({"key1", "key2"}, results);
```

Key `LocalCacheOptions` settings:

| Field | Recommended Value | Description |
|-------|------------------|-------------|
| `bucket_size` | 8–64 | Number of shards; increase for high read/write concurrency |
| `cache_map_type` | `CacheMapType_AbslFlatMap` | Better performance for string keys |
| `enable_doubly_buffer` | Enable for read-heavy workloads | Eliminates read locks; suited for periodic bulk writes |

**Implementation Details**

`LocalCacheImpl<Key, Value, MapPolicy>` shards the map by `bucket_size`, with each shard protected by an independent `std::shared_mutex`. When `enable_doubly_buffer` is set, `butil::DoublyBufferedData` replaces the mutex, making the read path completely lock-free. Hash distribution uses `absl::Hash`.

---

### 6. Metric Reporting (`adscommon/metric/`)

**Usage**

Declare static metric objects in a module header, then report on the request path:

```cpp
#include "adscommon/metric/metric.h"

// Declare metrics (typically as static variables in a module's metric_exporter.h)
static auto g_qps = adscommon::metric::NewCounterMetric("my_service_qps", {"env", "status"});
static auto g_req = adscommon::metric::NewRequestMetric("my_service_req", {"env"});

// Report in the request handler
void HandleRequest(const std::string& env) {
    adscommon::metric::Labels labels = {env};

    // Option 1: RAII — automatically records QPS and latency
    adscommon::metric::LatencyRecorderGuard guard(g_req, labels);
    g_req.RecordRate(labels);

    // Option 2: Manual reporting
    g_qps.RecordRate({"live", "success"});
    g_qps.RecordErrorRate("timeout", {"live"});  // With error label
}
```

Three metric types:

| Type | Factory Function | When to Use |
|------|-----------------|-------------|
| `CounterMetric` | `NewCounterMetric(name, labels)` | Monotonically increasing values: QPS, error counts, etc. |
| `SummaryMetric` | `NewSummaryMetric(name, labels)` | Distributions requiring percentiles: latency, payload size, etc. |
| `RequestMetric` | `NewRequestMetric(name, labels)` | RPC endpoints needing both QPS and latency; auto-creates `{name}_qps` and `{name}_latency` |

**Library pre-defined metrics (`metric_exporter.h`):**

| Metric Name | Type | Labels |
|-------------|------|--------|
| `kafka_consumer_count` | Counter | `topic_name`, `consumer_group` |

**Implementation Details**

The underlying implementation wraps `sbase::mbvar` (`RecorderMbvar<bvar::Adder<double>>` and `RecorderMbvar<sbase::SummaryRecorder>`), exposed via brpc's built-in Prometheus endpoint (configured with `--prometheus`). `LatencyRecorderGuard` measures elapsed time in microseconds using `clock_gettime(CLOCK_REALTIME)`.

---

### 7. Utility Libraries (`adscommon/utils/`)

**Usage**

**JSON serialization/deserialization (`jsonutil.h`):**

```cpp
MyStruct obj;
std::string json_str;
utils::jsonutil::ToJson(obj, json_str);    // Serialize
utils::jsonutil::FromJson(json_str, obj);  // Deserialize (T must implement nlohmann JSON interface)
```

**Time utilities (`timeutil.h`):**

```cpp
// Get current timestamp
int64_t now_sec = utils::timeutil::CurrentTimestampSeconds();
int64_t now_ms  = utils::timeutil::CurrentTimestampMillis();

// Format a timestamp in a country's local timezone ("YYYY-MM-DD HH:MM:SS")
std::string local_time = utils::timeutil::TimestampToLocalTime("SG", now_sec);

// Get the Unix timestamp of midnight (00:00:00) for a given day and country
int64_t day_start = utils::timeutil::GetDayStartTimestamp("TH", now_sec);
```

Supported country codes: `ID`, `TH`, `VN`, `BR`, `AR`, `MX`, `SG`, `TW`, `PH`, `MY`, `CL`, `CO`. Falls back to Asia/Singapore (UTC+8) for unknown codes.

**String utilities (`stringutil.h`):**

```cpp
std::string upper = utils::stringutil::StringToUpper("hello"); // "HELLO"
std::string lower = utils::stringutil::StringToLower("WORLD"); // "world"
```

**Environment variable helpers (`baseutils.h`):**

```cpp
std::string pod_ip = utils::GetEnvironmentVariable("POD_IP");
std::string env    = utils::GetEnvironmentVariableWithDefault("ENV", "test");
```

**Implementation Details**

`timeutil` uses `absl::TimeZone` and `absl::Time` for timezone conversion. `jsonutil` is built on nlohmann JSON; exceptions are caught internally and converted to `LOG(ERROR)` + `false` return values, so callers do not need exception handling.

---

## Architecture

```
                        ┌─────────────────────────────────────────────────────┐
                        │              Upstream Ads Microservices               │
                        │   (ads-engine / ads-info / bidding-store / ...)      │
                        └───────────────────────┬─────────────────────────────┘
                                                │ Bazel cc_library dependency
                        ┌───────────────────────▼─────────────────────────────┐
                        │                  ads-common-cpp                      │
                        │                                                       │
                        │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐  │
                        │  │  config  │ │kafkamgr  │ │redismgr  │ │ cache  │  │
                        │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └───┬────┘  │
                        │       │            │            │            │        │
                        │  ┌────▼─────────────────────────────────────▼────┐   │
                        │  │              service / metric / utils          │   │
                        │  └────────────────────────────────────────────────┘   │
                        └───────────────────────┬─────────────────────────────┘
                                                │
           ┌────────────────────────────────────┼──────────────────────────────────┐
           │                                    │                                   │
  ┌────────▼────────┐               ┌───────────▼──────────┐           ┌──────────▼──────┐
  │  Config Center  │               │  SPEX (Service Disc.) │           │  Kafka Cluster   │
  │ (sbase ConfigSDK)│               │  (sbase SpexRegister) │           │  (librdkafka)    │
  └─────────────────┘               └──────────────────────┘           └─────────────────┘
           │
  ┌────────▼────────┐
  │      Redis      │
  │ (sbase RedisClient)│
  └─────────────────┘
```

**External dependency interactions:**

| External System | How It's Used | Encapsulation Location |
|-----------------|---------------|----------------------|
| Config Center | `sbase::config::ConfigCenterSDK` long-polling; subscribes to namespace/config-item changes | `adscommon/config/config_center.{h,cpp}` |
| SPEX | `sbase::SpexRegister` registers the service instance; reads `SP_HTTP_TCP_ADDR` from env | `adscommon/service/service_util.cpp` |
| Kafka | `modern-cpp-kafka` + `librdkafka`, SASL/SCRAM authentication, SSL support | `adscommon/kafkamgr/` |
| Redis | `sbase::RedisClient`, multi-instance support, naming-service-based addressing | `adscommon/redismgr/` |
| brpc | brpc Server + Naming Proxy (ZooKeeper) naming service | `adscommon/service/service_util.cpp` |
| sbase mbvar | Metric reporting; Counter / Summary / Recorder types | `adscommon/metric/metric.h` |

**Runtime environment variables (`adscommon/constant/global_constant.h`):**

| Env Var | Constant | Description |
|---------|----------|-------------|
| `POD_IP` | `kPodIP` | Pod IP, used as the SPEX registration address |
| `SP_HTTP_TCP_ADDR` | `kHttpSpexAgentAddr` | SPEX HTTP Agent address |
| `cid` | `kCID` | Cluster ID |
| `ENV` | `kEnv` | Runtime environment (live/staging/test) |
| `MODULE_NAME` | `kModule` | Module name |
| `PFB_NAME` | `kPFB` | PFB label for SPEX routing (optional) |
| `SERVICE_NAME` | `kSDU` | SDU service name |

---

## Directory Structure

```
ads-common-cpp/
├── adscommon/                   # Library source root
│   ├── cache/
│   │   └── local_cache.hpp      # Generic local in-memory cache (sharded + doubly buffered)
│   ├── config/
│   │   ├── config_center.{h,cpp}    # ConfigCenterManager singleton
│   │   ├── config_template.h        # BaseConfigTemplate<T> CRTP template
│   │   └── service_config.h         # ServiceConfig struct (YAML deserialization)
│   ├── constant/
│   │   └── global_constant.h        # Runtime global constants (from env vars)
│   ├── kafkamgr/
│   │   ├── kafka_config.{h,cpp}         # KafkaConsumerConfig + ConfigFetcher
│   │   ├── kafka_consumer.{h,cpp}       # KafkaConsumer (poll thread)
│   │   └── kafka_consumer_worker.{h,cpp} # KafkaConsumerWorker (bthread worker pool)
│   ├── metric/
│   │   ├── metric.h                 # CounterMetric / SummaryMetric / RequestMetric
│   │   └── metric_exporter.h        # Pre-defined metrics (kafka_consumer_count)
│   ├── redismgr/
│   │   ├── redis_config.{h,cpp}     # RedisConfig + ConfigFetcher
│   │   └── redis_mgr.{h,cpp}        # RedisMgr singleton
│   ├── service/
│   │   └── service_util.{h,cpp}     # RunServer() / InitLogger() / InitSignal()
│   └── utils/
│       ├── baseutils.h              # Env var helpers, UUID handling
│       ├── jsonutil.h               # JSON serialization/deserialization
│       ├── logger.h                 # Logging macros
│       ├── stringutil.{h,cpp}       # String utilities
│       └── timeutil.{h,cpp}         # Time utilities (multi-country timezones)
├── test/
│   ├── test_main.cpp                # Unit test entry point
│   └── adscommon/
│       └── utils/                   # Unit tests for utility modules
├── BUILD                            # Bazel build rules
├── MODULE.bazel                     # Bazel dependency declarations (bzlmod)
├── .bazelrc                         # Bazel configuration (toolchain, remote execution)
└── Makefile                         # Shortcuts for common build commands
```

---

## Development Guidelines

### Code Style

- C++ standard: **C++17** (`--cxxopt=-std=c++17` in `.bazelrc`)
- Compiler: Clang-12 (default) or Clang-16 (switchable), platform Ubuntu 20.04
- Compiler warnings: `-Wall -Wextra -Wnon-virtual-dtor -Wdelete-non-virtual-dtor` (see `common_copts` in `BUILD`)
- Follow Google C++ Style Guide; naming conventions align with the sbase ecosystem

### Project Structure

- All shared code lives under `adscommon/`, organized by functional module
- Each module's header file is its public interface; minimize exposed surface area
- Use `sbase::Singleton<T>` for singletons (e.g., `ConfigCenterManagerIns`, `RedisMgrIns`)
- Configurations requiring hot-reload inherit `BaseConfigTemplate<T>` and implement `deserializeConfigItems()`

### Naming Conventions

| Category | Convention | Example |
|----------|-----------|---------|
| Class / Struct | `PascalCase` | `KafkaConsumer`, `RedisConfig` |
| Function / Method | `PascalCase` | `InitOnce()`, `GetConfig()` |
| Private member variables | `snake_case_` with trailing underscore | `consumer_worker_`, `init_` |
| Global constants | `kCamelCase` | `kPodIP`, `kEnv` |
| Namespaces | `lowercase` | `adscommon::kafka`, `utils::timeutil` |
| Header guards | `ADSCOMMON_MODULE_FILE_H_` | `ADSCOMMON_METRIC_METRIC_H_` |

### Error Handling

- Initialization methods (`InitOnce`, `RegisterRedisClient`, etc.) return `bool`; failures are logged via `LOG(ERROR)`
- Runtime errors are reported via `LOG(ERROR)` / `LOG(WARNING)`; exceptions are not used
- Signal-based crashes (SIGSEGV/SIGILL/SIGFPE/SIGABRT) are handled by `InitSignal()`, which prints a butil stack trace then re-raises

### Unit Testing Standards

Test files live in `test/adscommon/` and use the GoogleTest framework.

```bash
# Run all unit tests in debug mode
make unittest

# Equivalent command
bazel test -c dbg :ads-common-cpp-unittest --test_output=all
```

Existing test coverage: `jsonutil`, `yaml`, `utils` (baseutils), `timeutil`, `stringutil`

New modules must include corresponding `*_unittest.cpp` files under `test/adscommon/`.

### Code Review & Git Workflow

- Feature branch naming: `{username}/feature/{description}` (e.g., `chenxuan/feature/init-common-lib`)
- All `make unittest` tests must pass before submitting a PR
- PRs require at least one reviewer approval before merging to main

---

## Configuration

### Config Files

On service startup, gflags `--conf_dir` and `--service_conf_file` specify the config directory and filename. `RunServer()` internally calls `ParseServiceConfig()` to deserialize the YAML file into `ServiceConfig`.

Key `ServiceConfig` fields (`adscommon/config/service_config.h`):

| Field | Type | Description |
|-------|------|-------------|
| `config_center_conf` | `optional<ConfigCenterConf>` | Config Center connection information |
| `spex_register_conf` | `optional<SpexRegisterConf>` | SPEX registration parameters |
| `spex_identity_conf` | `optional<SpexIdentityConf>` | SPEX instance identity |
| `server_conf` | `optional<ServerConf>` | brpc Server configuration (max concurrency, etc.) |

Required `ConfigCenterConf` fields:

| Field | Description |
|-------|-------------|
| `url` | Config Center service address |
| `project` | Project name |
| `module` | Module name |
| `namespaces` | List of subscribed namespaces (each requires `namespace_name` and `secret`) |

### SPEX and spcli Setup

SPEX instance registration happens automatically inside `RunServer()`. The `instance_id` is composed as follows:

```
{spex_name}.{cid}.{env}.{tag}.{sdu_id}.{trimmed_uuid}
```

Required `SpexRegisterConf` fields:

| Field | Description |
|-------|-------------|
| `spex_network` | Network type |
| `spex_enable_h2c` | Whether to enable HTTP/2 clear-text |
| `spex_register_commands` | List of routing rules |

The SPEX HTTP Agent address is injected via the `SP_HTTP_TCP_ADDR` environment variable (mapped to `kHttpSpexAgentAddr`).

---

## Deployment

### Build for Production

```bash
# Build with default config (remote-shopee-clang-12)
make build

# Build a specific target
make build BAZEL_TARGET=//:ads-common-cpp

# Build the demo binary
make build-demo

# Generate compile_commands.json (for clangd/IDE support)
make build-compile-commands

# Clean build artifacts
make clean-bazel
```

Remote build platform details:
- **Remote executor**: `grpc://buildbarn.api.sr.shopee.io`
- **Build invocation results**: `http://build.sr.shopee.io/platform/invocation/`
- **Internal BCR**: `http://build.sr.shopee.io/bcr/`, `https://build.sra.shopee.io/official-bcr/`

### Release Process

Releases are fully automated via GitLab CI (`.gitlab-ci.yml`) — no manual BCR interaction needed:

1. Merge your PR into the main branch
2. Push a Git tag to GitLab in the following format:

   ```
   Pattern: ^\d+\.\d+\.\d+\.[a-z]$
   Examples: 1.0.0.a, 2.3.1.b
   ```

3. The CI `upload_to_bcr` job triggers automatically, running `tools/scripts/upload_to_bcr.sh` to register the tag as a new version in the internal BCR (`http://build.sr.shopee.io/bcr/`)
4. Downstream services update their `MODULE.bazel` version pin to start using the new release:

   ```python
   bazel_dep(name = "ads-common-cpp", version = "1.0.0.a")
   ```

---

## Monitoring

The metric system is based on `sbase::mbvar`. Metrics are exposed via brpc's built-in Prometheus endpoint (address specified via `--prometheus` gflag).

**Pre-defined metrics (`adscommon/metric/metric_exporter.h`):**

| Metric Name | Type | Labels | Description |
|-------------|------|--------|-------------|
| `kafka_consumer_count` | Counter | `topic_name`, `consumer_group` | Kafka message consumption count |

**Example of reporting business metrics:**

```cpp
// Composite QPS + latency metric
auto req_metric = adscommon::metric::NewRequestMetric("my_rpc", {"env", "status"});

// In request handler
Labels labels = {"live", "success"};
LatencyRecorderGuard guard(req_metric, labels);  // Automatically records latency on scope exit
req_metric.RecordRate(labels);                   // Record QPS
```

---

## Business Terminology Glossary

| Term | Description |
|------|-------------|
| eCPM | Effective Cost Per Mille — effective revenue per 1,000 impressions |
| uGSP | Uniform Generalized Second Price — ad auction pricing mechanism |
| SPEX | Shopee Service Proxy Extension — Shopee's service discovery and routing platform |
| spcli | Shopee CLI tool for project initialization and configuration management |
| DAG | Directed Acyclic Graph — used to describe feature processing pipelines |
| GAS | Generalized Ads System — common architecture for the ads system |
| SDU | Service Deployment Unit |
| PFB | Traffic label used in SPEX routing rule tag filtering |
| CID | Cluster ID |
| Config Center | Configuration management platform providing hot-reload capabilities |
| mbvar | sbase's built-in metrics library, compatible with bvar and extending it with a Summary type |

---

## Additional Resources

- [brpc Official Documentation](https://brpc.apache.org/)
- [modern-cpp-kafka GitHub](https://github.com/morganstanley/modern-cpp-kafka)
- [nlohmann/json GitHub](https://github.com/nlohmann/json)
- [abseil-cpp GitHub](https://github.com/abseil/abseil-cpp)
- [Bazel bzlmod Documentation](https://bazel.build/external/bzlmod)
- Shopee Internal BCR: `http://build.sr.shopee.io/bcr/`
- Remote Build Invocations: `http://build.sr.shopee.io/platform/invocation/`

---

## Frequently Asked Questions

**Q1: How do I add ads-common-cpp as a dependency in a new Ads microservice?**

Add `ads-common-cpp` as a dependency in the downstream service's `MODULE.bazel`, then reference `//:ads-common-cpp` (or the appropriate target) in the `deps` field of the service's `BUILD` file.

**Q2: ConfigCenterManager initialization fails with `init config center sdk failed`. How do I troubleshoot?**

Verify that `ServiceConfig.config_center_conf` is fully populated: `url`, `project`, and `namespaces` (each entry needs `namespace_name` and `secret`). Also check network connectivity and that the secrets are valid.

**Q3: BaseConfigTemplate initialization hangs for more than 60 seconds. What should I do?**

`BaseConfigTemplate` waits up to `kWaitTimeSeconds` (60 seconds) for the Config Center to push the first update. A timeout indicates the Config Center connection failed or the target namespace/config_item does not exist. Check both the server-side Config Center configuration and network connectivity.

**Q4: How do I implement a new hot-reload configuration module?**

Subclass `BaseConfigTemplate<YourConfigType>` and implement both `deserializeConfigItems()` overloads (one for full-namespace updates, one for single config-item updates). Then call `InitOnce(namespace_name, config_item)` to initialize.

**Q5: How does KafkaConsumer deliver messages to my code?**

Subclass `KafkaConsumerWorker` and implement `HandleMessage(key, msg)`. Pass the instance to `KafkaConsumer::InitOnce()` as the `call_back` parameter. Call `StartConsume()` to start and `Stop()` to stop consuming.

**Q6: Which `CacheMapType` should I choose for LocalCache?**

- For string keys with good hash distribution, prefer `CacheMapType_AbslFlatMap` (abseil `flat_hash_map` is cache-friendly and generally faster).
- For stricter hash-collision tolerance or stability requirements, use `CacheMapType_UnorderedMap`.

**Q7: When should I enable `enable_doubly_buffer` in LocalCache?**

Enable it for read-heavy workloads (e.g., thousands of reads per second with only periodic bulk writes). This eliminates read-lock contention. Keep it disabled for write-heavy or high-frequency-write scenarios.

**Q8: How do I add new metrics?**

Declare a static metric object in your module's `metric_exporter.h` (or a custom header) using `NewCounterMetric` / `NewSummaryMetric` / `NewRequestMetric`. Call `RecordValue` / `RecordRate` / `RecordLatency` on the request processing path.

**Q9: Why is jemalloc used?**

`jemalloc` is declared in `MODULE.bazel` and linked in the `ads-common-cpp-lib` target in `BUILD`. It replaces the glibc default allocator to reduce mutex contention and memory fragmentation in multi-threaded scenarios.

**Q10: How do I build locally without the remote executor?**

Use the `local` Bazel config defined in `.bazelrc`:

```bash
bazel build --config=local //:ads-common-cpp
```

Note: this requires a local Clang-12 toolchain to be installed.

---

<!-- Generated by sra-toolkit/skills/ads-readme-generate -->
