import React from 'react'
import clsx from 'clsx'

const getImage = (name) => `images/${name}.png`
const fallback =
  'data:image/svg+xml;utf8,' +
  encodeURIComponent(
    '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">' +
      '<rect fill="%23343a40" width="64" height="64" rx="8" />' +
      '<path fill="%23f8f9fa" d="M20 32h24v4H20zm0-10h24v4H20zm0 20h24v4H20z" />' +
    '</svg>'
  )

export default function ItemCard({ slot, item, onContext }) {
  const src = item ? getImage(item.name) : null
  const handleContext = (e) => {
    e.preventDefault()
    if (item) {
      onContext(e, slot, item)
    }
  }

  return (
    <div
      className={clsx('item-card', { empty: !item })}
      draggable={!!item}
      data-slot={slot}
      onContextMenu={handleContext}
    >
      {item ? (
        <>
          <img
            src={src}
            onError={(ev) => {
              ev.target.onerror = null
              ev.target.src = fallback
            }}
            alt={item.name}
          />
          <div className="item-info">
            <span className="label">{item.label || item.name}</span>
            <span className="amount">x{item.amount}</span>
            {item.metadata?.durability !== undefined && (
              <div className="durability">
                <div style={{ width: `${Math.max(0, item.metadata.durability)}%` }} />
              </div>
            )}
          </div>
        </>
      ) : (
        <span className="empty-label">{slot}</span>
      )}
    </div>
  )
}
