IsJohnDead = IsJohnDead or {}

local _G = _G or getfenv(0)
local addon = IsJohnDead

addon.johnUnitID = nil
addon.isInRaid = false
addon.lastDeathTime = 0
addon.johnDetected = false
addon.deathCount = 0

addon.deathNames = {
    "Johnbbwman",
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
    "Johnpaperarmorman",
    "Johnreztimerlongman",
    "Johnghostreleasedman",
    "Johncorpserunman",
    "Johnspirithealsman",
    "Johnlagspikeman",
    "Johnbackpedalman",
    "Johnfelloffcliffman",
    "Johnstoodinfrontman",
    "Johnparryhastedman",
    "Johndoomfireman",
    "Johnpatchwerkedman",
    "Johnoneshotcritman",
    "Johnoveraggroman",
    "Johntrainwreckman",
    "Johnfloorismylifeman",
    "Johnvoidzoneman",
    "Johncleaveenjoyerman",
    "Johnafkmidpullman",
    "Johnlogouttimerhitman",
    "Johnhealeroomman",
    "Johnforgotcooldownman",
    "Johnbubblewasdownman",
    "Johnpotiononcooldownman",
    "Johndisconnectedman",
    "Johnkeyboardwalkman",
    "Johnwrongtargetman",
    "Johnbehindbreathman",
    "Johnsharkbaitman",
    "Johndrowningman",
    "Johnlavahopman",
    "Johnaoedownman",
    "Johnpullsadman",
    "Johntoosquishyman",
    "Johnheaddeskman",
    "Johnfearpulletman",
    "Johntailwhippedman",
    "Johnknockbackcliffman",
    "Johnmisplacedtotemman",
    "Johnchainlightningedman",
    "Johncursestackedman",
    "Johngoonerman",
    "Johnprepotforgotman",
    "Johnchubbychaserman",
    "Johnpoisoncloudman",
    "Johnshadowcrashman",
    "Johnmeteorsmashedman",
    "Johnbleedoutman",
    "Johnmortalwoundman",
    "Johnbloodpoolman",
    "Johnaggroresetman",
    "Johnmindcontrolledman",
    "Johnstunsilencedman",
    "Johntwoshotman",
    "Johnmindblastedman",
    "Johnthreatcapman",
    "Johnholynovaagroman",
    "Johnwrongphaseman",
    "Johndidntdispelman",
    "Johntankspotman",
    "Johnraidstackman"
}

local frame = CreateFrame("Frame", "IsJohnDeadFrame")

function addon:UpdateRaidStatus()
    local numRaidMembers = GetNumRaidMembers()
    local numPartyMembers = GetNumPartyMembers()

    self.isInRaid = (numRaidMembers > 0)
    local isInParty = (numPartyMembers > 0)

    if self.isInRaid then
        self:ScanForJohn()
    elseif isInParty then
        self:ScanForJohnInParty()
    else
        self.johnUnitID = nil
        self.johnDetected = false
    end
end

function addon:ScanForJohn()
    if not self.isInRaid then
        return
    end

    local foundJohn = false

    for i = 1, 40 do
        local unitID = "raid" .. tostring(i)
        local name = UnitName(unitID)

        if name and name == "Johnhealrman" then
            if not self.johnDetected then
                DEFAULT_CHAT_FRAME:AddMessage("Johnhealrman detected in raid", 0, 1, 0)
                self.johnDetected = true
            end
            self.johnUnitID = unitID
            foundJohn = true
            break
        end
    end

    if not foundJohn then
        self.johnUnitID = nil
        self.johnDetected = false
    end
end

function addon:ScanForJohnInParty()
    local foundJohn = false

    for i = 1, GetNumPartyMembers() do
        local unitID = "party" .. tostring(i)
        local name = UnitName(unitID)

        if name and name == "Johnhealrman" then
            if not self.johnDetected then
                DEFAULT_CHAT_FRAME:AddMessage("Johnhealrman detected in party", 0, 1, 0)
                self.johnDetected = true
            end
            self.johnUnitID = unitID
            foundJohn = true
            break
        end
    end

    if not foundJohn then
        self.johnUnitID = nil
        self.johnDetected = false
    end
end

function addon:CheckJohnHealth()
    if not self.johnUnitID or not UnitExists(self.johnUnitID) then
        return
    end

    if UnitIsDead(self.johnUnitID) then
        if (GetTime() - self.lastDeathTime) > 5 then
            local numNames = table.getn(self.deathNames)
            local randomIndex = math.random(1, numNames)
            local randomName = self.deathNames[randomIndex]
            self.deathCount = self.deathCount + 1
            local deathMessage = randomName .. " [" .. tostring(self.deathCount) .. "]"
            SendChatMessage(deathMessage, "RAID")
            self.lastDeathTime = GetTime()
        end
    end
end

local function OnEvent()
    if event == "PLAYER_ENTERING_WORLD" then
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

frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("RAID_ROSTER_UPDATE")
frame:RegisterEvent("UNIT_HEALTH")

frame:SetScript("OnEvent", OnEvent)
