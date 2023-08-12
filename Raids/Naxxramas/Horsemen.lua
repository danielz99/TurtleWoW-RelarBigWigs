
local module, L = BigWigs:ModuleDeclaration("The Four Horsemen", "Naxxramas")
local thane = AceLibrary("Babble-Boss-2.2")["Thane Korth'azz"]
local mograine = AceLibrary("Babble-Boss-2.2")["Highlord Mograine"]
local zeliek = AceLibrary("Babble-Boss-2.2")["Sir Zeliek"]
local blaumeux = AceLibrary("Babble-Boss-2.2")["Lady Blaumeux"]

module.revision = 20005
module.enabletrigger = { thane, mograine, zeliek, blaumeux }
module.toggleoptions = { "mark", "shieldwall", -1, "meteor", "void", "wrath", "bosskill" }

L:RegisterTranslations("enUS", function()
    return {
        cmd = "Horsemen",

        mark_cmd = "mark",
        mark_name = "Mark Alerts",
        mark_desc = "Warn for marks",

        shieldwall_cmd = "shieldwall",
        shieldwall_name = "Shieldwall Alerts",
        shieldwall_desc = "Warn for shieldwall",

        void_cmd = "void",
        void_name = "Void Zone Alerts",
        void_desc = "Warn on Lady Blaumeux casting Void Zone.",

        meteor_cmd = "meteor",
        meteor_name = "Meteor Alerts",
        meteor_desc = "Warn on Thane casting Meteor.",

        wrath_cmd = "wrath",
        wrath_name = "Holy Wrath Alerts",
        wrath_desc = "Warn on Zeliek casting Wrath.",

        markbar = "Mark %d",
        mark_warn = "Mark %d!",
        mark_warn_5 = "Mark %d in 5 sec",
        marktrigger1 = "afflicted by Mark of Zeliek",
        marktrigger2 = "afflicted by Mark of Korth'azz",
        marktrigger3 = "afflicted by Mark of Blaumeux",
        marktrigger4 = "afflicted by Mark of Mograine",

        voidtrigger = "Your life is mine!",
        voidwarn = "Void Zone Incoming",
        voidbar = "Void Zone",

        meteortrigger = "Thane Korth'azz's Meteor hits ",
        meteortrigger2 = "I like my meat extra crispy!",
        meteorwarn = "Meteor!",
        meteorbar = "Meteor",

        wrathtrigger = "Sir Zeliek's Holy Wrath hits ",
        wrathtrigger2 = "I have no choice but to obey!",
        wrathwarn = "Holy Wrath!",
        wrathbar = "Holy Wrath",

        startwarn = "The Four Horsemen Engaged! Mark in 20 sec",

        shieldwallbar = "%s - Shield Wall",
        shieldwalltrigger = "(.*) gains Shield Wall.",
        shieldwall_warn = "%s - Shield Wall for 20 sec",
        shieldwall_warn_over = "%s - Shield Wall GONE!",
    }
end)

L:RegisterTranslations("esES", function()
    return {
        --cmd = "Horsemen",

        --mark_cmd = "mark",
        mark_name = "Alerta de Marcas",
        mark_desc = "Avisa para Marcas",

        --shieldwall_cmd  = "shieldwall",
        shieldwall_name = "Alerta de Muro de escudo",
        shieldwall_desc = "Avisa para Muro de escudo",

        --void_cmd = "void",
        void_name = "Alerta de Zona de vacío",
        void_desc = "Avisa cuando Lady Blaumeux lance Zona de vacío.",

        --meteor_cmd = "meteor",
        meteor_name = "Alerta de Meteoro",
        meteor_desc = "Avisa cuando Thane lance Meteoro.",

        --wrath_cmd = "wrath",
        wrath_name = "Alerta de Cólera sagrada",
        wrath_desc = "Avisa cuando Zeliek lance Cólera sagrada.",

        markbar = "Marca de %d",
        mark_warn = "¡Marca de %d!",
        mark_warn_5 = "Marca de %d en 5 segundos",
        marktrigger1 = "sufre de Marca de Zeliek",
        marktrigger2 = "sufre de Marca de Korth'azz",
        marktrigger3 = "sufre de Marca de Blaumeux",
        marktrigger4 = "sufre de Marca de Mograine",

        voidtrigger = "Lady Blaumeux lanza Zona de vacío.",
        voidwarn = "Zona de vacío entrante",
        voidbar = "Zona de vacío",

        meteortrigger = "Meteoro de Thane Korth'azz golpea ",
        meteortrigger2 = "I like my meat extra crispy!",
        meteorwarn = "¡Meteoro!",
        meteorbar = "Meteoro",

        wrathtrigger = "Cólera sagrada de Sir Zeliek impacta ",
        wrathtrigger2 = "I have no choice but to obey!",
        wrathwarn = "¡Cólera sagrada!",
        wrathbar = "Cólera sagrada",

        startwarn = "Entrando en combate con Los Cuatro Caballoshombre! Marca en ~17 segundos",

        shieldwallbar = "%s - Muro de escudo",
        shieldwalltrigger = "(.*) gana Muro de escudo.",
        shieldwall_warn = "%s - Muro de escudo por 20 segundos",
        shieldwall_warn_over = "¡%s - Muro de escudo DESAPARECE!",
    }
end)

