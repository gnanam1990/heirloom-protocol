import assert from "node:assert/strict";
import test from "node:test";

async function render() {
  const workerUrl = new URL("../dist/server/index.js", import.meta.url);
  workerUrl.searchParams.set("test", `${process.pid}-${Date.now()}`);
  const { default: worker } = await import(workerUrl.href);
  return worker.fetch(
    new Request("http://localhost/", { headers: { accept: "text/html" } }),
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
  assert.match(html, /Live deployment · source verified/);
  assert.match(html, /Create the first owner vault/);
  assert.match(html, /Connect wallet/);
  assert.match(html, /58 core/);
  assert.match(html, /0x935e5101d7563429BC152889603D3A17f466f4e4/i);
  assert.match(html, /HEIRLOOM_V3_1_R1/);
  assert.match(html, /9 fork/);
  assert.match(html, /16\/16 mutants/);
});
