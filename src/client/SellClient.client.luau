--!strict
-- SellClient: painel do NPC "Vender Brainmon" (estilo chunky via UIKit). Abre ao disparar o ProximityPrompt "SellPrompt".
-- Vender manda a Configuration pro servidor, que revalida posse e paga. Valor = Data.SellValue (mesma formula do servidor).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")

local Data = require(ReplicatedStorage:WaitForChild("BrainmonData"))
local UIKit = require(ReplicatedStorage:WaitForChild("UIKit"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SellBrainmon = Remotes:WaitForChild("SellBrainmon") :: RemoteFunction

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local braindex = player:WaitForChild("Braindex") :: Folder
local ACCENT = Color3.fromRGB(70, 180, 110)

local gui = Instance.new("ScreenGui")
gui.Name = "BrainSell"
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
	size = UDim2.fromOffset(460, 500),
	title = "Vender Brainmon",
	accent = ACCENT,
	contentColor = Color3.fromRGB(24, 34, 28),
})

local scroll = Instance.new("ScrollingFrame")
scroll.Position = UDim2.fromOffset(12, 10)
scroll.Size = UDim2.new(1, -24, 1, -20)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 6
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.Parent = panel.content
do
	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 8)
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Parent = scroll
end

local empty = Instance.new("TextLabel")
empty.BackgroundTransparency = 1
empty.Position = scroll.Position
empty.Size = scroll.Size
empty.Font = Enum.Font.GothamBold
empty.TextSize = 18
empty.TextColor3 = Color3.fromRGB(150, 170, 160)
empty.Text = "Nada pra vender."
empty.Visible = false
empty.Parent = panel.content

-- toast de venda
local toast = Instance.new("TextLabel")
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -14)
toast.Size = UDim2.fromOffset(300, 44)
toast.BackgroundColor3 = Color3.fromRGB(18, 24, 20)
toast.BackgroundTransparency = 1
toast.TextTransparency = 1
toast.Font = Enum.Font.FredokaOne
toast.TextScaled = true
toast.TextColor3 = Color3.fromRGB(120, 255, 138)
toast.ZIndex = 6
UIKit.textOutline(toast)
toast.Text = ""
toast.Parent = panel.root
UIKit.corner(toast, 10)
local function showToast(text: string)
	toast.Text = text
	toast.BackgroundTransparency = 0.1
	toast.TextTransparency = 0
	local t = TweenService:Create(toast, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { BackgroundTransparency = 1, TextTransparency = 1 })
	task.delay(1.0, function()
		t:Play()
	end)
end

-- ---------------------------------------------------------------- venda
local selling = false
local function doSell(cfg: Configuration, btn: TextButton)
	if selling then
		return
	end
	selling = true
	local label = btn.Text
	btn.Text = "..."
	local ok, res = pcall(function()
		return SellBrainmon:InvokeServer(cfg)
	end)
	selling = false
	if ok and typeof(res) == "table" and res.ok then
		showToast("+ $" .. Data.Money(res.value or 0))
	else
		btn.Text = label
	end
end

-- ---------------------------------------------------------------- linhas
local function row(cfg: Configuration, order: number)
	local sp = Data.SpeciesById[cfg:GetAttribute("Species") :: string]
	if not sp then
		return
	end
	local rarity = Data.RarityOf(sp)
	local mutation = (cfg:GetAttribute("Mutation") :: string?) or "Normal"
	local mut = Data.Mutations[mutation]
	local isMut = mutation ~= "Normal" and mut ~= nil
	local color = if isMut then mut.color else Data.RarityInfo[rarity].color
	local value = Data.SellValue(sp.id, mutation)

	local r = Instance.new("Frame")
	r.Size = UDim2.new(1, 0, 0, 64)
	r.BackgroundColor3 = Color3.fromRGB(36, 48, 42)
	r.BorderSizePixel = 0
	r.LayoutOrder = order
	r.Parent = scroll
	UIKit.corner(r, 12)
	UIKit.stroke(r, 3)

	local tag = Instance.new("Frame")
	tag.Size = UDim2.new(0, 8, 1, -16)
	tag.Position = UDim2.fromOffset(8, 8)
	tag.BackgroundColor3 = color
	tag.BorderSizePixel = 0
	tag.Parent = r
	UIKit.corner(tag, 4)

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromOffset(24, 10)
	name.Size = UDim2.new(1, -160, 0, 28)
	name.Font = Enum.Font.FredokaOne
	name.TextScaled = true
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextColor3 = Color3.fromRGB(245, 245, 245)
	UIKit.textOutline(name)
	name.Text = (if isMut then mut.label .. " " else "") .. sp.name
	name.Parent = r

	local sub = Instance.new("TextLabel")
	sub.BackgroundTransparency = 1
	sub.Position = UDim2.fromOffset(24, 38)
	sub.Size = UDim2.new(1, -160, 0, 18)
	sub.Font = Enum.Font.GothamBold
	sub.TextScaled = true
	sub.TextXAlignment = Enum.TextXAlignment.Left
	sub.TextColor3 = color
	sub.Text = `Lv {cfg:GetAttribute("Level") or 1} · {rarity}`
	sub.Parent = r

	local sell = UIKit.button({
		parent = r,
		text = "$" .. Data.Money(value),
		color = Color3.fromRGB(80, 200, 95),
		size = UDim2.fromOffset(124, 44),
		position = UDim2.new(1, -10, 0.5, 0),
		anchor = Vector2.new(1, 0.5),
	})
	sell.Activated:Connect(function()
		doSell(cfg, sell)
	end)
end

local function rebuild()
	for _, ch in scroll:GetChildren() do
		if ch:IsA("Frame") then
			ch:Destroy()
		end
	end
	local kids = braindex:GetChildren()
	empty.Visible = #kids == 0
	for i, cfg in kids do
		if cfg:IsA("Configuration") then
			row(cfg :: Configuration, i)
		end
	end
end

local function markDirty()
	if gui.Enabled then
		rebuild()
	end
end
braindex.ChildAdded:Connect(markDirty)
braindex.ChildRemoved:Connect(markDirty)

-- ---------------------------------------------------------------- abre pelo prompt do NPC
local function bindPrompt(p: Instance)
	if p:IsA("ProximityPrompt") then
		p.Triggered:Connect(function(plr)
			if plr == player then
				gui.Enabled = true
				rebuild()
			end
		end)
	end
end
for _, p in CollectionService:GetTagged("SellPrompt") do
	bindPrompt(p)
end
CollectionService:GetInstanceAddedSignal("SellPrompt"):Connect(bindPrompt)

panel.close.Activated:Connect(function()
	gui.Enabled = false
end)
dim.Activated:Connect(function()
	gui.Enabled = false
end)
