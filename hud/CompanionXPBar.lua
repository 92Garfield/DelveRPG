-- DelveRPG: Companion XP Bar widget
-- Tracks Valeera Sanguinar (faction 2744) friendship progression.
-- Displays a status bar for the current level's XP progress with
-- animated fill and a floating "+XP" label on gain.
-- Author: Demonperson a.k.a. 92Garfield

DelveRPG = DelveRPG or {}
DelveRPG.CompanionXPBar = {}

local XPBar = DelveRPG.CompanionXPBar

local DEFAULT_FACTION_ID = 2744

-- Returns the faction ID to use – prefers the saved setting when DB is ready
local function GetFactionId()
    if DelveRPG.db and DelveRPG.db.global.companionFactionId then
        return DelveRPG.db.global.companionFactionId
    end
    return DEFAULT_FACTION_ID
end

local NAME_ROW_H    = 16   -- height of the companion name row
local LEVEL_ROW_H   = 18   -- height of the level / fraction row
local BAR_HEIGHT    = 22   -- status bar height
local DELVE_ROW_H   = 16   -- height of the "XP this delve" row
local FRAME_HEIGHT  = NAME_ROW_H + LEVEL_ROW_H + BAR_HEIGHT + DELVE_ROW_H  -- 72

local FONT_NORMAL   = "GameFontNormalLarge"       -- level label
local FONT_SMALL    = "GameFontNormal"  -- name, xp fraction, delve xp

local ANIM_DURATION = 0.75
local XP_COLOR      = { r = 0.4,  g = 0.85, b = 1.0 }  -- Cyan
local LABEL_COLOR   = { r = 1.0,  g = 0.82, b = 0.0 }  -- Gold
local SUB_COLOR     = { r = 0.7,  g = 0.7,  b = 0.7 }  -- Grey
local DIM_COLOR     = { r = 0.55, g = 0.55, b = 0.55 }  -- Dimmer grey for name

-- Module state
local lastStanding       = nil
local delveStartStanding = nil   -- standing when the current delve began
local displayedBarValue  = 0
local animTicker         = nil

--------------------------------------------------------------------------------
-- Helpers
--------------------------------------------------------------------------------

-- Query current friendship data; returns nil if unavailable
local function QueryXP()
    return C_GossipInfo.GetFriendshipReputation(GetFactionId())
end

-- Compute in-level values from a reputation info struct
local function ComputeLevelProgress(info)
    local standing   = info.standing          or 0
    local threshold  = info.reactionThreshold or 0
    local nextThresh = info.nextThreshold
    local levelMax   = nextThresh and (nextThresh - threshold) or 1
    local levelCur   = standing - threshold
    return levelCur, math.max(levelMax, 1)
end

--------------------------------------------------------------------------------
-- Animation
--------------------------------------------------------------------------------

function XPBar:StartFillAnim(fromVal, toVal)
    if animTicker then
        animTicker:Cancel()
        animTicker = nil
    end

    local elapsed = 0

    animTicker = C_Timer.NewTicker(0.033, function()
        elapsed = elapsed + 0.033
        local t     = math.min(elapsed / ANIM_DURATION, 1)
        local eased = DelveRPG.Utils.EaseOut(t)
        local value = fromVal + (toVal - fromVal) * eased

        self.bar:SetValue(value)
        displayedBarValue = value

        if t >= 1 then
            animTicker:Cancel()
            animTicker = nil
            self.bar:SetValue(toVal)
            displayedBarValue = toVal
        end
    end)
end

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

