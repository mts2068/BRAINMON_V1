--!strict
-- ShopClient: Loja no estilo da referencia. Aba "Ovos" (lista | detalhe com OVO em display + odds de mutation + comprar)
-- e aba "Ofertas" (Starter Pack + VIP). O ovo em display esconde QUAL brainmon vem; so mostra a raridade e as odds.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local Data = require(ReplicatedStorage:WaitForChild("BrainmonData"))
local Factory = require(ReplicatedStorage:WaitForChild("BrainmonFactory"))
local UIKit = require(ReplicatedStorage:WaitForChild("UIKit"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ShopBuy = Remotes:WaitForChild("ShopBuy") :: RemoteFunction

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local ACCENT = Color3.fromRGB(150, 80, 215)

local gui = Instance.new("ScreenGui")
gui.Name = "BrainShop"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Enabled = false
gui.Parent = playerGui

local dim = Instance.new("TextButton")
dim.Text, dim.AutoButtonColor, dim.BorderSizePixel = "", false, 0
dim.BackgroundColor3, dim.BackgroundTransparency = Color3.new(0, 0, 0), 0.5
dim.Size = UDim2.fromScale(1, 1)
dim.Parent = gui

local panel = UIKit.panel({
	parent = gui,
	size = UDim2.fromOffset(640, 520),
	title = "Loja",
	accent = ACCENT,
	icon = "🥚",
	contentColor = Color3.fromRGB(34, 30, 46),
})
panel.close.Activated:Connect(function()
	gui.Enabled = false
end)
dim.Activated:Connect(function()
	gui.Enabled = false
end)

-- ====================== abas ======================
local tabBar = Instance.new("Frame")
tabBar.Position = UDim2.fromOffset(12, 8)
tabBar.Size = UDim2.new(1, -24, 0, 36)
tabBar.BackgroundTransparency = 1
tabBar.Parent = panel.content

local eggsView = Instance.new("Frame")
eggsView.Position = UDim2.fromOffset(0, 50)
eggsView.Size = UDim2.new(1, 0, 1, -50)
eggsView.BackgroundTransparency = 1
eggsView.Parent = panel.content

local offersView = Instance.new("Frame")
offersView.Position = UDim2.fromOffset(0, 50)
offersView.Size = UDim2.new(1, 0, 1, -50)
offersView.BackgroundTransparency = 1
offersView.Visible = false
offersView.Parent = panel.content

local function showTab(eggs: boolean)
	eggsView.Visible = eggs
	offersView.Visible = not eggs
end
local tabEggs = UIKit.button({ parent = tabBar, text = "🥚 Ovos", color = Color3.fromRGB(150, 80, 215), size = UDim2.new(0.5, -6, 1, 0), position = UDim2.fromScale(0, 0), anchor = Vector2.new(0, 0) })
local tabOffers = UIKit.button({ parent = tabBar, text = "💎 Ofertas", color = Color3.fromRGB(240, 170, 60), size = UDim2.new(0.5, -6, 1, 0), position = UDim2.fromScale(1, 0), anchor = Vector2.new(1, 0) })
tabEggs.Activated:Connect(function()
	showTab(true)
end)
tabOffers.Activated:Connect(function()
	showTab(false)
end)

-- ====================== reveal + toast (compartilhados) ======================
local function spinModel(viewport: ViewportFrame, camera: Camera, model: Model): () -> ()
	for _, c in viewport:GetChildren() do
		if c:IsA("Model") then
			c:Destroy()
		end
	end
	model.Parent = viewport
	local cf, size = model:GetBoundingBox()
	local center = cf.Position
	local radius = math.max(size.X, size.Y, size.Z)
	local dist = radius * 2.0 + 3
	local a = 0
	local conn = RunService.RenderStepped:Connect(function(dt)
		a += dt * 0.7
		camera.CFrame = CFrame.lookAt(center + Vector3.new(math.sin(a) * dist, radius * 0.35, math.cos(a) * dist), center)
	end)
	return function()
		conn:Disconnect()
		model:Destroy()
	end
end

local revealOverlay = Instance.new("TextButton")
revealOverlay.Text, revealOverlay.AutoButtonColor, revealOverlay.BorderSizePixel = "", false, 0
revealOverlay.BackgroundColor3, revealOverlay.BackgroundTransparency = Color3.new(0, 0, 0), 0.5
revealOverlay.Size, revealOverlay.Visible, revealOverlay.ZIndex = UDim2.fromScale(1, 1), false, 20
revealOverlay.Parent = gui
local card = Instance.new("Frame")
card.AnchorPoint, card.Position, card.Size = Vector2.new(0.5, 0.5), UDim2.fromScale(0.5, 0.5), UDim2.fromOffset(300, 350)
card.BackgroundColor3, card.BorderSizePixel, card.ZIndex = Color3.fromRGB(32, 30, 42), 0, 21
card.Parent = revealOverlay
UIKit.corner(card, 16)
local cardStroke = UIKit.stroke(card, 4)
local cardScale = Instance.new("UIScale")
cardScale.Parent = card
local rvp = Instance.new("ViewportFrame")
rvp.Size, rvp.Position = UDim2.new(1, -20, 0, 230), UDim2.fromOffset(10, 12)
rvp.BackgroundColor3, rvp.Ambient, rvp.ZIndex = Color3.fromRGB(20, 18, 28), Color3.fromRGB(210, 210, 210), 21
rvp.Parent = card
UIKit.corner(rvp, 12)
local rcam = Instance.new("Camera")
rcam.Parent = rvp
rvp.CurrentCamera = rcam
local rName = Instance.new("TextLabel")
rName.BackgroundTransparency, rName.Position, rName.Size = 1, UDim2.fromOffset(10, 250), UDim2.new(1, -20, 0, 54)
rName.Font, rName.TextScaled, rName.ZIndex = Enum.Font.FredokaOne, true, 21
UIKit.textOutline(rName)
rName.Parent = card
local rSub = Instance.new("TextLabel")
rSub.BackgroundTransparency, rSub.Position, rSub.Size = 1, UDim2.fromOffset(10, 306), UDim2.new(1, -20, 0, 30)
rSub.Font, rSub.TextScaled, rSub.ZIndex = Enum.Font.GothamBold, true, 21
UIKit.textOutline(rSub)
rSub.Parent = card

local revealClean: (() -> ())? = nil
local function showResult(p: any)
	if revealClean then
		revealClean()
	end
	local sp = Data.SpeciesById[p.Species]
	local mut = Data.Mutations[p.Mutation]
	local isMut = p.Mutation ~= "Normal" and mut ~= nil
	local color = if isMut then mut.color else Data.RarityInfo[p.Rarity].color
	rName.Text = (if isMut then mut.label .. " " else "") .. (if sp then sp.name else tostring(p.Species))
	rName.TextColor3 = Color3.fromRGB(255, 255, 255)
	rSub.Text = if isMut then `{p.Rarity} · {mut.label}` else p.Rarity
	rSub.TextColor3 = color
	cardStroke.Color = color
	revealClean = spinModel(rvp, rcam, Factory.Create(p.Species, p.Mutation))
	revealOverlay.Visible = true
	cardScale.Scale = 0.7
	TweenService:Create(cardScale, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
end
revealOverlay.Activated:Connect(function()
	revealOverlay.Visible = false
	if revealClean then
		revealClean()
		revealClean = nil
	end
end)
;(Remotes:WaitForChild("ShopReveal") :: RemoteEvent).OnClientEvent:Connect(showResult)

local toast = Instance.new("TextLabel")
toast.AnchorPoint, toast.Position, toast.Size = Vector2.new(0.5, 1), UDim2.new(0.5, 0, 1, -10), UDim2.fromOffset(320, 40)
toast.BackgroundTransparency, toast.TextTransparency, toast.ZIndex = 1, 1, 8
toast.Font, toast.TextScaled = Enum.Font.FredokaOne, true
UIKit.textOutline(toast)
toast.Parent = panel.root
local function flash(text: string, color: Color3)
	toast.Text, toast.TextColor3, toast.TextTransparency = text, color, 0
	local t = TweenService:Create(toast, TweenInfo.new(0.6, Enum.EasingStyle.Quad), { TextTransparency = 1 })
	task.delay(1.2, function()
		t:Play()
	end)
end

-- ====================== ABA OVOS ======================
local eggList = Instance.new("ScrollingFrame")
eggList.Position, eggList.Size = UDim2.fromOffset(12, 0), UDim2.new(0, 212, 1, -10)
eggList.BackgroundColor3, eggList.BackgroundTransparency, eggList.BorderSizePixel = Color3.fromRGB(22, 20, 32), 0.2, 0
eggList.ScrollBarThickness, eggList.CanvasSize, eggList.AutomaticCanvasSize = 5, UDim2.new(), Enum.AutomaticSize.Y
eggList.Parent = eggsView
UIKit.corner(eggList, 10)
UIKit.stroke(eggList, 3)
do
	local l = Instance.new("UIListLayout")
	l.Padding, l.SortOrder = UDim.new(0, 8), Enum.SortOrder.LayoutOrder
	l.Parent = eggList
	local p = Instance.new("UIPadding")
	p.PaddingTop, p.PaddingBottom, p.PaddingLeft, p.PaddingRight = UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8), UDim.new(0, 8)
	p.Parent = eggList
end

local detail = Instance.new("Frame")
detail.Position, detail.Size = UDim2.fromOffset(234, 0), UDim2.new(1, -246, 1, -10)
detail.BackgroundColor3, detail.BackgroundTransparency, detail.BorderSizePixel = Color3.fromRGB(22, 20, 32), 0.2, 0
detail.Parent = eggsView
UIKit.corner(detail, 10)
UIKit.stroke(detail, 3)

local vp = Instance.new("ViewportFrame")
vp.Position, vp.Size = UDim2.fromOffset(10, 10), UDim2.new(1, -20, 0, 160)
vp.BackgroundColor3, vp.Ambient = Color3.fromRGB(16, 14, 24), Color3.fromRGB(210, 210, 210)
vp.Parent = detail
UIKit.corner(vp, 8)
local cam = Instance.new("Camera")
cam.Parent = vp
vp.CurrentCamera = cam

local dName = Instance.new("TextLabel")
dName.BackgroundTransparency, dName.Position, dName.Size = 1, UDim2.fromOffset(10, 176), UDim2.new(1, -20, 0, 28)
dName.Font, dName.TextScaled, dName.TextColor3 = Enum.Font.FredokaOne, true, Color3.fromRGB(245, 245, 245)
UIKit.textOutline(dName)
dName.Parent = detail
local dRarity = Instance.new("TextLabel")
dRarity.BackgroundTransparency, dRarity.Position, dRarity.Size = 1, UDim2.fromOffset(10, 204), UDim2.new(1, -20, 0, 18)
dRarity.Font, dRarity.TextScaled = Enum.Font.GothamBold, true
dRarity.Parent = detail
local oddsTitle = Instance.new("TextLabel")
oddsTitle.BackgroundTransparency, oddsTitle.Position, oddsTitle.Size = 1, UDim2.fromOffset(10, 226), UDim2.new(1, -20, 0, 16)
oddsTitle.Font, oddsTitle.TextScaled, oddsTitle.TextXAlignment = Enum.Font.GothamBold, true, Enum.TextXAlignment.Left
oddsTitle.TextColor3, oddsTitle.Text = Color3.fromRGB(180, 180, 195), "Chances:"
oddsTitle.Parent = detail
local oddsFrame = Instance.new("Frame")
oddsFrame.Position, oddsFrame.Size, oddsFrame.BackgroundTransparency = UDim2.fromOffset(10, 244), UDim2.new(1, -20, 1, -318), 1
oddsFrame.Parent = detail
do
	local l = Instance.new("UIListLayout")
	l.Padding = UDim.new(0, 3)
	l.Parent = oddsFrame
end

local function eggModel(color: Color3): Model
	local m = Instance.new("Model")
	local p = Instance.new("Part")
	p.Shape, p.Size = Enum.PartType.Ball, Vector3.new(4.2, 5.4, 4.2)
	p.Color, p.Material, p.Anchored, p.CanCollide = color, Enum.Material.SmoothPlastic, true, false
	p.Parent = m
	m.PrimaryPart = p
	return m
end

local detailClean: (() -> ())? = nil
local buying = false
local currentEgg = "Egg1"
local buyBtn: TextButton? = nil

local function doBuyBC(eggId: string)
	if buying then
		return
	end
	buying = true
	local ok, res = pcall(function()
		return ShopBuy:InvokeServer(eggId)
	end)
	buying = false
	if ok and typeof(res) == "table" and res.ok then
		showResult(res.payload)
	else
		local code = if typeof(res) == "table" and res.code then res.code else "Erro"
		if code ~= "RateLimited" and code ~= "Busy" then
			flash(({ NotEnough = "BC insuficiente", GrantFailed = "Falhou — BC devolvido" })[code] or "Erro", Color3.fromRGB(255, 120, 120))
		end
	end
end

local function select(eggId: string)
	local egg = Data.Eggs[eggId]
	if not egg then
		return
	end
	currentEgg = eggId
	local w = Data.Worlds[egg.world]
	local rarityColor = Data.RarityInfo[w.rarity].color
	if detailClean then
		detailClean()
	end
	detailClean = spinModel(vp, cam, eggModel(rarityColor)) -- OVO em display (esconde o brainmon)
	dName.Text = egg.name
	dRarity.Text, dRarity.TextColor3 = w.rarity, rarityColor

	for _, c in oddsFrame:GetChildren() do
		if c:IsA("Frame") then
			c:Destroy()
		end
	end
	local total = 0
	for _, k in Data.MutationOrder do
		total += Data.Mutations[k].weight
	end
	for i, k in Data.MutationOrder do
		local m = Data.Mutations[k]
		local pct = m.weight / total * 100
		local row = Instance.new("Frame")
		row.Size, row.BackgroundTransparency, row.LayoutOrder = UDim2.new(1, 0, 0, 16), 1, i
		row.Parent = oddsFrame
		local sw = Instance.new("Frame")
		sw.Size, sw.Position, sw.BackgroundColor3, sw.BorderSizePixel = UDim2.fromOffset(12, 12), UDim2.fromOffset(0, 2), m.color, 0
		sw.Parent = row
		UIKit.corner(sw, 3)
		local nm = Instance.new("TextLabel")
		nm.BackgroundTransparency, nm.Position, nm.Size = 1, UDim2.fromOffset(18, 0), UDim2.new(1, -90, 1, 0)
		nm.Font, nm.TextScaled, nm.TextXAlignment, nm.TextColor3 = Enum.Font.GothamBold, true, Enum.TextXAlignment.Left, Color3.fromRGB(230, 230, 235)
		nm.Text = m.label
		nm.Parent = row
		local pc = Instance.new("TextLabel")
		pc.BackgroundTransparency, pc.AnchorPoint, pc.Position, pc.Size = 1, Vector2.new(1, 0), UDim2.new(1, 0, 0, 0), UDim2.new(0, 78, 1, 0)
		pc.Font, pc.TextScaled, pc.TextXAlignment, pc.TextColor3 = Enum.Font.GothamBold, true, Enum.TextXAlignment.Right, m.color
		pc.Text = if pct >= 1 then string.format("%.0f%%", pct) else string.format("%.2f%%", pct)
		pc.Parent = row
	end

	if buyBtn then
		buyBtn.Parent:Destroy()
	end
	if egg.price > 0 then
		buyBtn = UIKit.button({ parent = detail, text = "Comprar  $" .. Data.Money(egg.price), color = Color3.fromRGB(80, 200, 95), size = UDim2.new(1, -20, 0, 50), position = UDim2.new(0.5, 0, 1, -12), anchor = Vector2.new(0.5, 1) })
		;(buyBtn :: TextButton).Activated:Connect(function()
			doBuyBC(eggId)
		end)
	else
		buyBtn = UIKit.button({ parent = detail, text = "R$ " .. (if egg.robux > 0 then "comprar" else "em breve"), color = Color3.fromRGB(240, 196, 70), size = UDim2.new(1, -20, 0, 50), position = UDim2.new(0.5, 0, 1, -12), anchor = Vector2.new(0.5, 1), textColor = Color3.fromRGB(40, 34, 20) })
		;(buyBtn :: TextButton).Activated:Connect(function()
			if egg.robux > 0 then
				MarketplaceService:PromptProductPurchase(player, egg.robux)
			else
				flash("Robux em breve", Color3.fromRGB(240, 196, 70))
			end
		end)
	end
end

for i, w in Data.Worlds do
	local egg = Data.Eggs["Egg" .. i]
	if not egg then
		continue
	end
	local rarityColor = Data.RarityInfo[w.rarity].color
	local b = UIKit.button({ parent = eggList, text = "", color = Color3.fromRGB(48, 44, 62), size = UDim2.new(1, 0, 0, 52) })
	b.Text = ""
	local tag = Instance.new("Frame")
	tag.Size, tag.Position, tag.BackgroundColor3, tag.BorderSizePixel = UDim2.new(0, 6, 1, -10), UDim2.fromOffset(4, 5), rarityColor, 0
	tag.Parent = b
	UIKit.corner(tag, 3)
	local nm = Instance.new("TextLabel")
	nm.BackgroundTransparency, nm.Position, nm.Size = 1, UDim2.fromOffset(16, 6), UDim2.new(1, -22, 0, 22)
	nm.Font, nm.TextScaled, nm.TextXAlignment, nm.TextColor3 = Enum.Font.FredokaOne, true, Enum.TextXAlignment.Left, Color3.fromRGB(245, 245, 245)
	UIKit.textOutline(nm)
	nm.Text = w.name
	nm.Parent = b
	local pr = Instance.new("TextLabel")
	pr.BackgroundTransparency, pr.Position, pr.Size = 1, UDim2.fromOffset(16, 28), UDim2.new(1, -22, 0, 18)
	pr.Font, pr.TextScaled, pr.TextXAlignment = Enum.Font.GothamBold, true, Enum.TextXAlignment.Left
	pr.TextColor3 = if egg.price > 0 then Color3.fromRGB(120, 255, 138) else Color3.fromRGB(240, 196, 70)
	pr.Text = if egg.price > 0 then "$" .. Data.Money(egg.price) else "Robux"
	pr.Parent = b
	;(b.Parent :: Frame).LayoutOrder = i
	b.Activated:Connect(function()
		select("Egg" .. i)
	end)
end

-- ====================== ABA OFERTAS ======================
-- Starter Pack (card grandao)
local sp = Instance.new("Frame")
sp.Position, sp.Size = UDim2.fromOffset(12, 0), UDim2.new(1, -24, 0, 150)
sp.BackgroundColor3, sp.BorderSizePixel = Color3.fromRGB(240, 170, 60), 0
sp.Parent = offersView
UIKit.corner(sp, 14)
UIKit.stroke(sp, 4)
UIKit.gradient(sp, Color3.fromRGB(240, 170, 60))
local spTitle = Instance.new("TextLabel")
spTitle.BackgroundTransparency, spTitle.Position, spTitle.Size = 1, UDim2.fromOffset(16, 10), UDim2.new(1, -32, 0, 34)
spTitle.Font, spTitle.TextScaled, spTitle.TextXAlignment, spTitle.TextColor3 = Enum.Font.FredokaOne, true, Enum.TextXAlignment.Left, Color3.fromRGB(255, 255, 255)
UIKit.textOutline(spTitle)
spTitle.Text = "⭐ STARTER PACK"
spTitle.Parent = sp
local spDesc = Instance.new("TextLabel")
spDesc.BackgroundTransparency, spDesc.Position, spDesc.Size = 1, UDim2.fromOffset(16, 48), UDim2.new(1, -32, 0, 56)
spDesc.Font, spDesc.TextScaled, spDesc.TextXAlignment, spDesc.TextYAlignment = Enum.Font.GothamBold, false, Enum.TextXAlignment.Left, Enum.TextYAlignment.Top
spDesc.TextSize, spDesc.TextColor3, spDesc.TextWrapped = 18, Color3.fromRGB(40, 30, 10), true
spDesc.Text = "1 Brainmon Cósmico  •  2 Ovos de Fogo  •  " .. Data.Money(Data.Robux.StarterPack.bc) .. " BC"
spDesc.Parent = sp
local spBuy = UIKit.button({ parent = sp, text = if Data.Robux.StarterPack.product > 0 then "Comprar (Robux)" else "Robux em breve", color = Color3.fromRGB(80, 200, 95), size = UDim2.new(1, -32, 0, 44), position = UDim2.new(0.5, 0, 1, -12), anchor = Vector2.new(0.5, 1) })
spBuy.Activated:Connect(function()
	if Data.Robux.StarterPack.product > 0 then
		MarketplaceService:PromptProductPurchase(player, Data.Robux.StarterPack.product)
	else
		flash("Starter Pack em breve", Color3.fromRGB(240, 196, 70))
	end
end)

-- VIP cards
local function vipCard(cfg: any, y: number)
	local f = Instance.new("Frame")
	f.Position, f.Size = UDim2.fromOffset(12, y), UDim2.new(1, -24, 0, 76)
	f.BackgroundColor3, f.BorderSizePixel = Color3.fromRGB(90, 70, 160), 0
	f.Parent = offersView
	UIKit.corner(f, 12)
	UIKit.stroke(f, 3)
	UIKit.gradient(f, Color3.fromRGB(120, 90, 210))
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency, t.Position, t.Size = 1, UDim2.fromOffset(14, 10), UDim2.new(1, -170, 0, 28)
	t.Font, t.TextScaled, t.TextXAlignment, t.TextColor3 = Enum.Font.FredokaOne, true, Enum.TextXAlignment.Left, Color3.fromRGB(255, 255, 255)
	UIKit.textOutline(t)
	t.Text = "👑 " .. cfg.label
	t.Parent = f
	local d = Instance.new("TextLabel")
	d.BackgroundTransparency, d.Position, d.Size = 1, UDim2.fromOffset(14, 42), UDim2.new(1, -170, 0, 22)
	d.Font, d.TextScaled, d.TextXAlignment, d.TextColor3 = Enum.Font.GothamBold, true, Enum.TextXAlignment.Left, Color3.fromRGB(235, 225, 255)
	d.Text = `+{math.floor(cfg.cashBonus * 100)}% coleta e sorte`
	d.Parent = f
	local buy = UIKit.button({ parent = f, text = "R$ " .. cfg.robux, color = Color3.fromRGB(240, 196, 70), size = UDim2.fromOffset(140, 50), position = UDim2.new(1, -12, 0.5, 0), anchor = Vector2.new(1, 0.5), textColor = Color3.fromRGB(40, 34, 20) })
	buy.Activated:Connect(function()
		if cfg.pass > 0 then
			MarketplaceService:PromptGamePassPurchase(player, cfg.pass)
		else
			flash(cfg.label .. " em breve", Color3.fromRGB(240, 196, 70))
		end
	end)
end
vipCard(Data.Robux.Vip, 162)
vipCard(Data.Robux.VipUnlimited, 246)

-- ====================== abrir/fechar ======================
local hud = playerGui:WaitForChild("BrainHud")
local menuClick = hud:WaitForChild("MenuClick") :: BindableEvent
menuClick.Event:Connect(function(name: string)
	if name ~= "SHOP" then
		return
	end
	gui.Enabled = not gui.Enabled
	if gui.Enabled then
		showTab(true)
		select(currentEgg)
	elseif detailClean then
		detailClean()
		detailClean = nil
	end
end)
