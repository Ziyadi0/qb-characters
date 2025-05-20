fx_version 'cerulean'
game 'gta5'

 -- ## By idrag https://discord.gg/e3RebFbSPZ
description 'QB-Multicharacter'
version '1.0.0'

shared_scripts {
    '@ox_lib/init.lua',
    '@qb-core/shared/locale.lua',
    'locales/en.lua',
    'locales/*.lua',
    'config.lua'
}
client_script 'client/main.lua'
server_scripts  {
    '@oxmysql/lib/MySQL.lua',
    'server/main.lua'
}

ui_page 'html/index.html'

files {
    'html/index.html',
    'html/style.css',
    'html/newstyle.css',
    'html/ServerLogo.png',
    'html/image.png',
    'html/sign.png',
    'html/style/*.*',
    'html/js/*.*',
    'html/sounds/*.*'
}

dependencies {
    'qb-core',
}

escrow_ignore {
    'config.lua'
}

lua54 'yes'

dependency '/assetpacks'