"use client";

import { BadgeCheck, ExternalLink, HeartPulse, Rocket, ShieldCheck, WalletCards } from "lucide-react";
import { useEffect, useMemo, useState } from "react";
import { decodeEventLog, formatUnits, isAddress, parseUnits, type Address } from "viem";
import {
  useAccount,
  useReadContract,
  useWaitForTransactionReceipt,
  useWriteContract,
} from "wagmi";
import {
  erc20Abi,
  FACTORY_ADDRESS,
  factoryAbi,
  USDC_ADDRESS,
  VAULT_USER_SALT,
  vaultAbi,
  VERSION_ID,
} from "../protocol";

const MINIMUM_DURATIONS = {
  inactivityPeriod: 90n * 24n * 60n * 60n,
  challengePeriod: 7n * 24n * 60n * 60n,
  primaryWindow: 30n * 24n * 60n * 60n,
  fallbackWindow: 30n * 24n * 60n * 60n,
  configDelay: 2n * 24n * 60n * 60n,
  configExecutionWindow: 30n * 24n * 60n * 60n,
  recoveryDelay: 2n * 24n * 60n * 60n,
  recoveryExecutionWindow: 30n * 24n * 60n * 60n,
} as const;

const fieldLabels = [
  ["primary", "Standard primary"],
  ["fallback", "Standard fallback"],
  ["terminalPrimary", "Terminal primary"],
  ["terminalFallback", "Terminal fallback"],
  ["guardianA", "Guardian 1"],
  ["guardianB", "Guardian 2"],
  ["guardianC", "Guardian 3"],
  ["recovery", "Recovery address"],
] as const;

type FormState = Record<(typeof fieldLabels)[number][0], string>;

const emptyForm = Object.fromEntries(fieldLabels.map(([key]) => [key, ""])) as FormState;

function shortAddress(value?: string) {
  return value ? `${value.slice(0, 6)}…${value.slice(-4)}` : "—";
}

