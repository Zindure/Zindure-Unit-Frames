-- Test frame logic

function UpdateTestFramePositions()
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

function CreateTestFrame(index)
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

function ShowTestFrames()
    for _, frame in ipairs(partyFrames) do
        frame:Hide()
    end
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

function HideTestFrames()
    for _, frame in ipairs(testFrames) do
        frame:Hide()
    end
    if(IsInGroup() and not IsInRaid()) then
        for _, frame in ipairs(partyFrames) do
            frame:Show()
        end
    end
    UpdateFramePositions()
end

-- Raid test frame logic

function UpdateRaidTestFramePositions()
    local groupSize = 5
    local spacing = 5
    local groupSpacing = 5

    for i, frame in ipairs(raidTestFrames) do
        frame:ClearAllPoints()
        -- Reparent all frames except the first to the first frame
        if i == 1 then
            frame:SetParent(UIParent)
            frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", raidFrameSettings.baseX, raidFrameSettings.baseY)
        else
            frame:SetParent(raidTestFrames[1])
            local groupIndex = math.floor((i - 1) / groupSize)
            local indexInGroup = (i - 1) % groupSize
            if raidFrameSettings.layout == "vertical" then
                local x = groupIndex * (raidFrameSettings.frameWidth + groupSpacing)
                local y = -indexInGroup * (raidFrameSettings.frameHeight + spacing)
                frame:SetPoint("TOPLEFT", raidTestFrames[1], "TOPLEFT", x, y)
            else
                local x = indexInGroup * (raidFrameSettings.frameWidth + spacing)
                local y = -groupIndex * (raidFrameSettings.frameHeight + groupSpacing)
                frame:SetPoint("TOPLEFT", raidTestFrames[1], "TOPLEFT", x, y)
            end
        end
        frame:SetSize(raidFrameSettings.frameWidth, raidFrameSettings.frameHeight)
        frame.healthBar:SetHeight(raidFrameSettings.frameHeight - powerBarHeight)
        frame.powerBar:SetHeight(powerBarHeight)
    end
end

function CreateRaidTestFrame(index)
    local parent = index == 1 and UIParent or raidTestFrames[1]
    local frame = CreateFrame("Button", "CF_RaidTestFrame"..index, parent, "SecureUnitButtonTemplate")
    frame:SetSize(raidFrameSettings.frameWidth, raidFrameSettings.frameHeight)

    if index == 1 then
        frame:SetMovable(true)
        frame:EnableMouse(true)
        frame:RegisterForDrag("LeftButton")
        frame:SetScript("OnDragStart", frame.StartMoving)
        frame:SetScript("OnDragStop", function(self)
            self:StopMovingOrSizing()
            local xOfs, yOfs = self:GetLeft(), self:GetTop()
            local parentLeft, parentTop = UIParent:GetLeft(), UIParent:GetTop()
            local baseX = xOfs - parentLeft
            local baseY = yOfs - parentTop
            raidFrameSettings.baseX = baseX
            raidFrameSettings.baseY = baseY
            EnsureSavedVariables()
            ZUF_Settings.raidFrameSettings.baseX = baseX
            ZUF_Settings.raidFrameSettings.baseY = baseY
            UpdateRaidTestFramePositions()
            UpdateRaidFramePositions()
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
    frame.healthBar:SetHeight(raidFrameSettings.frameHeight - powerBarHeight)
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
    frame.nameText:SetFont(LSM:Fetch("font", "MyFont"), 10, "OUTLINE")
    frame.nameText:SetPoint("CENTER", frame.healthBar, "CENTER")
    if index == 1 then
        frame.nameText:SetText("Drag me")
    else
        frame.nameText:SetText("RaidTest " .. index)
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
        icon:SetTexture("Interface\\Icons\\Spell_Holy_Renew")
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
        icon:SetTexture("Interface\\Icons\\Spell_Nature_Regeneration")
        icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
        icon:Show()
        frame.buffIcons.icons[i] = icon
    end

    return frame
end

function ShowRaidTestFrames()
    for _, frame in ipairs(raidFrames) do
        frame:Hide()
    end
    if #raidTestFrames == 0 then
        for i = 1, 25 do -- or 40 for full raid
            local frame = CreateRaidTestFrame(i)
            table.insert(raidTestFrames, frame)
        end
    end
    for _, frame in ipairs(raidTestFrames) do
        frame:Show()
    end
    UpdateRaidTestFramePositions()
end

function HideRaidTestFrames()
    for _, frame in ipairs(raidTestFrames) do
        frame:Hide()
    end

    if raidToggled then
        for _, frame in ipairs(raidFrames) do
            frame:Show()
        end
        UpdateRaidFramePositions()
    end
end
