<!-- ads-workspace-gdoc-sync: gdoc_id=1gAz_00G2nxFZt8BKoudiBWUT54aIvQgKJ_qT4lD_-fQ gdoc_url=https://docs.google.com/document/d/1gAz_00G2nxFZt8BKoudiBWUT54aIvQgKJ_qT4lD_-fQ/edit -->

# CRM

## Introduction
[Ads CRM(Customer Relationship Management)](https://bd-centre.test.shopee.com/ads-crm) is a dedicated module under [BD(Business Development) platform](bd-centre.shopee.com) to support Shopee staff in managing seller's ads related performance. 
This README aims to help new contributors understand both the business and technical aspects of the frontend project.

### Apply Permission
Contact your mentor/tech lead/PJ to grant you access under different envs.
Ensure you've been added into (here)[https://bd-centre.test.shopee.com/admin/organization/user/list].

## Tech Stack
- Frontend: Vue.js, TypeScript
- Routing: Vue Router
- Styling: SCSS
- Linting: ESLint, Stylelint
- Formatting: Prettier

### Tech Infrastucture
- This project operates within the Multi-Module Framework (MMF) as the ads-crm module, identified by Module ID: 219. For a comprehensive list of all modules, visit [here](https://seller-portal.i.shopee.io/repository/modules).

- The `ads-crm` module is part of the `bd-center` portal which identified by Portal ID: 17. To see all portals, visit [here](https://seller-portal.i.shopee.io/repository/portals).

#### Multi Module Framework
[What is MMF/MMC](https://seller-portal.i.test.shopee.io/docs/pages/quick-start/introduction.html#what-is-mmf)
[MMC configuration](https://seller-portal.i.test.shopee.io/docs/pages/mmc/config/)

- `.mmc-env`: Environment Config, configure running environments.
- `config/.remote-config.json`: Remote Config, fetch from the Portal.
- `mmc.config.js`: MMC Config, configure MMC options.
- `config/*.js`: Plugin Config, configure built-in plugins.


## Getting Started
### Install MMC
Follow the steps [here](https://seller-portal.i.test.shopee.io/docs/pages/mmc/install/#install-mmc)

After successfully installing, you can directly use the `mmc` command:
```
mmc -V
```
### Start Local Server
Under the root of current folder, run
```
yarn run init
```
This will
- Executes `mmc init -p 17`.
- Install `node_modules` of the module.
- Fetch module info and portal info according to the information from `.mmc-env` and `mmc.config.js`.
- Download portal code into `packages/bd-center` (what matters are types, node_modules,tsconfig.json,there is no souce code[this could be set by `mmc.config.js:usePortalSourceCode` to choose whether need to use or not, in our case we don't need]).
- Fetch remote config and write into `config/remote-config.json` to generate the final config to init module.
- Check if the portal and module use the same tech or precompied, if yes, install dependencies for the portal, otherwise compile portal.
- Generate module local configs(e.g. .eslintrc.json, .stylelintrc.json, tsconfig.json, typing.d.ts) to keep module's configs been consistant with the portal.

```
yarn run dev
```
This will
- Executes `mmc dev`.
- Executes `devtoolkit` to set up the proxy inside the portal.
- Starts the local development server, hosted by default at `localhost:4205`.
- Bundles the source code as static resources and been hosted in dev server.
- Ensures that when visiting the test environment BD center for CRM, you can access the resources from the dev server.


### Start Development
Access to `https://bd-centre.test.shopee.com/ads-crm` in the browser.
You will see a floating button([DevTool Kit](https://seller-portal.i.test.shopee.io/docs/pages/devtoolkit/)) on the page. Open it and switch to the [MMF dev tool](https://seller-portal.i.test.shopee.io/docs/pages/devtoolkit/core/mmf-devtools.html) tab. Ensure `Connect to Dev Server` has been toggle on and connecting to your running local server.

Now when you change your local code, the page will hot reload, applying the changes immediately.

## Development
### Workflow
Refer to the [Paid Ads Development Workflow](https://confluence.shopee.io/display/TD/%5BPaid+Ads%5D+Development+Workflow) for detailed development processes.

### Code Structure
.
├── _shared                // Common shared resources used across the project
│   ├── api                // API service definitions and configurations
│   ├── assets             // Static assets like images, fonts, etc.
│   ├── components         // Reusable Vue components
│   ├── composables        // Reusable Vue Composition API functions
│   ├── constants          // Application-wide constant definitions
│   ├── core               // Core utilities and services
│   ├── directives         // Custom Vue directives
│   ├── filters            // Vue filters for data formatting
│   ├── mixins             // Reusable Vue mixins
│   ├── router             // Routing configurations
│   ├── styles             // Global and reusable styles
│   ├── support            // Support utilities and helpers
│   ├── types              // TypeScript type definitions
│   ├── typing             // Vendor level TypeScript typings
│   └── utils              // Utility functions
├── custom.d.ts            // Custom TypeScript declarations
├── index.ts               // Main entry point for the application
├── pages                  // Page components for different views
│   ├── adsDetail          // Ads Detail Page
│   ├── overview           // Overview Page
│   ├── shop               // Shop Overview Page, aka Shop List Page
│   ├── shop-detail        // The new USF Shop Detail Page
│   └── shopDetail         // The legacy Shop Detail Page (Pending sunset)
└── typing.d.ts            // Global TypeScript declarations, generated by mmc

### Legacy Code Migration
#### Previous Codebase
The project initially used the Vue Options API with decorators. Below is an example of the old component code:
```
<template>
    <div>
    <h1>{{ title }}</h1>
    <p>{{ message }}</p>
    </div>
</template>

<script lang="tsx">
import { Component, Vue, Prop } from 'vue-property-decorator';

@Component({
  components: {},
})
export default class OldComponent extends Vue {
  @Prop({ type: String, required: true }) title!: string;

  message = 'Hello from the old component!';

  created() {
    this.greet();
  }

  greet() {
    console.log(this.message);
  }
}
</script>

<style scoped>
h1 {
  color: blue;
}

</style>


```
#### Migration Plan
We are transitioning to the Vue Composition API setup syntax while retaining the current Vue version. Here is an example of how to refactor the old component using the Composition API:
```
<template>
  <div>
    <h1>{{ title }}</h1>
    <p>{{ message }}</p>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';

const props = defineProps<{
  title: string;
}>();

const message = ref('Hello from the new component!');

const greet = () => {
  console.log(message.value);
};

onMounted(() => {
  greet();
});
</script>

<style scoped>
h1 {
  color: blue;
}
</style>

```

### UI Library
We primarily use Shopee EDS UI (https://eds.shopee.io/#/components) `version 2.8.25` to build the basic UI components. If the EDS UI widgets do not meet your requirements, you can either:

- Contact the EDS PIC for support via the Seatalk Channel (Seller-Center/BD-center/SOP/FE support).
- Implement your own solution if feasible.
  - Read the version 2.8.25 source code (here)[https://git.garena.com/jianbo.hu/vue-ui/-/tree/master/]   

### Routes
**How to add/update new routes**
There are two levels of routes:

- Framework level: `config/.remote-config.json`
- Module level: `src/_shared/router/index.ts`
For more details, see (How MMF loads modules)[https://seller-portal.i.test.shopee.io/docs/pages/mmf-runtime/#how-mmf-loads-modules].

To update routes, modify both locations. For framework-level changes, visit the (Seller Portal)[https://seller-portal.i.shopee.io/repository/modules/219/detail] and edit Routes under different environments.

For live environment edits, apply changes when ready to release, especially if modifying existing routes.

**Add Necessary Page Level Service**
If you encounter code like
 ```
import { app } from "pas-common/framework";
console.log(app.shop); // trying to access app.shop

 ```
 Or your dependencies code include such logic which is not quite transparent.

 You need to ensure that it is valid to access. This usually requires setting up `meta.service.shop` of router configuration, so that the page level will auto fetch the shop infomation from https://bd-centre.test.shopee.com/api/admin/bd_center/v1/shop/get_shop_info.
(Please double check if it is really necessray to add since it will bring some overhead to the page performance, there is a remaing  [issue](https://git.garena.com/shopee/seller-fe/seller-platform/issue-pool/-/issues/101) pending to fix in terms of it.)

Add Service Shop Information in Router:
```
{
    "meta": {
        "service": [
        "shop"
        ],
        "authCodes": [
        "can_access_menu_ads_sales_crm_shop_view"
        ],
        "nonShopFallbackPath": "/ads-crm/shop"
    },
    "name": "ADS_CRM_SHOP_DETAIL_PAGE",
    "path": "/shop-detail"
},
```

### Translation
We use the Transify ((User Guide)[https://docs.google.com/document/d/1BXT0r2C7sUmgMjbxhzGF5bkfSi5RT_85ns_TdqA3gog/edit#heading=h.usijz3i0upu2]) for translation. Usually, the PM will indicate the Transify key names, create them, and fill in the contents accordingly.

**Transify Resource**
Access the Transify resource [here](https://tsp.i.seller.shopee.io/resource/detail/3559).
**How to use**
In the legacy class component:
```
this.$t('some_transify_key')
```

In the new setup component:
```
import { translate } from "pas-common/framework";
translate('some_transify_key')
```

### Best Practices
#### Code Naming Convention
Follow the (Paid Ads WebFE Naming Convention)[https://confluence.shopee.io/display/SPAD/%5BPaid+Ads+-+WebFE%5D+Naming]

#### Sharing Common Logic and Utilities
Use `pas-common` for shared logic and utilities whenever possible. Before integrating it into your project, double-check with each product line PIC to ensure it is appropriate for your use case. If modifications are necessary, consult with the PIC to review the changes.

If the shared logic is not widely applicable like `pas-common`, place it in the `src/_shared` folder for easy access by new contributors.

## Deployemnt
### Creating PFB
Follow the (instructions)[https://sites.google.com/shopee.com/pfb-v2/user-guide/quick-start] to create your PFB in (here)[https://pfb.shopee.io/projects/323].
If BE has created already then we could share it.

### Build Your Branch
- Go to (Seller Portal)[https://seller-portal.i.shopee.io/build/modules-group]
- Select Module Group `Ads CRM(BD center)`
- Check the option `ads-crm`, choose your wanted build branch
- Choose Env
- Check `Auto Publish`
- Choose Portal as `bd-center`
- Region choose `Select All` + `sg`
- Fill in PBF2.0
  - If you can't find the PFB name under the dropdown menu, just manully fill in
- Click `Build & Publish`


If need to deploy changes to livish, no need to indicate pfb.

## Release
We follow (PaidAds Release Work Flow)[https://confluence.shopee.io/pages/viewpage.action?spaceKey=RMM&title=PaidAds+Deployment#PaidAdsDeployment-OnboardedRepos]

## Important Notes
### Vue Version
The Vue Version has been decieded by Portal level, not Module level.
Currently we are using Vue version 2.7.13 followed by BD Center.

### Styling
Always remember to use scoped styles.

## Trouble Shooting
If you encounter any infrastructure issues, please contact Seller DOD:

Seatalk Channel: Seller-Center/BD-center/SOP/FE support
Report Issues: Report issues (here)[https://git.garena.com/shopee/seller-fe/seller-platform/issue-pool/-/issues]

### Common Issues and Solutions
**No Error Output but Changes Not Applied**
If your dev server shows no errors but your changes are not reflected on the page, ensure you are connected to your dev server inside the devtool kit.

**Page Keeps Reloading**
If the page keeps reloading continuously.

You could always try the following steps to fix issue above:

Remove the local dist folder.
Reinitialize and run the dev server:
```
yarn run init & yarn dev
```
Retry accessing your changes.
