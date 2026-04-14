-- DelveRPG: Utility functions
-- Author: Demonperson a.k.a. 92Garfield

DelveRPG = DelveRPG or {}
DelveRPG.Utils = {}

local Utils = DelveRPG.Utils

-- Format copper amount to coloured gold/silver/copper string
function Utils.FormatGold(copper)
    if not copper or copper <= 0 then
        return "0c"
    end
    local gold   = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop    = copper % 100
    if gold > 0 then
        return string.format("|cffffd700%dg|r |cffc0c0c0%ds|r |cffb87333%dc|r", gold, silver, cop)
    elseif silver > 0 then
        return string.format("|cffc0c0c0%ds|r |cffb87333%dc|r", silver, cop)
    else
        return string.format("|cffb87333%dc|r", cop)
    end
end

-- Format copper as plain text for popup labels
function Utils.FormatGoldPlain(copper)
    if not copper or copper <= 0 then
        return "0c"
    end
    local gold   = math.floor(copper / 10000)
    local silver = math.floor((copper % 10000) / 100)
    local cop    = copper % 100
    if gold > 0 then
        return string.format("%dg %ds %dc", gold, silver, cop)
    elseif silver > 0 then
        return string.format("%ds %dc", silver, cop)
    else
        return string.format("%dc", cop)
    end
end

-- Format large integers with K/M abbreviation
function Utils.FormatNumber(n)
    if not n then
        return "0"
    end
    n = math.floor(n)
    if n >= 1000000 then
        return string.format("%.1fM", n / 1000000)
    elseif n >= 1000 then
        return string.format("%.1fK", n / 1000)
    else
        return tostring(n)
    end
end

-- Ease-out quadratic interpolation (t in [0,1])
function Utils.EaseOut(t)
    return 1 - (1 - t) * (1 - t)
end

-- Clamp a value between min and max
function Utils.Clamp(value, minVal, maxVal)
    if value < minVal then
        return minVal
    elseif value > maxVal then
        return maxVal
    end
    return value
end
