<!-- ads-workspace-gdoc-sync: gdoc_id=1D7TMpx0uEsSZ5CSiQsmqCQGFu59XyLB1R421_URqF1U gdoc_url=https://docs.google.com/document/d/1D7TMpx0uEsSZ5CSiQsmqCQGFu59XyLB1R421_URqF1U/edit -->

# ads-common-cpp

Shopee Ads 团队 C++ 通用基础库，为各 Ads 微服务提供可复用的基础设施模块。

---

## 目录

- [项目概述](#项目概述)
- [核心功能](#核心功能)
- [项目架构](#项目架构)
- [目录结构](#目录结构)
- [开发规范](#开发规范)
  - [代码风格](#代码风格)
  - [项目结构](#项目结构)
  - [命名规范](#命名规范)
  - [错误处理](#错误处理)
  - [单元测试](#单元测试)
  - [Code Review & Git Workflow](#code-review--git-workflow)
- [配置说明](#配置说明)
  - [配置文件](#配置文件)
  - [SPEX 与 spcli 配置](#spex-与-spcli-配置)
- [部署](#部署)
  - [生产构建](#生产构建)
  - [发布流程](#发布流程)
- [监控](#监控)
- [业务术语表](#业务术语表)
- [参考资料](#参考资料)
- [常见问题](#常见问题)

---

## 项目概述

`ads-common-cpp` 是 Shopee Ads 团队的 C++ 公共库，以 Bazel 静态库（`cc_library`）的形式提供，供各 Ads 微服务通过 Bazel 依赖引用。

库封装了以下能力：

- **配置中心接入**：对接 sbase `ConfigCenterSDK`，支持命名空间/配置项粒度的热更新订阅
- **Kafka 消费**：基于 `modern-cpp-kafka` 的消费者管理，内置并发队列和 bthread 工作线程池
- **Redis 管理**：多实例 Redis 客户端注册与获取
- **服务启动框架**：整合日志初始化、信号处理、SPEX 注册、brpc 服务器启动
- **本地缓存**：支持分桶 + `DoublyBufferedData` 无锁读的内存哈希表
- **指标上报**：封装 sbase mbvar，提供 Counter、Summary、Request（QPS + 延迟）三种指标类型
- **通用工具**：字符串处理、JSON 序列化/反序列化、时间工具

---

## 核心功能

### 1. 配置中心（`adscommon/config/`）

**用法**

推荐使用 `BaseConfigTemplate<T>` 接入热更新配置，分三步：

**第一步：定义配置结构体并继承模板**

```cpp
// 定义配置类型（需实现 nlohmann JSON 的 from_json）
struct MyConfig {
    int timeout_ms = 1000;
    std::string endpoint;
    NLOHMANN_DEFINE_TYPE_INTRUSIVE_WITH_DEFAULT(MyConfig, timeout_ms, endpoint)
};

// 继承 BaseConfigTemplate 并实现反序列化
class MyConfigFetcher : public adscommon::config::BaseConfigTemplate<MyConfig> {
protected:
    std::shared_ptr<MyConfig> deserializeConfigItems(
        const std::unordered_map<std::string, std::string>& values) override {
        // 处理整个 namespace 的更新
        auto cfg = std::make_shared<MyConfig>();
        // ... 解析 values ...
        return cfg;
    }
    std::shared_ptr<MyConfig> deserializeConfigItems(const std::string& value) override {
        // 处理单个 config_item 的更新
        auto cfg = std::make_shared<MyConfig>();
        utils::jsonutil::FromJson(value, *cfg);
        return cfg;
    }
};
```

**第二步：初始化（在服务启动、ConfigCenterManager 完成初始化后）**

```cpp
MyConfigFetcher fetcher;
// 订阅单个配置项（留空 config_item 则订阅整个 namespace）
fetcher.InitOnce("my_namespace", "my_config_item");
```

**第三步：运行时读取（无锁）**

```cpp
auto cfg = fetcher.GetConfig();  // 返回 std::shared_ptr<MyConfig>
if (cfg) {
    int timeout = cfg->timeout_ms;
}
```

也可直接通过 `ConfigCenterManager` 订阅回调：

```cpp
ConfigCenterManagerIns::get()->WatchConfig(ns, item, [](const std::string& val) { /* ... */ });
ConfigCenterManagerIns::get()->WatchNamespace(ns, [](const std::unordered_map<std::string, std::string>& map) { /* ... */ });
```

**内置实现：** `KafkaConsumerConfigFetcher`（→ `MultiConsumerConfig`）、`RedisConfigFetcher`（→ `MultiRedisConfig`），可直接使用。

**实现细节**

`ConfigCenterManager` 封装 `sbase::config::ConfigCenterSDK`，在 `InitOnce()` 时连接配置中心并启动长轮询。`BaseConfigTemplate<T>` 通过 `butil::DoublyBufferedData` 实现配置无锁读：写端反序列化后调用 `updateData()` 原子切换，读端 `GetConfig()` 不持有锁。

---

### 2. Kafka 消费管理（`adscommon/kafkamgr/`）

**用法**

**第一步：实现消费逻辑**

继承 `KafkaConsumerWorker` 并实现 `HandleMessage()`：

```cpp
class MyWorker : public adscommon::kafka::KafkaConsumerWorker {
protected:
    bool HandleMessage(std::string&& key, std::string&& msg) override {
        // 处理消息，返回 true 表示成功
        return true;
    }
};
```

**第二步：配置并启动消费者**

```cpp
adscommon::kafka::KafkaConsumerConfig config;
config.brokers   = "kafka-broker:9092";
config.topics    = {"my-topic"};
config.group_id  = "my-consumer-group";
config.mechanism = "SCRAM-SHA-256";   // SASL 认证（可选）
config.username  = "user";
config.password  = "pass";
config.worker_num = 100;              // 并行处理的 bthread 数量

auto worker = std::make_shared<MyWorker>();
worker->InitOnce(config.worker_num, /*queue_size=*/1000000, /*is_sync=*/false);

adscommon::kafka::KafkaConsumer consumer;
consumer.InitOnce(config, worker);
consumer.StartConsume();
```

**第三步：停止**

```cpp
consumer.Stop();
```

`KafkaConsumerConfig` 完整字段：

| 字段 | 说明 |
|------|------|
| `brokers` | Kafka broker 地址 |
| `topics` | 订阅的 topic 集合 |
| `group_id` | 消费者组 ID |
| `unique_suffix` | 是否在 group_id 末尾追加唯一标识（多实例场景） |
| `mechanism` / `username` / `password` | SASL 认证配置 |
| `worker_num` | 工作线程数，默认 100 |

**实现细节**

`KafkaConsumer` 封装 `modern-cpp-kafka`（底层 `librdkafka`），在独立线程中 poll 消息后推入 `moodycamel::ConcurrentQueue`；`KafkaConsumerWorker` 维护 bthread 工作线程池，从队列取消息后调用 `HandleMessage()`。

---

### 3. Redis 管理（`adscommon/redismgr/`）

**用法**

**初始化（服务启动时注册实例）：**

```cpp
adscommon::redis::RedisConfig redis_config;
redis_config.naming_service_url = "np://redis-cluster/my_service";
redis_config.timeout_ms         = 100;
redis_config.connection_type    = "single";
redis_config.load_balance_type  = "random";

adscommon::redis::RedisMgrIns::get()->InitOnce();
adscommon::redis::RedisMgrIns::get()->RegisterRedisClient("cache", redis_config);

// 批量注册
adscommon::redis::RedisMgrIns::get()->BatchRegisterRedisClients(redis_conf_map);
```

**运行时获取客户端：**

```cpp
auto client = adscommon::redis::RedisMgrIns::get()->GetRedisClient("cache");
// client 为 std::shared_ptr<sbase::RedisClient>，可直接调用其 Get/Set/Mget 等方法
```

`RedisConfig` 完整字段：

| 字段 | 说明 |
|------|------|
| `naming_service_url` | Redis 地址（naming service 格式，必填） |
| `timeout_ms` | 请求超时，默认 1000ms |
| `connection_type` | 连接类型（如 `single`） |
| `load_balance_type` | 负载均衡策略（如 `random`） |
| `user_name` / `passwd` | 认证信息（可选） |
| `db_index` | 数据库索引 |
| `max_retry` | 最大重试次数 |

**实现细节**

`RedisMgr` 基于 `sbase::Singleton<sbase::InstanceManager<sbase::RedisClient, ...>>`，按名称维护多个 `sbase::RedisClient` 实例。`RedisConfig` 通过 `NLOHMANN_DEFINE_TYPE_INTRUSIVE_WITH_DEFAULT` 支持 JSON 自动反序列化，可直接配合 `BaseConfigTemplate` 实现热更新。

---

### 4. 服务启动框架（`adscommon/service/`）

**用法**

在 `main()` 中调用 `RunServer()`，传入配置路径、服务方法映射和 protobuf Service 实例：

```cpp
int main(int argc, char* argv[]) {
    gflags::ParseCommandLineFlags(&argc, &argv, true);

    MyRpcServiceImpl service_impl;
    // 重载一：从 YAML 文件自动加载 ServiceConfig
    return RunServer(FLAGS_conf_dir + "/server-" + FLAGS_env + ".yaml",
                     "MyMethod", &service_impl);

    // 重载二：由调用方自行构建 ServiceConfig
    // adscommon::config::ServiceConfig cfg = buildConfig();
    // return RunServer(cfg, "MyMethod", &service_impl);
}
```

启动时需通过 gflags 提供以下参数：

| gflag | 说明 |
|-------|------|
| `--port` | 服务监听端口 |
| `--env` | 运行环境（live/staging/test） |
| `--conf_dir` | 配置文件目录 |
| `--log_dir` / `--log_file` | 日志目录和文件名 |
| `--num_threads` | brpc 工作线程数 |
| `--brpc_stream_window_size` | HTTP/2 stream 窗口大小 |
| `--spex_register` | 是否注册 SPEX |

**实现细节**

`RunServer()` 按以下顺序完成初始化：信号处理（SIGSEGV/SIGILL/SIGFPE/SIGABRT → 打印堆栈并 re-raise）→ 异步日志（`sbase::AsyncLogSink` + 日志轮转）→ Naming Proxy brpc 命名服务注册 → Config Center Manager 初始化 → SPEX 实例注册（instance_id 格式：`{spex_name}.{cid}.{env}.{tag}.{sdu_id}.{trimmed_uuid}`）→ brpc Server 启动。

---

### 5. 本地缓存（`adscommon/cache/`）

**用法**

通过工厂函数创建缓存实例，操作统一通过 `ILocalCache<Key, Value>` 接口：

```cpp
#include "adscommon/cache/local_cache.hpp"

using namespace adscommon::localcache;

// 创建缓存（推荐：16 分桶 + AbslFlatMap）
LocalCacheOptions opts;
opts.bucket_size          = 16;
opts.cache_map_type       = CacheMapType::CacheMapType_AbslFlatMap;
opts.enable_doubly_buffer = false;  // 高频读场景可开启

auto cache = CreateLocalCache<std::string, MyData>(opts);

// 写入
cache->Set("key1", my_data);
cache->BatchSet({{" key1", d1}, {"key2", d2}});

// 读取
MyData val;
bool found = cache->Get("key1", val);

std::vector<std::pair<bool, MyData>> results;
cache->BatchGet({"key1", "key2"}, results);
```

`LocalCacheOptions` 关键选项：

| 字段 | 推荐值 | 说明 |
|------|--------|------|
| `bucket_size` | 8–64 | 分桶数，读写并发高时适当增大 |
| `cache_map_type` | `CacheMapType_AbslFlatMap` | 字符串键场景性能更优 |
| `enable_doubly_buffer` | 读多写少时开启 | 消除读锁，适合周期性全量写入的场景 |

**实现细节**

`LocalCacheImpl<Key, Value, MapPolicy>` 按 `bucket_size` 分桶，每个桶独立加锁（`std::shared_mutex`）；开启 `enable_doubly_buffer` 时替换为 `butil::DoublyBufferedData`，读路径完全无锁。哈希散列使用 `absl::Hash`。

---

### 6. 指标上报（`adscommon/metric/`）

**用法**

在模块头文件中声明静态指标对象，在请求路径中上报：

```cpp
#include "adscommon/metric/metric.h"

// 声明指标（通常放在模块的 metric_exporter.h 中，作为 static 变量）
static auto g_qps = adscommon::metric::NewCounterMetric("my_service_qps", {"env", "status"});
static auto g_req = adscommon::metric::NewRequestMetric("my_service_req", {"env"});

// 在请求处理函数中上报
void HandleRequest(const std::string& env) {
    adscommon::metric::Labels labels = {env};

    // 方式一：RAII 自动记录 QPS 和延迟
    adscommon::metric::LatencyRecorderGuard guard(g_req, labels);
    g_req.RecordRate(labels);

    // 方式二：手动上报
    g_qps.RecordRate({"live", "success"});
    g_qps.RecordErrorRate("timeout", {"live"});  // 带 error label
}
```

三种指标类型：

| 类型 | 工厂函数 | 适用场景 |
|------|----------|---------|
| `CounterMetric` | `NewCounterMetric(name, labels)` | QPS、错误计数等单调递增指标 |
| `SummaryMetric` | `NewSummaryMetric(name, labels)` | 延迟、大小等需要分位数的指标 |
| `RequestMetric` | `NewRequestMetric(name, labels)` | 同时需要 QPS 和延迟的 RPC 场景，自动生成 `{name}_qps` 和 `{name}_latency` 两个指标 |

**库内预定义指标（`metric_exporter.h`）：**

| 指标名 | 类型 | Labels |
|--------|------|--------|
| `kafka_consumer_count` | Counter | `topic_name`, `consumer_group` |

**实现细节**

底层封装 `sbase::mbvar`（`RecorderMbvar<bvar::Adder<double>>` 和 `RecorderMbvar<sbase::SummaryRecorder>`），通过 brpc 内置 Prometheus 端点（`--prometheus` gflag）对外暴露。`LatencyRecorderGuard` 使用 `clock_gettime(CLOCK_REALTIME)` 计算微秒级耗时。

---

### 7. 工具库（`adscommon/utils/`）

**用法**

**JSON 序列化/反序列化（`jsonutil.h`）：**

```cpp
MyStruct obj;
std::string json_str;
utils::jsonutil::ToJson(obj, json_str);   // 序列化
utils::jsonutil::FromJson(json_str, obj); // 反序列化（T 需实现 nlohmann JSON 接口）
```

**时间工具（`timeutil.h`）：**

```cpp
// 获取当前时间戳
int64_t now_sec  = utils::timeutil::CurrentTimestampSeconds();
int64_t now_ms   = utils::timeutil::CurrentTimestampMillis();

// 按国家时区格式化时间戳（"YYYY-MM-DD HH:MM:SS"）
std::string local_time = utils::timeutil::TimestampToLocalTime("SG", now_sec);

// 获取某天零点时间戳
int64_t day_start = utils::timeutil::GetDayStartTimestamp("TH", now_sec);
```

支持的国家代码：`ID`、`TH`、`VN`、`BR`、`AR`、`MX`、`SG`、`TW`、`PH`、`MY`、`CL`、`CO`，未知代码回退到 Asia/Singapore（UTC+8）。

**字符串工具（`stringutil.h`）：**

```cpp
std::string upper = utils::stringutil::StringToUpper("hello"); // "HELLO"
std::string lower = utils::stringutil::StringToLower("WORLD"); // "world"
```

**环境变量读取（`baseutils.h`）：**

```cpp
std::string pod_ip = utils::GetEnvironmentVariable("POD_IP");
std::string env    = utils::GetEnvironmentVariableWithDefault("ENV", "test");
```

**实现细节**

`timeutil` 底层使用 `absl::TimeZone` 和 `absl::Time` 处理时区转换。`jsonutil` 基于 nlohmann JSON，异常在内部捕获并转换为 `LOG(ERROR)` + 返回 `false`，调用方无需处理异常。

---

## 项目架构

```
                        ┌─────────────────────────────────────────────────────┐
                        │                  上层 Ads 微服务                     │
                        │   (ads-engine / ads-info / bidding-store / ...)      │
                        └───────────────────────┬─────────────────────────────┘
                                                │ bazel cc_library 依赖
                        ┌───────────────────────▼─────────────────────────────┐
                        │                  ads-common-cpp                      │
                        │                                                       │
                        │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐  │
                        │  │  config  │ │kafkamgr  │ │redismgr  │ │ cache  │  │
                        │  └────┬─────┘ └────┬─────┘ └────┬─────┘ └───┬────┘  │
                        │       │            │            │            │        │
                        │  ┌────▼─────────────────────────────────────▼────┐   │
                        │  │                   service / metric / utils     │   │
                        │  └────────────────────────────────────────────────┘   │
                        └───────────────────────┬─────────────────────────────┘
                                                │
           ┌────────────────────────────────────┼──────────────────────────────────┐
           │                                    │                                   │
  ┌────────▼────────┐               ┌───────────▼──────────┐           ┌──────────▼──────┐
  │  Config Center  │               │    SPEX（服务发现）   │           │   Kafka Cluster  │
  │ (sbase ConfigSDK)│               │  (sbase SpexRegister) │           │ (librdkafka)     │
  └─────────────────┘               └──────────────────────┘           └─────────────────┘
           │
  ┌────────▼────────┐
  │      Redis      │
  │ (sbase RedisClient)│
  └─────────────────┘
```

**外部依赖交互关系：**

| 外部系统 | 使用方式 | 封装位置 |
|----------|----------|----------|
| Config Center | `sbase::config::ConfigCenterSDK` 长轮询，订阅命名空间/配置项变更 | `adscommon/config/config_center.{h,cpp}` |
| SPEX | `sbase::SpexRegister` 注册服务实例，从环境变量读取 `SP_HTTP_TCP_ADDR` | `adscommon/service/service_util.cpp` |
| Kafka | `modern-cpp-kafka` + `librdkafka`，SASL/SCRAM 认证，SSL 支持 | `adscommon/kafkamgr/` |
| Redis | `sbase::RedisClient`，支持多实例、naming service 寻址 | `adscommon/redismgr/` |
| brpc | brpc Server + Naming Proxy（ZooKeeper）命名服务 | `adscommon/service/service_util.cpp` |
| sbase mbvar | 指标上报，Counter / Summary / Recorder | `adscommon/metric/metric.h` |

**运行时环境变量（`adscommon/constant/global_constant.h`）：**

| 变量名 | 常量 | 说明 |
|--------|------|------|
| `POD_IP` | `kPodIP` | Pod IP，用于 SPEX 注册地址 |
| `SP_HTTP_TCP_ADDR` | `kHttpSpexAgentAddr` | SPEX HTTP Agent 地址 |
| `cid` | `kCID` | 集群 ID |
| `ENV` | `kEnv` | 运行环境（live/staging/test） |
| `MODULE_NAME` | `kModule` | 模块名 |
| `PFB_NAME` | `kPFB` | PFB 标识（可选） |
| `SERVICE_NAME` | `kSDU` | SDU 服务名 |

---

## 目录结构

```
ads-common-cpp/
├── adscommon/                   # 库源码根目录
│   ├── cache/
│   │   └── local_cache.hpp      # 通用本地内存缓存（分桶 + 双缓冲）
│   ├── config/
│   │   ├── config_center.{h,cpp}    # ConfigCenterManager 单例
│   │   ├── config_template.h        # BaseConfigTemplate<T> CRTP 模板
│   │   └── service_config.h         # ServiceConfig 结构体（YAML 反序列化）
│   ├── constant/
│   │   └── global_constant.h        # 运行时全局常量（从环境变量读取）
│   ├── kafkamgr/
│   │   ├── kafka_config.{h,cpp}         # KafkaConsumerConfig + ConfigFetcher
│   │   ├── kafka_consumer.{h,cpp}       # KafkaConsumer（poll 线程）
│   │   └── kafka_consumer_worker.{h,cpp} # KafkaConsumerWorker（bthread 工作池）
│   ├── metric/
│   │   ├── metric.h                 # CounterMetric / SummaryMetric / RequestMetric
│   │   └── metric_exporter.h        # 预定义指标（kafka_consumer_count）
│   ├── redismgr/
│   │   ├── redis_config.{h,cpp}     # RedisConfig + ConfigFetcher
│   │   └── redis_mgr.{h,cpp}        # RedisMgr 单例
│   ├── service/
│   │   └── service_util.{h,cpp}     # RunServer() / InitLogger() / InitSignal()
│   └── utils/
│       ├── baseutils.h              # 环境变量读取、UUID 处理
│       ├── jsonutil.h               # JSON 序列化/反序列化
│       ├── logger.h                 # 日志宏
│       ├── stringutil.{h,cpp}       # 字符串工具
│       └── timeutil.{h,cpp}         # 时间工具（多国时区）
├── test/
│   ├── test_main.cpp                # 单元测试入口
│   └── adscommon/
│       └── utils/                   # 各工具模块单元测试
├── BUILD                            # Bazel 构建规则
├── MODULE.bazel                     # Bazel 依赖声明（bzlmod）
├── .bazelrc                         # Bazel 配置（toolchain、远程执行）
└── Makefile                         # 常用构建命令封装
```

---

## 开发规范

### 代码风格

- C++ 标准：**C++17**（`.bazelrc` 中 `--cxxopt=-std=c++17`）
- 编译器：Clang-12（默认）或 Clang-16（可切换），平台 Ubuntu 20.04
- 编译选项：`-Wall -Wextra -Wnon-virtual-dtor -Wdelete-non-virtual-dtor`（见 `BUILD` 中 `common_copts`）
- 代码格式参考 Google C++ Style Guide，命名与 sbase 生态保持一致

### 项目结构

- 所有公共代码放在 `adscommon/` 下，按功能模块分子目录
- 每个模块的头文件即为对外接口，保持最小暴露原则
- 单例使用 `sbase::Singleton<T>` 实现（见 `ConfigCenterManagerIns`、`RedisMgrIns`）
- 需要配置中心热更新的配置，继承 `BaseConfigTemplate<T>` 并实现 `deserializeConfigItems()`

### 命名规范

| 类型 | 规范 | 示例 |
|------|------|------|
| 类/结构体 | `PascalCase` | `KafkaConsumer`, `RedisConfig` |
| 函数/方法 | `PascalCase` | `InitOnce()`, `GetConfig()` |
| 私有成员变量 | `snake_case_` 加下划线后缀 | `consumer_worker_`, `init_` |
| 全局常量 | `kCamelCase` | `kPodIP`, `kEnv` |
| 命名空间 | `lowercase` | `adscommon::kafka`, `utils::timeutil` |
| 头文件保护宏 | `ADSCOMMON_MODULE_FILE_H_` | `ADSCOMMON_METRIC_METRIC_H_` |

### 错误处理

- 初始化类方法（`InitOnce`、`RegisterRedisClient` 等）返回 `bool`，失败时通过 `LOG(ERROR)` 记录错误信息
- 运行时错误通过 `LOG(ERROR)` / `LOG(WARNING)` 记录，不使用异常
- 信号异常（SIGSEGV/SIGILL/SIGFPE/SIGABRT）由 `InitSignal()` 注册，打印 butil 堆栈后 re-raise

### 单元测试

测试文件位于 `test/adscommon/`，使用 GoogleTest 框架。

```bash
# 运行所有单元测试（debug 模式）
make unittest

# 等价命令
bazel test -c dbg :ads-common-cpp-unittest --test_output=all
```

已有测试覆盖：`jsonutil`、`yaml`、`utils`（baseutils）、`timeutil`、`stringutil`

新增模块时须同步在 `test/adscommon/` 下编写对应的 `*_unittest.cpp`。

### Code Review & Git Workflow

- 功能分支命名：`{username}/feature/{description}`（如当前分支 `chenxuan/feature/init-common-lib`）
- 提交前确保 `make unittest` 全部通过
- PR 合入 main 前需至少一名 reviewer approve

---

## 配置说明

### 配置文件

服务启动时通过 `--conf_dir` 和 `--service_conf_file` gflag 指定配置目录和文件名，`RunServer()` 内部调用 `ParseServiceConfig()` 将 YAML 文件反序列化为 `ServiceConfig`。

`ServiceConfig` 主要字段（`adscommon/config/service_config.h`）：

| 字段 | 类型 | 说明 |
|------|------|------|
| `config_center_conf` | `optional<ConfigCenterConf>` | 配置中心连接信息 |
| `spex_register_conf` | `optional<SpexRegisterConf>` | SPEX 注册参数 |
| `spex_identity_conf` | `optional<SpexIdentityConf>` | SPEX 实例身份信息 |
| `server_conf` | `optional<ServerConf>` | brpc Server 配置（最大并发等） |

`ConfigCenterConf` 必填字段：

| 字段 | 说明 |
|------|------|
| `url` | 配置中心服务地址 |
| `project` | 项目名 |
| `module` | 模块名 |
| `namespaces` | 订阅的命名空间列表（每项需 `namespace_name` 和 `secret`） |

### SPEX 与 spcli 配置

SPEX 实例在 `RunServer()` 启动时自动注册，instance_id 由以下信息拼接：

```
{spex_name}.{cid}.{env}.{tag}.{sdu_id}.{trimmed_uuid}
```

注册所需的 `SpexRegisterConf` 字段：

| 字段 | 说明 |
|------|------|
| `spex_network` | 网络类型 |
| `spex_enable_h2c` | 是否启用 HTTP/2 clear-text |
| `spex_register_commands` | 路由规则列表 |

SPEX HTTP Agent 地址通过环境变量 `SP_HTTP_TCP_ADDR` 注入（对应 `kHttpSpexAgentAddr`）。

---

## 部署

### 生产构建

```bash
# 使用默认配置（remote-shopee-clang-12）构建库目标
make build

# 构建指定目标
make build BAZEL_TARGET=//:ads-common-cpp

# 构建 demo 可执行文件
make build-demo

# 生成 compile_commands.json（供 clangd/IDE 使用）
make build-compile-commands

# 清理构建产物
make clean-bazel
```

远程构建平台：
- **远程执行器**：`grpc://buildbarn.api.sr.shopee.io`
- **构建结果**：`http://build.sr.shopee.io/platform/invocation/`
- **内部 BCR**：`http://build.sr.shopee.io/bcr/`、`https://build.sra.shopee.io/official-bcr/`

### 发布流程

发布由 GitLab CI（`.gitlab-ci.yml`）全自动完成，无需手动操作 BCR：

1. 合并 PR 到主分支
2. 在 GitLab 上打一个符合以下格式的 tag：

   ```
   格式：^\d+\.\d+\.\d+\.[a-z]$
   示例：1.0.0.a、2.3.1.b
   ```

3. CI 的 `upload_to_bcr` job 自动触发，调用 `tools/scripts/upload_to_bcr.sh`，将当前 tag 作为版本号注册到内部 BCR（`http://build.sr.shopee.io/bcr/`）
4. 下游服务在自身 `MODULE.bazel` 中更新版本号即可使用新版本：

   ```python
   bazel_dep(name = "ads-common-cpp", version = "1.0.0.a")
   ```

---

## 监控

指标系统基于 `sbase::mbvar`，通过 brpc 内置的 Prometheus 端点（`--prometheus` gflag 指定地址）对外暴露。

**预定义指标（`adscommon/metric/metric_exporter.h`）：**

| 指标名 | 类型 | Labels | 说明 |
|--------|------|--------|------|
| `kafka_consumer_count` | Counter | `topic_name`, `consumer_group` | Kafka 消息消费计数 |

**业务层指标上报示例：**

```cpp
// QPS + 延迟复合指标
auto req_metric = adscommon::metric::NewRequestMetric("my_rpc", {"env", "status"});

// 在请求处理函数中
Labels labels = {"live", "success"};
LatencyRecorderGuard guard(req_metric, labels);  // 作用域结束时自动记录延迟
req_metric.RecordRate(labels);                   // 记录 QPS
```

---

## 业务术语表

| 术语 | 说明 |
|------|------|
| eCPM | Effective Cost Per Mille，每千次展示有效收入 |
| uGSP | Uniform Generalized Second Price，广告竞价定价机制 |
| SPEX | Shopee Service Proxy Extension，Shopee 服务发现与路由平台 |
| spcli | Shopee CLI 工具，用于项目初始化和配置管理 |
| DAG | Directed Acyclic Graph，有向无环图，用于特征处理流水线描述 |
| GAS | Generalized Ads System，广告系统通用架构 |
| SDU | Service Deployment Unit，服务部署单元 |
| PFB | 流量标识，用于 SPEX 路由规则中的标签过滤 |
| CID | Cluster ID，集群标识 |
| Config Center | 配置中心，提供配置热更新能力 |
| mbvar | sbase 内置指标库，兼容 bvar 接口并扩展 Summary 类型 |

---

## 参考资料

- [brpc 官方文档](https://brpc.apache.org/)
- [modern-cpp-kafka GitHub](https://github.com/morganstanley/modern-cpp-kafka)
- [nlohmann/json GitHub](https://github.com/nlohmann/json)
- [abseil-cpp GitHub](https://github.com/abseil/abseil-cpp)
- [Bazel bzlmod 文档](https://bazel.build/external/bzlmod)
- Shopee 内部 BCR：`http://build.sr.shopee.io/bcr/`
- 远程构建结果：`http://build.sr.shopee.io/platform/invocation/`

---

## 常见问题

**Q1：如何在新的 Ads 微服务中引入 ads-common-cpp？**

在下游服务的 `MODULE.bazel` 中添加对 `ads-common-cpp` 的依赖，并在 `BUILD` 文件的 `deps` 中引用 `//:ads-common-cpp`（或对应 target）。

**Q2：ConfigCenterManager 初始化失败，日志提示 `init config center sdk failed`，如何排查？**

确认 `ServiceConfig.config_center_conf` 字段已正确填写：`url`、`project`、`namespaces`（每项需 `namespace_name` 和 `secret`）。同时检查网络连通性和 secret 的有效性。

**Q3：BaseConfigTemplate 初始化卡住超过 60 秒，如何处理？**

`BaseConfigTemplate` 最多等待 `kWaitTimeSeconds`（60 秒）等待配置中心首次推送。若超时，说明配置中心未成功连接或对应 namespace/config_item 不存在，需检查配置中心侧配置是否存在。

**Q4：如何实现一个新的配置热更新模块？**

继承 `BaseConfigTemplate<YourConfigType>`，实现两个 `deserializeConfigItems()` 重载（分别处理全命名空间更新和单 config_item 更新），然后调用 `InitOnce(namespace_name, config_item)` 初始化。

**Q5：KafkaConsumer 如何处理消息？**

继承 `KafkaConsumerWorker` 并实现 `HandleMessage(key, msg)`，然后将实例传入 `KafkaConsumer::InitOnce()` 的 `call_back` 参数。调用 `StartConsume()` 启动消费，`Stop()` 停止消费并等待队列清空。

**Q6：LocalCache 应该选择哪种 `CacheMapType`？**

- 键为字符串且散列均匀时，优先选 `CacheMapType_AbslFlatMap`（abseil flat_hash_map，缓存友好，性能更优）
- 对散列冲突容忍度低或需要稳定性时选 `CacheMapType_UnorderedMap`

**Q7：`enable_doubly_buffer` 什么时候开启？**

读多写少（如每秒数千次读，仅周期性全量写入）的场景下开启，可消除读锁竞争。纯写或高频写的场景下保持关闭。

**Q8：如何添加新的指标？**

在业务模块对应的 `metric_exporter.h`（或自定义头文件）中用 `NewCounterMetric` / `NewSummaryMetric` / `NewRequestMetric` 声明静态指标对象，在请求处理路径中调用 `RecordValue` / `RecordRate` / `RecordLatency`。

**Q9：为什么使用 jemalloc？**

`MODULE.bazel` 中声明了 `jemalloc` 依赖，在 `BUILD` 的 `ads-common-cpp-lib` 中链接，用于替换 glibc 默认内存分配器，减少多线程场景下的内存分配锁竞争和碎片化。

**Q10：本地开发如何不使用远程执行器构建？**

在 `.bazelrc` 中有 `local` 配置，使用 `bazel build --config=local //:ads-common-cpp` 即可本地构建（不发送到 buildbarn），但需要本地安装 clang-12 工具链。

---

<!-- Generated by sra-toolkit/skills/ads-readme-generate -->
