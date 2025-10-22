import React from 'react'

export default function Header({ filters, onFilterChange, inventory }) {
  return (
    <header className="header">
      <div>
        <input
          type="text"
          placeholder="Search"
          value={filters.search}
          onChange={(e) => onFilterChange({ search: e.target.value })}
        />
        <select value={filters.category} onChange={(e) => onFilterChange({ category: e.target.value })}>
          <option value="all">All</option>
          <option value="food">Food</option>
          <option value="medical">Medical</option>
          <option value="weapon">Weapons</option>
          <option value="ammo">Ammo</option>
          <option value="attachment">Attachments</option>
        </select>
        <select value={filters.sort} onChange={(e) => onFilterChange({ sort: e.target.value })}>
          <option value="name">Name</option>
          <option value="qty">Quantity</option>
          <option value="weight">Weight</option>
        </select>
      </div>
      <div className="capacity">
        Weight: {inventory.weight?.toFixed?.(2) || 0} / {inventory.weightLimit}
      </div>
    </header>
  )
}
