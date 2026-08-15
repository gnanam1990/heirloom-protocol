import fs from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const root = path.resolve(process.cwd(), "../..");
const sourceDir = path.join(root, "outputs/demo-video");
const targetDir = path.join(sourceDir, "rendered");

const segments = [
  {
    source: "01-overview.png",
    file: "01-intro.png",
    mode: "hero",
    eyebrow: "HEIRLOOM",
    title: "Asset continuity on Base",
    subtitle: "Permissionless execution. Destination-locked payout.",
    detail: "BASE SEPOLIA · PROPOSAL PROTOTYPE",
  },
  {
    source: "01-overview.png",
    file: "02-owner-control.png",
    title: "Owner control stays active",
    subtitle: "Wallet or passkey-backed Base Account · no seed phrase shared with beneficiaries",
  },
  {
    source: "06-vault-tokens.png",
    file: "03-funded-vault.png",
    title: "20 USDC funded test vault",
    subtitle: "Verified on Base Sepolia · public contract state · zero custody by Heirloom",
  },
  {
    source: "04-activity.png",
    file: "04-liveness.png",
    title: "Owner-only liveness",
    subtitle: "90-day inactivity · 7-day challenge · irreversible snapshot only after the challenge",
  },
  {
    source: "02-beneficiaries.png",
    file: "05-destination-lock.png",
    title: "Executor cannot aim the payout",
    subtitle: "The contract derives recipient, amount, and exactly one valid time phase",
  },
  {
    source: "03-security.png",
    file: "06-evidence.png",
    title: "Evidence, not a trust claim",
    subtitle: "73 contract tests · 5 stateful groups · 16/16 production mutants killed",
  },
  {
    source: "05-blockscout.png",
    file: "07-outro.png",
    mode: "outro",
    eyebrow: "HEIRLOOM",
    title: "Built for Base",
    subtitle: "Permissionless execution without payout authority",
    detail: "PROPOSAL PROTOTYPE · NOT A PUBLIC MAINNET PRODUCT",
  },
];

const escapeXml = (value) =>
  value.replaceAll("&", "&amp;").replaceAll("<", "&lt;").replaceAll(">", "&gt;");

function normalOverlay(segment) {
  return Buffer.from(`
    <svg width="1920" height="1080" xmlns="http://www.w3.org/2000/svg">
      <rect x="0" y="894" width="1920" height="186" fill="#020817" fill-opacity="0.94"/>
      <rect x="0" y="894" width="1920" height="5" fill="#0052ff"/>
      <text x="120" y="960" fill="#ffffff" font-family="-apple-system, BlinkMacSystemFont, Arial, sans-serif" font-size="42" font-weight="700">${escapeXml(segment.title)}</text>
      <text x="120" y="1015" fill="#b8c5e3" font-family="-apple-system, BlinkMacSystemFont, Arial, sans-serif" font-size="27">${escapeXml(segment.subtitle)}</text>
    </svg>
  `);
}

function heroOverlay(segment, outro = false) {
  const anchor = outro ? "middle" : "start";
  const x = outro ? 960 : 160;
  const titleY = outro ? 520 : 300;
  return Buffer.from(`
    <svg width="1920" height="1080" xmlns="http://www.w3.org/2000/svg">
      <rect width="1920" height="1080" fill="#020817" fill-opacity="${outro ? "0.74" : "0.58"}"/>
      ${outro ? "" : '<rect x="118" y="150" width="10" height="270" fill="#0052ff"/>'}
      <text x="${x}" y="${titleY - 90}" text-anchor="${anchor}" fill="#7aa2ff" font-family="-apple-system, BlinkMacSystemFont, Arial, sans-serif" font-size="34" font-weight="700" letter-spacing="5">${escapeXml(segment.eyebrow)}</text>
      <text x="${x}" y="${titleY}" text-anchor="${anchor}" fill="#ffffff" font-family="-apple-system, BlinkMacSystemFont, Arial, sans-serif" font-size="76" font-weight="800">${escapeXml(segment.title)}</text>
      <text x="${x}" y="${titleY + 85}" text-anchor="${anchor}" fill="#d5ddf5" font-family="-apple-system, BlinkMacSystemFont, Arial, sans-serif" font-size="34">${escapeXml(segment.subtitle)}</text>
      <text x="${x}" y="${titleY + 150}" text-anchor="${anchor}" fill="#9aabcf" font-family="Menlo, monospace" font-size="23" letter-spacing="1">${escapeXml(segment.detail)}</text>
    </svg>
  `);
}

await fs.mkdir(targetDir, { recursive: true });

for (const segment of segments) {
  const background = await sharp(path.join(sourceDir, segment.source))
    .resize(1920, 1080, { fit: "contain", background: "#020817" })
    .png()
    .toBuffer();
  const overlay = segment.mode === "hero"
    ? heroOverlay(segment)
    : segment.mode === "outro"
      ? heroOverlay(segment, true)
      : normalOverlay(segment);
  await sharp(background)
    .composite([{ input: overlay }])
    .png()
    .toFile(path.join(targetDir, segment.file));
}

console.log(`Rendered ${segments.length} demo frames to ${targetDir}`);
