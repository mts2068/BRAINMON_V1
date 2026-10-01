--!strict
-- Combat: dados e formulas da batalha (F1). Stats por raridade (auto, ajustavel), tabela de tipos, moves por tipo,
-- formula de dano (estilo Pokemon) e catch-rate por HP%+ball. Servidor E cliente leem daqui.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Data = require(ReplicatedStorage:WaitForChild("BrainmonData"))

local C = {}

-- ---------------------------------------------------------------- tipos (efetividade)
-- SUPER = 2x, WEAK = 0.5x, resto = 1x. (loop balanceado adaptado aos nossos 9 tipos; ajustavel)
local SUPER: { [string]: { string } } = {
	Fogo = { "Planta", "Gelo", "Metal" },
	["Água"] = { "Fogo", "Terra" },
	Planta = { "Água", "Terra" },
	Terra = { "Fogo", "Raio", "Metal" },
	Gelo = { "Planta", "Sombra" },
	Raio = { "Água", "Metal" },
	Metal = { "Gelo", "Planta" },
	Magia = { "Sombra", "Terra" },
	Sombra = { "Magia", "Raio" },
}
local WEAK: { [string]: { string } } = {
	Fogo = { "Água", "Terra" },
	["Água"] = { "Planta", "Raio" },
	Planta = { "Fogo", "Gelo", "Metal" },
	Terra = { "Água", "Planta", "Gelo" },
	Gelo = { "Fogo", "Metal" },
	Raio = { "Terra", "Sombra" },
	Metal = { "Fogo", "Terra" },
	Magia = { "Sombra" },
	Sombra = { "Gelo", "Magia" },
}
local function has(list: { string }?, v: string): boolean
	if not list then
		return false
	end
	for _, x in list do
		if x == v then
			return true
		end
	end
	return false
end
-- Multiplicador do tipo do move contra o tipo do defensor.
function C.Effectiveness(moveType: string, defType: string): number
	if has(SUPER[moveType], defType) then
		return 2
	elseif has(WEAK[moveType], defType) then
		return 0.5
	end
	return 1
end

-- ---------------------------------------------------------------- stats base (por raridade + variacao estavel)
export type Stats = { hp: number, atk: number, def: number, spd: number }

local BST: { [string]: number } = { Common = 210, Rare = 320, Epic = 440, Mystic = 580 }
local WEIGHT = { hp = 0.32, atk = 0.26, def = 0.24, spd = 0.18 }
local baseCache: { [string]: Stats } = {}

-- Stats base no nivel 1 (deterministico por especie; varia +-13% por bicho).
function C.BaseStats(species: Data.Species): Stats
	local cached = baseCache[species.id]
	if cached then
		return cached
	end
	local total = BST[Data.RarityOf(species)] or 300
	local r = Random.new(species.n) -- semente estavel: mesmo bicho = mesmos stats
	local function stat(w: number): number
		return math.floor(total * w * (1 + r:NextNumber(-0.13, 0.13)))
	end
	local s: Stats = { hp = stat(WEIGHT.hp) + 20, atk = stat(WEIGHT.atk), def = stat(WEIGHT.def), spd = stat(WEIGHT.spd) }
	baseCache[species.id] = s
	return s
end

-- Stats no nivel N (crescimento ~linear; ~2x base no nivel 20). HP cresce um pouco mais.
function C.StatsAtLevel(species: Data.Species, level: number): Stats
	local b = C.BaseStats(species)
	local g = (level - 1) * 0.055
	return {
		hp = math.floor(b.hp * (1 + g * 1.25)) + level * 2,
		atk = math.floor(b.atk * (1 + g)),
		def = math.floor(b.def * (1 + g)),
		spd = math.floor(b.spd * (1 + g)),
	}
end

-- ---------------------------------------------------------------- moves (por tipo)
export type Move = { name: string, type: string, power: number }

local TYPE_MOVES: { [string]: { { any } } } = {
	Fogo = { { "Brasa", 45 }, { "Labareda", 85 } },
	["Água"] = { { "Jato d'Água", 45 }, { "Hidrobomba", 85 } },
	Planta = { { "Folha Navalha", 45 }, { "Tempestade Floral", 85 } },
	Terra = { { "Chute de Lama", 45 }, { "Terremoto", 85 } },
	Gelo = { { "Lufada Gelada", 45 }, { "Nevasca", 85 } },
	Raio = { { "Choque", 45 }, { "Trovão", 85 } },
	Sombra = { { "Golpe Sombrio", 45 }, { "Bola Sombria", 85 } },
	Magia = { { "Confusão", 45 }, { "Psíquico", 85 } },
	Metal = { { "Garra de Aço", 45 }, { "Canhão de Ferro", 85 } },
}

-- Moveset da especie: Investida (fraco) + 2 moves do seu tipo. Todos do tipo do bicho (STAB).
function C.MovesFor(species: Data.Species): { Move }
	local t = species.type
	local tm = TYPE_MOVES[t]
	local moves: { Move } = { { name = "Investida", type = t, power = 35 } }
	if tm then
		for _, m in tm do
			table.insert(moves, { name = m[1] :: string, type = t, power = m[2] :: number })
		end
	end
	return moves
end

-- ---------------------------------------------------------------- dano (formula estilo Pokemon)
export type Combatant = { atk: number, def: number, level: number, type: string }

function C.Damage(attacker: Combatant, defender: Combatant, move: Move, rng: Random?): number
	local eff = C.Effectiveness(move.type, defender.type)
	local stab = if move.type == attacker.type then 1.5 else 1
	local roll = if rng then rng:NextNumber(0.85, 1) else 0.925
	local base = (2 * attacker.level / 5 + 2) * move.power * attacker.atk / math.max(defender.def, 1) / 50 + 2
	return math.max(1, math.floor(base * stab * eff * roll))
end

-- ---------------------------------------------------------------- captura (ball + HP%)
C.Balls = {
	Poke = { mult = 1.0, label = "Poké Ball" },
	Premier = { mult = 1.0, label = "Premier Ball" },
	Great = { mult = 1.6, label = "Great Ball" },
	Ultra = { mult = 2.2, label = "Ultra Ball" },
} :: { [string]: { mult: number, label: string } }

local BASE_CATCH: { [string]: number } = { Common = 0.5, Rare = 0.28, Epic = 0.14, Mystic = 0.06 }

-- Chance de capturar (0..1). HP cheio = dificil; HP baixo = ate ~3x mais facil. ball muda o multiplicador.
function C.CatchChance(species: Data.Species, hpFrac: number, ballKey: string): number
	local ball = C.Balls[ballKey] or C.Balls.Poke
	local base = BASE_CATCH[Data.RarityOf(species)] or 0.3
	local hpBonus = (1 - math.clamp(hpFrac, 0, 1)) * 1.9 -- 0 no HP cheio, +1.9 no HP 0
	return math.clamp(base * ball.mult * (0.4 + hpBonus), 0.02, 0.95)
end

-- XP que o vencedor ganha ao derrotar `species` nivel `level` (curva simples).
function C.XpReward(species: Data.Species, level: number): number
	local rarityMult = ({ Common = 1, Rare = 2, Epic = 4, Mystic = 8 })[Data.RarityOf(species)] or 1
	return math.floor((10 + level * 4) * rarityMult)
end

-- XP necessario pra passar do nivel N pro N+1.
function C.XpToNext(level: number): number
	return math.floor(20 * level ^ 1.5)
end

return C
