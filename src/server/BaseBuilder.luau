--!strict
-- BaseBuilder: bases dos jogadores a partir do modelo Base1 (kit), 1 por slot de Data.BaseSlots().
-- Base1 tem 10 Platforms (pads), Sign (frente, +Z), LockBase/WallLock (steal futuro). Front vira pra avenida.
-- Pads sao lidos do CLONE em runtime (sem hardcode de geometria). Collect Zone e criada na frente.
local Workspace = game:GetService("Workspace")
local ServerStorage = game:GetService("ServerStorage")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage:WaitForChild("BrainmonData"))

local B = {}

export type Plot = { folder: Instance, center: Vector3, pads: { Vector3 }, sign: BasePart, collect: BasePart, owner: number?, occupied: { [number]: any }?, pending: number? }
export type Bases = { folder: Folder, plots: { Plot } }

-- Base1 vira template em ServerStorage (tira do Workspace no 1o boot; idempotente).
local function getTemplate(): Model?
	local t = ServerStorage:FindFirstChild("BaseTemplate")
	if t and t:IsA("Model") then
		return t
	end
	local b = Workspace:FindFirstChild("Base1")
	if b and b:IsA("Model") then
		b.Name = "BaseTemplate"
		b.Parent = ServerStorage
		return b
	end
	return nil
end

-- numero do Platform ("Platform10" -> 10) pra ordenar os pads certinho.
local function platNum(name: string): number
	return tonumber(string.match(name, "%d+")) or 0
end

local function topOf(inst: Instance): Vector3
	if inst:IsA("Model") then
		local cf, size = inst:GetBoundingBox()
		return cf.Position + Vector3.new(0, size.Y / 2, 0)
	else
		local p = inst :: BasePart
		return p.Position + Vector3.new(0, p.Size.Y / 2, 0)
	end
end

local function ownerGui(signPart: BasePart)
	local gui = Instance.new("BillboardGui")
	gui.Name = "Owner"
	gui.Adornee = signPart
	gui.Size = UDim2.fromOffset(200, 34)
	gui.StudsOffset = Vector3.new(0, 1.5, 0)
	gui.MaxDistance = 160
	gui.Parent = signPart
	local txt = Instance.new("TextLabel")
	txt.BackgroundTransparency = 1
	txt.Size = UDim2.fromScale(1, 1)
	txt.Font = Enum.Font.FredokaOne
	txt.TextScaled = true
	txt.TextColor3 = Color3.fromRGB(252, 250, 245)
	txt.TextStrokeTransparency = 0
	txt.Text = "Base livre"
	txt.Parent = gui
end

local function makeCollect(parent: Instance, pos: Vector3): BasePart
	local collect = Instance.new("Part")
	collect.Name = "CollectZone"
	collect.Anchored = true
	collect.CanCollide = false
	collect.Size = Vector3.new(26, 0.4, 8)
	collect.Position = pos
	collect.Color = Color3.fromRGB(90, 230, 120)
	collect.Material = Enum.Material.Neon
	collect.Parent = parent
	local gui = Instance.new("BillboardGui")
	gui.Name = "Collect"
	gui.Adornee = collect
	gui.Size = UDim2.fromOffset(180, 40)
	gui.StudsOffset = Vector3.new(0, 3, 0)
	gui.MaxDistance = 110
	gui.Parent = collect
	local txt = Instance.new("TextLabel")
	txt.Name = "Pending"
	txt.BackgroundTransparency = 1
	txt.Size = UDim2.fromScale(1, 1)
	txt.Font = Enum.Font.FredokaOne
	txt.TextScaled = true
	txt.TextColor3 = Color3.fromRGB(120, 255, 138)
	txt.TextStrokeTransparency = 0
	txt.Text = "Coletar $0"
	txt.Parent = gui
	return collect
end

function B.Build(): Bases
	local old = Workspace:FindFirstChild("Bases")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Bases"
	folder.Parent = Workspace

	local template = getTemplate()
	if not template then
		warn("[BaseBuilder] Base1/BaseTemplate nao encontrado; bases nao serao criadas")
	end

	local plots: { Plot } = {}
	for _, slot in Data.BaseSlots() do
		local x, z, face = slot.pos.X, slot.pos.Z, slot.face
		local pf = Instance.new("Folder")
		pf.Name = "Plot"
		pf.Parent = folder

		local pads: { Vector3 } = {}
		local sign: BasePart? = nil
		local monsParent: Instance = pf

		if template then
			local clone = template:Clone()
			local yaw = if face == 1 then 0 else math.pi -- front (+Z) vira pra avenida
			clone:PivotTo(CFrame.new(x, 0, z) * CFrame.Angles(0, yaw, 0))
			-- assenta no chao: base inferior em y = 0
			local bcf, bsize = clone:GetBoundingBox()
			local minY = bcf.Position.Y - bsize.Y / 2
			clone:PivotTo(CFrame.new(0, -minY, 0) * clone:GetPivot())
			-- blinda o kit: ancora tudo (cenario estatico) e remove scripts de terceiro
			for _, d in clone:GetDescendants() do
				if d:IsA("BasePart") then
					d.Anchored = true
				elseif d:IsA("LuaSourceContainer") then
					d:Destroy()
				end
			end
			clone.Parent = pf

			local plats: { Instance } = {}
			for _, c in clone:GetChildren() do
				if string.sub(c.Name, 1, 8) == "Platform" then
					table.insert(plats, c)
				end
			end
			table.sort(plats, function(a, b)
				return platNum(a.Name) < platNum(b.Name)
			end)
			for _, c in plats do
				table.insert(pads, topOf(c))
			end

			local signModel = clone:FindFirstChild("Sign")
			local signPart = signModel and signModel:FindFirstChildWhichIsA("BasePart", true)
			if signPart then
				ownerGui(signPart)
				sign = signPart
			end

			local mons = Instance.new("Folder")
			mons.Name = "Mons"
			mons.Parent = clone
			monsParent = mons
		end

		local collect = makeCollect(pf, Vector3.new(x, 1.0, z + face * 37)) -- na frente, lado da avenida
		table.insert(plots, {
			folder = monsParent,
			center = Vector3.new(x, 0, z),
			pads = pads,
			sign = sign or collect,
			collect = collect,
		})
	end
	return { folder = folder, plots = plots }
end

return B
