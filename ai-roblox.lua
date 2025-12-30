local HttpService = game:GetService("HttpService")

-- Load ControlBotZ
local botz = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/o9mniej/ControlBotZ0_IBot/refs/heads/main/ControlBotZ%20Module.lua"
))()

botz.Prefix = "."
botz.Bots = {"IBot"}

print("AI bot started")

-- VERY simple system prompt
local systemPrompt = [[
You are a Roblox bot.
Reply with a short, simple sentence.
Do not use commands.
]]

function mainFunction(player, message)
    local args = botz:GetArgs(message)

    -- Only react to .ai
    if args[1] ~= ".ai" then return end

    local userText = message:sub(5) -- remove ".ai "

    local payload = {
        model = "openai",
        messages = {
            { role = "system", content = systemPrompt },
            { role = "user", content = userText }
        },
        temperature = 1.0,
        max_tokens = 50
    }

    local success, response = pcall(function()
        return HttpService:PostAsync(
            "https://text.pollinations.ai/openai",
            HttpService:JSONEncode(payload),
            Enum.HttpContentType.ApplicationJson
        )
    end)

    if not success then
        botz:Chat("AI error.")
        return
    end

    local data = HttpService:JSONDecode(response)
    local reply = data.choices[1].message.content

    -- Make the bot speak
    botz:Chat(reply)
end

botz:Init(mainFunction)
