import type { Metadata } from "next";
import { Dashboard } from "./components/Dashboard";

const title = "Heirloom — Asset continuity on Base";
const description =
  "A non-custodial continuity vault with owner-only liveness and destination-locked payouts.";

const canonical = "https://heirloom-base-v31.gnanasekaran-sekaree.chatgpt.site";
const socialImage = `${canonical}/heirloom-social-card.png`;

export const metadata: Metadata = {
  title,
  description,
  alternates: { canonical },
  openGraph: {
    title,
    description: "Owner-only liveness. Destination-locked continuity.",
    url: canonical,
    siteName: "Heirloom",
    type: "website",
    images: [{ url: socialImage, width: 1672, height: 941, alt: "Heirloom on Base" }],
  },
  twitter: {
    card: "summary_large_image",
    title,
    description: "Owner-only liveness. Destination-locked continuity.",
    images: [socialImage],
  },
};

export default function Home() {
  return <Dashboard />;
}
