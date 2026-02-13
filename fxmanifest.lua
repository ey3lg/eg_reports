fx_version 'cerulean'
game 'gta5'
lua54 'yes'

name 'eg_reports'
author 'eg (eg.tebex.io)'
version '1.0.2'

shared_scripts {
    '@ox_lib/init.lua',
    'shared/config.lua',
    'shared/locale.lua',
}

client_scripts {
    'bridge/client.lua',
    'client/modules/*.lua',
    'client/callbacks.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'bridge/server.lua',
    'server/config.lua',
    'server/main.lua',
    'server/modules/*.lua',
    'server/callbacks.lua'
}

ui_page 'web/dist/index.html'

files {
    'web/dist/index.html',
    'web/dist/**/*',
    'locales/*.json'
}

dependencies {
    'oxmysql',
    'ox_lib',
    'community_bridge',
    'screenshot-basic'
}
