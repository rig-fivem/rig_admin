--- @file src/server/main.lua
--- @description Main server side handling.

--- @section Commands

exports.rig:register_command({
    ace = { "rig.dev", "rig.admin" },
    name = "rig:adminmenu",
    help = "Open the admin menu",
    handler = function(source)
        TriggerClientEvent("rig_admin:client:open_quickmenu", source)
    end
})

exports.rig:register_command({
    ace = { "rig.dev", "rig.admin" },
    name = "rig:copycoords",
    help = "Copy your coordinates [v2, v3, v4]",
    params = {
        { name = "type", help = "[v2], [v3], [v4]" }
    },
    handler = function(source, args)
        local coord_type = args[1] or "v4"
        local ped = GetPlayerPed(source)
        if not DoesEntityExist(ped) then return false end

        local coords = GetEntityCoords(ped)
        local heading = GetEntityHeading(ped)

        local string
        if coord_type == "v2" then
            string = ("vector2(%.2f, %.2f)"):format(coords.x, coords.y)
        elseif coord_type == "v3" then
            string = ("vector3(%.2f, %.2f, %.2f)"):format(coords.x, coords.y, coords.z)
        elseif coord_type == "v4" then
            string = ("vector4(%.2f, %.2f, %.2f, %.2f)"):format(coords.x, coords.y, coords.z, heading)
        else
            return exports.rig:notify(source, {
                type = "error",
                header = "ADMIN",
                message = ("Unknown coordinate type: %s"):format(coord_type),
                duration = 4500
            })
        end

        exports.rig:notify(source, {
            type = "info",
            header = "ADMIN",
            message = ("Copied %s coordinates to clipboard"):format(coord_type),
            duration = 4500
        })

        TriggerClientEvent("rig_admin:client:copy_to_clipboard", source, string)
    end
})