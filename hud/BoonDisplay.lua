-- DelveRPG: Boon Display widget
-- Finds the Boons buff (spell 1280098) by iterating helpful auras with
-- C_UnitAuras.GetAuraDataByIndex, then reads its tooltip via
-- C_TooltipInfo.GetUnitAura.  lines[2].leftText is a multi-line string of
-- "StatName: value\r\n" entries that are parsed and displayed in a 2-column
-- grid with integer count-up animation on change.
-- Author: Demonperson a.k.a. 92Garfield

DelveRPG = DelveRPG or {}
DelveRPG.BoonDisplay = {}

local BD = DelveRPG.BoonDisplay

local BOONS_SPELL_ID = 1280098
local MAX_BOON_SLOTS = 8    -- 4 rows × 2 columns

local ROW_HEIGHT    = 19
local ROW_PADDING   = 0
local PANEL_PADDING = 6
local COL_WIDTH     = 134   -- half of 280 minus inner gap
local ANIM_DURATION = 0.5   -- seconds for integer count-up

local FONT_NORMAL = "GameFontNormalLarge"      -- section header
local FONT_SMALL  = "GameFontNormal"           -- row labels and values

local BOON_COLOR  = { r = 0.75, g = 0.5,  b = 1.0 }  -- Purple
local LABEL_COLOR = { r = 1.0,  g = 0.82, b = 0.0 }  -- Gold
local VALUE_COLOR = { r = 1.0,  g = 1.0,  b = 1.0 }
local ZERO_COLOR  = { r = 0.5,  g = 0.5,  b = 0.5 }

-- Slot state: array of pre-allocated UI row pairs
-- slot = { labelFs, valueFs, displayedNum, targetNum, suffix, animTicker, statName }
local slots     = {}
local slotMap   = {}  -- statName -> index in slots[]
local slotCount = 0

--------------------------------------------------------------------------------
-- Value helpers
--------------------------------------------------------------------------------

