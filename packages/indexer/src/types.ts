export type Address = `0x${string}`;

export type PaymentCheckEvent =
  | {
      type: 'PaymentCheckMinted';
      checkId: bigint;
      sender: Address;
      recipient: Address;
      token: Address;
      amount: bigint;
      blockNumber: bigint;
      txHash: `0x${string}`;
    }
  | {
      type: 'PaymentCheckRedeemed';
      checkId: bigint;
      redeemer: Address;
      blockNumber: bigint;
      txHash: `0x${string}`;
    };

export type PaymentCheckStatus = 'CREATED' | 'REDEEMED';
