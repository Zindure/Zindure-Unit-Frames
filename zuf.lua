local addonName = "Zindure's Unit Frames"
local LSM = LibStub("LibSharedMedia-3.0")

-- Register custom media
LSM:Register("statusbar", "Smooth", "Interface\\AddOns\\zindure-unit-frames\\media\\ElvUI2.tga")
LSM:Register("font", "MyFont", "Interface\\AddOns\\zindure-unit-frames\\media\\Arial.ttf")

--[[ -- Variables for frame settings
frameSettings = {
    isMovable = false,
    layout = "vertical", -- "vertical" or "horizontal"
    frameWidth = 150,
    frameHeight = 25,
    baseX = 30, -- Base X offset
    baseY = -40, -- Base Y offset
} ]]

local testMode = false
local testFrames = {}

local EFFECT_SPELLIDS = {}

local powerBarHeight = 6 -- or 8, or any pixel value you want for the power bar height

-- Ensure this is at the very top:
local function EnsureSavedVariables()
    if ZUF_Settings.frameSettings == nil then
        ZUF_Settings.frameSettings = {
            isMovable = false,
            layout = "vertical",
            frameWidth = 150,
            frameHeight = 25,
            baseX = 30,
            baseY = -40,
        }
    end
end

local function CopyTable(tbl)
    local copy = {}
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            copy[k] = CopyTable(v)
        else
            copy[k] = v
        end
    end
    return copy
end

-- Test unit frames table
local partyFrames = {}

-- Hidden frame for managing visibility
local hiddenFrame = CreateFrame("Frame")
hiddenFrame:Hide()

-- Smart hiding function: only runs logic if frames are actually visible
local function HideBlizzardFrames()
    -- Avoid re-running the function if it's already running
    if isChecking then return end
    isChecking = true

    if not IsInRaid() then
        -- Hide old-style party frames if they are shown
        for i = 1, 4 do
            local frame = _G["PartyMemberFrame" .. i]
            if frame and frame:IsShown() then
                frame:UnregisterAllEvents()
                frame:SetParent(hiddenFrame)
                frame:Hide()
            end
        end
        -- Hide new-style compact party frame if it is shown
        if CompactPartyFrame and CompactPartyFrame:IsShown() then
            CompactPartyFrame:UnregisterAllEvents()
            CompactPartyFrame:SetParent(hiddenFrame)
            CompactPartyFrame:Hide()
        end
        -- Hide raid-style party frames (CompactRaidFrameManager and Container)
        if CompactRaidFrameManager then
            CompactRaidFrameManager:UnregisterAllEvents()
            CompactRaidFrameManager:SetParent(hiddenFrame)
            CompactRaidFrameManager:Hide()
        end
        if CompactRaidFrameContainer then
            CompactRaidFrameContainer:UnregisterAllEvents()
            CompactRaidFrameContainer:SetParent(hiddenFrame)
            CompactRaidFrameContainer:Hide()
        end
    else
        -- In a raid: restore Blizzard raid frames
        if CompactRaidFrameManager then
            CompactRaidFrameManager:SetParent(UIParent)
            CompactRaidFrameManager:Show()
            CompactRaidFrameManager:RegisterEvent("GROUP_ROSTER_UPDATE")
            CompactRaidFrameManager:RegisterEvent("PLAYER_ENTERING_WORLD")
            -- Add any other events you want to restore
        end
        if CompactRaidFrameContainer then
            CompactRaidFrameContainer:SetParent(UIParent)
            CompactRaidFrameContainer:Show()
        end
    end

    isChecking = false
end

local function UpdateFramePositions()

    for i, frame in ipairs(partyFrames) do
        frame:ClearAllPoints()
        if frameSettings.layout == "vertical" then
            if i == 1 then
                frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", frameSettings.baseX, frameSettings.baseY)
            else
                frame:SetPoint("TOPLEFT", partyFrames[i - 1], "BOTTOMLEFT", 0, -10)
            end
        else
            if i == 1 then
                frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", frameSettings.baseX, frameSettings.baseY)
            else
                frame:SetPoint("TOPLEFT", partyFrames[i - 1], "TOPRIGHT", 10, 0)
            end
        end
        frame:SetSize(frameSettings.frameWidth, frameSettings.frameHeight)
        -- Update health and power bar heights
        frame.healthBar:SetHeight(frameSettings.frameHeight - powerBarHeight)
        frame.powerBar:SetHeight(powerBarHeight)
    end
end

