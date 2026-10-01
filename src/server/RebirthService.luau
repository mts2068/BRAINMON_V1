--!strict
-- RebirthService: reseta BC em troca de bonus PERMANENTES (multiplicador de coleta + sorte de ovo). Mantem o Braindex.
-- Requisito: BC >= custo (cresce por rebirth) E N especies DISTINTAS no Braindex (cresce por rebirth).
-- Autoridade: so aqui mexe no attribute "Rebirths". BaseService/ShopService LEEM CashMult/ShyneChance daqui.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage:WaitForChild("BrainmonData"))
local Braindex = require(script.Parent.BraindexService)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local RebirthRF = Remotes:WaitForChild("Rebirth") :: RemoteFunction

local R = {}
local busy: { [Player]: boolean } = {}

local function count(player: Player): number
	return (player:GetAttribute("Rebirths") :: number?) or 0
end

-- bonus de VIP (attributes marcados pelo VipService). VipUnlimited tem prioridade.
local function vip(player: Player, field: string): number
	if player:GetAttribute("VipUnlimited") then
		return Data.Robux.VipUnlimited[field]
	elseif player:GetAttribute("Vip") then
		return Data.Robux.Vip[field]
	end
	return 0
end

-- multiplicador de coleta efetivo (BaseService usa no lugar de Data.Config.CashMulti)
function R.CashMult(player: Player): number
	return Data.Config.CashMulti + count(player) * Data.Config.RebirthCashInc + vip(player, "cashBonus")
end

-- multiplicador de SORTE de mutation em OVO (1 = base; sobe por rebirth e VIP). ShopService passa pro RollMutation.
function R.Luck(player: Player): number
	return 1 + count(player) * Data.Config.RebirthLuckMult + vip(player, "luckBonus")
end

function R.Cost(n: number): number
	return math.floor(Data.Config.RebirthBaseCost * (Data.Config.RebirthCostMult ^ n))
end

function R.SpeciesNeeded(n: number): number
	return Data.Config.RebirthBaseSpecies + n * Data.Config.RebirthSpeciesInc
end

function R.DistinctSpecies(player: Player): number
	local folder = player:FindFirstChild("Braindex")
	if not folder then
		return 0
	end
	local seen: { [string]: boolean } = {}
	for _, cfg in folder:GetChildren() do
		local s = cfg:GetAttribute("Species")
		if typeof(s) == "string" then
			seen[s] = true
		end
	end
	local n = 0
	for _ in seen do
		n += 1
	end
	return n
end

type Result = { ok: boolean, code: string, rebirths: number? }

function R.Do(player: Player): Result
	if busy[player] then
		return { ok = false, code = "Busy" }
	end
	busy[player] = true
	local result: Result
	local n = count(player)
	if R.DistinctSpecies(player) < R.SpeciesNeeded(n) then
		result = { ok = false, code = "NeedSpecies" }
	else
		local cost = R.Cost(n)
		local bal = (player:GetAttribute("BC") :: number?) or 0
		if bal < cost then
			result = { ok = false, code = "NotEnough" }
		else
			Braindex.AddBC(player, -bal) -- reseta BC (mantem o Braindex)
			player:SetAttribute("Rebirths", n + 1)
			result = { ok = true, code = "OK", rebirths = n + 1 }
		end
	end
	busy[player] = nil
	return result
end

local function ensure(p: Player)
	if p:GetAttribute("Rebirths") == nil then
		p:SetAttribute("Rebirths", 0)
	end
end

function R.Init()
	Players.PlayerAdded:Connect(ensure)
	for _, p in Players:GetPlayers() do
		ensure(p)
	end
	Players.PlayerRemoving:Connect(function(p: Player)
		busy[p] = nil
	end)
	RebirthRF.OnServerInvoke = function(player: Player)
		return R.Do(player)
	end
end

return R
