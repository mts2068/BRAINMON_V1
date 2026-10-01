--!strict
-- VipService: checa posse dos Game Passes VIP / VIP Ilimitado e marca o jogador (attributes "Vip"/"VipUnlimited").
-- RebirthService.CashMult/Luck leem esses attributes e somam o bonus. UserOwnsGamePass e persistente na Roblox (sem DataStore).
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Data = require(ReplicatedStorage:WaitForChild("BrainmonData"))

local V = {}

local function check(player: Player)
	for _, key in { "Vip", "VipUnlimited" } do
		local pass = Data.Robux[key].pass
		if pass and pass > 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass)
			end)
			if ok and owns then
				player:SetAttribute(key, true)
			end
		end
	end
end

function V.Init()
	Players.PlayerAdded:Connect(function(p)
		task.spawn(check, p)
	end)
	for _, p in Players:GetPlayers() do
		task.spawn(check, p)
	end
	-- aplica na hora apos a compra do gamepass
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player: Player, passId: number, purchased: boolean)
		if not purchased then
			return
		end
		if passId == Data.Robux.Vip.pass then
			player:SetAttribute("Vip", true)
		elseif passId == Data.Robux.VipUnlimited.pass then
			player:SetAttribute("VipUnlimited", true)
		end
	end)
end

return V
