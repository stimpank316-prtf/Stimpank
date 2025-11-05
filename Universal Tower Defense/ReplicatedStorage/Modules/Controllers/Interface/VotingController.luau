-- stimpank Voting Controller Module for UTD

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local voteFunction = ReplicatedStorage.Remotes.Gamemode.Vote

local endVoting = ReplicatedStorage.Remotes.Gamemode.EndVoting
local updateTime = ReplicatedStorage.Remotes.Gamemode.UpdateTime
local updateVoting = ReplicatedStorage.Remotes.Gamemode.UpdateVoting

local localPlayer = Players.LocalPlayer
local playerGui = localPlayer.PlayerGui

local infoGui = playerGui.Info
local gamemodesGui = playerGui.Gamemodes

local VotingController = {}

local voted = {}
local imageBuffer = {}
local connections = {}

local PL_IMAGE_SIZE = UDim2.fromScale(0.36, 0.36)
local BORDER_RADIUS = 2
local IMAGE_INFO = TweenInfo.new(0.125, Enum.EasingStyle.Sine)

local random = Random.new(workspace:GetServerTimeNow())

local function getThumbnail(id: number, type: Enum.ThumbnailType, size: Enum.ThumbnailSize): string
	local success, image =  pcall(function()
		return Players:GetUserThumbnailAsync(id, type, size)
	end)
	
	if success then
		if image then
			return image
		end
	end
end

local function getRandomPositionUD2(childPos: Vector2, parentPos: Vector2)
	local chPosX = childPos.X
	local chPosY = childPos.Y
	
	local prPosX = parentPos.X
	local prPosY = parentPos.Y
	
	local rangeX = prPosX - BORDER_RADIUS * 2 - chPosX
	local rangeY = prPosY - BORDER_RADIUS * 2 - chPosY
	
	local finalPosX = ( math.random(rangeX) + BORDER_RADIUS + chPosX / 2) / prPosX
	local finalPosY = ( math.random(rangeY) + BORDER_RADIUS + chPosY / 2) / prPosY
	
	return UDim2.fromScale(finalPosX, finalPosY)
end

local function getVoting(player: Player)
	for _, data in voted do
		if data.Player == player then
			return data
		end
	end
end

function VotingController:BindVoting()
	for _, gmFrame in gamemodesGui.Container:GetChildren() do
		if gmFrame:IsA("Frame") then
			if gmFrame:FindFirstChildOfClass("TextButton") then
				connections[#connections + 1] = gmFrame.Button.Activated:Connect(function()
					local gmName = gmFrame.Name
					
					local result = voteFunction:InvokeServer(gmName)
					
					if result then
						VotingController:Vote(gmFrame, localPlayer)
					end
				end)
			end
		end
	end
end

function VotingController:UpdateTime(timeNumber: number)
	local seconds = math.floor(timeNumber % 60)
	local minutes = math.floor(timeNumber / 60)
	
	local str = `%.2d:%.2d`
	
	if timeNumber <= 0 then
		infoGui.Container.Text.Text = "Starting in:"
    end
	
	infoGui.Container.TimeLeft.Text = str:format(minutes, seconds)
end

function VotingController:ClearupImages()
	for _, data in voted do
		if data.Image then
			data.Image:Destroy()
		end
	end
end

function VotingController:EndVoting()
	table.clear(voted)
	
	VotingController:ClearupImages()
	
	for _, connection: RBXScriptConnection in connections do
		connection:Disconnect()
	end
	
	table.clear(connections)
	
	gamemodesGui.Enabled = false
end

function VotingController:Vote(gmFrame: Frame, player: Player)
	local gmName = gmFrame.Name

	if gmFrame.PlayersVoted:FindFirstChild(player.Name) then
		gmFrame.PlayersVoted[player.Name]:Destroy()
	end

	local image = Instance.new("ImageLabel")
	
	image.Image = (function()
		if imageBuffer[player.UserId] then
			return imageBuffer[player.UserId]
		else
			local image = getThumbnail(player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)

			if image then
				imageBuffer[player.UserId] = image

				return image
			end
		end
	end)()

	image.Size = PL_IMAGE_SIZE
	image.Position = getRandomPositionUD2(image.AbsoluteSize, gmFrame.AbsoluteSize)
	image.AnchorPoint = Vector2.one * 0.5

	image.BackgroundTransparency = 0.65
	image.BackgroundColor3 = Color3.fromRGB(60, 60, 60)

	image.ZIndex = 1

	image.Name = player.Name
	image.Parent = gmFrame.PlayersVoted
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = image
	
	local stroke = gmFrame:FindFirstChildOfClass("UIStroke")
	
	if stroke then
		local newStroke = stroke:Clone()
		newStroke.Parent = image
	end

	TweenService:Create(
		image,
		IMAGE_INFO,
		{Rotation = image.Rotation + 360}
	):Play()

	if getVoting(player) then
		local data = getVoting(player)

		data.Name = gmName
		data.GMFrame = gmFrame
		data.Image = image
	else
		table.insert(voted, {
			Name = gmName,
			Player = player,

			GMFrame = gmFrame,
			Image = image
		})
	end
end

endVoting.OnClientEvent:Connect(function()
	VotingController:EndVoting()
end)

updateTime.OnClientEvent:Connect(function(timeLeft: number)
	VotingController:UpdateTime(timeLeft)
end)

updateVoting.OnClientEvent:Connect(function(player: Player, gmName: string)
	if player == localPlayer then return end
	
	local gmFrame = gamemodesGui.Container:FindFirstChild(gmName) :: Frame?
	
	if gmFrame then
	    VotingController:Vote(gmFrame, player)
	end
end)

VotingController:BindVoting()

return VotingController
