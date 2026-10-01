--!strict
-- BattleService (F2): batalha por turnos contra selvagem (PVE). Acoes: Fight / Bag(ball) / Run / Switch.
-- Captura UNICA: jogar ball usa Combat.CatchChance -> BraindexService.AddRecord (o mesmo da captura no mundo).
-- Autoridade total no servidor: o cliente so manda a acao e recebe o estado (BattleSync).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Combat = require(ReplicatedStorage:WaitForChild("Combat"))
local Data = require(ReplicatedStorage:WaitForChild("BrainmonData"))
local Braindex = require(script.Parent.BraindexService)
local BaseService = require(script.Parent.BaseService)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local BattleStart = Remotes:WaitForChild("BattleStart") :: RemoteEvent
local BattleAction = Remotes:WaitForChild("BattleAction") :: RemoteEvent
local BattleSync = Remotes:WaitForChild("BattleSync") :: RemoteEvent

local B = {}
local rng = Random.new()

type Mon = {
	cfg: Configuration?,
	species: Data.Species,
	type: string, -- cache de species.type (o Combat.Damage usa pra STAB/efetividade)
	mutation: string,
	level: number,
	hp: number,
	maxHp: number,
	atk: number,
	def: number,
	spd: number,
	moves: { Combat.Move },
}
type Session = { player: Player, wildModel: Model?, world: number, team: { Mon }, active: number, wild: Mon, over: boolean, lines: { string } }

local sessions: { [Player]: Session } = {}

local function monFrom(sp: Data.Species, mutation: string, level: number, cfg: Configuration?): Mon
	local s = Combat.StatsAtLevel(sp, level)
	return { cfg = cfg, species = sp, type = sp.type, mutation = mutation, level = level, hp = s.hp, maxHp = s.hp, atk = s.atk, def = s.def, spd = s.spd, moves = Combat.MovesFor(sp) }
end

-- time do jogador = Brainmons do squad (InSquad). Retorna lista de Mon.
local function buildTeam(player: Player): { Mon }
	local team: { Mon } = {}
	local folder = player:FindFirstChild("Braindex")
	if not folder then
		return team
	end
	for _, cfg in folder:GetChildren() do
		if cfg:IsA("Configuration") and cfg:GetAttribute("InSquad") then
			local sp = Data.SpeciesById[cfg:GetAttribute("Species") :: string]
			if sp then
				table.insert(team, monFrom(sp, (cfg:GetAttribute("Mutation") :: string?) or "Normal", (cfg:GetAttribute("Level") :: number?) or 1, cfg :: Configuration))
			end
		end
	end
	return team
end

-- payload pro cliente (sem instancias): estado completo da batalha + falas do turno.
local function snapshot(s: Session, result: string?): any
	local a = s.team[s.active]
	local teamInfo = {}
	for _, m in s.team do
		table.insert(teamInfo, { name = m.species.name, hp = m.hp, maxHp = m.maxHp, fainted = m.hp <= 0 })
	end
	local moveNames = {}
	for _, mv in a.moves do
		table.insert(moveNames, mv.name)
	end
	return {
		wild = { name = s.wild.species.name, type = s.wild.species.type, rarity = Data.RarityOf(s.wild.species), mutation = s.wild.mutation, level = s.wild.level, hp = s.wild.hp, maxHp = s.wild.maxHp },
		you = { name = a.species.name, type = a.species.type, level = a.level, hp = a.hp, maxHp = a.maxHp, moves = moveNames },
		team = teamInfo,
		activeIndex = s.active,
		lines = s.lines,
		over = s.over,
		result = result,
	}
end

local function sync(s: Session, result: string?)
	BattleSync:FireClient(s.player, snapshot(s, result))
	s.lines = {}
end

local function line(s: Session, text: string)
	table.insert(s.lines, text)
end

-- um atacante usa um move no alvo. Retorna true se o alvo desmaiou.
local function attack(s: Session, atk: Mon, def: Mon, move: Combat.Move): boolean
	local dmg = Combat.Damage(atk, def, move, rng)
	def.hp = math.max(0, def.hp - dmg)
	line(s, `{atk.species.name} usou {move.name}!`)
	local eff = Combat.Effectiveness(move.type, def.species.type)
	if eff > 1 then
		line(s, "Foi super eficaz!")
	elseif eff < 1 then
		line(s, "Não foi muito eficaz...")
	end
	return def.hp <= 0
end

-- captura UNICA (usada pelo Bag da batalha E pelo mundo via B.TryCatch). true se capturou.
function B.TryCatch(player: Player, sp: Data.Species, mutation: string, world: number, hpFrac: number, ballKey: string): (boolean, Configuration?)
	local chance = Combat.CatchChance(sp, hpFrac, ballKey)
	if rng:NextNumber() > chance then
		return false, nil
	end
	local cfg = Braindex.AddRecord(player, sp.id, mutation, world)
	if cfg then
		BaseService.TryPlace(player, cfg)
	end
	return true, cfg
end

-- concede XP ao Brainmon ativo (sobe de nivel enquanto der). So quem derrota ganha.
local function awardXp(s: Session, m: Mon)
	if not m.cfg then
		return
	end
	local gained = Combat.XpReward(s.wild.species, s.wild.level)
	local xp = ((m.cfg:GetAttribute("Xp") :: number?) or 0) + gained
	local level = m.cfg:GetAttribute("Level") :: number? or 1
	line(s, `{m.species.name} ganhou {gained} XP!`)
	while xp >= Combat.XpToNext(level) do
		xp -= Combat.XpToNext(level)
		level += 1
		line(s, `{m.species.name} subiu pro nível {level}!`)
	end
	m.cfg:SetAttribute("Xp", xp)
	m.cfg:SetAttribute("Level", level)
