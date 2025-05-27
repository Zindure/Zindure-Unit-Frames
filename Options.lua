-- Options/config panel

function CreateConfigWindow()
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
            rowFrame:SetPoint("TOPLEFT", spellList, "TOPLEFT", 0, -((i-1)*16))

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