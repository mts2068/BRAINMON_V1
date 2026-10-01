--!strict
-- BrainDexClient: painel BRAINDEX (estilo chunky via UIKit). Grid dos individuos reais do player, lido por
-- replicacao de atributo (player.Braindex = Folder de Configuration com Species/Mutation/Level/...). Sem Remote de leitura.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage:WaitForChild("BrainmonData"))
local UIKit = require(ReplicatedStorage:WaitForChild("UIKit"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local braindex = player:WaitForChild("Braindex") :: Folder
local ACCENT = Color3.fromRGB(70, 110, 235)

local gui = Instance.new("ScreenGui")
gui.Name = "BrainDex"
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
	size = UDim2.fromOffset(580, 500),
	title = "Braindex",
	accent = ACCENT,
	contentColor = Color3.fromRGB(26, 30, 44),
})

local countLabel = Instance.new("TextLabel")
countLabel.BackgroundTransparency = 1
countLabel.AnchorPoint = Vector2.new(1, 0.5)
countLabel.Position = UDim2.new(1, -58, 0, 26)
countLabel.Size = UDim2.fromOffset(160, 24)
countLabel.Font = Enum.Font.GothamBold
countLabel.TextScaled = true
countLabel.TextXAlignment = Enum.TextXAlignment.Right
countLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
countLabel.ZIndex = 3
UIKit.textOutline(countLabel)
countLabel.Text = ""
countLabel.Parent = panel.header

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
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(100, 118)
	grid.CellPadding = UDim2.fromOffset(10, 10)
	grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
	grid.SortOrder = Enum.SortOrder.LayoutOrder
	grid.Parent = scroll
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0, 4)
	pad.Parent = scroll
end

local empty = Instance.new("TextLabel")
empty.BackgroundTransparency = 1
empty.Position = scroll.Position
empty.Size = scroll.Size
empty.Font = Enum.Font.GothamBold
empty.TextSize = 18
empty.TextColor3 = Color3.fromRGB(150, 160, 190)
empty.Text = "Nenhum Brainmon ainda.\nCapture um selvagem ou compre um ovo na loja."
empty.Visible = false
empty.Parent = panel.content

-- ---------------------------------------------------------------- slot por individuo
local function makeSlot(cfg: Configuration, order: number)
	local sp = Data.SpeciesById[cfg:GetAttribute("Species") :: string]
	if not sp then
		return
	end
	local rarity = Data.RarityOf(sp)
	local mutation = (cfg:GetAttribute("Mutation") :: string?) or "Normal"
	local mut = Data.Mutations[mutation]
	local isMut = mutation ~= "Normal" and mut ~= nil
	local color = if isMut then mut.color else Data.RarityInfo[rarity].color

	local slot = Instance.new("Frame")
	slot.BackgroundColor3 = Color3.fromRGB(38, 44, 62)
	slot.BorderSizePixel = 0
	slot.LayoutOrder = order
	slot.Parent = scroll
	UIKit.corner(slot, 10)
	UIKit.stroke(slot, 3, color)

	local typeBar = Instance.new("Frame")
	typeBar.Size = UDim2.new(1, 0, 0, 8)
	typeBar.BackgroundColor3 = Data.Types[sp.type] or Color3.fromRGB(200, 200, 200)
	typeBar.BorderSizePixel = 0
	typeBar.Parent = slot
	UIKit.corner(typeBar, 10)

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromOffset(4, 14)
	name.Size = UDim2.new(1, -8, 0, 54)
	name.Font = Enum.Font.FredokaOne
	name.TextWrapped = true
	name.TextSize = 14
	name.TextColor3 = Color3.fromRGB(245, 245, 245)
	UIKit.textOutline(name)
	name.Text = (if isMut then mut.label .. " " else "") .. sp.name
	name.Parent = slot

	local info = Instance.new("TextLabel")
	info.BackgroundTransparency = 1
	info.AnchorPoint = Vector2.new(0.5, 1)
	info.Position = UDim2.new(0.5, 0, 1, -8)
	info.Size = UDim2.new(1, -8, 0, 32)
	info.Font = Enum.Font.GothamBold
	info.TextScaled = true
	info.TextColor3 = color
	info.Text = `Lv {cfg:GetAttribute("Level") or 1} · {rarity}`
	info.Parent = slot
end

local function rebuild()
	for _, ch in scroll:GetChildren() do
		if ch:IsA("Frame") then
			ch:Destroy()
		end
	end
	local kids = braindex:GetChildren()
	empty.Visible = #kids == 0
	local species: { [string]: boolean } = {}
	for i, cfg in kids do
		if cfg:IsA("Configuration") then
			makeSlot(cfg :: Configuration, i)
			species[cfg:GetAttribute("Species") :: string] = true
		end
	end
	local nsp = 0
	for _ in species do
		nsp += 1
	end
	countLabel.Text = `{#kids} · {nsp}/{#Data.Species}`
end

local dirty = false
local function markDirty()
	if gui.Enabled then
		rebuild()
	else
		dirty = true
	end
end
braindex.ChildAdded:Connect(markDirty)
braindex.ChildRemoved:Connect(markDirty)

-- ---------------------------------------------------------------- abrir/fechar
local hud = playerGui:WaitForChild("BrainHud")
local menuClick = hud:WaitForChild("MenuClick") :: BindableEvent
menuClick.Event:Connect(function(name: string)
	if name ~= "BRAINDEX" then
		return
	end
	gui.Enabled = not gui.Enabled
	if gui.Enabled and dirty then
		dirty = false
		rebuild()
	end
end)
panel.close.Activated:Connect(function()
	gui.Enabled = false
end)
dim.Activated:Connect(function()
	gui.Enabled = false
end)

rebuild()
