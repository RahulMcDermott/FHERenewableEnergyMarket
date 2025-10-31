import { useState, useEffect } from 'react'
import { ethers } from 'ethers'
import { createFhevmClient, encrypt } from '@fhevm/sdk'
import EnergyOfferForm from './components/EnergyOfferForm'
import EnergyDemandForm from './components/EnergyDemandForm'
import TradingPeriodInfo from './components/TradingPeriodInfo'
import WalletConnect from './components/WalletConnect'

declare global {
  interface Window {
    ethereum?: any
  }
}

function App() {
  const [provider, setProvider] = useState<ethers.BrowserProvider | null>(null)
  const [signer, setSigner] = useState<ethers.Signer | null>(null)
  const [account, setAccount] = useState<string>('')
  const [fhevmClient, setFhevmClient] = useState<any>(null)
  const [isInitializing, setIsInitializing] = useState(false)
  const [error, setError] = useState<string>('')

  const connectWallet = async () => {
    try {
      setError('')
      if (!window.ethereum) {
        setError('Please install MetaMask to use this application')
        return
      }

      const web3Provider = new ethers.BrowserProvider(window.ethereum)
      const accounts = await web3Provider.send('eth_requestAccounts', [])
      const web3Signer = await web3Provider.getSigner()

      setProvider(web3Provider)
      setSigner(web3Signer)
      setAccount(accounts[0])

      // Initialize FHEVM client
      setIsInitializing(true)
      try {
        const client = await createFhevmClient({
          network: 'sepolia',
          contractAddress: import.meta.env.VITE_CONTRACT_ADDRESS || '0x0000000000000000000000000000000000000000'
        })
        setFhevmClient(client)
      } catch (err) {
        console.error('Failed to initialize FHEVM client:', err)
        setError('Failed to initialize FHEVM client. Please check your network connection.')
      } finally {
        setIsInitializing(false)
      }
    } catch (err: any) {
      setError(err.message || 'Failed to connect wallet')
      console.error(err)
    }
  }

  const disconnectWallet = () => {
    setProvider(null)
    setSigner(null)
    setAccount('')
    setFhevmClient(null)
  }

  useEffect(() => {
    if (window.ethereum) {
      window.ethereum.on('accountsChanged', (accounts: string[]) => {
        if (accounts.length === 0) {
          disconnectWallet()
        } else {
          setAccount(accounts[0])
        }
      })

      window.ethereum.on('chainChanged', () => {
        window.location.reload()
      })
    }

    return () => {
      if (window.ethereum) {
        window.ethereum.removeListener('accountsChanged', () => {})
        window.ethereum.removeListener('chainChanged', () => {})
      }
    }
  }, [])

  return (
    <div className="container">
      <header>
        <h1>🌱 Private Renewable Energy Market</h1>
        <p>Confidential Trading Platform for Clean Energy</p>
        <WalletConnect
          account={account}
          isConnected={!!account}
          onConnect={connectWallet}
          onDisconnect={disconnectWallet}
        />
      </header>

      {error && <div className="error">{error}</div>}

      {isInitializing && (
        <div className="loading">Initializing FHEVM SDK...</div>
      )}

      <main>
        {account && fhevmClient ? (
          <>
            <TradingPeriodInfo provider={provider} />

            <EnergyOfferForm
              signer={signer}
              fhevmClient={fhevmClient}
            />

            <EnergyDemandForm
              signer={signer}
              fhevmClient={fhevmClient}
            />

            <div className="card">
              <h2>📊 SDK Status</h2>
              <div className="stats-section">
                <div className="stat-item">
                  <label>FHEVM Client:</label>
                  <span className="status-badge active">Connected</span>
                </div>
                <div className="stat-item">
                  <label>Network:</label>
                  <span>Sepolia</span>
                </div>
                <div className="stat-item">
                  <label>SDK Version:</label>
                  <span>1.0.0</span>
                </div>
              </div>
            </div>
          </>
        ) : (
          <div className="card">
            <h2>Welcome!</h2>
            <p style={{ marginBottom: '1rem', color: 'var(--text-secondary)' }}>
              Connect your wallet to start trading renewable energy privately using FHEVM encryption.
            </p>
            <p style={{ color: 'var(--text-secondary)' }}>
              This application demonstrates the FHEVM SDK integration with React for confidential energy trading.
            </p>
          </div>
        )}
      </main>
    </div>
  )
}

export default App