local timer = {
    firstMark = 20,
    mark = 12,
    firstMeteor = 20,
    meteor = { 12, 15 },
    firstWrath = 20,
    wrath = { 10, 14 },
    firstVoid = 15,
    void = { 12, 15 },
    shieldwall = 20,
}
local icon = {
    mark = "Spell_Shadow_CurseOfAchimonde",
    meteor = "Spell_Fire_Fireball02",
    wrath = "Spell_Holy_Excorcism",
    void = "spell_shadow_antishadow",
    shieldwall = "Ability_Warrior_ShieldWall",
}
local syncName = {
    shieldwall = "HorsemenShieldWall" .. module.revision,
    mark = "HorsemenMark" .. module.revision,
    DelayedVoidZone = "HorsemenDelayedVoidZone" .. module.revision,
    wrath = "HorsemenWrath" .. module.revision,
    meteor = "HorsemenMeteor" .. module.revision,
}

local void_trigger = "Lady Blaumeux casts Void Zone"

local times = nil
local globalMarks = 0
local playerGroup = 0

local MOVE_SAFE_SPOT = "MOVE TO |cf75DE52fSAFE SPOT"
local MOVE_THANE = "MOVE TO |cff7b9a2fTHANE|r - STACK ON TANK"
local MOVE_MOGRAINE = "MOVE TO |cffb2422eMOGRAINE"

function module:OnEnable()
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS")
    self:RegisterEvent("CHAT_MSG_MONSTER_SAY")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE", "MarkEvent")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE", "MarkEvent")
    self:RegisterEvent("CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE", "MarkEvent")

    self:ThrottleSync(3, syncName.shieldwall)
    self:ThrottleSync(8, syncName.mark)
    self:ThrottleSync(5, syncName.DelayedVoidZone)
    self:ThrottleSync(5, syncName.wrath)
    self:ThrottleSync(5, syncName.meteor)
end

function module:OnSetup()
    self:RegisterEvent("CHAT_MSG_COMBAT_HOSTILE_DEATH")

    self.marks = 0
    self.deaths = 0

    globalMarks = 0

    times = {}
end

local fhAlert = CreateFrame("Frame", "fhAlert");

fhAlert:RegisterEvent("CHAT_MSG_ADDON")

fhAlert:SetPoint("CENTER", UIParent, "CENTER", 0, -100);

fhAlert.text = fhAlert:CreateFontString("$parentText", "OVERLAY");
fhAlert.text:Hide()
fhAlert.text:SetWidth(800);
fhAlert.text:SetHeight(108);
fhAlert.text:SetFont(STANDARD_TEXT_FONT, 50, "OUTLINE");
fhAlert.text:SetPoint("CENTER", UIParent, 0, 100);
fhAlert.text:SetJustifyV("MIDDLE");
fhAlert.text:SetJustifyH("CENTER");

local fh_alert = CreateFrame('Frame')
fh_alert:Hide()
function fh_alert_marks(message)
    fhAlert.text:SetText(message);
    DEFAULT_CHAT_FRAME:AddMessage(message)
    fh_alert:Show()
end

fhAlert.healerIndex = 0

fhAlert:SetScript("OnEvent", function()
    if event then
        if event == 'CHAT_MSG_ADDON' and arg1 == "TWABW" then
            local data = string.split(arg2, ' ')
            for _, d in data do
                for healerIndex = 1, 3 do
                    if string.find(d, '[' .. healerIndex .. ']' .. UnitName('player'), 1, true) then
                        fhAlert.healerIndex = healerIndex
                        DEFAULT_CHAT_FRAME:AddMessage("Healer index set to " .. healerIndex)
                        break
                    end
                end
            end
        end
    end
end)

