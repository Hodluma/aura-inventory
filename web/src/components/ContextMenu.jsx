import React from 'react'

const actions = [
  { key: 'use', label: 'Use' },
  { key: 'equip', label: 'Equip' },
  { key: 'split', label: 'Split' },
  { key: 'drop', label: 'Drop' },
  { key: 'hotbar', label: 'Assign to Hotbar' }
]

export default function ContextMenu({ visible, position, onAction, item }) {
  if (!visible || !item) return null
  return (
    <div className="context-menu" style={{ top: position.y, left: position.x }}>
      {actions.map((action) => (
        <button key={action.key} onClick={() => onAction(action.key)}>
          {action.label}
        </button>
      ))}
    </div>
  )
}
