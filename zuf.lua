-- Smart hiding function: only runs logic if frames are actually visible
function HideBlizzardFrames()
    -- Avoid re-running the function if it's already running
    if isChecking then return end
    isChecking = true
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
    if raidToggled and IsInRaid() then
        
        -- Move Blizzard Raid Frames off-screen if they try to show
        if CompactRaidFrameContainer then
            CompactRaidFrameContainer:ClearAllPoints()
            CompactRaidFrameContainer:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", -1000, -1000)
        end

        if CompactRaidFrameContainer then
            CompactRaidFrameContainer:UnregisterAllEvents()
            CompactRaidFrameContainer:SetParent(hiddenFrame)
            CompactRaidFrameContainer:Hide()
        end
        -- Hide Blizzard Main Tank and Main Assist frames
        for i = 1, 8 do -- 8 is a safe upper bound for raid groups
            local tankFrame = _G["CompactRaidGroup"..i.."MainTank"]
            local assistFrame = _G["CompactRaidGroup"..i.."MainAssist"]
            if tankFrame then
                tankFrame:UnregisterAllEvents()
                tankFrame:SetParent(hiddenFrame)
                tankFrame:Hide()
            end
            if assistFrame then
                assistFrame:UnregisterAllEvents()
                assistFrame:SetParent(hiddenFrame)
                assistFrame:Hide()
            end
        end
    end
    if IsInRaid() and not raidToggled then

        if CompactRaidFrameContainer then
            CompactRaidFrameContainer:ClearAllPoints()
            CompactRaidFrameContainer:SetPoint("TOPLEFT", CompactRaidFrameManager, "TOPRIGHT", 0, -9)
        end
        -- Set Blizzard Raid UI to shown
        if CompactRaidFrameManager_SetSetting then

            CompactRaidFrameManager_SetSetting("IsShown", 1)
        end

        if CompactRaidFrameManager then
            CompactRaidFrameManager:SetParent(UIParent)
            CompactRaidFrameManager:Show()
        end
        if CompactRaidFrameContainer then
            CompactRaidFrameContainer:SetParent(UIParent)
            CompactRaidFrameContainer:Show()
            CompactRaidFrameContainer:RegisterAllEvents()
            -- Force a layout update (sometimes needed)
            if CompactRaidFrameContainer.flowFrames and type(CompactRaidFrameContainer.Layout) == "function" then
                CompactRaidFrameContainer:Layout()
            end
        end
    end
    isChecking = false
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

-- Watchdog to keep Blizzard frames hidden
local function StartBlizzardFrameWatchdog()
    local interval = 2 -- seconds
    local function watchdog()
        HideBlizzardFrames()
        C_Timer.After(interval, watchdog)
    end
    watchdog()
end

-- Init
local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:RegisterEvent("GROUP_ROSTER_UPDATE") -- Triggered when group composition changes
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

        if not ZUF_Settings.raidFrameSettings then
            ZUF_Settings.raidFrameSettings = CopyTable(ZUF_Defaults.raidFrameSettings)
            raidFrameSettings = ZUF_Settings.raidFrameSettings
        else 
            raidFrameSettings = ZUF_Settings.raidFrameSettings
        end

        local _, playerClass = UnitClass("player")
        EFFECT_SPELLIDS = (ZUF_Settings.trackedSpells and ZUF_Settings.trackedSpells[playerClass]) or {}
        BUFF_SPELLIDS = (ZUF_Settings.trackedBuffs and ZUF_Settings.trackedBuffs[playerClass]) or {}
        raidToggled = ZUF_Settings.raidFrameSettings.isToggled

        if IsInRaid() and ZUF_Settings.raidFrameSettings.IsToggled then
            CreateRaidFrames()
        elseif IsInGroup() then
            CreateFrames()
        end
        HideBlizzardFrames()
        C_Timer.After(5, HideBlizzardFrames)
        C_Timer.After(10, HideBlizzardFrames)

    elseif event == "PLAYER_LOGIN" or event == "GROUP_ROSTER_UPDATE" then
        if ZUF_Settings and frameSettings then
            if IsInRaid() and raidToggled then
                HidePartyFrames()
                CreateRaidFrames()
            elseif IsInRaid() and not raidToggled then
                HidePartyFrames()
            elseif IsInGroup() then
                HideRaidFrames()
                CreateFrames()
            else
                -- Not in a group or raid: hide all custom frames
                HidePartyFrames()
                HideRaidFrames()
            end
            C_Timer.After(1, HideBlizzardFrames)
        end
    end

    -- Start watchdog after login
    if event == "PLAYER_LOGIN" then
        --[[ StartBlizzardFrameWatchdog() ]]
    end
end)
