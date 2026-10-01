--!strict
-- HudClient: HUD principal. BrainCoins no canto superior direito (formatado) + cluster de botoes a esquerda.
-- Os paineis (Shop/Rebirth/Braindex/Battle/Trade/Inventory) ainda nao existem: por ora o clique mostra um aviso.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Data = require(ReplicatedStorage:WaitForChild("BrainmonData"))
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "BrainHud"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.IgnoreGuiInset = false
gui.Parent = playerGui

-- Canal simples pros paineis (ShopClient etc.) abrirem ao clicar no botao do menu.
local menuClick = Instance.new("BindableEvent")
menuClick.Name = "MenuClick"
menuClick.Parent = gui
local IMPLEMENTED: { [string]: boolean } = { SHOP = true, BRAINDEX = true, REBIRTH = true } -- demais botoes caem no toast "em breve"

-- ---------------------------------------------------------------- BrainCoins (topo-direito)
local bcFrame = Instance.new("Frame")
bcFrame.Name = "BrainCoins"
bcFrame.AnchorPoint = Vector2.new(1, 0)
bcFrame.Position = UDim2.new(1, -16, 0, 12)
bcFrame.Size = UDim2.fromOffset(190, 52)
bcFrame.BackgroundColor3 = Color3.fromRGB(24, 26, 34)
bcFrame.BackgroundTransparency = 0.1
bcFrame.BorderSizePixel = 0
bcFrame.Parent = gui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = bcFrame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(120, 255, 138)
	stroke.Thickness = 1.5
	stroke.Transparency = 0.3
	stroke.Parent = bcFrame
end
local bcLabel = Instance.new("TextLabel")
bcLabel.Name = "Value"
bcLabel.BackgroundTransparency = 1
bcLabel.Size = UDim2.fromScale(1, 1)
bcLabel.Font = Enum.Font.FredokaOne
bcLabel.TextScaled = true
bcLabel.TextColor3 = Color3.fromRGB(120, 255, 138)
bcLabel.TextStrokeTransparency = 0.5
bcLabel.Text = "$0"
bcLabel.Parent = bcFrame
do
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 12)
	pad.PaddingRight = UDim.new(0, 12)
	pad.PaddingTop = UDim.new(0, 8)
	pad.PaddingBottom = UDim.new(0, 8)
	pad.Parent = bcLabel
end

local function refreshBC()
	local bc = (player:GetAttribute("BC") :: number?) or 0
	bcLabel.Text = "$" .. Data.Money(bc)
end
player:GetAttributeChangedSignal("BC"):Connect(refreshBC)
refreshBC()

-- ---------------------------------------------------------------- toast
local toast = Instance.new("TextLabel")
toast.Name = "Toast"
toast.AnchorPoint = Vector2.new(0.5, 1)
toast.Position = UDim2.new(0.5, 0, 1, -120)
toast.Size = UDim2.fromOffset(320, 46)
toast.BackgroundColor3 = Color3.fromRGB(20, 22, 30)
toast.BackgroundTransparency = 1
toast.TextTransparency = 1
toast.Font = Enum.Font.GothamBold
toast.TextScaled = true
toast.TextColor3 = Color3.fromRGB(245, 245, 245)
toast.Text = ""
toast.Parent = gui
do
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, 10)
	c.Parent = toast
end
local function showToast(text: string)
	toast.Text = text
	toast.BackgroundTransparency = 0.15
	toast.TextTransparency = 0
	local t = TweenService:Create(toast, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { BackgroundTransparency = 1, TextTransparency = 1 })
	task.delay(1.1, function()
		t:Play()
	end)
end

-- ---------------------------------------------------------------- cluster de botoes (esquerda)
local menu = Instance.new("Frame")
menu.Name = "Menu"
menu.AnchorPoint = Vector2.new(0, 0.5)
menu.Position = UDim2.new(0, 14, 0.5, 0)
menu.Size = UDim2.fromOffset(72, 6 * 68)
menu.BackgroundTransparency = 1
menu.Parent = gui
do
	local layout = Instance.new("UIListLayout")
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.Padding = UDim.new(0, 10)
	layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder -- respeita a ordem do mockup (nao alfabetica)
	layout.Parent = menu
end

local buttons = {
	{ name = "SHOP", color = Color3.fromRGB(150, 70, 180) },
	{ name = "REBIRTH", color = Color3.fromRGB(150, 40, 55) },
	{ name = "BRAINDEX", color = Color3.fromRGB(55, 75, 200) },
	{ name = "BATTLE", color = Color3.fromRGB(110, 190, 230) },
	{ name = "TRADE", color = Color3.fromRGB(60, 170, 90) },
	{ name = "INVENTORY", color = Color3.fromRGB(180, 120, 70) },
}

-- Icones do HUD (btn_*.png em assets/hud/). Preencher com os rbxassetid apos importar no Studio;
-- vazio = cai no quadrado colorido (fallback). Ex.: SHOP = "rbxassetid://123456789".
local ICONS: { [string]: string } = {
	SHOP = "",
	REBIRTH = "",
	BRAINDEX = "",
	BATTLE = "",
	TRADE = "",
	INVENTORY = "",
}

for i, b in buttons do
	local holder = Instance.new("Frame")
	holder.Name = b.name
	holder.Size = UDim2.fromOffset(72, 58)
	holder.BackgroundTransparency = 1
	holder.LayoutOrder = i
	holder.Parent = menu

	local btn = Instance.new("ImageButton")
	btn.Size = UDim2.fromOffset(56, 56)
	btn.Position = UDim2.new(0.5, 0, 0, 0)
	btn.AnchorPoint = Vector2.new(0.5, 0)
	btn.BorderSizePixel = 0
	btn.AutoButtonColor = true
	btn.Parent = holder
	local id = ICONS[b.name]
	if id ~= "" then
		btn.Image = id -- o PNG ja tem o fundo colorido arredondado
		btn.BackgroundTransparency = 1
	else
		btn.Image = ""
		btn.BackgroundColor3 = b.color
		local c = Instance.new("UICorner")
		c.CornerRadius = UDim.new(0, 12)
		c.Parent = btn
		local stroke = Instance.new("UIStroke")
		stroke.Color = Color3.fromRGB(255, 255, 255)
		stroke.Thickness = 2
		stroke.Transparency = 0.4
		stroke.Parent = btn
	end

	local caption = Instance.new("TextLabel")
	caption.BackgroundTransparency = 1
	caption.Position = UDim2.new(0.5, 0, 1, -12)
	caption.AnchorPoint = Vector2.new(0.5, 0)
	caption.Size = UDim2.fromOffset(72, 12)
	caption.Font = Enum.Font.GothamBold
	caption.TextScaled = true
	caption.TextColor3 = Color3.fromRGB(245, 245, 245)
	caption.TextStrokeTransparency = 0
	caption.Text = b.name
	caption.Parent = holder

	btn.Activated:Connect(function()
		if IMPLEMENTED[b.name] then
			menuClick:Fire(b.name)
		else
			showToast(b.name:sub(1, 1) .. b.name:sub(2):lower() .. " — em breve")
		end
	end)
end
