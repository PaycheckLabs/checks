import { PaymentCheckEvent, PaymentCheckStatus } from './types.js';

export function derivePaymentCheckStatus(events: PaymentCheckEvent[]): PaymentCheckStatus {
  for (const e of events) {
    if (e.type === 'PaymentCheckRedeemed') return 'REDEEMED';
  }
  return 'CREATED';
}
