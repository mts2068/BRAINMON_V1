--!strict
-- WildSpawner: Brainmons selvagens andando nas zonas de cada mundo (so mostra os modelos; captura/trap vem na proxima fase).
-- Regras herdadas do projeto antigo: passo limitado pelo que falta ate o alvo e por dt <= 0.1 (sem saltos),
-- clamp pela bounding box (nao pelo pivo) para criatura grande nao escapar pela cerca.
local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Data = require(ReplicatedStorage:WaitForChild("BrainmonData"))
local Factory = require(ReplicatedStorage:WaitForChild("BrainmonFactory"))
local BattleService = require(script.Parent.BattleService)

type Wild = {
	model: Model,
	pos: Vector3,
	target: Vector3?,
	pause: number,
	yaw: number,
	phase: number,
	speed: number,
	half: Vector3,
	zone: { center: Vector3, size: Vector3 },
	t: number,
	world: number,
	info: any,
	folder: Folder,
	caught: boolean?,
}

local W = {}
local wilds: { Wild } = {}
local rng = Random.new()

local function randomPoint(w: Wild): Vector3
	local hx = math.max(w.zone.size.X / 2 - math.max(w.half.X, w.half.Z), 1)
	local hz = math.max(w.zone.size.Z / 2 - math.max(w.half.X, w.half.Z), 1)
	for _ = 1, 8 do
		local p = w.zone.center + Vector3.new(rng:NextNumber(-hx, hx), 0, rng:NextNumber(-hz, hz))
		if (p - w.zone.center).Magnitude > 52 then -- longe do marco central
			return p
		end
	end
	return w.zone.center + Vector3.new(hx, 0, 0)
end

local function label(root: BasePart, sp: Data.Species, rarity: string, mutation: string, halfY: number)
	local mut = Data.Mutations[mutation]
	local isMut = mutation ~= "Normal" and mut ~= nil
	local gui = Instance.new("BillboardGui")
	gui.Adornee = root
	gui.Size = UDim2.fromOffset(220, 46)
	gui.StudsOffsetWorldSpace = Vector3.new(0, halfY + 2.5, 0)
	gui.MaxDistance = 90
	gui.ResetOnSpawn = false
	gui.Parent = root
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromScale(1, 0.58)
	name.Font = Enum.Font.GothamBold
	name.TextScaled = true
	name.TextColor3 = if isMut then mut.color else Data.RarityInfo[rarity].color
	name.TextStrokeTransparency = 0
	name.Text = (if isMut then mut.label .. " " else "") .. sp.name
	name.Parent = gui
	local ty = name:Clone()
	ty.Position = UDim2.fromScale(0, 0.6)
	ty.Size = UDim2.fromScale(1, 0.4)
	ty.TextColor3 = Data.Types[sp.type] or Color3.new(1, 1, 1)
	ty.Text = `{sp.type} · {rarity}`
	ty.Parent = gui
end

local spawnOne: (world: number, info: any, folder: Folder) -> ()

-- Quando um selvagem some (capturado/derrotado na batalha, que destroi o modelo): tira da lista e repoe a populacao.
local function onWildRemoved(w: Wild)
	local i = table.find(wilds, w)
	if i then
		table.remove(wilds, i)
	end
	if w.folder.Parent then
		spawnOne(w.world, w.info, w.folder)
	end
end

