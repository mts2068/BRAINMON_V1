--!strict
-- SellService: NPC "Vender Brainmon". Troca UM individuo do player.Braindex por BC (pagamento unico, nao renda).
-- Cliente manda a Configuration (replicada); servidor revalida posse, calcula o valor (Data.SellValue),
-- remove da base (libera o pad) e do Braindex, e credita BC. Cliente nunca envia o valor.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage:WaitForChild("BrainmonData"))
local Braindex = require(script.Parent.BraindexService)
local BaseService = require(script.Parent.BaseService)

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local SellBrainmon = Remotes:WaitForChild("SellBrainmon") :: RemoteFunction

local S = {}
local lastSell: { [Player]: number } = {}

type Result = { ok: boolean, code: string, value: number? }

function S.Sell(player: Player, cfg: unknown): Result
	if typeof(cfg) ~= "Instance" then
		return { ok = false, code = "BadArgs" }
	end
	local inst = cfg :: Instance
	if not inst:IsA("Configuration") then
		return { ok = false, code = "BadArgs" }
	end
	local folder = player:FindFirstChild("Braindex")
	if not folder or inst.Parent ~= folder then
		return { ok = false, code = "NotOwner" } -- so o que e do jogador e esta no Braindex
	end
	local now = os.clock()
	local prev = lastSell[player]
	if prev and now - prev < 0.3 then
		return { ok = false, code = "RateLimited" }
	end
	lastSell[player] = now

	local conf = inst :: Configuration
	local value = Data.SellValue(conf:GetAttribute("Species") :: string, conf:GetAttribute("Mutation") :: string?)
	BaseService.RemovePlaced(player, conf) -- libera o pad se estava exposto (ok se nao estava)
	conf:Destroy() -- tira do Braindex antes de creditar (sem yield entre remover e pagar)
	if value > 0 then
		Braindex.AddBC(player, value)
	end
	return { ok = true, code = "OK", value = value }
end

function S.Init()
	SellBrainmon.OnServerInvoke = function(player: Player, cfg: unknown)
		return S.Sell(player, cfg)
	end
	Players.PlayerRemoving:Connect(function(p: Player)
		lastSell[p] = nil
	end)
end

return S
