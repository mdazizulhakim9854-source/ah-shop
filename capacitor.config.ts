import type {CapacitorConfig} from '@capacitor/cli';
const config:CapacitorConfig={appId:'com.ahshop.store',appName:'AH SHOP',webDir:'dist',server:{androidScheme:'https'},android:{allowMixedContent:false},plugins:{CapacitorHttp:{enabled:false}}};
// Proposed application ID, not a registered business identifier. Confirm ownership/uniqueness before Play upload.
export default config;
