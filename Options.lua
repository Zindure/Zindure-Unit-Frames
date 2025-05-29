-- Options/config panel

function CreateConfigWindow()
    local _, playerClass = UnitClass("player")
    local configFrame = CreateFrame("Frame", "CF_ConfigWindow", UIParent, "BasicFrameTemplateWithInset")
    configFrame:SetSize(400, 500)
    configFrame:SetPoint("CENTER")
    configFrame:SetMovable(true)
    configFrame:EnableMouse(true)
    configFrame:RegisterForDrag("LeftButton")
    configFrame:SetScript("OnDragStart", configFrame.StartMoving)
    configFrame:SetScript("OnDragStop", configFrame.StopMovingOrSizing)
    configFrame:SetFrameStrata("DIALOG")
    configFrame:SetFrameLevel(100)
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
    configFrame.title:SetText("ZUF - Options")

    -- Tabs
    PanelTemplates_SetNumTabs(configFrame, 3)
    configFrame.selectedTab = 1
    

    local tabWidth, tabHeight = 80, 22

    local tab1 = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    tab1:SetSize(tabWidth, tabHeight)
    tab1:SetText("General")
    tab1:SetPoint("TOPLEFT", configFrame, "BOTTOMLEFT", 0, 0)

    local tab2 = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    tab2:SetSize(tabWidth, tabHeight)
    tab2:SetText("Party")
    tab2:SetPoint("LEFT", tab1, "RIGHT", 4, 0)

    local tab3 = CreateFrame("Button", nil, configFrame, "UIPanelButtonTemplate")
    tab3:SetSize(tabWidth, tabHeight)
    tab3:SetText("Raid")
    tab3:SetPoint("LEFT", tab2, "RIGHT", 4, 0)
    

    -- ScrollFrames for each tab
    local scrollFrames, scrollChildren = {}, {}
    for i = 1, 3 do
        local scrollFrame = CreateFrame("ScrollFrame", nil, configFrame, "UIPanelScrollFrameTemplate")
        scrollFrame:SetPoint("TOPLEFT", configFrame.Bg, "TOPLEFT", 4, -6)
        scrollFrame:SetPoint("BOTTOMRIGHT", configFrame.Bg, "BOTTOMRIGHT", -28, 6)
        local scrollChild = CreateFrame("Frame", nil, scrollFrame)
        scrollChild:SetSize(1, 1)
        scrollFrame:SetScrollChild(scrollChild)
        scrollFrames[i] = scrollFrame
        scrollChildren[i] = scrollChild
    end

    local tabButtons = {tab1, tab2, tab3}

    for i, tab in ipairs(tabButtons) do

        -- Blizzard-style left border
        tab.leftBorder = tab:CreateTexture(nil, "BORDER")
        tab.leftBorder:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
        tab.leftBorder:SetTexCoord(0.0, 0.125, 0, 1)
        tab.leftBorder:SetWidth(8)
        tab.leftBorder:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", -2, -2)
        tab.leftBorder:SetPoint("TOPLEFT", tab, "TOPLEFT", -2, 2)
        tab.leftBorder:Hide()

        -- Blizzard-style right border
        tab.rightBorder = tab:CreateTexture(nil, "BORDER")
        tab.rightBorder:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
        tab.rightBorder:SetTexCoord(0.875, 1, 0, 1)
        tab.rightBorder:SetWidth(8)
        tab.rightBorder:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 2, -2)
        tab.rightBorder:SetPoint("TOPRIGHT", tab, "TOPRIGHT", 2, 2)
        tab.rightBorder:Hide()

        -- Blizzard-style bottom border
        tab.bottomBorder = tab:CreateTexture(nil, "BORDER")
        tab.bottomBorder:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
        tab.bottomBorder:SetTexCoord(0.125, 0.875, 0, 0.125)
        tab.bottomBorder:SetHeight(8)
        tab.bottomBorder:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", -2, -2)
        tab.bottomBorder:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 2, -2)
        tab.bottomBorder:Hide()
    end

    local function ShowTab(tab)
        for i = 1, 3 do
            scrollFrames[i]:SetShown(i == tab)
            -- Visually highlight the selected tab
            if tabButtons[i].bg then
                if i == tab then
                    tabButtons[i].bg:SetColorTexture(0.3, 0.3, 0.5, 1)
                else
                    tabButtons[i].bg:SetColorTexture(0.2, 0.2, 0.2, 0.7)
                end
                tabButtons[i].bg:SetShown(true)
            end
            tabButtons[i]:SetButtonState(i == tab and "PUSHED" or "NORMAL")
        end
    end

    tab1:SetScript("OnClick", function() ShowTab(1) end)
    tab2:SetScript("OnClick", function() ShowTab(2) end)
    tab3:SetScript("OnClick", function() ShowTab(3) end)

    -- Show tab 1 by default
    ShowTab(1)

    --------------------------------------------------
    -- === GENERAL TAB CONTENT (scrollChildren[1]) ===
    --------------------------------------------------

    local partyLabel = scrollChildren[1]:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    partyLabel:SetPoint("TOPLEFT", 10, -10)
    partyLabel:SetText("General Settings")

     -- Movable Toggle
    local movableCheckbox = CreateFrame("CheckButton", nil, scrollChildren[1], "UICheckButtonTemplate")
    movableCheckbox:SetPoint("TOPLEFT", partyLabel, "TOPLEFT", 0, -20)
    movableCheckbox.text = movableCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    movableCheckbox.text:SetPoint("LEFT", movableCheckbox, "RIGHT", 5, 0)
    movableCheckbox.text:SetText("Make Frames Movable (Drag Player Frame)")
    if frameSettings.isMovable or raidFrameSettings.isMovable then
        movableCheckbox:SetChecked(true)
    else
        movableCheckbox:SetChecked(false)
    end
    movableCheckbox:SetScript("OnClick", function(self)
        frameSettings.isMovable = self:GetChecked()
        raidFrameSettings.isMovable = self:GetChecked()
        if frameSettings.isMovable then
            if not IsInRaid() and IsInGroup() then
                partyFrames[1]:SetMovable(frameSettings.isMovable)
                partyFrames[1]:EnableMouse(true)
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
            elseif IsInRaid() then
                raidFrames[1]:SetMovable(raidFrameSettings.isMovable)
                raidFrames[1]:EnableMouse(true)
                raidFrames[1]:RegisterForDrag("LeftButton")
                raidFrames[1]:SetScript("OnDragStart", raidFrames[1].StartMoving)
                raidFrames[1]:SetScript("OnDragStop", function(self)
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
                    -- Re-apply unit/click attributes
                    self:SetAttribute("unit", self.unit or "player")
                    self:RegisterForClicks("AnyUp")
                    self:SetAttribute("type1", "target")
                    self:SetAttribute("type2", "togglemenu")
                    UpdateRaidFramePositions()
                end)
            end
        else
            if not IsInRaid() and IsInGroup() then
                partyFrames[1]:RegisterForDrag()
                partyFrames[1]:SetScript("OnDragStart", nil)
                partyFrames[1]:SetScript("OnDragStop", nil)
            elseif IsInRaid() then
                raidFrames[1]:RegisterForDrag()
                raidFrames[1]:SetScript("OnDragStart", nil)
                raidFrames[1]:SetScript("OnDragStop", nil)
            end
        end
        if not IsInRaid() and IsInGroup() then
            CreateFrames()
        elseif IsInRaid() then
            CreateRaidFrames()
        end
    end)

    -- Tracked Spells Label
    local trackedLabel = scrollChildren[1]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    trackedLabel:SetPoint("TOPLEFT", movableCheckbox, "BOTTOMLEFT", 0, -20)
    trackedLabel:SetText("Tracked Spells (" .. (playerClass or "Unknown") .. ")")

    -- ScrollFrame for spell list
    local spellListScrollFrame = CreateFrame("ScrollFrame", nil, scrollChildren[1], "UIPanelScrollFrameTemplate")
    spellListScrollFrame:SetPoint("TOPLEFT", trackedLabel, "BOTTOMLEFT", 0, -5)
    spellListScrollFrame:SetSize(250, 100)

    local spellList = CreateFrame("Frame", nil, spellListScrollFrame)
    spellList:SetSize(250, 100)
    spellListScrollFrame:SetScrollChild(spellList)

    local function RefreshSpellList()
        for _, child in ipairs({spellList:GetChildren()}) do
            child:Hide()
            child:SetParent(nil)
        end
        local tracked = ZUF_Settings.trackedSpells and ZUF_Settings.trackedSpells[playerClass] or {}
        for i, spellID in ipairs(tracked) do
            local name, _, icon = GetSpellInfo(spellID)
            local rowFrame = CreateFrame("Frame", nil, spellList)
            rowFrame:SetSize(250, 16)
            rowFrame:SetPoint("TOPLEFT", spellList, "TOPLEFT", 0, -((i-1)*16))

            local rowText = rowFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
            rowText:SetPoint("LEFT", rowFrame, "LEFT", 0, 0)
            rowText:SetText((icon and "|T"..icon..":14|t " or "") .. (name or "Unknown") .. " (" .. spellID .. ")")
            rowText:Show()

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
    local addBoxLabel = scrollChildren[1]:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    addBoxLabel:SetPoint("BOTTOMLEFT", spellListScrollFrame, "BOTTOMLEFT", 5, -15)
    addBoxLabel:SetText("Drag a spell here or enter a SpellID:")

    local addBox = CreateFrame("EditBox", nil, scrollChildren[1], "InputBoxTemplate")
    addBox:SetSize(60, 20)
    addBox:SetPoint("TOPLEFT", addBoxLabel, "BOTTOMLEFT", 0, -2)
    addBox:SetAutoFocus(false)
    addBox:SetNumeric(true)
    addBox:SetMaxLetters(7)

    local addButton = CreateFrame("Button", nil, scrollChildren[1], "UIPanelButtonTemplate")
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
        for _, id in ipairs(ZUF_Settings.trackedSpells[playerClass]) do
            if id == spellID then return end
        end
        table.insert(ZUF_Settings.trackedSpells[playerClass], spellID)
        addBox:SetText("")
        RefreshSpellList()
        print("Added spellID:", spellID)
    end)

    local resetSpellsButton = CreateFrame("Button", nil, scrollChildren[1], "UIPanelButtonTemplate")
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
    local trackedBuffsLabel = scrollChildren[1]:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    trackedBuffsLabel:SetPoint("TOPLEFT", addBox, "BOTTOMLEFT", 0, -30)
    trackedBuffsLabel:SetText("Tracked Buffs (" .. (playerClass or "Unknown") .. ")")

    -- ScrollFrame for buffs list
    local buffsListScrollFrame = CreateFrame("ScrollFrame", nil, scrollChildren[1], "UIPanelScrollFrameTemplate")
    buffsListScrollFrame:SetPoint("TOPLEFT", trackedBuffsLabel, "BOTTOMLEFT", 0, -5)
    buffsListScrollFrame:SetSize(250, 100)

    local buffsList = CreateFrame("Frame", nil, buffsListScrollFrame)
    buffsList:SetSize(250, 100)
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
            rowFrame:SetSize(250, 16)
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
    local addBuffBoxLabel = scrollChildren[1]:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    addBuffBoxLabel:SetPoint("BOTTOMLEFT", buffsListScrollFrame, "BOTTOMLEFT", 5, -15)
    addBuffBoxLabel:SetText("Drag a spell here or enter a SpellID:")

    local addBuffBox = CreateFrame("EditBox", nil, scrollChildren[1], "InputBoxTemplate")
    addBuffBox:SetSize(60, 20)
    addBuffBox:SetPoint("TOPLEFT", addBuffBoxLabel, "BOTTOMLEFT", 0, -2)
    addBuffBox:SetAutoFocus(false)
    addBuffBox:SetNumeric(true)
    addBuffBox:SetMaxLetters(7)

    local addBuffButton = CreateFrame("Button", nil, scrollChildren[1], "UIPanelButtonTemplate")
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

    local resetBuffsButton = CreateFrame("Button", nil, scrollChildren[1], "UIPanelButtonTemplate")
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


    ------------------------------------------------
    -- === PARTY TAB CONTENT (scrollChildren[2]) ===
    ------------------------------------------------

    local partyLabel = scrollChildren[2]:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    partyLabel:SetPoint("TOPLEFT", 10, -10)
    partyLabel:SetText("Party Settings")

    -- Dropdown to choose layout
    local layoutDropdown = CreateFrame("Frame", "CF_LayoutDropdown", scrollChildren[2], "UIDropDownMenuTemplate")
    layoutDropdown:SetPoint("TOPLEFT", partyLabel, "BOTTOMLEFT", 0, -10)
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
    local widthSlider = CreateFrame("Slider", "CF_WidthSlider", scrollChildren[2], "OptionsSliderTemplate")
    widthSlider:SetPoint("TOPLEFT", layoutDropdown, "BOTTOMLEFT", 15, -20)
    widthSlider:SetMinMaxValues(70, 125)
    widthSlider:SetValue(frameSettings.frameWidth)
    widthSlider:SetValueStep(1)
    widthSlider:SetObeyStepOnDrag(true)
    widthSlider.text = _G[widthSlider:GetName() .. "Text"]
    widthSlider.text:SetText("Frame Width")
    widthSlider:SetScript("OnValueChanged", function(self, value)
        frameSettings.frameWidth = math.floor(value)
        EnsureSavedVariables()
        ZUF_Settings.frameSettings.frameWidth = math.floor(value)
        UpdateFramePositions()
        UpdateTestFramePositions()
    end)

    -- Slider to adjust frame height
    local heightSlider = CreateFrame("Slider", "CF_HeightSlider", scrollChildren[2], "OptionsSliderTemplate")
    heightSlider:SetPoint("TOPLEFT", widthSlider, "BOTTOMLEFT", 0, -20)
    heightSlider:SetMinMaxValues(45, 90)
    heightSlider:SetValue(frameSettings.frameHeight)
    heightSlider:SetValueStep(1)
    heightSlider:SetObeyStepOnDrag(true)
    heightSlider.text = _G[heightSlider:GetName() .. "Text"]
    heightSlider.text:SetText("Frame Height")
    heightSlider:SetScript("OnValueChanged", function(self, value)
        frameSettings.frameHeight = math.floor(value)
        EnsureSavedVariables()
        ZUF_Settings.frameSettings.frameHeight = math.floor(value)
        UpdateFramePositions()
        UpdateTestFramePositions()
    end)

    -- Reset Position Button
    local resetButton = CreateFrame("Button", nil, scrollChildren[2], "UIPanelButtonTemplate")
    resetButton:SetSize(120, 24)
    resetButton:SetPoint("TOPLEFT", heightSlider, "BOTTOMLEFT", 0, -30)
    resetButton:SetText("Reset Position")
    resetButton:SetScript("OnClick", function()
        local defaultX = ZUF_Defaults.frameSettings.baseX or 30
        local defaultY = ZUF_Defaults.frameSettings.baseY or -40
        frameSettings.baseX = defaultX
        frameSettings.baseY = defaultY
        EnsureSavedVariables()
        ZUF_Settings.frameSettings.baseX = defaultX
        ZUF_Settings.frameSettings.baseY = defaultY
        UpdateFramePositions()
        print("Unit frame position reset to default.")
    end)

    -- Test Mode Button
    local testButton = CreateFrame("Button", nil, scrollChildren[2], "UIPanelButtonTemplate")
    testButton:SetSize(140, 24)
    testButton:SetPoint("TOP", resetButton, "BOTTOM", 0, -10)
    testButton:SetText("Toggle Party Test Mode")
    testButton:SetScript("OnClick", function()
        testMode = not testMode
        if testMode then
            ShowTestFrames()
        else
            HideTestFrames()
        end
    end)

    ------------------------------------------------
    -- === RAID TAB CONTENT (scrollChildren[3]) ===
    ------------------------------------------------

    local raidLabel = scrollChildren[3]:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    raidLabel:SetPoint("TOPLEFT", 10, -10)
    raidLabel:SetText("Raid Settings")

    -- Toggle for raidToggled
    local raidToggleCheckbox = CreateFrame("CheckButton", nil, scrollChildren[3], "UICheckButtonTemplate")
    raidToggleCheckbox:SetPoint("TOPLEFT", raidLabel, "BOTTOMLEFT", 0, -10)
    raidToggleCheckbox.text = raidToggleCheckbox:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    raidToggleCheckbox.text:SetPoint("LEFT", raidToggleCheckbox, "RIGHT", 5, 0)
    raidToggleCheckbox.text:SetText("Enable Raid Frames")
    raidToggleCheckbox:SetChecked(raidToggled or false)
    raidToggleCheckbox:SetScript("OnClick", function(self)
        ZUF_Settings.raidFrameSettings.isToggled = self:GetChecked()
        raidToggled = self:GetChecked()
        if IsInRaid() and raidToggled then
            HideBlizzardFrames()
            CreateRaidFrames()
        elseif IsInRaid() and not raidToggled then
            HideBlizzardFrames()
            HideRaidFrames()
        end
    end)

    -- Slider to adjust frame width
    local raidWidthSlider = CreateFrame("Slider", "CF_RaidWidthSlider", scrollChildren[3], "OptionsSliderTemplate")
    raidWidthSlider:SetPoint("TOPLEFT", raidToggleCheckbox, "BOTTOMLEFT", 15, -20)
    raidWidthSlider:SetMinMaxValues(35, 125)
    raidWidthSlider:SetValue(frameSettings.frameWidth)
    raidWidthSlider:SetValueStep(1)
    raidWidthSlider:SetObeyStepOnDrag(true)
    raidWidthSlider.text = _G[raidWidthSlider:GetName() .. "Text"]
    raidWidthSlider.text:SetText("Frame Width")
    raidWidthSlider:SetScript("OnValueChanged", function(self, value)
        raidFrameSettings.frameWidth = math.floor(value)
        EnsureSavedVariables()
        ZUF_Settings.raidFrameSettings.frameWidth = math.floor(value)
        UpdateRaidFramePositions()
        UpdateRaidTestFramePositions()
    end)

    -- Slider to adjust frame height
    local raidHeightSlider = CreateFrame("Slider", "CF_RaidHeightSlider", scrollChildren[3], "OptionsSliderTemplate")
    raidHeightSlider:SetPoint("TOPLEFT", raidWidthSlider, "BOTTOMLEFT", 0, -20)
    raidHeightSlider:SetMinMaxValues(45, 90)
    raidHeightSlider:SetValue(frameSettings.frameHeight)
    raidHeightSlider:SetValueStep(1)
    raidHeightSlider:SetObeyStepOnDrag(true)
    raidHeightSlider.text = _G[raidHeightSlider:GetName() .. "Text"]
    raidHeightSlider.text:SetText("Frame Height")
    raidHeightSlider:SetScript("OnValueChanged", function(self, value)
        raidFrameSettings.frameHeight = math.floor(value)
        EnsureSavedVariables()
        ZUF_Settings.raidFrameSettings.frameHeight = math.floor(value)
        UpdateRaidFramePositions()
        UpdateRaidTestFramePositions()
    end)

    -- Reset Position Button
    local raidResetButton = CreateFrame("Button", nil, scrollChildren[3], "UIPanelButtonTemplate")
    raidResetButton:SetSize(120, 24)
    raidResetButton:SetPoint("TOPLEFT", raidHeightSlider, "BOTTOMLEFT", 0, -30)
    raidResetButton:SetText("Reset Position")
    raidResetButton:SetScript("OnClick", function()
        local defaultX = ZUF_Defaults.raidFrameSettings.baseX or 30
        local defaultY = ZUF_Defaults.raidFrameSettings.baseY or -40
        raidFrameSettings.baseX = defaultX
        raidFrameSettings.baseY = defaultY
        EnsureSavedVariables()
        ZUF_Settings.raidFrameSettings.baseX = defaultX
        ZUF_Settings.raidFrameSettings.baseY = defaultY
        UpdateRaidFramePositions()
        UpdateRaidTestFramePositions()
        print("Unit frame position reset to default.")
    end)

    -- Test Raid Mode Button
    local testRaidButton = CreateFrame("Button", nil, scrollChildren[3], "UIPanelButtonTemplate")
    testRaidButton:SetSize(140, 24)
    testRaidButton:SetPoint("TOP", raidResetButton, "BOTTOM", 0, -10)
    testRaidButton:SetText("Toggle Raid Test Mode")
    testRaidButton:SetScript("OnClick", function()
        testMode = not testMode
        if testMode then
            ShowRaidTestFrames()
        else
            HideRaidTestFrames()
        end
    end)

    configFrame:Hide()
    return configFrame
end
