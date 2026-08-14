import type { Metadata } from "next";
import { Dashboard } from "./components/Dashboard";

export const metadata: Metadata = {
  title: "Heirloom — Asset continuity on Base",
  description:
    "A non-custodial continuity vault with owner-only liveness and destination-locked payouts.",
  other: { "codex-preview": "development" },
  openGraph: {
    title: "Heirloom — Asset continuity on Base",
    description: "Owner-only liveness. Destination-locked continuity.",
    images: [{ url: "/heirloom-social-card.png", width: 1672, height: 941 }],
  },
};

export default function Home() {
  return <Dashboard />;
}
