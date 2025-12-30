local HttpService = game:GetService("HttpService")

-- Load ControlBotZ
local botz = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/o9mniej/ControlBotZ0_IBot/refs/heads/main/ControlBotZ%20Module.lua"
))()

botz.Prefix = "."
botz.Bots = {"IBot"}

print("AI bot started (Xeno)")

-- Xeno HTTP
local http = request
assert(http, "Xeno request function not found")

local systemPrompt = "You are a Roblox bot. Reply with a short, simple sentence."

function mainFunction(player, message)
    local args = botz:GetArgs(message)
    if args[1] ~= ".ai" then return end

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

    botz:Chat(reply)
end

botz:Init(mainFunction)
