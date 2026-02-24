import { Buffer } from "buffer";
(globalThis as unknown as Record<string, unknown>).Buffer = Buffer;

import { StrictMode, useState, useEffect } from "react";
import { createRoot } from "react-dom/client";
import { LogLevel, WalletProvider } from "@txnlab/use-wallet-react";
import { WalletUIProvider, type Theme } from "@txnlab/use-wallet-ui-react";
import "@txnlab/use-wallet-ui-react/dist/style.css";
import { WalletManager, WalletId } from "@txnlab/use-wallet-react";
import "./index.css";
import App from "./App.tsx";

const walletManager = new WalletManager({
  options: {
    debug: true,
    logLevel: LogLevel.DEBUG,
    resetNetwork: true,
  },
  wallets: [
    WalletId.METAMASK,
    // WalletId.RAINBOW,
    WalletId.LUTE,
    WalletId.KMD,
  ],
  defaultNetwork: "localnet",
});

function Root() {
  const [theme, setTheme] = useState<Theme>(() => {
    const stored = localStorage.getItem("app-theme");
    if (stored === "light" || stored === "dark") return stored;
    return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
  });

  useEffect(() => {
    localStorage.setItem("app-theme", theme);
    document.documentElement.style.colorScheme = theme;
    document.documentElement.style.color = theme === "dark" ? "rgba(255, 255, 255, 0.87)" : "#213547";
    document.documentElement.style.backgroundColor = theme === "dark" ? "#242424" : "#ffffff";
  }, [theme]);

  return (
    <WalletProvider manager={walletManager}>
      <WalletUIProvider theme={theme}>
        <App theme={theme} setTheme={setTheme} />
      </WalletUIProvider>
    </WalletProvider>
  );
}

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <Root />
  </StrictMode>,
);
