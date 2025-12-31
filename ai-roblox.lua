local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local LocalPLR = Players.LocalPlayer

-- Load ControlBotZ module
local botz = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/o9mniej/ControlBotZ0_IBot/refs/heads/main/ControlBotZ%20Module.lua"
))()

botz.Prefix = "."
botz.Bots = {"IBot"}

print("AI bot started")

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
            task.wait(1.2) -- safe delay to prevent Roblox errors
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
    local startIndex = 1
    while startIndex <= #text do
        table.insert(chunks, text:sub(startIndex, startIndex + maxLength - 1))
        startIndex = startIndex + maxLength
    end
    return chunks
end

-- ======================
-- AI SYSTEM PROMPT
-- ======================
local systemPrompt = [[
You are IBot, a friendly Roblox bot. You can output commands:
.say <text> to chat
.walkto <player> to move to a player

You know which players are in the server and their names. 
Respond with one or more commands, one per line. Only commands, nothing else.
]]

-- ======================
-- BOT INTRO
-- ======================
task.delay(2, function()
    safeChat("Hi! I'm IBot.")
    safeChat("Type .ai at the beginning of your message to talk to me.")
    safeChat("Example: .ai hello")
    safeChat("I am also in beta so please go easy on me :)")
end)

-- ======================
-- HELPER: GET PLAYERS LIST
-- ======================
local function getPlayersText()
    local text = ""
    for _, plr in ipairs(Players:GetPlayers()) do
        text = text .. "- " .. plr.Name
        if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
            local pos = plr.Character.HumanoidRootPart.Position
            text = text .. ", Position: ("..math.floor(pos.X)..","..math.floor(pos.Y)..","..math.floor(pos.Z)..")"
        end
        text = text .. "\n"
    end
    return text
end

-- MAIN FUNCTION
local function mainFunction(player, message)
    if typeof(player) == "string" and player == botz.Bots[1] then return end

    local args = botz:GetArgs(message)
    if args[1] ~= ".ai" then return end
    if #args == 1 then
        safeChat("Use .ai followed by what you want to say.")
        safeChat("Example: .ai hello")
        return
    end

    local userText = message:sub(5)
    local playersText = getPlayersText()

    -- ======================
    -- PREPARE AI PAYLOAD
    -- ======================
    local payload = {
        model = "roblox-rp",
        messages = {
            { role = "system", content = systemPrompt .. "\nPlayers in server:\n" .. playersText },
            { role = "user", content = player.Name .. ": " .. userText }
        },
        temperature = 1.0,
        max_tokens = 150
    }

    print("=== DEBUG: Sending AI Request ===")
    print(HttpService:JSONEncode(payload))
    print("================================")

    local success, res = pcall(function()
        return http({
            Url = "https://text.pollinations.ai/openai",
            Method = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body = HttpService:JSONEncode(payload)
        })
    end)

    if not success then
        print("[DEBUG] HTTP request failed:", res)
        safeChat("AI error (request failed).")
        return
    end

    print("[DEBUG] HTTP Status:", res.StatusCode)
    print("[DEBUG] Response Body:", res.Body)

    if not res or res.StatusCode ~= 200 or not res.Body then
        safeChat("AI error (bad response).")
        return
    end

    local data
    local decodeSuccess, decodeError = pcall(function()
        data = HttpService:JSONDecode(res.Body)
    end)

    if not decodeSuccess then
        print("[DEBUG] JSON decode error:", decodeError)
        safeChat("AI error (decode failed).")
        return
    end

    if not data or not data.choices or not data.choices[1] then
        print("[DEBUG] Invalid AI response structure")
        safeChat("AI error (invalid structure).")
        return
    end

    local reply = data.choices[1].message.content

    print("=== AI RAW RESPONSE ===")
    print(reply)
    print("=======================")

    -- ======================
    -- PARSE AI COMMANDS
    -- ======================
    for line in reply:gmatch("[^\r\n]+") do
        if line:sub(1,4) == ".say" then
            local msg = line:sub(6)
            for _, chunk in ipairs(splitMessage(msg, 200)) do
                safeChat(chunk)
            end
            print("[BOT EXECUTE] .say: " .. msg)

        elseif line:sub(1,7) == ".walkto" then
            local targetName = line:sub(9)
            local targetPlayer = Players:FindFirstChild(targetName)
            if targetPlayer and targetPlayer.Character and targetPlayer.Character:FindFirstChild("HumanoidRootPart") then
                if LocalPLR and LocalPLR.Character and LocalPLR.Character:FindFirstChild("Humanoid") then
                    LocalPLR.Character.Humanoid:MoveTo(targetPlayer.Character.HumanoidRootPart.Position)
                end
            end
            print("[BOT EXECUTE] .walkto: " .. targetName)
        end
    end
end

botz:Init(mainFunction)
