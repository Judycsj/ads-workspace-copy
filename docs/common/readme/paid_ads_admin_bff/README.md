<!-- ads-workspace-gdoc-sync: gdoc_id=1qbL2iM3VmLx9jT3MLnKYh8U6X5nhwtM-RwOTDtpIRcM gdoc_url=https://docs.google.com/document/d/1qbL2iM3VmLx9jT3MLnKYh8U6X5nhwtM-RwOTDtpIRcM/edit -->

![node](https://img.shields.io/badge/node-10.7.0-brightgreen.svg)
![lerna](https://img.shields.io/badge/maintained%20with-lerna-cc00ff.svg)

## Get Started

> This monorepo requires latest `yarn`.

To install `yarn`, `yarn` prefers binary package manager rather than `npm`:

So you might want to use `brew`, `apt-get`, or other managers, which depends on your operating system.

Using Homebrew on OS X, for example:

```sh
brew install yarn
```

To add dependencies

```sh
yarn
```

To run with test env:

```sh
yarn start:dev
```

## Structure

### Core executable folder

The core modules used in BFF are located in `src` folder:

```
📦 src
 ├ 📂 constant
 │ ├ 📜 API.ts               // Store the API constant object
 │ └ 📜 permission.ts        // Store the soup permissions constant object
 ├ 📂 interface              // Store some customized types from all the modules
 ├ 📂 middlewares
 │ ├ 📜 pfb.middleware.ts    // Used for adding pfb into the request sent to BE
 ├ 📂 modules
 │ ├ 📂 API
 │ │ ├ 📜 api.service.ts     // Common api service, can be used in the module
 │ │ ├ 📜 fetch.ts           // Customized Axios instance
 │ │ ├ 📜 index.ts
 │ │ └ 📜 spex.service.ts    // Spex api service, used for the modules basedd on Spex
 │ ├ 📂 ads                  // Ads Module includings KeywordsAds/ShopAds/TargetingAds modules
 │ ├ 📂 affiliateAds
 │ ├ 📂 badCaseBenchmark
 │ ├ 📂 balanceLog
 │ ├ 📂 bannerAds
 │ ├ 📂 blacklistKeywords
 │ ├ 📂 fraudTool
 │ ├ 📂 manualAdsCredit
 │ └ 📂 whitelist
 ├ 📂 protofiles             // Store the protobuf files used in every module
 ├ 📂 soup                   // Used for generating the soup permission code in soup
 │ ├ 📜 touchPermission.js
 │ └ 📜 touchPermission.ts
 ├ 📂 utils
 │ ├ 📜 csv.ts               // Used for handling the csv file needs
 │ ├ 📜 index.ts             // Basic util functions
 │ ├ 📜 outputFunctions.ts   // Provides different kinds of log function
 │ └ 📜 request.ts           // Provide the util functions used in request stage
 ├ 📜 app.module.ts          // Root module
 └ 📜 main.ts                // Root execution file
```

### Config Folder

The files from config folder will be regarded as the opition used in soup2-sdk-nest module(thirdParty module)

```
📦 config
 ├ 📜 live.env
 ├ 📜 local.env
 ├ 📜 staging.env
 ├ 📜 test.env
 └ 📜 uat.env
```

The `live.env` could be referenced as the basic format of the configuration.
