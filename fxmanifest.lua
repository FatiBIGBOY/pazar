fx_version 'cerulean'
game 'gta5'

author 'bigboydevelopments'
description '📦 İkinci El Eşya Pazarı Sistemi (QBCore)'
version '1.0.0'

lua54 'yes'

shared_scripts {
    '@qb-core/shared/locale.lua',
    'config.lua'
}

client_scripts {
    'client.lua'
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server.lua'
}
