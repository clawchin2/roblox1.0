-- Utility Functions
local Utils = {}

function Utils.formatNumber(num)
    if num >= 1000000 then
        return string.format("%.1fM", num / 1000000)
    elseif num >= 1000 then
        return string.format("%.1fK", num / 1000)
    end
    return tostring(num)
end

function Utils.lerp(a, b, t)
    return a + (b - a) * t
end

function Utils.randomRange(min, max)
    return min + math.random() * (max - min)
end

function Utils.clamp(val, min, max)
    return math.max(min, math.min(max, val))
end

function Utils.distanceXZ(a, b)
    return math.sqrt((a.X - b.X)^2 + (a.Z - b.Z)^2)
end

return Utils