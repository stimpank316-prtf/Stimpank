-- Game Gui Script for UTD

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player.PlayerGui

local SKIP_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Sine)

local SKIP_GUI_GOAL_POSITION = UDim2.fromScale(0.5, 0.185)
local SKIP_GUI_DEFAULT_POSITION = UDim2.fromScale(-2, 0.185)

local HP_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Sine)

local MOVE_INFO = TweenInfo.new(0.1, Enum.EasingStyle.Circular)

local updateGui = ReplicatedStorage.Remotes.Gamemode.UpdateGui

local skipRequest = ReplicatedStorage.Remotes.Gamemode.SkipRequest
local toggleSkipGui = ReplicatedStorage.Remotes.Gamemode.ToggleSkipGui

local infoGui = playerGui:WaitForChild("Info")
local skipGui = playerGui:WaitForChild("Skip")
local gamemodeGui = playerGui:WaitForChild("Gamemodes")

local healthGui = playerGui:WaitForChild("Health")

local health = workspace.Config.Health
local maxHealth = workspace.Config.MaxHealth

local buttonBlacklist = {
	["Upgrade"] = true
}

local function checkForGameRunning()
	if workspace.Config.IsGameRunning.Value then
        gamemodeGui.Enabled = false
	end
end

local function foreachButton()
	for _, button in script.Parent:GetDescendants() do
		if button:IsA("GuiButton") and button.Name ~= "ContextActionGui" then
			if buttonBlacklist[button.Name] then continue end
			
			button.Activated:Connect(function()
				ReplicatedStorage.Assets.Sounds.UI.Click:Play()
			end)
			
			local parent = button.Parent :: Frame?
			local size = if parent:IsA("Frame") then parent.Size else UDim2.fromScale()
			
			if parent then
				parent.MouseEnter:Connect(function()
					if parent and parent:IsA("Frame") then
						TweenService:Create(
							parent,
							MOVE_INFO,
							{Size = UDim2.fromScale(
								size.X.Scale * 1.02,
								size.Y.Scale * 1.02
								)
							}
						):Play()
					end

					--ReplicatedStorage.Assets.Sounds.UI.Hover:Play()
				end)

				parent.MouseLeave:Connect(function()
					if parent and parent:IsA("Frame") then
						TweenService:Create(
							parent,
							MOVE_INFO,
							{Size = size}
						):Play()
					end
				end)
			end
			
			task.wait()
		end
	end
end

local function onHealthChanged()
	local percent = math.clamp(health.Value / maxHealth.Value, 0, maxHealth.Value)

	local size = UDim2.fromScale(percent, 1)

	TweenService:Create(
		healthGui.Container.HealthBar.Bar,
		HP_INFO, {Size = size}
	):Play()

	healthGui.Container.HP.Text = `{math.clamp(health.Value, 0, maxHealth.Value)} / {maxHealth.Value}`
end

local function initHealth()
	local percent = math.clamp(health.Value / maxHealth.Value, 0, maxHealth.Value)

	local size = UDim2.fromScale(percent, 1)

	healthGui.Container.HealthBar.Bar.Size = size

	healthGui.Container.HP.Text = `{math.clamp(health.Value, 0, maxHealth.Value)} / {maxHealth.Value}`
end

local function updateWaveGui(diffTime: number, currentWave: number, text: string?, playSFX: boolean?)
	local seconds = math.floor(diffTime % 60)
	local minutes = math.floor(diffTime / 60)
	
	local timeStr = "%.2d:%.2d"
	
	infoGui.Container.TimeLeft.Text = timeStr:format(minutes, seconds)
	
	if text then
		infoGui.Container.Text.Text = text
	else
		if currentWave then
		    infoGui.Container.Text.Text = `WAVE: {currentWave}`
		end
	end
	
	--if playSFX then
		--ReplicatedStorage.Assets.Sounds.Game.Countdown:Play()
		
		--ReplicatedStorage.Assets.Sounds.Game.Countdown.Ended:Wait()
	--end
end

local function toggleSkipFrame(enable: boolean)
	if enable then
		TweenService:Create(
			skipGui.Container,
			SKIP_INFO,
			{Position = SKIP_GUI_GOAL_POSITION}
		):Play()
	else
		TweenService:Create(
			skipGui.Container,
			SKIP_INFO,
			{Position = SKIP_GUI_DEFAULT_POSITION}
		):Play()
	end
end

local function onSkipChoiceActivated(choice: string)
	skipRequest:FireServer(choice)
	
	local tween = TweenService:Create(
		skipGui.Container,
		SKIP_INFO,
		{Position = UDim2.fromScale(2, 0.185)}
	)
	
	tween:Play()
	
	tween.Completed:Once(function()
		skipGui.Container.Visible = false
		
		skipGui.Container.Position = SKIP_GUI_DEFAULT_POSITION
		
		skipGui.Container.Visible = true
	end)
end

task.spawn(foreachButton)

initHealth()
checkForGameRunning()

skipGui.Container.Choices.Accept.Activated:Connect(function()
	onSkipChoiceActivated("Yes")
end)

skipGui.Container.Choices.Reject.Activated:Connect(function()
	onSkipChoiceActivated("No")
end)

updateGui.OnClientEvent:Connect(updateWaveGui)
toggleSkipGui.OnClientEvent:Connect(toggleSkipFrame)

health:GetPropertyChangedSignal("Value"):Connect(onHealthChanged)
