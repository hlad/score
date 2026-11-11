-- Score plugin menu and persistent settings (MAME 0.281)
local menu = {}
local print_every_frame = false
local config_dir

local function load_settings()
    local home = manager.options.entries.homepath:value():match("([^;]+)")    
    config_dir = home .. "/score"
    local file = io.open(config_dir .. "/plugin.cfg", "r")
    if file then
        local settings = require("json").parse(file:read("a"))
        file:close()
        if settings and settings.print_every_frame ~= nil then
            print_every_frame = settings.print_every_frame and true or false
        end
    end
end

local function save_settings()    
    local attr = lfs.attributes(config_dir)
    if not attr then
        lfs.mkdir(config_dir)
    elseif attr.mode ~= "directory" then
        emu.print_error("Score plugin: settings path is not a directory: " .. config_dir)
        return
    end
    local file = io.open(config_dir .. "/plugin.cfg", "w")
    if not file then
        emu.print_error("Score plugin: cannot write plugin.cfg")
        return
    end
    file:write(require("json").stringify({ print_every_frame = print_every_frame }, { indent = true }))
    file:close()
end

function menu.get_print_every_frame()
    return print_every_frame
end

function menu.start()
    load_settings()
    local function populate()
        local mode = print_every_frame and "Every frame" or "On exit"
        return {
            { "Score output options", "", "off" },
            { "---", "", "off" },
            { "Print result", mode, "lr" }
        }
    end
    local function callback(index, event)
        if index ~= 3 then return false end
        if event == "left" or event == "right" or event == "select" then
            print_every_frame = not print_every_frame
            save_settings()
            return true
        end
        return false
    end
    emu.register_menu(callback, populate, "Score")
end

return menu