-- Create one unit frame
local function CreateUnitFrame(unit, index)
    local frame = CreateFrame("Button", "CF_UnitFrame"..index, UIParent, "SecureUnitButtonTemplate")
    frame:SetSize(frameSettings.frameWidth, frameSettings.frameHeight)

    if index > 1 then
        frame:SetPoint("TOPLEFT", partyFrames[index - 1], "BOTTOMLEFT", 0, -10)
    else
        frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", frameSettings.baseX, frameSettings.baseY)

        -- Add drag functionality for the first frame
        frame:EnableMouse(true)
        frame:SetMovable(frameSettings.isMovable)
        if frameSettings.isMovable then
            frame:RegisterForDrag("LeftButton")
            frame:SetScript("OnDragStart", frame.StartMoving)
            frame:SetScript("OnDragStop", function(self)
                self:StopMovingOrSizing()
                -- Always get position relative to TOPLEFT of UIParent
                local xOfs, yOfs = self:GetLeft(), self:GetTop()
                local parentLeft, parentTop = UIParent:GetLeft(), UIParent:GetTop()
                -- Calculate offsets from UIParent's TOPLEFT
                local baseX = xOfs - parentLeft
                local baseY = yOfs - parentTop
                -- Save
                frameSettings.baseX = baseX
                frameSettings.baseY = baseY
                EnsureSavedVariables()
                ZUF_Settings.frameSettings.baseX = baseX
                ZUF_Settings.frameSettings.baseY = baseY

                -- Re-apply unit/click attributes
                self:SetAttribute("unit", self.unit or "player")
                self:RegisterForClicks("AnyUp")
                self:SetAttribute("type1", "target")
                self:SetAttribute("type2", "togglemenu")
                UpdateFramePositions()
            end)
        else
            frame:RegisterForDrag()
            frame:SetScript("OnDragStart", nil)
            frame:SetScript("OnDragStop", nil)
        end
    end

    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0.1, 0.1, 0.1, 0.8)

    -- Health bar
    frame.healthBar = CreateFrame("StatusBar", nil, frame)
    frame.healthBar:SetStatusBarTexture(LSM:Fetch("statusbar", "Smooth"))
    frame.healthBar:SetStatusBarColor(0.2, 0.9, 0.2)
    frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.healthBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.healthBar:SetHeight(frameSettings.frameHeight - powerBarHeight)

    -- Power bar
    frame.powerBar = CreateFrame("StatusBar", nil, frame)
    frame.powerBar:SetStatusBarTexture(LSM:Fetch("statusbar", "Smooth"))
    frame.powerBar:SetPoint("TOPLEFT", frame.healthBar, "BOTTOMLEFT", 0, 0)
    frame.powerBar:SetPoint("TOPRIGHT", frame.healthBar, "BOTTOMRIGHT", 0, 0)
    frame.powerBar:SetHeight(powerBarHeight)
    frame.powerBar:SetMinMaxValues(0, 100)
    frame.powerBar:SetValue(100)
    frame.powerBar:SetStatusBarColor(0, 0.4, 1) -- Default to mana blue

    -- Name text
    frame.nameText = frame.healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.nameText:SetFont(LSM:Fetch("font", "MyFont"), 12, "OUTLINE")
    frame.nameText:SetPoint("CENTER", frame.healthBar, "CENTER")

    -- Effect icons container (bottom left of health bar
    frame.effectIcons = CreateFrame("Frame", nil, frame.healthBar)
    frame.effectIcons:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMLEFT", 2, 2)
    frame.effectIcons:SetSize(60, 16)
    frame.effectIcons.icons = {}

    -- Buff icons container (top left of health bar)
    frame.buffIcons = CreateFrame("Frame", nil, frame.healthBar)
    frame.buffIcons:SetPoint("TOPLEFT", frame.healthBar, "TOPLEFT", 2, -2)
    frame.buffIcons:SetSize(60, 16)
    frame.buffIcons.icons = {}

    -- Helper to add an effect icon by spellID
    local iconSize = 14
    frame.effectIcons.icons = {}

    local function AddEffectIconBySpellID(spellID)
        local idx = #frame.effectIcons.icons + 1
        local icon = frame.effectIcons:CreateTexture(nil, "OVERLAY")
        icon:SetSize(iconSize, iconSize)
        icon:SetPoint("LEFT", frame.effectIcons, "LEFT", (idx - 1) * (iconSize + 2), 0)
        local tex = GetSpellTexture(spellID)
        icon:SetTexture(tex)
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        frame.effectIcons.icons[idx] = icon
    end

    -- Set the unit for the frame
    frame.unit = unit
    frame:SetAttribute("unit", unit)
    frame:RegisterForClicks("AnyUp")
    frame:SetAttribute("type1", "target")
    frame:SetAttribute("type2", "togglemenu")

    -- Enable mouseover tooltips
    frame:SetScript("OnEnter", function(self)
        if UnitExists(self.unit) then
            GameTooltip_SetDefaultAnchor(GameTooltip, self)
            GameTooltip:SetUnit(self.unit)
            GameTooltip:Show()
        end
    end)
    frame:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)

    -- Update function
    frame:SetScript("OnUpdate", function(self)
        if UnitExists(unit) then
            local _, class = UnitClass(unit)
            local color = RAID_CLASS_COLORS[class]
            -- OFFLINE: Gray out if not connected
            if not UnitIsConnected(unit) then
                self:SetAlpha(0.4)
                self.healthBar:SetStatusBarColor(0.5, 0.5, 0.5)
                self.powerBar:SetStatusBarColor(0.5, 0.5, 0.5)
                self.nameText:SetText(UnitName(unit) .. "\n<DC>" or "")
            else
                -- IN RANGE/OUT OF RANGE: Dim if out of range
                local inRange = UnitInRange(unit)
                if inRange == false then
                    self:SetAlpha(0.5)
                else
                    self:SetAlpha(1)
                end
             if color then
                self.healthBar:SetStatusBarColor(color.r, color.g, color.b)
             else
                self.healthBar:SetStatusBarColor(0.2, 0.9, 0.2)
            end

            self.powerBar:SetStatusBarColor(0, 0.4, 1)
            self.nameText:SetText(UnitName(unit) or "")
            end

            local hp = UnitHealth(unit)
            local maxHp = UnitHealthMax(unit)
            if maxHp > 0 then
                self.healthBar:SetMinMaxValues(0, maxHp)
                self.healthBar:SetValue(hp)
                -- frame.healthText:SetText(hp .. " / " .. maxHp)
            end


            -- Power bar update
            local powerType = UnitPowerType(unit)
            local power = UnitPower(unit)
            local maxPower = UnitPowerMax(unit)
            self.powerBar:SetMinMaxValues(0, maxPower)
            self.powerBar:SetValue(power)
            local r, g, b = PowerBarColor[powerType] and PowerBarColor[powerType].r or 0, PowerBarColor[powerType] and PowerBarColor[powerType].g or 0, PowerBarColor[powerType] and PowerBarColor[powerType].b or 1
            self.powerBar:SetStatusBarColor(r, g, b)

            -- EFFECT TRACKING (trackedSpells)
            -- Hide and release previous effect icons and cooldowns
            for _, icon in ipairs(self.effectIcons.icons) do
                icon:Hide()
                if icon.cooldown then icon.cooldown:Hide() end
                if icon.countText then icon.countText:Hide() end
            end
            wipe(self.effectIcons.icons)

            local idx = 1
            for i = 1, 40 do
                local name, iconTexture, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellId = UnitAura(unit, i, "HELPFUL")
                if not name then break end
                for _, effectSpellId in ipairs(EFFECT_SPELLIDS) do
                    if spellId == effectSpellId and caster == "player" then
                        local icon = self.effectIcons:CreateTexture(nil, "OVERLAY")
                        icon:SetSize(14, 14)
                        icon:SetPoint("LEFT", self.effectIcons, "LEFT", (idx - 1) * (14 + 2), 0)
                        icon:SetTexture(iconTexture)
                        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                        icon:Show()
                        self.effectIcons.icons[idx] = icon

                        -- Add cooldown swipe
                        if duration and duration > 0 and expires then
                            local cooldown = CreateFrame("Cooldown", nil, self.effectIcons, "CooldownFrameTemplate")
                            cooldown:SetAllPoints(icon)
                            cooldown:SetDrawEdge(false)
                            cooldown:SetDrawBling(false)
                            cooldown:SetReverse(true)
                            cooldown:SetCooldown(expires - duration, duration)
                            cooldown:Show()
                            icon.cooldown = cooldown
                        end

                        -- Add stack count if > 1
                        if count and count > 1 then
                            local countText = self.effectIcons:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                            countText:SetPoint("BOTTOM", icon, "BOTTOM", 0, 0)
                            countText:SetText(count)
                            countText:SetTextColor(1, 1, 1, 1)
                            icon.countText = countText
                            countText:Show()
                        end

                        idx = idx + 1
                        break
                    end
                end
            end

            -- BUFF TRACKING (trackedBuffs)
            -- Hide and release previous buff icons and cooldowns
            for _, icon in ipairs(self.buffIcons.icons) do
                icon:Hide()
                if icon.cooldown then icon.cooldown:Hide() end
                if icon.countText then icon.countText:Hide() end
            end
            wipe(self.buffIcons.icons)

            local buffIdx = 1
            local playerClass = select(2, UnitClass("player"))
            local trackedBuffs = (ZUF_Settings.trackedBuffs and ZUF_Settings.trackedBuffs[playerClass]) or {}
            for i = 1, 40 do
                local name, iconTexture, count, dispelType, duration, expires, caster, isStealable, shouldConsolidate, spellId = UnitAura(unit, i, "HELPFUL")
                if not name then break end
                for _, buffSpellId in ipairs(trackedBuffs) do
                    if spellId == buffSpellId then
                        local icon = self.buffIcons:CreateTexture(nil, "OVERLAY")
                        icon:SetSize(14, 14)
                        icon:SetPoint("LEFT", self.buffIcons, "LEFT", (buffIdx - 1) * (14 + 2), 0)
                        icon:SetTexture(iconTexture)
                        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                        icon:Show()
                        self.buffIcons.icons[buffIdx] = icon

                        -- Add cooldown swipe
                        if duration and duration > 0 and expires then
                            local cooldown = CreateFrame("Cooldown", nil, self.buffIcons, "CooldownFrameTemplate")
                            cooldown:SetAllPoints(icon)
                            cooldown:SetDrawEdge(false)
                            cooldown:SetDrawBling(false)
                            cooldown:SetReverse(true)
                            cooldown:SetCooldown(expires - duration, duration)
                            cooldown:Show()
                            icon.cooldown = cooldown
                        end

                        -- Add stack count if > 1
                        if count and count > 1 then
                            local countText = self.buffIcons:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
                            countText:SetPoint("BOTTOM", icon, "BOTTOM", 0, 0)
                            countText:SetText(count)
                            countText:SetTextColor(1, 1, 1, 1)
                            icon.countText = countText
                            countText:Show()
                        end

                        buffIdx = buffIdx + 1
                        break
                    end
                end
            end

            -- Healing prediction using wow API
            local guid = UnitGUID(unit)
            local myGUID = UnitGUID("player")
            local heal = UnitGetIncomingHeals(unit)
            if maxHp > 0 and heal and heal > 0 then
                self.healPredictionBar:SetMinMaxValues(0, maxHp)
                self.healPredictionBar:SetValue(math.min(hp + heal, maxHp))
                self.healPredictionBar:Show()
                -- Set the frame level above the health bar so it's visible
                self.healPredictionBar:SetFrameLevel(self.healthBar:GetFrameLevel() - 1)
                -- Make the heal prediction bar partially transparent
                self.healPredictionBar:SetAlpha(0.6)
                -- Optionally, set a different color for the prediction
                self.healPredictionBar:SetStatusBarColor(0, 1, 0, 0.4)
                -- Make sure the health bar is drawn above the background but below the prediction bar
                self.healthBar:SetFrameLevel(self.healPredictionBar:GetFrameLevel() + 1)
            else
                self.healPredictionBar:Hide()
            end
            
        end
    end)

    -- Healing prediction bar (overlay)
    frame.healPredictionBar = CreateFrame("StatusBar", nil, frame)
    frame.healPredictionBar:SetStatusBarTexture(LSM:Fetch("statusbar", "Smooth"))
    frame.healPredictionBar:SetStatusBarColor(0, 1, 0, 0.4) -- Green, semi-transparent
    frame.healPredictionBar:SetFrameLevel(frame.healthBar:GetFrameLevel() + 1)
    frame.healPredictionBar:SetPoint("TOPLEFT", frame.healthBar, "TOPLEFT")
    frame.healPredictionBar:SetPoint("BOTTOMRIGHT", frame.healthBar, "BOTTOMRIGHT")
    frame.healPredictionBar:Hide()

    table.insert(partyFrames, frame)
    return frame
