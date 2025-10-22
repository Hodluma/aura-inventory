import React, { useMemo } from 'react'
import ItemCard from './ItemCard'

export default function InventoryGrid({ title, inventory, onMove, onContext, inventoryKey, containerId }) {
  const slots = useMemo(() => {
    const grid = []
    for (let i = 1; i <= inventory.slots; i += 1) {
      grid.push({ slot: i, item: inventory.items[i] })
    }
    return grid
  }, [inventory])

  const handleDrop = (e, targetSlot) => {
    e.preventDefault()
    const fromSlot = Number(e.dataTransfer.getData('slot'))
    const fromInventory = e.dataTransfer.getData('inventory') || 'player'
    const dragContainer = e.dataTransfer.getData('containerId')
    if (!fromSlot) return
    if (fromSlot === targetSlot) return
    onMove({
      fromInventory,
      toInventory: inventoryKey,
      containerId: containerId || dragContainer,
      fromSlot,
      toSlot: targetSlot
    })
  }

  const allowDrop = (e) => e.preventDefault()

  return (
    <div className="inventory-grid" data-key={inventoryKey}>
      <header>
        <h2>{title}</h2>
        <span>
          {inventory.weight?.toFixed?.(2) || 0} / {inventory.weightLimit || inventory.slots}
        </span>
      </header>
      <div className="grid">
        {slots.map(({ slot, item }) => (
          <div
            key={slot}
            className="slot"
            onDragOver={allowDrop}
            onDrop={(e) => handleDrop(e, slot)}
            onDragStart={(e) => {
              e.dataTransfer.setData('slot', slot)
              e.dataTransfer.setData('inventory', inventoryKey)
              if (containerId) {
                e.dataTransfer.setData('containerId', containerId)
              }
            }}
          >
            <ItemCard slot={slot} item={item} onContext={onContext} />
          </div>
        ))}
      </div>
    </div>
  )
}
