--!strict
-- EventService: de tempos em tempos (intervalo aleatorio) um Brainmon raro (Epic -> Mystic), em versao Shyne,
-- aparece no hub por uma janela de tempo e pode ser capturado. O banner acima do cristal SO aparece durante o evento.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Data = require(ReplicatedStorage:WaitForChild("BrainmonData"))
local Factory = require(ReplicatedStorage:WaitForChild("BrainmonFactory"))
local Braindex = require(script.Parent.BraindexService)
local BaseService = require(script.Parent.BaseService)

local E = {}

local INTERVAL_MIN, INTERVAL_MAX = 120, 300 -- s entre eventos (2-5 min; ajustavel)
local DURATION = 90 -- s que o bicho fica disponivel
local RARITY_WEIGHTS = { { "Epic", 65 }, { "Mystic", 35 } } -- do epico ao mais raro

local rng = Random.new()
local mapRef: any = nil -- setado no Init; usado pra achar a zona do mundo do evento

local function randomInZone(zone: any): Vector3
	local hx = math.max(zone.size.X / 2 - 12, 1)
	local hz = math.max(zone.size.Z / 2 - 12, 1)
	return zone.center + Vector3.new(rng:NextNumber(-hx, hx), 0, rng:NextNumber(-hz, hz))
end
local banner: BillboardGui? = nil
local bannerText: TextLabel? = nil
local active = false

local function setBanner(text: string?)
	if banner then
		banner.Enabled = text ~= nil
	end
	if bannerText and text then
		bannerText.Text = text
	end
end

local function pickRarity(): string
	local total = 0
	for _, e in RARITY_WEIGHTS do
		total += e[2]
	end
	local r = rng:NextNumber() * total
	for _, e in RARITY_WEIGHTS do
		r -= e[2]
		if r <= 0 then
			return e[1]
		end
	end
	return "Epic"
end

local function speciesOf(rarity: string): Data.Species?
	local pool = {}
	for _, sp in Data.Species do
		if Data.RarityOf(sp) == rarity then
			table.insert(pool, sp)
		end
	end
	if #pool == 0 then
		return nil
	end
	return pool[rng:NextInteger(1, #pool)]
end

local function runEvent()
	if active then
		return
	end
	local rarity = pickRarity()
	local sp = speciesOf(rarity)
	if not sp then
		return
	end
	local info = mapRef and mapRef.worlds and mapRef.worlds[sp.world]
	if not info then
		return -- sem o mapa/zona nao spawna
	end
	active = true
	local mutation = ({ "Galaxia", "Hacker", "Arcoiris" })[rng:NextInteger(1, 3)] -- evento = mutation alta garantida
	local model = Factory.Create(sp.id, mutation)
	local root = model.PrimaryPart :: BasePart
	local half = root.Size / 2
	model.Name = "Event_" .. sp.id
	model:SetAttribute("Species", sp.id)
	model:SetAttribute("Mutation", mutation)
	local pos = randomInZone(info.zone) -- ponto aleatorio no mundo do bicho
	model:PivotTo(CFrame.new(pos.X, half.Y, pos.Z) * Factory.FacingFix)
	local light = Instance.new("PointLight")
	light.Color = Data.Mutations[mutation].color
	light.Range = 34
	light.Brightness = 4
	light.Parent = root
	model.Parent = Workspace

	local caught = false
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Capturar EVENTO"
	prompt.ObjectText = Data.Mutations[mutation].label .. " " .. sp.name
	prompt.HoldDuration = 1.2
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.Parent = root
	prompt.Triggered:Connect(function(player)
		if caught then
			return
		end
		caught = true
		local cfg = Braindex.AddRecord(player, sp.id, mutation, sp.world)
		if cfg then
			BaseService.TryPlace(player, cfg)
		end
		if model.Parent then
			model:Destroy()
		end
		setBanner(`✨ {player.Name} capturou {Data.Config.StarGlyph} {sp.name}!`)
		task.wait(5)
		if not active then
			setBanner(nil)
		end
	end)

	-- countdown no banner enquanto disponivel
	local t0 = os.clock()
	while not caught and model.Parent and os.clock() - t0 < DURATION do
		local left = math.ceil(DURATION - (os.clock() - t0))
		setBanner(`{Data.Config.StarGlyph} {string.upper(sp.name)} em {Data.Worlds[sp.world].name} — {left}s`)
		task.wait(1)
	end
	if not caught then
		if model.Parent then
			model:Destroy()
		end
		setBanner(nil)
	end
	active = false
end

-- dispara um evento agora (teste)
function E.Trigger()
	task.spawn(runEvent)
end

function E.Init(map: any)
	mapRef = map
	local hub = map.folder:FindFirstChild("Hub")
	local anchor = hub and hub:FindFirstChild("EventBanner")
	banner = (anchor and anchor:FindFirstChild("Event")) :: BillboardGui?
	local frame = banner and banner:FindFirstChild("Frame")
	bannerText = (frame and frame:FindFirstChild("Text")) :: TextLabel?
	setBanner(nil) -- escondido fora de evento
	task.spawn(function()
		while true do
			task.wait(rng:NextNumber(INTERVAL_MIN, INTERVAL_MAX))
			runEvent()
		end
	end)
end

return E
