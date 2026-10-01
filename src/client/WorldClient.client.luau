--!strict
-- WorldClient: o cliente SO pede e exibe. Atmosfera por mundo, menu Worlds (tecla M: IR / LIBERAR / BLOQUEADO),
-- fade + banner do nome da area. Estilo de UI do guia 6.3: fundo #23263A transp 0.4, UICorner 12, UIStroke 2, texto Bold com stroke preto.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Data = require(ReplicatedStorage:WaitForChild("BrainmonData"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local WorldTravel = Remotes:WaitForChild("WorldTravel") :: RemoteEvent
local WorldState = Remotes:WaitForChild("WorldState") :: RemoteEvent
local WorldBanner = Remotes:WaitForChild("WorldBanner") :: RemoteEvent

local player = Players.LocalPlayer

-- ---------------------------------------------------------------- atmosfera
local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
atm.Parent = Lighting
local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
bloom.Size = 24
bloom.Parent = Lighting

local currentTweens: { Tween } = {}
local function applyAtmosphere(raw: { [string]: any })
	local a = Data.SafeAtmosphere(raw) -- clamp na faixa segura
	for _, t in currentTweens do
		t:Cancel()
	end
	local info = TweenInfo.new(1.5, Enum.EasingStyle.Sine)
	currentTweens = {
		TweenService:Create(Lighting, info, { ClockTime = a.clock, Brightness = a.brightness, Ambient = a.ambient, OutdoorAmbient = a.outdoor }),
		TweenService:Create(atm, info, { Color = a.atmColor, Haze = a.haze, Density = a.density, Decay = a.decay, Glare = a.glare }),
		TweenService:Create(bloom, info, { Threshold = a.bloomThreshold, Intensity = a.bloomIntensity }),
	}
	for _, t in currentTweens do
		t:Play()
	end
end

local function onWorld()
	local idx = (player:GetAttribute("World") :: number?) or 0
	applyAtmosphere(if idx == 0 then Data.HubAtmosphere else Data.Worlds[idx].atmosphere)
end
player:GetAttributeChangedSignal("World"):Connect(onWorld)
onWorld()

-- ---------------------------------------------------------------- UI
local function new(class: string, props: { [string]: any }, parent: Instance?): any
	local o = Instance.new(class)
	for k, v in props do
		(o :: any)[k] = v
	end
	o.Parent = parent
	return o
end

local function text(parent: Instance, props: { [string]: any }): TextLabel
	props.BackgroundTransparency = 1
	props.Font = props.Font or Enum.Font.GothamBold
	props.TextColor3 = props.TextColor3 or Color3.fromRGB(242, 242, 242)
	props.TextStrokeColor3 = Color3.new(0, 0, 0)
	props.TextStrokeTransparency = 0
	return new("TextLabel", props, parent)
end

local gui = new("ScreenGui", { Name = "WorldUI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 20 }, player:WaitForChild("PlayerGui"))

local fade = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, ZIndex = 100, Active = false }, gui)
local banner = text(gui, { Size = UDim2.fromScale(0.7, 0.1), Position = UDim2.fromScale(0.15, 0.12), TextScaled = true, TextTransparency = 1, TextStrokeTransparency = 1, ZIndex = 101 })
local noticeLbl = text(gui, { Size = UDim2.fromScale(0.5, 0.05), Position = UDim2.fromScale(0.25, 0.8), TextScaled = true, TextTransparency = 1, TextStrokeTransparency = 1, TextColor3 = Color3.fromRGB(255, 201, 51), ZIndex = 101 })

