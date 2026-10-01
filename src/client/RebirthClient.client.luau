--!strict
-- RebirthClient: painel REBIRTH (estilo chunky via UIKit). Mostra multiplicador atual -> proximo e os requisitos.
-- Reseta so BC (mantem Braindex); da +multiplicador de coleta e +sorte de ovo. Servidor e a autoridade (Rebirth RF).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Data = require(ReplicatedStorage:WaitForChild("BrainmonData"))
local UIKit = require(ReplicatedStorage:WaitForChild("UIKit"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RebirthRF = Remotes:WaitForChild("Rebirth") :: RemoteFunction

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local braindex = player:WaitForChild("Braindex") :: Folder
local C = Data.Config
local ACCENT = Color3.fromRGB(205, 60, 80)
local OK_COL = Color3.fromRGB(120, 255, 138)
local NO_COL = Color3.fromRGB(255, 120, 120)

local gui = Instance.new("ScreenGui")
gui.Name = "BrainRebirth"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = false
gui.Parent = playerGui

local dim = Instance.new("TextButton")
dim.Text = ""
dim.AutoButtonColor = false
dim.BackgroundColor3 = Color3.new(0, 0, 0)
dim.BackgroundTransparency = 0.45
dim.BorderSizePixel = 0
dim.Size = UDim2.fromScale(1, 1)
dim.Parent = gui

local panel = UIKit.panel({
	parent = gui,
	size = UDim2.fromOffset(440, 440),
	title = "Rebirth",
	accent = ACCENT,
	contentColor = Color3.fromRGB(34, 26, 30),
})

-- helper: label simples
local function label(parent: Instance, pos: UDim2, size: UDim2, font: Enum.Font, scaled: boolean): TextLabel
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position = pos
	t.Size = size
	t.Font = font
	t.TextScaled = scaled
	t.TextColor3 = Color3.fromRGB(245, 245, 245)
	UIKit.textOutline(t)
	t.Parent = parent
	return t
end

-- caixa de bonus (multiplicador atual -> proximo)
local cashLabel = label(panel.content, UDim2.fromOffset(16, 16), UDim2.new(1, -32, 0, 40), Enum.Font.FredokaOne, true)
local luckLabel = label(panel.content, UDim2.fromOffset(16, 60), UDim2.new(1, -32, 0, 30), Enum.Font.GothamBold, true)

local warn = label(panel.content, UDim2.fromOffset(16, 98), UDim2.new(1, -32, 0, 24), Enum.Font.Gotham, true)
warn.TextColor3 = Color3.fromRGB(255, 180, 120)
warn.Text = "Reseta só os BrainCoins. Mantém o Braindex."

-- requisitos
local reqTitle = label(panel.content, UDim2.fromOffset(16, 130), UDim2.new(1, -32, 0, 24), Enum.Font.FredokaOne, true)
reqTitle.Text = "Requisitos:"
reqTitle.TextXAlignment = Enum.TextXAlignment.Left
local reqBC = label(panel.content, UDim2.fromOffset(16, 158), UDim2.new(1, -32, 0, 30), Enum.Font.GothamBold, true)
reqBC.TextXAlignment = Enum.TextXAlignment.Left
local reqSp = label(panel.content, UDim2.fromOffset(16, 192), UDim2.new(1, -32, 0, 30), Enum.Font.GothamBold, true)
reqSp.TextXAlignment = Enum.TextXAlignment.Left

-- toast
local toast = label(panel.content, UDim2.fromOffset(16, 226), UDim2.new(1, -32, 0, 24), Enum.Font.GothamBold, true)
toast.TextTransparency = 1
local function flash(text: string, color: Color3)
	toast.Text = text
	toast.TextColor3 = color
	toast.TextTransparency = 0
	local t = TweenService:Create(toast, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { TextTransparency = 1 })
	task.delay(1.3, function()
		t:Play()
	end)
end

-- botoes
local rebirthBtn = UIKit.button({
	parent = panel.content,
	text = "Rebirth",
	color = Color3.fromRGB(90, 150, 240),
	size = UDim2.new(0.56, -20, 0, 54),
	position = UDim2.new(0, 16, 1, -16),
	anchor = Vector2.new(0, 1),
})
local skipBtn = UIKit.button({
	parent = panel.content,
	text = "Skip (R$)",
	color = Color3.fromRGB(80, 200, 95),
	size = UDim2.new(0.44, -20, 0, 54),
	position = UDim2.new(1, -16, 1, -16),
	anchor = Vector2.new(1, 1),
})

-- ---------------------------------------------------------------- estado
local function distinctSpecies(): number
	local seen: { [string]: boolean } = {}
	for _, cfg in braindex:GetChildren() do
		local s = cfg:GetAttribute("Species")
		if typeof(s) == "string" then
			seen[s] = true
		end
	end
	local n = 0
	for _ in seen do
		n += 1
	end
	return n
end

local function refresh()
	local n = (player:GetAttribute("Rebirths") :: number?) or 0
	local bc = (player:GetAttribute("BC") :: number?) or 0
	local cost = math.floor(C.RebirthBaseCost * (C.RebirthCostMult ^ n))
	local needSp = C.RebirthBaseSpecies + n * C.RebirthSpeciesInc
	local haveSp = distinctSpecies()
	local curMult = C.CashMulti + n * C.RebirthCashInc
	local curLuck = 1 + n * C.RebirthLuckMult

	cashLabel.Text = `Coleta ×{string.format("%.1f", curMult)}  →  ×{string.format("%.1f", curMult + C.RebirthCashInc)}`
	luckLabel.Text = `Sorte de ovo ×{string.format("%.2f", curLuck)}  →  ×{string.format("%.2f", curLuck + C.RebirthLuckMult)}`
	luckLabel.TextColor3 = Color3.fromRGB(240, 196, 70)

	local bcOk = bc >= cost
	local spOk = haveSp >= needSp
	reqBC.Text = `BC: {Data.Money(bc)} / {Data.Money(cost)}`
	reqBC.TextColor3 = if bcOk then OK_COL else NO_COL
	reqSp.Text = `Espécies: {haveSp} / {needSp}`
	reqSp.TextColor3 = if spOk then OK_COL else NO_COL
end

local busy = false
local ERR: { [string]: string } = { NeedSpecies = "Faltam espécies", NotEnough = "BC insuficiente", Busy = "Calma!" }
rebirthBtn.Activated:Connect(function()
	if busy then
		return
	end
	busy = true
	local ok, res = pcall(function()
		return RebirthRF:InvokeServer()
	end)
	busy = false
	if ok and typeof(res) == "table" and res.ok then
		flash(`Rebirth {res.rebirths}! ✨`, OK_COL)
	elseif ok and typeof(res) == "table" then
		flash(ERR[res.code] or "Não deu", NO_COL)
	end
	refresh()
end)
skipBtn.Activated:Connect(function()
	flash("Robux em breve", Color3.fromRGB(240, 196, 70))
end)

player:GetAttributeChangedSignal("BC"):Connect(refresh)
player:GetAttributeChangedSignal("Rebirths"):Connect(refresh)
braindex.ChildAdded:Connect(refresh)
braindex.ChildRemoved:Connect(refresh)

-- ---------------------------------------------------------------- abrir/fechar
local hud = playerGui:WaitForChild("BrainHud")
local menuClick = hud:WaitForChild("MenuClick") :: BindableEvent
menuClick.Event:Connect(function(name: string)
	if name ~= "REBIRTH" then
		return
	end
	gui.Enabled = not gui.Enabled
	if gui.Enabled then
		refresh()
	end
end)
panel.close.Activated:Connect(function()
	gui.Enabled = false
end)
dim.Activated:Connect(function()
	gui.Enabled = false
end)

refresh()
