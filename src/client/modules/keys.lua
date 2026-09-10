--- @module keys
--- @file src/client/modules/m.lua
--- @description Handles some general key functions and a static key list.
--- Mainly saves on needing to remember key codes.

--- @section Constants

local KEYS = {
    ["enter"] = 191,
    ["escape"] = 322,
    ["backspace"] = 177,
    ["tab"] = 37,
    ["arrowleft"] = 174,
    ["arrowright"] = 175,
    ["arrowup"] = 172,
    ["arrowdown"] = 173,
    ["space"] = 22,
    ["delete"] = 178,
    ["insert"] = 121,
    ["home"] = 213,
    ["end"] = 214,
    ["pageup"] = 10,
    ["pagedown"] = 11,
    ["leftcontrol"] = 36,
    ["leftshift"] = 21,
    ["leftalt"] = 19,
    ["rightcontrol"] = 70,
    ["rightshift"] = 70,
    ["rightalt"] = 70,
    ["numpad0"] = 108,
    ["numpad1"] = 117,
    ["numpad2"] = 118,
    ["numpad3"] = 60,
    ["numpad4"] = 107,
    ["numpad5"] = 110,
    ["numpad6"] = 109,
    ["numpad7"] = 117,
    ["numpad8"] = 111,
    ["numpad9"] = 112,
    ["numpad+"] = 96,
    ["numpad-"] = 97,
    ["numpadenter"] = 191,
    ["numpad."] = 108,
    ["f1"] = 288,
    ["f2"] = 289,
    ["f3"] = 170,
    ["f4"] = 168,
    ["f5"] = 166,
    ["f6"] = 167,
    ["f7"] = 168,
    ["f8"] = 169,
    ["f9"] = 56,
    ["f10"] = 57,
    ["a"] = 34,
    ["b"] = 29,
    ["c"] = 26,
    ["d"] = 30,
    ["e"] = 46,
    ["f"] = 49,
    ["g"] = 47,
    ["h"] = 74,
    ["i"] = 27,
    ["j"] = 36,
    ["k"] = 311,
    ["l"] = 182,
    ["m"] = 244,
    ["n"] = 249,
    ["o"] = 39,
    ["p"] = 199,
    ["q"] = 44,
    ["r"] = 45,
    ["s"] = 33,
    ["t"] = 245,
    ["u"] = 303,
    ["v"] = 0,
    ["w"] = 32,
    ["x"] = 73,
    ["y"] = 246,
    ["z"] = 20,
    ["mouse1"] = 24,
    ["mouse2"] = 25
}

--- @section Initalisation

local m = {}

m.keys = KEYS

--- @section Functions

function m.get_keys()
    return KEYS
end

function m.get_key(key_name)
    return KEYS[key_name]
end

function m.get_key_name(key_code)
    for name, code in pairs(KEYS) do
        if code == key_code then
            return name
        end
    end
    return nil
end

function m.print_key_list()
    print("Keylist:")
    for name, code in pairs(KEYS) do
        print(name, code)
    end
end

function m.key_exists(key_name)
    return KEYS[key_name] ~= nil
end

return m