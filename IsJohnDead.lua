IsJohnDead = IsJohnDead or {}

local _G = _G or getfenv(0)
local addon = IsJohnDead

addon.johnUnitID = nil
addon.isInRaid = false
addon.johnWasLowHealth = false
addon.lastWarningTime = 0
addon.lastDeathTime = 0
addon.debugMode = false
addon.outputEnabled = true

addon.deathNames = {
    "Johnrespawnman",
    "Johnloggedoutman",
    "Johngotpwnedman",
    "Johnfailedman",
    "Johntriedman",
    "Johnscrewedupman",
    "Johnwipedman",
    "Johnaggrodman",
    "Johnpulledtoomuchman",
    "Johnbrokeman",
    "Johnoopsiman",
    "Johnwhoopsiedman",
    "JohnGameOverman",
    "JohnInsertCoinman",
    "JohnTryAgainman",
    "JohnNeedsarezagainman",
    "Johnneededmorehealsman",
    "Johndpsedtoohardman",
    "Johntankedthefloorman",
    "Johnstoodinthefireman",
    "Johnleeroyjenkinsedman",
    "Johnignoredbossmechanicsman",
    "Johnflatlineman",
    "Johnnohealthman",
    "Johncleavecollectorman",
    "Johnhealerneedshealsman",
    "Johnpaperarmorman"
}

IsJohnDeadDB = IsJohnDeadDB or {
    debugMode = false,
    outputEnabled = true
}

local frame = CreateFrame("Frame", "IsJohnDeadFrame")

function addon:DebugPrint(message)
    if self.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("[IsJohnDead] " .. tostring(message), 1, 1, 0)
    end
end

function addon:UpdateRaidStatus()
    local wasInRaid = self.isInRaid
    local numRaidMembers = GetNumRaidMembers()
    local numPartyMembers = GetNumPartyMembers()

    self.isInRaid = (numRaidMembers > 0)
    local isInParty = (numPartyMembers > 0)

    self:DebugPrint("Raid: " .. tostring(numRaidMembers) .. " Party: " .. tostring(numPartyMembers))

    if self.isInRaid then
        if not wasInRaid then
            self:DebugPrint("Entered raid - scanning")
        end
        self:ScanForJohn()
    elseif isInParty then
        self:DebugPrint("In party - scanning")
        self:ScanForJohnInParty()
    else
        if wasInRaid then
            self:DebugPrint("Left raid/party")
        end
        self.johnUnitID = nil
        self.johnWasLowHealth = false
    end
end

function addon:ScanForJohn()
    if not self.isInRaid then
        return
    end

    local foundJohn = false
    local numRaidMembers = GetNumRaidMembers()

    self:DebugPrint("Scanning " .. tostring(numRaidMembers) .. " raid members")

    for i = 1, 40 do
        local unitID = "raid" .. tostring(i)
        local name = UnitName(unitID)

        if name then
            self:DebugPrint("Slot " .. tostring(i) .. ": " .. tostring(name))

            if name == "Johnhealrman" then
                self.johnUnitID = unitID
                foundJohn = true

                DEFAULT_CHAT_FRAME:AddMessage("John is in the Raid!", 0, 1, 0)
                self:DebugPrint("Found Johnhealrman as " .. tostring(unitID))

                self:CheckJohnHealth()
                break
            end
        end
    end

    if not foundJohn and self.johnUnitID then
        self:DebugPrint("Johnhealrman left the raid")
        self.johnUnitID = nil
        self.johnWasLowHealth = false
    end
end

function addon:ScanForJohnInParty()
    local foundJohn = false

    for i = 1, GetNumPartyMembers() do
        local unitID = "party" .. tostring(i)
        local name = UnitName(unitID)

        if name then
            self:DebugPrint("Party " .. tostring(i) .. ": " .. tostring(name))

            if name == "Johnhealrman" then
                self.johnUnitID = unitID
                foundJohn = true
                DEFAULT_CHAT_FRAME:AddMessage("John is in the Party!", 0, 1, 0)
                self:DebugPrint("Found Johnhealrman as " .. tostring(unitID))
                self:CheckJohnHealth()
                break
            end
        end
    end

    if not foundJohn and self.johnUnitID then
        self:DebugPrint("Johnhealrman left the party")
        self.johnUnitID = nil
        self.johnWasLowHealth = false
    end
end