end

local function UpdateTestFramePositions()
    for i, frame in ipairs(testFrames) do
        frame:ClearAllPoints()
        if frameSettings.layout == "vertical" then
            if i == 1 then
                frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", frameSettings.baseX, frameSettings.baseY)
            else
                frame:SetPoint("TOPLEFT", testFrames[i - 1], "BOTTOMLEFT", 0, -10)
            end
        else
            if i == 1 then
                frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", frameSettings.baseX, frameSettings.baseY)
            else
                frame:SetPoint("TOPLEFT", testFrames[i - 1], "TOPRIGHT", 10, 0)
            end
        end
        frame:SetSize(frameSettings.frameWidth, frameSettings.frameHeight)
        frame.healthBar:SetHeight(frameSettings.frameHeight - powerBarHeight)
        frame.powerBar:SetHeight(powerBarHeight)
    end
end

local function CreateTestFrame(index)
    local frame = CreateFrame("Button", "CF_TestFrame"..index, UIParent, "SecureUnitButtonTemplate")
    frame:SetSize(frameSettings.frameWidth, frameSettings.frameHeight)

    if index == 1 then
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            -- Save new position for real frames
            local xOfs, yOfs = self:GetLeft(), self:GetTop()
            local parentLeft, parentTop = UIParent:GetLeft(), UIParent:GetTop()
            local baseX = xOfs - parentLeft
            local baseY = yOfs - parentTop
            frameSettings.baseX = baseX
            frameSettings.baseY = baseY
            EnsureSavedVariables()
            ZUF_Settings.frameSettings.baseX = baseX
            ZUF_Settings.frameSettings.baseY = baseY
            UpdateTestFramePositions()
            UpdateFramePositions()
        end)
    else
        frame:SetMovable(false)
        frame:EnableMouse(false)
        frame:RegisterForDrag()
        frame:SetScript("OnDragStart", nil)
        frame:SetScript("OnDragStop", nil)
    end

    -- Background
    frame.bg = frame:CreateTexture(nil, "BACKGROUND")
    frame.bg:SetAllPoints()
    frame.bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)

    -- Health bar
    frame.healthBar = CreateFrame("StatusBar", nil, frame)
    frame.healthBar:SetStatusBarTexture(LSM:Fetch("statusbar", "Smooth"))
    frame.healthBar:SetStatusBarColor(0.2, 0.9, 0.2)
    frame.healthBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    frame.healthBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    frame.healthBar:SetHeight(frameSettings.frameHeight - powerBarHeight)
    frame.healthBar:SetMinMaxValues(0, 100)
    frame.healthBar:SetValue(math.random(30, 100))

    -- Power bar
    frame.powerBar = CreateFrame("StatusBar", nil, frame)
    frame.powerBar:SetStatusBarTexture(LSM:Fetch("statusbar", "Smooth"))
    frame.powerBar:SetPoint("TOPLEFT", frame.healthBar, "BOTTOMLEFT", 0, 0)
    frame.powerBar:SetPoint("TOPRIGHT", frame.healthBar, "BOTTOMRIGHT", 0, 0)
    frame.powerBar:SetHeight(powerBarHeight)
    frame.powerBar:SetMinMaxValues(0, 100)
    frame.powerBar:SetValue(math.random(10, 100))
    frame.powerBar:SetStatusBarColor(0, 0.4, 1)

    -- Name text
    frame.nameText = frame.healthBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    frame.nameText:SetFont(LSM:Fetch("font", "MyFont"), 12, "OUTLINE")
    frame.nameText:SetPoint("CENTER", frame.healthBar, "CENTER")
    if index == 1 then
        frame.nameText:SetText("Drag me")
    else
        frame.nameText:SetText("Test " .. index)
    end

    -- Effect icons
    frame.effectIcons = CreateFrame("Frame", nil, frame.healthBar)
    frame.effectIcons:SetPoint("BOTTOMLEFT", frame.healthBar, "BOTTOMLEFT", 2, 2)
    frame.effectIcons:SetSize(60, 16)
    frame.effectIcons.icons = {}
    for i = 1, 2 do
        local icon = frame.effectIcons:CreateTexture(nil, "OVERLAY")
        icon:SetSize(14, 14)
        icon:SetPoint("LEFT", frame.effectIcons, "LEFT", (i-1)*16, 0)
        icon:SetTexture("Interface\\Icons\\Spell_Holy_Renew") -- Placeholder icon
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:Show()
        frame.effectIcons.icons[i] = icon
    end

    -- Buff icons
    frame.buffIcons = CreateFrame("Frame", nil, frame.healthBar)
    frame.buffIcons:SetPoint("TOPLEFT", frame.healthBar, "TOPLEFT", 2, -2)
    frame.buffIcons:SetSize(60, 16)
    frame.buffIcons.icons = {}
    for i = 1, 2 do
        local icon = frame.buffIcons:CreateTexture(nil, "OVERLAY")
        icon:SetSize(14, 14)
        icon:SetPoint("LEFT", frame.buffIcons, "LEFT", (i-1)*16, 0)
        icon:SetTexture("Interface\\Icons\\Spell_Nature_Regeneration") -- Mark of the Wild icon
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:Show()
        frame.buffIcons.icons[i] = icon
    end

    return frame
