<!-- ads-workspace-gdoc-sync: gdoc_id=1ZUmfk51AtMBGQJZnRiV00NInICZXVsVHJRWwDc5m0Pw gdoc_url=https://docs.google.com/document/d/1ZUmfk51AtMBGQJZnRiV00NInICZXVsVHJRWwDc5m0Pw/edit -->

# Graph Manager Conf

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

`graph-manager-conf` is the DAG configuration repository used by Graph Manager. It centrally maintains operator definitions, graph definitions, and registry metadata for Ads-related business domains. The repository itself does not contain service runtime logic or the graph rendering engine. Instead, it acts as a configuration source consumed by Graph Manager and related tooling.

Based on the current `config.yaml`, the repository registers:

- 12 business domains
- 79 graph configurations
- 4 deprecated domains whose names end with `_DEPRECATED`

The git remote of this repository is `https://git.garena.com/shopee/deep/searchads/graph-manager-conf`. The most directly related upstream tool repository is `https://git.garena.com/shopee/deep/searchads/graph-manager`, which provides graph visualization, edit entrypoints, and upgrade flow.

## Features

- Maintain `opdef.yaml` and graph YAML files on a per-domain basis.
- Use the root-level `config.yaml` as the central registry for domains, graph paths, and default render directions.
- Provide Graph Manager with an enumerable list of domains, graphs, and file paths.
- Use `validate.py` to batch-validate graph configurations through `tool draw --check`.
- Reuse the same validation entrypoint in CI through `.gitlab-ci.yml`.
- Store related upstream GitLab repository URLs for some domains such as `retrieval` and `featureserver`.
- Preserve deprecated configurations for historical access and compatibility, while marking them explicitly with `_DEPRECATED`.

## Architecture

The repository consists of three core configuration layers:

- Domain directories: such as `adsengine/`, `retrieval/`, and `indexer/`, each usually containing one `opdef.yaml` and multiple graph YAML files.
- Root registry `config.yaml`: declares each domain name, optional `gitlab` URL, `opdef` path, graph file paths, and optional render direction.
- Validation script `validate.py`: recursively scans YAML graph files and invokes an external `tool` command for validation.

The runtime relationship is:

1. `config.yaml` acts as the unified entrypoint and is read by Graph Manager or other tools to list available domains and graphs.
2. Each domain-level `opdef.yaml` describes available operator interfaces, while graph YAML files describe DAG nodes and dependencies.
3. `validate.py` runs `tool draw --opdef <dir>/opdef.yaml --graph <graph.yaml> --check` for every YAML file except `opdef.yaml` and `config.yaml`.
4. `.gitlab-ci.yml` only calls `python3 validate.py`, so local validation and CI validation share the same entrypoint.

Both active and deprecated domains are kept in the same repository. Their status is distinguished mainly by names in `config.yaml`, not by separate directory tiers.

## Directory Structure

```text
.
├── adsengine/
├── attribution/
├── featureserver/
├── indexer/
├── ohmyemb/
├── prerank/
├── query_understand/
├── relevance/
├── retrieval/
├── searchads/
├── searchadsgear/
├── tracking/
├── config.yaml
├── validate.py
├── README.md
├── README_EN.md
└── .gitlab-ci.yml
```

Main directories and their current registration counts:

| Directory | Registered Graphs | Description |
| --- | ---: | --- |
| `adsengine/` | 21 | Ads Engine recall, info, bid, deduction, and unified flows |
| `retrieval/` | 16 | Retrieval, recall, and recommendation DAGs |
| `indexer/` | 16 | Decision, collection, sink, and attribute update flows |
| `attribution/` | 5 | Attribution and tracking-related flows |
| `ohmyemb/` | 3 | Offline and online embedding workflows |
| `featureserver/` | 1 | Feature Server graph configuration |
| `query_understand/` | 1 | Query understanding workflow |
| `tracking/` | 1 | Tracking runner workflow |
| `searchads/` | 5 | Deprecated Search Ads configs |
| `prerank/` | 4 | Deprecated Prerank configs |
| `searchadsgear/` | 4 | Deprecated Search Ads Gear configs |
| `relevance/` | 2 | Deprecated Relevance configs |

