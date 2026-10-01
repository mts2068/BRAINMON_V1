--!strict
-- BiomeBuilder: gera TODO o mapa no boot (hub central + 8 mundos) em Workspace.Map. Nada e salvo a mao:
-- a pasta e destruida e recriada a cada boot (guia 7.2). SpawnLocation/zonas nascem daqui.
-- Layout (imagem de referencia): rio ao centro (N-S) com calcadas, 2 colunas x 4 linhas de mundos, praca com cristal no meio.
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")

local Data = require(game:GetService("ReplicatedStorage"):WaitForChild("BrainmonData"))
local L = Data.Layout

local B = {}

export type WorldInfo = {
	folder: Folder,
	origin: Vector3,
	spawn: CFrame, -- onde o jogador aparece ao entrar
	zone: { center: Vector3, size: Vector3 }, -- area onde os selvagens podem andar
	gatePos: Vector3,
}
export type Map = { folder: Folder, hubSpawn: CFrame, worlds: { WorldInfo } }

local M = Enum.Material

local function P(parent: Instance, name: string, size: Vector3, cf: CFrame, color: Color3, mat: Enum.Material?, o: { [string]: any }?): Part
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or M.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CanTouch = false
	p.CastShadow = false
	if o then
		for k, v in o do
			(p :: any)[k] = v
		end
	end
	p.Parent = parent
	return p
end

local BALL = { Shape = Enum.PartType.Ball }
local function disc(parent: Instance, name: string, diameter: number, thick: number, pos: Vector3, color: Color3, mat: Enum.Material, o: { [string]: any }?)
	-- cilindro "deitado": eixo X vira eixo Y com giro de 90 graus em Z
	local opts: { [string]: any } = { Shape = Enum.PartType.Cylinder }
	if o then
		for k, v in o do
			opts[k] = v
		end
	end
	return P(parent, name, Vector3.new(thick, diameter, diameter), CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), color, mat, opts)
end

local function weighted(list: { any }, rng: Random)
	local total = 0
	for _, d in list do
		total += d.w
	end
	local r = rng:NextNumber() * total
	for _, d in list do
		r -= d.w
		if r <= 0 then
			return d
		end
	end
	return list[#list]
end

-- Arvore de mesh (Mesh_AlpTrees4) = UNICA arvore do mapa. Move 1 pra ServerStorage como template e apaga o cluster do meio.
local function getTreeTemplate(): Model?
	local t = ServerStorage:FindFirstChild("TreeTemplate")
	if t and t:IsA("Model") then
		return t
	end
	local first: Model? = nil
	for _, c in Workspace:GetChildren() do
		if c:IsA("Model") and string.find(c.Name, "AlpTrees") then
			if not first then
				first = c
			else
				c:Destroy() -- remove o cluster original do meio
			end
		end
	end
	if first then
		first.Name = "TreeTemplate"
		first.Parent = ServerStorage
		return first
	end
	return nil
end

-- Clona a arvore no chao em `pos` com escala/giro aleatorios. Retorna true se colocou.
local function placeTree(parent: Instance, pos: Vector3, rng: Random, sMin: number, sMax: number, collide: boolean): boolean
	local tpl = getTreeTemplate()
	if not tpl then
		return false
	end
	local tree = tpl:Clone()
	tree:ScaleTo(rng:NextNumber(sMin, sMax))
	tree:PivotTo(CFrame.new(pos.X, 0, pos.Z) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0))
	local bcf, bsize = tree:GetBoundingBox()
	tree:PivotTo(CFrame.new(0, -(bcf.Position.Y - bsize.Y / 2), 0) * tree:GetPivot())
	for _, dsc in tree:GetDescendants() do
		if dsc:IsA("BasePart") then
			dsc.Anchored = true
			dsc.CanCollide = collide
		end
	end
	tree.Parent = parent
	return true
end

-- Grama alta do bioma: moitas de laminas finas espalhadas pelo chao (nao colidem). Evita o marco e o corredor do portao.
local function scatterGrass(parent: Instance, origin: Vector3, half: number, sgn: number, color: Color3, rng: Random)
	local inset = half - 14
	for _ = 1, 150 do
		local rx, rz = rng:NextNumber(-inset, inset), rng:NextNumber(-inset, inset)
		if math.sqrt(rx * rx + rz * rz) > 54 and not (math.abs(rz) < 22 and rx * sgn < -(half - 52)) then
			local base = origin + Vector3.new(rx, 0, rz)
			for _ = 1, rng:NextInteger(3, 4) do
				local h = rng:NextNumber(3.5, 6.5)
				local bp = base + Vector3.new(rng:NextNumber(-1.5, 1.5), 0, rng:NextNumber(-1.5, 1.5))
				P(parent, "Grass", Vector3.new(0.3, h, 0.3), CFrame.new(bp + Vector3.new(0, h / 2, 0)) * CFrame.Angles(rng:NextNumber(-0.22, 0.22), rng:NextNumber(0, 6.28), rng:NextNumber(-0.22, 0.22)), color, M.Grass, { CanCollide = false })
			end
		end
	end
