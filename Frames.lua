-- Party/Raid frame logic

function UpdateFramePositions()
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
        frame.healthBar:SetHeight(frameSettings.frameHeight - powerBarHeight)
        frame.powerBar:SetHeight(powerBarHeight)
    end
end

-- Create one unit frame
function CreateUnitFrame(unit, index)
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

-- Create frames for player + 4 party members
partyUnits = { "player", "party1", "party2", "party3", "party4" }
function CreateFrames()
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

function UpdateFrameSizes()
    for _, frame in ipairs(partyFrames) do
        frame:SetSize(frameSettings.frameWidth, frameSettings.frameHeight)
        frame.healthBar:SetHeight(frameSettings.frameHeight - powerBarHeight)
        frame.powerBar:SetHeight(powerBarHeight)
    end
end