function XPBar:Initialize(parent)
    -- Outer frame  (4 rows: name / level+fraction / bar / delve xp)
    self.frame = CreateFrame("Frame", nil, parent)
    self.frame:SetSize(280, FRAME_HEIGHT)

    -- Row 1: Companion name (dimmed, small)
    self.nameLabel = self.frame:CreateFontString(nil, "OVERLAY", FONT_SMALL)
    self.nameLabel:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 2, 0)
    self.nameLabel:SetTextColor(DIM_COLOR.r, DIM_COLOR.g, DIM_COLOR.b, 1)
    self.nameLabel:SetText("")

    -- Row 2: Level label (left) + XP fraction (right)
    self.levelLabel = self.frame:CreateFontString(nil, "OVERLAY", FONT_NORMAL)
    self.levelLabel:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 2, -NAME_ROW_H)
    self.levelLabel:SetTextColor(LABEL_COLOR.r, LABEL_COLOR.g, LABEL_COLOR.b, 1)
    self.levelLabel:SetText("Companion")

    self.xpLabel = self.frame:CreateFontString(nil, "OVERLAY", FONT_SMALL)
    self.xpLabel:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -2, -NAME_ROW_H)
    self.xpLabel:SetTextColor(SUB_COLOR.r, SUB_COLOR.g, SUB_COLOR.b, 1)
    self.xpLabel:SetText("-- / --")

    -- Row 3: Status bar (sits between level row and delve-xp row)
    local barOffsetFromTop = NAME_ROW_H + LEVEL_ROW_H

    self.bg = self.frame:CreateTexture(nil, "BACKGROUND")
    self.bg:SetPoint("TOPLEFT",  self.frame, "TOPLEFT",  0, -barOffsetFromTop)
    self.bg:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, -barOffsetFromTop)
    self.bg:SetHeight(BAR_HEIGHT)
    self.bg:SetColorTexture(0, 0, 0, 0.65)

    self.bar = CreateFrame("StatusBar", nil, self.frame)
    self.bar:SetPoint("TOPLEFT",  self.frame, "TOPLEFT",  0, -barOffsetFromTop)
    self.bar:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", 0, -barOffsetFromTop)
    self.bar:SetHeight(BAR_HEIGHT)
    self.bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    self.bar:SetStatusBarColor(XP_COLOR.r, XP_COLOR.g, XP_COLOR.b, 0.85)
    self.bar:SetMinMaxValues(0, 1)
    self.bar:SetValue(0)

    -- Shine line on top of bar
    self.shine = self.bar:CreateTexture(nil, "OVERLAY")
    self.shine:SetPoint("TOPLEFT",  self.bar, "TOPLEFT",  0, -1)
    self.shine:SetPoint("TOPRIGHT", self.bar, "TOPRIGHT", 0, -1)
    self.shine:SetHeight(2)
    self.shine:SetColorTexture(1, 1, 1, 0.15)

    -- Row 4: XP gained this delve (bottom-right, small)
    self.delveXpLabel = self.frame:CreateFontString(nil, "OVERLAY", FONT_SMALL)
    self.delveXpLabel:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -2, 0)
    self.delveXpLabel:SetTextColor(XP_COLOR.r, XP_COLOR.g, XP_COLOR.b, 0.8)
    self.delveXpLabel:SetText("")

    self:Refresh()
end

--------------------------------------------------------------------------------
-- Data updates
--------------------------------------------------------------------------------

-- Full silent refresh (no animation, used at login)
function XPBar:Refresh()
    local info = QueryXP()
    if not info then
        return
    end

    local levelCur, levelMax = ComputeLevelProgress(info)
    self.bar:SetMinMaxValues(0, levelMax)
    self.bar:SetValue(levelCur)
    displayedBarValue = levelCur
    lastStanding      = info.standing

    self.nameLabel:SetText(info.name or "")
    self.levelLabel:SetText(info.reaction or "Companion")
    self.xpLabel:SetText(
        DelveRPG.Utils.FormatNumber(levelCur) .. " / " ..
        DelveRPG.Utils.FormatNumber(levelMax)
    )
    self:UpdateDelveXPLabel(info.standing)
end

-- Update the "XP gained this delve" label
function XPBar:UpdateDelveXPLabel(standing)
    if delveStartStanding and standing then
        local gained = standing - delveStartStanding
        if gained > 0 then
            self.delveXpLabel:SetText("+" .. DelveRPG.Utils.FormatNumber(gained) .. " XP this delve")
        else
            self.delveXpLabel:SetText("")
        end
    else
        self.delveXpLabel:SetText("")
    end
end

-- Reset the delve XP counter (called when entering a new delve)
function XPBar:ResetDelveXP()
    local info = QueryXP()
    if info then
        delveStartStanding = info.standing
    else
        delveStartStanding = nil
    end
    self:UpdateDelveXPLabel(info and info.standing)
end

-- Called on FACTION_STANDING_CHANGED / UPDATE_FACTION
function XPBar:OnFactionChanged()
    local info = QueryXP()
    if not info then
        return
    end

    local levelCur, levelMax = ComputeLevelProgress(info)
    local standing           = info.standing or 0

    self.bar:SetMinMaxValues(0, levelMax)
    self.nameLabel:SetText(info.name or "")
    self.levelLabel:SetText(info.reaction or "Companion")
    self.xpLabel:SetText(
        DelveRPG.Utils.FormatNumber(levelCur) .. " / " ..
        DelveRPG.Utils.FormatNumber(levelMax)
    )
    self:UpdateDelveXPLabel(standing)

    if lastStanding and standing > lastStanding then
        local gain = standing - lastStanding
        self:StartFillAnim(displayedBarValue, levelCur)
        DelveRPG.FloatingText:Spawn(
            self.frame,
            "+" .. DelveRPG.Utils.FormatNumber(gain) .. " XP",
            XP_COLOR
        )
    else
        -- Level up or silent update: snap immediately
        self.bar:SetValue(levelCur)
        displayedBarValue = levelCur
    end

    lastStanding = standing
end

--------------------------------------------------------------------------------
-- Layout helpers (called by HUDContainer)
--------------------------------------------------------------------------------

function XPBar:SetPoint(...)
    self.frame:SetPoint(...)
end

function XPBar:GetHeight()
    return self.frame:GetHeight()
end

function XPBar:Show()
    self.frame:Show()
end

function XPBar:Hide()
    self.frame:Hide()
end
