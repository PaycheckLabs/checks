export type Address = `0x${string}`;
export type Hash = `0x${string}`;
export type Bytes32 = `0x${string}`;

export type PaymentCheckStatus = 'NONE' | 'ACTIVE' | 'REDEEMED' | 'VOID';

export type PaymentCheckEvent =
  | {
      type: 'PaymentCheckMinted';
      checkId: bigint;
      issuer: Address;
      initialHolder: Address;
      token: Address;
      amount: bigint;
      claimableAt: bigint;
      reference: Bytes32;
      blockNumber: bigint;
      txHash: Hash;
    }
  | {
      type: 'PaymentCheckRedeemed';
      checkId: bigint;
      redeemer: Address;
      token: Address;
      amount: bigint;
      blockNumber: bigint;
      txHash: Hash;
    }
  | {
      type: 'PaymentCheckVoided';
      checkId: bigint;
      issuer: Address;
      token: Address;
      amount: bigint;
      blockNumber: bigint;
      txHash: Hash;
    };
