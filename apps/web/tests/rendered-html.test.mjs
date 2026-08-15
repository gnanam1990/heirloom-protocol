import assert from "node:assert/strict";
import test from "node:test";

async function render(path = "/") {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);
  return worker.fetch(
    new Request(`http://localhost${path}`, { headers: { accept: "text/html" } }),
    { ASSETS: { fetch: async () => new Response("Not found", { status: 404 }) } },
    { waitUntil() {}, passThroughOnException() {} },
  );
}

test("server-renders the Heirloom product shell", async () => {
  const response = await render();
  assert.equal(response.status, 200);
  assert.match(response.headers.get("content-type") ?? "", /^text\/html\b/i);
  const html = await response.text();
  assert.match(html, /<title>Heirloom — Asset continuity on Base<\/title>/i);
  assert.match(html, /Factory ready/);
  assert.match(html, /Vault balance/);
  assert.match(html, /Liveness epoch/);
  assert.match(html, /Destination schedule/);
  assert.match(html, /Lifecycle timeline/);
  assert.match(html, /Testnet live · mainnet proof verified/);
  assert.match(html, /Factory live\. Product writes remain locked\./);
  assert.match(html, /Unaudited proposal deployment\./);
  assert.match(html, /No mainnet vault creation, deposits, or user onboarding are authorized\./);
  assert.match(html, /Create the first owner vault/);
  assert.match(html, /Connect wallet/);
  assert.match(html, /href="\/demo"/i);
  assert.match(html, /60-sec demo/);
  assert.match(html, /73 core/);
  assert.match(html, /0x935e5101d7563429BC152889603D3A17f466f4e4/i);
  assert.match(html, /HEIRLOOM_V3_1_R1/);
  assert.match(html, /9 fork/);
  assert.match(html, /16\/16 mutants/);
  assert.match(html, /0x524A95082dAD59fd8bf18FA27F89E3f55202eEcf/i);
  assert.match(html, /0xf04990ce21cbe3a3a78d3ae347c1250f10d23cccd6437aa5bdba090ddcce9270/i);
  assert.match(html, /property="og:image" content="https:\/\/heirloom-protocol-production\.up\.railway\.app\/heirloom-social-card\.png"/i);
  assert.match(html, /name="twitter:card" content="summary_large_image"/i);
  assert.doesNotMatch(html, /codex-preview/i);
});

test("server-renders the public one-minute demo route", async () => {
  const response = await render("/demo");
  assert.equal(response.status, 200);
  const html = await response.text();
  assert.match(html, /<title>Heirloom — One-minute Base demo<\/title>/i);
  assert.match(html, /Permissionless execution without payout authority\./);
  assert.match(html, /Interactive Heirloom product walkthrough/i);
  assert.match(html, /Play demo/);
  assert.match(html, /Text only/);
  assert.match(html, /Destination lock/);
  assert.doesNotMatch(html, /<audio/i);
  assert.doesNotMatch(html, /<video/i);
  assert.match(html, /20 USDC funded/);
  assert.match(html, /Proposal prototype/);
  assert.match(html, /property="og:title" content="Heirloom — One-minute Base demo"/i);
  assert.match(html, /name="twitter:description" content="An interactive 60-second walkthrough/i);
  assert.doesNotMatch(html, /property="og:image"/i);
});
