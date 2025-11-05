local ReplicatedStorage = game:GetService("ReplicatedStorage")

local modules = ReplicatedStorage.Modules

local EnemyReplicator = require(modules.Controllers.EnemyReplicator)
local TowerReplicator = require(modules.Controllers.TowerReplicator)

local VotingController = require(modules.Controllers.Interface.VotingController)
local PlacementController = require(modules.Controllers.PlacementController)
local InventoryController = require(modules.Controllers.Interface.InventoryController)

local getData = ReplicatedStorage.Remotes.Data.GetData

local function initTowers()
	local data = getData:InvokeServer()
	
	if data then
		for idx, tower in data.EquippedTowers do
			local skin = data.Skins[tower].Equipped
			
			if skin then
				InventoryController:AddTower(tower, skin, idx)
			end
		end
	end
end

task.spawn(initTowers)
