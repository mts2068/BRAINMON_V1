--!strict
-- BattleClient (F2): UI da batalha por turnos. Escuta BattleSync (estado do servidor) e manda BattleAction.
-- So exibe e pede; o servidor decide tudo (dano, captura, XP). Menu: Fight / Bag / Run / Monster.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local UIKit = require(ReplicatedStorage:WaitForChild("UIKit"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BattleAction = Remotes:WaitForChild("BattleAction") :: RemoteEvent
local BattleSync = Remotes:WaitForChild("BattleSync") :: RemoteEvent

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainBattle"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = false
gui.Parent = playerGui

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = Color3.fromRGB(12, 14, 22)
bg.BackgroundTransparency = 0.25
bg.BorderSizePixel = 0
bg.Parent = gui

-- ---------------------------------------------------------------- caixa de info (nome/level/HP)
local function infoBox(anchorRight: boolean, yScale: number): any
	local f = Instance.new("Frame")
	f.Size = UDim2.fromOffset(320, 78)
	f.AnchorPoint = Vector2.new(if anchorRight then 1 else 0, 0.5)
	f.Position = UDim2.new(if anchorRight then 1 else 0, if anchorRight then -24 else 24, yScale, 0)
	f.BackgroundColor3 = Color3.fromRGB(28, 30, 44)
	f.BorderSizePixel = 0
	f.Parent = gui
	UIKit.corner(f, 12)
	UIKit.stroke(f, 3)
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Position = UDim2.fromOffset(12, 6)
	name.Size = UDim2.new(1, -70, 0, 26)
	name.Font = Enum.Font.FredokaOne
	name.TextScaled = true
	name.TextXAlignment = Enum.TextXAlignment.Left
	name.TextColor3 = Color3.fromRGB(245, 245, 245)
	UIKit.textOutline(name)
	name.Parent = f
	local lv = Instance.new("TextLabel")
	lv.BackgroundTransparency = 1
	lv.AnchorPoint = Vector2.new(1, 0)
	lv.Position = UDim2.new(1, -12, 0, 6)
	lv.Size = UDim2.fromOffset(58, 26)
	lv.Font = Enum.Font.GothamBold
	lv.TextScaled = true
	lv.TextColor3 = Color3.fromRGB(230, 230, 235)
	UIKit.textOutline(lv)
	lv.Parent = f
	local barBg = Instance.new("Frame")
	barBg.Position = UDim2.fromOffset(12, 40)
	barBg.Size = UDim2.new(1, -24, 0, 16)
	barBg.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
	barBg.BorderSizePixel = 0
	barBg.Parent = f
	UIKit.corner(barBg, 8)
	UIKit.stroke(barBg, 2)
	local fill = Instance.new("Frame")
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(90, 220, 110)
	fill.BorderSizePixel = 0
	fill.Parent = barBg
	UIKit.corner(fill, 8)
	local hpTxt = Instance.new("TextLabel")
	hpTxt.BackgroundTransparency = 1
	hpTxt.Position = UDim2.fromOffset(12, 58)
	hpTxt.Size = UDim2.new(1, -24, 0, 16)
	hpTxt.Font = Enum.Font.GothamBold
	hpTxt.TextScaled = true
	hpTxt.TextXAlignment = Enum.TextXAlignment.Right
	hpTxt.TextColor3 = Color3.fromRGB(200, 205, 215)
	hpTxt.Parent = f
	return { frame = f, name = name, lv = lv, fill = fill, hpTxt = hpTxt }
end

local wildInfo = infoBox(true, 0.18)
local youInfo = infoBox(false, 0.64)

local function setHp(box: any, hp: number, maxHp: number, name: string, level: number)
	box.name.Text = name
	box.lv.Text = "Lv " .. level
	box.hpTxt.Text = `{math.max(0, hp)}/{maxHp}`
	local frac = math.clamp(hp / math.max(maxHp, 1), 0, 1)
	local col = if frac > 0.5 then Color3.fromRGB(90, 220, 110) elseif frac > 0.2 then Color3.fromRGB(240, 200, 60) else Color3.fromRGB(230, 70, 70)
	TweenService:Create(box.fill, TweenInfo.new(0.35), { Size = UDim2.fromScale(frac, 1) }):Play()
	box.fill.BackgroundColor3 = col
end

-- ---------------------------------------------------------------- diálogo
local dialog = Instance.new("TextLabel")
dialog.AnchorPoint = Vector2.new(0.5, 1)
dialog.Position = UDim2.new(0.5, 0, 1, -170)
dialog.Size = UDim2.fromOffset(620, 60)
dialog.BackgroundColor3 = Color3.fromRGB(28, 30, 44)
dialog.BorderSizePixel = 0
dialog.Font = Enum.Font.GothamBold
dialog.TextScaled = true
dialog.TextColor3 = Color3.fromRGB(245, 245, 245)
dialog.TextWrapped = true
dialog.Text = ""
dialog.Parent = gui
UIKit.corner(dialog, 12)
UIKit.stroke(dialog, 3)
do
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 14)
	pad.PaddingRight = UDim.new(0, 14)
	pad.Parent = dialog
end

-- ---------------------------------------------------------------- menu de ações
local menu = Instance.new("Frame")
menu.AnchorPoint = Vector2.new(0.5, 1)
menu.Position = UDim2.new(0.5, 0, 1, -24)
menu.Size = UDim2.fromOffset(620, 120)
menu.BackgroundTransparency = 1
menu.Parent = gui
do
	local grid = Instance.new("UIGridLayout")
	grid.CellSize = UDim2.fromOffset(302, 56)
	grid.CellPadding = UDim2.fromOffset(16, 8)
	grid.Parent = menu
end

local function clearMenu()
	for _, c in menu:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
end

local busy = false
local function send(action: any)
	if busy then
		return
	end
	busy = true
	clearMenu()
	BattleAction:FireServer(action)
end

local lastSnap: any = nil
local showMainMenu -- fwd

local function menuBtn(text: string, color: Color3, order: number, fn: () -> ())
	local b = UIKit.button({ parent = menu, text = text, color = color, size = UDim2.fromOffset(302, 56) })
	;(b.Parent :: Frame).LayoutOrder = order
	b.Activated:Connect(fn)
end

local function showFight()
	clearMenu()
	local s = lastSnap
	if not s then
		return
	end
	for i, mv in s.you.moves do
		menuBtn(mv, Color3.fromRGB(210, 70, 70), i, function()
			send({ kind = "Fight", move = i })
		end)
	end
	menuBtn("◀ Voltar", Color3.fromRGB(90, 95, 115), 99, showMainMenu)
end

local BALLS = { { "Poke", "Poké Ball" }, { "Great", "Great Ball" }, { "Ultra", "Ultra Ball" }, { "Premier", "Premier Ball" } }
local function showBag()
	clearMenu()
	for i, b in BALLS do
		menuBtn(b[2], Color3.fromRGB(240, 196, 70), i, function()
			send({ kind = "Bag", ball = b[1] })
		end)
	end
	menuBtn("◀ Voltar", Color3.fromRGB(90, 95, 115), 99, showMainMenu)
end

local function showTeam()
	clearMenu()
	local s = lastSnap
	if not s then
		return
	end
	for i, m in s.team do
		if not m.fainted and i ~= s.activeIndex then
			menuBtn(`{m.name} ({m.hp}/{m.maxHp})`, Color3.fromRGB(70, 180, 110), i, function()
				send({ kind = "Switch", index = i })
			end)
		end
	end
	menuBtn("◀ Voltar", Color3.fromRGB(90, 95, 115), 99, showMainMenu)
end

function showMainMenu()
	clearMenu()
	menuBtn("⚔ Fight", Color3.fromRGB(210, 70, 70), 1, showFight)
	menuBtn("🎒 Bag", Color3.fromRGB(240, 196, 70), 2, showBag)
	menuBtn("🔄 Monster", Color3.fromRGB(70, 180, 110), 3, showTeam)
	menuBtn("🏃 Run", Color3.fromRGB(90, 140, 230), 4, function()
		send({ kind = "Run" })
	end)
end

-- ---------------------------------------------------------------- recebe estado
BattleSync.OnClientEvent:Connect(function(snap: any)
	if snap.noTeam then
		clearMenu()
		dialog.Text = "Você não tem Brainmon no squad! Pegue um com a Poké Ball (G)."
		gui.Enabled = true
		menuBtn("OK", Color3.fromRGB(90, 140, 230), 1, function()
			gui.Enabled = false
		end)
		return
	end
	lastSnap = snap
	busy = false
	gui.Enabled = true
	setHp(wildInfo, snap.wild.hp, snap.wild.maxHp, (if snap.wild.mutation ~= "Normal" then snap.wild.mutation .. " " else "") .. snap.wild.name, snap.wild.level)
	setHp(youInfo, snap.you.hp, snap.you.maxHp, snap.you.name, snap.you.level)
	dialog.Text = table.concat(snap.lines, "  ")
	if snap.over then
		clearMenu()
		task.delay(2.2, function()
			if lastSnap == snap then
				gui.Enabled = false
			end
		end)
	else
		showMainMenu()
	end
end)
