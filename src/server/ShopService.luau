--!strict
-- ShopService: UNICA autoridade de compra (Passo 3). Cliente so pede ShopBuy:InvokeServer(eggId) e exibe.
-- So vende OVOS: gasta BC (via BraindexService) e sorteia um Brainmon do mundo do ovo (raridade = raridade do mundo).
-- Sem persistencia (DataStore ainda nao existe). O cliente NUNCA envia preco, mundo ou resultado.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Data = require(ReplicatedStorage:WaitForChild("BrainmonData"))
local Braindex = require(script.Parent.BraindexService)
local BaseService = require(script.Parent.BaseService)
local Rebirth = require(script.Parent.RebirthService)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ShopBuy = Remotes:WaitForChild("ShopBuy") :: RemoteFunction
local ShopReveal = Remotes:WaitForChild("ShopReveal") :: RemoteEvent

local S = {}
local rng = Random.new()

local busy: { [Player]: boolean } = {} -- trava anti duplo-gasto durante a compra
local lastBuy: { [Player]: number } = {} -- rate limit por jogador

type Result = { ok: boolean, code: string, payload: any? }

-- Debita BC sem yield entre checar e debitar (anti duplo-gasto). true se debitou.
local function charge(player: Player, amount: number): boolean
	local bal = (player:GetAttribute("BC") :: number?) or 0
	if bal < amount then
		return false
	end
	Braindex.AddBC(player, -amount)
	return true
end

-- Sorteia e entrega um Brainmon do mundo (mesma regra do WildSpawner). Retorna payload cosmetico ou nil.
local function grantEgg(player: Player, world: number): { Species: string, Mutation: string, Rarity: string }?
	local pool = Data.SpeciesByWorld[world]
	if not pool or #pool == 0 then
		return nil
	end
	local sp = pool[rng:NextInteger(1, #pool)] -- uniforme; TODO: pesos por especie se quiser raras dentro do mundo
	local mutation = Data.RollMutation(rng, Rebirth.Luck(player)) -- sorte de mutation cresce com rebirth
	local cfg = Braindex.AddRecord(player, sp.id, mutation, world)
	if not cfg then
		return nil
	end
	BaseService.TryPlace(player, cfg) -- auto-expoe na base se houver pad livre (igual a captura)
	return { Species = sp.id, Mutation = mutation, Rarity = Data.RarityOf(sp) }
end

-- Starter Pack (dev product): BC + 1 brainmon cosmico (Mystic + Arcoiris) + N ovos de fogo (Forja).
local function grantStarterPack(player: Player): boolean
	local sp = Data.Robux.StarterPack
	Braindex.AddBC(player, sp.bc)
	local cosmicPool = Data.SpeciesByWorld[sp.cosmic.world]
	if cosmicPool and #cosmicPool > 0 then
		local s = cosmicPool[rng:NextInteger(1, #cosmicPool)]
		local cfg = Braindex.AddRecord(player, s.id, sp.cosmic.mutation, sp.cosmic.world)
		if cfg then
			BaseService.TryPlace(player, cfg)
		end
	end
	for _ = 1, sp.fire.count do
		grantEgg(player, sp.fire.world)
	end
	return true
end

-- Chamada pelo remote ShopBuy. `eggId` vem do cliente => NAO confiavel.
function S.Buy(player: Player, eggId: unknown): Result
	if typeof(eggId) ~= "string" or #eggId > 32 then
		return { ok = false, code = "BadArgs" }
	end
	local now = os.clock()
	local prev = lastBuy[player]
	if prev and now - prev < 0.4 then
		return { ok = false, code = "RateLimited" }
	end
	if busy[player] then
		return { ok = false, code = "Busy" }
	end
	local egg = Data.Eggs[eggId]
	if not egg or egg.price <= 0 then
		return { ok = false, code = "UnknownEgg" }
	end

	lastBuy[player] = now
	busy[player] = true
	local result: Result
	if not charge(player, egg.price) then
		result = { ok = false, code = "NotEnough" }
	else
		local payload = grantEgg(player, egg.world)
		if payload then
			result = { ok = true, code = "OK", payload = payload }
		else
			Braindex.AddBC(player, egg.price) -- entrega falhou: devolve o BC
			result = { ok = false, code = "GrantFailed" }
		end
	end
	busy[player] = nil
	return result
end

-- Robux: mundo do ovo cujo dev product id bate (0 = nao configurado).
local function worldByProduct(productId: number): number?
	for _, egg in Data.Eggs do
		if egg.robux > 0 and egg.robux == productId then
			return egg.world
		end
	end
	return nil
end

function S.Init()
	ShopBuy.OnServerInvoke = function(player: Player, eggId: unknown)
		return S.Buy(player, eggId)
	end
	Players.PlayerRemoving:Connect(function(p: Player)
		busy[p] = nil
		lastBuy[p] = nil
	end)

	-- Robux (ovos raros). ponytail: sem DataStore nao guarda PurchaseId -> risco baixo de regrant em crash
	-- (ovo e consumivel, so beneficia o jogador). Trocar por idempotente quando existir persistencia.
	MarketplaceService.ProcessReceipt = function(receipt)
		local player = Players:GetPlayerByUserId(receipt.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local starter = Data.Robux.StarterPack
		if starter.product > 0 and receipt.ProductId == starter.product then
			return if grantStarterPack(player) then Enum.ProductPurchaseDecision.PurchaseGranted else Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local world = worldByProduct(receipt.ProductId)
		if world then
			local payload = grantEgg(player, world)
			if payload then
				ShopReveal:FireClient(player, payload) -- cliente abre o reveal
				return Enum.ProductPurchaseDecision.PurchaseGranted
			end
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
end

return S
