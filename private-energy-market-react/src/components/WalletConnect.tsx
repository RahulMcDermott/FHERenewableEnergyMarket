interface WalletConnectProps {
  account: string
  isConnected: boolean
  onConnect: () => void
  onDisconnect: () => void
}

export default function WalletConnect({
  account,
  isConnected,
  onConnect,
  onDisconnect
}: WalletConnectProps) {
  return (
    <div className="connection-status">
      {!isConnected ? (
        <button className="btn btn-primary" onClick={onConnect}>
          Connect Wallet
        </button>
      ) : (
        <div className="wallet-info">
          <span>
            {account.slice(0, 6)}...{account.slice(-4)}
          </span>
          <button
            className="btn btn-secondary"
            style={{ padding: '0.5rem 1rem', fontSize: '0.875rem' }}
            onClick={onDisconnect}
          >
            Disconnect
          </button>
        </div>
      )}
    </div>
  )
}
