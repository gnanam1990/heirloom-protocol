"use client";

import {
  Activity,
  AlertTriangle,
  ArrowUpRight,
  BadgeCheck,
  Bell,
  ChevronRight,
  CircleHelp,
  Clock3,
  FileCheck2,
  Fingerprint,
  HeartPulse,
  LayoutDashboard,
  LockKeyhole,
  Menu,
  Network,
  ShieldCheck,
  Users,
  Vault,
  WalletCards,
  X,
} from "lucide-react";
import { useEffect, useState } from "react";
import { formatUnits } from "viem";
import { useAccount, useConnect, useDisconnect, useSwitchChain } from "wagmi";
import { baseSepolia } from "wagmi/chains";
import {
  MAINNET_PROPOSAL,
  RELEASE_TRANSACTIONS,
  RELEASE_VAULT_ADDRESS,
} from "../protocol";
import { LiveVault, type VaultSnapshot } from "./LiveVault";

type View = "overview" | "beneficiaries" | "security" | "activity";
type IconType = typeof Vault;

const navigation = [
  { id: "overview" as const, label: "Overview", icon: LayoutDashboard },
  { id: "beneficiaries" as const, label: "Beneficiaries", icon: Users },
  { id: "security" as const, label: "Security", icon: ShieldCheck },
  { id: "activity" as const, label: "Activity", icon: Activity },
];

function shortAddress(address?: string) {
  return address ? `${address.slice(0, 6)}…${address.slice(-4)}` : "—";
}

function days(value?: bigint) {
  return value === undefined ? "—" : `${Number(value) / 86_400} days`;
}