function spawnOne(world: number, info: any, folder: Folder)
	local pool = Data.SpeciesByWorld[world]
	if not pool or #pool == 0 then
		return
	end
	local sp = pool[rng:NextInteger(1, #pool)]
	local mutation = Data.RollMutation(rng)
	local rarity = Data.RarityOf(sp)
	local model = Factory.Create(sp.id, mutation)
	local root = model.PrimaryPart :: BasePart
	local half = root.Size / 2
	local w: Wild = {
		model = model, pos = info.zone.center, target = nil, pause = rng:NextNumber(0, 3), yaw = rng:NextNumber(0, 6.28),
		phase = rng:NextNumber(0, 6.28), speed = rng:NextNumber(3, 5), half = half, zone = info.zone, t = 0,
		world = world, info = info, folder = folder,
	}
	w.pos = randomPoint(w)
	model.Name = sp.id
	model:SetAttribute("World", world)
	model:SetAttribute("SpeciesNumber", sp.n)
	model:SetAttribute("Species", sp.id)
	model:SetAttribute("Mutation", mutation)
	model:SetAttribute("Rarity", rarity)
	model:SetAttribute("Type", sp.type)
	CollectionService:AddTag(model, "Wild")
	label(root, sp, rarity, mutation, half.Y)
	local mut = Data.Mutations[mutation]
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Batalhar"
	prompt.ObjectText = (if mutation ~= "Normal" and mut then mut.label .. " " else "") .. sp.name
	prompt.HoldDuration = 0.4
	prompt.MaxActivationDistance = 14
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt.Triggered:Connect(function(player)
		BattleService.StartWild(player, model) -- abre a batalha; captura = jogar ball no Bag
	end)
	-- captura direta no mundo (HP cheio = dificil). Mesma captura unica da batalha. Por ora Poke Ball infinita (bag = F3).
	local ballPrompt = Instance.new("ProximityPrompt")
	ballPrompt.ActionText = "Jogar Poké Ball"
	ballPrompt.ObjectText = sp.name
	ballPrompt.KeyboardKeyCode = Enum.KeyCode.G
	ballPrompt.HoldDuration = 0.5
	ballPrompt.MaxActivationDistance = 14
	ballPrompt.RequiresLineOfSight = false
	ballPrompt.Parent = root
	ballPrompt.Triggered:Connect(function(player)
		local caught = BattleService.TryCatch(player, sp, mutation, world, 1, "Poke")
		if caught and model.Parent then
			model:Destroy() -- Destroying -> repoe a populacao
		end
	end)
	model:PivotTo(CFrame.new(w.pos.X, half.Y, w.pos.Z) * Factory.FacingFix)
	model.Parent = folder
	table.insert(wilds, w)
	model.Destroying:Once(function()
		onWildRemoved(w)
	end)
end

local function step(w: Wild, dt: number)
	w.t += dt
	if w.pause > 0 then
		w.pause -= dt
	elseif not w.target then
		w.target = randomPoint(w)
	else
		local to = w.target - w.pos
		local dist = to.Magnitude
		if dist < 0.6 then
			w.target = nil
			w.pause = rng:NextNumber(1.5, 4)
		else
			w.pos += to.Unit * math.min(w.speed * dt, dist) -- passo limitado ao que falta
			w.yaw = math.atan2(-to.X, -to.Z)
		end
	end
	local m = math.max(w.half.X, w.half.Z)
	w.pos = Vector3.new(
		math.clamp(w.pos.X, w.zone.center.X - w.zone.size.X / 2 + m, w.zone.center.X + w.zone.size.X / 2 - m),
		0,
		math.clamp(w.pos.Z, w.zone.center.Z - w.zone.size.Z / 2 + m, w.zone.center.Z + w.zone.size.Z / 2 - m)
	)
	-- idle (equivalente ao "Idle" dos GLBs, que o Roblox nao importa): respira subindo/descendo e balanca de leve
	local bob = math.sin(w.t * 2.2 + w.phase) * 0.12
	local roll = math.sin(w.t * 1.4 + w.phase) * math.rad(1.5)
	w.model:PivotTo(CFrame.new(w.pos.X, w.half.Y + bob, w.pos.Z) * CFrame.Angles(0, w.yaw, roll) * Factory.FacingFix)
end

function W.Start(map: any)
	local folder = Instance.new("Folder")
	folder.Name = "Wild"
	folder.Parent = Workspace
	for i = 1, #Data.Worlds do
		for _ = 1, Data.WildCount(i) do
			spawnOne(i, map.worlds[i], folder)
		end
	end
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += math.min(dt, 0.1) -- sem salto quando o servidor engasga
		if acc < 1 / 15 then
			return
		end
		for _, w in wilds do
			if w.model.Parent then
				step(w, acc)
			end
		end
		acc = 0
	end)
	print(`[WildSpawner] {#wilds} selvagens (por raridade do mundo)`)
end

return W
