--!strict
-- BrainmonData: fonte unica de dados (raridades, tipos, mundos, layout, especies).
-- Servidor E cliente leem daqui; nenhum valor de jogo fica espalhado em scripts.
local SpeciesList = require(script.Parent.Species)

export type Species = { n: number, id: string, name: string, type: string, world: number }

local D = {}

D.Config = {
	-- ponytail: libera os 8 mundos para testar o mapa. Desligar quando quiser que o gate (capturas + BC) seja real.
	DevUnlockAll = true,
	WildPerWorld = 6,
	ShyneChance = 1 / 200,
	TravelDebounce = 2, -- [video B#10 06:32] debounce de 2 s no GeoHop
	StarGlyph = "\u{2605}", -- fonte do Roblox nao tem U+2726
	-- economia (decisao minha; balancear depois com os gates 2500 -> 50M). Renda = soma do squad, 1 tick/s.
	StartBC = 0,
	SquadSize = 8, -- time de batalha (futuro); nao rende
	ShyneIncomeMult = 5,
	IncomeTick = 1, -- segundos entre ticks de acumulo na base
	CashMulti = 1, -- multiplicador ao COLETAR (vira upgrade/index-bonus depois, como no jogo de referencia)
	SellMult = 10, -- venda avulsa (NPC): BC = renda/s do individuo x isto. TODO balancear.
	-- Rebirth (reseta so BC; mantem Braindex). Da +multiplicador de coleta E +sorte de ovo, permanentes. TODO balancear.
	RebirthBaseCost = 50000, -- BC do 1o rebirth
	RebirthCostMult = 3, -- custo x3 a cada rebirth (50K -> 150K -> 450K ...)
	RebirthBaseSpecies = 10, -- especies DISTINTAS exigidas no 1o rebirth
	RebirthSpeciesInc = 5, -- +5 especies exigidas por rebirth
	RebirthCashInc = 0.5, -- +0.5 no multiplicador de coleta por rebirth (efetivo = CashMulti + rebirths*isto)
	RebirthLuckMult = 0.25, -- +25% de peso pras mutations por rebirth (sorte de ovo; selvagem continua global)
}

-- Escada de raridade (ideia do jogo). Escala = maior dimensao do bicho em studs (4.5 Common -> 12.3 topo, como no projeto antigo).
D.Rarities = { "Common", "Rare", "Epic", "Mystic" }
-- income = BC/s por individuo no squad (curva exponencial, estilo Steal a Brainrot; editavel).
D.RarityInfo = {
	Common = { color = Color3.fromRGB(176, 176, 176), scale = 4.5, income = 3 },
	Rare = { color = Color3.fromRGB(60, 141, 255), scale = 6.5, income = 20 },
	Epic = { color = Color3.fromRGB(166, 77, 255), scale = 9, income = 140 },
	Mystic = { color = Color3.fromRGB(255, 77, 77), scale = 12.3, income = 1000 },
	Shyne = { color = Color3.fromRGB(255, 226, 122), scale = 1, income = 0 }, -- legado (mutations substituem)
} :: { [string]: { color: Color3, scale: number, income: number } }

-- Mutations = skins do BrainrotPack; multiplicam renda/valor. Substituem o antigo "Shyne".
-- key = nome da pasta em BrainrotPack; prefix = prefixo do nome do modelo naquela pasta. mult/weight = PLACEHOLDER (balancear).
D.MutationOrder = { "Normal", "Oro", "Diamante", "Lava", "Galaxia", "Hacker", "Arcoiris" }
D.Mutations = {
	Normal = { prefix = "", mult = 1, weight = 1000, color = Color3.fromRGB(200, 200, 205), label = "Normal" },
	Oro = { prefix = "Gold ", mult = 2, weight = 70, color = Color3.fromRGB(240, 196, 70), label = "Ouro" },
	Diamante = { prefix = "Diamond ", mult = 4, weight = 35, color = Color3.fromRGB(120, 230, 245), label = "Diamante" },
	Lava = { prefix = "Lava ", mult = 8, weight = 16, color = Color3.fromRGB(255, 120, 40), label = "Lava" },
	Galaxia = { prefix = "Galaxy ", mult = 15, weight = 7, color = Color3.fromRGB(170, 90, 255), label = "Galáxia" },
	Hacker = { prefix = "Hacker ", mult = 25, weight = 3, color = Color3.fromRGB(60, 255, 120), label = "Hacker" },
	Arcoiris = { prefix = "Rainbow ", mult = 50, weight = 1, color = Color3.fromRGB(255, 120, 200), label = "Arco-íris" },
} :: { [string]: { prefix: string, mult: number, weight: number, color: Color3, label: string } }

-- Sorteia uma mutation (ponderada). luck > 1 empurra pras melhores (bonus de rebirth).
function D.RollMutation(rng: Random, luck: number?): string
	local l = luck or 1
	local total, weighted = 0, {}
	for _, k in D.MutationOrder do
		local w = D.Mutations[k].weight
		if k ~= "Normal" then
			w *= l
		end
		weighted[k] = w
		total += w
	end
	local roll = rng:NextNumber() * total
	local acc = 0
	for _, k in D.MutationOrder do
		acc += weighted[k]
		if roll < acc then
			return k
		end
	end
	return "Normal"
end

-- Multiplicador de renda/valor da mutation (seguro p/ chave desconhecida).
function D.MutationMult(mut: string?): number
	local m = D.Mutations[mut or "Normal"]
	return if m then m.mult else 1
end

D.Types = {
	Fogo = Color3.fromRGB(235, 90, 40),
	["Água"] = Color3.fromRGB(60, 150, 235),
	Magia = Color3.fromRGB(190, 110, 235),
	Terra = Color3.fromRGB(160, 120, 70),
	Gelo = Color3.fromRGB(150, 215, 240),
	Raio = Color3.fromRGB(245, 215, 50),
	Sombra = Color3.fromRGB(80, 70, 120),
	Planta = Color3.fromRGB(90, 190, 80),
	Metal = Color3.fromRGB(160, 165, 175),
} :: { [string]: Color3 }

-- Layout em studs (guia 7.2: tudo gerado no boot; 16 st de vao de cerca; hub entre as linhas 2 e 3).
D.Layout = {
	Plot = 340, -- lado de cada mundo (escalado: 175 especies + mais wilds)
	Road = 20, -- vao entre mundos da mesma coluna
	River = 36, -- rio central (x de -18 a 18)
	Walk = 12, -- calcada de cada margem (x 18..30)
	Hub = 300, -- faixa do hub (town): avenida central + 2 fileiras de bases dos lados
	GateGap = 16,
	Rows = 4,
}

-- Slots das bases dos jogadores: 2 fileiras (norte/sul) lado a lado da avenida central do hub.
-- Fonte unica: BiomeBuilder emoldura (cerca/postes) e BaseBuilder preenche os plots. face = +1 avenida ao +Z, -1 ao -Z.
function D.BaseSlots(): { { pos: Vector3, face: number } }
	local slots = {}
	local xs = { -250, -185, -120, 120, 185, 250 }
	local rowZ = 92
	for _, x in xs do
		table.insert(slots, { pos = Vector3.new(x, 0, -rowZ), face = 1 }) -- fileira norte: frente/coleta pro +Z (avenida)
	end
	for _, x in xs do
		table.insert(slots, { pos = Vector3.new(x, 0, rowZ), face = -1 }) -- fileira sul: frente/coleta pro -Z
	end
	return slots
end

-- Raridade nativa + gate (ideia: "3 / 3 BRAINMONS - BC / 5000 BC"): species = quantas especies do mundo anterior, bc = custo.
-- Atmosfera: faixa segura do guia (brilho 1.0-2.8, glare <= 0.55, haze <= 2.0, bloomThreshold >= 0.8) — D.SafeAtmosphere garante.
local c = Color3.fromRGB
D.Worlds = ({
	{
		id = "SelvaTotens", name = "A Selva dos Totens Perdidos", rarity = "Common", col = 1, row = 2,
		gate = { species = 0, bc = 0 },
		style = {
			floor = { c(74, 110, 60), c(64, 98, 52) }, floorMat = Enum.Material.Grass, fence = c(92, 80, 62), fenceMat = Enum.Material.Slate,
			accent = c(120, 220, 90),
			deco = {
				{ k = "tree", w = 5, a = c(86, 62, 40), b = c(48, 110, 52) },
				{ k = "stack", w = 2, a = c(120, 110, 90), b = c(90, 140, 70) }, -- totem de pedra com musgo
				{ k = "pillar", w = 2, a = c(110, 105, 95) },
				{ k = "mound", w = 2, a = c(58, 120, 56) },
			},
			landmark = { kind = "tiers", layers = { { 80, 10, c(100, 100, 88) }, { 62, 10, c(92, 110, 80) }, { 44, 10, c(86, 120, 76) }, { 26, 8, c(120, 130, 100) } }, top = c(120, 220, 90) },
		},
		atmosphere = { clock = 17.6, brightness = 1.9, atmColor = c(140, 190, 150), haze = 1.5, density = 0.33, outdoor = c(84, 120, 96), ambient = c(60, 84, 64), decay = c(70, 110, 60) },
	},
	{
		id = "Banquete", name = "O Banquete de Caramelo e Neve", rarity = "Common", col = 1, row = 1,
		gate = { species = 3, bc = 2500 },
		style = {
			floor = { c(240, 205, 220), c(232, 222, 200) }, floorMat = Enum.Material.SmoothPlastic, fence = c(150, 100, 80), fenceMat = Enum.Material.Concrete,
			accent = c(255, 150, 200),
			deco = {
				{ k = "tree", w = 4, a = c(120, 80, 55), b = c(245, 160, 200) }, -- arvore de algodao-doce
				{ k = "stack", w = 3, a = c(120, 80, 50), b = c(235, 190, 120) },
				{ k = "crystal", w = 2, a = c(200, 235, 250) },
				{ k = "mound", w = 3, a = c(238, 240, 245) },
			},
			landmark = { kind = "tiers", layers = { { 90, 14, c(120, 80, 50) }, { 70, 14, c(165, 110, 66) }, { 50, 14, c(205, 150, 92) }, { 30, 14, c(238, 238, 242) } }, top = c(220, 50, 70) },
		},
		atmosphere = { clock = 16.2, brightness = 2.2, atmColor = c(225, 205, 235), haze = 1.0, density = 0.25, outdoor = c(150, 130, 160), ambient = c(120, 100, 130), decay = c(220, 160, 190) },
	},
	{
		id = "Pantano", name = "O Pantano Tóxico", rarity = "Rare", col = 1, row = 3,
		gate = { species = 3, bc = 15000 },
		style = {
			floor = { c(64, 56, 74), c(72, 84, 48) }, floorMat = Enum.Material.Mud, fence = c(50, 44, 60), fenceMat = Enum.Material.Slate,
			accent = c(150, 255, 60),
			deco = {
				{ k = "tree", w = 4, a = c(60, 44, 70), b = c(70, 100, 40), dead = true },
				{ k = "pool", w = 4, a = c(120, 255, 70) },
				{ k = "stack", w = 2, a = c(110, 70, 150), b = c(150, 255, 60) }, -- cogumelo
				{ k = "pillar", w = 2, a = c(70, 60, 85) },
			},
			landmark = { kind = "tiers", layers = { { 40, 18, c(90, 62, 120) }, { 32, 18, c(100, 70, 130) }, { 24, 16, c(80, 56, 110) } }, top = c(150, 255, 60) },
		},
		atmosphere = { clock = 18.8, brightness = 1.7, atmColor = c(130, 170, 90), haze = 1.8, density = 0.35, outdoor = c(80, 96, 70), ambient = c(56, 60, 52), decay = c(100, 150, 60) },
	},
	{
		id = "Abissal", name = "A Cidade Abissal dos Sussurros", rarity = "Rare", col = 1, row = 4,
		gate = { species = 4, bc = 80000 },
		style = {
			floor = { c(30, 76, 96), c(36, 92, 104) }, floorMat = Enum.Material.Slate, fence = c(28, 56, 70), fenceMat = Enum.Material.Cobblestone,
			accent = c(80, 230, 240),
			deco = {
				{ k = "crystal", w = 4, a = c(240, 130, 160) }, -- coral
				{ k = "crystal", w = 3, a = c(80, 220, 230) },
				{ k = "pillar", w = 3, a = c(40, 100, 110) },
				{ k = "pool", w = 2, a = c(60, 200, 230) },
			},
			landmark = { kind = "tiers", layers = { { 96, 12, c(30, 80, 96) }, { 76, 12, c(34, 96, 112) }, { 56, 12, c(40, 112, 126) }, { 36, 12, c(50, 130, 140) }, { 18, 10, c(80, 200, 210) } }, top = c(120, 255, 240) },
		},
		atmosphere = { clock = 14, brightness = 1.8, atmColor = c(90, 170, 200), haze = 1.7, density = 0.4, outdoor = c(70, 120, 150), ambient = c(50, 90, 110), decay = c(40, 110, 140) },
	},
	{
		id = "NeonPark", name = "O Parque Neon do Caos Digital", rarity = "Epic", col = 2, row = 1,
		gate = { species = 4, bc = 400000 },
		style = {
			floor = { c(46, 50, 66), c(38, 42, 58) }, floorMat = Enum.Material.Metal, fence = c(30, 30, 44), fenceMat = Enum.Material.Metal,
			accent = c(190, 90, 255),
			deco = {
				{ k = "stack", w = 4, a = c(36, 38, 52), b = c(90, 220, 255) }, -- torre com neon
				{ k = "lamp", w = 4, a = c(190, 90, 255) },
				{ k = "lamp", w = 3, a = c(90, 230, 255) },
				{ k = "pillar", w = 2, a = c(50, 52, 70) },
			},
			landmark = { kind = "towers", base = c(34, 36, 50), neon = c(190, 90, 255), top = c(150, 60, 230) },
		},
		atmosphere = { clock = 20.5, brightness = 1.6, atmColor = c(120, 100, 190), haze = 1.2, density = 0.3, outdoor = c(92, 86, 150), ambient = c(70, 60, 110), decay = c(110, 70, 170), bloomThreshold = 0.85, bloomIntensity = 0.6 },
	},
	{
		id = "Forja", name = "A Forja de Magma e Caos", rarity = "Epic", col = 2, row = 3,
		gate = { species = 5, bc = 2000000 },
		style = {
			floor = { c(86, 56, 42), c(70, 46, 36) }, floorMat = Enum.Material.Basalt, fence = c(50, 34, 30), fenceMat = Enum.Material.Basalt,
			accent = c(255, 140, 40),
			deco = {
				{ k = "pool", w = 4, a = c(255, 120, 30) },
				{ k = "pillar", w = 3, a = c(40, 30, 28) },
				{ k = "mound", w = 3, a = c(60, 42, 36) },
				{ k = "crystal", w = 2, a = c(255, 160, 50) },
			},
			landmark = { kind = "tiers", layers = { { 100, 16, c(58, 40, 34) }, { 76, 16, c(70, 46, 38) }, { 52, 16, c(84, 52, 40) }, { 28, 14, c(100, 60, 44) } }, top = c(255, 120, 30) },
		},
		atmosphere = { clock = 17.8, brightness = 2.0, atmColor = c(190, 130, 90), haze = 1.3, density = 0.3, outdoor = c(130, 96, 80), ambient = c(96, 70, 60), decay = c(210, 110, 50) },
	},
	{
		id = "Cristais", name = "O Reino dos Cristais Etéreos", rarity = "Mystic", col = 2, row = 2,
		gate = { species = 5, bc = 10000000 },
		style = {
			floor = { c(64, 44, 116), c(76, 54, 132) }, floorMat = Enum.Material.Slate, fence = c(50, 36, 90), fenceMat = Enum.Material.Marble,
			accent = c(200, 150, 255),
			deco = {
				{ k = "crystal", w = 6, a = c(180, 110, 255) },
				{ k = "stack", w = 2, a = c(222, 178, 70), b = c(240, 210, 110) }, -- altar dourado
				{ k = "pillar", w = 2, a = c(90, 64, 150) },
				{ k = "lamp", w = 1, a = c(120, 230, 255) },
			},
			landmark = { kind = "tiers", layers = { { 90, 8, c(70, 50, 130) }, { 66, 8, c(222, 178, 70) }, { 46, 8, c(80, 58, 146) }, { 28, 8, c(222, 178, 70) } }, top = c(200, 150, 255) },
		},
		atmosphere = { clock = 19.6, brightness = 1.9, atmColor = c(150, 110, 210), haze = 1.4, density = 0.32, outdoor = c(110, 90, 170), ambient = c(86, 70, 130), decay = c(140, 90, 220) },
	},
	{
		id = "Arena", name = "A Arena das Sombras Eterna", rarity = "Mystic", col = 2, row = 4,
		gate = { species = 6, bc = 50000000 },
		style = {
			floor = { c(66, 66, 74), c(54, 54, 62) }, floorMat = Enum.Material.Slate, fence = c(40, 40, 48), fenceMat = Enum.Material.Slate,
			accent = c(230, 70, 70),
			deco = {
				{ k = "pillar", w = 5, a = c(48, 48, 56) },
				{ k = "stack", w = 2, a = c(40, 40, 48), b = c(200, 60, 60) }, -- torre de holofote/banner
				{ k = "crystal", w = 2, a = c(200, 50, 60) },
				{ k = "mound", w = 2, a = c(70, 70, 78) },
			},
			landmark = { kind = "ring", wall = c(44, 44, 52), sand = c(168, 138, 96), trim = c(200, 60, 60) },
		},
		atmosphere = { clock = 21, brightness = 1.6, atmColor = c(110, 110, 140), haze = 1.0, density = 0.28, outdoor = c(96, 96, 128), ambient = c(70, 70, 96), decay = c(120, 50, 60) },
	},
} :: any)

-- Hub (praca central com cristal): entardecer calibrado do projeto antigo (hora azul; quente so dos postes).
D.HubAtmosphere = ({
	clock = 18.4, brightness = 2.0, atmColor = c(150, 172, 214), haze = 1.2, density = 0.30,
	outdoor = c(96, 112, 160), ambient = c(70, 80, 110), decay = c(92, 60, 120),
} :: any)

-- Garante a faixa segura (guia 6.4): evita apagao branco por haze alto e bloom em tudo.
function D.SafeAtmosphere(a: { [string]: any }): { [string]: any }
	local s = table.clone(a)
	s.brightness = math.clamp(s.brightness, 1.0, 2.8)
	s.haze = math.clamp(s.haze, 0, 2.0)
	s.glare = math.clamp(s.glare or 0.3, 0, 0.55)
	s.bloomThreshold = math.max(s.bloomThreshold or 0.9, 0.8)
	s.bloomIntensity = s.bloomIntensity or 0.4
	return s
end

-- Posicao do mundo i (centro do plot) a partir do layout. Colunas: 1 = oeste (-x), 2 = leste (+x).
function D.OriginOf(i: number): Vector3
	local L, w = D.Layout, D.Worlds[i]
	local x = (L.River / 2 + L.Walk + L.Plot / 2) * (if w.col == 1 then -1 else 1)
	local step = L.Plot + L.Road
	local z
	if w.row <= 2 then
		z = -(L.Hub / 2 + L.Plot / 2) - (2 - w.row) * step
	else
		z = (L.Hub / 2 + L.Plot / 2) + (w.row - 3) * step
	end
	return Vector3.new(x, 0, z)
end

function D.Gate(i: number) -- requisito para ENTRAR no mundo i pela 1a vez (mundo anterior = i-1)
	return D.Worlds[i].gate
end

-- Indices
D.Species = SpeciesList :: { Species }
D.SpeciesById = {} :: { [string]: Species }
D.SpeciesByWorld = {} :: { [number]: { Species } }
for _, sp in SpeciesList do
	D.SpeciesById[sp.id] = sp
	local list = D.SpeciesByWorld[sp.world] or {}
	table.insert(list, sp)
	D.SpeciesByWorld[sp.world] = list
end

function D.RarityOf(sp: Species): string
	return D.Worlds[sp.world].rarity
end

-- Quantos selvagens por mundo: comuns = mais; raros = mais dificeis de achar.
local WildByRarity = { Common = 18, Rare = 12, Epic = 8, Mystic = 5 }
function D.WildCount(i: number): number
	return WildByRarity[D.Worlds[i].rarity] or 8
end

-- Valor de venda avulsa (NPC "Vender Brainmon"). Fonte unica: servidor paga e cliente mostra o mesmo numero.
function D.SellValue(speciesId: string, mutation: string?): number
	local sp = D.SpeciesById[speciesId]
	if not sp then
		return 0
	end
	local base = D.RarityInfo[D.RarityOf(sp)].income * D.MutationMult(mutation)
	return math.floor(base * D.Config.SellMult)
end

-- Ovos da loja (Passo 3): 1 ovo por mundo. Comprar gasta BC e da um Brainmon daquele mundo
-- (raridade = raridade do mundo). Preco = PLACEHOLDER; balancear junto com os gates. price <= 0 = fora da loja.
-- TODO balancear: hoje so o preco gateia (da pra comprar ovo Mystic cedo se tiver BC). Se virar problema, gatear por mundo desbloqueado.
-- price = BC (-1 = nao vende por BC); robux = id do Developer Product (0 = falta criar no Studio).
-- Ovos raros (Epic/Mystic, mundos 5-8) sao por Robux. TODO: criar os dev products e por os ids aqui.
local EggDefs = {
	{ price = 150, robux = 0 },
	{ price = 900, robux = 0 },
	{ price = 6000, robux = 0 },
	{ price = 40000, robux = 0 },
	{ price = -1, robux = 0 }, -- NeonPark (Epic): Robux
	{ price = -1, robux = 0 }, -- Forja (Epic): Robux
	{ price = -1, robux = 0 }, -- Cristais (Mystic): Robux
	{ price = -1, robux = 0 }, -- Arena (Mystic): Robux
}
D.Eggs = {} :: { [string]: { world: number, price: number, robux: number, name: string } }
for i, w in D.Worlds do
	local d = EggDefs[i] or { price = -1, robux = 0 }
	D.Eggs["Egg" .. i] = { world = i, price = d.price, robux = d.robux, name = "Ovo · " .. w.name }
end

-- Monetizacao Robux. Todos os ids = 0 ate o Mattheus criar no Studio (Monetization) e me passar.
-- StarterPack = Developer Product (bundle). Vip/VipUnlimited = Game Passes (bonus permanente de coleta/sorte).
D.Robux = {
	StarterPack = {
		product = 0, -- Developer Product id
		robux = 0, -- preco so pra exibir (opcional)
		bc = 20000000000, -- 20 B de BC
		cosmic = { world = 8, mutation = "Arcoiris" }, -- 1 brainmon "cosmico" = Mystic + Arco-iris
		fire = { world = 6, count = 2 }, -- 2 "ovos de fogo" = 2 brainmons da Forja
	},
	Vip = { pass = 0, robux = 599, label = "VIP", cashBonus = 0.5, luckBonus = 0.5 },
	VipUnlimited = { pass = 0, robux = 1000, label = "VIP Ilimitado", cashBonus = 2.0, luckBonus = 2.0 },
} :: any

-- Abreviacao de dinheiro (notacao do usuario): 1 / 1K / 1M / 1Bi / 1T / 1Qa / 1Qi / 1Sx ... (2 casas, sem zeros a direita).
local MoneySuffix = { "", "K", "M", "Bi", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "Ud", "Dd", "Td" }
function D.Money(n: number): string
	n = math.floor(n)
	if n < 0 then
		return "-" .. D.Money(-n)
	end
	local i = 0
	local v = n
	while v >= 1000 and i < #MoneySuffix - 1 do
		v /= 1000
		i += 1
	end
	if i == 0 then
		return tostring(n)
	end
	local s = string.format("%.2f", v):gsub("%.?0+$", "") -- remove zeros a direita (1.20 -> 1.2, 1.00 -> 1)
	return s .. MoneySuffix[i + 1]
end

-- "3 / 3 BRAINMONS · BC / 5000 BC" (placa e menu Worlds)
function D.GateText(i: number, owned: number, bc: number): string
	local g = D.Worlds[i].gate
	return `{math.min(owned, g.species)} / {g.species} BRAINMONS · {math.min(bc, g.bc)} / {g.bc} BC`
end

return D