export function Dashboard() {
  const [view, setView] = useState<View>("overview");
  const [mobileOpen, setMobileOpen] = useState(false);
  const [vaultSnapshot, setVaultSnapshot] = useState<VaultSnapshot>({ guardians: [] });
  const { address, chainId, isConnected } = useAccount();
  const { connectors, connect, isPending, error } = useConnect();
  const { disconnect } = useDisconnect();
  const { switchChain } = useSwitchChain();
  const baseConnector = connectors.find((connector) => connector.id === "baseAccount");
  const injectedConnector = connectors.find((connector) => connector.id === "injected");
  const preferredConnector = injectedConnector ?? baseConnector;

  function connectWallet() {
    if (preferredConnector) connect({ connector: preferredConnector, chainId: baseSepolia.id });
  }

  return (
    <main className="app-shell">
      <aside className={`sidebar ${mobileOpen ? "sidebar-open" : ""}`}>
        <div className="brand-row">
          <span className="base-mark" aria-hidden="true" />
          <span className="brand-name">heirloom</span>
          <button
            className="icon-button mobile-close"
            onClick={() => setMobileOpen(false)}
            aria-label="Close navigation"
          >
            <X size={18} />
          </button>
        </div>

        <nav className="nav-list" aria-label="Primary navigation">
          <p className="nav-eyebrow">Vault</p>
          {navigation.map((item) => {
            const Icon = item.icon;
            return (
              <button
                key={item.id}
                className={`nav-item ${view === item.id ? "nav-item-active" : ""}`}
                onClick={() => {
                  setView(item.id);
                  setMobileOpen(false);
                }}
              >
                <Icon size={18} strokeWidth={1.8} />
                <span>{item.label}</span>
              </button>
            );
          })}
        </nav>

        <div className="sidebar-spacer" />
        <div className="network-card">
          <div className="network-card-head">
            <span className="status-dot" /> Base Sepolia
          </div>
          <p>Pre-production network</p>
          <div className="network-row">
            <span>Protocol v3.1-R1</span>
            <BadgeCheck size={15} />
          </div>
        </div>
        <button
          className="help-link"
          onClick={() => {
            setView("security");
            setMobileOpen(false);
          }}
        >
          <CircleHelp size={17} /> Safety guide
        </button>
      </aside>

      {mobileOpen && (
        <button
          className="sidebar-scrim"
          aria-label="Close navigation"
          onClick={() => setMobileOpen(false)}
        />
      )}

      <section className="workspace">
        <header className="topbar">
          <button
            className="icon-button mobile-menu"
            onClick={() => setMobileOpen(true)}
            aria-label="Open navigation"
          >
            <Menu size={20} />
          </button>
          <div className="environment-pill">
            <span className="status-dot" /> Base Sepolia
          </div>
          <div className="topbar-actions">
            <button
              className="icon-button"
              aria-label="Open activity"
              onClick={() => setView("activity")}
            >
              <Bell size={19} />
            </button>
            {isConnected ? (
              <button
                className="account-button"
                onClick={() => disconnect()}
                title="Disconnect Base Account"
              >
                <span className="account-identicon" />
                <span>{shortAddress(address)}</span>
              </button>
            ) : (
              <button
                className="primary-button connect-button"
                onClick={connectWallet}
                disabled={!preferredConnector || isPending}
              >
                <Fingerprint size={17} />
                {isPending ? "Opening wallet…" : "Connect wallet"}
              </button>
            )}
          </div>
        </header>

        <div className="content-wrap">
          <div className="page-heading">
            <div>
              <p className="page-kicker">
                {view === "overview" ? "Owner vault" : "Vault controls"}
              </p>
              <h1>{navigation.find((item) => item.id === view)?.label}</h1>
              <p className="page-description">
                {view === "overview" &&
                  "A clear view of liveness, routing, and the next irreversible deadline."}
                {view === "beneficiaries" &&
                  "Review the destination-locked payment schedule and rollover order."}
                {view === "security" &&
                  "Recovery quorum, version identity, and owner-only liveness controls."}
                {view === "activity" &&
                  "Verifiable protocol events, actions, and lifecycle evidence."}
              </p>
            </div>
            <div className="heading-actions">
              <span className="preview-badge">Testnet live · mainnet proof verified</span>
              <a
                className="secondary-button"
                href="https://github.com/gnanam1990/heirloom-protocol/blob/main/docs/PROOF-OF-WORK.md"
                target="_blank"
                rel="noreferrer"
              >
                <FileCheck2 size={17} /> Public proof
              </a>
            </div>
          </div>

          {error && (
            <div className="alert error-alert">
              Base Account connection failed: {error.message}
            </div>
          )}
          {isConnected && chainId !== baseSepolia.id && (
            <div className="alert chain-alert">
              <span>Switch to Base Sepolia to use this pre-production vault.</span>
              <button onClick={() => switchChain({ chainId: baseSepolia.id })}>
                Switch network
              </button>
            </div>
          )}

          {view === "overview" && (
            <Overview
              snapshot={vaultSnapshot}
              onSnapshot={setVaultSnapshot}
              onNavigate={setView}
            />
          )}
          {view === "beneficiaries" && <Beneficiaries snapshot={vaultSnapshot} />}
          {view === "security" && <Security snapshot={vaultSnapshot} />}
          {view === "activity" && <ActivityView snapshot={vaultSnapshot} />}
        </div>
      </section>
    </main>
  );
}

