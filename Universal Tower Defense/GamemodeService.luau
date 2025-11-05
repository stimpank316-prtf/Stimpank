-- stimpank Gamemode Service for Universal Tower Defense
-- version: 0.0.2
-- ### ALPHA ### ---

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local voteFunction = ReplicatedStorage.Remotes.Gamemode.Vote

local endVoting = ReplicatedStorage.Remotes.Gamemode.EndVoting

local updateGui = ReplicatedStorage.Remotes.Gamemode.UpdateGui
local updateTime = ReplicatedStorage.Remotes.Gamemode.UpdateTime
local updateVoting = ReplicatedStorage.Remotes.Gamemode.UpdateVoting

local skipRequest = ReplicatedStorage.Remotes.Gamemode.SkipRequest
local toggleSkipGui = ReplicatedStorage.Remotes.Gamemode.ToggleSkipGui

local enemyDestroyed =  ServerStorage.Modules.Services.EnemyService.EnemyDestroyed

local EnemyService = require(ServerStorage.Modules.Services.EnemyService)

local GamemodeService = {}

local waveStructure = require(script.WaveStructure)

local SKIP_TIME = 40
local DELAY_BETWEEN_WAVES = 10

local currentWave = 0

local countdown = 0

local skipped = false
local skipVotingActive = false
local countdownActive = true
local waveEnded = false
local isLastWave = false

local currentAmbient = nil :: Sound

local maxSkips = 0

local gamemodes = {"Fire Mode"}

local votings = {
	["Fire Mode"] = {}
}

local skipChoices = {
	["No"] = false,
	["Yes"] = true
}

local random = Random.new()

local skipVotings = {}