function module:OnEngage()
    self.marks = 0

    globalMarks = 0

    if self.db.profile.mark then
        self:Message(L["startwarn"], "Attention")
        self:Bar(string.format(L["markbar"], self.marks + 1), timer.firstMark, icon.mark, true, "White")
        self:DelayedMessage(timer.firstMark - 5, string.format(L["mark_warn_5"], self.marks + 1), "Urgent")
    end
    if self.db.profile.meteor then
        self:Bar(L["meteorbar"], timer.firstMeteor, icon.meteor, true, "Red")
    end
    if self.db.profile.wrath then
        self:Bar(L["wrathbar"], timer.firstWrath, icon.wrath, true, "Yellow")
    end
    if self.db.profile.void then
        self:Bar(L["voidbar"], timer.firstVoid, icon.void, true, "Black")
    end

    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n, _, group = GetRaidRosterInfo(i);
            if n == UnitName('player') then
                playerGroup = group
            end
        end
    end

    if playerGroup > 0 then
        if playerGroup == 3 then
            fh_alert_marks(MOVE_THANE)
        end
        if playerGroup == 4 then
            fh_alert_marks(MOVE_SAFE_SPOT)
        end
        if playerGroup == 5 then
            fh_alert_marks(MOVE_MOGRAINE)
        end
        if playerGroup == 6 then
            fh_alert_marks(MOVE_SAFE_SPOT)
        end
    end

end

fh_alert:SetScript("OnShow", function()
    this.startTime = GetTime()
    fhAlert.text:Show()
end)
fh_alert:SetScript("OnHide", function()
    fhAlert.text:Hide()
end)
fh_alert:SetScript("OnUpdate", function()
    local plus = 5
    local gt = GetTime() * 1000
    local st = (this.startTime + plus) * 1000
    if gt >= st then
        fh_alert:Hide()
    end
end)

function module:OnDisengage()
end

function module:MarkEvent(msg)
    if string.find(msg, L["marktrigger1"]) or string.find(msg, L["marktrigger2"]) or string.find(msg, L["marktrigger3"]) or string.find(msg, L["marktrigger4"]) then
        self:Sync(syncName.mark)
    end
end

function module:DelayedVoidZone(msg)
    if string.find(msg, void_trigger) then
        self:Sync(syncName.DelayedVoidZone)
    end
end

function module:VoidZoneEvent()
    self:ScheduleEvent("DelayedVoidZoneEvent", self.DelayedVoidZoneEvent, 0.2, self)
    self:WarningSign(icon.void, 3)
    self:IntervalBar(L["voidbar"], timer.void[1], timer.void[2], icon.void, true, "Black")
end

function module:DelayedVoidZoneEvent()
    local target = self:CheckTarget()

    if target then
        self:Icon(target, 3)
        if target == UnitName("player") then
            self:Message("Void Zone on YOU !!!", "Important")
            self:TriggerEvent("BigWigs_Sound", "AirHorn")
            SendChatMessage("Void Zone On Me !", "SAY")
        else
            self:Message("Void Zone on " .. target .. " !!!", "Important")
        end
    end
end

function module:CheckTarget()

    if UnitName("target") == blaumeux then
        return UnitName("targettarget")
    else
        for i = 1, GetNumRaidMembers() do
            if UnitName("Raid" .. i .. "target") == blaumeux then
                return UnitName("Raid" .. i .. "targettarget")
            end
        end
    end
    return nil
end

function module:CHAT_MSG_SPELL_PERIODIC_CREATURE_BUFFS(msg)
    local _, _, mob = string.find(msg, L["shieldwalltrigger"])
    if mob then
        self:Sync(syncName.shieldwall .. " " .. mob)
    end
end

function module:CHAT_MSG_MONSTER_SAY(msg)
    if string.find(msg, L["voidtrigger"]) then
        self:Sync(syncName.DelayedVoidZone)
    elseif string.find(msg, L["meteortrigger2"]) then
        self:Sync(syncName.meteor)
    elseif string.find(msg, L["wrathtrigger2"]) then
        self:Sync(syncName.wrath)
    end
end

function module:CHAT_MSG_COMBAT_HOSTILE_DEATH(msg)
    if msg == string.format(UNITDIESOTHER, thane) or
            msg == string.format(UNITDIESOTHER, zeliek) or
            msg == string.format(UNITDIESOTHER, mograine) or
            msg == string.format(UNITDIESOTHER, blaumeux) then

        self.deaths = self.deaths + 1
        if self.deaths == 4 then
            self:SendBossDeathSync()
        end
    end
end

function module:BigWigs_RecvSync(sync, rest, nick)
    if sync == syncName.mark then
        self:Mark()
    elseif sync == syncName.meteor then
        self:Meteor()
    elseif sync == syncName.wrath then
        self:Wrath()
    elseif sync == syncName.DelayedVoidZone then
        self:VoidZoneEvent()
    elseif sync == syncName.shieldwall and rest then
        self:Shieldwall(rest)
    end
end

