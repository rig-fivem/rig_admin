--- @module configs.permissions
--- @file configs/permissions.lua
--- @description Handles permissions for each action

return {

    enabled = true,

    user = {
        noclip = { "rig.dev", "rig.admin" },
        godmode = { "rig.dev", "rig.admin" },
    },

    players = {
        godmode = { "rig.dev", "rig.admin" },
    },

}