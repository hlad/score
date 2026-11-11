local exports = {
    name = "score",
    version = "0.1",
    description = "Reads configured score memory locations and prints the score at game end.",
    license = "MIT",
    author = { name = "hlad" }
}	

local score = exports

local plugin_path = ""

local scores = {}

local score_val = 0

local cpu, mem

local menu

function score.set_folder(path)
    plugin_path = path
end

local function byte_to_bcd(value)
    local low = value % 16
    local high = math.floor(value / 16)
    if low > 9 or high > 9 then
        return nil
    end
    return high * 10 + low
end

local function get_score(romname, start, length, format, endian, multiplier)
	local i_start, i_end, increment

	local score_val = 0

	local x = 0

	if endian == "little" then
		i_start = start + length -1
		i_end = start
		increment = -1
	else
		i_start = start
		i_end = start + length -1
		increment = 1
	end

	for i = i_start, i_end, increment
	do
		score_val = score_val + (byte_to_bcd(mem:read_u8(i)) *(100^x) | 0)		
		x = x + 1
	end

	if multiplier==nil then
		multiplier=1
	end

	return score_val * multiplier
end

function score.startplugin()
	menu = dofile(plugin_path .. "/menu.lua")
	menu.start()

	scores, err = loadfile(plugin_path .. "/scores.lua")		

	reset_subscription = emu.add_machine_reset_notifier(function ()
		local romname = emu.romname()
		local gamename = emu.gamename()
		if romname~="___empty" and scores()[romname]~=nil then
			device = scores()[romname].device == nil and ":maincpu" or scores()[romname].device
			space = scores()[romname].space == nil and "program" or scores()[romname].space
			score_val = 0
			cpu = manager.machine.devices[device]
			mem = cpu.spaces[space]
		end
	end)

	stop_subscription = emu.add_machine_stop_notifier(function()
		local romname = emu.romname()
		local gamename = emu.gamename()
		if romname~="___empty" then        				
			emu.print_info(string.format(
				'MAME_SCORE: {"game":"%s","score":%d}',				
			romname, score_val))
		end
    end)

	frame = emu.add_machine_frame_notifier(function()
		local romname = emu.romname()
		local gamename = emu.gamename()
		if romname~="___empty" then
			local ok, err = pcall(function()
				local address = scores()[romname].address
				local length = scores()[romname].length
				local format = scores()[romname].format
				local endian = scores()[romname].endian
				local multiplier = scores()[romname].multiplier

				score_val = get_score(romname, address, length, format, endian, multiplier)	

				if menu.get_print_every_frame() then
					emu.print_info(string.format('MAME_SCORE: {"game":"%s","score":%d}', romname, score_val))
				end
			end)
		end
	end)

end

return exports
