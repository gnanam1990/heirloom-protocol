import { createConfig, http } from "wagmi";
import { base, baseSepolia } from "wagmi/chains";
import { baseAccount, injected } from "wagmi/connectors";

export const config = createConfig({
  chains: [baseSepolia, base],
  connectors: [baseAccount({ appName: "Heirloom" }), injected({ shimDisconnect: true })],
  transports: {
    [baseSepolia.id]: http("https://sepolia.base.org"),
    [base.id]: http("https://mainnet.base.org"),
  },
  ssr: true,
});

declare module "wagmi" {
  interface Register {
    config: typeof config;
  }
}