end

-- ---------------------------------------------------------------- decoracao (kind -> construtor)
-- pos = ponto no chao (y = 0). Todas as pecas ficam em `parent`.
type Deco = (parent: Instance, pos: Vector3, rng: Random, d: any, neon: boolean) -> ()
local Decos: { [string]: Deco } = {}

Decos.tree = function(parent, pos, rng, d, _)
	-- arvore de mesh (menor que a floresta de fundo); nao colide pra nao prender o jogador no mundo
	if placeTree(parent, pos, rng, 0.28, 0.5, false) then
		return
	end
	-- fallback blocky (so se o template sumir)
	local h = if d.dead then rng:NextNumber(6, 9) else rng:NextNumber(8, 14)
	P(parent, "Trunk", Vector3.new(1.6, h, 1.6), CFrame.new(pos + Vector3.new(0, h / 2, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6.28), 0), d.a, M.Wood)
	local r = rng:NextNumber(8, 13)
	P(parent, "Leaves", Vector3.new(r, r * 0.8, r), CFrame.new(pos + Vector3.new(0, h + r * 0.25, 0)), d.b, M.Grass, BALL)
end

Decos.stack = function(parent, pos, rng, d, neon)
	local y, w = 0, rng:NextNumber(4.5, 6)
	local yaw = rng:NextNumber(0, 6.28)
	for i = 1, rng:NextInteger(3, 4) do
		local lastNeon = neon and i % 2 == 0
		P(parent, "Block", Vector3.new(w, 3, w), CFrame.new(pos + Vector3.new(0, y + 1.5, 0)) * CFrame.Angles(0, yaw + i * 0.35, 0), if i % 2 == 0 then d.b else d.a, if lastNeon then M.Neon else M.Slate)
		y += 3
		w *= 0.82
	end
end

Decos.pillar = function(parent, pos, rng, d, _)
	local h = rng:NextNumber(8, 16)
	P(parent, "Pillar", Vector3.new(3, h, 3), CFrame.new(pos + Vector3.new(0, h / 2, 0)), d.a, M.Slate)
	P(parent, "Cap", Vector3.new(4.2, 1, 4.2), CFrame.new(pos + Vector3.new(0, h + 0.5, 0)), d.a:Lerp(Color3.new(1, 1, 1), 0.15), M.Slate)
end

Decos.mound = function(parent, pos, rng, d, _)
	local w, h = rng:NextNumber(9, 17), rng:NextNumber(3, 6)
	P(parent, "Mound", Vector3.new(w, h, w), CFrame.new(pos + Vector3.new(0, h * 0.15, 0)), d.a, M.Grass, { Shape = Enum.PartType.Ball, CanCollide = false })
end

Decos.crystal = function(parent, pos, rng, d, _)
	for i = 1, rng:NextInteger(1, 3) do
		local h = rng:NextNumber(4, 10)
		local off = Vector3.new(rng:NextNumber(-1.5, 1.5), 0, rng:NextNumber(-1.5, 1.5))
		P(parent, "Crystal", Vector3.new(1.6, h, 1.6), CFrame.new(pos + off + Vector3.new(0, h / 2 - 0.5, 0)) * CFrame.Angles(rng:NextNumber(-0.4, 0.4), rng:NextNumber(0, 6.28), rng:NextNumber(-0.4, 0.4)), d.a, M.Glass, { Transparency = 0.12 })
	end
end

Decos.pool = function(parent, pos, rng, d, _)
	local dia = rng:NextNumber(7, 15)
	disc(parent, "Pool", dia, 0.3, pos + Vector3.new(0, 0.18, 0), d.a, M.Neon, { Transparency = 0.2, CanCollide = false })
end

Decos.lamp = function(parent, pos, rng, d, _)
	local h = rng:NextNumber(7, 12)
	P(parent, "LampBase", Vector3.new(2, 1, 2), CFrame.new(pos + Vector3.new(0, 0.5, 0)), Color3.fromRGB(30, 30, 40), M.Metal)
	P(parent, "LampBar", Vector3.new(0.7, h, 0.7), CFrame.new(pos + Vector3.new(0, h / 2 + 1, 0)), d.a, M.Neon)
end

-- ---------------------------------------------------------------- marcos (landmarks)
local Landmarks = {}

function Landmarks.tiers(parent: Instance, origin: Vector3, lm: any)
	local y = 0
	local last = 0
	for _, layer in lm.layers do
		local w, h, col = layer[1], layer[2], layer[3]
		P(parent, "Tier", Vector3.new(w, h, w), CFrame.new(origin + Vector3.new(0, y + h / 2, 0)), col, M.Slate, { CastShadow = true })
		y += h
		last = w
	end
	local orb = P(parent, "Beacon", Vector3.new(last * 0.45, last * 0.45, last * 0.45), CFrame.new(origin + Vector3.new(0, y + last * 0.25, 0)), lm.top, M.Neon, BALL)
	local light = Instance.new("PointLight")
	light.Color = lm.top
	light.Range = 48
	light.Brightness = 2
	light.Parent = orb
