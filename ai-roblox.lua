local botz = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/o9mniej/ControlBotZ0_IBot/refs/heads/main/ControlBotZ%20Module.lua"
))()

botz.Prefix = "."
botz.Bots = {"IBot"}

botz:addAdmin("o9mniej1")
botz:addAdmin("TheRealThomasPlayz")
botz:addAdmin("N93333")

botz:Chat("test")

function mainFunction(player, message)
    local args = botz:GetArgs(message) -- ALWAYS first

    -- .test
    if args[1] == botz.Prefix .. "test" then
        botz:Chat("Hello World")
    end

    -- .say <text>
    if args[1] == botz.Prefix .. "say" then
        botz:Chat("You said: " .. (args[2] or "nothing"))
    end
end

botz:Init(mainFunction)
