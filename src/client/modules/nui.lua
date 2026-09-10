--- @module quickmenu
--- @file src/client/modules/quickmenu.lua
--- @description Handles building, opening, and closing the quickmenu nui component

--- @section Guard

if rawget(_G, "__client_quickmenu_module") then
    return _G.__client_quickmenu_module
end

--- @section Imports

local _keys = require("src.client.modules.keys")

--- @section Initalisation

local m = {}
_G.__client_quickmenu_module = m

--- @section Variables

local is_quickmenu_open = false
local functions = {}

--- @section Helpers

local function has_function(label)
    return functions[label] ~= nil
end

local function register_function(label, func)
    functions[label] = func
end

local function call_registered_function(label, data)
    if not label then
        log("error", "nui: label is required")
        return false
    end

    local func = functions[label]
    if not func then
        log("error", ("nui: no function registered for label '%s'"):format(label))
        return false
    end

    return func(data)
end

local function sanitize(data, path)
    path = path or "root"
    local out = {}

    for k, v in pairs(data) do
        local p = ("%s_%s"):format(path, tostring(k)):gsub("[^%w_]", "")

        if (k == "on_action" or k == "on_increment" or k == "on_decrement" or k == "on_select") then
            register_function(p, v)
            out.action = p
        elseif type(v) == "table" then
            out[k] = sanitize(v, p)
        else
            out[k] = v
        end
    end

    return out
end

local function send_nav(input)
    SendNUIMessage({ type = "qm_nav", input = input })
end

local function start_nav_thread()
    CreateThread(function()
        while is_quickmenu_open do
            Wait(0)

            if IsControlJustPressed(0, _keys.get_key("arrowup")) then
                send_nav("up")
            elseif IsControlJustPressed(0, _keys.get_key("arrowdown")) then
                send_nav("down")
            elseif IsControlJustPressed(0, _keys.get_key("enter")) then
                send_nav("select")
            elseif IsControlJustPressed(0, _keys.get_key("backspace")) then
                send_nav("back")
            elseif IsControlJustPressed(0, _keys.get_key("escape")) then
                m.close_quickmenu()
            end
        end
    end)
end

--- @section Functions

function m.open_quickmenu(payload)
    if type(payload) ~= "table" then
        log("error", "quickmenu: open() requires a table payload")
        return
    end

    if is_quickmenu_open then
        m.close_quickmenu()
    end

    local sanitized = sanitize(payload)

    is_quickmenu_open = true

    SendNUIMessage({ func = "build_quickmenu", payload = sanitized })

    start_nav_thread()
end

function m.close_quickmenu()
    if not is_quickmenu_open then return end

    is_quickmenu_open = false

    SendNUIMessage({ func = "close_quickmenu" })
end

function m.is_quickmenu_open()
    return is_quickmenu_open
end

function m.push_dynamic_update(id, items, title)
    if not is_quickmenu_open then return end
    SendNUIMessage({ type = "qm_update", id = id, items = items, title = title })
end

function m.copy_to_clipboard(string)
    if not string then return end
    SendNUIMessage({ func = "copy_to_clipboard", string = string })
end

--- @section NUI Callbacks

RegisterNUICallback("nui:handler", function(data, cb)
    log("info", ("nui: handler invoked with %s"):format(json.encode(data)))

    if not data or not data.action then
        if cb then cb(false) end
        return
    end

    local response = true

    if has_function(data.action) then
        local success, result = pcall(call_registered_function, data.action, data)

        if success then
            if result ~= nil then
                response = result
            end
        else
            log("error", ("nui: handler failed for action '%s': %s"):format(data.action, result))
            response = false
        end
    end

    if data.should_close then
        m.close_quickmenu()
    end

    if cb then cb(response) end
end)

--- @section Exports

exports("open_quickmenu", m.open_quickmenu)
exports("close_quickmenu", m.close_quickmenu)
exports("push_dynamic_update", m.push_dynamic_update)

return m