end

function Landmarks.towers(parent: Instance, origin: Vector3, lm: any)
	local spec = { { -32, -22, 120 }, { 30, -26, 90 }, { 2, 8, 150 }, { -26, 30, 80 }, { 34, 28, 104 } }
	local tallest = { x = 0, z = 0, h = 0 }
	for _, t in spec do
		local x, z, h = t[1], t[2], t[3]
		local pos = origin + Vector3.new(x, h / 2, z)
		P(parent, "Tower", Vector3.new(18, h, 18), CFrame.new(pos), lm.base, M.Metal, { CastShadow = true })
		for k = 1, 3 do
			P(parent, "Band", Vector3.new(18.6, 1, 18.6), CFrame.new(origin + Vector3.new(x, h * k / 4, z)), lm.neon, M.Neon)
		end
		if h > tallest.h then
			tallest = { x = x, z = z, h = h }
		end
	end
	local orb = P(parent, "Orb", Vector3.new(30, 30, 30), CFrame.new(origin + Vector3.new(tallest.x, tallest.h + 30, tallest.z)), lm.top, M.Neon, BALL)
	local light = Instance.new("PointLight")
	light.Color = lm.neon
	light.Range = 60
	light.Brightness = 3
	light.Parent = orb
end

function Landmarks.ring(parent: Instance, origin: Vector3, lm: any)
	disc(parent, "ArenaFloor", 84, 0.4, origin + Vector3.new(0, 0.2, 0), lm.sand, M.Sand)
	for k = 1, 8 do -- rachaduras
		local a = k * 0.78
		P(parent, "Crack", Vector3.new(0.5, 0.1, 30), CFrame.new(origin + Vector3.new(math.cos(a) * 14, 0.45, math.sin(a) * 14)) * CFrame.Angles(0, a, 0), Color3.fromRGB(70, 56, 40), M.Slate, { CanCollide = false })
	end
	local half = 52
	for _, s in { { 0, -half, 112, 8 }, { 0, half, 112, 8 }, { -half, 0, 8, 112 }, { half, 0, 8, 112 } } do
		for step = 1, 3 do
			local grow = step * 7
			local sz = if s[3] > s[4] then Vector3.new(s[3] + step * 8, step * 6, s[4]) else Vector3.new(s[3], step * 6, s[4] + step * 8)
			local off = Vector3.new(s[1] + math.sign(s[1]) * grow, step * 3, s[2] + math.sign(s[2]) * grow)
			P(parent, "Stand", sz, CFrame.new(origin + off), lm.wall, M.Slate, { CastShadow = true })
		end
		P(parent, "Trim", Vector3.new(math.max(s[3], 1), 0.8, math.max(s[4], 1)), CFrame.new(origin + Vector3.new(s[1] * 1.0, 1.5, s[2] * 1.0)), lm.trim, M.Neon)
	end
	for _, c in { { -66, -66 }, { 66, -66 }, { -66, 66 }, { 66, 66 } } do
		P(parent, "Light", Vector3.new(6, 36, 6), CFrame.new(origin + Vector3.new(c[1], 18, c[2])), lm.wall, M.Metal, { CastShadow = true })
		P(parent, "Lamp", Vector3.new(8, 4, 8), CFrame.new(origin + Vector3.new(c[1], 38, c[2])), Color3.fromRGB(255, 240, 220), M.Neon)
	end
end

