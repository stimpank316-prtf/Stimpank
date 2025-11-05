-- stimpank Tower Service for Universal Tower Defense
-- version: 0.0.1
--- ### ALPHA ### ---

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local renderModel = ReplicatedStorage.Remotes.Placement.RenderModel
local deleteModel = ReplicatedStorage.Remotes.Placement.DeleteModel

local updateTower = ReplicatedStorage.Remotes.Tower.UpdateTower
local upgradeTower = ReplicatedStorage.Remotes.Tower.UpgradeTower

local sellTower = ReplicatedStorage.Remotes.Tower.SellTower
local changeTarget = ReplicatedStorage.Remotes.Tower.ChangeTarget

local placeFunction = ReplicatedStorage.Remotes.Placement.Place
local getTowerDataFunction = ReplicatedStorage.Remotes.Data.GetTowerData

local data = ServerStorage.Data.Towers

local EnemyService = require(ServerStorage.Modules.Services.EnemyService)

local UpgradeHandler = require(ServerStorage.Modules.Handlers.UpgradeHandler)

local TowerService = {}

local targetFinder = require(script.TargetFinder)
local towerFunctions = script.TowerFunctions

local MAX_TOWERS_AMOUNT = 40

local towers = {}

local function getTower(player: Player, id: string)
	if towers[player] then
		local models = towers[player].Towers

		for _, model: {Name: string, Id: string} in models do
			if model.Id == id then
				return model
			end
		end
	end
end

function TowerService:Sync(player: Player)
	for _, towerData in towers do
		for _, tower in towerData.Towers do
			renderModel:FireClient(
				player,
				tower.Player,
				tower.Id,
				tower.Name,
				tower.Skin,
				tower.Level,
				
				CFrame.new(tower.Position + tower.Offset),
				CFrame.Angles(0, math.rad(tower.Rotation), 0)
			)
		end
	end
end

function TowerService:AddPlayerTowers(player: Player, towerStruct: struct)
	if not towers[player] then
		towers[player] = {
			Towers = {},
			Count = 0,
			
			EquippedTowers = towerStruct.EquippedTowers,
			OwnedTowers = towerStruct.OwnedTowers,
			Skins = towerStruct.Skins
		}
		
        return true
	end
	
	towers[player].EquippedTowers = towerStruct.EquippedTowers
	towers[player].OwnedTowers = towerStruct.OwnedTowers
	towers[player].Skins = towerStruct.Skins
	
	return true
end

function TowerService:TryUpgrade(player: Player, id: string)
	local tower = getTower(player, id)
	
	if player ~= tower.Player then return end
	
	if tower then
		local result = UpgradeHandler:tryUpgrade(tower)
		
		if result then
			renderModel:FireAllClients(
				player,
				id,
				tower.Name,
				tower.Skin,
				tower.Level,
				
				CFrame.new(tower.Position + tower.Offset),
				CFrame.Angles(0, math.rad(tower.Rotation), 0)
			)
			
			return result
		end
	end
end

function TowerService:ChangeTarget(player: Player, towerId: string)
	local pTowers = towers[player]
	
	if pTowers then
		local tower = getTower(player, towerId)
		
		if tower then
			local currentTargetIndex = table.find(tower.AvailableTargets, tower.Target)
			
			local nextIndex = currentTargetIndex + 1
			
			if nextIndex > #tower.AvailableTargets then
				nextIndex = 1
			end
			
			local finalTarget = tower.AvailableTargets[nextIndex]
			
			if finalTarget then
				tower.Target = finalTarget
				
				return typeof(finalTarget) == "string" and finalTarget
			end
		end
	end
end

