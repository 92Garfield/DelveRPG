-- DelveRPG: HUD Container
-- Draggable parent frame that stacks CompanionXPBar, BoonDisplay and
-- GoldDisplay vertically.  Position is persisted in AceDB.
-- Author: Demonperson a.k.a. 92Garfield

DelveRPG = DelveRPG or {}
DelveRPG.HUDContainer = {}

local HUD = DelveRPG.HUDContainer

local ELEMENT_GAP = 8  -- vertical pixels between widgets

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

function HUD:Initialize()
    -- Root draggable frame
    self.frame = CreateFrame("Frame", "DelveRPGHUDFrame", UIParent)
    self.frame:SetSize(280, 300)  -- height adjusted after Layout()
    self.frame:SetFrameStrata("MEDIUM")
    self.frame:SetFrameLevel(10)

    self.frame:SetMovable(true)
    self.frame:EnableMouse(true)
    self.frame:RegisterForDrag("LeftButton")

    self.frame:SetScript("OnDragStart", function(f)
        f:StartMoving()
    end)

    self.frame:SetScript("OnDragStop", function(f)
        f:StopMovingOrSizing()
        if DelveRPG.db then
            local _, _, _, xOfs, yOfs = f:GetPoint()
            DelveRPG.db.global.hud.posX = xOfs
            DelveRPG.db.global.hud.posY = yOfs
        end
    end)

    -- Initialise child widgets
    DelveRPG.CompanionXPBar:Initialize(self.frame)
    DelveRPG.BoonDisplay:Initialize(self.frame)
    DelveRPG.GoldDisplay:Initialize(self.frame)

    self:Layout()
    self:ApplySavedPosition()
end

-- Stack widgets top-to-bottom inside the container
function HUD:Layout()
    local curY = 0

    DelveRPG.CompanionXPBar:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -curY)
    curY = curY + DelveRPG.CompanionXPBar:GetHeight() + ELEMENT_GAP

    DelveRPG.BoonDisplay:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -curY)
    curY = curY + DelveRPG.BoonDisplay:GetHeight() + ELEMENT_GAP

    DelveRPG.GoldDisplay:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, -curY)
    curY = curY + DelveRPG.GoldDisplay:GetHeight()

    self.frame:SetHeight(curY)
end

-- Restore saved screen position from AceDB (called after db is ready)
function HUD:ApplySavedPosition()
    if not DelveRPG.db then
        return
    end

    local cfg = DelveRPG.db.global.hud
    self.frame:ClearAllPoints()
    self.frame:SetPoint("CENTER", UIParent, "CENTER", cfg.posX, cfg.posY)
end

--------------------------------------------------------------------------------
-- Visibility
--------------------------------------------------------------------------------

function HUD:Show()
    self.frame:Show()
end

function HUD:Hide()
    self.frame:Hide()
end

function HUD:Toggle()
    if self.frame:IsShown() then
        self:Hide()
    else
        self:Show()
    end
end

function HUD:SetScale(scale)
    self.frame:SetScale(scale)
end

function HUD:IsShown()
    return self.frame:IsShown()
end
