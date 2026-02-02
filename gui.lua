--!strict
-- PurpleUI v2 (compact, popup dropdown on right, slider shows min/max/current)
-- Put this ModuleScript next to your LocalScript (easiest) or in ReplicatedStorage.

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local LOCAL_PLAYER = Players.LocalPlayer

type Callback<T> = (T) -> ()

-- =========================
-- Theme + Compact Metrics
-- =========================

local Theme = {
	GradA = Color3.fromRGB(88, 0, 255),
	GradB = Color3.fromRGB(10, 10, 18),

	Surface = Color3.fromRGB(18, 16, 26),
	Surface2 = Color3.fromRGB(22, 19, 33),
	Surface3 = Color3.fromRGB(28, 24, 42),

	Stroke = Color3.fromRGB(130, 80, 255),

	Text = Color3.fromRGB(240, 240, 255),
	SubText = Color3.fromRGB(175, 175, 195),

	Accent = Color3.fromRGB(150, 105, 255),
	AccentDim = Color3.fromRGB(105, 70, 190),
}

local M = {
	Corner = 12,
	StrokeT = 1,

	TopBarH = 36,
	SidebarW = 118,      -- compact
	Gap = 10,
	Pad = 10,

	RowH = 30,           -- compact row height
	ButtonH = 30,
	SliderH = 44,
	DropdownH = 30,

	FontTitle = 15,
	FontBody = 13,
	FontSmall = 12,

	PopupMaxRows = 7,
	PopupRowH = 26,
	PopupGap = 4,
	PopupPadY = 8,
}

-- =========================
-- Helpers
-- =========================

local function tween(obj: Instance?, ti: TweenInfo, props: {[string]: any})
	if not obj then return nil end
	local t = TweenService:Create(obj, ti, props)
	t:Play()
	return t
end

local function mk(className: string, props: {[string]: any}?, children: {Instance}?): Instance
	local inst = Instance.new(className)
	if props then
		for k, v in pairs(props) do
			(inst :: any)[k] = v
		end
	end
	if children then
		for _, c in ipairs(children) do
			c.Parent = inst
		end
	end
	return inst
end

local function addCorner(parent: Instance, px: number)
	mk("UICorner", {CornerRadius = UDim.new(0, px), Parent = parent})
end

local function addStroke(parent: Instance, transparency: number)
	mk("UIStroke", {
		Color = Theme.Stroke,
		Thickness = M.StrokeT,
		Transparency = transparency,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function addGradient(parent: Instance, rotation: number?)
	local g = mk("UIGradient", {
		Rotation = rotation or 0,
		Color = ColorSequence.new({
			ColorSequenceKeypoint.new(0, Theme.GradA),
			ColorSequenceKeypoint.new(1, Theme.GradB),
		}),
		Parent = parent,
	}) :: UIGradient
	return g
end

local function font(weight: Enum.FontWeight)
	return Font.new("rbxasset://fonts/families/GothamSSm.json", weight)
end

local function label(text: string, size: number, transparency: number, weight: Enum.FontWeight, xAlign: Enum.TextXAlignment?)
	return mk("TextLabel", {
		BackgroundTransparency = 1,
		Text = text,
		TextColor3 = Theme.Text,
		TextTransparency = transparency,
		TextSize = size,
		FontFace = font(weight),
		TextXAlignment = xAlign or Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Center,
	})
end

local function buttonBase(parent: Instance, h: number)
	local b = mk("TextButton", {
		BackgroundColor3 = Theme.Surface2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, h),
		Text = "",
		AutoButtonColor = false,
		Parent = parent,
	})
	addCorner(b, 10)
	addStroke(b, 0.78)
	return b
end

local function makeDraggable(dragHandle: GuiObject, dragTarget: GuiObject)
	dragHandle.Active = true
	dragHandle.Selectable = true

	local dragging = false
	local dragStart: Vector2? = nil
	local startPos: UDim2? = nil

	local function update(pos: Vector2)
		if not dragStart or not startPos then return end
		local d = pos - dragStart
		dragTarget.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + d.X,
			startPos.Y.Scale, startPos.Y.Offset + d.Y
		)
	end

	dragHandle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = dragTarget.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then dragging = false end
			end)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if not dragging then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			update(input.Position)
		end
	end)
