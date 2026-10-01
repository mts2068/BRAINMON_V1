--!strict
-- Bootstrap: ordem explicita de inicializacao (guia 5.4). Dados -> Modelos -> Mapa -> Portais -> Selvagens.
-- Futuro (nesta ordem): DataService -> BraindexService -> ShopService -> BaseService -> StealService -> BattleService.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Garante os Remotes ANTES de requerer os servicos (robustez: se o project.json nao sincronizou um remote novo,
-- cria aqui pra o WaitForChild dos servicos nao travar o boot inteiro). Fonte unica da lista de remotes.
do
	local remotes = ReplicatedStorage:FindFirstChild("Remotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "Remotes"
		remotes.Parent = ReplicatedStorage
	end
	local NEEDED: { [string]: string } = {
		WorldTravel = "RemoteEvent", WorldState = "RemoteEvent", WorldBanner = "RemoteEvent",
		ShopBuy = "RemoteFunction", SellBrainmon = "RemoteFunction", Rebirth = "RemoteFunction", ShopReveal = "RemoteEvent",
		BattleStart = "RemoteEvent", BattleAction = "RemoteEvent", BattleSync = "RemoteEvent",
	}
	for name, class in NEEDED do
		if not remotes:FindFirstChild(name) then
			local r = Instance.new(class)
			r.Name = name
			r.Parent = remotes
		end
	end
end

local Factory = require(ReplicatedStorage.BrainmonFactory)
local BiomeBuilder = require(script.Parent.BiomeBuilder)
local BaseBuilder = require(script.Parent.BaseBuilder)
local BraindexService = require(script.Parent.BraindexService)
local BaseService = require(script.Parent.BaseService)
local ShopService = require(script.Parent.ShopService)
local SellService = require(script.Parent.SellService)
local RebirthService = require(script.Parent.RebirthService)
local VipService = require(script.Parent.VipService)
local BattleService = require(script.Parent.BattleService)
local PortalService = require(script.Parent.PortalService)
local WildSpawner = require(script.Parent.WildSpawner)
local EventService = require(script.Parent.EventService)

local real, fake = Factory.Preload()
print(`[Bootstrap] modelos: {real} reais, {fake} placeholders`)

-- sobras do template do Studio (o mapa e todo gerado): remove para nao brigar com o chao gerado
for _, n in { "Baseplate", "SpawnLocation" } do
	local o = workspace:FindFirstChild(n)
	if o then
		o:Destroy()
	end
end

BraindexService.Init() -- Braindex + BC + renda passiva (soma os Placed na base)
local map = BiomeBuilder.Build()
local bases = BaseBuilder.Build()
BaseService.Init(bases) -- aloca plots e expoe os capturados (antes dos selvagens, que colocam na base ao capturar)
print(`[BaseBuilder] distrito de bases: {#bases.plots} plots`)
ShopService.Init() -- loja de ovos: compra gasta BC e cria o Brainmon (usa AddRecord + TryPlace)
SellService.Init() -- NPC "Vender Brainmon": troca individuo por BC (libera o pad + destroi o cfg)
RebirthService.Init() -- reseta BC por +multiplicador/+sorte; BaseService/ShopService leem CashMult/ShyneChance daqui
VipService.Init() -- posse dos gamepasses VIP -> attributes que o RebirthService soma no multiplicador/sorte
BattleService.Init() -- batalha por turnos contra selvagem (F2) + captura unica (B.TryCatch)
PortalService.Init(map)
WildSpawner.Start(map)
EventService.Init(map) -- evento periodico de Brainmon raro num mundo aleatorio; banner no hub durante o evento
print("[Bootstrap] BRAINMON pronto")
