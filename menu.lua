-- Score plugin menu and persistent settings (MAME 0.281)
local menu = {}
local print_mode = "exit"
local config_dir

local modes = {
    "exit",
    "frame",
    "change"
}

local mode_names = {
    exit = "On exit",
    frame = "Every frame",
    change = "On score change"
}

local function load_settings()
    local home = manager.options.entries.homepath:value():match("([^;]+)")    
    config_dir = home .. "/score"
    local file = io.open(config_dir .. "/plugin.cfg", "r")
    if file then
        local settings = require("json").parse(file:read("a"))
        file:close()
        if settings then
            if settings.print_mode then
                print_mode = settings.print_mode
            elseif settings.print_every_frame then
                print_mode = "frame"
            end
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
    file:write(require("json").stringify(
        { print_mode = print_mode },
        { indent = true }
    ))
    file:close()
end

function menu.get_print_mode()
    return print_mode
end

function menu.start()
    load_settings()
    local function populate()
        return {
            { "Score output options", "", "off" },
            { "---", "", "off" },
            { "Print result", mode_names[print_mode], "lr" }
        }
    end
    local function callback(index, event)
        if index ~= 3 then return false end

        if event == "left" or event == "right"
            or event == "select" then

            local current = 1
            for i, mode in ipairs(modes) do
                if mode == print_mode then
                    current = i
                    break
                end
            end

            current = current % #modes + 1
            print_mode = modes[current]

            save_settings()
            return true
        end
        return false
    end

    emu.register_menu(callback, populate, "Score")
end

return menu