function addon:CheckJohnHealth()
    if not self.johnUnitID or not UnitExists(self.johnUnitID) then
        return
    end

    if UnitIsDead(self.johnUnitID) then
        if not self.johnWasLowHealth or (GetTime() - self.lastDeathTime) > 5 then
            if self.outputEnabled then
                local numNames = table.getn(self.deathNames)
                local randomIndex = math.random(1, numNames)
                local randomName = self.deathNames[randomIndex]
                SendChatMessage(randomName, "RAID")
            end
            self.lastDeathTime = GetTime()
            self:DebugPrint("John died - " .. (self.outputEnabled and "sent message" or "output disabled"))
        end
        self.johnWasLowHealth = false
        return
    end

    local currentHP = UnitHealth(self.johnUnitID)
    local maxHP = UnitHealthMax(self.johnUnitID)

    if maxHP > 0 then
        local healthPercent = (currentHP / maxHP) * 100

        if healthPercent <= 20 and not self.johnWasLowHealth then
            if (GetTime() - self.lastWarningTime) > 5 then
                if self.outputEnabled then
                    SendChatMessage("Johnhealrman is almost dead! Heal him quick!", "YELL")
                end
                self.johnWasLowHealth = true
                self.lastWarningTime = GetTime()
                self:DebugPrint("John at " .. tostring(string.format("%.1f", healthPercent)) .. "% - warning sent")
            end
        elseif healthPercent > 25 then
            self.johnWasLowHealth = false
        end

        self:DebugPrint("John HP: " .. tostring(string.format("%.1f", healthPercent)) .. "%")
    end
end

local function OnEvent()
    if event == "ADDON_LOADED" and arg1 == "IsJohnDead" then
        addon.debugMode = IsJohnDeadDB.debugMode or false
        addon.outputEnabled = IsJohnDeadDB.outputEnabled
        if addon.outputEnabled == nil then
            addon.outputEnabled = true
        end
        addon:DebugPrint("IsJohnDead loaded v1.1")

    elseif event == "PLAYER_ENTERING_WORLD" then
        addon:UpdateRaidStatus()

    elseif event == "RAID_ROSTER_UPDATE" then
        addon:UpdateRaidStatus()

    elseif event == "UNIT_HEALTH" then
        local unit = arg1
        if unit and addon.johnUnitID and unit == addon.johnUnitID then
            addon:CheckJohnHealth()
        end
    end
end

local function SlashHandler(msg)
    local command = string.lower(msg or "")

    if command == "status" then
        local status = "IsJohnDead Status:"
        DEFAULT_CHAT_FRAME:AddMessage(status, 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("In Raid: " .. (addon.isInRaid and "Yes" or "No"), 0.8, 0.8, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage("John Found: " .. (addon.johnUnitID and ("Yes (" .. tostring(addon.johnUnitID) .. ")") or "No"), 0.8, 0.8, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage("Debug: " .. (addon.debugMode and "On" or "Off"), 0.8, 0.8, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage("Output: " .. (addon.outputEnabled and "On" or "Off"), 0.8, 0.8, 0.8)

    elseif command == "debug" then
        addon.debugMode = not addon.debugMode
        IsJohnDeadDB.debugMode = addon.debugMode
        DEFAULT_CHAT_FRAME:AddMessage("IsJohnDead debug: " .. (addon.debugMode and "ON" or "OFF"), 1, 1, 0)

    elseif command == "output" then
        addon.outputEnabled = not addon.outputEnabled
        IsJohnDeadDB.outputEnabled = addon.outputEnabled
        DEFAULT_CHAT_FRAME:AddMessage("IsJohnDead output: " .. (addon.outputEnabled and "ON" or "OFF"), 1, 1, 0)

    elseif command == "scan" then
        addon:UpdateRaidStatus()
        DEFAULT_CHAT_FRAME:AddMessage("Manual scan completed", 1, 1, 0)

    elseif command == "test" then
        if addon.johnUnitID then
            addon:CheckJohnHealth()
            DEFAULT_CHAT_FRAME:AddMessage("Health check performed", 1, 1, 0)
        else
            DEFAULT_CHAT_FRAME:AddMessage("Johnhealrman not found", 1, 0.5, 0)
        end

    else
        DEFAULT_CHAT_FRAME:AddMessage("IsJohnDead Commands:", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/ijd status - Show status", 0.8, 0.8, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage("/ijd debug - Toggle debug", 0.8, 0.8, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage("/ijd output - Toggle output", 0.8, 0.8, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage("/ijd scan - Manual scan", 0.8, 0.8, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage("/ijd test - Test health check", 0.8, 0.8, 0.8)
    end
end

frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("RAID_ROSTER_UPDATE")
frame:RegisterEvent("UNIT_HEALTH")

frame:SetScript("OnEvent", OnEvent)

SLASH_ISJOHNDEAD1 = "/ijd"
SlashCmdList["ISJOHNDEAD"] = SlashHandler
