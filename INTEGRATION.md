# Early Adopter Integration Guide

In case you want to experiment with liquid-evm-accounts in your frontend:

## 1. Install packages

Use npm aliases to install the experimental `@d13co` builds under the `@txnlab` package names. This way your imports stay as `@txnlab/use-wallet-react` — no find-and-replace needed.

```bash
pnpm add @txnlab/use-wallet@npm:@d13co/use-wallet @txnlab/use-wallet-react@npm:@d13co/use-wallet-react @txnlab/use-wallet-ui-react liquid-accounts-evm @metamask/sdk
```

Note: This uses use-wallet v4. Migration should be straightforward/painless if you are on v2 or v3:

- https://txnlab.gitbook.io/use-wallet/v3/guides/migrating-from-v2.x
- https://txnlab.gitbook.io/use-wallet/guides/migrating-from-v3.x

## 2. Usage

```tsx
import {
  NetworkId, WalletId, WalletManager, WalletProvider,
} from '@txnlab/use-wallet-react'
import {
  WalletUIProvider, WalletButton,
} from '@txnlab/use-wallet-ui-react'

// Add metamask to your use-wallet config

const walletManager = new WalletManager({
  wallets: [
    WalletId.PERA,
    WalletId.DEFLY,
    WalletId.EXODUS,
    WalletId.METAMASK,
  ],
  defaultNetwork: NetworkId.MAINNET,
})

// Add ui provider & place <WalletButton /> as your login / connected button somewhere

function App() {
  return (
    <WalletProvider manager={walletManager}>
      <WalletUIProvider theme="system">
        {/* your app */}
          {/* somewhere in header */}
            <WalletButton />
            {/* ... */}
      </WalletUIProvider>
    </WalletProvider>
  )
}
```

`WalletUIProvider` must be nested inside `WalletProvider`. It handles:

- Transaction review dialogs (before/after sign)
- NFD profile prefetching for connected accounts
- Theme injection (`'light'` | `'dark'` | `'system'`)
- Optional `queryClient` prop if you already have a `@tanstack/react-query` provider

## 3. Opt in EVM account to assets

After connecting your EVM account, you can opt it in to assets via:

{WalletButton} -> ⚡ Manage -> Opt in

