-- stimpank Upgrade Handler Module for UTD

local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local upgradeTower = ReplicatedStorage.Remotes.Tower.UpgradeTower
local sellTower = ReplicatedStorage.Remotes.Tower.SellTower
local changeTarget = ReplicatedStorage.Remotes.Tower.ChangeTarget

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local upgradeGui = playerGui:WaitForChild("UpgradeGui")

local UpgradeHandler = {}

local function createRange(tower: Model, rangeUnit: number)
	local highlight = Instance.new("Highlight")
	highlight.FillTransparency = 1

	highlight:AddTag("InGuiCosmetics")

	highlight.Parent = tower

	local pivot = tower:GetPivot() :: CFrame

	local part = Instance.new("Part")
	part.Size = Vector3.new(0.15, rangeUnit * 2, rangeUnit * 2)
	part.Position = Vector3.new(pivot.X, 0.5, pivot.Z)
	part.Orientation = Vector3.new(0, 0, 90)

	part.Color = Color3.fromRGB(98, 166, 255)
	part.Transparency = 0.65

	part.Anchored = true
	part.CanCollide = false

	part.Shape = Enum.PartType.Cylinder

	part:AddTag("InGuiCosmetics")

	part.Name = "Range"
	part.Parent = tower
	
	return part, highlight
end

local function setStats(tower: Model)
	if tower:FindFirstChild("Stats") and tower:FindFirstChild("Stats"):FindFirstChild("UpgradeStats") then
		upgradeGui.Adornee = tower:FindFirstChild("Head") :: MeshPart
		
		upgradeGui.Container.TowerName.Text = tower.Stats.TowerName.Value

		upgradeGui.Container.Stats.Damage.Text = `🗡{tower.Stats.Damage.Value}`
		upgradeGui.Container.Stats.Firerate.Text = `⌛{tower.Stats.Firerate.Value}`
		upgradeGui.Container.Stats.Range.Text = `🌍{tower.Stats.Range.Value}`

		upgradeGui.Container.OtherStats.TotalDamage.TotalDamage.Text = tower.Stats.TotalDamage.Value
		upgradeGui.Container.OtherStats.TotalCost.TotalCost.Text = tower.Stats.TotalCost.Value

		upgradeGui.Container.UpgStats.Damage.Text = `🗡{tower.Stats.Damage.Value} -> {tower.Stats.UpgradeStats.Damage.Value}`
		upgradeGui.Container.UpgStats.Firerate.Text = `⌛{tower.Stats.Firerate.Value} -> {tower.Stats.UpgradeStats.Firerate.Value}`
		upgradeGui.Container.UpgStats.Range.Text = `🌍{tower.Stats.Range.Value} -> {tower.Stats.UpgradeStats.Range.Value}`

		upgradeGui.Container.Upgrade.Text = `Upgrade ({tower.Stats.UpgradeStats.UpgradeCost.Value}$)`
		upgradeGui.Container.Target.Text = `Target: {tower.Stats.Target.Value}`
		upgradeGui.Container.UpgStats.Description.Text = tower.Stats.UpgradeStats.Description.Value

		upgradeGui.Container.Sell.Text = `Sell ({tower.Stats.SellCost.Value}$)`

		upgradeGui.Container.Images.Level.Text = tostring(tower.Stats.Level.Value)
	end
end

function UpgradeHandler:onClose()
	upgradeGui.Container.Exit.Activated:Connect(function()
		upgradeGui.Enabled = false
		
		for _, cosmetic in CollectionService:GetTagged("InGuiCosmetics") do
			cosmetic:Destroy()
		end
	end)
end

function UpgradeHandler:bindEvents()
	upgradeGui.Container.Upgrade.Activated:Connect(function()
		if ReplicatedStorage.Config:GetAttribute("SelectedTowerId") ~= "" then
			ReplicatedStorage.Assets.Sounds.UI.Purchase:Play()
			
			UpgradeHandler:tryUpgrade(ReplicatedStorage.Config:GetAttribute("SelectedTowerId"))
		end
	end)
	
	upgradeGui.Container.Sell.Activated:Connect(function()
		if ReplicatedStorage.Config:GetAttribute("SelectedTowerId") ~= "" then
			UpgradeHandler:sellTower(ReplicatedStorage.Config:GetAttribute("SelectedTowerId"))
			
			for _, cosmetic in CollectionService:GetTagged("InGuiCosmetics") do
				cosmetic:Destroy()
			end
			
			upgradeGui.Enabled = false
		end
	end)
	
	upgradeGui.Container.Target.Activated:Connect(function()
		if ReplicatedStorage.Config:GetAttribute("SelectedTowerId") ~= "" then
			changeTarget:FireServer(ReplicatedStorage.Config:GetAttribute("SelectedTowerId"))
		end
	end)
