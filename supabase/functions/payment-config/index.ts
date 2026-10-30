import {handle} from '../_shared/http.ts';
import {ready,gatewayEnv} from '../_shared/gateway.ts';
Deno.serve(req=>handle(req,'payment-config',120,async()=>({available:await ready(),mode:gatewayEnv().mode,provider:'SSLCOMMERZ'})));
