--!strict
-- BrainmonFactory: modelos dos Brainmon. Brainrots reais vem de ReplicatedStorage.BrainrotPack (por mutation/skin);
-- as 88 especies inventadas (sem modelo real) caem num bloco colorido pelo tipo (placeholder), montado no boot.
-- Cada clone sai normalizado: tudo Anchored, sem colisao, com um `Root` (bounding box) como PrimaryPart.
-- ponytail: o pack inteiro (87 x 7 variantes) replica pros clientes (preciso pro viewport de reveal). Pesado no join;
--   se virar gargalo, replicar so a pasta Normal e montar variantes no servidor.
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Data = require(script.Parent.BrainmonData)
local Assets = require(script.Parent.BrainmonAssets)

local F = {}

-- ponytail: constante unica de calibracao. O GLB sai com a frente em +Z; se no Studio o bicho andar de costas, mude para CFrame.identity.
F.FacingFix = CFrame.Angles(0, math.pi, 0)

local library: Folder
if RunService:IsServer() then
	library = Instance.new("Folder")
	library.Name = "BrainmonModels"
	library.Parent = ReplicatedStorage
else
	library = ReplicatedStorage:WaitForChild("BrainmonModels") :: Folder
end

-- Pasta dos brainrots reais. No servidor, move do Workspace pra ReplicatedStorage no 1o uso (idempotente).
local function getPack(): Folder?
	local p = ReplicatedStorage:FindFirstChild("BrainrotPack")
	if p then
		return p :: Folder
	end
	if RunService:IsServer() then
		local w = Workspace:FindFirstChild("BrainrotPack")
		if w then
			w.Parent = ReplicatedStorage
			return w :: Folder
		end
		return nil
	end
	return ReplicatedStorage:WaitForChild("BrainrotPack", 15) :: Folder?
end

local function finalize(model: Model)
	local cf, size = model:GetBoundingBox()
	local root = Instance.new("Part")
	root.Name = "Root"
	root.Size = size
	root.CFrame = cf
	root.Transparency = 1
	root.Anchored = true
	root.CanCollide = false
	root.CanTouch = false
	root.Parent = model
	model.PrimaryPart = root
	for _, d in model:GetDescendants() do
		if d:IsA("BasePart") then
			d.Anchored = true
			d.CanCollide = false
		elseif d:IsA("LuaSourceContainer") then
			d:Destroy() -- sem script de terceiro
		end
	end
end

local function placeholder(sp: Data.Species): Model
	local m = Instance.new("Model")
	local col = Data.Types[sp.type] or Color3.fromRGB(200, 200, 200)
	local body = Instance.new("Part")
	body.Name = "Body"
	body.Shape = Enum.PartType.Block
	body.Size = Vector3.new(3, 2.6, 4)
	body.Color = col
	body.Material = Enum.Material.SmoothPlastic
	body.Parent = m
	local head = body:Clone()
	head.Name = "Head"
	head.Size = Vector3.new(2.2, 2.2, 2.2)
	head.CFrame = body.CFrame * CFrame.new(0, 1.6, -2.4) -- frente = -Z
	head.Parent = m
	for _, sx in { -0.55, 0.55 } do
		local eye = Instance.new("Part")
		eye.Name = "Eye"
		eye.Size = Vector3.new(0.5, 0.5, 0.2)
		eye.Color = Color3.new(1, 1, 1)
		eye.CFrame = head.CFrame * CFrame.new(sx, 0.2, -1.1)
		eye.Parent = m
	end
	return m
end

local function load(sp: Data.Species): Model
	local id = Assets[sp.n]
	if id and id > 0 then
		local ok, container = pcall(InsertService.LoadAsset, InsertService, id)
		if ok then
			local found = container:FindFirstChildWhichIsA("Model")
			if found then
				found.Parent = nil
				container:Destroy()
				return found
			end
		end
		warn(`[BrainmonFactory] LoadAsset falhou para {sp.id} ({id}); usando placeholder`)
	end
	return placeholder(sp)
end

-- Modelo da especie na mutation pedida (fallback: Normal, depois nil).
local function packModel(pack: Folder, species: Data.Species, mutation: string): Model?
	local info = Data.Mutations[mutation] or Data.Mutations.Normal
	local folder = pack:FindFirstChild(mutation)
	if folder then
		local m = folder:FindFirstChild(info.prefix .. species.name)
		if m and m:IsA("Model") then
			return m :: Model
		end
	end
	local normal = pack:FindFirstChild("Normal")
	local nm = normal and normal:FindFirstChild(species.name)
	return if nm and nm:IsA("Model") then nm :: Model else nil
end

-- Servidor, no boot. Placeholder so pras especies SEM modelo real (as reais clonam do pack na hora).
function F.Preload()
	local pack = getPack()
	local normal = pack and pack:FindFirstChild("Normal")
	local real, fake = 0, 0
	for _, sp in Data.Species do
		if normal and normal:FindFirstChild(sp.name) then
			real += 1
		else
			local m = load(sp)
			m.Name = sp.id
			finalize(m)
			m:SetAttribute("Species", sp.id)
			m:SetAttribute("Real", Assets[sp.n] ~= nil)
			m.Parent = library
			fake += 1
		end
	end
	return real, fake
end

-- Clone normalizado. mutation = skin (default "Normal"); escala absoluta pela MAIOR dimensao -> rarity.scale.
function F.Create(speciesId: string, mutation: string?): Model
	local sp = Data.SpeciesById[speciesId]
	local mut = mutation or "Normal"
	local src: Model? = nil

	local pack = getPack()
	if pack and sp then
		src = packModel(pack, sp, mut)
	end
	if not src then
		src = library:FindFirstChild(speciesId) :: Model? -- placeholder das inventadas
	end

	local m: Model
	if src then
		m = src:Clone()
	else
		m = placeholder(sp or ({ type = "Terra" } :: any))
		m.Name = speciesId
	end
	if not (m.PrimaryPart and m:FindFirstChild("Root")) then
		finalize(m) -- modelos do pack (ou placeholder cru) ainda nao normalizados
	end

	local rarity = if sp then Data.RarityOf(sp) else "Common"
	local target = Data.RarityInfo[rarity].scale
	local _, size = m:GetBoundingBox()
	local cur = math.max(size.X, size.Y, size.Z)
	if cur > 0 then
		m:ScaleTo(m:GetScale() * target / cur)
	end
	m:SetAttribute("Rarity", rarity)
	m:SetAttribute("Mutation", mut)
	if sp then
		m:SetAttribute("Type", sp.type)
	end
	return m
end

return F
