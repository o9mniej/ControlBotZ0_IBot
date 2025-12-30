local botz = loadstring(game:HttpGet("https://raw.githubusercontent.com/o9mniej/ControlBotZ0_IBot/refs/heads/main/ControlBotZ%20Module.lua"))()
botz.Prefix = "."
botz.Bots = {"IBot"}
botz:addAdmin("o9mniej1")
botz:addAdmin("TheRealThomasPlayz")
botz:addAdmin("N93333")
botz:Chat("test")
function mainFunction(player, message)
  if message == botz.Prefix .. "test" then -- So you need to type .test instead of just test
    botz:Chat("Hello World")
  end

end