end

function UpgradeHandler:bind(tower: {})
	local model = tower.Tower.Model :: Model
	
	local detector = model:FindFirstChildOfClass("ClickDetector")
	
	if not detector then return end
	
	tower.Connections["Click"] = detector.MouseClick:Connect(function(playerWhoClicked: Player)
		if playerWhoClicked ~= tower.Player then return end		
		
		--print("yay click detector")
		
		upgradeGui.Enabled = not upgradeGui.Enabled
		
		if upgradeGui.Enabled then
			local rangeUnit = model.Stats.Range.Value
			
			createRange(model, rangeUnit)
			
			setStats(model)
			
			ReplicatedStorage.Config:SetAttribute("SelectedTowerId", tower.Id)
			
			task.spawn(function()
				while upgradeGui.Enabled and model do
					if model:FindFirstChild("Stats") then
						upgradeGui.Container.OtherStats.TotalDamage.TotalDamage.Text = model.Stats.TotalDamage.Value
						upgradeGui.Container.OtherStats.TotalCost.TotalCost.Text = model.Stats.TotalCost.Value
						upgradeGui.Container.Target.Text = `Target: {model.Stats.Target.Value}`
					end

					task.wait()
				end
			end)
		else
			for _, cosmetic in CollectionService:GetTagged("InGuiCosmetics") do
				cosmetic:Destroy()
			end
		end
	end)
	
	local highlight
	
	tower.Connections["OnEnter"] = detector.MouseHoverEnter:Connect(function()
		highlight = Instance.new("Highlight")
		highlight.FillTransparency = 1
		highlight.Parent = model
	end)
	
	tower.Connections["OnLeave"] = detector.MouseHoverLeave:Connect(function()
		if highlight then
			highlight:Destroy()
			highlight = nil
		end
	end)
end

function UpgradeHandler:tryUpgrade(id: string)
	local result = upgradeTower:InvokeServer(id)
	
	if result ~= nil then
		local tower = ReplicatedStorage.Assets.Towers:FindFirstChild(result.Name)
		local oldTower = workspace.Client.Towers:FindFirstChild(id)
		
		if tower and oldTower then
			local towerLevel = tower:FindFirstChild(result.Skin):FindFirstChild(result.Level)
			
			if towerLevel then
				local newTowerLevel = towerLevel:FindFirstChild(result.Name):Clone() :: Model
				
				if newTowerLevel then
					oldTower:Destroy()
					
					oldTower = nil
					
					task.wait(0.15)
					
					local tower = workspace.Client.Towers:FindFirstChild(id)
					
					if tower then
						local rangeUnit = tower.Stats.Range.Value
						
                        createRange(tower, rangeUnit)

						setStats(tower)
						
						task.spawn(function()
							while upgradeGui.Enabled do
								if tower:FindFirstChild("Stats") then
									upgradeGui.Container.OtherStats.TotalDamage.TotalDamage.Text = tower.Stats.TotalDamage.Value
									upgradeGui.Container.OtherStats.TotalCost.TotalCost.Text = tower.Stats.TotalCost.Value
									upgradeGui.Container.Target.Text = `Target: {tower.Stats.Target.Value}`
								end

								task.wait()
							end
						end)
					end

					return true
				end
			end
	
			setStats(oldTower)
			
			--ReplicatedStorage.Config:SetAttribute("SelectedTowerId", "")
			
			local range = oldTower:FindFirstChild("Range")
			
			if range then
				if range:IsA("BasePart") then
					local rangeUnit = oldTower.Stats.Range.Value

					range.Size = Vector3.new(0.2, rangeUnit * 2, rangeUnit * 2)
				end
			end
			
			return true
		end
	end
end

function UpgradeHandler:sellTower(id: string)
	sellTower:FireServer(id)
end

UpgradeHandler:bindEvents()
UpgradeHandler:onClose()

return UpgradeHandler
