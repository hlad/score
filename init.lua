local exports = {
    name = "score",
    version = "0.1",
    description = "Reads configured score memory locations and prints the score at game end.",
    license = "MIT",
    author = { name = "hlad" }
}	

local utils

local score = exports

local plugin_path = ""

local scores = {}

local values = {}
local values_last = {}

local cpu, mem

local menu

local fields = {"score", "lives"}

function score.set_folder(path)
    plugin_path = path
end

local function print_result(romname, values)
	local output = string.format('MAME_SCORE: {"game":"%s"', romname)

	local values_json = ""

	for _, field in ipairs(fields) do
			if values[field] ~= nil then
				values_json = values_json .. string.format(',"%s":"%s"', field, values[field])
			end
	end

	output = output .. values_json .. "}"

	emu.print_info(output)
end

local function get_value(start, length, format, endian, multiplier, addressing)
	local i_start, i_end, increment

	local value = 0

	local x = 0

	if addressing == "bit" then
		if endian == "little" then
			i_start = start + (length -1) * 8
			i_end = start
			increment = -8
		else
			i_start = start
			i_end = start + (length -1) * 8
			increment = 8
		end
	else
		if endian == "little" then
			i_start = start + length -1
			i_end = start
			increment = -1
		else
			i_start = start
			i_end = start + length -1
			increment = 1
		end
	end

	for i = i_start, i_end, increment
	do
		if format == "bcd" then
			value = value + (utils.byte_to_bcd(mem:read_u8(i)) * (100^x) | 0)
		end
		if format == "bin" then
			value = value + (mem:read_u8(i) * (256^x) | 0)
		end
		if format == "digits" then
			value = value + (utils.byte_to_digit(mem:read_u8(i)) * (10^x) | 0)
		end
		x = x + 1
	end

	if multiplier==nil then
		multiplier=1
	end

	return value * multiplier
end

function score.startplugin()
	utils = dofile(plugin_path .. "/utils.lua")
	menu = dofile(plugin_path .. "/menu.lua")
	menu.start()

	scores, err = loadfile(plugin_path .. "/scores.lua")

	reset_subscription = emu.add_machine_reset_notifier(function ()
		local romname = emu.romname()
		local gamename = emu.gamename()
		if romname~="___empty" and scores()[romname]~=nil then
			device = scores()[romname].device == nil and ":maincpu" or scores()[romname].device
			space = scores()[romname].space == nil and "program" or scores()[romname].space
			cpu = manager.machine.devices[device]
			mem = cpu.spaces[space]
		end
	end)

	stop_subscription = emu.add_machine_stop_notifier(function()
		local romname = emu.romname()
		local gamename = emu.gamename()
		if romname~="___empty" then        				
			print_result(romname, values)
		end
    end)

	frame = emu.add_machine_frame_notifier(function()
		local romname = emu.romname()
		local gamename = emu.gamename()
		if romname~="___empty" then
			local ok, err = pcall(function()
				values = {}
				for _, field in ipairs(fields) do
					if scores()[romname][field] ~= nil then
						local address = scores()[romname][field].address
						local length = scores()[romname][field].length
						local format = scores()[romname][field].format
						local endian = scores()[romname][field].endian
						local multiplier = scores()[romname][field].multiplier
						local addressing = scores()[romname][field].addressing

						values[field] = get_value(address, length, format, endian, multiplier, addressing)
					end
				end

				local mode = menu.get_print_mode()
				
				if mode == "frame" then
					print_result(romname, values)
				elseif mode == "change" and utils.table_equal(values, values_last) == false then
					print_result(romname, values)
					values_last = values
				end
			end)
		end
	end)
end

return exports
