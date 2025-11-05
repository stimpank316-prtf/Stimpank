-- stimpank Inventory Controller Module for UTD

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local towersGui = playerGui:WaitForChild("Towers")

local getDataFunction = ReplicatedStorage.Remotes.Data.GetData
local getTowerDataFunction = ReplicatedStorage.Remotes.Data.GetTowerData

local PlacementController = require(script.Parent.Parent.PlacementController)

local assets = ReplicatedStorage.Assets

local InventoryController = {}

local towers = {}

local INPUT_INDEXES = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
	[Enum.KeyCode.Four] = 4,
	[Enum.KeyCode.Five] = 5
}

local SELECT_ACTION = "Select"

local function getPos()
	local location = UserInputService:GetMouseLocation()
	
	return location
end

local function offsetToScale(udim2: Vector2, parentUDim2: Vector2)
	local scaleX = udim2.X / parentUDim2.X
	local scaleY = udim2.Y / parentUDim2.Y
	
	return UDim2.fromScale(scaleX, scaleY)
end

function InventoryController:AddTower(name: string, skin: string, idx: number)
	local towerFolder = assets.Towers:FindFirstChild(name)
	
	if towerFolder then
		local skinFolder = towerFolder:FindFirstChild(skin)
		
		if skinFolder then
			local tower = skinFolder:FindFirstChild("0")
			
			local uiTower = assets.UI.Templates.UITower:Clone()
			
			local image = assets.Images.Towers:FindFirstChild(name) :: Decal
			
			if image then
				uiTower.TowerImage.Image = image.Texture
			end
			
			uiTower.Index.Text = idx
			
			uiTower.Name = name
			uiTower.Parent = towersGui.Container.Towers
			
			local towerData = getTowerDataFunction:InvokeServer(name)
			
			if towerData then
				uiTower:SetAttribute("Damage", towerData.Damage)
				uiTower:SetAttribute("Firerate", towerData.Firerate)
				uiTower:SetAttribute("Range", towerData.Range)
				uiTower:SetAttribute("Cost", towerData.Cost)
				
				uiTower:SetAttribute("Name", name)
				uiTower:SetAttribute("Skin", skin)
				
				uiTower.Cost.Text = `{towerData.Cost}$`
			end
			
			table.insert(towers, {
				Name = name,
				Skin = skin,
				
				Config = {
					Damage = towerData.Damage,
					Firerate = towerData.Firerate,
					Range = towerData.Range,
					Cost = towerData.Cost,
					
					Name = name,
					Skin = skin
				}
			})
			
			InventoryController:BindEvents(uiTower)
		end
	end
end

function InventoryController:SelectTower(idx: number)
	local towerData = towers[idx]
	
	if towerData then
		local tower = assets.Towers:FindFirstChild(towerData.Name)
		
		if not tower then return end
		
		local skin = tower:FindFirstChild(towerData.Skin)
		
		if not skin then return end
		
		local towerLevel = skin:FindFirstChild("0") :: Folder
		
		if not towerLevel then return end
		
		local towerModel = towerLevel:FindFirstChild(towerData.Name) :: Model
		
		if not towerModel then return end

       -- local range = createTemporaryRange(towerModel, towerData.Config.Range)

		PlacementController:Start(towerModel)
	end
end

function InventoryController:BindEvents(uiTower: Frame)
	local moveConnection = nil
	
	uiTower.Button.Activated:Connect(function()
		local tower = assets.Towers:FindFirstChild(uiTower:GetAttribute("Name"))
		
		if tower then
			local skin = tower:FindFirstChild(uiTower:GetAttribute("Skin"))
			
			if skin then
				local zero = skin:FindFirstChild("0"):FindFirstChild(uiTower:GetAttribute("Name"))
				
				if zero and zero:IsA("Model") then
					PlacementController:Start(zero)
				end
			end
		end
		
		ReplicatedStorage.Assets.Sounds.UI.Click:Play()
	end)
	
	uiTower.MouseEnter:Connect(function(x: number, y: number)
		local towerInfo = towersGui.TowerInfo
		towerInfo.Visible = true
		
		towerInfo.Stats.Damage.Text = `🗡{uiTower:GetAttribute("Damage")}`
		towerInfo.Stats.Firerate.Text = `⌛{uiTower:GetAttribute("Firerate")}`
		towerInfo.Stats.Range.Text = `🌍{uiTower:GetAttribute("Range")}`
		towerInfo.Stats.Cost.Text = `💸{uiTower:GetAttribute("Cost")}`
		
		towerInfo.TowerName.Text = uiTower:GetAttribute("Name")
		
		towerInfo.Position = offsetToScale(getPos(), towerInfo.Parent.AbsolutePosition)
		
		moveConnection = uiTower.MouseMoved:Connect(function(x: number, y: number)
			local pos = getPos()
			
			local scalePos = offsetToScale(pos, towerInfo.Parent.AbsoluteSize)
			
			towerInfo.Position = UDim2.fromScale(scalePos.X.Scale - 0.05, scalePos.Y.Scale - 0.3)
		end)
	end)
	
	uiTower.MouseLeave:Connect(function()
		if moveConnection then
			moveConnection:Disconnect()
			moveConnection = nil
		end
		
		towersGui.TowerInfo.Visible = false
		
		towersGui.TowerInfo.Stats.Damage.Text = ""
		towersGui.TowerInfo.Stats.Firerate.Text = ""
		towersGui.TowerInfo.Stats.Range.Text = ""
		towersGui.TowerInfo.Stats.Cost.Text = ""
		
		towersGui.TowerInfo.TowerName.Text = ""
	end)
end

ContextActionService:BindAction(SELECT_ACTION, function(_, _, input: InputObject)
	if input.UserInputState == Enum.UserInputState.Begin then
		local index = INPUT_INDEXES[input.KeyCode]

		if index then
			InventoryController:SelectTower(index)
		end
	end
end, false, Enum.KeyCode.One, Enum.KeyCode.Two, Enum.KeyCode.Three, Enum.KeyCode.Four, Enum.KeyCode.Five)

return InventoryController