end

local function makeScroll(parent: Instance)
	local scroll = mk("ScrollingFrame", {
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.AccentDim,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.fromOffset(0, 0),
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = parent,
	}) :: ScrollingFrame

	mk("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = scroll,
	})

	mk("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = scroll,
	})
	return scroll
end

local function makeSection(parent: Instance, titleText: string)
	local box = mk("Frame", {
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		AutomaticSize = Enum.AutomaticSize.Y,
		Size = UDim2.new(1, 0, 0, 0),
		Parent = parent,
	})
	addCorner(box, 12)
	addStroke(box, 0.80)

	local head = label(titleText, M.FontSmall, 0.15, Enum.FontWeight.Bold)
	head.Size = UDim2.new(1, 0, 0, 16)
	head.Parent = box

	mk("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 6),
		Parent = box,
	})

	mk("UIPadding", {
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 10),
		PaddingRight = UDim.new(0, 10),
		Parent = box,
	})

	return box
end

-- =========================
-- Components
-- =========================

local function makeButton(parent: Instance, text: string, cb: () -> ())
	local b = buttonBase(parent, M.ButtonH)

	local t = label(text, M.FontBody, 0.0, Enum.FontWeight.SemiBold)
	t.Position = UDim2.fromOffset(10, 0)
	t.Size = UDim2.new(1, -20, 1, 0)
	t.Parent = b

	b.MouseEnter:Connect(function()
		tween(b, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Theme.Surface3})
	end)
	b.MouseLeave:Connect(function()
		tween(b, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Theme.Surface2})
	end)

	b.MouseButton1Click:Connect(cb)
	return b
end

local function makeToggle(parent: Instance, text: string, default: boolean, onChanged: Callback<boolean>)
	local row = mk("Frame", {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, M.RowH), Parent = parent})

	local t = label(text, M.FontBody, 0.0, Enum.FontWeight.SemiBold)
	t.Size = UDim2.new(1, -70, 1, 0)
	t.Parent = row

	local pill = mk("TextButton", {
		BackgroundColor3 = Theme.Surface2,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(48, 22),
		Position = UDim2.new(1, -48, 0.5, -11),
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})
	addCorner(pill, 999)
	addStroke(pill, 0.80)

	local knob = mk("Frame", {
		BackgroundColor3 = Theme.SubText,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(16, 16),
		Position = UDim2.new(0, 3, 0.5, -8),
		Parent = pill,
	})
	addCorner(knob, 999)

	local state = default

	local function apply(animated: boolean)
		local goalX = state and (48 - 16 - 3) or 3
		local goalKnob = state and Theme.Accent or Theme.SubText
		local goalPill = state and Theme.Surface3 or Theme.Surface2

		if animated then
			tween(knob, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				Position = UDim2.new(0, goalX, 0.5, -8),
				BackgroundColor3 = goalKnob,
			})
			tween(pill, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = goalPill})
		else
			knob.Position = UDim2.new(0, goalX, 0.5, -8)
			knob.BackgroundColor3 = goalKnob
			pill.BackgroundColor3 = goalPill
		end
	end

	apply(false)

	pill.MouseButton1Click:Connect(function()
		state = not state
		apply(true)
		onChanged(state)
	end)

	onChanged(state)

	return { Get = function() return state end, Set = function(v: boolean) state = v; apply(true); onChanged(state) end }
end

