local HttpService = game:GetService("HttpService")

-- Load ControlBotZ
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
            task.wait(1.2) -- safe delay
        end
        chatting = false
    end)
end

-- ======================
-- SPLIT LONG MESSAGES
-- ======================
local function splitMessage(text, maxLength)
    maxLength = maxLength or 200 -- Roblox safe limit
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
local systemPrompt = "You are a friendly Roblox bot named IBot. Reply with short, simple sentences."

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
-- MAIN FUNCTION
-- ======================
function mainFunction(player, message)
    -- 🚫 Ignore bot talking to itself
    if typeof(player) == "string" and player == botz.Bots[1] then
        return
    end

    local args = botz:GetArgs(message)

    -- Only react to .ai
    if args[1] ~= ".ai" then return end

    -- If user just types ".ai"
    if #args == 1 then
        safeChat("Use .ai followed by what you want to say.")
        safeChat("Example: .ai hello")
        return
    end

    local userText = message:sub(5)

    local payload = {
        model = "openai",
        messages = {
            { role = "system", content = systemPrompt },
            { role = "user", content = userText }
        },
        temperature = 1.0,
        max_tokens = 150
    }

    local res = http({
        Url = "https://text.pollinations.ai/openai",
        Method = "POST",
        Headers = {
            ["Content-Type"] = "application/json"
        },
        Body = HttpService:JSONEncode(payload)
    })

    if not res or not res.Body then
        safeChat("AI error.")
        return
    end

    local data = HttpService:JSONDecode(res.Body)
    if not data or not data.choices or not data.choices[1] then
        safeChat("AI error.")
        return
    end

    local reply = data.choices[1].message.content

    -- 🚫 Prevent AI from triggering commands
    if reply:sub(1, 1) == "." then
        reply = "I can only reply in chat."
    end

    -- Split long messages and send safely
    for _, chunk in ipairs(splitMessage(reply, 200)) do
        safeChat(chunk)
    end
end

botz:Init(mainFunction)
