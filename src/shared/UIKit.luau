--!strict
-- UIKit: kit de UI "chunky" no estilo da referencia (contorno preto grosso + gradiente + cantos redondos + texto com contorno).
-- So construcao de GUI; usado pelos *Client. Sem textura por ora (placeholder); trocar por rbxassetid quando os assets subirem.
-- Nota Roblox: UIStroke em TextButton/TextLabel contorna o TEXTO, nao a borda. Por isso o botao e um Frame (borda) + TextButton transparente dentro.
local UIKit = {}

local BLACK = Color3.fromRGB(18, 18, 22)
UIKit.Black = BLACK

function UIKit.corner(inst: Instance, r: number): UICorner
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r)
	c.Parent = inst
	return c
end

-- borda preta (so em Frame/ImageLabel; em texto o UIStroke iria no texto)
function UIKit.stroke(inst: Instance, thickness: number, color: Color3?): UIStroke
	local s = Instance.new("UIStroke")
	s.Thickness = thickness
	s.Color = color or BLACK
	s.Parent = inst
	return s
end

local function shade(c: Color3, f: number): Color3
	return Color3.new(math.clamp(c.R * f, 0, 1), math.clamp(c.G * f, 0, 1), math.clamp(c.B * f, 0, 1))
end
UIKit.shade = shade

-- gradiente vertical claro->escuro a partir de uma cor base
function UIKit.gradient(inst: Instance, base: Color3, light: number?, dark: number?): UIGradient
	local g = Instance.new("UIGradient")
	g.Color = ColorSequence.new(shade(base, light or 1.28), shade(base, dark or 0.76))
	g.Rotation = 90
	g.Parent = inst
	return g
end

-- aplica contorno preto ao TEXTO (built-in, pra nao brigar com a borda do Frame)
local function textOutline(t: TextLabel | TextButton)
	t.TextStrokeColor3 = BLACK
	t.TextStrokeTransparency = 0
end
UIKit.textOutline = textOutline

export type ButtonOpts = {
	parent: Instance,
	text: string,
	color: Color3,
	size: UDim2,
	position: UDim2?,
	anchor: Vector2?,
	textColor: Color3?,
	corner: number?,
}

-- Botao chunky. Retorna o TextButton (conecte .Activated). Posicao/ancora/size vao no Frame externo.
function UIKit.button(opts: ButtonOpts): TextButton
	local wrap = Instance.new("Frame")
	wrap.Size = opts.size
	if opts.position then
		wrap.Position = opts.position
	end
	if opts.anchor then
		wrap.AnchorPoint = opts.anchor
	end
	wrap.BackgroundColor3 = opts.color
	wrap.BorderSizePixel = 0
	wrap.Parent = opts.parent
	UIKit.corner(wrap, opts.corner or 10)
	UIKit.stroke(wrap, 3)
	UIKit.gradient(wrap, opts.color)

	local b = Instance.new("TextButton")
	b.BackgroundTransparency = 1
	b.Size = UDim2.fromScale(1, 1)
	b.Text = opts.text
	b.Font = Enum.Font.FredokaOne
	b.TextScaled = true
	b.TextColor3 = opts.textColor or Color3.fromRGB(255, 255, 255)
	textOutline(b)
	b.Parent = wrap
	local p = Instance.new("UIPadding")
	p.PaddingLeft = UDim.new(0, 8)
	p.PaddingRight = UDim.new(0, 8)
	p.PaddingTop = UDim.new(0, 5)
	p.PaddingBottom = UDim.new(0, 5)
	p.Parent = b
	return b
end

export type Panel = { root: Frame, content: Frame, close: TextButton, header: Frame }

-- Janela padrao: borda preta + header com gradiente (accent) + icone + titulo + X vermelho. content = area util abaixo.
function UIKit.panel(opts: { parent: Instance, size: UDim2, title: string, accent: Color3, contentColor: Color3?, icon: string? }): Panel
	local root = Instance.new("Frame")
	root.AnchorPoint = Vector2.new(0.5, 0.5)
	root.Position = UDim2.fromScale(0.5, 0.5)
	root.Size = opts.size
	root.BackgroundColor3 = opts.contentColor or Color3.fromRGB(32, 38, 54)
	root.BorderSizePixel = 0
	root.Parent = opts.parent
	UIKit.corner(root, 16)
	UIKit.stroke(root, 4)

	local header = Instance.new("Frame")
	header.Size = UDim2.new(1, 0, 0, 52)
	header.BackgroundColor3 = opts.accent
	header.BorderSizePixel = 0
	header.ZIndex = 2
	header.Parent = root
	UIKit.corner(header, 16)
	UIKit.stroke(header, 4)
	UIKit.gradient(header, opts.accent)
	-- tapa o arredondado de baixo do header (cola no corpo)
	local skirt = Instance.new("Frame")
	skirt.Size = UDim2.new(1, 0, 0, 18)
	skirt.Position = UDim2.new(0, 0, 1, -18)
	skirt.BackgroundColor3 = shade(opts.accent, 0.9)
	skirt.BorderSizePixel = 0
	skirt.ZIndex = 1
	skirt.Parent = header

	local titleX = 18
	if opts.icon then
		local box = Instance.new("Frame")
		box.Size = UDim2.fromOffset(38, 38)
		box.Position = UDim2.fromOffset(9, 7)
		box.BackgroundColor3 = shade(opts.accent, 0.68)
		box.BorderSizePixel = 0
		box.ZIndex = 3
		box.Parent = header
		UIKit.corner(box, 9)
		UIKit.stroke(box, 3)
		local ic = Instance.new("TextLabel")
		ic.BackgroundTransparency = 1
		ic.Size = UDim2.fromScale(1, 1)
		ic.Font = Enum.Font.FredokaOne
		ic.TextScaled = true
		ic.Text = opts.icon
		ic.TextColor3 = Color3.fromRGB(255, 255, 255)
		ic.ZIndex = 4
		textOutline(ic)
		ic.Parent = box
		titleX = 56
	end

	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Position = UDim2.fromOffset(titleX, 0)
	title.Size = UDim2.new(1, -titleX - 58, 1, 0)
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.Text = opts.title
	title.ZIndex = 3
	textOutline(title)
	title.Parent = header
	local tp = Instance.new("UIPadding")
	tp.PaddingTop = UDim.new(0, 10)
	tp.PaddingBottom = UDim.new(0, 10)
	tp.Parent = title

	local close = UIKit.button({
		parent = header,
		text = "X",
		color = Color3.fromRGB(220, 60, 70),
		size = UDim2.fromOffset(38, 38),
		position = UDim2.new(1, -10, 0.5, 0),
		anchor = Vector2.new(1, 0.5),
	})
	close.Parent.ZIndex = 3

	local content = Instance.new("Frame")
	content.Position = UDim2.fromOffset(0, 52)
	content.Size = UDim2.new(1, 0, 1, -52)
	content.BackgroundTransparency = 1
	content.Parent = root

	return { root = root, content = content, close = close, header = header }
end

return UIKit