local function makeSlider(parent: Instance, text: string, minV: number, maxV: number, defaultV: number, onChanged: Callback<number>)
	local box = mk("Frame", {
		BackgroundColor3 = Theme.Surface2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, M.SliderH),
		Parent = parent,
	})
	addCorner(box, 10)
	addStroke(box, 0.80)

	local title = label(text, M.FontBody, 0.0, Enum.FontWeight.SemiBold)
	title.Position = UDim2.fromOffset(10, 4)
	title.Size = UDim2.new(1, -20, 0, 16)
	title.Parent = box

	-- Min / Current / Max labels
	local minL = label(tostring(minV), M.FontSmall, 0.18, Enum.FontWeight.Medium, Enum.TextXAlignment.Left)
	minL.Position = UDim2.fromOffset(10, 20)
	minL.Size = UDim2.new(0, 60, 0, 14)
	minL.Parent = box

	local curL = label(tostring(defaultV), M.FontSmall, 0.0, Enum.FontWeight.Bold, Enum.TextXAlignment.Center)
	curL.Position = UDim2.new(0.5, -40, 0, 20)
	curL.Size = UDim2.fromOffset(80, 14)
	curL.Parent = box

	local maxL = label(tostring(maxV), M.FontSmall, 0.18, Enum.FontWeight.Medium, Enum.TextXAlignment.Right)
	maxL.Position = UDim2.new(1, -70, 0, 20)
	maxL.Size = UDim2.new(0, 60, 0, 14)
	maxL.Parent = box

	local track = mk("Frame", {
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 10, 1, -12),
		Size = UDim2.new(1, -20, 0, 8),
		Parent = box,
	})
	addCorner(track, 999)

	local fill = mk("Frame", {
		BackgroundColor3 = Theme.Accent,
		BorderSizePixel = 0,
		Size = UDim2.new(0, 0, 1, 0),
		Parent = track,
	})
	addCorner(fill, 999)

	local grabbing = false
	local value = math.clamp(defaultV, minV, maxV)

	local function setValue(v: number, fire: boolean)
		value = math.clamp(v, minV, maxV)
		local a = (value - minV) / (maxV - minV)
		fill.Size = UDim2.new(a, 0, 1, 0)
		-- pretty display (no crazy decimals)
		local shown = (math.floor(value * 100) / 100)
		curL.Text = tostring(shown)
		if fire then onChanged(value) end
	end

	local function posToValue(x: number)
		local abs = track.AbsolutePosition.X
		local w = track.AbsoluteSize.X
		local a = math.clamp((x - abs) / w, 0, 1)
		return minV + (maxV - minV) * a
	end

	setValue(value, false)
	onChanged(value)

	track.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			grabbing = true
			setValue(posToValue(input.Position.X), true)
		end
	end)

	UIS.InputChanged:Connect(function(input)
		if not grabbing then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			setValue(posToValue(input.Position.X), true)
		end
	end)

	UIS.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			grabbing = false
		end
	end)

	return { Get = function() return value end, Set = function(v: number) setValue(v, true) end }
end

