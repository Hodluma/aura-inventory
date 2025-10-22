import React from 'react'

export default function Attachments({ context, onDetach }) {
  if (!context) return null
  return (
    <div className="attachments">
      <h3>Attachments</h3>
      {context.options && context.options.length > 0 ? (
        <ul>
          {context.options.map((weapon) => (
            <li key={weapon.slot}>
              Slot {weapon.slot} - {weapon.weaponName}
              <ul>
                {Object.keys(weapon.attachments || {}).map((key) => (
                  <li key={key}>
                    {key}
                    <button onClick={() => onDetach(weapon.slot, key)}>Detach</button>
                  </li>
                ))}
              </ul>
            </li>
          ))}
        </ul>
      ) : (
        <p>No compatible weapon.</p>
      )}
    </div>
  )
}