end

local function finish(s: Session, result: string)
	s.over = true
	if (result == "win" or result == "caught") and s.wildModel and s.wildModel.Parent then
		s.wildModel:Destroy() -- selvagem sai do mundo
	end
	sync(s, result)
	sessions[s.player] = nil
end

-- o selvagem age (IA simples: move aleatorio). Retorna true se o jogador ativo desmaiou.
local function wildTurn(s: Session): boolean
	local a = s.team[s.active]
	local move = s.wild.moves[rng:NextInteger(1, #s.wild.moves)]
	return attack(s, s.wild, a, move)
end

-- jogador ativo desmaiou: tenta trocar automaticamente; se nao houver, perdeu.
local function onPlayerFaint(s: Session): boolean
	line(s, `{s.team[s.active].species.name} desmaiou!`)
	for i, m in s.team do
		if m.hp > 0 then
			s.active = i
			line(s, `Vai, {m.species.name}!`)
			return true
		end
	end
	return false -- time todo desmaiado
end

local function doFight(s: Session, moveIdx: number)
	local a = s.team[s.active]
	local move = a.moves[moveIdx]
	if not move then
		return
	end
	-- ordem por velocidade (empate: jogador primeiro)
	local playerFirst = a.spd >= s.wild.spd
	if playerFirst then
		if attack(s, a, s.wild, move) then
			line(s, `{s.wild.species.name} selvagem desmaiou!`)
			awardXp(s, a)
			return finish(s, "win")
		end
		if wildTurn(s) and not onPlayerFaint(s) then
			return finish(s, "lose")
		end
	else
		if wildTurn(s) and not onPlayerFaint(s) then
			return finish(s, "lose")
		end
		if attack(s, s.team[s.active], s.wild, move) then
			line(s, `{s.wild.species.name} selvagem desmaiou!`)
			awardXp(s, s.team[s.active])
			return finish(s, "win")
		end
	end
	sync(s)
end

local function doBag(s: Session, ballKey: string)
	if not Combat.Balls[ballKey] then
		ballKey = "Poke"
	end
	local hpFrac = s.wild.hp / s.wild.maxHp
	line(s, `Você jogou uma {Combat.Balls[ballKey].label}!`)
	local ok = B.TryCatch(s.player, s.wild.species, s.wild.mutation, s.world, hpFrac, ballKey)
	if ok then
		line(s, `{s.wild.species.name} foi capturado!`)
		return finish(s, "caught")
	end
	line(s, "Quase! O Brainmon escapou.")
	if wildTurn(s) and not onPlayerFaint(s) then
		return finish(s, "lose")
	end
	sync(s)
end

local function doRun(s: Session)
	local chance = 0.5 + (s.team[s.active].spd - s.wild.spd) * 0.01
	if rng:NextNumber() < math.clamp(chance, 0.2, 0.95) then
		line(s, "Você fugiu!")
		return finish(s, "fled")
	end
	line(s, "Não conseguiu fugir!")
	if wildTurn(s) and not onPlayerFaint(s) then
		return finish(s, "lose")
	end
	sync(s)
end

local function doSwitch(s: Session, idx: number)
	local m = s.team[idx]
	if not m or m.hp <= 0 or idx == s.active then
		return
	end
	s.active = idx
	line(s, `Vai, {m.species.name}!`)
	if wildTurn(s) and not onPlayerFaint(s) then
		return finish(s, "lose")
	end
	sync(s)
end

function B.StartWild(player: Player, wildModel: Instance?)
	if sessions[player] then
		return
	end
	if typeof(wildModel) ~= "Instance" or not wildModel:IsA("Model") then
		return
	end
	local speciesId = wildModel:GetAttribute("Species") :: string?
	local world = wildModel:GetAttribute("World") :: number?
	local sp = speciesId and Data.SpeciesById[speciesId]
	if not sp or not world then
		return
	end
	local team = buildTeam(player)
	if #team == 0 then
		BattleSync:FireClient(player, { noTeam = true }) -- sem Brainmon no squad
		return
	end
	local wildLevel = math.max(1, world * 4 + rng:NextInteger(-2, 3))
	local s: Session = {
		player = player,
		wildModel = wildModel,
		world = world,
		team = team,
		active = 1,
		wild = monFrom(sp, (wildModel:GetAttribute("Mutation") :: string?) or "Normal", wildLevel, nil),
		over = false,
		lines = { `Um {sp.name} selvagem apareceu!` },
	}
	sessions[player] = s
	sync(s)
end

local function onAction(player: Player, action: any)
	local s = sessions[player]
	if not s or s.over or typeof(action) ~= "table" then
		return
	end
	local kind = action.kind
	if kind == "Fight" and typeof(action.move) == "number" then
		doFight(s, action.move)
	elseif kind == "Bag" and typeof(action.ball) == "string" then
		doBag(s, action.ball)
	elseif kind == "Run" then
		doRun(s)
	elseif kind == "Switch" and typeof(action.index) == "number" then
		doSwitch(s, action.index)
	end
end

function B.Init()
	BattleStart.OnServerEvent:Connect(B.StartWild)
	BattleAction.OnServerEvent:Connect(onAction)
	Players.PlayerRemoving:Connect(function(p: Player)
		sessions[p] = nil
	end)
end

return B