-- Popup dropdown anchored to the RIGHT SIDE of the window (inside)
local function makeDropdown(parent: Instance, text: string, options: {string}, defaultV: string?, onChanged: (string)->(), windowRoot: Frame)
	-- compact row
	local row = mk("Frame", {
		BackgroundColor3 = Theme.Surface2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, M.DropdownH),
		Parent = parent,
	})
	addCorner(row, 10)
	addStroke(row, 0.80)

	local btn = mk("TextButton", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Text = "",
		AutoButtonColor = false,
		Parent = row,
	})

	local title = label(text, M.FontBody, 0, Enum.FontWeight.SemiBold)
	title.Position = UDim2.fromOffset(10, 0)
	title.Size = UDim2.new(1, -70, 1, 0)
	title.Parent = btn

	local selected = defaultV or (options[1] or "")
	local sel = label(selected, M.FontSmall, 0.15, Enum.FontWeight.Medium, Enum.TextXAlignment.Right)
	sel.Position = UDim2.new(1, -38, 0, 0)
	sel.Size = UDim2.new(0, 120, 1, 0)
	sel.Parent = btn

	-- ✅ ARROW EXISTS (symbol, never breaks)
	local arrow = mk("TextLabel", {
		BackgroundTransparency = 1,
		Text = ">",
		TextSize = 16,
		TextColor3 = Theme.SubText,
		FontFace = font(Enum.FontWeight.Bold),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		Rotation = 0, -- closed = right
		Parent = btn,
	}) :: TextLabel

	local function setArrow(opened: boolean)
		-- guard against destroyed UI
		if not arrow.Parent or not row.Parent then return end
		tween(arrow, TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Rotation = opened and 90 or 0, -- open = down
			TextColor3 = opened and Theme.Accent or Theme.SubText
		})
	end

	-- find ScreenGui
	local screenGui: ScreenGui? = nil
	do
		local cur: Instance? = windowRoot
		while cur do
			if cur:IsA("ScreenGui") then screenGui = cur break end
			cur = cur.Parent
		end
	end
	if not screenGui then error("makeDropdown: ScreenGui not found") end

	-- shared overlay (one per ScreenGui)
	local overlay = screenGui:FindFirstChild("__DropdownOverlay") :: Frame?
	if not overlay then
		overlay = mk("Frame", {
			Name = "__DropdownOverlay",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
			ZIndex = 9000,
			Parent = screenGui,
		}) :: Frame

		mk("TextButton", {
			Name = "Catch",
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Text = "",
			AutoButtonColor = false,
			ZIndex = 9000,
			Parent = overlay,
		})
	end

	local catcher = overlay:WaitForChild("Catch") :: TextButton
	local popup: Frame? = nil
	local open = false

	-- keep connections so we can disconnect on destroy
	local conns: {RBXScriptConnection} = {}

	local function close()
		open = false
		setArrow(false)
		if popup then popup:Destroy() end
		popup = nil

		-- only hide overlay if this dropdown is the one that opened it
		overlay.Visible = false
	end

	-- click outside closes
	conns[#conns+1] = catcher.MouseButton1Click:Connect(function()
		if open then close() end
	end)

	local function openPopup()
		open = true
		setArrow(true)
		overlay.Visible = true

		-- remove any old popup from THIS dropdown instance
		if popup then popup:Destroy() popup = nil end

		local rootAbs = windowRoot.AbsolutePosition
		local rootSize = windowRoot.AbsoluteSize
		local guiAbs = screenGui.AbsolutePosition

		-- width ~ 1/5 window, compact min
		local popupW = math.max(170, math.floor(rootSize.X * 0.20))

		-- right side inside window
		local popupX = (rootAbs.X - guiAbs.X) + rootSize.X - popupW - 12

		-- align to this row vertically
		local popupY = (row.AbsolutePosition.Y - guiAbs.Y) + row.AbsoluteSize.Y + 6

		-- height cap with scroll
		local visibleRows = math.min(#options, M.PopupMaxRows)
		local h = M.PopupPadY + visibleRows * M.PopupRowH + (visibleRows - 1) * M.PopupGap + M.PopupPadY

		-- keep inside window vertically (clamp)
		local windowTop = (rootAbs.Y - guiAbs.Y) + (M.TopBarH + 10)
		local windowBottom = (rootAbs.Y - guiAbs.Y) + rootSize.Y - 12
		if popupY + h > windowBottom then
			popupY = math.max(windowTop, windowBottom - h)
		end

		popup = mk("Frame", {
			BackgroundColor3 = Theme.Surface3,
			BorderSizePixel = 0,
			Position = UDim2.fromOffset(popupX, popupY),
			Size = UDim2.fromOffset(popupW, h),
			ZIndex = 9100,
			Parent = overlay,
		}) :: Frame
		addCorner(popup, 12)
		addStroke(popup, 0.65)

		local list = mk("ScrollingFrame", {
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.fromScale(1, 1),
			AutomaticCanvasSize = Enum.AutomaticSize.Y,
			CanvasSize = UDim2.fromOffset(0, 0),
			ScrollBarThickness = 3,
			ScrollBarImageColor3 = Theme.AccentDim,
			ZIndex = 9200,
			Parent = popup,
		}) :: ScrollingFrame

		mk("UIPadding", {
			PaddingTop = UDim.new(0, M.PopupPadY),
			PaddingBottom = UDim.new(0, M.PopupPadY),
			PaddingLeft = UDim.new(0, 8),
			PaddingRight = UDim.new(0, 8),
			Parent = list,
		})

		mk("UIListLayout", {
			Padding = UDim.new(0, M.PopupGap),
			SortOrder = Enum.SortOrder.LayoutOrder,
			Parent = list,
		})

		for i, opt in ipairs(options) do
			local b = mk("TextButton", {
				BackgroundColor3 = Theme.Surface2,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, M.PopupRowH),
				Text = "",
				AutoButtonColor = false,
				LayoutOrder = i,
				ZIndex = 9300,
				Parent = list,
			})
			addCorner(b, 10)
			addStroke(b, 0.80)

			local t = label(opt, M.FontSmall, 0, Enum.FontWeight.Medium)
			t.Position = UDim2.fromOffset(8, 0)
			t.Size = UDim2.new(1, -16, 1, 0)
			t.Parent = b

			-- highlight current selection
			if opt == selected then
				b.BackgroundColor3 = Theme.Surface
			end

			b.MouseEnter:Connect(function()
				tween(b, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Theme.Surface})
			end)
			b.MouseLeave:Connect(function()
				local back = (opt == selected) and Theme.Surface or Theme.Surface2
				tween(b, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = back})
			end)

			b.MouseButton1Click:Connect(function()
				selected = opt
				sel.Text = selected
				onChanged(selected)
				close()
			end)
		end
	end

	conns[#conns+1] = btn.MouseButton1Click:Connect(function()
		if open then close() else openPopup() end
	end)

	-- 🔒 cleanup: if row gets destroyed (tab switch / rebuild), close + disconnect
	conns[#conns+1] = row.Destroying:Connect(function()
		if popup then popup:Destroy() end
		popup = nil
		open = false
		overlay.Visible = false
		for _, c in ipairs(conns) do
			c:Disconnect()
		end
	end)

	onChanged(selected)

	return {
		Get = function() return selected end,
		Set = function(v: string)
			selected = v
			sel.Text = v
			onChanged(v)
		end,
		SetOptions = function(o: {string})
			options = o
			if not table.find(options, selected) then
				selected = options[1] or ""
				sel.Text = selected
				onChanged(selected)
			end
			if open then close() end
		end,
	}