-- ---------------------------------------------------------------- mundo
local function buildWorld(i: number, parent: Folder): WorldInfo
	local w = Data.Worlds[i]
	local st = w.style
	local origin = Data.OriginOf(i)
	local sgn = if w.col == 1 then -1 else 1
	local folder = Instance.new("Folder")
	folder.Name = `World_{i}_{w.id}`
	folder:SetAttribute("Index", i)
	folder.Parent = parent
	local half = L.Plot / 2
	local neonWorld = w.id == "NeonPark"

	-- chao quadriculado (tiles de 20 st; nunca preto/branco puro)
	local tiles = Instance.new("Folder")
	tiles.Name = "Floor"
	tiles.Parent = folder
	local n = L.Plot / 20
	for ix = 0, n - 1 do
		for iz = 0, n - 1 do
			P(tiles, "Tile", Vector3.new(20, 1, 20), CFrame.new(origin + Vector3.new(-half + 10 + ix * 20, -0.5, -half + 10 + iz * 20)), st.floor[(ix + iz) % 2 + 1], st.floorMat)
		end
	end

	-- cerca: 3 lados continuos + lado do rio com vao de GateGap (portao)
	local fences = Instance.new("Folder")
	fences.Name = "Fence"
	fences.Parent = folder
	local gap = L.GateGap
	local fx = sgn * (L.River / 2 + L.Walk) + sgn * 0.75 -- x da cerca voltada ao rio
	local pieceLen = (L.Plot - gap) / 2
	for _, dz in { -1, 1 } do
		P(fences, "Wall", Vector3.new(1.5, 6, pieceLen), CFrame.new(fx, 3, origin.Z + dz * (gap / 2 + pieceLen / 2)), st.fence, st.fenceMat, { CastShadow = true })
	end
	local outerX = origin.X + sgn * half
	P(fences, "Wall", Vector3.new(1.5, 6, L.Plot), CFrame.new(outerX, 3, origin.Z), st.fence, st.fenceMat)
	for _, dz in { -1, 1 } do
		P(fences, "Wall", Vector3.new(L.Plot, 6, 1.5), CFrame.new(origin.X, 3, origin.Z + dz * half), st.fence, st.fenceMat)
	end
	for k = 0, 12 do -- postes a cada 20 st nos lados continuos
		local t = -half + k * 20 + 10
		P(fences, "Post", Vector3.new(2.6, 8, 2.6), CFrame.new(outerX, 4, origin.Z + t), st.fence, st.fenceMat)
		P(fences, "Post", Vector3.new(2.6, 8, 2.6), CFrame.new(origin.X + t, 4, origin.Z - half), st.fence, st.fenceMat)
		P(fences, "Post", Vector3.new(2.6, 8, 2.6), CFrame.new(origin.X + t, 4, origin.Z + half), st.fence, st.fenceMat)
	end

	-- portao (Gate House): pilares + dintel + porta solida (a passagem e por teleporte validado no servidor)
	local gate = Instance.new("Folder")
	gate.Name = "Gate"
	gate.Parent = folder
	for _, dz in { -1, 1 } do
		P(gate, "Pillar", Vector3.new(4, 16, 4), CFrame.new(fx, 8, origin.Z + dz * (gap / 2 + 2)), st.fence:Lerp(Color3.new(1, 1, 1), 0.2), M.Slate, { CastShadow = true })
	end
	local lintel = P(gate, "Lintel", Vector3.new(4, 3, gap + 8), CFrame.new(fx, 16.5, origin.Z), st.fence:Lerp(Color3.new(1, 1, 1), 0.2), M.Slate)
	P(gate, "Door", Vector3.new(1, 13, gap), CFrame.new(fx, 6.5, origin.Z), st.accent, M.Neon, { Transparency = 0.45 })
	local sign = Instance.new("BillboardGui")
	sign.Name = "GateSign"
	sign.Adornee = lintel
	sign.Size = UDim2.fromOffset(340, 76)
	sign.StudsOffset = Vector3.new(0, 5, 0)
	sign.MaxDistance = 140
	sign.ResetOnSpawn = false
	sign.Parent = lintel
	local title = Instance.new("TextLabel")
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 0.58)
	title.Font = Enum.Font.GothamBold
	title.TextScaled = true
	title.TextColor3 = Color3.fromRGB(242, 242, 242)
	title.TextStrokeColor3 = Color3.new(0, 0, 0)
	title.TextStrokeTransparency = 0
	title.Text = w.name
	title.Parent = sign
	local req = title:Clone()
	req.Position = UDim2.fromScale(0, 0.6)
	req.Size = UDim2.fromScale(1, 0.38)
	req.TextColor3 = Color3.fromRGB(255, 201, 51)
	req.Text = if i == 1 then "ENTRADA LIVRE" else `{w.gate.species} BRAINMONS · {w.gate.bc} BC`
	req.Parent = sign

	local function pad(name: string, x: number, kind: string, action: string)
		local p = P(gate, name, Vector3.new(6, 0.4, 8), CFrame.new(x, 0.2, origin.Z), st.accent, M.Neon, { Transparency = 0.4 })
		p:SetAttribute("World", i)
		p:SetAttribute("Kind", kind)
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = action
		pp.ObjectText = w.name
		pp.HoldDuration = 0.3
		pp.MaxActivationDistance = 10
		pp.RequiresLineOfSight = false
		pp.Parent = p
	end
	pad("EnterPad", sgn * (L.River / 2 + L.Walk / 2 + 4), "Enter", "Entrar")
	pad("ExitPad", sgn * (L.River / 2 + L.Walk + 10), "Exit", "Voltar ao Hub")

	-- marco central
	local lmFolder = Instance.new("Folder")
	lmFolder.Name = "Landmark"
	lmFolder.Parent = folder
	;(Landmarks :: any)[st.landmark.kind](lmFolder, origin, st.landmark)

	-- decoracao: ~62% agrupada perto do item anterior (evita cara de campo de golfe); respeita marco e corredor do portao
	local decoF = Instance.new("Folder")
	decoF.Name = "Decor"
	decoF.Parent = folder
	local rng = Random.new(7000 + i)
	local prev: Vector3? = nil
	local inset = half - 16
	local placed = 0
	for _ = 1, 170 do
		local d = weighted(st.deco, rng)
		local pos: Vector3
		if prev and rng:NextNumber() < 0.62 then
			pos = prev + Vector3.new(rng:NextNumber(-22, 22), 0, rng:NextNumber(-22, 22))
		else
			pos = origin + Vector3.new(rng:NextNumber(-inset, inset), 0, rng:NextNumber(-inset, inset))
		end
		local rel = pos - origin
		local inBounds = math.abs(rel.X) < inset and math.abs(rel.Z) < inset
		local nearLandmark = rel.Magnitude < 58
		local nearGate = math.abs(rel.Z) < 22 and (rel.X * sgn) < -(half - 52)
		if inBounds and not nearLandmark and not nearGate then
			Decos[d.k](decoF, Vector3.new(pos.X, 0, pos.Z), rng, d, neonWorld and d.k ~= "mound")
			prev = pos
			placed += 1
		end
	end

	-- grama alta do bioma (cor do chao puxada pro verde pra combinar com cada mundo)
	local grassF = Instance.new("Folder")
	grassF.Name = "Grass"
	grassF.Parent = folder
	scatterGrass(grassF, origin, half, sgn, st.floor[1]:Lerp(Color3.fromRGB(74, 120, 60), 0.5), rng)

	-- barreira de energia (caixa OCA de vidro fosco, cor do mundo): bloqueia entrar a pe;
	-- so se entra pelo portal (teleporte validado) ou pelo seletor M. Mundo aberto por dentro (quem teleporta nao fica preso).
	do
		local S, H, t = L.Plot, 150, 2
		local half = S / 2
		local function wall(name: string, size: Vector3, off: Vector3)
			P(folder, name, size, CFrame.new(origin + off), st.accent, Enum.Material.Glass, { CanCollide = true, CastShadow = false, Transparency = 0.4 })
		end
		wall("Dome", Vector3.new(t, H, S), Vector3.new(half, H / 2, 0))
		wall("Dome", Vector3.new(t, H, S), Vector3.new(-half, H / 2, 0))
		wall("Dome", Vector3.new(S, H, t), Vector3.new(0, H / 2, half))
		wall("Dome", Vector3.new(S, H, t), Vector3.new(0, H / 2, -half))
		wall("DomeTop", Vector3.new(S, t, S), Vector3.new(0, H, 0))
	end

	local spawnPos = Vector3.new(sgn * (L.River / 2 + L.Walk + 34), 3, origin.Z)
	return {
		folder = folder,
		origin = origin,
		spawn = CFrame.lookAt(spawnPos, Vector3.new(origin.X, 3, origin.Z)),
		zone = { center = Vector3.new(origin.X, 0, origin.Z), size = Vector3.new(L.Plot - 48, 0, L.Plot - 48) },
		gatePos = Vector3.new(fx, 0, origin.Z),
	}