local function ambientLoop()
	while not isLastWave do
		local ambients = ReplicatedStorage.Assets.Sounds.Game.Ambient:GetChildren()
		
		local randNumber = random:NextInteger(1, #ambients)
		
		local ambient = ambients[randNumber]
		
		if ambient:IsA("Sound") then
			if currentAmbient then
				currentAmbient:Stop()
				currentAmbient = nil
			end
			
			ambient:Play()
			
			currentAmbient = ambient
			
			ambient.Ended:Wait()
		end
		
		task.wait()
	end
end

local function stopAmbient()
	if currentAmbient then
		currentAmbient:Stop()
		currentAmbient = nil
	end
end

function GamemodeService:WaveLoop(gmName: string)
	task.spawn(ambientLoop)
	
	local gamemodeWaveStructure = waveStructure[gmName]
	local totalWaves = #gamemodeWaveStructure
	
	if gamemodeWaveStructure then
		task.spawn(function()
			local currentTime = workspace:GetServerTimeNow()
			
			while countdownActive do
				if currentTime >= countdown then
					currentTime = workspace:GetServerTimeNow()
				end
				
				if countdown > 0 and not waveEnded then
					countdown -= 1
					
					--if countdown - 20 > 0 then
					local timeLeft = countdown - math.floor( workspace:GetServerTimeNow() - currentTime )
						
					updateGui:FireAllClients(timeLeft)
					
					if timeLeft <= SKIP_TIME then
						toggleSkipGui:FireAllClients(true)
					end
					--end
				end
				
				task.wait(1)
			end
		end)
		
		for index, wave in gamemodeWaveStructure do
			waveEnded = false

			countdown = wave.Time or 60
			currentWave = index
			
			skipVotingActive = true
		
			if currentWave == totalWaves then
				isLastWave = true
			end
			
			if currentWave >= totalWaves then
				updateGui:FireAllClients(0, currentWave, "LAST WAVE! Good luck😉")
				
				task.delay(3, function()
					updateGui:FireAllClients(0, currentWave, "WAVE: THE LAST WAVE")
				end)
			end
			
			updateGui:FireAllClients(0, currentWave)
			
			for _, group in wave.Enemies do
				for i = 1, group.Quantity do
					EnemyService:SpawnEnemy(group.Name, nil, group.IsBoss)
					
					local music = ReplicatedStorage.Assets.Sounds.Game.Boss:FindFirstChild(group.Name) :: Sound
					
					if music then
						stopAmbient()
						
						music:Play()
					end
			
					task.wait(group.Delay)
				end
			end
		
			repeat 
				task.wait()
			until (#EnemyService:GetEnemiesUseArray() == 0 or skipped == true or (countdown == 0 and countdownActive) or workspace.Config.Health.Value <= 0) 
				and not isLastWave 
				or (isLastWave and #EnemyService:GetEnemiesUseArray() == 0)
			
			if skipped then
				skipped = false
			end 
			
			toggleSkipGui:FireAllClients(false)
			
			if workspace.Config.Health.Value <= 0 then
				return
			end
			
			local currentTime = workspace:GetServerTimeNow()
			
			local reward = math.floor(wave.Reward / #Players:GetPlayers())
			
			for _, player in Players:GetPlayers() do
				player.leaderstats.Money.Value += reward
			end
			
			waveEnded = true
			
			if currentWave == totalWaves  then
				break
			end
			
			while task.wait() do
				local timeLeft = DELAY_BETWEEN_WAVES - math.floor( workspace:GetServerTimeNow() - currentTime )

				if currentWave < totalWaves then
					updateGui:FireAllClients(timeLeft, currentWave, "Next wave in:", true)
				end

				if workspace:GetServerTimeNow() - currentTime >= DELAY_BETWEEN_WAVES then
					break
				end
			end
			--else
				
			--end
		end
		
		local currentTime = workspace:GetServerTimeNow()
		
		while task.wait() do
			local timeLeft = DELAY_BETWEEN_WAVES - math.floor( workspace:GetServerTimeNow() - currentTime )
			
			updateGui:FireAllClients(timeLeft, currentWave, "YOU DID IT!!! CONGRATS💪🔥😎")
			
			if workspace:GetServerTimeNow() - currentWave >= DELAY_BETWEEN_WAVES then
				break
			end
		end
		
		for _, player in Players:GetPlayers() do
			player:Kick("YOU DID IT!!!💪😎🔥")
		end
	end
end

function GamemodeService:StartVoting(cd: number)
	local currentTime = workspace:GetServerTimeNow()
	
	while task.wait() do
		local diffTime = cd - math.floor( workspace:GetServerTimeNow() - currentTime )
		
		updateTime:FireAllClients(diffTime)
		
		if workspace:GetServerTimeNow() - currentTime >= cd then
			--- code ---
			local winner = GamemodeService:EndVoting()
			
			if winner then
				currentTime = workspace:GetServerTimeNow()
				
				while task.wait() do
					local diffTime = cd - math.floor( workspace:GetServerTimeNow() - currentTime )
					
					updateTime:FireAllClients(diffTime)
					
					if workspace:GetServerTimeNow() - currentTime >= cd then
						break
					end
				end
				
				workspace.Config.IsGameRunning.Value = true
				
				table.clear(votings["Fire Mode"])
				
				GamemodeService:WaveLoop(winner)
			end
			
			break
		end
	end
end

function GamemodeService:ProcessVote(player: Player, gmName: string)
	if typeof(gmName) == "string" then
		local idx = table.find(gamemodes, gmName)
		
		if idx then
			if table.find(votings[gmName], player) then
				local idx = table.find(votings[gmName], player)
				
				table.remove(votings[gmName], idx)
			end
			
			table.insert(votings[gmName], player)
			
			updateVoting:FireAllClients(player, gmName)
			
			return true
		end
	end
	
	return false
end

function GamemodeService:ProcessSkipRequest(player: Player, choice: string)
	if not skipVotingActive then return end
	
	local encodedChoice = skipChoices[choice] :: boolean

	if encodedChoice then
		table.insert(skipVotings, {
			Player = player,
			Choice = encodedChoice
		})
	end
	
	if #skipVotings >= maxSkips then
		local skips = 0
		
		for _, choiceData in skipVotings do
			if choiceData.Choice == true then
				skips += 1
			end
		end

		if skips >= maxSkips then
			skipped = true

			table.clear(skipVotings)

			skipVotingActive = false
		end
	end
end

function GamemodeService:EndVoting(): (string, number)
	local winner = nil
	local bestScore = -math.huge
	
	for name, players in votings do
		if #players > bestScore then
			winner = name
			bestScore = #players
		end
	end
	
	if winner then
		--print(`The winner is: {winner} with score - {bestScore}`)
		
		endVoting:FireAllClients()
		
		return winner, bestScore
	end
end

voteFunction.OnServerInvoke = function(player: Player, gmName: string)
	return GamemodeService:ProcessVote(player, gmName)
end

skipRequest.OnServerEvent:Connect(function(player: Player, choice: string)
	GamemodeService:ProcessSkipRequest(player, choice)
end)

task.spawn(function()
	while task.wait(0.2) do
		maxSkips = #Players:GetPlayers()
	end
end)

return GamemodeService
