import React, { useCallback, useEffect, useMemo, useState } from 'react'
import InventoryGrid from './components/InventoryGrid'
import ContainerGrid from './components/ContainerGrid'
import Hotbar from './components/Hotbar'
import ContextMenu from './components/ContextMenu'
import Toast from './components/Toast'
import Header from './components/Header'
import Crafting from './components/Crafting'
import Attachments from './components/Attachments'
import Shops from './components/Shops'
import GroundDrops from './components/GroundDrops'
import { useInventoryStore, useShallow } from './state/store'

const post = (event, data) => {
  fetch(`https://aura-inventory/${event}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data ?? {})
  })
}

export default function App() {
  const [context, setContext] = useState({ visible: false, position: { x: 0, y: 0 }, slot: null, item: null, source: 'player' })
  const [recipes, setRecipes] = useState([])
  const [stationId, setStationId] = useState(null)
  const [drops, setDrops] = useState([])
  const [shops, setShops] = useState([])
  const [attachmentContext, setAttachmentContext] = useState(null)

  const [inventory, container, hotbarState, toasts, filters, open] = useInventoryStore(
    (state) => [state.inventory, state.container, state.hotbar, state.toasts, state.filters, state.open],
    useShallow
  )
  const setInventory = useInventoryStore((state) => state.setInventory)
  const setContainer = useInventoryStore((state) => state.setContainer)
  const setHotbar = useInventoryStore((state) => state.setHotbar)
  const setOpen = useInventoryStore((state) => state.setOpen)
  const pushToast = useInventoryStore((state) => state.pushToast)
  const dismissToast = useInventoryStore((state) => state.dismissToast)
  const setFilters = useInventoryStore((state) => state.setFilters)

  useEffect(() => {
    const handler = (event) => {
      const { action, data } = event.data || {}
      switch (action) {
        case 'openInventory':
          if (data.open !== undefined) setOpen(data.open)
          if (data.state) setInventory(data.state)
          break
        case 'state':
          if (data?.items) setInventory(data)
          break
        case 'openContainer':
          setContainer(data)
          break
        case 'notify':
          pushToast({ message: data.message, type: data.type })
          break
        case 'hotbar':
          setHotbar(data)
          break
        case 'craftingStation':
          setRecipes(data.recipes || [])
          setStationId(data.id)
          break
        case 'drops':
          setDrops(data)
          break
        case 'shops':
          setShops(data)
          break
        case 'attachments':
          setAttachmentContext(data)
          break
        default:
          break
      }
    }
    window.addEventListener('message', handler)
    return () => window.removeEventListener('message', handler)
  }, [setOpen, setInventory, setContainer, pushToast, setHotbar])

  const filteredInventory = useMemo(() => {
    const items = { ...(inventory.items || {}) }
    const search = filters.search?.toLowerCase() || ''
    const category = filters.category
    Object.entries(items).forEach(([slot, item]) => {
      if (!item) return
      const matchesSearch = item.name.toLowerCase().includes(search)
      const matchesCategory = category === 'all' || item.category === category
      if (!matchesSearch || !matchesCategory) {
        items[slot] = null
      }
    })
    return { ...inventory, items }
  }, [inventory, filters])

  const resolvedHotbar = useMemo(() => {
    const slots = {}
    const mapping = hotbarState.slots || {}
    const items = inventory.items || {}
    Object.entries(mapping).forEach(([slot, invSlot]) => {
      const item = items[invSlot]
      if (item) slots[slot] = item
    })
    return { slots, active: hotbarState.active }
  }, [hotbarState, inventory.items])

  const handleMove = useCallback((payload) => {
    post('moveItem', payload)
  }, [])

  const handleContext = useCallback((event, slot, item) => {
    setContext({ visible: true, position: { x: event.clientX, y: event.clientY }, slot, item, source: event.currentTarget.closest('.inventory-grid')?.dataset?.key || 'player' })
  }, [])

  useEffect(() => {
    const listener = () => setContext((ctx) => ({ ...ctx, visible: false }))
    window.addEventListener('click', listener)
    return () => window.removeEventListener('click', listener)
  }, [])

  const handleContextAction = (action) => {
    const { slot } = context
    switch (action) {
      case 'use':
        post('useItem', { slot })
        break
      case 'split': {
        const amount = Number(prompt('Split amount'))
        const toSlot = Number(prompt('Target slot'))
        if (Number.isFinite(amount) && Number.isFinite(toSlot)) {
          post('splitStack', { fromSlot: slot, toSlot, amount })
        }
        break
      }
      case 'drop':
        {
          const amount = Number(prompt('Amount to drop', context.item.amount))
          if (Number.isFinite(amount)) {
            post('dropItem', { slot, amount })
          }
        }
        break
      case 'hotbar':
        const hotbarSlot = Number(prompt('Assign to hotbar slot (1-5)'))
        if (Number.isFinite(hotbarSlot)) {
          post('hotbarUpdate', { slot: hotbarSlot, itemSlot: slot })
        }
        break
      default:
        break
    }
    setContext((ctx) => ({ ...ctx, visible: false }))
  }

  const handleCraft = (recipeId) => {
    if (!stationId) return
    post('craftStart', { recipeId, stationId })
  }

  const handleFilterChange = (value) => setFilters(value)

  return (
    <div className="app" style={{ display: open ? 'grid' : 'none' }}>
      <Header filters={filters} onFilterChange={handleFilterChange} inventory={inventory} />
      <InventoryGrid
        title="Inventory"
        inventory={filteredInventory}
        inventoryKey="player"
        onMove={handleMove}
        onContext={handleContext}
      />
      <ContainerGrid container={container} onMove={handleMove} onContext={handleContext} />
      <Hotbar
        hotbar={resolvedHotbar}
        onBind={(slot) => {
          const itemSlot = Number(prompt('Inventory slot to bind'))
          if (Number.isFinite(itemSlot)) {
            post('hotbarUpdate', { slot, itemSlot })
          }
        }}
      />
      <Crafting recipes={recipes} onCraft={handleCraft} />
      <Attachments
        context={attachmentContext}
        onDetach={(slot, type) => {
          post('detach', { weaponSlot: slot, attachmentType: type })
          setAttachmentContext(null)
        }}
      />
      <Shops shops={shops} onBuy={(shopId, itemName, amount) => post('shopBuy', { shopId, itemName, amount })} onSell={(shopId, itemName, amount) => post('shopSell', { shopId, itemName, amount })} />
      <GroundDrops drops={drops} onPickup={(dropId) => post('pickupDrop', { dropId })} />
      <ContextMenu visible={context.visible} position={context.position} onAction={handleContextAction} item={context.item} />
      <div className="toast-container">
        {toasts.map((toast) => (
          <Toast key={toast.id} toast={toast} onDismiss={dismissToast} />
        ))}
      </div>
    </div>
  )
}
