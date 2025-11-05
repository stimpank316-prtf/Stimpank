-- stimpank Enemy Replicator Module for UTD

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local assets = ReplicatedStorage.Assets

local createEnemy = ReplicatedStorage.Remotes.Enemy.CreateEnemy
local updateEnemy = ReplicatedStorage.Remotes.Enemy.UpdateEnemy
local deleteEnemy = ReplicatedStorage.Remotes.Enemy.DeleteEnemy

local player = Players.LocalPlayer

local Enemy = require(ReplicatedStorage.Modules.Classes.NPC.Enemy)

local EnemyReplicator = {}

local enemies = {}

local currentTime = workspace:GetServerTimeNow()

local TIME_THRESHOLD = 0.1
--local RENDER_THRESHOLD = 60

function EnemyReplicator:CreateEnemy(data: {})
	local id = data.Id
	
	if enemies[id] then return end

	local enemyCreator = Enemy.new(data.Name)
	
	--print(enemyCreator)
	
	local enemy = enemyCreator.Enemy.new(id, data.Statuses, data.Mutations, {Health = data.Health, MaxHealth = data.MaxHealth}, data.CFrame)
	
	enemies[id] = {
		Id = id,
		Name = data.Name,

		Model = enemy.Model,
		Display = enemy.Gui,
		
		Enemy = enemy
	}
	
	if enemy.Init then
		task.spawn(enemy.Init, data)
	end
	
	--enemyCreator:Destroy()
	--enemyCreator = nil
end

function EnemyReplicator:DeleteEnemy(id: string)
	local enemy = enemies[id]

	if enemy then
		if enemy.Enemy then
			enemy.Enemy:Destroy()
		end

		enemies[id] = nil
	end
end

function EnemyReplicator:UpdateEnemy(id: string, data: {})
	if workspace:GetServerTimeNow() - currentTime > TIME_THRESHOLD then
		local enemy = enemies[id]
		--print(enemies)

		if not enemy then return end
		
		if enemy.Enemy then
			if enemy.Enemy.Update then
				task.spawn(enemy.Enemy.Update, enemy.Enemy, data)
			end
		end
		--print(enemy)
	end
end

createEnemy.OnClientEvent:Connect(function(...)
	EnemyReplicator:CreateEnemy(...)
end)

deleteEnemy.OnClientEvent:Connect(function(...)
	EnemyReplicator:DeleteEnemy(...)
end)

updateEnemy.OnClientEvent:Connect(function(...)
	EnemyReplicator:UpdateEnemy(...)
end)

return EnemyReplicator
