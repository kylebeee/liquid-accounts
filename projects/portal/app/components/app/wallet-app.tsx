import { useEffect, useRef, useState } from 'react'
import { useWallet } from '@txnlab/use-wallet-react'
import { WalletButton } from '@txnlab/use-wallet-ui-react'
import { WalletProviders } from './wallet-providers'
import { WalletDashboard } from './wallet-dashboard'

/** Synchronously check if wagmi has a stored session in localStorage. */
function hasWagmiStoredSession(): boolean {
  try {
    return !!localStorage.getItem('wagmi.recentConnectorId')
  } catch {
    return false
  }
}

/**
 * Listens to wallet state and calls `onResolved` once we know the final
 * connection status (connected or definitively disconnected).
 * Renders nothing — lives inside WalletProviders only to access the hook.
 */
function WalletResolver({ hadSession, onResolved }: { hadSession: boolean; onResolved: () => void }) {
  const { activeAddress, isReady } = useWallet()
  const firedRef = useRef(false)

  useEffect(() => {
    if (firedRef.current) return
    if (activeAddress) {
      firedRef.current = true
      onResolved()
    } else if (isReady && !hadSession) {
      firedRef.current = true
      onResolved()
    }
  }, [activeAddress, isReady, hadSession, onResolved])

  return null
}

function WalletAppContent() {
  const { activeAddress } = useWallet()

  return (
    <>
      {!activeAddress && (
        <div data-wallet-ui className="flex justify-center mb-8">
          <WalletButton size="lg" />
        </div>
      )}
      <WalletDashboard />
    </>
  )
}

export default function WalletApp() {
  const hadSession = useRef(hasWagmiStoredSession())
  const [resolved, setResolved] = useState(false)

  return (
    <WalletProviders>
      {!resolved ? (
        <>
          <div className="flex justify-center py-12">
            <div className="h-10 w-10 animate-spin rounded-full border-4 border-muted border-t-primary" />
          </div>
          <WalletResolver hadSession={hadSession.current} onResolved={() => setResolved(true)} />
        </>
      ) : (
        <WalletAppContent />
      )}
    </WalletProviders>
  )
}
