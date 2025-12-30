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

-- Simple system prompt
local systemPrompt = "You are a friendly Roblox bot. Reply with short, simple sentences."

-- Bot introduction (after a short delay)
task.delay(2, function()
    botz:Chat("Hi! I'm IBot.")
    botz:Chat("You can talk to me using .ai followed by your message.")
    botz:Chat("Example: .ai hello")
end)

function mainFunction(player, message)
    -- 🚫 Ignore the bot talking to itself
    if player == botz.Bots[1] then return end

    local args = botz:GetArgs(message)

    -- Only react to .ai
    if args[1] ~= ".ai" then return end

    -- If user just types ".ai"
    if #args == 1 then
        botz:Chat("Use .ai followed by what you want to say.")
        botz:Chat("Example: .ai hello")
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
        max_tokens = 50
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
        botz:Chat("AI error.")
        return
    end

    local data = HttpService:JSONDecode(res.Body)
    local reply = data.choices[1].message.content

    -- Extra safety: never let AI trigger itself
    if reply:sub(1, 3) == ".ai" then
        reply = "I can't use that command."
    end

    botz:Chat(reply)
end

botz:Init(mainFunction)