end

-- ---------------------------------------------------------------- hub (town) + rio
local function lamp(parent: Instance, pos: Vector3)
	P(parent, "LampPole", Vector3.new(0.6, 9, 0.6), CFrame.new(pos + Vector3.new(0, 4.5, 0)), Color3.fromRGB(44, 46, 54), M.Metal)
	local bulb = P(parent, "Bulb", Vector3.new(1.8, 1.8, 1.8), CFrame.new(pos + Vector3.new(0, 9.5, 0)), Color3.fromRGB(255, 205, 130), M.Neon, BALL)
	local pl = Instance.new("PointLight")
	pl.Color = Color3.fromRGB(255, 195, 120)
	pl.Range = 34
	pl.Brightness = 1.6
	pl.Parent = bulb
end

-- rotulo flutuante simples (pequeno, encostado no topo da estrutura)
local function townLabel(adornee: BasePart, text: string, color: Color3, offY: number)
	local gui = Instance.new("BillboardGui")
	gui.Adornee = adornee
	gui.Size = UDim2.fromOffset(150, 24)
	gui.StudsOffset = Vector3.new(0, offY, 0)
	gui.MaxDistance = 220
	gui.Parent = adornee
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.fromScale(1, 1)
	t.Font = Enum.Font.FredokaOne
	t.TextScaled = true
	t.TextColor3 = color
	t.TextStrokeTransparency = 0
	t.Text = text
	t.Parent = gui
end

