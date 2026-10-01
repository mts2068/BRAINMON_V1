--!strict
-- BraindexService: cada captura vira um INDIVIDUO (Configuration sob player.Braindex), nao um contador.
-- Toda renda passa por GetRecordIncome. Renda passiva = soma do squad (InSquad) em UM loop 1x/s (guia 3.5: sem thread por bicho).
-- BC vive como atributo do Player (fonte; PortalService/ShopService leem daqui) e e espelhado em leaderstats para o playerlist.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage:WaitForChild("BrainmonData"))

local B = {}

local function braindex(player: Player): Folder?
	return player:FindFirstChild("Braindex") :: Folder?
end

local function squadCount(folder: Folder): number
	local n = 0
	for _, c in folder:GetChildren() do
		if c:GetAttribute("InSquad") then
			n += 1
		end
	end
	return n
end

local function setBC(player: Player, amount: number)
	player:SetAttribute("BC", amount)
	local ls = player:FindFirstChild("leaderstats")
	local bc = ls and ls:FindFirstChild("BC")
	if bc then
		(bc :: IntValue).Value = math.floor(amount)
	end
end

-- credita BC (usado pelo BaseService ao COLETAR a renda acumulada na base). Retorna o novo saldo.
function B.AddBC(player: Player, amount: number): number
	local novo = ((player:GetAttribute("BC") :: number?) or 0) + amount
	setBC(player, novo)
	return novo
end

-- BC/s de um unico individuo (unica autoridade de renda).
function B.GetRecordIncome(cfg: Instance): number
	local sp = Data.SpeciesById[cfg:GetAttribute("Species") :: string]
	if not sp then
		return 0
	end
	local base = Data.RarityInfo[Data.RarityOf(sp)].income
	return base * Data.MutationMult(cfg:GetAttribute("Mutation") :: string?)
end

-- Cria um individuo a partir de uma captura/ovo. Entra no squad se houver vaga. Retorna a Configuration.
function B.AddRecord(player: Player, speciesId: string, mutation: string?, world: number?): Configuration?
	local sp = Data.SpeciesById[speciesId]
	local folder = braindex(player)
	if not sp or not folder then
		return nil
	end
	local cfg = Instance.new("Configuration")
	cfg.Name = speciesId
	cfg:SetAttribute("Species", speciesId)
	cfg:SetAttribute("Mutation", mutation or "Normal")
	cfg:SetAttribute("Level", 1)
	cfg:SetAttribute("Xp", 0)
	cfg:SetAttribute("Biome", world or sp.world)
	cfg:SetAttribute("InSquad", squadCount(folder) < Data.Config.SquadSize) -- time de batalha (futuro); nao rende
	cfg:SetAttribute("Placed", false) -- renda vem de quem esta na base (BaseService), nao do squad
	cfg.Parent = folder
	return cfg
end

local function onPlayer(player: Player)
	if not player:FindFirstChild("Braindex") then
		local f = Instance.new("Folder")
		f.Name = "Braindex"
		f.Parent = player
	end
	if not player:FindFirstChild("leaderstats") then
		local ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		ls.Parent = player
		local bc = Instance.new("IntValue")
		bc.Name = "BC"
		bc.Parent = ls
	end
	setBC(player, (player:GetAttribute("BC") :: number?) or Data.Config.StartBC)
end

function B.Init()
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		task.spawn(onPlayer, p)
	end
	-- a renda agora ACUMULA na base e e sacada na Collect Zone (BaseService); aqui nao ha mais loop de credito.
end

return B
