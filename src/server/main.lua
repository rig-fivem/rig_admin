--- @file src/server/main.lua
--- @description Main server side handling.

--- @section Imports

local _perms = require("configs.permissions")

--- @section Functions

local function has_permission(source, category, permission)
    if not _perms.enabled then return true end

    category = category or "user"
    local aces = _perms[category] and _perms[category][permission]

    if not aces then return false end
    if type(aces) == "string" then aces = { aces } end
    
    for _, ace in ipairs(aces) do
        if IsPlayerAceAllowed(source, ace) then return true end
    end
    
    return false
end

--- @section Callbacks

exports.rig:register_callback("rig_admin:server:validate_permission", function(source, data, cb)
    local category = data and data.category
    local permission = data and data.permission

    if not permission then
        cb({ allowed = false })
        return
    end

    cb({ allowed = has_permission(source, category, permission) })
end)

exports.rig:register_callback("rig_admin:server:get_players", function(source, data, cb)
    local players = {}
    
    for _, player_id in ipairs(GetPlayers()) do
        local server_id = tonumber(player_id)
        local user = exports.rig:get_user_data(server_id)

        table.insert(players, {
            id = server_id,
            unique_id = user and user.unique_id or "UID N/A",
            name = user and user.name or GetPlayerName(server_id),
        })
    end

    cb(players)
end)