end

local function ShowTestFrames()
    -- Hide real frames
    for _, frame in ipairs(partyFrames) do
        frame:Hide()
    end
    -- Create or show test frames
    if #testFrames == 0 then
        for i = 1, 5 do
            local frame = CreateTestFrame(i)
            table.insert(testFrames, frame)
        end
    end
    for _, frame in ipairs(testFrames) do
        frame:Show()
    end
    UpdateTestFramePositions()
end

local function HideTestFrames()
    for _, frame in ipairs(testFrames) do
        frame:Hide()
    end
    -- Show real frames
    for _, frame in ipairs(partyFrames) do
        frame:Show()
    end
    UpdateFramePositions()
end

-- Create frames for player + 4 party members
local partyUnits = { "player", "party1", "party2", "party3", "party4" }
local function CreateFrames()
    -- Hide and clear old frames
    for _, frame in ipairs(partyFrames) do
        frame:Hide()
        frame:SetParent(nil)
    end
    wipe(partyFrames)

    if frameSettings.isMovable and not IsInRaid() then
        -- Always show 5 frames with placeholders
        local units = { "player", "party1", "party2", "party3", "party4" }
        for i, unit in ipairs(units) do
            if UnitExists(unit) then
                CreateUnitFrame(unit, i)
            else
                -- Use "player" as a placeholder for missing units
                local frame = CreateUnitFrame("player", i)
                frame.nameText:SetText("Placeholder " .. i)
                frame.healthBar:SetValue(math.random(30, 100)) -- Random health for visual variety
            end
            UpdateFramePositions()
        end
        -- Do nothing if in a raid
    elseif IsInRaid() then
        for _, frame in ipairs(partyFrames) do
            frame:Hide()
        end
        return
    elseif IsInGroup() then
        local units = { "player" }
        for i = 1, 4 do
            local unit = "party" .. i
            if UnitExists(unit) then
                table.insert(units, unit)
            end
        end
        for i, unit in ipairs(units) do
            CreateUnitFrame(unit, i)
            UpdateFramePositions()
        end
    end
