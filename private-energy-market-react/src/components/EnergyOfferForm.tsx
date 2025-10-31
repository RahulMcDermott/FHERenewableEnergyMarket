import { useState } from 'react'
import { ethers } from 'ethers'
import { encrypt } from '@fhevm/sdk'

interface EnergyOfferFormProps {
  signer: ethers.Signer | null
  fhevmClient: any
}

export default function EnergyOfferForm({ signer, fhevmClient }: EnergyOfferFormProps) {
  const [energyAmount, setEnergyAmount] = useState<string>('')
  const [pricePerKwh, setPricePerKwh] = useState<string>('')
  const [energyType, setEnergyType] = useState<string>('1')
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [message, setMessage] = useState<{ type: 'success' | 'error'; text: string } | null>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setMessage(null)

    if (!energyAmount || !pricePerKwh) {
      setMessage({ type: 'error', text: 'Please fill in all fields' })
      return
    }

    try {
      setIsSubmitting(true)

      // Encrypt the values using FHEVM SDK
      const encryptedAmount = await encrypt(fhevmClient, parseInt(energyAmount), { bits: 32 })
      const encryptedPrice = await encrypt(fhevmClient, parseInt(pricePerKwh), { bits: 32 })

      console.log('Encrypted values:', { encryptedAmount, encryptedPrice })

      // In a real implementation, you would submit to the smart contract here
      // await contract.submitEnergyOffer(encryptedAmount, encryptedPrice, energyType)

      setMessage({
        type: 'success',
        text: `Energy offer encrypted successfully! Amount: ${energyAmount} kWh, Price: ${pricePerKwh} wei`
      })

      // Reset form
      setEnergyAmount('')
      setPricePerKwh('')
    } catch (err: any) {
      console.error('Error submitting offer:', err)
      setMessage({ type: 'error', text: err.message || 'Failed to submit energy offer' })
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="card">
      <h2>⚡ Energy Producer</h2>
      <form onSubmit={handleSubmit}>
        <div className="form-grid">
          <div className="form-group">
            <label htmlFor="energyAmount">Energy Amount (kWh):</label>
            <input
              type="number"
              id="energyAmount"
              min="1"
              max="4294967295"
              placeholder="e.g., 100"
              value={energyAmount}
              onChange={(e) => setEnergyAmount(e.target.value)}
              disabled={isSubmitting}
            />
          </div>
          <div className="form-group">
            <label htmlFor="pricePerKwh">Price per kWh (wei):</label>
            <input
              type="number"
              id="pricePerKwh"
              min="1"
              max="4294967295"
              placeholder="e.g., 1000000"
              value={pricePerKwh}
              onChange={(e) => setPricePerKwh(e.target.value)}
              disabled={isSubmitting}
            />
            <small style={{ color: '#888', fontSize: '0.8em', marginTop: '4px', display: 'block' }}>
              Maximum: 4,294,967,295 wei
            </small>
          </div>
          <div className="form-group">
            <label htmlFor="energyType">Energy Type:</label>
            <select
              id="energyType"
              value={energyType}
              onChange={(e) => setEnergyType(e.target.value)}
              disabled={isSubmitting}
            >
              <option value="1">🌞 Solar</option>
              <option value="2">💨 Wind</option>
              <option value="3">💧 Hydro</option>
              <option value="4">🌋 Geothermal</option>
            </select>
          </div>
        </div>

        <button type="submit" className="btn btn-success" disabled={isSubmitting}>
          {isSubmitting ? 'Submitting...' : 'Submit Energy Offer'}
        </button>

        {message && (
          <div className={message.type} style={{ marginTop: '1rem' }}>
            {message.text}
          </div>
        )}
      </form>

      <div className="stats-section">
        <h3>Your Offers</h3>
        <div className="stat-item">
          <label>Active Offers:</label>
          <span>0</span>
        </div>
      </div>
    </div>
  )
}