function Overview({
  snapshot,
  onSnapshot,
  onNavigate,
}: {
  snapshot: VaultSnapshot;
  onSnapshot: (snapshot: VaultSnapshot) => void;
  onNavigate: (view: View) => void;
}) {
  const [now, setNow] = useState<number>();
  useEffect(() => {
    const refresh = window.setTimeout(() => setNow(Date.now()), 0);
    const interval = window.setInterval(() => setNow(Date.now()), 60_000);
    return () => {
      window.clearTimeout(refresh);
      window.clearInterval(interval);
    };
  }, []);
  const funded = (snapshot.balance ?? 0n) > 0n;
  const active = snapshot.state === 0;
  const inactivity = snapshot.durations?.[0];
  const challenge = snapshot.durations?.[1];
  const claimAt =
    snapshot.lastSeen !== undefined && inactivity !== undefined
      ? Number(snapshot.lastSeen + inactivity) * 1000
      : undefined;
  const remainingDays = claimAt && now
    ? Math.max(0, Math.ceil((claimAt - now) / (24 * 60 * 60 * 1000)))
    : undefined;
  const elapsedPercent =
    claimAt && now && snapshot.lastSeen !== undefined && inactivity
      ? Math.min(
          100,
          Math.max(
            0,
            ((now / 1000 - Number(snapshot.lastSeen)) / Number(inactivity)) * 100,
          ),
        )
      : 0;
  const status = snapshot.address
    ? active
      ? funded
        ? "Active · funded"
        : "Active · awaiting funding"
      : `State ${snapshot.state ?? "—"}`
    : "Factory ready";

  return (
    <>
      <LiveVault onSnapshot={onSnapshot} />
      <MainnetProposalProof />
      <section className="status-hero">
        <div className="status-copy">
          <div className="status-title-row">
            <span className="healthy-ring">
              <HeartPulse size={24} />
            </span>
            <span>
              <span className="eyebrow">Vault status</span>
              <strong>{status}</strong>
            </span>
          </div>
          <p>
            {snapshot.address
              ? "Only a fresh action signed by the current owner can extend this vault's liveness."
              : "Create an owner vault above. The deployed factory is source verified and chain locked."}
          </p>
          {snapshot.address && (
            <a
              className="heartbeat-button"
              href={`https://base-sepolia.blockscout.com/address/${snapshot.address}`}
              target="_blank"
              rel="noreferrer"
            >
              Open vault <ArrowUpRight size={16} />
            </a>
          )}
        </div>
        <div className="deadline-panel">
          <span className="eyebrow">Next claim boundary</span>
          <strong>{remainingDays === undefined ? "—" : `${remainingDays} days`}</strong>
          <span>
            {claimAt
              ? new Date(claimAt).toLocaleString()
              : "Available after a vault is configured"}
          </span>
          <div className="progress-track">
            <span style={{ width: `${elapsedPercent}%` }} />
          </div>
          <div className="progress-labels">
            <span>Last owner action</span>
            <span>90-day threshold</span>
          </div>
        </div>
      </section>

      <section className="metric-grid">
        <Metric
          icon={WalletCards}
          label="Vault balance"
          value={snapshot.balance === undefined ? "—" : `${formatUnits(snapshot.balance, 6)} USDC`}
          meta={snapshot.address ? shortAddress(snapshot.address) : "No owner vault selected"}
        />
        <Metric
          icon={HeartPulse}
          label="Liveness epoch"
          value={snapshot.livenessNonce?.toString() ?? "—"}
          meta="Owner-authenticated actions only"
        />
        <Metric
          icon={ShieldCheck}
          label="Recovery quorum"
          value={snapshot.guardianThreshold ? `${snapshot.guardianThreshold} of ${snapshot.guardians.length}` : "—"}
          meta={snapshot.recoveryAddress ? `Recovery ${shortAddress(snapshot.recoveryAddress)}` : "Not loaded"}
        />
        <Metric
          icon={Clock3}
          label="Challenge window"
          value={days(challenge)}
          meta="Begins after a valid claim request"
        />
      </section>

      <section className="dashboard-grid">
        <div className="panel beneficiaries-panel">
          <PanelHeader
            title="Destination schedule"
            subtitle="Executor cannot choose where funds go."
            action="View all"
            onAction={() => onNavigate("beneficiaries")}
          />
          <div className="beneficiary-list">
            <BeneficiaryRow
              initials="S"
              label={snapshot.standard ? shortAddress(snapshot.standard.primary) : "Standard route"}
              share={snapshot.standard ? `${snapshot.standard.bps / 100}%` : "—"}
              phase="Primary"
              color="blue"
            />
            <div className="terminal-row">
              <div className="avatar terminal-avatar">
                <LockKeyhole size={17} />
              </div>
              <div className="beneficiary-copy">
                <strong>{snapshot.terminal ? shortAddress(snapshot.terminal.primary) : "Terminal route"}</strong>
                <span>Terminal · executes last</span>
              </div>
              <div className="beneficiary-phase terminal-phase">Terminal locked</div>
              <strong className="share-value">
                {snapshot.terminal ? `${snapshot.terminal.bps / 100}%` : "—"}
              </strong>
            </div>
          </div>
          <div className="destination-legend">
            <LockKeyhole size={15} />
            <span>
              Every phase exposes exactly one valid destination. Fallback timing cannot detect key
              loss.
            </span>
          </div>
        </div>

        <div className="panel timeline-panel">
          <PanelHeader
            title="Lifecycle timeline"
            subtitle="Current state and irreversible boundaries."
          />
          <ol className="timeline">
            <TimelineItem state="done" title="Factory deployed" meta="Version HEIRLOOM_V3_1_R1 · source verified" />
            <TimelineItem state={snapshot.address ? "done" : "current"} title="Vault configured" meta={snapshot.address ? shortAddress(snapshot.address) : "Owner-controlled addresses required"} />
            <TimelineItem state={funded ? "done" : snapshot.address ? "current" : undefined} title="Vault funded" meta={funded ? `${formatUnits(snapshot.balance ?? 0n, 6)} USDC confirmed on-chain` : "Awaiting owner deposit"} />
            <TimelineItem state={funded && active ? "current" : undefined} title="Owner liveness" meta={`${days(inactivity)} inactivity threshold`} />
            <TimelineItem title="Challenge and distribution" meta="7 days, then primary → fallback → rollover" />
            <TimelineItem title="Terminal settlement" meta="Only after all standard shares resolve" />
          </ol>
        </div>
      </section>

      <section className="proof-strip">
        <div className="proof-icon">
          <BadgeCheck size={22} />
        </div>
        <div>
          <span className="eyebrow">Protocol evidence</span>
          <strong>73 core · 9 fork · 5 stateful · 16/16 mutants</strong>
        </div>
        <div className="proof-meta">
          <span>Runtime</span>
          <strong>23,818 B</strong>
        </div>
        <a
          className="text-button"
          href="https://github.com/gnanam1990/heirloom-protocol/actions"
          target="_blank"
          rel="noreferrer"
        >
          Review proof <ArrowUpRight size={16} />
        </a>
      </section>
    </>
  );
}

