local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/abvcghsdcxy/bleh/main/gui.lua"))()

local win = UI.CreateWindow({
	Title = "Purple Library",
	Size = Vector2.new(620, 390),
	KeyToToggle = Enum.KeyCode.RightShift,
})

win:Notify("Loaded", "Press RightShift to toggle.", 3)

local main = win:AddTab("Main", "★")
local misc = win:AddTab("Misc", "⚙")

local s1 = main:AddSection("Combat")
main:AddToggleIn(s1, "Auto Swing", false, function(v) print("Auto Swing:", v) end)
main:AddSliderIn(s1, "Reach", 1, 20, 5, function(v) print("Reach:", v) end)
main:AddDropdownIn(s1, "Toggle", {"Option0", "Option1", "Option2", "Option3"}, "Legit", function(v) print("Mode:", v) end)
main:AddKeybindIn(s1, "Keybind", Enum.KeyCode.P, function(k) print("key set:", k) end, function()
	win:SetVisible(false)
end)
main:AddButtonIn(s1, "Notify Test", function()
	win:Notify("Hello", "This is a notification.", 2)
end)

local s2 = misc:AddSection("Settings")
misc:AddToggleIn(s2, "Show FPS", true, function(v) print("Show FPS:", v) end)
misc:AddButtonIn(s2, "Destroy UI", function()
	win:Destroy()
end)
