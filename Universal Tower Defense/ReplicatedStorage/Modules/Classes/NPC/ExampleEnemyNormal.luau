local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local bossesGui = playerGui:WaitForChild("Bosses")

local BaseEnemy = require(script.Parent.Base.BaseEnemy)

local NormalEnemy = {}
setmetatable(NormalEnemy, BaseEnemy)

NormalEnemy.__index = NormalEnemy

function NormalEnemy.new(id: string, statuses: {}, mutations: {}, statistics: {Health: number, MaxHealth: number}, cf: CFrame?)
	local enemy = {}
	
	setmetatable(enemy, NormalEnemy)
	
	enemy.Id = id
	enemy.Name = "Normal"
	
	enemy.Stats = statistics
	enemy.Statuses = statuses
	enemy.Mutations = mutations

	enemy.SourceModel = ReplicatedStorage.Assets.Enemies:FindFirstChild("Normal")
	enemy.Model = ReplicatedStorage.Assets.Enemies:FindFirstChild("Normal"):Clone()
	enemy.Model.Name = id
	enemy.Model.Parent = workspace.Client.Enemies

	enemy.Gui = ReplicatedStorage.Assets.UI.Enemy.EnemyDisplay:Clone()
	enemy.Gui.Adornee = (enemy.Model:FindFirstChild("Head") or enemy.Model.PrimaryPart)
	enemy.Gui.Parent = (enemy.Model:FindFirstChild("Head") or enemy.Model.PrimaryPart)

	enemy.Gui.EnemyName.Text = enemy.Name
	enemy.Gui.Container.HealthBar.HP.Text = `{statistics.Health}/{statistics.MaxHealth}`

	if #mutations > 0 then
		enemy.Gui.Container.Mutations.Visible = true
	end

	if mutations["Boss"] then
		local bossBar = ReplicatedStorage.Assets.UI.Enemy.BossBar:Clone()

		bossBar.HealthBar.HP.Text = `{statistics.Health}/{statistics.MaxHealth}`
		bossBar.BossName.Text = enemy.Name
		bossBar.Parent = bossesGui.Container

		enemy.BossGui = bossBar
	end

	enemy.TweenInfo = TweenInfo.new(0.25, Enum.EasingStyle.Sine)

	enemy.Animations = enemy.Model:FindFirstChild("Animations") :: Folder or Instance.new("Folder") :: Folder
	enemy.Animations.Name = "Animations"

	if cf then
		enemy.Model:PivotTo(cf)
	end

	enemy:OnEnter()
	
	return enemy
end

--function NormalEnemy:Init()
	--warn("This function does nothing and not implemented. \n \t ENEMY - NORMAL ENEMY; \n \t CONTEXT - CLIENT")
--end

return NormalEnemy
