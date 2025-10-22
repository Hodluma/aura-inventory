import React from 'react'

export default function GroundDrops({ drops, onPickup }) {
  if (!drops || drops.length === 0) return null
  return (
    <div className="ground-drops">
      <h3>Nearby Drops</h3>
      <ul>
        {drops.map((drop) => (
          <li key={drop.id}>
            {drop.item.name} x{drop.item.amount}
            <button onClick={() => onPickup(drop.id)}>Pickup</button>
          </li>
        ))}
      </ul>
    </div>
  )
}
