--- @file src/client/main.lua
--- @description Main client side handling

--- @section Imports

local _nui = require("src.client.modules.nui")

--- @section Cache

local cached_players = {}

--- @section Helpers

local function fetch_players(cb)
    exports.rig:trigger_callback("rig_admin:server:get_players", {}, function(server_players)
        cached_players = server_players or {}
        if cb then cb() end
    end)
end

local function build_player_items()
    local items = {}

    for _, player in ipairs(cached_players) do
        local server_id = player.id

        items[#items + 1] = {
            id = "player_" .. server_id,
            label = ("%s | [%s] (%s)"):format(player.name, player.unique_id, server_id),
            icon = "fas fa-user",
            items = {
                {
                    id = "kick_" .. server_id,
                    label = "Kick",
                    should_close = true,
                    data = { target = server_id },
                    on_select = function(d)
                        print(("kick fired for %s"):format(d.target))
                    end,
                },
                {
                    id = "ban_" .. server_id,
                    label = "Ban",
                    should_close = true,
                    data = { target = server_id },
                    on_select = function(d)
                        print(("ban fired for %s"):format(d.target))
                    end,
                },
            }
        }
    end

    return items
end

--- @section Events

local test_menu = {
    layout = { position = "top-right" },
    sections = {
        {
            label = "Test",
            items = {
                {
                    id = "test_item_1",
                    label = "Test Item 1",
                    icon = "fas fa-star",
                    on_select = function(data)
                        print("function fired")
                    end,
                },
                {
                    id = "test_players",
                    label = "Players",
                    icon = "fas fa-users",
                    dynamic = true,
                    on_select = function(data)
                        return { items = build_player_items() }
                    end,
                }
            }
        }
    }
}

RegisterNetEvent("rig_admin:client:open_quickmenu", function()
    fetch_players(function()
        _nui.open_quickmenu(test_menu)
    end)
end)

RegisterNetEvent("rig_admin:client:close_quickmenu", function()
    _nui.close_quickmenu()
end)

RegisterNetEvent("rig_admin:client:copy_to_clipboard", function(string)
    if not string then return end
    _nui.copy_to_clipboard(string)
end)