function Beneficiaries({ snapshot }: { snapshot: VaultSnapshot }) {
  return (
    <section className="panel detail-panel">
      <PanelHeader
        title="Destination-locked schedule"
        subtitle="Shares are calculated once from the distribution snapshot."
      />
      <div className="schedule-table" role="table" aria-label="Beneficiary schedule">
        <div className="schedule-head" role="row">
          <span>Beneficiary</span><span>Primary phase</span><span>Fallback phase</span><span>Share</span>
        </div>
        <ScheduleRow
          name="Standard route"
          primary={shortAddress(snapshot.standard?.primary)}
          fallback={shortAddress(snapshot.standard?.fallbackAddress)}
          share={snapshot.standard ? `${snapshot.standard.bps / 100}%` : "—"}
        />
        <ScheduleRow
          name="Terminal route"
          primary={shortAddress(snapshot.terminal?.primary)}
          fallback={shortAddress(snapshot.terminal?.fallbackAddress)}
          share={snapshot.terminal ? `${snapshot.terminal.bps / 100}%` : "—"}
          terminal
        />
      </div>
      <div className="info-callout">
        <Clock3 size={19} />
        <div><strong>Time determines the route</strong><p>Primary is valid first, fallback becomes valid after its deadline, then unpaid standard shares roll into the terminal amount.</p></div>
      </div>
    </section>
  );
}

