import React from 'react'

export default function Shops({ shops, onBuy, onSell }) {
  if (!shops || shops.length === 0) return null
  return (
    <div className="shops">
      <h3>Shops</h3>
      {shops.map((shop) => (
        <div key={shop.id} className="shop">
          <h4>{shop.label}</h4>
          <div className="items">
            {shop.items.map((item) => (
              <div key={item.name} className="shop-item">
                <span>{item.name}</span>
                <span>${item.price}</span>
                <div className="actions">
                  <button onClick={() => onBuy(shop.id, item.name, 1)}>Buy</button>
                  <button onClick={() => onSell(shop.id, item.name, 1)}>Sell</button>
                </div>
              </div>
            ))}
          </div>
        </div>
      ))}
    </div>
  )
}
