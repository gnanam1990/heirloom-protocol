import type { Metadata } from "next";
import { Geist, Geist_Mono } from "next/font/google";
import { Providers } from "./providers";
import "./globals.css";

const baseSans = Geist({ variable: "--font-base-sans", subsets: ["latin"] });
const baseMono = Geist_Mono({ variable: "--font-base-mono", subsets: ["latin"] });

export const metadata: Metadata = {
  title: "Heirloom",
  description: "Non-custodial asset continuity on Base.",
  icons: { icon: "/favicon.svg", shortcut: "/favicon.svg" },
  other: { "base:app_id": "6a809111e4a8a41598e7a375" },
};

export default function RootLayout({ children }: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="en">
      <body className={`${baseSans.variable} ${baseMono.variable}`}>
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