Key root files:

- `config.yaml`: central configuration registry.
- `validate.py`: batch validation script shared by local runs and CI.
- `.gitlab-ci.yml`: GitLab CI entrypoint, currently only running `python3 validate.py`.
- `README.md` / `README_EN.md`: Chinese and English documentation.

## Development Guidelines

### Code Style

- YAML is the primary asset type in this repository, and Python is only used for batch validation.
- Every domain entry in `config.yaml` follows the same structure: `name`, optional `gitlab`, `opdef`, and `graphs`.
- Graph filenames usually reflect business intent directly, such as `ads_recall_base.yaml`, `tracking_runner.yaml`, and `brand_max_retrieval.yaml`.

### Project Structure

- Each domain directory usually contains one `opdef.yaml` and multiple graph files.
- The repository root keeps all domain directories at the same level alongside the central registry.
- Deprecated domains are not removed from the repository and continue to be registered through names ending with `_DEPRECATED`.

### Naming Conventions

- Domain names are defined by the top-level `name` field in `config.yaml`.
- Graph names are defined by `graphs[].name`. They do not have to match filenames exactly, though most current entries map closely to file names.
- Render direction is controlled by `graphs[].direction`, and the current repository mainly uses `TB` and `LR`.
- Deprecated domains are marked consistently with the `_DEPRECATED` suffix.

### Error Handling

- `validate.py` uses `subprocess.run(..., capture_output=True, text=True)` to call the external command without aborting after a single file.
- If any graph validation command produces stdout, the script prints failure details and marks the overall run as failed.
- When at least one file fails, the script exits with `sys.exit(1)`.

### Unit Testing Standards

- There is no unit test framework and no standalone Python or YAML test suite in this repository.
- The only built-in quality gate is the graph validation driven by `validate.py`.

### Code Review & Git Workflow

- Any graph change usually needs coordinated updates across `opdef.yaml`, the target graph YAML, and `config.yaml`.
- If a new graph is not registered in `config.yaml`, Graph Manager cannot discover it from the central entrypoint.
- Because CI is intentionally lightweight, reviews should focus on graph definitions, operator interface compatibility, and accidental use of deprecated domains.

## Configuration

### Config Files

The repository is built around the following file types:

- `config.yaml`: top-level registry listing each domain's `opdef` and graph entries.
- `<domain>/opdef.yaml`: domain-level operator definitions referenced by graph files in the same directory.
- `<domain>/*.yaml`: concrete graph files describing DAG nodes, arguments, inputs, outputs, and dependencies.
- `validate.py`: walks all graph files and runs validation checks.
- `.gitlab-ci.yml`: integrates `validate.py` into GitLab CI.

A minimal registration example looks like this:

```yaml
- name: example_domain
  opdef: example_domain/opdef.yaml
  graphs:
    - name: example_graph
      path: example_domain/example_graph.yaml
      direction: LR
```

The following field meanings are verifiable from the current repository:

- `name`: domain name or graph name.
- `gitlab`: optional related repository URL, present only for some domains.
- `opdef`: path to the domain-level operator definition file.
- `path`: path to the graph file.
- `direction`: optional render direction.

### SPEX and spcli Setup

No SPEX SDK usage, `spcli` command, SPEX release configuration, or related scripts were found in this repository. The only external tool dependencies that can be confirmed are:

- `tool`: the graph drawing and validation command invoked by `validate.py`
- `python3`: used to execute `validate.py`
- Graph Manager: the primary consumer and visualization entrypoint for these configs

## Deployment

### Build for Production

This repository is not a standalone service and does not produce a runtime binary for deployment. The only local usage path that is directly verifiable from code is validation:

```bash
python3 validate.py
```

Before running it, `tool` must be available in the environment; otherwise validation cannot complete.

### Release Process