end


local function makeKeybind(parent: Instance, text: string, defaultKey: Enum.KeyCode, onChanged: Callback<Enum.KeyCode>, onPressed: (() -> ())?)
	local box = mk("Frame", {
		BackgroundColor3 = Theme.Surface2,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, M.RowH),
		Parent = parent,
	})
	addCorner(box, 10)
	addStroke(box, 0.80)

	local title = label(text, M.FontBody, 0.0, Enum.FontWeight.SemiBold)
	title.Position = UDim2.fromOffset(10, 0)
	title.Size = UDim2.new(1, -110, 1, 0)
	title.Parent = box

	local keyBtn = mk("TextButton", {
		BackgroundColor3 = Theme.Surface,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(84, 22),
		Position = UDim2.new(1, -94, 0.5, -11),
		Text = "",
		AutoButtonColor = false,
		Parent = box,
	})
	addCorner(keyBtn, 8)
	addStroke(keyBtn, 0.85)

	local keyText = label(defaultKey.Name, M.FontSmall, 0.1, Enum.FontWeight.Bold, Enum.TextXAlignment.Center)
	keyText.Size = UDim2.fromScale(1, 1)
	keyText.Parent = keyBtn

	local waiting = false
	local key = defaultKey

	keyBtn.MouseButton1Click:Connect(function()
		waiting = true
		keyText.Text = "..."
	end)

	UIS.InputBegan:Connect(function(input, gpe)
		if gpe then return end

		if waiting and input.KeyCode ~= Enum.KeyCode.Unknown then
			waiting = false
			key = input.KeyCode
			keyText.Text = key.Name
			onChanged(key)
			return
		end

		if input.KeyCode == key then
			if onPressed then onPressed() end
		end
	end)

	onChanged(key)

	return { Get = function() return key end, Set = function(k: Enum.KeyCode) key = k; keyText.Text = k.Name; onChanged(k) end }
end

-- =========================
-- Window / Tabs API
-- =========================

local Lib = {}
Lib.__index = Lib

export type Window = {
	Gui: ScreenGui,
	Root: Frame,
	Sidebar: Frame,
	Content: Frame,
	Tabs: {[string]: any},
	CurrentTab: any?,
	SetVisible: (self: Window, visible: boolean) -> (),
	Destroy: (self: Window) -> (),
	AddTab: (self: Window, name: string, iconText: string?) -> any,
	Notify: (self: Window, title: string, body: string, seconds: number?) -> (),
}

local WindowMT = {}
WindowMT.__index = WindowMT

local TabMT = {}
TabMT.__index = TabMT