-- Split a raw value string (e.g. "1,234" or "15%") into (integer, suffix)
local function ParseValue(str)
    if not str then
        return 0, ""
    end
    str = str:match("^%s*(.-)%s*$")  -- trim whitespace
    local numStr = str:match("^[%d,]+")
    if not numStr then
        return 0, str -- fully non-numeric; keep whole string as suffix
    end

    return tonumber(numStr), str:sub(#numStr + 1, #numStr + 1) -- remove any non-numeric chars from suffix
    --local num    = tonumber(numStr:gsub(",", "")) or 0
    --local suffix = str:sub(#numStr + 1)
    --return math.floor(num), suffix
end

-- Build the display string for a value slot
local function FormatSlotValue(num, suffix)
    return tostring(num) .. (suffix or "")
end

--------------------------------------------------------------------------------
-- Aura lookup and tooltip parsing
--------------------------------------------------------------------------------

-- Return the positional aura index (1-based) of the Boons buff, or nil
local function FindBoonsAuraIndex()
    local i = 1
    while true do
        local auraData = C_UnitAuras.GetAuraDataByIndex("player", i, "HELPFUL")
        if not auraData then
            break
        end

        if (issecretvalue(auraData.spellId)) then
            -- can't do anything
            return nil
        end

        if auraData.spellId == BOONS_SPELL_ID then
            return i
        end
        i = i + 1
    end
    return nil
end

-- Parse the Boons tooltip and return an ordered array of
-- { name = "Maximum Health", num = 1234, suffix = "" }
local PARSE_BOON_QUEUED = false
local function ParseBoonsTooltip(depth)
    if not depth then
        depth = 0
    elseif depth > 9 then
        -- Prevent infinite recursion if something goes wrong with tooltip parsing
        return nil
    end

    local auraIndex = FindBoonsAuraIndex()
    if not auraIndex then
        if not PARSE_BOON_QUEUED then
            PARSE_BOON_QUEUED = true
            C_Timer.After(0.5, function()
                PARSE_BOON_QUEUED = false
                ParseBoonsTooltip(depth + 1)
            end)
        end
        return nil
    end

    local tooltipData = C_TooltipInfo.GetUnitAura("player", auraIndex, "HELPFUL")
    if not tooltipData or not tooltipData.lines or not tooltipData.lines[2] then
        return nil
    end

    local text = tooltipData.lines[2].leftText
    if not text or text == "" then
        return nil
    end

    local nameReplace = {
        ["Maximum Health"] = "Max HP",
        ["Agility"]       = "Main Stat",
        ["Strength"]       = "Main Stat",
        ["Intellect"]      = "Main Stat",
        ["Critical Strike"] = "Critical Strike",
        ["Haste"]          = "Haste",
        ["Mastery"]        = "Mastery",
        ["Versatility"]     = "Versatility",
        ["Movement Speed"]  = "Move Speed",
        ["Damage Reduction"] = "Dmg. Red.",
    }

    local entries = {}
    -- Split on \r\n, \r, or \n — handle all common line-ending styles
    for line in text:gmatch("[^\r\n]+") do
        local statName, valueStr = line:match("^%s*(.-)%s*:%s*(.-)%s*$")
        if statName and valueStr and statName ~= "" and valueStr ~= "" then
            if (nameReplace[statName]) then
                statName = nameReplace[statName]
            end

            local num, suffix = ParseValue(valueStr)
            table.insert(entries, { name = statName, num = num, suffix = suffix })
        end
    end

    return entries
end

--------------------------------------------------------------------------------
-- Count-up animation for a single slot
--------------------------------------------------------------------------------

local function StartCountUp(slot, fromNum, toNum)
    if slot.animTicker then
        slot.animTicker:Cancel()
        slot.animTicker = nil
    end

    if fromNum == toNum then
        return
    end

    local elapsed = 0
    local range   = toNum - fromNum

    slot.animTicker = C_Timer.NewTicker(0.033, function()
        elapsed = elapsed + 0.033
        local t     = math.min(elapsed / ANIM_DURATION, 1)
        local value = math.floor(fromNum + range * t)

        slot.displayedNum = value

        if value > 0 then
            slot.valueFs:SetTextColor(VALUE_COLOR.r, VALUE_COLOR.g, VALUE_COLOR.b, 1)
        else
            slot.valueFs:SetTextColor(ZERO_COLOR.r, ZERO_COLOR.g, ZERO_COLOR.b, 1)
        end
        slot.valueFs:SetText(FormatSlotValue(value, slot.suffix))

        if t >= 1 then
            slot.animTicker:Cancel()
            slot.animTicker = nil
            slot.displayedNum = toNum
            slot.valueFs:SetText(FormatSlotValue(toNum, slot.suffix))
        end
    end)
end

--------------------------------------------------------------------------------
-- Slot management
--------------------------------------------------------------------------------

-- Return the slot for a stat name, assigning a new one if first seen
local function GetOrAssignSlot(statName)
    local idx = slotMap[statName]
    if idx then
        return slots[idx]
    end

    slotCount = slotCount + 1
    if slotCount > MAX_BOON_SLOTS then
        return nil
    end

    local slot = slots[slotCount]
    slot.statName = statName
    slot.labelFs:SetText(statName)
    slotMap[statName] = slotCount
    return slot
end

--------------------------------------------------------------------------------
-- Construction
--------------------------------------------------------------------------------

-- Header-only height used when no boon rows are visible
local HEADER_HEIGHT = 28

function BD:Initialize(parent)
    -- Outer frame – height is dynamic; start at header-only size
    self.frame = CreateFrame("Frame", nil, parent)
    self.frame:SetSize(280, HEADER_HEIGHT)

    -- Background
    self.bg = self.frame:CreateTexture(nil, "BACKGROUND")
    self.bg:SetAllPoints(self.frame)
    self.bg:SetColorTexture(0, 0, 0, 0.55)

    -- Header label
    self.header = self.frame:CreateFontString(nil, "OVERLAY", FONT_NORMAL)
    self.header:SetPoint("TOPLEFT", self.frame, "TOPLEFT", PANEL_PADDING, -PANEL_PADDING)
    self.header:SetTextColor(LABEL_COLOR.r, LABEL_COLOR.g, LABEL_COLOR.b, 1)
    self.header:SetText("Boons")

    -- Accent line under header
    self.line = self.frame:CreateTexture(nil, "ARTWORK")
    self.line:SetPoint("TOPLEFT",  self.frame, "TOPLEFT",  PANEL_PADDING,  -20)
    self.line:SetPoint("TOPRIGHT", self.frame, "TOPRIGHT", -PANEL_PADDING, -20)
    self.line:SetHeight(1)
    self.line:SetColorTexture(BOON_COLOR.r, BOON_COLOR.g, BOON_COLOR.b, 0.6)

    -- Pre-allocate all slots; stat names are filled in on first tooltip parse
    slots     = {}
    slotMap   = {}
    slotCount = 0

    for i = 1, MAX_BOON_SLOTS do
        local col    = (i - 1) % 2
        local rowIdx = math.ceil(i / 2)
        local x = PANEL_PADDING + col * COL_WIDTH
        local y = -(PANEL_PADDING + 22 + (rowIdx - 1) * (ROW_HEIGHT + ROW_PADDING))

        local labelFs = self.frame:CreateFontString(nil, "OVERLAY", FONT_SMALL)
        labelFs:SetPoint("TOPLEFT", self.frame, "TOPLEFT", x, y)
        labelFs:SetWidth(COL_WIDTH - 36)
        labelFs:SetJustifyH("LEFT")
        labelFs:SetTextColor(BOON_COLOR.r, BOON_COLOR.g, BOON_COLOR.b, 1)
        labelFs:SetText("")

        local valueFs = self.frame:CreateFontString(nil, "OVERLAY", FONT_SMALL)
        valueFs:SetPoint("TOPRIGHT", self.frame, "TOPLEFT", x + COL_WIDTH - 10, y)
        valueFs:SetWidth(36)
        valueFs:SetJustifyH("RIGHT")
        valueFs:SetTextColor(ZERO_COLOR.r, ZERO_COLOR.g, ZERO_COLOR.b, 1)
        valueFs:SetText("")

        slots[i] = {
            statName     = nil,
            labelFs      = labelFs,
            valueFs      = valueFs,
            displayedNum = 0,
            targetNum    = 0,
            suffix       = "",
            animTicker   = nil,
        }

        -- Hidden until a non-zero value is assigned
        labelFs:Hide()
        valueFs:Hide()
    end
end

--------------------------------------------------------------------------------
-- Dynamic layout – called after every data change
-- Re-packs only the non-zero slots into the 2-column grid and resizes the frame.
--------------------------------------------------------------------------------

local function RedrawLayout()
    if not BD.frame then
        return
    end

    -- Collect slots that have a non-zero target value
    local visible = {}
    for i = 1, slotCount do
        local slot = slots[i]
        if slot.targetNum > 0 then
            table.insert(visible, slot)
        end
    end

    -- First hide every pre-allocated row
    for i = 1, MAX_BOON_SLOTS do
        slots[i].labelFs:Hide()
        slots[i].valueFs:Hide()
    end

    -- Reposition and show only the visible rows
    for i, slot in ipairs(visible) do
        local col    = (i - 1) % 2
        local rowIdx = math.ceil(i / 2)
        local x = PANEL_PADDING + col * COL_WIDTH
        local y = -(PANEL_PADDING + 22 + (rowIdx - 1) * (ROW_HEIGHT + ROW_PADDING))

        slot.labelFs:ClearAllPoints()
        slot.labelFs:SetPoint("TOPLEFT", BD.frame, "TOPLEFT", x, y)
        slot.valueFs:ClearAllPoints()
        slot.valueFs:SetPoint("TOPRIGHT", BD.frame, "TOPLEFT", x + COL_WIDTH - 10, y)
        slot.labelFs:Show()
        slot.valueFs:Show()
    end

    -- Resize the frame to fit exactly the visible rows (or just the header)
    local newH
    if #visible == 0 then
        newH = HEADER_HEIGHT
    else
        local rowCount = math.ceil(#visible / 2)
        local contentH = rowCount * ROW_HEIGHT + (rowCount - 1) * ROW_PADDING
        newH = contentH + PANEL_PADDING * 2 + 22
    end
    BD.frame:SetHeight(newH)

    -- Re-stack all HUD widgets so nothing overlaps
    if DelveRPG.HUDContainer and DelveRPG.HUDContainer.frame then
        DelveRPG.HUDContainer:Layout()
    end
end

--------------------------------------------------------------------------------
-- Data updates
--------------------------------------------------------------------------------

-- Silent refresh: populate current values without animation (used at login)
function BD:Refresh()
    local entries = ParseBoonsTooltip()
    if not entries then
        return
    end

    for _, entry in ipairs(entries) do
        local slot = GetOrAssignSlot(entry.name)
        if slot then
            slot.suffix       = entry.suffix
            slot.displayedNum = entry.num
            slot.targetNum    = entry.num
            slot.valueFs:SetText(FormatSlotValue(entry.num, entry.suffix))
            if entry.num > 0 then
                slot.valueFs:SetTextColor(VALUE_COLOR.r, VALUE_COLOR.g, VALUE_COLOR.b, 1)
            else
                slot.valueFs:SetTextColor(ZERO_COLOR.r, ZERO_COLOR.g, ZERO_COLOR.b, 1)
            end
        end
    end

    RedrawLayout()
end

-- Called on UNIT_AURA for "player"
function BD:OnUnitAura()
    local entries = ParseBoonsTooltip()
    if not entries then
        return
    end

    for _, entry in ipairs(entries) do
        local slot = GetOrAssignSlot(entry.name)
        if slot then
            slot.suffix = entry.suffix
            local newNum = entry.num

            if newNum ~= slot.targetNum then
                local gain = newNum - slot.targetNum
                local from = slot.displayedNum
                slot.targetNum = newNum
                StartCountUp(slot, from, newNum)

                if gain > 0 then
                    DelveRPG.FloatingText:Spawn(
                        self.frame,
                        "+" .. tostring(gain) .. entry.suffix,
                        BOON_COLOR
                    )
                end
            end
        end
    end

    RedrawLayout()
end

--------------------------------------------------------------------------------
-- Layout helpers
--------------------------------------------------------------------------------

function BD:SetPoint(...)
    self.frame:SetPoint(...)
end

function BD:GetHeight()
    return self.frame:GetHeight()
end

function BD:Show()
    self.frame:Show()
end

function BD:Hide()
    self.frame:Hide()
end

function BD:Reset()
    -- Clear all slots and hide them
    for i = 1, slotCount do
        local slot = slots[i]
        slot.statName     = nil
        slot.displayedNum = 0
        slot.targetNum    = 0
        slot.suffix       = ""
        if slot.animTicker then
            slot.animTicker:Cancel()
            slot.animTicker = nil
        end
        slot.labelFs:SetText("")
        slot.valueFs:SetText("")
        slot.labelFs:Hide()
        slot.valueFs:Hide()
    end
    slotMap = {}
    slotCount = 0

    RedrawLayout()
end