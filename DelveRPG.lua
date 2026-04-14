-- DelveRPG: Main addon file
-- ARPG-style delve HUD – companion XP, boon bonuses, gold gained.
-- Author: Demonperson a.k.a. 92Garfield

-- Global namespace (set early so child files can extend it safely)
DelveRPG = DelveRPG or {}

DelveRPG.version = "1.0.0"

-- Runtime state: tracks whether the player is currently inside a delve.
-- Updated on every zone transition so event handlers can gate cheaply.
DelveRPG.isInDelve = false

--------------------------------------------------------------------------------
-- Initialise
--------------------------------------------------------------------------------

function DelveRPG:Initialize()
    print("DelveRPG v" .. self.version .. " loaded!")

    -- AceDB + options panel (must come first so db is ready)
    self.Options:Initialize()

    -- Build the HUD (reads db.global.hud.pos* for placement)
    self.HUDContainer:Initialize()

    -- Apply saved HUD scale
    local scale = self.db.global.hud.scale or 1.0
    self.HUDContainer:SetScale(scale)

    -- showOnlyInDelves flags
    self:ApplyVisibilityRules()

    -- Initial data population
    self.CompanionXPBar:Refresh()
    self.BoonDisplay:Refresh()
    self.GoldDisplay:Refresh()

    print("> DelveRPG HUD ready.")
end

--------------------------------------------------------------------------------
-- Scenario / delve detection for gold baseline
--------------------------------------------------------------------------------

local function IsInDelve()
    local _, _, difficultyID, _, _, _, _, _, _, _ = GetInstanceInfo()
    -- Delves have difficultyID 208
    return difficultyID == 208
end

--------------------------------------------------------------------------------
-- Visibility rules
-- Called whenever enabled or showOnlyInDelves changes, or on zone transitions.
-- Decides whether the HUD should be visible and whether gameplay events should
-- be processed.
--------------------------------------------------------------------------------

function DelveRPG:ApplyVisibilityRules()
    if not DelveRPG.db then
        return
    end

    local enabled         = DelveRPG.db.global.enabled
    local onlyInDelves    = DelveRPG.db.global.showOnlyInDelves
    local shouldShow      = enabled and (not onlyInDelves or DelveRPG.isInDelve)

    if shouldShow then
        DelveRPG.HUDContainer:Show()
    else
        DelveRPG.HUDContainer:Hide()
    end
end

--------------------------------------------------------------------------------
-- Returns true when gameplay event processing is allowed.
--------------------------------------------------------------------------------

local function EventsAllowed()
    if not DelveRPG.db then
        return false
    end

    if not DelveRPG.db.global.enabled then
        return false
    end

    if DelveRPG.db.global.showOnlyInDelves and not DelveRPG.isInDelve then
        return false
    end

    return true
end

local function OnZoneChanged()
    if not DelveRPG.db then
        return
    end

    local wasInDelve = DelveRPG.isInDelve
    DelveRPG.isInDelve = IsInDelve()

    DelveRPG:ApplyVisibilityRules()

    if DelveRPG.isInDelve and not wasInDelve then
        DelveRPG.BoonDisplay:Reset();
        DelveRPG.GoldDisplay:ResetBaseline()
        DelveRPG.CompanionXPBar:Refresh()
        DelveRPG.CompanionXPBar:ResetDelveXP()
    end
end

--------------------------------------------------------------------------------
-- Event frame
--------------------------------------------------------------------------------

local eventFrame = CreateFrame("Frame")

eventFrame:RegisterEvent("ADDON_LOADED")

eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
eventFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
eventFrame:RegisterEvent("SCENARIO_UPDATE")

eventFrame:RegisterEvent("FACTION_STANDING_CHANGED")
eventFrame:RegisterEvent("UPDATE_FACTION")
eventFrame:RegisterEvent("UNIT_AURA")
eventFrame:RegisterEvent("PLAYER_MONEY")

eventFrame:SetScript("OnEvent", function(_, event, arg1, ...)
    if event == "ADDON_LOADED" then
        if arg1 == "DelveRPG" then
            -- DelveRPG:Initialize()
            -- Data for Companion XP seems not to be loaded immediately
            C_Timer.After(5, function()
                DelveRPG:Initialize()
            end)
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        OnZoneChanged()
    elseif event == "ZONE_CHANGED_NEW_AREA" or event == "SCENARIO_UPDATE" then
        -- print("Event: " .. event)
        OnZoneChanged()
        --apparently the inDelve state doesnt change immediately
        C_Timer.After(1, OnZoneChanged)
    end

    if not EventsAllowed() then
        return
    end

    if event == "FACTION_STANDING_CHANGED" or event == "UPDATE_FACTION" then
        DelveRPG.CompanionXPBar:OnFactionChanged()
    elseif event == "UNIT_AURA" then
        -- arg1 is the unitToken
        if arg1 ~= "player" then
            return
        end

        DelveRPG.BoonDisplay:OnUnitAura()
    elseif event == "PLAYER_MONEY" then
        DelveRPG.GoldDisplay:OnMoneyChanged()
    end
end)

--------------------------------------------------------------------------------
-- Slash commands
--------------------------------------------------------------------------------

SLASH_DELVERPG1 = "/delve"
SLASH_DELVERPG2 = "/drpg"

SlashCmdList["DELVERPG"] = function(msg)
    msg = (msg or ""):lower():trim()

    if msg == "" or msg == "toggle" then
        DelveRPG.HUDContainer:Toggle()

    elseif msg == "show" then
        DelveRPG.HUDContainer:Show()
        print("DelveRPG: HUD shown.")

    elseif msg == "hide" then
        DelveRPG.HUDContainer:Hide()
        print("DelveRPG: HUD hidden.")

    elseif msg == "config" or msg == "options" then
        DelveRPG.Options:Open()

    elseif msg == "reset" or msg == "resetgold" then
        DelveRPG.GoldDisplay:ResetBaseline()
        print("DelveRPG: Gold counter reset.")

    elseif msg == "refresh" then
        DelveRPG.CompanionXPBar:Refresh()
        DelveRPG.BoonDisplay:Refresh()
        DelveRPG.GoldDisplay:Refresh()
        print("DelveRPG: Displays refreshed.")

    elseif msg == "help" then
        print("DelveRPG commands:")
        print("  /drpg          - Toggle HUD")
        print("  /drpg show     - Show HUD")
        print("  /drpg hide     - Hide HUD")
        print("  /drpg config   - Open options panel")
        print("  /drpg reset    - Reset gold counter")
        print("  /drpg refresh  - Force-refresh all displays")
        print("  /drpg help     - This help text")

    else
        print("DelveRPG: Unknown command. Type /drpg help for commands.")
    end
end