export function LiveVault() {
  const { address, chainId, isConnected } = useAccount();
  const [form, setForm] = useState<FormState>(emptyForm);
  const [acknowledged, setAcknowledged] = useState(false);
  const [localError, setLocalError] = useState<string>();
  const [storedVaultAddress] = useState<Address | undefined>(() => {
    if (typeof window === "undefined") return undefined;
    const stored = window.localStorage.getItem("heirloom.baseSepolia.vault");
    return stored && isAddress(stored) ? stored : undefined;
  });
  const createWrite = useWriteContract();
  const approveWrite = useWriteContract();
  const depositWrite = useWriteContract();
  const heartbeatWrite = useWriteContract();
  const createReceipt = useWaitForTransactionReceipt({ hash: createWrite.data });
  const approveReceipt = useWaitForTransactionReceipt({ hash: approveWrite.data });
  const depositReceipt = useWaitForTransactionReceipt({ hash: depositWrite.data });
  const heartbeatReceipt = useWaitForTransactionReceipt({ hash: heartbeatWrite.data });

  const factoryAsset = useReadContract({
    address: FACTORY_ADDRESS,
    abi: factoryAbi,
    functionName: "asset",
    chainId: 84_532,
  });
  const factoryVersion = useReadContract({
    address: FACTORY_ADDRESS,
    abi: factoryAbi,
    functionName: "VERSION_ID",
    chainId: 84_532,
  });
  const walletUsdc = useReadContract({
    address: USDC_ADDRESS,
    abi: erc20Abi,
    functionName: "balanceOf",
    args: address ? [address] : undefined,
    chainId: 84_532,
    query: { enabled: Boolean(address) },
  });
  const createdVaultAddress = useMemo(() => {
    if (!createReceipt.data) return undefined;
    for (const log of createReceipt.data.logs) {
      try {
        const decoded = decodeEventLog({ abi: factoryAbi, data: log.data, topics: log.topics });
        if (decoded.eventName === "VaultCreated") return decoded.args.vault;
      } catch {
        // Ignore unrelated receipt logs.
      }
    }
    return undefined;
  }, [createReceipt.data]);
  const vaultAddress = createdVaultAddress ?? storedVaultAddress;

  const vaultUsdc = useReadContract({
    address: USDC_ADDRESS,
    abi: erc20Abi,
    functionName: "balanceOf",
    args: vaultAddress ? [vaultAddress] : undefined,
    chainId: 84_532,
    query: { enabled: Boolean(vaultAddress) },
  });
  const vaultOwner = useReadContract({
    address: vaultAddress,
    abi: vaultAbi,
    functionName: "owner",
    chainId: 84_532,
    query: { enabled: Boolean(vaultAddress) },
  });
  const lastSeen = useReadContract({
    address: vaultAddress,
    abi: vaultAbi,
    functionName: "lastSeen",
    chainId: 84_532,
    query: { enabled: Boolean(vaultAddress) },
  });

  useEffect(() => {
    if (createdVaultAddress) {
      window.localStorage.setItem("heirloom.baseSepolia.vault", createdVaultAddress);
    }
  }, [createdVaultAddress]);

  const protocolVerified =
    factoryAsset.data?.toLowerCase() === USDC_ADDRESS.toLowerCase() &&
    factoryVersion.data === VERSION_ID;
  const busy =
    createWrite.isPending ||
    createReceipt.isLoading ||
    approveWrite.isPending ||
    approveReceipt.isLoading ||
    depositWrite.isPending ||
    depositReceipt.isLoading ||
    heartbeatWrite.isPending ||
    heartbeatReceipt.isLoading;
  const transactionError =
    createWrite.error || approveWrite.error || depositWrite.error || heartbeatWrite.error;

  const claimDate = useMemo(() => {
    if (lastSeen.data === undefined) return undefined;
    return new Date(Number(lastSeen.data + MINIMUM_DURATIONS.inactivityPeriod) * 1000);
  }, [lastSeen.data]);

  function updateField(key: keyof FormState, value: string) {
    setForm((current) => ({ ...current, [key]: value.trim() }));
  }

  async function createVault() {
    setLocalError(undefined);
    if (!address) return setLocalError("Connect the owner wallet first.");
    if (chainId !== 84_532) return setLocalError("Switch the wallet to Base Sepolia.");
    if (!acknowledged) return setLocalError("Confirm that every recovery address is controlled.");
    const values = Object.values(form);
    if (!values.every(isAddress)) return setLocalError("Every destination must be a valid address.");
    const destinations = [form.primary, form.fallback, form.terminalPrimary, form.terminalFallback];
    if (new Set(destinations.map((value) => value.toLowerCase())).size !== destinations.length) {
      return setLocalError("The four payout destinations must be unique.");
    }
    const guardians = [form.guardianA, form.guardianB, form.guardianC];
    if (new Set(guardians.map((value) => value.toLowerCase())).size !== guardians.length) {
      return setLocalError("Guardian addresses must be unique.");
    }
    if (guardians.some((value) => value.toLowerCase() === address.toLowerCase())) {
      return setLocalError("The owner cannot also be a guardian.");
    }
    if (form.recovery.toLowerCase() === address.toLowerCase()) {
      return setLocalError("Recovery must be different from the owner.");
    }
    if (guardians.some((value) => value.toLowerCase() === form.recovery.toLowerCase())) {
      return setLocalError("Recovery cannot also be a guardian.");
    }

    await createWrite.writeContractAsync({
      address: FACTORY_ADDRESS,
      abi: factoryAbi,
      functionName: "createVault",
      args: [
        address,
        VAULT_USER_SALT,
        {
          beneficiaries: [
            { primary: form.primary as Address, fallbackAddress: form.fallback as Address, bps: 4_000 },
          ],
          terminal: {
            primary: form.terminalPrimary as Address,
            fallbackAddress: form.terminalFallback as Address,
            bps: 6_000,
          },
          durations: MINIMUM_DURATIONS,
          guardians: guardians as [Address, Address, Address],
          guardianThreshold: 2,
          recoveryAddress: form.recovery as Address,
        },
      ],
      chainId: 84_532,
    });
  }

  async function approveUsdc() {
    if (!vaultAddress) return;
    await approveWrite.writeContractAsync({
      address: USDC_ADDRESS,
      abi: erc20Abi,
      functionName: "approve",
      args: [vaultAddress, parseUnits("20", 6)],
      chainId: 84_532,
    });
  }

  async function depositUsdc() {
    if (!vaultAddress) return;
    await depositWrite.writeContractAsync({
      address: vaultAddress,
      abi: vaultAbi,
      functionName: "deposit",
      args: [parseUnits("20", 6)],
      chainId: 84_532,
    });
  }

  async function heartbeat() {
    if (!vaultAddress) return;
    await heartbeatWrite.writeContractAsync({
      address: vaultAddress,
      abi: vaultAbi,
      functionName: "heartbeat",
      chainId: 84_532,
    });
  }

  return (
    <section className="panel live-vault-panel">
      <div className="live-vault-head">
        <div>
          <span className="live-label"><span className="status-dot" /> Live Base Sepolia</span>
          <h2>{vaultAddress ? "Owner vault control" : "Create the first owner vault"}</h2>
          <p>Factory and asset identity are read directly from the deployed contracts.</p>
        </div>
        <a href={`https://base-sepolia.blockscout.com/address/${FACTORY_ADDRESS}`} target="_blank" rel="noreferrer" className="secondary-button">
          Verified factory <ExternalLink size={15} />
        </a>
      </div>

      <div className="live-proof-grid">
        <div><BadgeCheck size={17} /><span>Factory</span><strong>{shortAddress(FACTORY_ADDRESS)}</strong></div>
        <div><ShieldCheck size={17} /><span>Identity</span><strong>{protocolVerified ? "Verified v3.1" : "Checking…"}</strong></div>
        <div><WalletCards size={17} /><span>Wallet USDC</span><strong>{walletUsdc.data === undefined ? "—" : formatUnits(walletUsdc.data, 6)}</strong></div>
        <div><HeartPulse size={17} /><span>Minimum lifecycle</span><strong>90d + 7d</strong></div>
      </div>

      {!vaultAddress ? (
        <div className="launch-grid">
          <div className="address-form">
            {fieldLabels.map(([key, label]) => (
              <label key={key}>
                <span>{label}</span>
                <input value={form[key]} onChange={(event) => updateField(key, event.target.value)} placeholder="0x…" autoComplete="off" spellCheck={false} />
              </label>
            ))}
          </div>
          <div className="launch-summary">
            <h3>Minimum safe schedule</h3>
            <p>40% standard · 60% terminal</p>
            <ul>
              <li>90-day inactivity threshold</li>
              <li>7-day owner challenge</li>
              <li>30-day primary and fallback phases</li>
              <li>2-of-3 guardian recovery</li>
            </ul>
            <label className="control-check">
              <input type="checkbox" checked={acknowledged} onChange={(event) => setAcknowledged(event.target.checked)} />
              <span>I control or have verified every guardian, recovery, and payout address.</span>
            </label>
            <button className="primary-button launch-button" disabled={!isConnected || busy || !protocolVerified} onClick={createVault}>
              <Rocket size={17} /> {busy ? "Waiting for wallet…" : "Create owner vault"}
            </button>
          </div>
        </div>
      ) : (
        <div className="vault-control-grid">
          <div className="vault-identity">
            <span>Vault address</span>
            <a href={`https://base-sepolia.blockscout.com/address/${vaultAddress}`} target="_blank" rel="noreferrer">{vaultAddress}</a>
            <p>Owner {shortAddress(vaultOwner.data)} · claim eligibility {claimDate ? claimDate.toLocaleDateString() : "loading"}</p>
          </div>
          <div className="vault-balance"><span>Vault balance</span><strong>{vaultUsdc.data === undefined ? "—" : formatUnits(vaultUsdc.data, 6)} USDC</strong></div>
          <div className="vault-actions">
            <button className="secondary-button" onClick={approveUsdc} disabled={busy || approveReceipt.isSuccess}>1. {approveReceipt.isSuccess ? "USDC approved" : "Approve 20 USDC"}</button>
            <button className="primary-button" onClick={depositUsdc} disabled={busy || !approveReceipt.isSuccess || depositReceipt.isSuccess}>2. {depositReceipt.isSuccess ? "20 USDC deposited" : "Deposit 20 USDC"}</button>
            <button className="secondary-button" onClick={heartbeat} disabled={busy}>Send heartbeat</button>
          </div>
        </div>
      )}

      {(localError || transactionError) && <div className="alert error-alert">{localError || transactionError?.shortMessage || transactionError?.message}</div>}
      {createReceipt.isSuccess && <div className="alert success-alert">Vault creation confirmed on Base Sepolia.</div>}
      {depositReceipt.isSuccess && <div className="alert success-alert">20 test USDC deposited. Owner liveness updated on-chain.</div>}
      {heartbeatReceipt.isSuccess && <div className="alert success-alert">Owner heartbeat confirmed.</div>}
    </section>
  );
}
