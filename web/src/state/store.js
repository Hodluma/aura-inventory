import create from 'zustand'
import shallow from 'zustand/shallow'

const initialState = {
  open: false,
  inventory: { items: {}, weight: 0, weightLimit: 0, slots: 0 },
  container: null,
  hotbar: { slots: {}, active: 1 },
  toasts: [],
  filters: { search: '', category: 'all', sort: 'name' },
  locale: 'en'
}

export const useInventoryStore = create((set, get) => ({
  ...initialState,
  setOpen: (open) => set({ open }),
  setInventory: (inventory) => set({ inventory }),
  setContainer: (container) => set({ container }),
  setHotbar: (hotbar) => set({ hotbar }),
  pushToast: (toast) =>
    set((state) => ({
      toasts: [...state.toasts, { id: Date.now(), ...toast }]
    })),
  dismissToast: (id) =>
    set((state) => ({
      toasts: state.toasts.filter((t) => t.id !== id)
    })),
  setFilters: (filters) => set((state) => ({ filters: { ...state.filters, ...filters } })),
  hydrate: (data) => set((state) => ({ ...state, ...data }))
}))

export const selectors = {
  inventory: (state) => state.inventory,
  container: (state) => state.container,
  hotbar: (state) => state.hotbar,
  toasts: (state) => state.toasts,
  filters: (state) => state.filters,
  open: (state) => state.open
}

export const useShallow = shallow
