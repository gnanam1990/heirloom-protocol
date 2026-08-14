"use client";

import {
  Activity,
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
  RefreshCw,
  ShieldCheck,
  Users,
  Vault,
  WalletCards,
  X,
} from "lucide-react";
import { useState } from "react";
import { useAccount, useConnect, useDisconnect, useSwitchChain } from "wagmi";
import { baseSepolia } from "wagmi/chains";

type View = "overview" | "beneficiaries" | "security" | "activity";
type IconType = typeof Vault;

const navigation = [
  { id: "overview" as const, label: "Overview", icon: LayoutDashboard },
  { id: "beneficiaries" as const, label: "Beneficiaries", icon: Users },
  { id: "security" as const, label: "Security", icon: ShieldCheck },
  { id: "activity" as const, label: "Activity", icon: Activity },
];

const beneficiaries = [
  { initials: "AK", label: "Anika K.", share: "30%", phase: "Primary", color: "blue" },
  { initials: "RM", label: "Ravi M.", share: "20%", phase: "Primary", color: "ink" },
];

function shortAddress(address?: string) {
  return address ? `${address.slice(0, 6)}…${address.slice(-4)}` : "Not connected";
}

export function Dashboard() {
  const [view, setView] = useState<View>("overview");
  const [mobileOpen, setMobileOpen] = useState(false);
  const { address, chainId, isConnected } = useAccount();
  const { connectors, connect, isPending, error } = useConnect();
  const { disconnect } = useDisconnect();
  const { switchChain } = useSwitchChain();
  const baseConnector = connectors.find((connector) => connector.id === "baseAccount");

  function connectBase() {
    if (baseConnector) connect({ connector: baseConnector, chainId: baseSepolia.id });
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
            <span>Protocol v3.1</span>
            <BadgeCheck size={15} />
          </div>
        </div>
        <button className="help-link">
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
            <button className="icon-button" aria-label="Notifications">
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
                onClick={connectBase}
                disabled={!baseConnector || isPending}
              >
                <Fingerprint size={17} />
                {isPending ? "Opening Base…" : "Connect with Base"}
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
              <span className="preview-badge">Interface preview · no funds connected</span>
              <button className="secondary-button">
                <FileCheck2 size={17} /> Public proof
              </button>
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

          {view === "overview" && <Overview />}
          {view === "beneficiaries" && <Beneficiaries />}
          {view === "security" && <Security />}
          {view === "activity" && <ActivityView />}
        </div>
      </section>
    </main>
  );
}

function Overview() {
  return (
    <>
      <section className="status-hero">
        <div className="status-copy">
          <div className="status-title-row">
            <span className="healthy-ring">
              <HeartPulse size={24} />
            </span>
            <span>
              <span className="eyebrow">Vault status</span>
              <strong>Active and healthy</strong>
            </span>
          </div>
          <p>
            Only a fresh action signed by the current owner can extend this vault&apos;s liveness.
          </p>
          <button
            className="heartbeat-button"
            disabled
            title="Connect the owner account to send a heartbeat"
          >
            <RefreshCw size={17} /> Send heartbeat
          </button>
        </div>
        <div className="deadline-panel">
          <span className="eyebrow">Next claim boundary</span>
          <strong>84 days</strong>
          <span>November 6, 2026 · 14:32 IST</span>
          <div className="progress-track">
            <span style={{ width: "7%" }} />
          </div>
          <div className="progress-labels">
            <span>Last owner action</span>
            <span>90-day threshold</span>
          </div>
        </div>
      </section>

      <section className="metric-grid">
        <Metric icon={WalletCards} label="Vault balance" value="$250,000.00" meta="250,000 USDC" />
        <Metric icon={Users} label="Destinations" value="3 configured" meta="2 standard · 1 terminal" />
        <Metric icon={ShieldCheck} label="Recovery quorum" value="2 of 3" meta="No request pending" />
        <Metric icon={Clock3} label="Challenge window" value="7 days" meta="Begins after a valid claim" />
      </section>

      <section className="dashboard-grid">
        <div className="panel beneficiaries-panel">
          <PanelHeader
            title="Destination schedule"
            subtitle="Executor cannot choose where funds go."
            action="View all"
          />
          <div className="beneficiary-list">
            {beneficiaries.map((item) => (
              <BeneficiaryRow key={item.initials} {...item} />
            ))}
            <div className="terminal-row">
              <div className="avatar terminal-avatar">
                <LockKeyhole size={17} />
              </div>
              <div className="beneficiary-copy">
                <strong>Continuity reserve</strong>
                <span>Terminal · executes last</span>
              </div>
              <div className="beneficiary-phase terminal-phase">Terminal locked</div>
              <strong className="share-value">50%</strong>
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
            <TimelineItem state="done" title="Vault configured" meta="Version HEIRLOOM_V3_1" />
            <TimelineItem state="current" title="Owner liveness" meta="84 days until claim request" />
            <TimelineItem title="Challenge" meta="7-day owner response window" />
            <TimelineItem title="Distribution" meta="Primary → fallback → rollover" />
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
          <strong>30 tests · 10,000 fuzz runs · 4 stateful invariants</strong>
        </div>
        <div className="proof-meta">
          <span>Runtime</span>
          <strong>23,602 B</strong>
        </div>
        <button className="text-button">
          Review proof <ArrowUpRight size={16} />
        </button>
      </section>
    </>
  );
}

