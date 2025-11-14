fx_version 'cerulean'
game 'gta5'
lua54 'yes'

client_script '@mythic-base/components/cl_error.lua'
client_script '@mythic-pwnzor/client/check.lua'

ui_page 'ui/index.html'

files {
    'ui/index.html',
    'ui/style.css',
    'ui/app.js'
}

client_scripts {
    'client/*.lua'
}

server_scripts {
    'server/*.lua'
}