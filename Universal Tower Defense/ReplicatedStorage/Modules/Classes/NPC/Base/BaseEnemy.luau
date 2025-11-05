local TweenService = game:GetService("TweenService")

local BaseEnemy = {}
BaseEnemy.__index = BaseEnemy

function BaseEnemy:Update(data: {})
	self.Stats = {
		Health = data.Health or 1,
		MaxHealth = data.MaxHealth or 1
	}

	self.Statuses = data.Statuses or {}
	self.Mutations = data.Mutations or {}

	local sizePercent = self.Stats.Health / self.Stats.MaxHealth :: number
	
	self.Gui.Container.HealthBar.HP.Text = `{self.Stats.Health}/{self.Stats.MaxHealth}`

	local size = UDim2.fromScale(sizePercent, 1)

	TweenService:Create(
		self.Gui.Container.HealthBar.Bar,
		self.TweenInfo,
		{Size = size}
	):Play()
	
	if self.BossGui then
		self.BossGui.HealthBar.HP.Text = `{self.Stats.Health}/{self.Stats.MaxHealth}`
		
		TweenService:Create(
			self.BossGui.HealthBar.Bar,
			self.TweenInfo,
			{Size = size}
		):Play()
	end

	local xOffset = data.XOffset :: CFrame
	local pivot = self.SourceModel:GetPivot() :: CFrame
	--local yOffset = data.YOffset :: CFrame
	local cframe = data.CFrame :: CFrame
	
	local modelCFrame = CFrame.new(cframe.X, pivot.Y, cframe.Z)

	local nodes = workspace:FindFirstChild("Nodes") :: Folder

	if nodes then
		local node = nodes:FindFirstChild(`Node{data.NextNodeIndex}`) :: BasePart

		if node then
			local nodePosition = node.Position
			local lookAtPosition = Vector3.new(nodePosition.X, pivot.Y, nodePosition.Z)

			local finalCFrame = CFrame.lookAt(modelCFrame.Position, lookAtPosition) * xOffset

			TweenService:Create(
				self.Model.PrimaryPart,
				self.TweenInfo,
				{CFrame = finalCFrame}
			):Play()
			 
			local walkAnim = self.Animations:FindFirstChild("Walk") :: Animation
			
			task.spawn(function()
				if walkAnim then
					if not self.WalkTrack then
						self.WalkTrack = self.Model.Humanoid.Animator:LoadAnimation(walkAnim) :: AnimationTrack
					end
					
					if self.WalkTrack.IsPlaying then
						return true
					end

					self.WalkTrack:Play()
				end
			end)
	
			return true
		end
	end

	TweenService:Create(
		self.Model.PrimaryPart, 
		self.TweenInfo,
		{CFrame = modelCFrame * xOffset}
	):Play()
	
	return true
end

function BaseEnemy:OnEnter()
	local model = self.Model :: Model
	
	if not model then return end
	
	local detector = model:FindFirstChildOfClass("ClickDetector")
	
	if not detector then return end
	
	local highlight
	
	self.Connections = {}
	
	self.Connections["OnEnter"] = detector.MouseHoverEnter:Connect(function()
		highlight = Instance.new("Highlight")
		highlight.FillColor = Color3.fromRGB(255, 255, 255)
		highlight.FillTransparency = 1
		
		highlight.Parent = model
		
		self.Gui.Enabled = true
	end)
	
	self.Connections["OnLeave"] = detector.MouseHoverLeave:Connect(function()
		if highlight then
			highlight:Destroy()
			highlight = nil
		end
		
		self.Gui.Enabled = false
	end)
end

function BaseEnemy:Init()
	local str = "This function is NOT implemented! \n %-5d <<< ENEMY - %s >>>; \n %-5d <<< CONTEXT - CLIENT >>>; \n %-5d %s"
	
	warn(string.format(str, 1, self.Name, 2, 3, debug.traceback()))
end

function BaseEnemy:Destroy()
	if self.Model then
		self.Model:Destroy()
	end
	
	if self.BossGui then
		self.BossGui:Destroy()
	end
	
	if self.Connections then
		self.Connections.OnEnter:Disconnect()
		self.Connections.OnLeave:Disconnect()

		table.clear(self.Connections)
	end
	
	setmetatable(self, nil)
end

return BaseEnemy