-- quiosque (banca com toldo) — marcador de loja/maquina; a funcao vem depois.
local function kiosk(parent: Instance, pos: Vector3, name: string, awn: Color3)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	local counter = P(f, "Counter", Vector3.new(11, 4, 6), CFrame.new(pos + Vector3.new(0, 2, 0)), Color3.fromRGB(226, 226, 232), M.SmoothPlastic)
	P(f, "CounterTrim", Vector3.new(11.4, 1.2, 6.4), CFrame.new(pos + Vector3.new(0, 3.6, 0)), awn, M.SmoothPlastic)
	for _, sx in { -1, 1 } do
		P(f, "Post", Vector3.new(0.6, 9, 0.6), CFrame.new(pos + Vector3.new(sx * 5, 4.5, 0)), Color3.fromRGB(210, 190, 140), M.Wood)
	end
	P(f, "Awning", Vector3.new(13, 0.6, 7), CFrame.new(pos + Vector3.new(0, 9, 1)) * CFrame.Angles(math.rad(-14), 0, 0), awn, M.Fabric)
	townLabel(counter, name, Color3.fromRGB(255, 255, 255), 8.5)
	return f
end

-- placa de leaderboard
local function board(parent: Instance, pos: Vector3, title: string, color: Color3)
	local f = Instance.new("Folder")
	f.Name = "Board_" .. title
	f.Parent = parent
	for _, sx in { -1, 1 } do
		P(f, "Post", Vector3.new(0.8, 16, 0.8), CFrame.new(pos + Vector3.new(sx * 8, 8, 0)), Color3.fromRGB(96, 74, 52), M.Wood)
	end
	local panel = P(f, "Panel", Vector3.new(1, 18, 20), CFrame.new(pos + Vector3.new(0, 13, 0)), color, M.SmoothPlastic)
	townLabel(panel, title, Color3.fromRGB(255, 255, 255), 10)
	return f
end

-- NPC blocky atras de um balcao
local function npcStand(parent: Instance, pos: Vector3, name: string, bodyColor: Color3)
	local f = Instance.new("Folder")
	f.Name = name
	f.Parent = parent
	P(f, "Stand", Vector3.new(9, 4, 4), CFrame.new(pos + Vector3.new(0, 2, 0)), Color3.fromRGB(210, 70, 70), M.SmoothPlastic)
	local body = P(f, "Body", Vector3.new(2.2, 3, 1.3), CFrame.new(pos + Vector3.new(0, 5.6, -1)), bodyColor, M.SmoothPlastic)
	P(f, "Head", Vector3.new(1.7, 1.7, 1.7), CFrame.new(pos + Vector3.new(0, 7.8, -1)), Color3.fromRGB(240, 205, 170), M.SmoothPlastic)
	townLabel(body, name, Color3.fromRGB(255, 255, 255), 3)
	return f
end

local function buildTownProps(hub: Folder)
	-- 4 ao redor da praca (ver fotos do usuario)
	kiosk(hub, Vector3.new(-62, 0, -44), "SHOP", Color3.fromRGB(150, 70, 180))
	kiosk(hub, Vector3.new(-62, 0, 44), "ROBUX SHOP", Color3.fromRGB(70, 180, 110))
	kiosk(hub, Vector3.new(62, 0, -44), "FUSE MACHINE", Color3.fromRGB(230, 120, 60))
	kiosk(hub, Vector3.new(62, 0, 44), "SPIN THE WHEEL", Color3.fromRGB(130, 95, 225))
	-- leaderboards numa ponta (oeste)
	board(hub, Vector3.new(-286, 0, -26), "TOP EARN", Color3.fromRGB(240, 196, 70))
	board(hub, Vector3.new(-286, 0, 26), "TOP TIME", Color3.fromRGB(235, 120, 150))
	-- NPCs na outra ponta (leste): vender e batalhar
	local sellNpc = npcStand(hub, Vector3.new(286, 0, -18), "Vender Brainmon", Color3.fromRGB(60, 120, 200))
	local sellPrompt = Instance.new("ProximityPrompt")
	sellPrompt.ActionText = "Vender"
	sellPrompt.ObjectText = "Vender Brainmon"
	sellPrompt.KeyboardKeyCode = Enum.KeyCode.E
	sellPrompt.MaxActivationDistance = 12
	sellPrompt.RequiresLineOfSight = false
	sellPrompt.Parent = sellNpc:FindFirstChild("Body")
	game:GetService("CollectionService"):AddTag(sellPrompt, "SellPrompt") -- SellClient abre o painel ao disparar
	npcStand(hub, Vector3.new(286, 0, 18), "Batalhar", Color3.fromRGB(200, 70, 70))
end