function Beneficiaries() {
  return (
    <section className="panel detail-panel">
      <PanelHeader
        title="Destination-locked schedule"
        subtitle="Shares are calculated once from the distribution snapshot."
        action="Propose change"
      />
      <div className="schedule-table" role="table" aria-label="Beneficiary schedule">
        <div className="schedule-head" role="row">
          <span>Beneficiary</span><span>Primary phase</span><span>Fallback phase</span><span>Share</span>
        </div>
        <ScheduleRow name="Anika K." primary="0x71C4…A290" fallback="0x4DA3…312A" share="30%" />
        <ScheduleRow name="Ravi M." primary="0x03F2…8E11" fallback="0x882D…0D64" share="20%" />
        <ScheduleRow name="Continuity reserve" primary="0x62A1…EE90" fallback="0x901F…20C8" share="50%" terminal />
      </div>
      <div className="info-callout">
        <Clock3 size={19} />
        <div><strong>Time determines the route</strong><p>Primary is valid first, fallback becomes valid after its deadline, then unpaid standard shares roll into the terminal amount.</p></div>
      </div>
    </section>
  );
}

function Security() {
  return (
    <div className="security-grid">
      <section className="panel detail-panel">
        <PanelHeader title="Guardian recovery" subtitle="Guardians may activate only the owner-precommitted address." />
        <div className="quorum-visual"><div className="quorum-number">2<span>/3</span></div><div><strong>Approval threshold</strong><p>2-day activation delay · 30-day execution window</p></div></div>
        <div className="guardian-stack"><span>GA</span><span>GB</span><span>GC</span><p>3 independent guardians</p></div>
      </section>
      <section className="panel detail-panel">
        <PanelHeader title="Verifiable identity" subtitle="Publicly inspectable for the life of every vault." />
        <SecurityRow icon={Network} label="Network" value="Base Sepolia · 84532" />
        <SecurityRow icon={Vault} label="Version" value="HEIRLOOM_V3_1" />
        <SecurityRow icon={FileCheck2} label="Vault runtime" value="23,602 bytes" />
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

function ActivityView() {
  return (
    <section className="panel detail-panel">
      <PanelHeader title="Protocol activity" subtitle="Every material transition is independently verifiable on Base." action="Open explorer" />
      <div className="activity-list">
        <ActivityRow icon={HeartPulse} title="Owner deposit and liveness" meta="Aug 8, 2026 · 14:32" hash="0x72be…903d" />
        <ActivityRow icon={FileCheck2} title="Vault created" meta="Aug 8, 2026 · 14:29" hash="0x108f…11a9" />
        <ActivityRow icon={BadgeCheck} title="Configuration committed" meta="Aug 8, 2026 · 14:29" hash="0xa4c1…e20b" />
      </div>
    </section>
  );
}

function Metric({ icon: Icon, label, value, meta }: { icon: IconType; label: string; value: string; meta: string }) {
  return <div className="metric-card"><div className="metric-icon"><Icon size={19} /></div><span>{label}</span><strong>{value}</strong><p>{meta}</p></div>;
}

function PanelHeader({ title, subtitle, action }: { title: string; subtitle: string; action?: string }) {
  return <div className="panel-header"><div><h2>{title}</h2><p>{subtitle}</p></div>{action && <button className="text-button">{action} <ChevronRight size={15} /></button>}</div>;
}

function BeneficiaryRow({ initials, label, share, phase, color }: (typeof beneficiaries)[number]) {
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

function ActivityRow({ icon: Icon, title, meta, hash }: { icon: IconType; title: string; meta: string; hash: string }) {
  return <div className="activity-row"><div className="metric-icon"><Icon size={18} /></div><div><strong>{title}</strong><p>{meta}</p></div><code>{hash}</code><button className="icon-button" aria-label={`Open transaction ${hash}`}><ArrowUpRight size={17} /></button></div>;
}
