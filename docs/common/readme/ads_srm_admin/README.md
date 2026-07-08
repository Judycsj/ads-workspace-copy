<!-- ads-workspace-gdoc-sync: gdoc_id=1OB7K1BCjVlnnY63YdcZIZGU4nV_wc3086AZhE-HYCqs gdoc_url=https://docs.google.com/document/d/1OB7K1BCjVlnnY63YdcZIZGU4nV_wc3086AZhE-HYCqs/edit -->

# Ads SRM Admin

## Development

Make your own copy of env var setting:

```bash
git clone gitlab@git.garena.com:shopee/isfe/ao/ads_srm_admin.git
```

### 1. Install dependency

```bash
yarn
```

### 2. Local dev

**If you don't need to develop with local BFF, just refer to Step 3**

#### Step 1: Start your local Redis server

If you don't have Redis installed locally, please follow this [quick start](https://redis.io/topics/quickstart).

Then open your terminal and type:

```bash
redis-server
```

#### Step 2: Start your BFF server

```bash
cd packages/bff
yarn start:dev
```

Your local BFF server will run on port 7777.

#### Step 3: Start your FE development server

Before you start, create a **.env** file under **packages/front-end**, and add the following variables:

```bash
# packages/front-end/.env
VITE_ENABLE_PFB=true
VITE_PFB=pfb-incentive-one-one-credit
VITE_BFF_ORIGIN = "http://localhost:7777"
```

> Note: If you don't need to develop with local BFF, just comment out the **VITE_BFF_ORIGIN** line. The default origin will be **https://srm.ads.test.shopee.io/**

Then start the development server:

```bash
cd packages/front-end
yarn start
```

### 3. Local dev with production mode

You can run your code in production mode when you want to debug locally:

```bash
cd packages/front-end
yarn build --localServer
```

Then you can access your application at `localhost:${port}` (the port will be displayed in your terminal).

## Folder Structure

```
.
├── deploy                       //  Jenkins build config
│   ├── node.json                // BFF server deploy config
│   └── static.json              // FE deploy config
├── package.json                 // monorepo root package.json
├── packages                     // source code
│   ├── bff                      // BFF code, based on NestJS
│   │   ├── README.md
│   │   ├── config               // ENV config file
│   │   ├── nest-cli.json        // nest-cli config
│   │   ├── package.json         // BFF Project package.json file
│   │   ├── src
│   │   │   ├── app.module.ts    // BFF main module
│   │   │   ├── config
│   │   │   │   └── redis        // redis config file
│   │   │   ├── constant         // constant definition
│   │   │   │   ├── API.ts       // define all API endpoint
│   │   │   │   ├── permission.ts         // SOUP permission key
│   │   │   │   ├── programApproval.ts    // BE API
│   │   │   │   └── programManagement.ts  // BE API
│   │   │   ├── interface
│   │   │   │   └── index.ts              // General response code
│   │   │   ├── main.ts                   // APP main entry
│   │   │   ├── middlewares               // Some middlewares, like authMiddleware
│   │   │   │   ├── authMiddleware.ts
│   │   │   │   └── pfbMiddlewares.ts
│   │   │   ├── modules                   // Business logic implementation
│   │   │   │   ├── API
│   │   │   │   ├── programApproval
│   │   │   │   └── programManagement
│   │   │   ├── soup                      // Portal permission touch utils
│   │   │   │   └── touchPermission.ts
│   │   │   ├── soup.module.ts            // SOUP module registration
│   │   │   └── utils                     // Common utils
│   │   │       ├── index.ts
│   │   │       └── request.ts
│   │   ├── tsconfig.build.json
│   │   └── tsconfig.json
│   ├── front-end                     // FE code folder
│   │   ├── README.md
│   │   ├── package.json
│   │   ├── src
│   │   │   ├── 404                   // 404 page
│   │   │   ├── NoPermissionPage      // No permission Page
│   │   │   ├── _shared               // shared resources
│   │   │   │   ├── API               // All request functions
│   │   │   │   ├── assets            // static resources
│   │   │   │   ├── components        // shared components
│   │   │   │   ├── constants         // constant definition
│   │   │   │   ├── constants.ts      // Kaya-toast constants definition
│   │   │   │   ├── hook              // shared hooks
│   │   │   │   ├── typings           // FE side typing files
│   │   │   │   └── utils             // common utils
│   │   │   ├── bundle.ts             // bundle import file
│   │   │   ├── config.ts             // Sidebar navbar config file
│   │   │   ├── home                  // default home file
│   │   │   │   └── index.tsx
│   │   │   ├── index.tsx             // kaya-toast entry file
│   │   │   ├── main.scss             // main sass file
│   │   │   ├── program-approval-center   // program approval center pages
│   │   │   ├── program-approver-list     // program approver list pages
│   │   │   ├── program-overview          // program overview pages
│   │   │   ├── program-update            // program update pages
│   │   │   ├── widget-country-select     // country select pages
│   │   │   └── widget-side-nav           // side navbar
│   │   ├── static                        // FE static files
│   │   │   ├── favicon.ico
│   │   │   └── index.html
│   │   ├── toast-pack.config.js          //  toast pack config file
│   │   └── tsconfig.json
│   └── typing                            // BFF and FE shared typing files
│       └── tsconfig.json
└── yarn.lock
```

## Useful Notes

### General Guidelines

- Before you start, please make sure you are following current project's structure design.
- Please use [@shopee_common/currency](https://git.garena.com/shopee/shopee-currency-lib) to deal with currency issues.
- Use [moment-timezone](https://momentjs.com/timezone/docs/) to format time as it can solve DST (daylight saving time) issues.

### Front-end Project

- You can refer to `packages/front-end/src/_shared/utils` and `packages/front-end/src/_shared/components`. When starting a new feature, try to reuse the utils and components in your development.
- We use `commonRequest` to handle async requests. Please refer to `packages/front-end/src/_shared/API/modules/programApproval.ts` for examples.
- Please create a page under a proper module according to its menu level. A new page needs to be loaded in `bundle.ts` and configured in `config.ts` if it needs to be displayed in the menu.
- Disable/Enable PFB config in `deploy/static.json` by using the `per_feature_branch` field.
- We use `toast pack` as the default bundle tool. For more information, please refer to [toast pack](https://git.garena.com/shopee/isfe/toast-maker/toast-pack).
- To support `pfb v2` used in BFF, you need to configure it in the file: `packages/front-end/.env`.

### BFF Project

- We use [NestJS](https://docs.nestjs.com/) as our `Node.js` framework.
- We use the `.env` file to maintain our configuration.
- We use Node commands to touch permissions when we need to add new permissions in [SOUP](https://confluence.shopee.io/pages/viewpage.action?pageId=104860698). Please refer to `packages/bff/src/soup/touchPermission.ts`.

### Typing

This folder is used to store the proto types used in Frontend and BFF projects.
For every feature that needs to change the proto from BE, you should:

1. Replace the proto content in the file: `packages/typing/srmProto/srm.proto`
2. Enter the target folder: `cd packages/typing/srmProto`
3. Run command: `yarn protoc`

Then you will see a new `srm.ts` generated under this file.
