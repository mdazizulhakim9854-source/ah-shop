export type Product={id:string;name:string;name_en:string;description:string;category_id:string;price:number;compare_at:number|null;stock:number;sku:string;active:boolean;sample:boolean;art:string;featured?:boolean;sort_order?:number;image_url?:string|null};
export type Category={id:string;name:string;name_en:string;icon:string};
export type CartLine={id:string;qty:number};
export type Settings={whatsapp:string;support_email:string;delivery_charge:number|null;delivery_time:string;payment_bkash:string;payment_nagad:string;about:string;delivery_policy:string;return_policy:string;privacy_policy:string;terms:string;online_payment_enabled:boolean;online_discount_percent:number;theme_accent:string;hero_title_bn:string;hero_title_en:string;hero_subtitle_bn:string;hero_subtitle_en:string};
export type Order={id:string;created_at:string;customer_name:string;phone:string;address:string;district:string;area:string;notes:string;payment_method:string;transaction_id:string;payment_status:string;status:string;subtotal:number;delivery_charge:number;discount:number;total:number;items:{product_id:string;name:string;qty:number;price:number}[];sample?:boolean;gateway_mode?:string|null};
export type ChatMessage={role:'user'|'assistant';content:string};

export type Review={id:string;product_id:string;author_name:string;rating:number;body:string;status?:string;sample:boolean;verified_purchase:boolean;created_at:string;order_id?:string|null};
