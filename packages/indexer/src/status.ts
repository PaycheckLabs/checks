import { PaymentCheckEvent, PaymentCheckStatus } from './types.js';

export function derivePaymentCheckStatus(events: PaymentCheckEvent[]): PaymentCheckStatus {
  if (!events || events.length === 0) return 'NONE';

  for (const e of events) {
    if (e.type === 'PaymentCheckVoided') return 'VOID';
  }
  for (const e of events) {
    if (e.type === 'PaymentCheckRedeemed') return 'REDEEMED';
  }
  for (const e of events) {
    if (e.type === 'PaymentCheckMinted') return 'ACTIVE';
  }

  return 'NONE';
}
