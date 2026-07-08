<!-- ads-workspace-gdoc-sync: gdoc_id=1yEKTIx1eGX0CpQZs0x4mtS3GiAqS59Jb7UZ9lc65NfY gdoc_url=https://docs.google.com/document/d/1yEKTIx1eGX0CpQZs0x4mtS3GiAqS59Jb7UZ9lc65NfY/edit -->

# Graph Manager

## Table of Contents

- [Introduction](#introduction)
- [Features](#features)
- [Architecture](#architecture)
- [Directory Structure](#directory-structure)
- [Development Guidelines](#development-guidelines)
- [Configuration](#configuration)
- [Deployment](#deployment)
- [Monitoring](#monitoring)
- [Business Terminology Glossary](#business-terminology-glossary)
- [Additional Resources](#additional-resources)
- [Frequently Asked Questions](#frequently-asked-questions)

## Introduction

Graph Manager is a lightweight tool for viewing, editing, and validating Ads DAG graph configurations. Its online entrypoint is `https://graphmanager.shopee.io`. The repository contains two main capabilities:

- A Streamlit-based web UI for loading `opdef` and graph YAML files from `graph-manager-conf`, rendering SVG output with the local `bin/tool`, and exporting PNG images.
- A Go SDK for reading graph content from local `graph-manager-conf/config.yaml` or loading debug graph content from Redis.

The git remote for this repository is `https://git.garena.com/shopee/deep/searchads/graph-manager`. The dependent graph configuration repository and rendering tool repository are hard-coded in the upgrade script as `graph-manager-conf` and `graph-engine`.

## Features

- Select graph configurations by `service` and `graph` in the web UI, with URL query parameters used to restore state.
- Edit `opdef` and graph YAML files inline with `streamlit-ace`.
- Run `./bin/tool draw` to generate DAG SVG output, with selectable direction and optional `--check` validation.
- Convert generated SVG output into PNG for download.
- Provide direct links to the `graph-manager-conf` GitLab edit page for manual Merge Request submission.
- Expose Go SDK `GetGraph(service, graph)` to load graph content from the local configuration directory.
- Expose Go SDK `GetGraphDebug(service, graph, key)` to load debug graph content from Redis and emit a Prometheus counter.
- Support upgrade flow during first startup or via `?maintain=upgrade`, which pulls dependent repositories and rebuilds the tool.

## Architecture

The system is composed of the following parts:

- `app.py`: Streamlit entrypoint responsible for layout, configuration loading, editor rendering, graph generation, PNG export, and maintenance mode control.
- `bin/tool`: local executable built from `graph-engine/tool`, used for actual DAG drawing and validation.
- `graph-manager-conf`: external runtime repository containing `config.yaml`, `opdef` files, and graph YAML files; both the web UI and Go SDK read from it.
- `graph_manager.go`: Go SDK wrapping local file reads and Redis-based debug graph reads.
- `exporter.go`: registers the Prometheus metric `paidads_graph_manager_debug_conf_counter` with labels `service`, `graph`, and `key`.
- Redis: `GetGraphDebug` connects to `s1bij.elasticredis.cloud.shopee.io:9854` and reads debug content using the key format `service-graph-key`.
- GitLab: Merge Request buttons jump to the online edit page in `graph-manager-conf`, and the upgrade script also uses Git to sync all required repositories.

The runtime flow is:

1. A user selects a service and graph in the Streamlit page, and `app.py` resolves the target `opdef` and graph file from `graph-manager-conf/config.yaml`.
2. The page writes edited YAML into a temporary directory and calls `./bin/tool draw` to produce SVG output and logs.
3. If rendering succeeds, the page displays the SVG and exports PNG through `cairosvg` and Pillow.
4. If the Go SDK debug API is used, the program reads debug content from Redis and records access counts in Prometheus metrics.

## Directory Structure

```text
.
├── app.py
├── exporter.go
├── graph_manager.go
├── go.mod
├── go.sum
├── requirements.txt
├── script/
│   └── upgrade.sh
└── doc/
    ├── allow.png
    └── img.png
```

- `app.py`: web application entrypoint.
- `graph_manager.go`: Go SDK and debug graph loading logic.
- `exporter.go`: Prometheus metric registration.
- `script/upgrade.sh`: upgrade script for syncing dependencies and rebuilding the tool.
- `doc/`: screenshot assets.

## Development Guidelines

### Code Style

- The Python side is organized as a script-style Streamlit app started directly from `__main__`.
- The Go side uses a single `graphmanager` package and exposes `GetGraph` and `GetGraphDebug`.
- YAML is the core configuration format, and both editing and loading workflows revolve around YAML files.

### Project Structure

- This repository only contains the UI, SDK, and upgrade script; it does not vendor the source code of `graph-manager-conf` or `graph-engine`.
- Runtime dependencies are cloned into the repository root by `script/upgrade.sh`.
- The web UI and Go SDK share `graph-manager-conf` as the source of truth for graph data.

### Naming Conventions

- Service names and graph names come from the `name` fields in `graph-manager-conf/config.yaml`.
- Redis debug keys use the fixed format `service-graph-key`.
- The Prometheus metric name is `paidads_graph_manager_debug_conf_counter`.

### Error Handling

- The web layer reports errors primarily through Streamlit APIs such as `st.error`, `st.stop`, and status messages.
- `GetGraph` and `GetGraphDebug` use `panic` on critical initialization failures such as missing config files, YAML parse failures, or Redis connectivity errors.
- During graph rendering, the output of `tool draw` is redirected to a temporary log file and then surfaced in the UI.

### Unit Testing Standards

- There are currently no test files in the repository and no `go test` or Python test entrypoints.
- The existing validation path relies mainly on the `OpDef Check / 校验` option in the page and on successful graph rendering.

### Code Review & Git Workflow

- The page includes buttons that jump directly to the online edit page in `graph-manager-conf`, so the current workflow is centered on editing in the page and manually pasting content into GitLab to submit an MR.
- `script/upgrade.sh` runs `git fetch` and `git reset --hard` on dependent repositories, which fits deployment-style synchronization but is unsafe for local uncommitted changes.

## Configuration

### Config Files

At minimum, this project depends on the following files and directories:

- `requirements.txt`: Python dependencies including `streamlit`, `streamlit-ace`, `pyyaml`, `redis`, and `cairosvg`.
- `go.mod`: Go dependencies including `github.com/go-redis/redis/v8`, `github.com/prometheus/client_golang`, and `gopkg.in/yaml.v3`.
- `graph-manager-conf/config.yaml`: service index that maps each service to its `opdef` and graph files.
- `graph-manager-conf/<path>`: actual `opdef` and graph YAML files.
- `bin/tool`: the graph drawing executable built from `graph-engine/tool`.
- `.maintain`: maintenance mode marker file; when present, the page stops serving requests and shows a maintenance notice.

### SPEX and spcli Setup

No SPEX SDK usage, `spcli` command, or related configuration files were found in this repository. The actual integrations visible in code are:

- Git-based syncing for `graph-manager-conf` and `graph-engine`.
- GitLab online edit pages for configuration changes.
- Redis for debug graph retrieval.

## Deployment

### Build for Production

The local startup flow documented by the repository is:

```bash
pip install -r requirements.txt
streamlit run app.py
```

For first-time setup or upgrade, the application relies on:

```bash
bash script/upgrade.sh
```

The script performs the following steps:

- Create `.maintain` to block concurrent access.
- Update this repository.
- Install Python dependencies.
- Clone or update `graph-manager-conf`.
- Clone or update `graph-engine`, then run `go build .` under `graph-engine/tool`.
- Copy the built executable into `bin/tool`.
- Remove `.maintain`.

### Release Process

No separate release platform configuration, gray rollout script, or SPEX release definition was found in the repository. The only verifiable release flow in code is:

1. Pull the latest code for this repository, `graph-manager-conf`, and `graph-engine` through `script/upgrade.sh`.
2. Rebuild `graph-engine/tool` and replace the local `bin/tool`.
3. Trigger the same upgrade flow from the web UI through `?maintain=upgrade`.

No gray release strategy is documented in this repository; if such a strategy exists in production, it is not implemented or described here.

## Monitoring

The only monitoring capability implemented in code is a Prometheus counter:

- Metric name: `paidads_graph_manager_debug_conf_counter`
- Type: `CounterVec`
- Labels: `service`, `graph`, `key`
- Purpose: count invocations of `GetGraphDebug`

No dashboard links, alert rule files, or alert thresholds are stored in this repository, so this README does not extend beyond what is verifiable in code.

## Business Terminology Glossary

- Graph: a DAG graph configuration under a service, identified by `graphs[].name` in `config.yaml`.
- OpDef: Operator Definition YAML for a service.
- Service: the owning business service of a graph configuration, identified by the top-level `name` field in `config.yaml`.
- Debug Graph: temporary configuration stored in Redis and retrieved through `GetGraphDebug`, intended for debugging only.
- Direction: graph layout direction, with UI options `TB`, `LR`, `RL`, and `BT`.

## Additional Resources

- Online entrypoint: `https://graphmanager.shopee.io`
- Graph configuration wiki: `https://git.garena.com/shopee/deep/searchads/graph-manager/-/wikis/How-to-define-graph-conf`
- Recall queue naming sheet: `https://docs.google.com/spreadsheets/d/1R7lWvcDF-Mey4mJQ1bRgEQy9XWwHAEmR0dH51J-nqpk`
- Repository URL: `https://git.garena.com/shopee/deep/searchads/graph-manager`
- Configuration repository: `https://git.garena.com/shopee/deep/searchads/graph-manager-conf`
- Source repository of the drawing tool: `gitlab@git.garena.com:shopee/deep/searchads/graph-engine.git`

## Frequently Asked Questions

### 1. What is the minimum setup required before opening the page?

You need the Python dependencies from `requirements.txt`, plus `graph-manager-conf` and `bin/tool` in the repository root. If those are missing, run `bash script/upgrade.sh`.

### 2. Where does the page load its configuration from?

The service list, `opdef` paths, and graph paths all come from `graph-manager-conf/config.yaml`, and the actual file contents are also read from `graph-manager-conf`.

### 3. Does editing YAML in the page submit changes automatically?

No. The page is only for editing and preview. Submission still happens by opening the GitLab edit page through the Merge Request button and manually pasting the updated content.

### 4. What does `OpDef Check / 校验` do?

It adds the `--check` flag when running `./bin/tool draw`, enabling extra validation during graph generation.

### 5. What is the difference between `GetGraph` and `GetGraphDebug`?

`GetGraph` reads official configuration from local files, while `GetGraphDebug` reads temporary debug configuration from Redis without modifying official files.

### 6. Where is debug graph data stored?

Debug graph data is read from Redis at `s1bij.elasticredis.cloud.shopee.io:9854` using keys in the format `service-graph-key`.

### 7. Why does this README not include a fuller deployment platform or monitoring dashboard section?

Because no such configuration or references are present in this repository. The document only records startup, upgrade, and monitoring details that are directly verifiable from code.

### 8. How is maintenance mode triggered?

When a `.maintain` file exists in the repository root, the page shows `Under maintenance` and stops. The upgrade script creates this file while it is running.

### 9. Why is the upgrade script considered risky?

Because it runs `git reset --hard` on this repository, `graph-manager-conf`, and `graph-engine`, which will overwrite uncommitted changes.

### 10. How is PNG download generated?

The page first renders SVG, then converts it to PNG with `cairosvg.svg2png`, and finally returns it through Streamlit's download button.

<!-- Generated by sra-toolkit/skills/ads-readme-generate -->