local function flash(lbl: TextLabel, msg: string, secs: number)
	lbl.Text = msg
	lbl.TextTransparency, lbl.TextStrokeTransparency = 0, 0
	task.delay(secs, function()
		if lbl.Text == msg then
			TweenService:Create(lbl, TweenInfo.new(0.6), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

WorldBanner.OnClientEvent:Connect(function(kind: string, msg: string?)
	if kind == "FadeOut" then
		TweenService:Create(fade, TweenInfo.new(0.4), { BackgroundTransparency = 0 }):Play()
	elseif kind == "FadeIn" then
		TweenService:Create(fade, TweenInfo.new(0.6), { BackgroundTransparency = 1 }):Play()
		flash(banner, msg or "", 3)
	elseif kind == "Notice" then
		flash(noticeLbl, msg or "", 3)
	end
end)

-- menu Worlds
local menu = new("Frame", { Size = UDim2.fromOffset(460, 560), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Color3.fromRGB(35, 38, 58), BackgroundTransparency = 0.25, Visible = false }, gui)
new("UICorner", { CornerRadius = UDim.new(0, 12) }, menu)
new("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0) }, menu)
text(menu, { Size = UDim2.new(1, -60, 0, 44), Position = UDim2.fromOffset(12, 6), Text = "MUNDOS", TextXAlignment = Enum.TextXAlignment.Left, TextSize = 28 })
local close = new("TextButton", { Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -46, 0, 6), BackgroundColor3 = Color3.fromRGB(183, 28, 28), Text = "X", Font = Enum.Font.GothamBold, TextSize = 22, TextColor3 = Color3.new(1, 1, 1) }, menu)
new("UICorner", { CornerRadius = UDim.new(0, 8) }, close)
new("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0) }, close)

local list = new("ScrollingFrame", { Size = UDim2.new(1, -24, 1, -64), Position = UDim2.fromOffset(12, 54), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 6, CanvasSize = UDim2.new() , AutomaticCanvasSize = Enum.AutomaticSize.Y }, menu)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, list)

type Row = { sub: TextLabel, btn: TextButton }
local rows: { [number]: Row } = {}

local function makeRow(idx: number, title: string, accent: Color3)
	local f = new("Frame", { Size = UDim2.new(1, -8, 0, 56), BackgroundColor3 = Color3.fromRGB(20, 22, 34), BackgroundTransparency = 0.2, LayoutOrder = idx }, list)
	new("UICorner", { CornerRadius = UDim.new(0, 8) }, f)
	new("Frame", { Size = UDim2.new(0, 5, 1, 0), BackgroundColor3 = accent, BorderSizePixel = 0 }, f)
	text(f, { Size = UDim2.new(1, -150, 0, 28), Position = UDim2.fromOffset(14, 2), Text = title, TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true })
	local sub = text(f, { Size = UDim2.new(1, -150, 0, 22), Position = UDim2.fromOffset(14, 31), Text = "", TextXAlignment = Enum.TextXAlignment.Left, TextScaled = true, Font = Enum.Font.Gotham, TextColor3 = Color3.fromRGB(255, 201, 51) })
	local btn = new("TextButton", { Size = UDim2.fromOffset(120, 36), Position = UDim2.new(1, -130, 0.5, -18), BackgroundColor3 = Color3.fromRGB(91, 58, 140), Text = "IR", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Color3.new(1, 1, 1) }, f)
	new("UICorner", { CornerRadius = UDim.new(0, 8) }, btn)
	new("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0) }, btn)
	btn.MouseButton1Click:Connect(function()
		WorldTravel:FireServer(idx)
		menu.Visible = false
	end)
	rows[idx] = { sub = sub, btn = btn }
end

makeRow(0, "Nexus Brainmon (Hub)", Color3.fromRGB(80, 200, 255))
for i, w in Data.Worlds do
	makeRow(i, `{i}. {w.name}`, w.style.accent)
end

local state = { unlocked = 1, world = 0, bc = 0, owned = {} :: { [number]: number } }
local function refresh()
	rows[0].sub.Text = "Praça central · liberdade para voltar"
	for i, w in Data.Worlds do
		local r = rows[i]
		if i <= state.unlocked then
			r.btn.Text, r.btn.BackgroundColor3 = "IR", Color3.fromRGB(91, 58, 140)
			r.sub.Text = `Raridade nativa: {w.rarity}`
		elseif i == state.unlocked + 1 then
			r.btn.Text, r.btn.BackgroundColor3 = "LIBERAR", Color3.fromRGB(107, 122, 58)
			r.sub.Text = Data.GateText(i, state.owned[i - 1] or 0, state.bc)
		else
			r.btn.Text, r.btn.BackgroundColor3 = "BLOQUEADO", Color3.fromRGB(70, 70, 80)
			r.sub.Text = `Libere o mundo {i - 1} antes`
		end
	end
end
refresh()

WorldState.OnClientEvent:Connect(function(s)
	state = s
	refresh()
end)

local function toggle()
	menu.Visible = not menu.Visible
end
close.MouseButton1Click:Connect(function()
	menu.Visible = false
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.M then
		toggle()
	end
end)

local hint = new("TextButton", { Size = UDim2.fromOffset(150, 40), Position = UDim2.new(0, 14, 1, -54), BackgroundColor3 = Color3.fromRGB(35, 38, 58), BackgroundTransparency = 0.4, Text = "[M] MUNDOS", Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = Color3.new(1, 1, 1) }, gui)
new("UICorner", { CornerRadius = UDim.new(0, 12) }, hint)
new("UIStroke", { Thickness = 2, Color = Color3.new(0, 0, 0) }, hint)
hint.MouseButton1Click:Connect(toggle)
