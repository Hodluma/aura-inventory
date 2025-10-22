import React from 'react'

export default function Tooltip({ item }) {
  if (!item) return null
  return (
    <div className="tooltip">
      <h3>{item.label || item.name}</h3>
      <p>{item.description}</p>
      <ul>
        {item.metadata?.durability !== undefined && <li>Durability: {item.metadata.durability}%</li>}
        {item.metadata?.caliber && <li>Caliber: {item.metadata.caliber}</li>}
        {item.metadata?.notes && <li>Notes: {item.metadata.notes}</li>}
      </ul>
    </div>
  )
}
