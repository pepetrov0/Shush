-- Shush: chat silencer for WotLK 3.3.5
-- Features: keyword list, recently silenced log, opposing-faction filter in non-PvP zones, on/off toggle.

local ADDON_NAME = ...
local PREFIX = "|cff66ccffShush|r: "

local defaults = {
    enabled = true,
    factionFilter = true,
    maxLog = 10,
    words = {},
    log = {},
}

-- Race -> faction (english race tokens from GetPlayerInfoByGUID)
local RACE_FACTION = {
    Human = "Alliance", Dwarf = "Alliance", NightElf = "Alliance",
    Gnome = "Alliance", Draenei = "Alliance",
    Orc = "Horde", Scourge = "Horde", Tauren = "Horde",
    Troll = "Horde", BloodElf = "Horde",
}

local function Print(msg)
    DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. msg)
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local function IsPvPArea()
    local _, instanceType = IsInInstance()
    if instanceType == "pvp" or instanceType == "arena" then
        return true
    end
    local pvpType = GetZonePVPInfo()
    return pvpType == "hostile" or pvpType == "contested"
        or pvpType == "combat" or pvpType == "arena"
end

local function GetAuthorFaction(guid)
    if not guid or guid == "" or not GetPlayerInfoByGUID then return nil end
    local _, _, _, englishRace = GetPlayerInfoByGUID(guid)
    return englishRace and RACE_FACTION[englishRace] or nil
end

local function MatchesWord(msg)
    local lowered = msg:lower()
    for _, word in ipairs(ShushDB.words) do
        if lowered:find(word, 1, true) then
            return word
        end
    end
    return nil
end

---------------------------------------------------------------------------
-- Log dump: /shush log prints it to chat and clears it
---------------------------------------------------------------------------

local function DumpLog()
    if #ShushDB.log == 0 then
        Print("Nothing silenced yet.")
        return
    end
    Print("recently silenced (" .. #ShushDB.log .. "):")
    for _, e in ipairs(ShushDB.log) do
        Print(string.format(
            "|cff888888[%s]|r |cffffd100%s|r |cff888888(%s)|r: |cffffffff%s|r",
            e.t, e.who, e.why, e.msg))
    end
    wipe(ShushDB.log)
    Print("log cleared.")
end

---------------------------------------------------------------------------
-- Chat filter
---------------------------------------------------------------------------

local lastLineID, lastResult

local function AddToLog(author, msg, reason)
    local log = ShushDB.log
    table.insert(log, { t = date("%H:%M:%S"), who = author, msg = msg, why = reason })
    while #log > ShushDB.maxLog do
        table.remove(log, 1)
    end
end

local function ChatFilter(self, event, msg, author, ...)
    if not ShushDB or not ShushDB.enabled then return false end

    -- Filters run once per chat frame; cache by lineID so we log/decide once.
    local lineID, guid = select(9, ...), select(10, ...)
    if lineID and lineID == lastLineID then
        return lastResult
    end

    local result, reason = false, nil
    local shortAuthor = author and author:match("^[^%-]+") or author

    if shortAuthor ~= UnitName("player") then
        local word = MatchesWord(msg)
        if word then
            result, reason = true, "word: " .. word
        elseif ShushDB.factionFilter and event ~= "CHAT_MSG_WHISPER" and not IsPvPArea() then
            local theirs = GetAuthorFaction(guid)
            local mine = UnitFactionGroup("player")
            if theirs and mine and theirs ~= mine then
                result, reason = true, "opposing faction"
            end
        end
    end

    if result then
        AddToLog(shortAuthor or "?", msg, reason)
    end

    lastLineID, lastResult = lineID, result
    return result
end

local FILTERED_EVENTS = {
    "CHAT_MSG_SAY", "CHAT_MSG_YELL", "CHAT_MSG_EMOTE",
    "CHAT_MSG_CHANNEL", "CHAT_MSG_WHISPER",
}

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

local function OnOff(v) return v and "|cff00ff00ON|r" or "|cffff0000OFF|r" end

local function ShowHelp()
    Print("Shush is " .. OnOff(ShushDB.enabled) .. "  |  faction filter " .. OnOff(ShushDB.factionFilter))
    Print("/shush on | off | toggle")
    Print("/shush add <word or phrase>   /shush remove <word or phrase>")
    Print("/shush list   - show silenced words")
    Print("/shush log    - print recent silenced messages, then clear the log")
    Print("/shush faction on | off   - opposing faction filter (non-PvP zones)")
end

local function Handler(input)
    local cmd, arg = (input or ""):match("^(%S*)%s*(.-)%s*$")
    cmd = cmd:lower()

    if cmd == "on" then
        ShushDB.enabled = true
        Print("enabled.")
    elseif cmd == "off" then
        ShushDB.enabled = false
        Print("disabled.")
    elseif cmd == "toggle" then
        ShushDB.enabled = not ShushDB.enabled
        Print(ShushDB.enabled and "enabled." or "disabled.")
    elseif cmd == "add" then
        arg = arg:lower()
        if arg == "" then return Print("Usage: /shush add <word or phrase>") end
        for _, w in ipairs(ShushDB.words) do
            if w == arg then return Print("'" .. arg .. "' is already on the list.") end
        end
        table.insert(ShushDB.words, arg)
        Print("added '" .. arg .. "'.")
    elseif cmd == "remove" or cmd == "del" then
        arg = arg:lower()
        for i, w in ipairs(ShushDB.words) do
            if w == arg then
                table.remove(ShushDB.words, i)
                return Print("removed '" .. arg .. "'.")
            end
        end
        Print("'" .. arg .. "' is not on the list.")
    elseif cmd == "list" then
        if #ShushDB.words == 0 then
            Print("word list is empty. Use /shush add <word>.")
        else
            Print("silenced words (" .. #ShushDB.words .. "): " .. table.concat(ShushDB.words, ", "))
        end
    elseif cmd == "log" then
        DumpLog()
    elseif cmd == "faction" then
        arg = arg:lower()
        if arg == "on" then ShushDB.factionFilter = true
        elseif arg == "off" then ShushDB.factionFilter = false
        else ShushDB.factionFilter = not ShushDB.factionFilter end
        Print("opposing faction filter " .. OnOff(ShushDB.factionFilter))
    else
        ShowHelp()
    end
end

SLASH_SHUSH1 = "/shush"
SlashCmdList["SHUSH"] = Handler

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:SetScript("OnEvent", function(self, event, name)
    if name ~= ADDON_NAME then return end

    ShushDB = ShushDB or {}
    for k, v in pairs(defaults) do
        if ShushDB[k] == nil then
            if type(v) == "table" then ShushDB[k] = {} else ShushDB[k] = v end
        end
    end

    for _, ev in ipairs(FILTERED_EVENTS) do
        ChatFrame_AddMessageEventFilter(ev, ChatFilter)
    end

    self:UnregisterEvent("ADDON_LOADED")
    Print("loaded. Type /shush for help.")
end)
