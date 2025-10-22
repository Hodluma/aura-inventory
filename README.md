# Aura Inventory

Aura Inventory is a production-focused inventory system for FiveM servers running QBCore. It features a modern React NUI, hotbar with cooldown overlay, secondary container support, crafting, attachments, and robust anti-cheat validations. The system is server-authoritative and ships with sensible example configurations to get you started quickly.

## Features
- Grid-based inventory with drag-and-drop, stack merge/split, and context menus
- Hotbar overlay (Z) with keybind activation (1–5)
- Secondary containers (vehicle trunks, stashes, crafting benches)
- React NUI with diff syncing, tooltips, filters, and notifications
- Server-side validation for all transfers, usage, and crafting
- Weapon durability, ammo, and attachment compatibility checks
- Crafting stations with job/gang/level requirements and fail chance
- Shops, ground drops, and admin inspection commands

## Installation
1. Ensure your server has **QBCore** and **oxmysql** installed and configured.
2. Clone or copy this resource folder into your FiveM resources directory:
   ```bash
   git clone https://github.com/your-org/aura-inventory.git
   ```
3. Install web dependencies and build the NUI bundle:
   ```bash
   cd aura-inventory/web
   npm install
   npm run build
   ```
4. Add `ensure aura-inventory` to your `server.cfg` after QBCore.
5. Restart your server. On first run, database tables for player inventories, ground drops, and logs will be created automatically.

## Keybinds
- **TAB**: Open/close inventory
- **Z**: Toggle hotbar overlay
- **1–5**: Use the respective hotbar slot item

Keybinds can be changed via `/ainv.rebind <key> <action>` or by editing `config/settings.lua`.

## Configuration
- `config/settings.lua`: Global tuning (capacity mode, weight limits, despawn timers, rate limits, webhook URLs, locales).
- `config/items.lua`: Item catalog with weight, stack size, categories, metadata defaults, and durability rules.
- `config/stashes.lua`: Named stash definitions with capacity and access rules.
- `config/shops.lua`: Shop inventory, pricing, taxes, and stock behavior.
- `config/crafting.lua`: Crafting recipes, stations, and requirements.

The `images/` folder is provided for optional PNG icons that match your item names. Add new icons there as needed—if an icon is missing, the UI renders an embedded fallback graphic automatically, so binaries are not required.

## Development
- The React front-end uses Vite for fast iteration. Run `npm run dev` inside `web/` to start a hot-reload server and update `fxmanifest.lua` to point to `http://localhost:5173` during development if desired.
- Lua files leverage QBCore exports and should be linted with `luacheck` where possible.

## License
Licensed under the MIT license. See [LICENSE](LICENSE) for details.
