import type { Metadata } from "next";
import Link from "next/link";
import { AnimatedDemo } from "./AnimatedDemo";

const title = "Heirloom — One-minute Base demo";
const description =
  "An interactive 60-second walkthrough of Heirloom's funded Base Sepolia continuity-vault prototype.";

export const metadata: Metadata = {
  title,
  description,
  alternates: {
    canonical: "https://heirloom-protocol-production.up.railway.app/demo",
  },
  openGraph: {
    title,
    description,
    url: "https://heirloom-protocol-production.up.railway.app/demo",
    siteName: "Heirloom",
    type: "website",
    images: [],
  },
  twitter: {
    card: "summary",
    title,
    description,
    images: [],
  },
};

export default function DemoPage() {
  return (
    <main className="demo-page">
      <header className="demo-header">
        <Link className="demo-brand" href="/">
          <span className="base-mark" aria-hidden="true" />
          <span>heirloom</span>
        </Link>
        <Link className="secondary-button" href="/">
          Back to product
        </Link>
      </header>

      <section className="demo-shell">
        <div className="demo-copy">
          <p className="page-kicker">Base Sepolia · interactive 60 seconds</p>
          <h1>Permissionless execution without payout authority.</h1>
          <p>
            See the funded vault, destination-locked schedule, owner-only liveness,
            and public Base evidence in one concise walkthrough.
          </p>
        </div>

        <AnimatedDemo />

        <div className="demo-proof-row">
          <div>
            <span>Network</span>
            <strong>Base Sepolia · 84532</strong>
          </div>
          <div>
            <span>Test vault</span>
            <strong>20 USDC funded</strong>
          </div>
          <div>
            <span>Evidence</span>
            <strong>73 tests · 16/16 mutants</strong>
          </div>
        </div>

        <p className="demo-disclaimer">
          Proposal prototype. Heirloom observes owner authorization and time; it does not detect
          death or lost keys. No public mainnet vault use or funding is authorized.
        </p>
      </section>
    </main>
  );
}
