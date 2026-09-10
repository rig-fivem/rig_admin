--[[
----------------------------------------
RIG Gathering (built for RIG-FiveM)

Author: Case (https://caseirl.dev)
Repo: https://github.com/rig-fivem/rig_gathering
License: https://github.com/rig-fivem/rig_gathering/blob/main/LICENSE
----------------------------------------
]]

fx_version "cerulean"
games { "gta5" }
name "rig_admin"
version "0.1.0"
description "Admin menu & panel for RIG (FiveM)."
license "Apache 2.0"
author "Case"
lua54 "yes"

ui_page "ui/index.html"
files {
    "locales/*.json",
    "ui/**/*",
}

shared_script "init.lua"

client_scripts {
    "src/client/modules/*.lua",
    "src/client/main.lua"
}
server_scripts {
    "configs/*.lua",
    "src/server/*.lua"
}

dependencies {
    "rig"
}