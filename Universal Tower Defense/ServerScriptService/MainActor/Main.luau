-- stimpank Parallel Main Server Script for UTD

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local modules = ServerStorage.Modules

local TowerService = require(modules.Services.TowerService)
local EnemyService = require(modules.Services.EnemyService)
local GamemodeService = require(modules.Services.GamemodeService)

local getDataFunction = ReplicatedStorage.Remotes.Data.GetData

local enemies = {"Normal Enemy", "Speedy Enemy", "Strong Enemy", "Tough Enemy"}

local currentTime = workspace:GetServerTimeNow()

local threshold = 0.175

local VOTE_CD = 10
local START_MONEY = 750

-- HAS TO BE REMOVED LATER WHEN DATA STORES WILL BE IMPLEMENTED
local templateData = {
	Skins = {
		["Heavy Gunner"] = {
			Equipped = "Default",
		},
		
		["Pistoler"] = {
			Equipped = "Default",
		}
	},
	
	EquippedTowers = {
		"Heavy Gunner",
		"Pistoler"
	},
	
	OwnedTowers = {
		"Heavy Gunner",
		"Pistoler"
	},
	
	Gold = 9999,
}

local playerData = {}

local mapLoaded = false

local function createMap(name: string)
	local map = ServerStorage.Assets.Maps:FindFirstChild(name)
	
	if map then
		local new = map:Clone()
		
		local nodes = new:FindFirstChild("Nodes")
		local path = new:FindFirstChild("Path")
		local spawnPoint = new:FindFirstChild("SpawnPoint")
		
		if nodes then
			nodes.Parent = workspace
		end
		
		if path then
			path.Parent = workspace
		end
		
		if spawnPoint then
			spawnPoint.Parent = workspace
		end
		
		new.Parent = workspace
		
		return new
	end
end

local function onPlayerAdded(player: Player)
	local data = templateData
	
	playerData[player] = templateData
	
	if not mapLoaded then
		mapLoaded = true
		
		local joinData = player:GetJoinData()
		
		if not joinData.TeleportData then
			createMap("Baseplate Map")
		else
			createMap(joinData.TeleportData.Map)
		end
		
		task.spawn(GamemodeService.StartVoting, GamemodeService, VOTE_CD)
	end
	
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player
	
	local money = Instance.new("IntValue")
	money.Name = "Money"
	money.Value = START_MONEY
	money.Parent = leaderstats

	TowerService:Sync(player)
	
	local struct = {
		EquippedTowers = data.EquippedTowers,
		OwnedTowers = data.OwnedTowers,
		Skins = data.Skins
	}
	
	TowerService:AddPlayerTowers(player, struct)
end

local rand = Random.new(workspace:GetServerTimeNow())

local steppedConnection
local heartbeatConnection

local function onHeartbeat(dt: number)
	if workspace.Config.Health.Value <= 0 then
		EnemyService:ClearAll()
		
		if heartbeatConnection then
			heartbeatConnection:Disconnect()
			heartbeatConnection = nil
		end
		
		return
	end

	if workspace:GetServerTimeNow() - currentTime > threshold then
		EnemyService:OnHeartbeat(dt)
		TowerService:OnHeartbeat(dt)

		currentTime = workspace:GetServerTimeNow()
	end
	--EnemyService:OnHeartbeat(dt)
end

local function onStepped(dt: number)
	if workspace.Config.Health.Value <= 0 then
		if steppedConnection then
			steppedConnection:Disconnect()
			steppedConnection = nil
		end
		
		return
	end
	
	TowerService:OnStepped(dt)
end

steppedConnection = RunService.PreAnimation:Connect(onStepped)
heartbeatConnection = RunService.Heartbeat:Connect(onHeartbeat)

getDataFunction.OnServerInvoke = function(player: Player)
	return playerData[player]
end

Players.PlayerAdded:Connect(onPlayerAdded)

task.spawn(function()
	while task.wait(0.2) do
		if workspace.Config.Health.Value <= 0 then
			for _, player in Players:GetPlayers() do
				player:Kick("You Lost!")
			end
		end
	end
end)
