local utils = {}

function utils.byte_to_bcd(value)
    local low = value % 16
    local high = math.floor(value / 16)
    if low > 9 or high > 9 then
        return nil
    end
    return high * 10 + low
end

function utils.byte_to_digit(value)
	return value ~= 0x24 and value % 16 or 0 -- Galaga has 0x24 instead of 0x00
end

function utils.table_equal(a, b)
    for k, v in pairs(a) do
        if type(v) == "table" then
            if type(b[k]) ~= "table"
                or not utils.table_equal(v, b[k]) then
                return false
            end
        elseif b[k] ~= v then
            return false
        end
    end

    for k in pairs(b) do
        if a[k] == nil then
            return false
        end
    end

    return true
end

return utils