function Security({ snapshot }: { snapshot: VaultSnapshot }) {
  return (
    <div className="security-grid">
      <section className="panel detail-panel">
        <PanelHeader title="Guardian recovery" subtitle="Guardians may activate only the owner-precommitted address." />
        <div className="quorum-visual"><div className="quorum-number">{snapshot.guardianThreshold ?? "—"}<span>/{snapshot.guardians.length || "—"}</span></div><div><strong>Approval threshold</strong><p>{days(snapshot.durations?.[6])} activation delay · {days(snapshot.durations?.[7])} execution window</p></div></div>
        <div className="guardian-stack">
          {snapshot.guardians.map((guardian, index) => <span key={guardian} title={guardian}>G{index + 1}</span>)}
          <p>{snapshot.guardians.length || "—"} configured guardians</p>
        </div>
        <SecurityRow icon={ShieldCheck} label="Recovery destination" value={shortAddress(snapshot.recoveryAddress)} />
      </section>
      <section className="panel detail-panel">
        <PanelHeader title="Verifiable identity" subtitle="Publicly inspectable for the life of every vault." />
        <SecurityRow icon={Network} label="Network" value="Base Sepolia · 84532" />
        <SecurityRow icon={Vault} label="Version" value="HEIRLOOM_V3_1_R1" />
        <SecurityRow icon={FileCheck2} label="Config epoch" value={snapshot.configNonce?.toString() ?? "—"} />
        <SecurityRow icon={Fingerprint} label="Config hash" value={shortAddress(snapshot.configHash)} />
        <SecurityRow icon={LockKeyhole} label="Upgrade authority" value="None" />
      </section>
      <section className="panel detail-panel security-wide">
        <PanelHeader title="Liveness boundary" subtitle="Actions that can and cannot postpone a claim." />
        <div className="permission-grid">
          <Permission good title="Creates liveness" items={["Owner heartbeat", "Owner deposit", "Owner withdrawal", "Owner config proposal or veto"]} />
          <Permission title="Never creates liveness" items={["Config execution", "Guardian votes", "Claim requests", "Direct token transfers"]} />
        </div>
      </section>
    </div>
  );
}

function ActivityView({ snapshot }: { snapshot: VaultSnapshot }) {
  const isReleaseVault = snapshot.address?.toLowerCase() === RELEASE_VAULT_ADDRESS.toLowerCase();
  return (
    <section className="panel detail-panel">
      <PanelHeader title="Protocol activity" subtitle="Every material transition is independently verifiable on Base." />
      <div className="activity-list">
        <ActivityRow
          icon={AlertTriangle}
          title="Unaudited proposal factory deployed"
          meta={`Aug 15, 2026 · Base mainnet block ${MAINNET_PROPOSAL.block} · no vaults authorized`}
          hash="0xf049…9270"
          href={MAINNET_PROPOSAL.explorer.transaction}
        />
        {isReleaseVault && (
          <>
            <ActivityRow icon={WalletCards} title="R1 vault funded with 20 USDC" meta="Aug 15, 2026 · Base Sepolia block 45502623 · liveness nonce 3" hash="0x233b…f615" href={`https://base-sepolia.blockscout.com/tx/${RELEASE_TRANSACTIONS.deposit}`} />
            <ActivityRow icon={FileCheck2} title="20 USDC approval recorded" meta="Aug 15, 2026 · Base Sepolia block 45501588" hash="0xaeb3…6df6" href={`https://base-sepolia.blockscout.com/tx/${RELEASE_TRANSACTIONS.approve}`} />
            <ActivityRow icon={Vault} title="R1 vault created" meta="Aug 15, 2026 · Base Sepolia block 45500300" hash="0x8f68…6312" href={`https://base-sepolia.blockscout.com/tx/${RELEASE_TRANSACTIONS.create}`} />
          </>
        )}
        <ActivityRow icon={FileCheck2} title="R1 factory deployed" meta="Aug 14, 2026 · Base Sepolia block 45483268" hash="0x839c…f0732" href={`https://base-sepolia.blockscout.com/tx/${RELEASE_TRANSACTIONS.factory}`} />
      </div>
    </section>
  );
}

function Metric({ icon: Icon, label, value, meta }: { icon: IconType; label: string; value: string; meta: string }) {
  return <div className="metric-card"><div className="metric-icon"><Icon size={19} /></div><span>{label}</span><strong>{value}</strong><p>{meta}</p></div>;
}

function PanelHeader({ title, subtitle, action, onAction }: { title: string; subtitle: string; action?: string; onAction?: () => void }) {
  return <div className="panel-header"><div><h2>{title}</h2><p>{subtitle}</p></div>{action && <button className="text-button" onClick={onAction}>{action} <ChevronRight size={15} /></button>}</div>;
}

