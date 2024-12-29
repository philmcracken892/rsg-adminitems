fx_version 'cerulean'
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'
game 'rdr3'

name "itemspawner"
author "phil"
version "1.0"
description "Item Spawner for RedM"

shared_scripts {
    '@ox_lib/init.lua',
    'config.lua'  
}


server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/sconfig.lua',  
    'server/server.lua'   
}

client_scripts {
    'client/*.lua'
}

dependencies {
    'ox_lib',
    'oxmysql',
    'rsg-core'  
}

lua54 'yes'