-- stimpank Tower Replicator Module for UTD

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local renderModel = ReplicatedStorage.Remotes.Placement.RenderModel
local deleteModel = ReplicatedStorage.Remotes.Placement.DeleteModel

local updateTower = ReplicatedStorage.Remotes.Tower.UpdateTower

local assets = ReplicatedStorage.Assets

local localPlayer = Players.LocalPlayer

local Tower = require(ReplicatedStorage.Modules.Classes.NPC.Tower)

--local PlacementController = require(ReplicatedStorage.Modules.Controllers.PlacementController)

local UpgradeHandler = require(ReplicatedStorage.Modules.Handlers.UpgradeHandler)

local TowerReplicator = {}

local towers = {}

local LOOK_AT_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Circular)

function TowerReplicator:RenderTower(player: Player, id: string, name: string, skin: string, level: number, position: CFrame, rotation: CFrame)
	if towers[id] then
		TowerReplicator:DeleteTower(id)
	end
	
	local newTower = Tower.new(name)
	
	if newTower then
		local tower = newTower.Tower.new("null", id, skin, level, position * rotation)
	
		towers[id] = {
			Id = id,
			Tower = tower,
			Player = player,
			Enemy = nil,

			Name = name,

			Connections = {},

			Thread = nil
		}

		if player == localPlayer then
			UpgradeHandler:bind(towers[id])
		end

		TowerReplicator:TowerLifeLoop(id)
	end
end

function TowerReplicator:UpdateTower(data: {})
	local tower = towers[data.Id]
	
	if tower then
		if tower.Tower then
			local stats = data.Stats
			local upgStats = data.UpgradeStats
			
			local model = tower.Tower.Model :: Model
			
			if model and model.Stats and #model.Stats:GetChildren() > 0 and model.Stats.UpgradeStats and #model.Stats.UpgradeStats:GetChildren() > 0 then
				model.Stats.Damage.Value = stats.Damage
				model.Stats.Firerate.Value = stats.Firerate
				model.Stats.Range.Value = stats.Range
				model.Stats.TowerName.Value = data.Name
				model.Stats.TotalCost.Value = stats.TotalCost
				model.Stats.TotalDamage.Value = stats.TotalDamage
				model.Stats.SellCost.Value = stats.SellCost
				model.Stats.Target.Value = data.Target
				model.Stats.Level.Value = data.Level

				model.Stats.UpgradeStats.Damage.Value = upgStats.Damage
				model.Stats.UpgradeStats.Firerate.Value = upgStats.Firerate
				model.Stats.UpgradeStats.Range.Value = upgStats.Range
				model.Stats.UpgradeStats.Description.Value = upgStats.Description
				model.Stats.UpgradeStats.UpgradeCost.Value = upgStats.Cost
			end

			if data.Enemy then
				tower.Enemy = data.Enemy
			else
				tower.Enemy = nil
			end
		end
	end
end

function TowerReplicator:TowerLifeLoop(id: string)
	towers[id].Thread = task.spawn(function()
		while towers[id] do
			local tower = towers[id]
			
			if tower then
				local storedTower = tower.Tower
				
				if storedTower and storedTower.Model and storedTower.Model.Parent then
					if storedTower.Attack then
						storedTower:Attack(tower.Enemy)
					end
				end
			end
			
			task.wait(tower.Tower.Model.Stats.Firerate.Value)
		end
	end)
end

function TowerReplicator:DeleteTower(id: string)
	local towerData = towers[id]
	
	if towerData then
		towerData.Tower:Destroy()

		for _, connection: RBXScriptConnection in towers[id].Connections do
			connection:Disconnect()
		end
		
		if towerData.Thread then
			task.cancel(towerData.Thread)
		end

		table.clear(towers[id].Connections)
		towers[id].Tower = nil

		towers[id].Stats = nil
		towers[id].UpgradeStats = nil
		
		towers[id] = nil
	end
end

renderModel.OnClientEvent:Connect(function(...)
	TowerReplicator:RenderTower(...)
end)

deleteModel.OnClientEvent:Connect(function(...)
	TowerReplicator:DeleteTower(...)
end)

updateTower.OnClientEvent:Connect(function(...)
	TowerReplicator:UpdateTower(...)
end)

return TowerReplicator
