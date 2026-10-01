--!strict
-- BaseService: aloca 1 plot por jogador e expoe os Brainmons capturados nos pads (eles rendem via atributo Placed).
-- A renda em si e somada pelo BraindexService (soma os Placed). Aqui so cuido da alocacao, do display e do rotulo $/s.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage:WaitForChild("BrainmonData"))
local Factory = require(ReplicatedStorage:WaitForChild("BrainmonFactory"))
local Braindex = require(script.Parent.BraindexService)
local Rebirth = require(script.Parent.RebirthService)

local S = {}
local plots: { any } = {}
local byUser: { [number]: any } = {}

type Display = { model: Model, base: Vector3, phase: number, t: number }
local displays: { Display } = {}

-- remove o display de um modelo (para o idle loop) e destroi o modelo.
local function dropDisplay(model: Model)
	for i, d in displays do
		if d.model == model then
			table.remove(displays, i)
			break
		end
	end
	model:Destroy()
end

local function label(root: BasePart, cfg: Configuration, sp: Data.Species, mutation: string, halfY: number)
	local rarity = Data.RarityOf(sp)
	local mut = Data.Mutations[mutation]
	local isMut = mutation ~= "Normal" and mut ~= nil
	local gui = Instance.new("BillboardGui")
	gui.Name = "Tag"
	gui.Adornee = root
	gui.Size = UDim2.fromOffset(200, 48)
	gui.StudsOffsetWorldSpace = Vector3.new(0, halfY + 2.5, 0)
	gui.MaxDistance = 90
	gui.Parent = root
	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Size = UDim2.fromScale(1, 0.55)
	name.Font = Enum.Font.GothamBold
	name.TextScaled = true
	name.TextColor3 = if isMut then mut.color else Data.RarityInfo[rarity].color
	name.TextStrokeTransparency = 0
	name.Text = (if isMut then mut.label .. " " else "") .. sp.name
	name.Parent = gui
	local sub = name:Clone()
	sub.Position = UDim2.fromScale(0, 0.55)
	sub.Size = UDim2.fromScale(1, 0.45)
	sub.TextColor3 = Color3.fromRGB(120, 255, 138)
	sub.Text = `${Data.Money(Braindex.GetRecordIncome(cfg))}/s · {rarity}`
	sub.Parent = gui
end

local function setSign(plot: any, text: string)
	local gui = plot.sign:FindFirstChild("Owner")
	local txt = gui and gui:FindFirstChildWhichIsA("TextLabel")
	if txt then
		txt.Text = text
	end
end

local function setCollect(plot: any)
	local gui = plot.collect:FindFirstChild("Collect")
	local txt = gui and gui:FindFirstChild("Pending")
	if txt then
		(txt :: TextLabel).Text = "Coletar $" .. Data.Money(plot.pending or 0)
	end
end

function S.AssignPlot(player: Player): any
	if byUser[player.UserId] then
		return byUser[player.UserId]
	end
	for _, plot in plots do
		if not plot.owner then
			plot.owner = player.UserId
			plot.occupied = {}
			byUser[player.UserId] = plot
			setSign(plot, player.Name)
			return plot
		end
	end
	return nil
end

function S.Release(player: Player)
	local plot = byUser[player.UserId]
	if plot then
		for _, slot in plot.occupied or {} do
			if slot.model then
				dropDisplay(slot.model)
			end
		end
		plot.owner = nil
		plot.occupied = {}
		plot.pending = 0
		setSign(plot, "Base livre")
		setCollect(plot)
	end
	byUser[player.UserId] = nil
end

-- remove UM individuo colocado (venda): libera o pad e apaga o display. true se estava exposto na base.
function S.RemovePlaced(player: Player, cfg: Configuration): boolean
	local plot = byUser[player.UserId]
	if not plot or not plot.occupied then
		return false
	end
	for pad, slot in plot.occupied do
		if slot.cfg == cfg then
			if slot.model then
				dropDisplay(slot.model)
			end
			plot.occupied[pad] = nil
			return true
		end
	end
	return false
end

-- coloca um individuo (cfg) num pad livre do plot do jogador. true se colocou (vira fonte de renda).
function S.TryPlace(player: Player, cfg: Configuration): boolean
	local plot = byUser[player.UserId]
	if not plot then
		return false
	end
	plot.occupied = plot.occupied or {}
	local padIndex: number? = nil
	for i = 1, #plot.pads do
		if not plot.occupied[i] then
			padIndex = i
			break
		end
	end
	if not padIndex then
		return false
	end
	local sp = Data.SpeciesById[cfg:GetAttribute("Species") :: string]
	if not sp then
		return false
	end
	local mutation = (cfg:GetAttribute("Mutation") :: string?) or "Normal"
	local model = Factory.Create(sp.id, mutation)
	local root = model.PrimaryPart :: BasePart
	local half = root.Size / 2
	local base = plot.pads[padIndex] + Vector3.new(0, half.Y, 0)
	model.Name = sp.id
	model:SetAttribute("OwnerUserId", player.UserId)
	label(root, cfg, sp, mutation, half.Y)
	model:PivotTo(CFrame.new(base) * Factory.FacingFix)
	model.Parent = plot.folder
	plot.occupied[padIndex] = { model = model, cfg = cfg }
	cfg:SetAttribute("Placed", true)
	cfg:SetAttribute("Pad", padIndex)
	table.insert(displays, { model = model, base = base, phase = math.random() * 6.28, t = 0 })
	return true
end

function S.Init(bases: any)
	plots = bases.plots
	Players.PlayerAdded:Connect(function(p)
		S.AssignPlot(p)
	end)
	for _, p in Players:GetPlayers() do
		S.AssignPlot(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		S.Release(p)
	end)

	-- Collect Zone: o dono pisa -> saca o pendente (x CashMulti) pro BC.
	for _, plot in plots do
		local last = 0
		plot.collect.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if not player or plot.owner ~= player.UserId or (plot.pending or 0) <= 0 then
				return
			end
			local now = os.clock()
			if now - last < 0.3 then
				return
			end
			last = now
			local gained = (plot.pending or 0) * Rebirth.CashMult(player) -- multiplicador cresce com rebirth
			plot.pending = 0
			setCollect(plot)
			Braindex.AddBC(player, gained)
		end)
	end

	-- acumulo: 1x/s soma a renda dos Brainmons expostos de cada base no pendente dela (um loop so)
	task.spawn(function()
		while true do
			task.wait(Data.Config.IncomeTick)
			for _, plot in plots do
				if plot.owner and plot.occupied then
					local inc = 0
					for _, slot in plot.occupied do
						if slot.cfg and slot.cfg.Parent then
							inc += Braindex.GetRecordIncome(slot.cfg)
						end
					end
					if inc > 0 then
						plot.pending = (plot.pending or 0) + inc * Data.Config.IncomeTick
						setCollect(plot)
					end
				end
			end
		end
	end)
	-- idle de todos os displays em UM loop (equivalente ao Idle dos GLBs; respira subindo/descendo)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += math.min(dt, 0.1)
		if acc < 1 / 15 then
			return
		end
		for _, d in displays do
			d.t += acc
			local bob = math.sin(d.t * 2.2 + d.phase) * 0.12
			d.model:PivotTo(CFrame.new(d.base.X, d.base.Y + bob, d.base.Z) * Factory.FacingFix)
		end
		acc = 0
	end)
end

return S
