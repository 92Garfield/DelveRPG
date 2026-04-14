-- DelveRPG: Floating text animation utility
-- Author: Demonperson a.k.a. 92Garfield

DelveRPG = DelveRPG or {}
DelveRPG.FloatingText = {}

local FT = DelveRPG.FloatingText

local FLOAT_DURATION = 1.5
local FLOAT_RISE     = 50
local POOL_SIZE      = 12
local FONT_PATH      = "Fonts\\FRIZQT__.TTF"
local FONT_SIZE      = 14
local FONT_FLAGS     = "OUTLINE"

FT.pool      = {}
FT.poolIndex = 1

-- Pre-allocate a pool of reusable frames so we never leak frames
function FT:InitPool()
    for i = 1, POOL_SIZE do
        local f = CreateFrame("Frame", "DelveRPGFloat" .. i, UIParent)
        f:SetSize(220, 30)
        f:SetFrameStrata("HIGH")
        f:SetFrameLevel(200)
        f:Hide()

        local fs = f:CreateFontString(nil, "OVERLAY")
        fs:SetFont(FONT_PATH, FONT_SIZE, FONT_FLAGS)
        fs:SetAllPoints(f)
        fs:SetJustifyH("CENTER")
        f.label  = fs
        f.ticker = nil

        self.pool[i] = f
    end
end

-- Grab the next frame from the circular pool
function FT:GetFrame()
    local f = self.pool[self.poolIndex]
    self.poolIndex = (self.poolIndex % POOL_SIZE) + 1

    -- Stop any running animation on this slot
    if f.ticker then
        f.ticker:Cancel()
        f.ticker = nil
    end
    f:Hide()

    return f
end

-- Spawn a floating "+value" text that rises and fades from the centre of parent
-- color: { r, g, b }
function FT:Spawn(parent, text, color)
    if not parent then
        return
    end
    if not self.pool[1] then
        self:InitPool()
    end

    color = color or { r = 1, g = 1, b = 1 }

    local f = self:GetFrame()
    f:ClearAllPoints()
    f:SetPoint("CENTER", parent, "CENTER", 0, 0)
    f:SetAlpha(1)
    f:Show()

    f.label:SetText(text)
    f.label:SetTextColor(color.r, color.g, color.b, 1)

    local elapsed = 0

    f.ticker = C_Timer.NewTicker(0.033, function()
        elapsed = elapsed + 0.033
        local t = math.min(elapsed / FLOAT_DURATION, 1)
        local currentY = FLOAT_RISE * t

        f:ClearAllPoints()
        f:SetPoint("CENTER", parent, "CENTER", 0, currentY)
        f:SetAlpha(1 - t)

        if t >= 1 then
            f.ticker:Cancel()
            f.ticker = nil
            f:Hide()
        end
    end)
end
