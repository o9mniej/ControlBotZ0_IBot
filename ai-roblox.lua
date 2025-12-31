local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPLR = Players.LocalPlayer

-- Load ControlBotZ module
local botz = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/o9mniej/ControlBotZ0_IBot/refs/heads/main/ControlBotZ%20Module.lua"
))()

botz.Prefix = "."
botz.Bots = {"IBot"}

print("AI bot started (OLLAMA)")

-- Xeno HTTP
local http = request
assert(http, "request() not found (Xeno required)")

-- ======================
-- CHAT QUEUE (ANTI ####)
-- ======================
local chatQueue = {}
local chatting = false

local function safeChat(text)
    table.insert(chatQueue, text)
    if chatting then return end
    chatting = true

    task.spawn(function()
        while #chatQueue > 0 do
            botz:Chat(table.remove(chatQueue, 1))
            task.wait(1.2)
        end
        chatting = false
    end)
end

-- ======================
-- SPLIT LONG MESSAGES
-- ======================
local function splitMessage(text, maxLength)
    maxLength = maxLength or 200
    local chunks = {}
    local i = 1
    while i <= #text do
        table.insert(chunks, text:sub(i, i + maxLength - 1))
        i += maxLength
    end
    return chunks
end

-- ======================
-- AI SYSTEM PROMPT
-- ======================
local systemPrompt = [[
You are IBot, a Roblox bot.
You MUST respond using ONLY commands:

.say <text>
.walkto <player>

One command per line.
No explanations.
]]

-- ======================
-- BOT INTRO
-- ======================
task.delay(2, function()
    safeChat("Hi! I'm IBot (Ollama).")
    safeChat("Use .ai <message> to talk to me.")
end)

-- ======================
-- PLAYERS LIST
-- ======================
local function getPlayersText()
    local text = ""
    for _, plr in ipairs(Players:GetPlayers()) do
        text ..= "- " .. plr.Name .. "\n"
    end
    return text
end

-- ======================
-- MAIN FUNCTION
-- ======================
local function mainFunction(player, message)
    if typeof(player) == "string" and player == botz.Bots[1] then return end

    local args = botz:GetArgs(message)
    if args[1] ~= ".ai" then return end
    if #args == 1 then
        safeChat("Usage: .ai <message>")
        return
    end

    local userText = message:sub(5)

    local payload = {
        model = "llama3", -- CHANGE MODEL HERE
        messages = {
            {
                role = "system",
                content = systemPrompt .. "\nPlayers:\n" .. getPlayersText()
            },
            {
                role = "user",
                content = player.Name .. ": " .. userText
            }
        },
        stream = false
    }

    local success, res = pcall(function()
        return http({
            Url = "http://127.0.0.1:11434/v1/chat/completions",
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if not success or not res or not res.Body then
        safeChat("Ollama error.")
        return
    end

    local data = HttpService:JSONDecode(res.Body)
    if not data or not data.choices or not data.choices[1] then
        safeChat("Ollama error.")
        return
    end

    local reply = data.choices[1].message.content

    print("=== OLLAMA RAW RESPONSE ===")
    print(reply)
    print("==========================")

    -- ======================
    -- EXECUTE COMMANDS
    -- ======================
    for line in reply:gmatch("[^\r\n]+") do
        -- .say
        if line:sub(1,4) == ".say" then
            local msg = line:sub(6)
            for _, chunk in ipairs(splitMessage(msg)) do
                safeChat(chunk)
            end
            print("[EXECUTE] .say:", msg)

        -- .walkto
        elseif line:sub(1,7) == ".walkto" then
            local targetName = line:sub(9)
            local target = Players:FindFirstChild(targetName)
            if target and target.Character and target.Character:FindFirstChild("HumanoidRootPart") then
                LocalPLR.Character.Humanoid:MoveTo(
                    target.Character.HumanoidRootPart.Position
                )
            end
            print("[EXECUTE] .walkto:", targetName)
        end
    end
end

botz:Init(mainFunction)
