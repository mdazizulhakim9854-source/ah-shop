/** Future integration boundaries ONLY. These interfaces do not connect a provider. */
export interface VerifiedPaymentEvent {
  provider: 'bkash' | 'nagad';
  merchantOrderId: string;
  providerTransactionId: string;
  amountBDT: string;
  currency: 'BDT';
  verifiedAt: string;
}
export interface MerchantPaymentAdapter {
  createPayment(orderId: string): Promise<{redirectUrl: string}>;
  // Must verify server-side provider status, amount, currency, merchant account and replay key.
  verifyCallback(rawBody: Uint8Array, headers: Headers): Promise<VerifiedPaymentEvent>;
}
export interface OfficialWhatsAppAdapter {
  verifyWebhook(rawBody: Uint8Array, headers: Headers): Promise<boolean>;
  sendApprovedTemplate(toE164: string, templateName: string, parameters: string[]): Promise<{messageId:string}>;
}