end

local function UpdateFrameSizes()
    for _, frame in ipairs(partyFrames) do
        frame:SetSize(frameSettings.frameWidth, frameSettings.frameHeight)
        frame.healthBar:SetHeight(frameSettings.frameHeight - powerBarHeight)
        frame.powerBar:SetHeight(powerBarHeight)
    end
end

-- Create a configuration window
local function CreateConfigWindow()
    local _, playerClass = UnitClass("player")
    local configFrame = CreateFrame("Frame", "CF_ConfigWindow", UIParent, "BasicFrameTemplateWithInset")
    configFrame:SetSize(340, 500)
    configFrame:SetPoint("CENTER")
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
    configFrame:SetFrameStrata("DIALOG")
    configFrame:SetFrameLevel(100)

    -- Make the window resizable
    configFrame:SetResizable(true)

    -- Add a resize handle in the bottom-right corner
    local resizeButton = CreateFrame("Button", nil, configFrame)
    resizeButton:SetSize(16, 16)
    resizeButton:SetPoint("BOTTOMRIGHT", -4, 4)
    resizeButton:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeButton:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeButton:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeButton:SetScript("OnMouseDown", function(self, button)
        if button == "LeftButton" then
            configFrame:StartSizing("BOTTOMRIGHT")
        end
    end)
    resizeButton:SetScript("OnMouseUp", function(self, button)
        configFrame:StopMovingOrSizing()
    end)

    configFrame.title = configFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    configFrame.title:SetPoint("CENTER", configFrame.TitleBg, "CENTER", 0, 0)
    configFrame.title:SetText("Unit Frames Config")

    -- Create the scroll frame and its child
    local scrollFrame = CreateFrame("ScrollFrame", "CF_ConfigScrollFrame", configFrame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", configFrame.Bg, "TOPLEFT", 4, -6)
    scrollFrame:SetPoint("BOTTOMRIGHT", configFrame.Bg, "BOTTOMRIGHT", -28, 6)

    local scrollChild = CreateFrame("Frame", nil, scrollFrame)
    scrollChild:SetSize(1, 1) -- Will be expanded as children are added
    scrollFrame:SetScrollChild(scrollChild)

    -- Now, place all your controls on scrollChild instead of configFrame
    -- Example for the first few controls:
    local movableCheckbox = CreateFrame("CheckButton", nil, scrollChild, "UICheckButtonTemplate")
    movableCheckbox:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 10, -10)
    movableCheckbox.text = movableCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    movableCheckbox.text:SetPoint("LEFT", movableCheckbox, "RIGHT", 5, 0)
    movableCheckbox.text:SetText("Make Frames Movable (Drag Player Frame)")
    movableCheckbox:SetScript("OnClick", function(self)
        frameSettings.isMovable = self:GetChecked()
        if IsInGroup() then
            partyFrames[1]:SetMovable(frameSettings.isMovable)
            partyFrames[1]:EnableMouse(true)
            if frameSettings.isMovable then
                if IsInGroup() then
                    partyFrames[1]:RegisterForDrag("LeftButton")
                    partyFrames[1]:SetScript("OnDragStart", partyFrames[1].StartMoving)
                    partyFrames[1]:SetScript("OnDragStop", function(self)
                        self:StopMovingOrSizing()
                        local xOfs, yOfs = self:GetLeft(), self:GetTop()
                        local parentLeft, parentTop = UIParent:GetLeft(), UIParent:GetTop()
                        local baseX = xOfs - parentLeft
                        local baseY = yOfs - parentTop
                        frameSettings.baseX = baseX
                        frameSettings.baseY = baseY
                        EnsureSavedVariables()
                        ZUF_Settings.frameSettings.baseX = baseX
                        ZUF_Settings.frameSettings.baseY = baseY

                        -- Re-apply unit/click attributes
                        self:SetAttribute("unit", self.unit or "player")
                        self:RegisterForClicks("AnyUp")
                        self:SetAttribute("type1", "target")
                        self:SetAttribute("type2", "togglemenu")
                        UpdateFramePositions()
                    end)
                end
            else
                partyFrames[1]:RegisterForDrag()
                partyFrames[1]:SetScript("OnDragStart", nil)
                partyFrames[1]:SetScript("OnDragStop", nil)
            end
            CreateFrames()
        end
    end)

    -- Dropdown to choose layout
    local layoutDropdown = CreateFrame("Frame", "CF_LayoutDropdown", scrollChild, "UIDropDownMenuTemplate")
    layoutDropdown:SetPoint("TOPLEFT", movableCheckbox, "BOTTOMLEFT", -5, -10)
    UIDropDownMenu_SetWidth(layoutDropdown, 150)
    UIDropDownMenu_SetText(layoutDropdown, "Layout: " .. (frameSettings.layout == "vertical" and "Vertical" or "Horizontal"))
    UIDropDownMenu_Initialize(layoutDropdown, function(self, level, menuList)
        local info = UIDropDownMenu_CreateInfo()
        info.func = function(self)
            frameSettings.layout = self.value
            UIDropDownMenu_SetText(layoutDropdown, "Layout: " .. (self.value == "vertical" and "Vertical" or "Horizontal"))
            UpdateFramePositions()
            UpdateTestFramePositions()
        end
        info.text, info.value = "Vertical", "vertical"
        UIDropDownMenu_AddButton(info)
        info.text, info.value = "Horizontal", "horizontal"
        UIDropDownMenu_AddButton(info)
    end)

    -- Slider to adjust frame width
    local widthSlider = CreateFrame("Slider", "CF_WidthSlider", scrollChild, "OptionsSliderTemplate")
    widthSlider:SetPoint("TOPLEFT", layoutDropdown, "BOTTOMLEFT", 15, -20)
    widthSlider:SetMinMaxValues(100, 300)
    widthSlider:SetValue(frameSettings.frameWidth)
    widthSlider:SetValueStep(1)
    widthSlider:SetObeyStepOnDrag(true)
    widthSlider.text = _G[widthSlider:GetName() .. "Text"]
    widthSlider.text:SetText("Frame Width")
    widthSlider:SetScript("OnValueChanged", function(self, value)
        frameSettings.frameWidth = math.floor(value)
        EnsureSavedVariables()
        ZUF_Settings.frameSettings.frameWidth = math.floor(value)
        UpdateFrameSizes()
        UpdateTestFramePositions()
    end)

    -- Slider to adjust frame height
    local heightSlider = CreateFrame("Slider", "CF_HeightSlider", scrollChild, "OptionsSliderTemplate")
    heightSlider:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, -20)
    heightSlider:SetMinMaxValues(20, 100)
    heightSlider:SetValue(frameSettings.frameHeight)
    heightSlider:SetValueStep(1)
    heightSlider:SetObeyStepOnDrag(true)
    heightSlider.text = _G[heightSlider:GetName() .. "Text"]
    heightSlider.text:SetText("Frame Height")
    heightSlider:SetScript("OnValueChanged", function(self, value)
    frameSettings.frameHeight = math.floor(value)
    EnsureSavedVariables()
    ZUF_Settings.frameSettings.frameHeight = math.floor(value)
    UpdateFrameSizes() -- Only update size!
    UpdateTestFramePositions()
    end)

    -- Reset Position Button
    local resetButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetButton:SetSize(120, 24)
    resetButton:SetPoint("TOPLEFT", heightSlider, "BOTTOMLEFT", 0, -30)
    resetButton:SetText("Reset Position")
    resetButton:SetScript("OnClick", function()
        local defaultX, defaultY = 30, -40
        frameSettings.baseX = defaultX
        frameSettings.baseY = defaultY
        EnsureSavedVariables()
        ZUF_Settings.frameSettings.baseX = defaultX
        ZUF_Settings.frameSettings.baseY = defaultY
        UpdateFramePositions()
        print("Unit frame position reset to default.")
    end)

    -- Test Mode Button
    local testButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    testButton:SetSize(120, 24)
    testButton:SetPoint("LEFT", resetButton, "RIGHT", 10, 0)
    testButton:SetText("Toggle Test Mode")
    testButton:SetScript("OnClick", function()
        testMode = not testMode
        if testMode then
            ShowTestFrames()
        else
            HideTestFrames()
        end
    end)

    -- Tracked Spells Label
    local trackedLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    trackedLabel:SetPoint("TOPLEFT", resetButton, "BOTTOMLEFT", 0, -20)
    trackedLabel:SetText("Tracked Spells (" .. (playerClass or "Unknown") .. ")")

    -- ScrollFrame for spell list
    local spellListScrollFrame = CreateFrame("ScrollFrame", nil, scrollChild, "UIPanelScrollFrameTemplate")
    spellListScrollFrame:SetPoint("TOPLEFT", trackedLabel, "BOTTOMLEFT", 0, -5)
    spellListScrollFrame:SetSize(180, 80)

    local spellList = CreateFrame("Frame", nil, spellListScrollFrame)
    spellList:SetSize(180, 80)
    spellListScrollFrame:SetScrollChild(spellList)

    local function RefreshSpellList()
        -- Remove all previous children (fontstrings and buttons)
        for _, child in ipairs({spellList:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end
        local tracked = ZUF_Settings.trackedSpells and ZUF_Settings.trackedSpells[playerClass] or {}
        for i, spellID in ipairs(tracked) do
            local name, _, icon = GetSpellInfo(spellID)
            -- Create a container frame for the row
            local rowFrame = CreateFrame("Frame", nil, spellList)
            rowFrame:SetSize(180, 16)
            rowFrame:SetPoint("TOPLEFT", buffsList, "TOPLEFT", 0, -((i-1)*16))

            local rowText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rowText:SetPoint("LEFT", rowFrame, "LEFT", 0, 0)
            rowText:SetText((icon and "|T"..icon..":14|t " or "") .. (name or "Unknown") .. " (" .. spellID .. ")")
            rowText:Show()

            -- Add remove ("X") button
            local removeBtn = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
            removeBtn:SetSize(18, 16)
            removeBtn:SetPoint("LEFT", rowText, "RIGHT", 5, 0)
            removeBtn:SetText("X")
            removeBtn:SetScript("OnClick", function()
                table.remove(ZUF_Settings.trackedSpells[playerClass], i)
                RefreshSpellList()
            end)
            removeBtn:Show()
        end
    end

    -- Add SpellID input
    local addBoxLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    addBoxLabel:SetPoint("BOTTOMLEFT", spellListScrollFrame, "BOTTOMLEFT", 5, -15)
    addBoxLabel:SetText("Drag a spell here or enter a SpellID:")

    local addBox = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
    addBox:SetSize(60, 20)
    addBox:SetPoint("TOPLEFT", addBoxLabel, "BOTTOMLEFT", 0, -2)
    addBox:SetAutoFocus(false)
    addBox:SetNumeric(true)
    addBox:SetMaxLetters(7)

    local addButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    addButton:SetSize(80, 20)
    addButton:SetPoint("LEFT", addBox, "RIGHT", 5, 0)
    addButton:SetText("Add")

    addButton:SetScript("OnClick", function()
        local spellID = tonumber(addBox:GetText())
        if not spellID then return end
        local _, playerClass = UnitClass("player")
        if not ZUF_Settings.trackedSpells[playerClass] then
            ZUF_Settings.trackedSpells[playerClass] = {}
        end
        -- Prevent duplicates
        for _, id in ipairs(ZUF_Settings.trackedSpells[playerClass]) do
            if id == spellID then return end
        end
        table.insert(ZUF_Settings.trackedSpells[playerClass], spellID)
        addBox:SetText("")
        RefreshSpellList()
        print("Added spellID:", spellID)
    end)

    local resetSpellsButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetSpellsButton:SetSize(60, 20)
    resetSpellsButton:SetPoint("LEFT", addButton, "RIGHT", 5, 0)
    resetSpellsButton:SetText("Reset")
    resetSpellsButton:SetScript("OnClick", function()
        local _, playerClass = UnitClass("player")
        if ZUF_Defaults and ZUF_Defaults.trackedSpells and ZUF_Defaults.trackedSpells[playerClass] then
            ZUF_Settings.trackedSpells[playerClass] = CopyTable(ZUF_Defaults.trackedSpells[playerClass])
            RefreshSpellList()
            print("Tracked spells reset to defaults for " .. playerClass)
        end
    end)

    addBox:SetScript("OnReceiveDrag", function(self)
    local type, id, subType = GetCursorInfo()
    if type == "spell" then
        local spellName, spellSubName = GetSpellBookItemName(id, "spell")
        local spellId = select(7, GetSpellInfo(spellName, spellSubName))
        if spellId then
            self:SetText(tostring(spellId))
        end
    end
    ClearCursor()
    end)

    addBox:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            self:SetText("")
        end
    end)

        -- Tracked Buffs Label
    local trackedBuffsLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    trackedBuffsLabel:SetPoint("TOPLEFT", addBox, "BOTTOMLEFT", 0, -30)
    trackedBuffsLabel:SetText("Tracked Buffs (" .. (playerClass or "Unknown") .. ")")

    -- ScrollFrame for buffs list
    local buffsListScrollFrame = CreateFrame("ScrollFrame", nil, scrollChild, "UIPanelScrollFrameTemplate")
    buffsListScrollFrame:SetPoint("TOPLEFT", trackedBuffsLabel, "BOTTOMLEFT", 0, -5)
    buffsListScrollFrame:SetSize(180, 80)

    local buffsList = CreateFrame("Frame", nil, buffsListScrollFrame)
    buffsList:SetSize(180, 80)
    buffsListScrollFrame:SetScrollChild(buffsList)

    local function RefreshBuffsList()
        for _, child in ipairs({buffsList:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end
        local tracked = ZUF_Settings.trackedBuffs and ZUF_Settings.trackedBuffs[playerClass] or {}
        for i, spellID in ipairs(tracked) do
            local name, _, icon = GetSpellInfo(spellID)
            local rowFrame = CreateFrame("Frame", nil, buffsList)
            rowFrame:SetSize(180, 16)
            rowFrame:SetPoint("TOPLEFT", buffsList, "TOPLEFT", 0, -((i-1)*16))

            local rowText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rowText:SetPoint("LEFT", rowFrame, "LEFT", 0, 0)
            rowText:SetText((icon and "|T"..icon..":14|t " or "") .. (name or "Unknown") .. " (" .. spellID .. ")")
            rowText:Show()

            local removeBtn = CreateFrame("Button", nil, rowFrame, "UIPanelButtonTemplate")
            removeBtn:SetSize(18, 16)
            removeBtn:SetPoint("LEFT", rowText, "RIGHT", 5, 0)
            removeBtn:SetText("X")
            removeBtn:SetScript("OnClick", function()
                table.remove(ZUF_Settings.trackedBuffs[playerClass], i)
                RefreshBuffsList()
            end)
            removeBtn:Show()
        end
    end

    -- Add SpellID input for buffs
    local addBuffBoxLabel = scrollChild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    addBuffBoxLabel:SetPoint("BOTTOMLEFT", buffsListScrollFrame, "BOTTOMLEFT", 5, -15)
    addBuffBoxLabel:SetText("Drag a spell here or enter a SpellID:")

    local addBuffBox = CreateFrame("EditBox", nil, scrollChild, "InputBoxTemplate")
    addBuffBox:SetSize(60, 20)
    addBuffBox:SetPoint("TOPLEFT", addBuffBoxLabel, "BOTTOMLEFT", 0, -2)
    addBuffBox:SetAutoFocus(false)
    addBuffBox:SetNumeric(true)
    addBuffBox:SetMaxLetters(7)

    local addBuffButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    addBuffButton:SetSize(80, 20)
    addBuffButton:SetPoint("LEFT", addBuffBox, "RIGHT", 5, 0)
    addBuffButton:SetText("Add")

    addBuffButton:SetScript("OnClick", function()
        local spellID = tonumber(addBuffBox:GetText())
        if not spellID then return end
        local _, playerClass = UnitClass("player")
        if not ZUF_Settings.trackedBuffs[playerClass] then
            ZUF_Settings.trackedBuffs[playerClass] = {}
        end
        for _, id in ipairs(ZUF_Settings.trackedBuffs[playerClass]) do
            if id == spellID then return end
        end
        table.insert(ZUF_Settings.trackedBuffs[playerClass], spellID)
        addBuffBox:SetText("")
        RefreshBuffsList()
        print("Added tracked buff spellID:", spellID)
    end)

    local resetBuffsButton = CreateFrame("Button", nil, scrollChild, "UIPanelButtonTemplate")
    resetBuffsButton:SetSize(60, 20)
    resetBuffsButton:SetPoint("LEFT", addBuffButton, "RIGHT", 5, 0)
    resetBuffsButton:SetText("Reset")
    resetBuffsButton:SetScript("OnClick", function()
        local _, playerClass = UnitClass("player")
        if ZUF_Defaults and ZUF_Defaults.trackedBuffs and ZUF_Defaults.trackedBuffs[playerClass] then
            ZUF_Settings.trackedBuffs[playerClass] = CopyTable(ZUF_Defaults.trackedBuffs[playerClass])
            RefreshBuffsList()
            print("Tracked buffs reset to defaults for " .. playerClass)
        end
    end)

    addBuffBox:SetScript("OnReceiveDrag", function(self)
        local type, id, subType = GetCursorInfo()
        if type == "spell" then
            local spellName, spellSubName = GetSpellBookItemName(id, "spell")
            local spellId = select(7, GetSpellInfo(spellName, spellSubName))
            if spellId then
                self:SetText(tostring(spellId))
            end
        end
        ClearCursor()
    end)

    addBuffBox:SetScript("OnMouseUp", function(self, button)
        if button == "RightButton" then
            self:SetText("")
        end
    end)

    RefreshBuffsList()
    RefreshSpellList()

    configFrame:Hide() -- Initially hidden
    return configFrame
end

-- Slash command to open the config window
SLASH_ZUF1 = "/ZUF"
SlashCmdList["ZUF"] = function()
    if not CF_ConfigWindow then
        CF_ConfigWindow = CreateConfigWindow()
    end
    if CF_ConfigWindow:IsShown() then
        CF_ConfigWindow:Hide()
    else
        CF_ConfigWindow:Show()
    end
end

-- Minimap Button
local minimapButton = CreateFrame("Button", "ZUF_MinimapButton", Minimap)
minimapButton:SetSize(32, 32)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetMovable(true)
minimapButton:SetClampedToScreen(true)
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Icon
minimapButton.icon = minimapButton:CreateTexture(nil, "BACKGROUND")
minimapButton.icon:SetTexture("Interface\\AddOns\\zindure-unit-frames\\media\\minimap-icon.tga") -- Use your own icon here!
minimapButton.icon:SetSize(20, 20)
minimapButton.icon:SetPoint("CENTER")

-- Border
minimapButton.border = minimapButton:CreateTexture(nil, "OVERLAY")
minimapButton.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
minimapButton.border:SetSize(54, 54)
minimapButton.border:SetPoint("TOPLEFT")

-- Position on minimap
minimapButton:SetPoint("TOPLEFT", Minimap, "TOPLEFT", 0, 0)

-- Drag to move
minimapButton:RegisterForDrag("LeftButton")
minimapButton:SetScript("OnDragStart", function(self) self:StartMoving() end)
minimapButton:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)

-- Click to toggle config window
minimapButton:SetScript("OnClick", function(self, button)
    if not CF_ConfigWindow then
        CF_ConfigWindow = CreateConfigWindow()
    end
    if CF_ConfigWindow:IsShown() then
        CF_ConfigWindow:Hide()
    else
        CF_ConfigWindow:Show()
    end
end)

-- Tooltip
minimapButton:SetScript("OnEnter", function(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:SetText("Zindure's Unit Frames\n|cffffff00Click to open config|r", nil, nil, nil, nil, true)
end)
minimapButton:SetScript("OnLeave", function(self)
    GameTooltip:Hide()
end)

-- Init
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("GROUP_ROSTER_UPDATE") -- Triggered when group composition changes
f:RegisterEvent("PLAYER_ENTERING_WORLD") -- Triggered when entering the world
f:RegisterEvent("ADDON_LOADED") -- Triggered when the addon is loaded
f:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == "zindure-unit-frames" then
        
        -- Initialize saved variables if they don't exist
        if ZUF_Settings == nil then
            if not ZUF_Defaults then
                -- Show error popup
                StaticPopupDialogs["ZUF_MISSING_DEFAULTS"] = {
                    text = "Zindure's Unit Frames: Critical error!\n\nZUF_Defaults is missing.\nPlease reinstall the addon.",
                    button1 = "OK",
                    timeout = 0,
                    whileDead = true,
                    hideOnEscape = true,
                }
                StaticPopup_Show("ZUF_MISSING_DEFAULTS")
                return -- Stop further loading
            end
            print("Initializing default variables for Zindure's Unit Frames")
            ZUF_Settings = CopyTable(ZUF_Defaults)
        else
            print("ZUF_Settings loaded")
        end
        if not ZUF_Settings.trackedBuffs then
            ZUF_Settings.trackedBuffs = {}
        end
        -- Load saved settings into frameSettings
        frameSettings = ZUF_Settings.frameSettings
        local _, playerClass = UnitClass("player")
        EFFECT_SPELLIDS = (ZUF_Settings.trackedSpells and ZUF_Settings.trackedSpells[playerClass]) or {}

        -- Initialize layout and visibility
        HideBlizzardFrames()
        CreateFrames()
    elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" or event == "GROUP_ROSTER_UPDATE" then
        if ZUF_Settings and frameSettings then
            HideBlizzardFrames()
            CreateFrames()
        end
    end
end)
