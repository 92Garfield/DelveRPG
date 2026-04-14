-- DelveRPG: Gold Display widget
-- Tracks total gold gained since entering the current delve (scenario instance).
-- Resets baseline when a new scenario is entered.  Provides a manual reset via
-- DelveRPG.GoldDisplay:ResetBaseline().
-- Author: Demonperson a.k.a. 92Garfield

DelveRPG = DelveRPG or {}
DelveRPG.GoldDisplay = {}

local GD = DelveRPG.GoldDisplay

local ROW_HEIGHT    = 28
local ANIM_DURATION = 0.5
local FONT_NORMAL   = "GameFontNormal"  -- label and value text
local GOLD_COLOR    = { r = 1.0,  g = 0.82, b = 0.0 }
local VALUE_COLOR   = { r = 1.0,  g = 1.0,  b = 1.0 }

-- Module state
local baselineMoney  = 0
local displayedGain  = 0  -- copper value currently shown
local targetGain     = 0
local animTicker     = nil

--------------------------------------------------------------------------------
-- Animation
--------------------------------------------------------------------------------

local function StartCountUp(from, to)
    if animTicker then
        animTicker:Cancel()
        animTicker = nil
    end

    if from == to then
        return
    end

    local elapsed = 0
    local range   = to - from

    animTicker = C_Timer.NewTicker(0.033, function()
        elapsed = elapsed + 0.033
        local t     = math.min(elapsed / ANIM_DURATION, 1)
        local value = math.floor(from + range * t)

        displayedGain = value
        GD.valueText:SetText(DelveRPG.Utils.FormatGold(value))

        if t >= 1 then
            animTicker:Cancel()
            animTicker = nil
            displayedGain = to
            GD.valueText:SetText(DelveRPG.Utils.FormatGold(to))
        end
    end)
end

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

function GD:Initialize(parent)
    -- Outer frame
    self.frame = CreateFrame("Frame", nil, parent)
    self.frame:SetSize(280, ROW_HEIGHT)

    -- Background
    self.bg = self.frame:CreateTexture(nil, "BACKGROUND")
    self.bg:SetAllPoints(self.frame)
    self.bg:SetColorTexture(0, 0, 0, 0.55)

    -- Gold coin icon
    self.icon = self.frame:CreateTexture(nil, "ARTWORK")
    self.icon:SetSize(20, 20)
    self.icon:SetPoint("LEFT", self.frame, "LEFT", 5, 0)
    self.icon:SetTexture("Interface\\MoneyFrame\\UI-GoldIcon")

    -- Label
    self.labelText = self.frame:CreateFontString(nil, "OVERLAY", FONT_NORMAL)
    self.labelText:SetPoint("LEFT", self.icon, "RIGHT", 5, 0)
    self.labelText:SetTextColor(GOLD_COLOR.r, GOLD_COLOR.g, GOLD_COLOR.b, 1)
    self.labelText:SetText("Gold Gained")

    -- Value (right-aligned)
    self.valueText = self.frame:CreateFontString(nil, "OVERLAY", FONT_NORMAL)
    self.valueText:SetPoint("RIGHT", self.frame, "RIGHT", -6, 0)
    self.valueText:SetTextColor(VALUE_COLOR.r, VALUE_COLOR.g, VALUE_COLOR.b, 1)
    self.valueText:SetText("0c")

    baselineMoney = GetMoney()
    displayedGain = 0
    targetGain    = 0
end

--------------------------------------------------------------------------------
-- Data updates
--------------------------------------------------------------------------------

-- Reset the gold counter (called on scenario enter or by command)
function GD:ResetBaseline()
    baselineMoney = GetMoney()
    displayedGain = 0
    targetGain    = 0
    if animTicker then
        animTicker:Cancel()
        animTicker = nil
    end
    self.valueText:SetText("0c")
end

-- Called on PLAYER_MONEY event
function GD:OnMoneyChanged()
    local currentMoney = GetMoney()
    local gained       = math.max(0, currentMoney - baselineMoney)

    if gained > targetGain then
        local gain = gained - targetGain
        local from = displayedGain
        targetGain = gained
        StartCountUp(from, gained)

        DelveRPG.FloatingText:Spawn(
            self.frame,
            "+" .. DelveRPG.Utils.FormatGoldPlain(gain),
            GOLD_COLOR
        )
    end
end

-- Silent refresh (in case baseline drifted from a reload)
function GD:Refresh()
    local currentMoney = GetMoney()
    local gained       = math.max(0, currentMoney - baselineMoney)
    displayedGain = gained
    targetGain    = gained
    self.valueText:SetText(DelveRPG.Utils.FormatGold(gained))
end

--------------------------------------------------------------------------------
-- Layout helpers
--------------------------------------------------------------------------------

function GD:SetPoint(...)
    self.frame:SetPoint(...)
end

function GD:GetHeight()
    return self.frame:GetHeight()
end

function GD:Show()
    self.frame:Show()
end

function GD:Hide()
    self.frame:Hide()
end
