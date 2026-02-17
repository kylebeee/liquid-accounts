import { Buffer } from "buffer";
globalThis.Buffer = Buffer;

import { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import { LogLevel, WalletProvider } from "@txnlab/use-wallet-react";
import { WalletUIProvider } from "@txnlab/use-wallet-ui-react";
import "@txnlab/use-wallet-ui-react/dist/style.css";
import { WalletManager, WalletId } from "@txnlab/use-wallet-react";
import "./index.css";
import App from "./App.tsx";

const walletManager = new WalletManager({
  options: {
    debug: true,
    logLevel: LogLevel.DEBUG
  },
  wallets: [
    WalletId.METAMASK,
    // WalletId.RAINBOW,
    WalletId.LUTE,
    WalletId.KMD,
  ],
  defaultNetwork: "localnet",
});

createRoot(document.getElementById("root")!).render(
  <StrictMode>
    <WalletProvider manager={walletManager}>
      <WalletUIProvider>
        <App />
      </WalletUIProvider>
    </WalletProvider>
  </StrictMode>,
);
