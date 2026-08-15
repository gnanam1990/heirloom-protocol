export const BASE_SEPOLIA_CHAIN_ID = 84_532;
export const FACTORY_ADDRESS = "0x935e5101d7563429BC152889603D3A17f466f4e4" as const;
export const USDC_ADDRESS = "0x036CbD53842c5426634e7929541eC2318f3dCF7e" as const;
export const VERSION_ID =
  "0x2307fc907cb859b0cb1ee608138ba346e301805703f489f8370477c357b73f56" as const;
export const VAULT_USER_SALT =
  "0x484549524c4f4f4d5f424153455f5345504f4c49415f534d4f4b455f52310000" as const;
export const VAULT_STORAGE_SLOT = "heirloom.baseSepolia.v3.1-r1.vault";
export const RELEASE_OWNER_ADDRESS = "0xE8405844a45C209895afE2e49be6aA2C6C6202a6" as const;
export const RELEASE_VAULT_ADDRESS = "0x21ea6A01Dd4A7C9F87Bdc80773fbB765FF6fa371" as const;
export const RELEASE_TRANSACTIONS = {
  factory: "0x839cb78414d54cd2e584d44b3f1062c43e7d6643741d6685c0d6218d8dff0732",
  create: "0x8f6879fa53eab91288f1c21597573fd17746c06b50b7d6f49e7fec0f04a66312",
  approve: "0xaeb3787db2c64bbf6c62d6cba71d6e8cacc5a24f2643765b82b823d4bc596df6",
  atomicUnitDeposit: "0xef168d573323b2cfaa76f24ea78129520562917f8aad342b3e7227f51d644e1a",
  deposit: "0x233bec0ae165905a397616be5222132225c368f1400765a47f8b26cb3433f615",
} as const;

export const MAINNET_PROPOSAL = {
  chainId: 8_453,
  network: "Base mainnet",
  factory: "0x524A95082dAD59fd8bf18FA27F89E3f55202eEcf",
  implementation: "0xd746Ca02cCFd0CA86d61eDd026810fdb8a0b3E80",
  asset: "0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913",
  transaction: "0xf04990ce21cbe3a3a78d3ae347c1250f10d23cccd6437aa5bdba090ddcce9270",
  block: 50_005_381,
  vaultCountAtVerification: 0,
  explorer: {
    transaction:
      "https://base.blockscout.com/tx/0xf04990ce21cbe3a3a78d3ae347c1250f10d23cccd6437aa5bdba090ddcce9270",
    factory:
      "https://base.blockscout.com/address/0x524A95082dAD59fd8bf18FA27F89E3f55202eEcf",
    implementation:
      "https://base.blockscout.com/address/0xd746Ca02cCFd0CA86d61eDd026810fdb8a0b3E80",
  },
} as const;

const beneficiaryComponents = [
  { name: "primary", type: "address" },
  { name: "fallbackAddress", type: "address" },
  { name: "bps", type: "uint16" },
] as const;

const durationComponents = [
  { name: "inactivityPeriod", type: "uint64" },
  { name: "challengePeriod", type: "uint64" },
  { name: "primaryWindow", type: "uint64" },
  { name: "fallbackWindow", type: "uint64" },
  { name: "configDelay", type: "uint64" },
  { name: "configExecutionWindow", type: "uint64" },
  { name: "recoveryDelay", type: "uint64" },
  { name: "recoveryExecutionWindow", type: "uint64" },
] as const;

const configComponents = [
  { name: "beneficiaries", type: "tuple[]", components: beneficiaryComponents },
  { name: "terminal", type: "tuple", components: beneficiaryComponents },
  { name: "durations", type: "tuple", components: durationComponents },
  { name: "guardians", type: "address[]" },
  { name: "guardianThreshold", type: "uint8" },
  { name: "recoveryAddress", type: "address" },
] as const;

export const factoryAbi = [
  {
    type: "function",
    name: "asset",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "address" }],
  },
  {
    type: "function",
    name: "implementation",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "address" }],
  },
  {
    type: "function",
    name: "deploymentChainId",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    type: "function",
    name: "VERSION_ID",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "bytes32" }],
  },
  {
    type: "function",
    name: "createVault",
    stateMutability: "nonpayable",
    inputs: [
      { name: "owner", type: "address" },
      { name: "userSalt", type: "bytes32" },
      { name: "config", type: "tuple", components: configComponents },
    ],
    outputs: [{ name: "vault", type: "address" }],
  },
  {
    type: "event",
    name: "VaultCreated",
    anonymous: false,
    inputs: [
      { indexed: true, name: "vault", type: "address" },
      { indexed: true, name: "owner", type: "address" },
      { indexed: true, name: "asset", type: "address" },
      { indexed: false, name: "versionId", type: "bytes32" },
      { indexed: false, name: "configHash", type: "bytes32" },
      { indexed: false, name: "creationSalt", type: "bytes32" },
      { indexed: false, name: "runtimeCodeHash", type: "bytes32" },
    ],
  },
] as const;

export const vaultAbi = [
  {
    type: "function",
    name: "owner",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "address" }],
  },
  {
    type: "function",
    name: "vaultState",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint8" }],
  },
  {
    type: "function",
    name: "lastSeen",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint64" }],
  },
  {
    type: "function",
    name: "livenessNonce",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint64" }],
  },
  {
    type: "function",
    name: "configNonce",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint64" }],
  },
  {
    type: "function",
    name: "currentConfigHash",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "bytes32" }],
  },
  {
    type: "function",
    name: "durations",
    stateMutability: "view",
    inputs: [],
    outputs: durationComponents,
  },
  {
    type: "function",
    name: "beneficiary",
    stateMutability: "view",
    inputs: [{ name: "index", type: "uint8" }],
    outputs: [{ name: "", type: "tuple", components: beneficiaryComponents }],
  },
  {
    type: "function",
    name: "terminalBeneficiary",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "tuple", components: beneficiaryComponents }],
  },
  {
    type: "function",
    name: "guardian",
    stateMutability: "view",
    inputs: [{ name: "index", type: "uint8" }],
    outputs: [{ name: "", type: "address" }],
  },
  {
    type: "function",
    name: "guardianThreshold",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint8" }],
  },
  {
    type: "function",
    name: "recoveryAddress",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "address" }],
  },
  {
    type: "function",
    name: "heartbeat",
    stateMutability: "nonpayable",
    inputs: [],
    outputs: [],
  },
  {
    type: "function",
    name: "deposit",
    stateMutability: "nonpayable",
    inputs: [{ name: "amount", type: "uint256" }],
    outputs: [],
  },
] as const;

export const erc20Abi = [
  {
    type: "function",
    name: "balanceOf",
    stateMutability: "view",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    type: "function",
    name: "allowance",
    stateMutability: "view",
    inputs: [
      { name: "owner", type: "address" },
      { name: "spender", type: "address" },
    ],
    outputs: [{ name: "", type: "uint256" }],
  },
  {
    type: "function",
    name: "approve",
    stateMutability: "nonpayable",
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" },
    ],
    outputs: [{ name: "", type: "bool" }],
  },
] as const;
