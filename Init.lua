-- Shared variables and utility functions

addonName = "Zindure's Unit Frames"
LSM = LibStub("LibSharedMedia-3.0")

LSM:Register("statusbar", "Smooth", "Interface\\AddOns\\zindure-unit-frames\\media\\ElvUI2.tga")
LSM:Register("font", "MyFont", "Interface\\AddOns\\zindure-unit-frames\\media\\Arial.ttf")

testMode = false
testFrames = {}
EFFECT_SPELLIDS = {}
powerBarHeight = 6

partyFrames = {}
frameSettings = nil -- will be set from saved variables

local hiddenFrame = CreateFrame("Frame")
hiddenFrame:Hide()

function EnsureSavedVariables()
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

function CopyTable(tbl)
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