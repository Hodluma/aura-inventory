fx_version 'cerulean'
game 'gta5'

name 'aura-inventory'
description 'Comprehensive inventory system with React NUI and QBCore backend.'
author 'Aura Team'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'shared/bridge_qb.lua',
    'shared/utils.lua',
    'config/settings.lua',
    'config/items.lua',
    'config/shops.lua',
    'config/stashes.lua',
    'config/crafting.lua'
}

client_scripts {
    'client/main.lua',
    'client/nui.lua',
    'client/target.lua',
    'client/weapons.lua',
    'client/ground.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/logs.lua',
    'server/inventory.lua',
    'server/containers.lua',
    'server/crafting.lua',
    'server/weapons.lua',
    'server/shops.lua',
    'server/main.lua'
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/assets/*',
    'images/*.png'
}

provide 'aura-inventory'