local function buildHub(parent: Folder): CFrame
	local hub = Instance.new("Folder")
	hub.Name = "Hub"
	hub.Parent = parent
	local totalZ = (L.Plot * 4 + L.Road * 2 + L.Hub) + 60
	local totalX = 2 * (L.River / 2 + L.Walk + L.Plot) + 20
	local halfX = totalX / 2
	local bz = L.Hub / 2 -- meia-profundidade da town

	-- base estrutural + gramado claro da town (2 lados do rio)
	P(hub, "Slab", Vector3.new(totalX, 3, totalZ), CFrame.new(0, -3, 0), Color3.fromRGB(60, 62, 72), M.Slate, { CastShadow = true })
	for _, sx in { -1, 1 } do
		local w = halfX - L.River / 2
		P(hub, "Lawn", Vector3.new(w, 1, L.Hub), CFrame.new(sx * (L.River / 2 + w / 2), -0.5, 0), Color3.fromRGB(104, 176, 92), M.Grass)
	end

	-- rio + cais + cachoeiras
	P(hub, "River", Vector3.new(L.River, 0.4, totalZ), CFrame.new(0, -1.3, 0), Color3.fromRGB(70, 200, 235), M.Glass, { Transparency = 0.2, CanCollide = false })
	for _, sx in { -1, 1 } do
		P(hub, "Curb", Vector3.new(2, 2.5, totalZ), CFrame.new(sx * (L.River / 2 + 1), -0.25, 0), Color3.fromRGB(150, 150, 158), M.Cobblestone)
		P(hub, "Waterfall", Vector3.new(L.River, 40, 1.5), CFrame.new(0, -20, -sx * (totalZ / 2 + 0.5)), Color3.fromRGB(150, 230, 250), M.Glass, { Transparency = 0.35, CanCollide = false })
	end

	-- AVENIDA central E-W: calcada clara + tapete vermelho com trim dourado (passa por cima do rio via praca)
	P(hub, "Walk", Vector3.new(totalX, 0.2, 58), CFrame.new(0, 0.1, 0), Color3.fromRGB(182, 184, 194), M.Cobblestone)
	P(hub, "Carpet", Vector3.new(totalX, 0.3, 32), CFrame.new(0, 0.26, 0), Color3.fromRGB(156, 42, 48), M.Fabric)
	for _, sz in { -1, 1 } do
		P(hub, "CarpetTrim", Vector3.new(totalX, 0.33, 2.5), CFrame.new(0, 0.3, sz * 16.5), Color3.fromRGB(228, 180, 78), M.SmoothPlastic)
	end

	-- praca + fonte de cristal no centro (clean)
	disc(hub, "Plaza", 104, 2, Vector3.new(0, 0.2, 0), Color3.fromRGB(196, 198, 206), M.Cobblestone)
	disc(hub, "PlazaRing", 84, 2, Vector3.new(0, 0.3, 0), Color3.fromRGB(168, 170, 180), M.Slate)
	disc(hub, "PlazaInner", 60, 2, Vector3.new(0, 0.4, 0), Color3.fromRGB(210, 212, 220), M.Cobblestone)
	disc(hub, "Basin", 30, 3, Vector3.new(0, 1.0, 0), Color3.fromRGB(150, 152, 162), M.Slate)
	disc(hub, "Water", 26, 1, Vector3.new(0, 2.6, 0), Color3.fromRGB(80, 200, 255), M.Neon, { Transparency = 0.3, CanCollide = false })
	local crystal = P(hub, "Crystal", Vector3.new(5, 26, 5), CFrame.new(0, 16, 0) * CFrame.Angles(0, math.rad(45), math.rad(6)), Color3.fromRGB(120, 230, 255), M.Neon, { Transparency = 0.1, CanCollide = false })
	for k = 1, 4 do
		local a = k * math.pi / 2
		P(hub, "Shard", Vector3.new(3, 14, 3), CFrame.new(math.cos(a) * 7, 9, math.sin(a) * 7) * CFrame.Angles(math.cos(a) * 0.35, a, -math.sin(a) * 0.35), Color3.fromRGB(150, 235, 255), M.Neon, { Transparency = 0.15, CanCollide = false })
	end
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(120, 230, 255)
	light.Range = 55
	light.Brightness = 3
	light.Parent = crystal

	-- aviso de evento acima do cristal (o sistema de eventos atualiza "Event.Text" depois)
	local eventAnchor = P(hub, "EventBanner", Vector3.new(1, 1, 1), CFrame.new(0, 42, 0), Color3.new(1, 1, 1), M.Neon, { Transparency = 1, CanCollide = false })
	local egui = Instance.new("BillboardGui")
	egui.Name = "Event"
	egui.Adornee = eventAnchor
	egui.Size = UDim2.fromOffset(440, 72)
	egui.MaxDistance = 600
	egui.Enabled = false -- escondido fora de evento; EventService liga durante o evento
	egui.Parent = eventAnchor
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(16, 16, 22)
	frame.BackgroundTransparency = 0.12
	frame.BorderSizePixel = 0
	frame.Parent = egui
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 14)
	corner.Parent = frame
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(150, 150, 160)
	stroke.Thickness = 2
	stroke.Parent = frame
	local etxt = Instance.new("TextLabel")
	etxt.Name = "Text"
	etxt.BackgroundTransparency = 1
	etxt.Size = UDim2.fromScale(0.92, 0.8)
	etxt.Position = UDim2.fromScale(0.04, 0.1)
	etxt.Font = Enum.Font.FredokaOne
	etxt.TextScaled = true
	etxt.TextColor3 = Color3.fromRGB(255, 92, 92)
	etxt.TextStrokeTransparency = 0
	etxt.Text = "COSMIC BRAINMON — em breve"
	etxt.Parent = frame

	-- postes ladeando a avenida + sebes baixas (look clean de town)
	for k = -4, 4 do
		if k ~= 0 then
			local x = k * 66
			for _, sz in { -1, 1 } do
				lamp(hub, Vector3.new(x, 0, sz * 30))
			end
		end
	end
	for _, sz in { -1, 1 } do
		for k = -4, 4 do
			local x = k * 64 + 32
			if math.abs(x) > 56 and math.abs(x) < halfX - 20 then
				P(hub, "Hedge", Vector3.new(26, 3, 3), CFrame.new(x, 1.5, sz * 44), Color3.fromRGB(70, 140, 70), M.Grass)
			end
		end
	end

	-- arvores esparsas no fundo da town (atras das fileiras de base), de backdrop
	local rng = Random.new(42)
	local treeD = { a = Color3.fromRGB(96, 68, 44), b = Color3.fromRGB(64, 150, 70) }
	for k = -6, 6 do
		if math.abs(k) > 1 then
			for _, sz in { -1, 1 } do
				local x = k * 44 + rng:NextNumber(-6, 6)
				if math.abs(x) > L.River / 2 + 6 and math.abs(x) < halfX - 10 then
					Decos.tree(hub, Vector3.new(x, 0, sz * (bz - 14)), rng, treeD, false)
				end
			end
		end
	end

	buildTownProps(hub) -- SHOP/ROBUX/FUSE/WHEEL ao redor da praca; leaderboards e NPCs nas pontas (posicoes das fotos)

	local sp = Instance.new("SpawnLocation")
	sp.Name = "HubSpawn"
	sp.Anchored = true
	sp.Neutral = true
	sp.Duration = 0
	sp.Size = Vector3.new(12, 1, 12)
	sp.CFrame = CFrame.lookAt(Vector3.new(74, 2.2, 0), Vector3.new(0, 2.2, 0))
	sp.Color = Color3.fromRGB(80, 200, 255)
	sp.Material = M.Neon
	sp.Transparency = 0.5
	sp.CanCollide = false
	sp.Parent = hub
	return CFrame.lookAt(Vector3.new(74, 4, 0), Vector3.new(0, 4, 0))