function TowerService:PlaceTower(player: Player, name: string, vectors: {origin: Vector3, direction: Vector3, rotation: number, offset: Vector3})
	if not towers[player] then
		towers[player] = {
			Towers = {},
			Count = 0,
			
			EquippedTowers = {},
			OwnedTowers = {},
			Skins = {}
		}
	end

	if towers[player].Count >= MAX_TOWERS_AMOUNT then return false, nil end
	
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = {player.Character}

	local ray = workspace:Raycast(vectors.origin, vectors.direction, params)
	
	--print("before raycast")

	if ray and ray.Instance then
		local inst = ray.Instance
	
		if inst:GetAttribute("CanPlace") then
			local modelData = data:FindFirstChild(name)

			if not modelData then return end

			local config = require(modelData.Config)
			
			local leaderstats = player.leaderstats :: Folder

			if leaderstats.Money.Value >= config["0"].Cost then
				leaderstats.Money.Value -= config["0"].Cost
				
				local id = HttpService:GenerateGUID(false)
				
				local skin = towers[player].Skins[name].Equipped :: string
				
				local module = require(script.TowerFunctions:FindFirstChild(name))
				
				towers[player].Towers[id] = {
					Position = ray.Position,
					Rotation = vectors.rotation,
					Offset = vectors.offset,
					
					Id = id,
					Name = name,
					Skin = skin,
					Player = player,
					
					TowerModule = module,
					
					DeltaTime = 0,

					Stats = {
						Damage = config["0"].Damage,
						Firerate = config["0"].Firerate,
						Range = config["0"].Range,
						
						TotalDamage = 0,
						TotalCost = config["0"].Cost,
						
						SellCost = math.floor(config["0"].Cost / 3),
						Description = "",
						
						Detections = config["0"].Detections,
					},
					
					UpgradeStats = {
						Damage = config["1"].Damage,
						Firerate = config["1"].Firerate,
						Range = config["1"].Range,
						
						Cost = config["1"].Cost,
						Description = config["1"].Description
					},
					
					Statuses = {},
					
					Level = 0,
					
					Enemy = nil,
					Target = "First",
					
					AvailableTargets = {"First", "Last", "Strongest", "Weakest"}
				}

				towers[player].Count += 1
				
				if module.Init then
					task.spawn(module.Init)
				end
				
				renderModel:FireAllClients(
					player,
					id,
					name,
					skin,
					0,
					CFrame.new(ray.Position + vectors.offset),
					CFrame.Angles(0, math.rad(vectors.rotation), 0)
				)

				--print("after")

				return true, id
			else
				warn("Not enough money!")
			end
		end
	end

	return false, nil
end

function TowerService:SellTower(player: Player, id: string)
	if towers[player] then
		local model = getTower(player, id)
		
		if player ~= model.Player then return end

		if model then
			local leaderstats = player.leaderstats
			local money = leaderstats.Money :: IntValue
			
			local tower = getTower(player, id)
			local name = tower.Name
			local level = tower.Level
			
			local config = require(data:FindFirstChild(name).Config)
			local cashback = math.floor(config[tostring(level)].Cost / 3)
			
			money.Value += cashback
			
			deleteModel:FireAllClients(id)
			
			towers[player].Count -= 1
			
			towers[player].Towers[id] = nil
		end
	end
end

function TowerService:OnHeartbeat(dt: number)
	for _, towerData in towers do
		for _, tower in towerData.Towers do
			local data = {
				Id = tower.Id,
				Name = tower.Name,
				
				Statuses = tower.Statuses,
				
				Stats = tower.Stats,
				UpgradeStats = tower.UpgradeStats,
				
				Target = tower.Target,
				
				Level = tower.Level,
				
				Enemy = tower.Enemy,
			}
			
			updateTower:FireAllClients(data)
		end
	end
end

function TowerService:OnStepped(dt: number)
	for _, playerTowers in towers do
		for _, tower in playerTowers.Towers do
			if tower.TowerModule then
				if tower.TowerModule.Attack then
					local enemies = EnemyService:GetEnemies()
					
					task.spawn(tower.TowerModule.Attack, tower.TowerModule, tower, dt, tower.Position, enemies)
				end
			end
		end
	end
end

function TowerService:GetPlayerTowers(player: Player)
	if towers[player] then
		return towers[player].Towers
	end
end

placeFunction.OnServerInvoke = function(...)
	return TowerService:PlaceTower(...)
end

upgradeTower.OnServerInvoke = function(...)
	return TowerService:TryUpgrade(...)
end

getTowerDataFunction.OnServerInvoke = function(player: Player, towerName: string)
	local towerData = data:FindFirstChild(towerName)
	
	if towerData then
		local config = require(towerData.Config)
		
		return {
			Damage = config["0"].Damage,
			Firerate = config["0"].Firerate,
			Range = config["0"].Range,
			
			Cost = config["0"].Cost,
		}
	end
end

sellTower.OnServerEvent:Connect(function(...)
	TowerService:SellTower(...)
end)

changeTarget.OnServerEvent:Connect(function(...)
	TowerService:ChangeTarget(...)
end)

export type struct = {
	EquippedTowers: {},
	OwnedTowers: {},
	Skins: {}
}

return TowerService
