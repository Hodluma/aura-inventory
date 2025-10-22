import React from 'react'
import InventoryGrid from './InventoryGrid'

export default function ContainerGrid({ container, onMove, onContext }) {
  if (!container) return null
  return (
    <InventoryGrid
      title={container.label}
      inventory={{
        items: container.items || {},
        slots: container.maxSlots,
        weight: container.weight || 0,
        weightLimit: container.maxWeight
      }}
      inventoryKey="container"
      containerId={container.id}
      onMove={(payload) => onMove({ ...payload, containerId: container.id })}
      onContext={onContext}
    />
  )
}
