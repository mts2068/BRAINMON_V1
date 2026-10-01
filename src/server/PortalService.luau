--!strict
-- PortalService: viagem entre hub e mundos (guia F0.9 "GeoHop": Part + ProximityPrompt + debounce de 2 s).
-- O SERVIDOR e a autoridade: valida requisito (especies do mundo anterior + BC), cobra, teleporta. O cliente so pede e exibe.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage:WaitForChild("BrainmonData"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local WorldTravel = Remotes:WaitForChild("WorldTravel") :: RemoteEvent
local WorldState = Remotes:WaitForChild("WorldState") :: RemoteEvent
local WorldBanner = Remotes:WaitForChild("WorldBanner") :: RemoteEvent

local S = {}
local map: any
local lastTravel: { [number]: number } = {}

-- [confirmar] integrar com BraindexService/ShopService quando existirem no projeto novo (decisao: renda e preco passam por la).
local function bc(player: Player): number
	return (player:GetAttribute("BC") :: number?) or 0
end

local function unlocked(player: Player): number
	return (player:GetAttribute("WorldsUnlocked") :: number?) or 1
end

-- especies distintas do mundo `world` que o jogador possui (indivíduos = Configuration em player.Braindex)
local function owned(player: Player, world: number): number
	local folder = player:FindFirstChild("Braindex")
	if not folder then
		return 0
	end
	local seen: { [string]: boolean } = {}
	for _, cfg in folder:GetChildren() do
		local sp = Data.SpeciesById[cfg:GetAttribute("Species") :: string]
		if sp and sp.world == world then
			seen[sp.id] = true
		end
	end
	local n = 0
	for _ in seen do
		n += 1
	end
	return n
end

local function pushState(player: Player)
	local counts = {}
	for i = 1, #Data.Worlds do
		counts[i] = owned(player, i)
	end
	WorldState:FireClient(player, { unlocked = unlocked(player), world = player:GetAttribute("World") or 0, bc = bc(player), owned = counts })
end

local function notice(player: Player, text: string)
	WorldBanner:FireClient(player, "Notice", text)
end

function S.Travel(player: Player, idx: unknown): boolean
	if typeof(idx) ~= "number" or idx % 1 ~= 0 or idx < 0 or idx > #Data.Worlds then
		return false -- valida tipo e faixa: o cliente nao e confiavel
	end
	local now = os.clock()
	if now - (lastTravel[player.UserId] or -math.huge) < Data.Config.TravelDebounce then
		return false
	end
	if not (player.Character and player.Character:FindFirstChild("HumanoidRootPart")) then
		return false
	end

	local dest: CFrame, name: string
	if idx == 0 then
		dest, name = map.hubSpawn, "Nexus Brainmon"
	else
		local un = unlocked(player)
		local w = Data.Worlds[idx]
		if idx > un then
			if idx ~= un + 1 then
				notice(player, "Libere o mundo anterior primeiro.")
				return false
			end
			local have = owned(player, idx - 1)
			if bc(player) < w.gate.bc or have < w.gate.species then
				notice(player, "Requisito: " .. Data.GateText(idx, have, bc(player)))
				return false
			end
			player:SetAttribute("BC", bc(player) - w.gate.bc) -- ponytail: cobranca direta; ShopService vira a autoridade quando existir
			player:SetAttribute("WorldsUnlocked", idx)
		end
		dest, name = map.worlds[idx].spawn, w.name
	end

	lastTravel[player.UserId] = now
	WorldBanner:FireClient(player, "FadeOut")
	task.wait(0.45)
	local char = player.Character
	if not char or not char.Parent then
		return false
	end
	char:PivotTo(dest + Vector3.new(0, 3, 0))
	player:SetAttribute("World", idx)
	WorldBanner:FireClient(player, "FadeIn", name)
	pushState(player)
	return true
end

local function onPlayer(player: Player)
	if Data.Config.DevUnlockAll then
		player:SetAttribute("WorldsUnlocked", #Data.Worlds)
	else
		player:SetAttribute("WorldsUnlocked", 1)
	end
	player:SetAttribute("World", 0)
	player.CharacterAdded:Connect(function(char)
		local hrp = char:WaitForChild("HumanoidRootPart", 10)
		if not hrp then
			return
		end
		local idx = (player:GetAttribute("World") :: number?) or 0
		local dest = if idx == 0 then map.hubSpawn else map.worlds[idx].spawn
		char:PivotTo(dest + Vector3.new(0, 3, 0)) -- respawn no mesmo mundo
	end)
	pushState(player)
end

function S.Init(builtMap: any)
	map = builtMap
	for _, d in map.folder:GetDescendants() do
		if d:IsA("ProximityPrompt") then
			local pad = d.Parent :: Instance
			local kind, world = pad:GetAttribute("Kind"), pad:GetAttribute("World")
			if kind == "Enter" then
				d.Triggered:Connect(function(player)
					S.Travel(player, world)
				end)
			elseif kind == "Exit" then
				d.Triggered:Connect(function(player)
					S.Travel(player, 0)
				end)
			end
		end
	end
	WorldTravel.OnServerEvent:Connect(function(player, idx)
		S.Travel(player, idx)
	end)
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in Players:GetPlayers() do
		task.spawn(onPlayer, p)
	end
	Players.PlayerRemoving:Connect(function(p)
		lastTravel[p.UserId] = nil
	end)
end

return S
