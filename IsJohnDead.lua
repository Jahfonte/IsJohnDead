-- IsJohnDead - Tracks Johnhealrman's health status in raids
-- Author: Jah

IsJohnDead = {}
IsJohnDead.johnUnitID = nil
IsJohnDead.isInRaid = false
IsJohnDead.johnWasLowHealth = false
IsJohnDead.lastWarningTime = 0
IsJohnDead.lastDeathTime = 0
IsJohnDead.debugMode = false
IsJohnDead.outputEnabled = true

-- Randomized death names
IsJohnDead.deathNames = {
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
    "Johncleavecollectorman"
}

-- Saved variables
IsJohnDeadDB = IsJohnDeadDB or {
    debugMode = false,
    outputEnabled = true
}

-- Event frame
local eventFrame = CreateFrame("Frame")

-- Initialize addon
function IsJohnDead:OnLoad()
    -- Register events
    eventFrame:RegisterEvent("RAID_ROSTER_UPDATE")
    eventFrame:RegisterEvent("UNIT_HEALTH")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("ADDON_LOADED")
    
    -- Set event handler
    eventFrame:SetScript("OnEvent", IsJohnDead.OnEvent)
    
    -- Register slash commands
    SLASH_ISJOHNDEAD1 = "/ijd"
    SlashCmdList["ISJOHNDEAD"] = IsJohnDead.SlashHandler
end

-- Event handler
function IsJohnDead.OnEvent(self, event, ...)
    if event == "ADDON_LOADED" and arg1 == "IsJohnDead" then
        IsJohnDead.debugMode = IsJohnDeadDB.debugMode or false
        IsJohnDead.outputEnabled = IsJohnDeadDB.outputEnabled or true
        IsJohnDead:DebugPrint("IsJohnDead loaded")
        
    elseif event == "PLAYER_ENTERING_WORLD" then
        IsJohnDead:UpdateRaidStatus()
        
    elseif event == "RAID_ROSTER_UPDATE" then
        IsJohnDead:UpdateRaidStatus()
        
    elseif event == "UNIT_HEALTH" then
        local unit = arg1
        if unit and IsJohnDead.johnUnitID and unit == IsJohnDead.johnUnitID then
            IsJohnDead:CheckJohnHealth()
        end
    end
end

-- Update raid status and scan for John
function IsJohnDead:UpdateRaidStatus()
    local wasInRaid = self.isInRaid
    self.isInRaid = (GetNumRaidMembers() > 0)
    
    if self.isInRaid then
        if not wasInRaid then
            self:DebugPrint("Entered raid - scanning for Johnhealrman")
        end
        self:ScanForJohn()
    else
        if wasInRaid then
            self:DebugPrint("Left raid")
        end
        self.johnUnitID = nil
        self.johnWasLowHealth = false
    end
end

-- Scan raid roster for Johnhealrman
function IsJohnDead:ScanForJohn()
    if not self.isInRaid then
        return
    end
    
    local foundJohn = false
    
    for i = 1, GetNumRaidMembers() do
        local unitID = "raid" .. i
        local name = UnitName(unitID)
        
        if name == "Johnhealrman" then
            self.johnUnitID = unitID
            foundJohn = true
            
            -- Show confirmation message (internal note)
            DEFAULT_CHAT_FRAME:AddMessage("John is in the Raid!", 0, 1, 0)
            self:DebugPrint("Found Johnhealrman as " .. unitID)
            
            -- Check his current health
            self:CheckJohnHealth()
            break
        end
    end
    
    if not foundJohn and self.johnUnitID then
        self:DebugPrint("Johnhealrman left the raid")
        self.johnUnitID = nil
        self.johnWasLowHealth = false
    end
end

