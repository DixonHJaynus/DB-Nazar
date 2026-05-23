fx_version 'cerulean'
games { 'rdr3' }
rdr3_warning 'I acknowledge that this is a prerelease build of RedM, and I am aware my resources *will* become incompatible once RedM ships.'

name 'DB-Nazar'
description 'Madam Nazar - Travelling Romani Fortune Teller & Rare Goods Merchant for RSG Core'
author 'DB Scripts'
version '1.0.2'

shared_scripts {
    'config.lua',
}

client_scripts {
    'client/main.lua',
    'client/treasure.lua',
}

server_scripts {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua',
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/script.js',
}

lua54 'yes'

dependencies {
    'rsg-core',
    'ox_target',
}
