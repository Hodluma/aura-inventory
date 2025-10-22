import React from 'react'

const fallback =
  'data:image/svg+xml;utf8,' +
  encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">' +
      '<rect fill="%23343a40" width="64" height="64" rx="8" />' +
      '<path fill="%23f8f9fa" d="M20 32h24v4H20zm0-10h24v4H20zm0 20h24v4H20z" />' +
    '</svg>'
  )

export default function Hotbar({ hotbar, onBind }) {
  const slots = hotbar.slots || {}
  return (
    <div className="hotbar">
      {Array.from({ length: 5 }).map((_, idx) => {
        const slot = idx + 1
        const item = slots[slot]
        return (
          <div key={slot} className={['hotbar-slot', hotbar.active === slot ? 'active' : ''].join(' ')}>
            <span className="index">{slot}</span>
            {item ? (
              <div className="item">
                <img
                  src={`images/${item.name}.png`}
                  onError={(e) => {
                    e.target.onerror = null
                    e.target.src = fallback
                  }}
                  alt={item.name}
                />
                <span className="amount">{item.amount}</span>
              </div>
            ) : (
              <button onClick={() => onBind(slot)}>Assign</button>
            )}
          </div>
        )
      })}
    </div>
  )
}
