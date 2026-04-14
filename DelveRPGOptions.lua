-- DelveRPG: Options panel
-- Uses AceDB-3.0 for persistence and AceConfig / AceConfigDialog for the UI.
-- Author: Demonperson a.k.a. 92Garfield

DelveRPG = DelveRPG or {}
DelveRPG.Options = {}

local Opts = DelveRPG.Options

--------------------------------------------------------------------------------
-- Defaults
--------------------------------------------------------------------------------

local defaults = {
    global = {
        enabled = true,
        showOnlyInDelves = false,
        hud = {
            posX  = 0,
            posY  = 200,
            scale = 1.0,
        },
        companionFactionId = 2744,
    },
}

-- Expose for other modules
Opts.defaults = defaults

--------------------------------------------------------------------------------
-- AceConfig options table
--------------------------------------------------------------------------------

local options = {
    name    = "DelveRPG",
    handler = Opts,
    type    = "group",
    args    = {
        header = {
            name  = "DelveRPG Settings",
            type  = "header",
            order = 1,
        },
        enabled = {
            name  = "Enable HUD",
            desc  = "Show or hide the DelveRPG HUD overlay",
            type  = "toggle",
            order = 2,
            width = "full",
            get   = function() return DelveRPG.db.global.enabled end,
            set   = function(_, val)
                DelveRPG.db.global.enabled = val
                if val then
                    DelveRPG.HUDContainer:Show()
                else
                    DelveRPG.HUDContainer:Hide()
                end
            end,
        },
        showOnlyInDelves = {
            name  = "Show Only in Delves",
            desc  = "When enabled, the HUD and all event processing are suppressed outside of delves",
            type  = "toggle",
            order = 3,
            width = "full",
            get   = function() return DelveRPG.db.global.showOnlyInDelves end,
            set   = function(_, val)
                DelveRPG.db.global.showOnlyInDelves = val
                DelveRPG:ApplyVisibilityRules()
            end,
        },
        scale = {
            name  = "HUD Scale",
            desc  = "Scale the entire HUD",
            type  = "range",
            order = 4,
            min   = 0.5,
            max   = 2.0,
            step  = 0.05,
            get   = function() return DelveRPG.db.global.hud.scale end,
            set   = function(_, val)
                DelveRPG.db.global.hud.scale = val
                DelveRPG.HUDContainer:SetScale(val)
            end,
        },
        posX = {
            name  = "Position X",
            desc  = "Horizontal offset from screen centre",
            type  = "range",
            order = 5,
            min   = -1000,
            max   = 1000,
            step  = 1,
            get   = function() return DelveRPG.db.global.hud.posX end,
            set   = function(_, val)
                DelveRPG.db.global.hud.posX = val
                DelveRPG.HUDContainer:ApplySavedPosition()
            end,
        },
        posY = {
            name  = "Position Y",
            desc  = "Vertical offset from screen centre",
            type  = "range",
            order = 6,
            min   = -600,
            max   = 600,
            step  = 1,
            get   = function() return DelveRPG.db.global.hud.posY end,
            set   = function(_, val)
                DelveRPG.db.global.hud.posY = val
                DelveRPG.HUDContainer:ApplySavedPosition()
            end,
        },
        companionFactionId = {
            name  = "Companion Faction ID",
            desc  = "Friendship faction ID for the companion XP bar (default 2744 = Brann)",
            type  = "range",
            order = 7,
            min   = 1,
            max   = 9999,
            step  = 1,
            get   = function() return DelveRPG.db.global.companionFactionId end,
            set   = function(_, val)
                DelveRPG.db.global.companionFactionId = val
                DelveRPG.CompanionXPBar:Refresh()
            end,
        },
        resetGold = {
            name  = "Reset Gold Counter",
            desc  = "Resets the gold-gained baseline to now",
            type  = "execute",
            order = 8,
            func  = function()
                DelveRPG.GoldDisplay:ResetBaseline()
                print("DelveRPG: Gold counter reset.")
            end,
        },
    },
}

--------------------------------------------------------------------------------
-- Initialise
--------------------------------------------------------------------------------

function Opts:Initialize()
    -- Set up AceDB
    DelveRPG.db = LibStub("AceDB-3.0"):New("DelveRPGDB", defaults)

    -- Register and attach to Blizzard options
    LibStub("AceConfigRegistry-3.0"):RegisterOptionsTable("DelveRPG", options)
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("DelveRPG", "DelveRPG")
end

function Opts:Open()
    LibStub("AceConfigDialog-3.0"):Open("DelveRPG")
end
