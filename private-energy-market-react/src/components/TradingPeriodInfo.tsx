import { useState, useEffect } from 'react'
import { ethers } from 'ethers'

interface TradingPeriodInfoProps {
  provider: ethers.BrowserProvider | null
}

export default function TradingPeriodInfo({ provider }: TradingPeriodInfoProps) {
  const [currentPeriod, setCurrentPeriod] = useState<number>(0)
  const [isActive, setIsActive] = useState<boolean>(false)

  useEffect(() => {
    // In a real implementation, this would fetch from the smart contract
    // For now, we'll show mock data
    setCurrentPeriod(1)
    setIsActive(true)
  }, [provider])

  return (
    <div className="card">
      <h2>📅 Current Trading Period</h2>
      <div className="stats-section" style={{ marginTop: '1rem', paddingTop: 0, borderTop: 'none' }}>
        <div className="stat-item">
          <label>Period:</label>
          <span>#{currentPeriod}</span>
        </div>
        <div className="stat-item">
          <label>Status:</label>
          <span className={`status-badge ${isActive ? 'active' : 'inactive'}`}>
            {isActive ? 'Active' : 'Inactive'}
          </span>
        </div>
        <div className="stat-item">
          <label>Time Remaining:</label>
          <span>23:45:12</span>
        </div>
      </div>
    </div>
  )
}