function horsemenIsRL()
    if not UnitInRaid('player') then
        return false
    end
    for i = 0, GetNumRaidMembers() do
        if GetRaidRosterInfo(i) then
            local n, r = GetRaidRosterInfo(i);
            if n == UnitName('player') and r == 2 then
                return true
            end
        end
    end
    return false
end

function module:Mark()
    self:RemoveBar(string.format(L["markbar"], self.marks))
    self.marks = self.marks + 1

    globalMarks = globalMarks + 1

    if horsemenIsRL() then
        SendChatMessage("HEALER [" .. globalMarks .. "] ROTATE", "RAID", DEFAULT_CHAT_FRAME.editBox.languageID);
    end
    if globalMarks == fhAlert.healerIndex then
        fh_alert_marks("|cf75DE52f- MOVE -")
        self:TriggerEvent("BigWigs_Sound", "BikeHorn")
    end

    if globalMarks == 3 then
        if fhAlert.healerIndex == 0 then
            self:TriggerEvent("BigWigs_Sound", "BikeHorn")
        end
        globalMarks = 0
    end

    if playerGroup > 0 then

        if self.marks == 0 or self.marks == 12 or self.marks == 24 or self.marks == 36 then
            if playerGroup == 3 then
                fh_alert_marks(MOVE_THANE)
            end
            if playerGroup == 4 then
                fh_alert_marks(MOVE_SAFE_SPOT)
            end
            if playerGroup == 5 then
                fh_alert_marks(MOVE_MOGRAINE)
            end
            if playerGroup == 6 then
                fh_alert_marks(MOVE_SAFE_SPOT)
            end
        end

        if self.marks == 3 or self.marks == 15 or self.marks == 27 or self.marks == 39 then
            if playerGroup == 3 then
                fh_alert_marks(MOVE_SAFE_SPOT)
            end
            if playerGroup == 4 then
                fh_alert_marks(MOVE_THANE)
            end
            if playerGroup == 5 then
                fh_alert_marks(MOVE_SAFE_SPOT)
            end
            if playerGroup == 6 then
                fh_alert_marks(MOVE_MOGRAINE)
            end
        end

        if self.marks == 6 or self.marks == 18 or self.marks == 30 or self.marks == 42 then
            if playerGroup == 3 then
                fh_alert_marks(MOVE_MOGRAINE)
            end
            if playerGroup == 4 then
                fh_alert_marks(MOVE_SAFE_SPOT)
            end
            if playerGroup == 5 then
                fh_alert_marks(MOVE_THANE)
            end
            if playerGroup == 6 then
                fh_alert_marks(MOVE_SAFE_SPOT)
            end
        end

        if self.marks == 9 or self.marks == 21 or self.marks == 33 or self.marks == 45 then
            if playerGroup == 3 then
                fh_alert_marks(MOVE_SAFE_SPOT)
            end
            if playerGroup == 4 then
                fh_alert_marks(MOVE_MOGRAINE)
            end
            if playerGroup == 5 then
                fh_alert_marks(MOVE_SAFE_SPOT)
            end
            if playerGroup == 6 then
                fh_alert_marks(MOVE_THANE)
            end
        end
    end

    if self.db.profile.mark then
        self:Message(string.format(L["mark_warn"], self.marks), "Important")
        self:Bar(string.format(L["markbar"], self.marks + 1), timer.mark, icon.mark, true, "White")
        self:DelayedMessage(timer.mark - 5, string.format(L["mark_warn_5"], self.marks + 1), "Urgent")
    end
end

function module:Meteor()
    if self.db.profile.meteor then
        self:Message(L["meteorwarn"], "Important")
        self:IntervalBar(L["meteorbar"], timer.meteor[1], timer.meteor[2], icon.meteor, true, "Red")
    end
end

function module:Wrath()
    if self.db.profile.wrath then
        self:Message(L["wrathwarn"], "Important")
        self:IntervalBar(L["wrathbar"], timer.wrath[1], timer.wrath[2], icon.wrath, true, "Yellow")
    end
end

function module:Shieldwall(mob)
    if mob and self.db.profile.shieldwall then
        self:Message(string.format(L["shieldwall_warn"], mob), "Attention")
        self:Bar(string.format(L["shieldwallbar"], mob), timer.shieldwall, icon.shieldwall, true, "Blue")
        self:DelayedMessage(timer.shieldwall, string.format(L["shieldwall_warn_over"], mob), "Positive")
    end
end

function string:split(delimiter)
    local result = {}
    local from = 1
    local delim_from, delim_to = string.find(self, delimiter, from)
    while delim_from do
        table.insert(result, string.sub(self, from, delim_from - 1))
        from = delim_to + 1
        delim_from, delim_to = string.find(self, delimiter, from)
    end
    table.insert(result, string.sub(self, from))
    return result
end
