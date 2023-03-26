fx_version 'adamant'
game 'gta5'

Author 'Playooze#4977'
description "Xn Garage Rebuilt"

client_scripts {
    "config.lua",
    "client.lua",
}

server_scripts {
    '@mysql-async/lib/MySQL.lua',
    "config.lua",
    "server.lua",
}

shared_scripts {
    '@es_extended/imports.lua',
}

dependecys {
    'cd_drawtextui', -- its free
    --'okokNotify', -- its leaked
}