function MainnetProposalProof() {
  return (
    <section className="mainnet-proof-panel" aria-labelledby="mainnet-proof-title">
      <div className="mainnet-proof-head">
        <div>
          <span className="proposal-pill"><BadgeCheck size={14} /> Base mainnet · proposal proof</span>
          <h2 id="mainnet-proof-title">Factory live. Product writes remain locked.</h2>
          <p>
            The reviewed proposal factory and implementation are source verified on Base. This is
            public technical evidence, not a production launch.
          </p>
        </div>
        <a
          className="secondary-button"
          href={MAINNET_PROPOSAL.explorer.transaction}
          target="_blank"
          rel="noreferrer"
        >
          View transaction <ArrowUpRight size={16} />
        </a>
      </div>
      <div className="mainnet-proof-facts">
        <a href={MAINNET_PROPOSAL.explorer.factory} target="_blank" rel="noreferrer">
          <span>Factory</span><strong>{shortAddress(MAINNET_PROPOSAL.factory)}</strong>
        </a>
        <a href={MAINNET_PROPOSAL.explorer.implementation} target="_blank" rel="noreferrer">
          <span>Implementation</span><strong>{shortAddress(MAINNET_PROPOSAL.implementation)}</strong>
        </a>
        <div><span>Deployment block</span><strong>{MAINNET_PROPOSAL.block.toLocaleString("en-US")}</strong></div>
        <div><span>Vault count verified</span><strong>{MAINNET_PROPOSAL.vaultCountAtVerification}</strong></div>
      </div>
      <div className="mainnet-risk-note">
        <AlertTriangle size={18} />
        <p><strong>Unaudited proposal deployment.</strong> No mainnet vault creation, deposits, or user onboarding are authorized.</p>
      </div>
    </section>
  );
}

function BeneficiaryRow({ initials, label, share, phase, color }: { initials: string; label: string; share: string; phase: string; color: string }) {
  return <div className="beneficiary-row"><div className={`avatar avatar-${color}`}>{initials}</div><div className="beneficiary-copy"><strong>{label}</strong><span>Standard beneficiary</span></div><div className="beneficiary-phase"><span className="status-dot" />{phase} active</div><strong className="share-value">{share}</strong></div>;
}

function TimelineItem({ state, title, meta }: { state?: "done" | "current"; title: string; meta: string }) {
  return <li className={state ? `timeline-${state}` : ""}><span className="timeline-marker">{state === "done" ? <BadgeCheck size={15} /> : null}</span><div><strong>{title}</strong><p>{meta}</p></div></li>;
}

function ScheduleRow({ name, primary, fallback, share, terminal }: { name: string; primary: string; fallback: string; share: string; terminal?: boolean }) {
  return <div className="schedule-row" role="row"><span><strong>{name}</strong>{terminal && <em>Terminal last</em>}</span><code>{primary}</code><code>{fallback}</code><strong>{share}</strong></div>;
}

function SecurityRow({ icon: Icon, label, value }: { icon: IconType; label: string; value: string }) {
  return <div className="security-row"><Icon size={17} /><span>{label}</span><strong>{value}</strong></div>;
}

function Permission({ title, items, good }: { title: string; items: string[]; good?: boolean }) {
  return <div className={`permission-card ${good ? "permission-good" : ""}`}><strong>{title}</strong>{items.map((item) => <span key={item}><BadgeCheck size={15} />{item}</span>)}</div>;
}

function ActivityRow({ icon: Icon, title, meta, hash, href }: { icon: IconType; title: string; meta: string; hash: string; href: string }) {
  return <div className="activity-row"><div className="metric-icon"><Icon size={18} /></div><div><strong>{title}</strong><p>{meta}</p></div><code>{hash}</code><a className="icon-button" href={href} target="_blank" rel="noreferrer" aria-label={`Open transaction ${hash}`}><ArrowUpRight size={17} /></a></div>;
}
