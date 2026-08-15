import type { Metadata } from "next";
import Link from "next/link";

const title = "Heirloom — One-minute Base demo";
const description =
  "A 60-second walkthrough of Heirloom's funded Base Sepolia continuity-vault prototype.";

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
    type: "video.other",
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
          <p className="page-kicker">Base Sepolia · 60 seconds</p>
          <h1>Permissionless execution without payout authority.</h1>
          <p>
            See the funded vault, destination-locked schedule, owner-only liveness,
            and public Base evidence in one concise walkthrough.
          </p>
        </div>

        <div className="demo-player-frame">
          <video
            controls
            playsInline
            preload="metadata"
            poster="/heirloom-social-card.png"
            aria-label="Heirloom one-minute Base proposal demo"
          >
            <source src="/demo/heirloom-one-minute-demo.mp4" type="video/mp4" />
            <track
              kind="captions"
              src="/demo/heirloom-one-minute-demo.vtt"
              srcLang="en"
              label="English"
              default
            />
            Your browser does not support embedded video. You can download the MP4 below.
          </video>
        </div>

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
          <a
            className="secondary-button"
            href="/demo/heirloom-one-minute-demo.mp4"
            download
          >
            Download MP4
          </a>
        </div>

        <p className="demo-disclaimer">
          Proposal prototype. Heirloom observes owner authorization and time; it does not detect
          death or lost keys. No public mainnet vault use or funding is authorized.
        </p>
      </section>
    </main>
  );
}