-- Check John's health and send warnings
function IsJohnDead:CheckJohnHealth()
    if not self.johnUnitID or not UnitExists(self.johnUnitID) then
        return
    end
    
    -- Check if John is dead
    if UnitIsDead(self.johnUnitID) then
        if not self.johnWasLowHealth or (GetTime() - self.lastDeathTime) > 5 then
            if self.outputEnabled then
                -- Pick random death name (vanilla 1.12 compatible)
                local randomIndex = math.random(1, table.getn(self.deathNames))
                local randomName = self.deathNames[randomIndex]
                SendChatMessage(randomName, "RAID")
            end
            self.lastDeathTime = GetTime()
            self:DebugPrint("John died - " .. (self.outputEnabled and "sent death message" or "output disabled"))
        end
        self.johnWasLowHealth = false
        return
    end
    
    -- Check health percentage
    local currentHP = UnitHealth(self.johnUnitID)
    local maxHP = UnitHealthMax(self.johnUnitID)
    
    if maxHP > 0 then
        local healthPercent = (currentHP / maxHP) * 100
        
        -- Check for low health (20% threshold)
        if healthPercent <= 20 and not self.johnWasLowHealth then
            if (GetTime() - self.lastWarningTime) > 5 then  -- 5 second cooldown
                if self.outputEnabled then
                    SendChatMessage("Johnhealrman is almost dead! Heal him quick!", "YELL")
                end
                self.johnWasLowHealth = true
                self.lastWarningTime = GetTime()
                self:DebugPrint("John at " .. string.format("%.1f", healthPercent) .. "% health - " .. (self.outputEnabled and "sent warning" or "output disabled"))
            end
        elseif healthPercent > 25 then
            -- Reset warning flag when health goes above 25%
            self.johnWasLowHealth = false
        end
        
        self:DebugPrint("John health: " .. string.format("%.1f", healthPercent) .. "%")
    end
end

-- Debug print function
function IsJohnDead:DebugPrint(message)
    if self.debugMode then
        DEFAULT_CHAT_FRAME:AddMessage("[IsJohnDead Debug] " .. message, 1, 1, 0)
    end
end

-- Slash command handler
function IsJohnDead.SlashHandler(msg)
    local command = string.lower(msg or "")
    
    if command == "status" then
        local status = "IsJohnDead Status:\n"
        status = status .. "In Raid: " .. (IsJohnDead.isInRaid and "Yes" or "No") .. "\n"
        status = status .. "John Found: " .. (IsJohnDead.johnUnitID and "Yes (" .. IsJohnDead.johnUnitID .. ")" or "No") .. "\n"
        status = status .. "Debug Mode: " .. (IsJohnDead.debugMode and "On" or "Off") .. "\n"
        status = status .. "Output Enabled: " .. (IsJohnDead.outputEnabled and "On" or "Off")
        DEFAULT_CHAT_FRAME:AddMessage(status, 1, 1, 1)
        
    elseif command == "debug" then
        IsJohnDead.debugMode = not IsJohnDead.debugMode
        IsJohnDeadDB.debugMode = IsJohnDead.debugMode
        DEFAULT_CHAT_FRAME:AddMessage("IsJohnDead debug mode: " .. (IsJohnDead.debugMode and "ON" or "OFF"), 1, 1, 0)
        
    elseif command == "output" then
        IsJohnDead.outputEnabled = not IsJohnDead.outputEnabled
        IsJohnDeadDB.outputEnabled = IsJohnDead.outputEnabled
        DEFAULT_CHAT_FRAME:AddMessage("IsJohnDead output: " .. (IsJohnDead.outputEnabled and "ON" or "OFF"), 1, 1, 0)
        
    elseif command == "scan" then
        IsJohnDead:ScanForJohn()
        DEFAULT_CHAT_FRAME:AddMessage("Manual raid scan completed", 1, 1, 0)
        
    elseif command == "test" then
        if IsJohnDead.johnUnitID then
            IsJohnDead:CheckJohnHealth()
            DEFAULT_CHAT_FRAME:AddMessage("Health check performed", 1, 1, 0)
        else
            DEFAULT_CHAT_FRAME:AddMessage("Johnhealrman not found in raid", 1, 0.5, 0)
        end
        
    else
        DEFAULT_CHAT_FRAME:AddMessage("IsJohnDead Commands:", 1, 1, 1)
        DEFAULT_CHAT_FRAME:AddMessage("/ijd status - Show monitoring status", 0.8, 0.8, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage("/ijd debug - Toggle debug mode", 0.8, 0.8, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage("/ijd output - Toggle chat output on/off", 0.8, 0.8, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage("/ijd scan - Manual raid scan", 0.8, 0.8, 0.8)
        DEFAULT_CHAT_FRAME:AddMessage("/ijd test - Test health check", 0.8, 0.8, 0.8)
    end
end

-- Initialize when loaded
IsJohnDead:OnLoad()