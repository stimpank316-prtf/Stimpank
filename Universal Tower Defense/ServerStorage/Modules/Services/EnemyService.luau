-- stimpank EnemyService for Universal Tower Defense
-- version: 0.0.2

-- not using OOP and other things on server, for better readabillity and performance (yeah, have some bad experience with OOP on server)
--[[ this service is created for Managing Enemies for tower defense game, some functions available:
    void Sync(Player player) - sends a current enemy data to SPECIFIC client, used when player joined later, when game is already started.
    void SpawnEnemy(string name, CFrame startCF?, bool spawnAsBoss?, int currentNodeIndex?, int nextNodeIndex?) - spawns a new enemy by provided name, have optional parameters to specify exclusive behavior.
    void DestroyEnemy(table enemy) - self explanatory, literally just destroys an enemy and fires event to all clients to delete enemy on their side.
    void OnHeartbeat(float dt) - calculates new position data and new enemy statuses/modifiers when called every frame (RunService.Heartbeat event).
    void ClearAll() - destroy all enemies in the game, internally uses :DestroyEnemy() method of EnemyService.
    table GetEnemies() - self explanatory, retuns all enemies on the server
    table GetEnemiesUseArray() - behaves similarly like :GetEnemies(), but returns an array of enemies instead of dictionary.
]]

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local ServerStorage = game:GetService("ServerStorage")

local data = ServerStorage.Data.Enemies

local createEnemy = ReplicatedStorage.Remotes.Enemy.CreateEnemy
local updateEnemy = ReplicatedStorage.Remotes.Enemy.UpdateEnemy
local deleteEnemy = ReplicatedStorage.Remotes.Enemy.DeleteEnemy

local EnemyService = {}

local enemyFunctions = script.EnemyFunctions

local enemies = {}

local OFFSET_THRESHOLD = 1.2

local function deepCopy(originalTable: {})
	local newTable = {}
	
	for key, element in originalTable do
		if type(element) == "table" then
			newTable[key] = deepCopy(element)
		else
			newTable[key] = element
		end
	end
	
	return newTable
end

function EnemyService:Sync(player: Player)
	for _, enemy in enemies do
		createEnemy:FireClient(player, {
			Id = enemy.Id,
			Name = enemy.Name,
			
			CFrame = enemy.CFrame,
			
			Statuses = enemy.Statuses,
            Mutations = enemy.Mutations
		})
	end
end

function EnemyService:SpawnEnemy(name: string, startCF: CFrame?, spawnAsBoss: boolean?, currentNodeIndex: number?, nextNodeIndex: number?)
	local enemy = data:FindFirstChild(name)

	if enemy then
		local config = require(enemy.Config)

		local id = HttpService:GenerateGUID(false)
		
		local enemyModuleInstance = enemyFunctions:FindFirstChild(name) :: ModuleScript
		local enemyModule
		
		if enemyModuleInstance then
			enemyModule = require(enemyModuleInstance)
		end
		
		local mutations = deepCopy(config.Mutations)
	
		if spawnAsBoss == true then
			mutations["Boss"] = true
		end
		
		enemies[id] = {
			Id = id,

			Name = name,
			Statuses = {},
			Mutations = mutations,
			
            EnemyModule = enemyModule or {},
			Config = config,

			CurrentNodeIndex = currentNodeIndex or 0,
			NextNodeIndex = nextNodeIndex or 1,
			
			Health = config.Health,
			MaxHealth = config.Health,
			
			CFrame = startCF or CFrame.new(),
			XOffset = CFrame.new(
				Random.new():NextNumber(-OFFSET_THRESHOLD, OFFSET_THRESHOLD),
				0,
				0
			),
			--YOffset = config.Offset or CFrame.new(),
			
			Attackers = {},

			Time = workspace:GetServerTimeNow()
		}
		
		if enemyModule then
			if enemyModule.Init then
				task.spawn(enemyModule.Init, enemyModule, enemies[id])
			end
		end

		createEnemy:FireAllClients({
			Id = id,
			Name = name,
			
			CFrame = enemies[id].CFrame,
			
			Statuses = enemies[id].Statuses,
			Mutations = enemies[id].Mutations,
		})
	end
end

function EnemyService:DestroyEnemy(enemy: {})
	if enemy.EnemyModule then
		if enemy.EnemyModule.OnDeath then
			task.spawn(enemy.EnemyModule.OnDeath, enemy.EnemyModule, enemy)
		end
	end
	
	deleteEnemy:FireAllClients(enemy.Id)
	
	local nodes = workspace.Nodes:GetChildren()
	
	if enemy.NextNodeIndex == #nodes then
		workspace.Config.Health.Value -= enemy.Health
	end
	
	if #enemy.Attackers > 0 then
		local baseMoney = enemy.MaxHealth
		local totalMoney = math.floor(baseMoney / #enemy.Attackers)
		
		for _, attacker: Player in enemy.Attackers do
			if attacker and attacker.Parent then
				attacker.leaderstats.Money.Value += totalMoney
			end
		end
	end
	
	enemies[enemy.Id] = nil
end

function EnemyService:OnHeartbeat(dt: number)
	for _, enemy in enemies do
		if not workspace:FindFirstChild("Nodes") then return end
		
		local currentNode = workspace.Nodes:FindFirstChild(`Node{enemy.CurrentNodeIndex}`) :: BasePart
		local nextNode = workspace.Nodes:FindFirstChild(`Node{enemy.NextNodeIndex}`) :: BasePart

		if not currentNode or not nextNode or enemy.Health <= 0 then EnemyService:DestroyEnemy(enemy) continue end
		
		task.desynchronize()

		local distance = (nextNode.Position - currentNode.Position).Magnitude
		local t = distance / enemy.Config.Speed

		local alpha = (workspace:GetServerTimeNow() - enemy.Time) / t

		if alpha >= 1 then
			enemy.Time = workspace:GetServerTimeNow()

			enemy.CurrentNodeIndex += 1
			enemy.NextNodeIndex += 1
		end

		local finalCFrame = currentNode.CFrame:Lerp(nextNode.CFrame, math.clamp(alpha, 0, 1))
	
		enemy.CFrame = finalCFrame
		
		--print(enemy.CFrame.X, enemy.CFrame.Z, " - SERVER POSITION DATA")
		
		--local x, y, z = pos:ToOrientation()

		task.synchronize()
		
		updateEnemy:FireAllClients(enemy.Id, {
			Statuses = enemy.Statuses,
			Mutations = enemy.Mutations,
		

			--CFrameToEncode = {
			--	Position = Vector3int16.new(finalCFrame.X, 0, finalCFrame.Z),
				--Offset = Vector3int16.new(enemy.Offset.X, 0, 0)
				--Orientation = Vector3int16.new(x, y, z)
			--},
			
			XOffset = enemy.XOffset :: CFrame,
			CFrame = finalCFrame :: CFrame,
			
			--Position = Vector3int16.new(finalCFrame.X, 0, finalCFrame.Z),
			--Offset = Vector3int16.new(enemy.Offset.X, 0, 0),
			
			NextNodeIndex = enemy.NextNodeIndex,
			
			Health = enemy.Health,
			MaxHealth = enemy.MaxHealth
		})
		
	end
end

function EnemyService:ClearAll()
	for _, enemy in enemies do
		EnemyService:DestroyEnemy(enemy)
	end
end

function EnemyService:GetEnemies()
	return enemies
end

function EnemyService:GetEnemiesUseArray()
	local array = {}
	
	for _, enemy in enemies do
		table.insert(array, enemy)
	end
	
	return array
end

return EnemyService
