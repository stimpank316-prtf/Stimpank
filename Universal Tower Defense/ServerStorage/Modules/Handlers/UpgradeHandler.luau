-- stimpank Server Upgrade Handler Module for UTD

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local data = ServerStorage.Data.Towers

local UpgradeHandler = {}

function UpgradeHandler:tryUpgrade(tower: {})
	local name = tower.Name :: string
	
	local config = require(data:FindFirstChild(name).Config)
	
	if config then
		local nextLevelNum = tower.Level + 1
		
		if config[tostring(nextLevelNum)] then
			local leaderstats = tower.Player.leaderstats :: Folder
			local money = leaderstats.Money :: IntValue
			
			local level = config[tostring(nextLevelNum)] 
			local nextLevel = config[tostring(nextLevelNum + 1)]
			
			local cost = level.Cost :: number

			if money.Value >= cost then
				money.Value -= cost
				
				tower.Level = nextLevelNum
				
				tower.Stats.Damage = level.Damage
				tower.Stats.Firerate = level.Firerate
				tower.Stats.Range = level.Range
				
				tower.Stats.TotalCost += cost
				tower.Stats.SellCost = math.floor(tower.Stats.TotalCost / 3)
				
				tower.Stats.Detections = level.Detections
				tower.Stats.Description = level.Description
				
				local data
				
				if nextLevel then
					tower.UpgradeStats.Damage = nextLevel.Damage
					tower.UpgradeStats.Firerate = nextLevel.Firerate
					tower.UpgradeStats.Range = nextLevel.Range

					tower.UpgradeStats.Cost = nextLevel.Cost
					tower.UpgradeStats.Description = nextLevel.Description
					
					data = {
						Stats = {
							Damage = tower.Stats.Damage,
							Firerate = tower.Stats.Firerate,
							Range = tower.Stats.Range,
							
							TotalDamage = tower.Stats.TotalDamage,
							TotalCost = tower.Stats.TotalCost,
							
							SellCost = tower.Stats.SellCost
						},
						
						NextStats = {
							Damage = tower.UpgradeStats.Damage,
							Firerate = tower.UpgradeStats.Firerate,
							Range = tower.UpgradeStats.Range,
							UpgradeCost = tower.UpgradeStats.Cost,
							
							Description = tower.UpgradeStats.Description,
						},
						
						Name = name,
						Position = tower.Position,
						
						Skin = tower.Skin,
						
						Level = tower.Level,
					}
				else
					data = {
						Stats = {
							Damage = tower.Stats.Damage,
							Firerate = tower.Stats.Firerate,
							Range = tower.Stats.Range,
							

							TotalDamage = tower.Stats.TotalDamage,
							TotalCost = tower.Stats.TotalCost,

                            Description = tower.Stats.Description,
							SellCost = tower.Stats.SellCost
						},

						NextStats = {
							Damage = tower.Stats.Damage,
							Firerate = tower.Stats.Firerate,
							Range = tower.Stats.Range,
							UpgradeCost = tower.Stats.Cost,

							Description = tower.Stats.Description,
						},

						Name = name,
						Position = tower.Position,
						
						Skin = tower.Skin,

						Level = tower.Level,
					}
				end
				
				return data
			end
		end
	end
end

return UpgradeHandler