end

-- Floresta de fundo: espalha a arvore de mesh pelo mapa, fora dos mundos, do hub e do corredor central.
local function scatterTrees(map: Folder)
	if not getTreeTemplate() then
		warn("[BiomeBuilder] sem TreeTemplate; floresta de fundo pulada")
		return
	end
	local rng = Random.new()
	local function blocked(x: number, z: number): boolean
		if math.abs(x) < 70 then
			return true -- corredor central (rio / viagem entre mundos)
		end
		if math.abs(z) < 165 and math.abs(x) < 330 then
			return true -- hub (town, bases, avenida)
		end
		for i = 1, #Data.Worlds do
			local o = Data.OriginOf(i)
			if math.abs(x - o.X) < 195 and math.abs(z - o.Z) < 195 then
				return true -- interior de cada mundo (com margem)
			end
		end
		return false
	end
	local trees = Instance.new("Folder")
	trees.Name = "Trees"
	trees.Parent = map
	local placed, tries = 0, 0
	while placed < 220 and tries < 5000 do
		tries += 1
		local x, z = rng:NextNumber(-580, 580), rng:NextNumber(-1080, 1080)
		if not blocked(x, z) and placeTree(trees, Vector3.new(x, 0, z), rng, 0.7, 1.4, true) then
			placed += 1
		end
	end
end

-- ---------------------------------------------------------------- API
function B.Build(): Map
	local old = Workspace:FindFirstChild("Map")
	if old then
		old:Destroy()
	end
	local map = Instance.new("Folder")
	map.Name = "Map"
	map.Parent = Workspace
	local t0 = os.clock()
	local hubSpawn = buildHub(map)
	local worlds: { WorldInfo } = {}
	for i = 1, #Data.Worlds do
		worlds[i] = buildWorld(i, map)
		task.wait() -- nao estoura o frame do boot
	end
	scatterTrees(map) -- floresta de fundo (clones da Mesh_AlpTrees4)
	print(`[BiomeBuilder] mapa gerado: {#map:GetDescendants()} instancias em {string.format("%.2f", os.clock() - t0)}s`)
	return { folder = map, hubSpawn = hubSpawn, worlds = worlds }
end

-- Caixa envolvente do mapa (guia F0.9: GetBiomeBounds) — base para a futura BaseBuilder nao colidir.
function B.GetBounds(): (Vector3, Vector3)
	local x = 2 * (L.River / 2 + L.Walk + L.Plot) + 20
	local z = L.Plot * 4 + L.Road * 2 + L.Hub + 60
	return Vector3.zero, Vector3.new(x, 120, z)
end

return B