function Lib.CreateWindow(opts: {Title: string?, Size: Vector2?, Parent: Instance?, KeyToToggle: Enum.KeyCode?}?): Window
	opts = opts or {}
	local titleText = opts.Title or "PurpleUI"
	local size = opts.Size or Vector2.new(520, 320)  -- compact default
	local parent = opts.Parent or LOCAL_PLAYER:WaitForChild("PlayerGui")
	local toggleKey = opts.KeyToToggle or Enum.KeyCode.RightShift

	local gui = mk("ScreenGui", {
		Name = "PurpleUI",
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		Parent = parent,
	}) :: ScreenGui

	local root = mk("Frame", {
		BackgroundColor3 = Color3.new(1, 1, 1),
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(size.X, size.Y),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		Parent = gui,
	}) :: Frame
	addCorner(root, 14)
	addStroke(root, 0.55)
	addGradient(root, 0)

	-- TopBar
	local top = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, M.TopBarH),
		Parent = root,
	}) :: Frame

	local title = label(titleText, M.FontTitle, 0.0, Enum.FontWeight.Bold)
	title.Position = UDim2.fromOffset(12, 0)
	title.Size = UDim2.new(1, -80, 1, 0)
	title.Parent = top

	local closeBtn = mk("TextButton", {
		BackgroundColor3 = Theme.Surface2,
		BorderSizePixel = 0,
		Size = UDim2.fromOffset(30, 24),
		Position = UDim2.new(1, -42, 0.5, -12),
		Text = "×",
		TextSize = 18,
		TextColor3 = Theme.Text,
		FontFace = font(Enum.FontWeight.Bold),
		AutoButtonColor = false,
		Parent = top,
	})
	addCorner(closeBtn, 10)
	addStroke(closeBtn, 0.75)

	local divider = mk("Frame", {
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.78,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 10, 0, M.TopBarH),
		Size = UDim2.new(1, -20, 0, 1),
		Parent = root,
	})

	-- Sidebar
	local sidebar = mk("Frame", {
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.18,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 10, 0, M.TopBarH + 10),
		Size = UDim2.new(0, M.SidebarW, 1, -(M.TopBarH + 20)),
		Parent = root,
	}) :: Frame
	addCorner(sidebar, 12)
	addStroke(sidebar, 0.78)

	local tabButtons = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 1, 0),
		Parent = sidebar,
	})
	mk("UIPadding", {
		PaddingTop = UDim.new(0, 10),
		PaddingBottom = UDim.new(0, 10),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		Parent = tabButtons,
	})
	mk("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
		Parent = tabButtons,
	})

	-- Content
	local content = mk("Frame", {
		BackgroundColor3 = Theme.Surface,
		BackgroundTransparency = 0.20,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 20 + M.SidebarW, 0, M.TopBarH + 10),
		Size = UDim2.new(1, -(30 + M.SidebarW), 1, -(M.TopBarH + 20)),
		Parent = root,
	}) :: Frame
	addCorner(content, 12)
	addStroke(content, 0.78)

	local pages = mk("Folder", {Name = "Pages", Parent = content})

	makeDraggable(top, root)

	local window: any = setmetatable({
		Gui = gui,
		Root = root,
		Sidebar = sidebar,
		Content = content,
		Tabs = {},
		CurrentTab = nil,
	}, WindowMT)

	local visible = true
	function window:SetVisible(v: boolean)
		visible = v
		gui.Enabled = v
	end

	closeBtn.MouseButton1Click:Connect(function()
		window:SetVisible(false)
	end)

	UIS.InputBegan:Connect(function(input, gpe)
		if gpe then return end
		if input.KeyCode == toggleKey then
			window:SetVisible(not gui.Enabled)
		end
	end)

	-- Simple notifications (compact)
	local notifHolder = mk("Frame", {
		BackgroundTransparency = 1,
		Size = UDim2.fromScale(1, 1),
		Parent = gui,
	})
	mk("UIPadding", {PaddingTop = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = notifHolder})
	mk("UIListLayout", {
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
		VerticalAlignment = Enum.VerticalAlignment.Top,
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = notifHolder,
	})

	function window:Notify(tit: string, body: string, seconds: number?)
		seconds = seconds or 2.2
		local card = mk("Frame", {
			BackgroundColor3 = Theme.Surface2,
			BorderSizePixel = 0,
			Size = UDim2.fromOffset(240, 64),
			Parent = notifHolder,
		})
		addCorner(card, 12)
		addStroke(card, 0.75)

		local g = addGradient(card, 0)
		g.Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.78),
			NumberSequenceKeypoint.new(1, 0.90),
		})

		local tt = label(tit, M.FontBody, 0.0, Enum.FontWeight.Bold)
		tt.Position = UDim2.fromOffset(10, 8)
		tt.Size = UDim2.new(1, -20, 0, 16)
		tt.Parent = card

		local bb = label(body, M.FontSmall, 0.18, Enum.FontWeight.Medium)
		bb.Position = UDim2.fromOffset(10, 26)
		bb.Size = UDim2.new(1, -20, 0, 34)
		bb.TextWrapped = true
		bb.Parent = card

		card.BackgroundTransparency = 1
		tween(card, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 0})

		task.delay(seconds, function()
			if not card.Parent then return end
			tween(card, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {BackgroundTransparency = 1})
			task.wait(0.18)
			if card then card:Destroy() end
		end)
	end

	function window:Destroy()
		if gui then gui:Destroy() end
	end

	function window:AddTab(name: string, iconText: string?)
		iconText = iconText or "•"

		local b = mk("TextButton", {
			BackgroundColor3 = Theme.Surface2,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 0, M.ButtonH),
			Text = "",
			AutoButtonColor = false,
			Parent = tabButtons,
		})
		addCorner(b, 10)
		addStroke(b, 0.85)

		local icon = label(iconText, M.FontBody, 0.25, Enum.FontWeight.Bold, Enum.TextXAlignment.Center)
		icon.Position = UDim2.fromOffset(6, 0)
		icon.Size = UDim2.fromOffset(18, M.ButtonH)
		icon.Parent = b

		local txt = label(name, M.FontBody, 0.0, Enum.FontWeight.SemiBold)
		txt.Position = UDim2.fromOffset(26, 0)
		txt.Size = UDim2.new(1, -30, 1, 0)
		txt.Parent = b

		local page = mk("Frame", {
			BackgroundTransparency = 1,
			Size = UDim2.fromScale(1, 1),
			Visible = false,
			Parent = pages,
		}) :: Frame

		local scroll = makeScroll(page)
		scroll.Size = UDim2.fromScale(1, 1)

		local tab: any = setmetatable({
			Name = name,
			Button = b,
			Page = page,
			Scroll = scroll,
		}, TabMT)

		function tab:AddSection(titleText2: string)
			return makeSection(scroll, titleText2)
		end
		function tab:AddButtonIn(section: Instance, text2: string, cb: () -> ())
			return makeButton(section, text2, cb)
		end
		function tab:AddToggleIn(section: Instance, text2: string, default2: boolean, cb: Callback<boolean>)
			return makeToggle(section, text2, default2, cb)
		end
		function tab:AddSliderIn(section: Instance, text2: string, minV: number, maxV: number, defaultV: number, cb: Callback<number>)
			return makeSlider(section, text2, minV, maxV, defaultV, cb)
		end
		function tab:AddDropdownIn(section: Instance, text2: string, opts2: {string}, default2: string?, cb: Callback<string>)
			return makeDropdown(section, text2, opts2, default2, cb, window.Root)
		end
		function tab:AddKeybindIn(section: Instance, text2: string, defaultKey: Enum.KeyCode, onKeyChanged: Callback<Enum.KeyCode>, onPressed: (() -> ())?)
			return makeKeybind(section, text2, defaultKey, onKeyChanged, onPressed)
		end

		function tab:Show()
			for _, t2 in pairs(window.Tabs) do
				t2.Page.Visible = false
				tween(t2.Button, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Theme.Surface2})
			end
			page.Visible = true
			tween(b, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Theme.Surface3})
			window.CurrentTab = tab
		end

		b.MouseEnter:Connect(function()
			if window.CurrentTab ~= tab then
				tween(b, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Theme.Surface})
			end
		end)
		b.MouseLeave:Connect(function()
			if window.CurrentTab ~= tab then
				tween(b, TweenInfo.new(0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundColor3 = Theme.Surface2})
			end
		end)
		b.MouseButton1Click:Connect(function() tab:Show() end)

		window.Tabs[name] = tab
		if not window.CurrentTab then tab:Show() end
		return tab
	end

	return window :: Window
end

return Lib
