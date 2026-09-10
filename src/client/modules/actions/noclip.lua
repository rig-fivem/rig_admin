--- @module noclip
--- @file src/client/modules/noclip.lua
--- @description Handles noclip: camera-based freecam movement with speed scroll, slow/fast modifiers

--- @section Guard

if rawget(_G, "__client_noclip_module") then
    return _G.__client_noclip_module
end

--- @section Imports

local _keys = require("src.client.modules.keys")
local key_list = _keys.get_keys()

--- @section Initalisation

local m = {}
_G.__client_noclip_module = m

--- @section Constants

local BASE_SPEED = 0.8
local SLOW_SPEED = 0.03
local FAST_MULT = 4.0
local BASE_ACCEL = 0.04
local FRICTION = 0.85
local SCROLL_STEP = 0.5
local SCROLL_MIN = 0.5
local SCROLL_MAX = 6.0

--- @section Variables

local noclip_active = false
local noclip_cam = nil
local noclip_vel = vector3(0.0, 0.0, 0.0)
local noclip_speed_mult = 1.0

--- @section Helpers

local function is_pressed(group, control)
    return IsControlPressed(group, control) or IsDisabledControlPressed(group, control)
end

local function find_ground(x, y, z)
    for i = 0, 500 do
        local found, ground_z = GetGroundZFor_3dCoord(x, y, z - i * 0.1, false)
        if found then return ground_z end
    end
    return z
end

--- @section Functions

local function start_noclip()
    local ped = PlayerPedId()
    local pos = GetEntityCoords(ped)
    noclip_cam = CreateCam("DEFAULT_SCRIPTED_CAMERA", true)
    SetCamCoord(noclip_cam, pos.x, pos.y, pos.z + 2.0)
    SetCamRot(noclip_cam, 0.0, 0.0, GetEntityHeading(ped), 2)
    SetCamFov(noclip_cam, 70.0)
    RenderScriptCams(true, false, 0, true, true)
    FreezeEntityPosition(ped, true)
    SetEntityAlpha(ped, 0, false)
    SetEntityCollision(ped, false, false)
    SetEntityInvincible(ped, true)
    noclip_vel = vector3(0.0, 0.0, 0.0)
    noclip_speed_mult = 1.0
    noclip_active = true
end

local function stop_noclip()
    noclip_active = false
    local cam_pos = GetCamCoord(noclip_cam)
    RenderScriptCams(false, false, 0, true, true)
    DestroyCam(noclip_cam, false)
    noclip_cam = nil
    local ped = PlayerPedId()
    local ground_z = find_ground(cam_pos.x, cam_pos.y, cam_pos.z)
    SetEntityCoords(ped, cam_pos.x, cam_pos.y, ground_z + 0.5, false, false, false, false)
    FreezeEntityPosition(ped, false)
    SetEntityAlpha(ped, 255, false)
    SetEntityCollision(ped, true, true)
    SetEntityInvincible(ped, false)
end

--- @section Threads

CreateThread(function()
    while true do
        Wait(0)
        if noclip_active and noclip_cam then
            local mx = GetDisabledControlNormal(0, 1)
            local my = GetDisabledControlNormal(0, 2)
            local rot = GetCamRot(noclip_cam, 2)
            local new_z = rot.z - mx * 5.0
            local new_x = math.max(-89.0, math.min(89.0, rot.x - my * 5.0))
            SetCamRot(noclip_cam, new_x, 0.0, new_z, 2)
            local rad_z = math.rad(new_z)
            local rad_x = math.rad(new_x)
            local fx = -math.sin(rad_z) * math.cos(rad_x)
            local fy =  math.cos(rad_z) * math.cos(rad_x)
            local fz =  math.sin(rad_x)
            local rx = -math.sin(math.rad(new_z - 90.0))
            local ry =  math.cos(math.rad(new_z - 90.0))
            if is_pressed(2, 15) then
                noclip_speed_mult = math.min(SCROLL_MAX, noclip_speed_mult + SCROLL_STEP)
            elseif is_pressed(2, 14) then
                noclip_speed_mult = math.max(SCROLL_MIN, noclip_speed_mult - SCROLL_STEP)
            end
            local top_speed = BASE_SPEED * noclip_speed_mult
            local accel = BASE_ACCEL * noclip_speed_mult
            if is_pressed(0, key_list["leftcontrol"]) then
                top_speed = SLOW_SPEED
                accel = BASE_ACCEL * 0.5
            elseif is_pressed(0, key_list["leftshift"]) then
                top_speed = BASE_SPEED * FAST_MULT * noclip_speed_mult
                accel = BASE_ACCEL * 4.0
            end
            local input = vector3(0.0, 0.0, 0.0)
            if is_pressed(0, key_list["w"]) then input = input + vector3(fx, fy, fz) end
            if is_pressed(0, key_list["s"]) then input = input - vector3(fx, fy, fz) end
            if is_pressed(0, key_list["a"]) then input = input - vector3(rx, ry, 0.0) end
            if is_pressed(0, key_list["d"]) then input = input + vector3(rx, ry, 0.0) end
            if is_pressed(0, key_list["q"]) then input = input + vector3(0.0, 0.0, 1.0) end
            if is_pressed(0, key_list["z"]) then input = input - vector3(0.0, 0.0, 1.0) end
            noclip_vel = noclip_vel + input * accel
            local spd = math.sqrt(noclip_vel.x^2 + noclip_vel.y^2 + noclip_vel.z^2)
            if spd > top_speed then
                noclip_vel = noclip_vel * (top_speed / spd)
            end
            noclip_vel = noclip_vel * FRICTION
            local pos = GetCamCoord(noclip_cam)
            local new_pos = vector3(pos.x + noclip_vel.x, pos.y + noclip_vel.y, pos.z + noclip_vel.z)
            SetCamCoord(noclip_cam, new_pos.x, new_pos.y, new_pos.z)
            SetEntityCoordsNoOffset(PlayerPedId(), new_pos.x, new_pos.y, new_pos.z, false, false, false)
            DisableAllControlActions(0)
        end
    end
end)

--- @section API

function m.toggle_noclip()
    exports.rig:trigger_callback("rig_admin:server:validate_permission", { permission = "noclip" }, function(response)
        if not response or not response.allowed then
            exports.rig:notify({
                header = translate("notify.access_denied"),
                type = "error",
                message = translate("notify.no_noclip_permission"),
                duration = 4000
            })
            return
        end
        if noclip_active then stop_noclip() else start_noclip() end
    end)
end

return m