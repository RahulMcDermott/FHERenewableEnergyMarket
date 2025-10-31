import { useState } from 'react'
import { ethers } from 'ethers'
import { encrypt } from '@fhevm/sdk'

interface EnergyDemandFormProps {
  signer: ethers.Signer | null
  fhevmClient: any
}

export default function EnergyDemandForm({ signer, fhevmClient }: EnergyDemandFormProps) {
  const [demandAmount, setDemandAmount] = useState<string>('')
  const [maxPrice, setMaxPrice] = useState<string>('')
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setMessage(null)

    if (!demandAmount || !maxPrice) {
      setMessage({ type: 'error', text: 'Please fill in all fields' })
      return
    }

    try {
      setIsSubmitting(true)

      // Encrypt the values using FHEVM SDK
      const encryptedAmount = await encrypt(fhevmClient, parseInt(demandAmount), { bits: 32 })
      const encryptedMaxPrice = await encrypt(fhevmClient, parseInt(maxPrice), { bits: 32 })

      console.log('Encrypted values:', { encryptedAmount, encryptedMaxPrice })

      // In a real implementation, you would submit to the smart contract here
      // await contract.submitEnergyDemand(encryptedAmount, encryptedMaxPrice, energyType)

      setMessage({
        type: 'success',
        text: `Energy demand encrypted successfully! Amount: ${demandAmount} kWh, Max Price: ${maxPrice} wei`
      })

      // Reset form
      setDemandAmount('')
      setMaxPrice('')
    } catch (err: any) {
      console.error('Error submitting demand:', err)
      setMessage({ type: 'error', text: err.message || 'Failed to submit energy demand' })
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="card">
      <h2>🏠 Energy Consumer</h2>
      <form onSubmit={handleSubmit}>
        <div className="form-grid">
          <div className="form-group">
            <label htmlFor="demandAmount">Required Energy (kWh):</label>
            <input
              type="number"
              id="demandAmount"
              min="1"
              max="4294967295"
              placeholder="e.g., 50"
              value={demandAmount}
              onChange={(e) => setDemandAmount(e.target.value)}
              disabled={isSubmitting}
            />
          </div>
          <div className="form-group">
            <label htmlFor="maxPrice">Max Price per kWh (wei):</label>
            <input
              type="number"
              id="maxPrice"
              min="1"
              max="4294967295"
              placeholder="e.g., 1200000"
              value={maxPrice}
              onChange={(e) => setMaxPrice(e.target.value)}
              disabled={isSubmitting}
            />
            <small style={{ color: '#888', fontSize: '0.8em', marginTop: '4px', display: 'block' }}>
              Maximum: 4,294,967,295 wei
            </small>
          </div>
        </div>

        <button type="submit" className="btn btn-info" disabled={isSubmitting}>
          {isSubmitting ? 'Submitting...' : 'Submit Energy Demand'}
        </button>

        {message && (
          <div className={message.type} style={{ marginTop: '1rem' }}>
            {message.text}
          </div>
        )}
      </form>

      <div className="stats-section">
        <h3>Your Demands</h3>
        <div className="stat-item">
          <label>Active Demands:</label>
          <span>0</span>
        </div>
      </div>
    </div>
  )
}