No deployment script, image build script, or service release definition is stored in this repository. The only verifiable "release" flow is configuration submission plus validation:

1. Update domain-level `opdef.yaml` and or graph YAML files.
2. If this is a new graph, add its registration to `config.yaml`.
3. Run `python3 validate.py` locally.
4. Submit to GitLab, where `.gitlab-ci.yml` runs the same validation again.

No gray rollout strategy or SPEX release process is documented in this repository, so this README does not expand beyond what is present in code.

## Monitoring

There is no monitoring code, Prometheus metric, dashboard link, or alert rule in the current repository. The observable signals come from external systems:

- console output from local `validate.py` runs
- the execution result of `python3 validate.py` in GitLab CI
- the behavior of Graph Manager when loading and rendering these configurations

For that reason, this section does not invent monitoring information that cannot be verified here.

## Business Terminology Glossary

- Graph Manager: the tool that consumes this repository and provides visualization and editing entrypoints.
- Domain: a top-level business-domain entry in `config.yaml`, such as `adsengine` or `retrieval`.
- OpDef: Operator Definition that declares available operator interfaces within a domain.
- Graph: a DAG configuration file under a domain, corresponding to `graphs[].name` and `graphs[].path`.
- Direction: graph render direction, mainly `TB` and `LR` in the current repository.
- Deprecated Domain: a historical business domain whose name ends with `_DEPRECATED`, meaning the domain is retained but should not be extended further.

## Additional Resources

- Graph Manager repository: `https://git.garena.com/shopee/deep/searchads/graph-manager`
- Current repository URL: `https://git.garena.com/shopee/deep/searchads/graph-manager-conf`
- Related repository for `retrieval`: `https://git.garena.com/shopee/deep/paidads-recall`
- Related repository for `featureserver`: `https://git.garena.com/shopee/deep/searchads/feature-server`
- Related repository for `searchads_DEPRECATED`: `https://git.garena.com/shopee/deep/search-ads/`
- Related repository for `searchadsgear_DEPRECATED`: `https://git.garena.com/shopee/deep/searchads/search-ads-gear`
- Related repository for `relevance_DEPRECATED`: `https://git.garena.com/shopee/deep/paidads-relevance`

## Frequently Asked Questions

### 1. What is the relationship between this repository and `graph-manager`?

`graph-manager-conf` only stores configuration, while `graph-manager` reads those configs and provides visualization and editing entrypoints.

### 2. What files are minimally required for a new graph?

Usually you need to add or update the target domain's graph YAML. If new operators are required, you must also update the domain `opdef.yaml`. Finally, register the graph in `config.yaml`.

### 3. Why is a newly added YAML file not visible in Graph Manager?

The most common reason is that it was not registered under the correct domain in the root `config.yaml`.

### 4. Which files does `validate.py` check?

It recursively scans all `.yaml` files, skips `opdef.yaml` and `config.yaml`, and validates only concrete graph files.

### 5. How is validation failure determined?

The current script treats stdout from `tool draw --check` as a failure signal. Any output causes failure details to be printed and the script to return a non-zero exit code.

### 6. Why does local validation fail with a missing `tool` command?

Because `tool` is not shipped in this repository. It is provided by the external Graph Manager toolchain, and `validate.py` depends on it.

### 7. Why are deprecated directories still kept in the repository?

Because `config.yaml` still registers those historical domains, and keeping them helps preserve compatibility with older graphs and historical lookups.

### 8. Which domains currently contain the most graphs?

From `config.yaml`, `adsengine` contains 21 registered graphs, while `retrieval` and `indexer` each contain 16.

### 9. What checks does CI run today?

The current `.gitlab-ci.yml` is intentionally minimal and only runs `python3 validate.py`.

### 10. Does this repository contain deployment or monitoring configuration?

No. It is a configuration repository rather than a standalone service repository, and there are no verifiable deployment scripts or monitoring definitions here.

<!-- Generated by sra-toolkit/skills/ads-readme-generate -->
