-- stimpank Placement Controller Module for UTD

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local placeFunction = ReplicatedStorage.Remotes.Placement.Place

local camera = workspace.CurrentCamera

local PlacementController = {}

PlacementController.CurrentModel = nil :: Model?
PlacementController.CurrentHighlight = nil :: Highlight?
PlacementController.RaycastParams = RaycastParams.new()
PlacementController.ModelRotation = 0

PlacementController.RaycastParams.FilterType = Enum.RaycastFilterType.Exclude

local canPlace = false

local DIRECTION_MULTIPLIER = 1000

local PLACE_INPUT = "Place"
local QUIT_INPUT = "Delete"
local ROTATE_INPUT = "Rotate"

--local ROTATION_INFO = TweenInfo.new(0.25, Enum.EasingStyle.Sine)
local ROTATION_PER_PRESS = 45

local BLOCKED_FILL_COLOR = Color3.fromRGB(255, 80, 74)
local UNBLOCKED_FILL_COLOR = Color3.fromRGB(205, 255, 112)

local DOUBLE_TAP_TIME_THRESHOLD = 0.3

local function getMouseRaycast(params: RaycastParams)
	local pos = UserInputService:GetMouseLocation()
	local ray = camera:ViewportPointToRay(pos.X, pos.Y)
	
	local origin = ray.Origin
	local direction = ray.Direction * DIRECTION_MULTIPLIER
	
	return workspace:Raycast(origin, direction, params), {origin = origin, direction = direction, offset = Vector3.new(0, PlacementController.CurrentModel:GetPivot().Y, 0)}
end

local function checkBoundingBox(model: Model)
	local overlapParams = OverlapParams.new()
	
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = {workspace.Path, workspace.Client.Towers, workspace.Client.Enemies}
	
	return workspace:GetPartBoundsInBox(model:GetPivot(), model:GetExtentsSize(), overlapParams)
end

function PlacementController:Start(model: Model)
	if PlacementController.CurrentModel then
		PlacementController:Stop()
	end
	
	PlacementController:PrepareModel(model)
	PlacementController:BindInputs()
end

function PlacementController:BindInputs()
	ContextActionService:BindAction(PLACE_INPUT, function(_, _, input: InputObject)
		local currentTime = workspace:GetServerTimeNow()
		
		if input.UserInputState == Enum.UserInputState.Begin then
			if input.UserInputType == Enum.UserInputType.Touch then
				if workspace:GetServerTimeNow() - currentTime <= DOUBLE_TAP_TIME_THRESHOLD then
					currentTime = workspace:GetServerTimeNow()
					
					PlacementController:PlaceModel()
					
					return Enum.ContextActionResult.Pass
				end
			end
			
			PlacementController:PlaceModel()
			
			return Enum.ContextActionResult.Pass
		end
	end, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch)
	
	ContextActionService:BindAction(QUIT_INPUT, function(_, _, input: InputObject)
		if input.UserInputState == Enum.UserInputState.Begin then
			PlacementController:Stop()
		end
	end, true, Enum.KeyCode.Q)
	
	ContextActionService:BindAction(ROTATE_INPUT, function(_, _, input: InputObject)
		if input.UserInputState == Enum.UserInputState.Begin then
			PlacementController.ModelRotation += ROTATION_PER_PRESS
		end
	end, true, Enum.KeyCode.R)
	
	ContextActionService:SetTitle(QUIT_INPUT, "Quit")
	ContextActionService:SetTitle(ROTATE_INPUT, "Rotate Tower")
end

function PlacementController:PrepareModel(model: Model)
	local newModel = model:Clone()
	newModel.Parent = workspace.Client.Placement
	
	local highlight = Instance.new("Highlight")
	highlight.FillColor = Color3.fromRGB(205, 255, 112)
	highlight.FillTransparency = 0.5
	highlight.Parent = newModel
	
	PlacementController.RaycastParams.FilterDescendantsInstances = {newModel}
	
	PlacementController.CurrentModel = newModel
	PlacementController.CurrentHighlight = highlight
end

function PlacementController:PlaceModel()
	if not canPlace then return end
	
	if PlacementController.CurrentModel then
		PlacementController.RaycastParams.FilterDescendantsInstances = {PlacementController.CurrentModel}
		
		local parts = checkBoundingBox(PlacementController.CurrentModel)
		
		if #parts > 0 then
			PlacementController.CurrentHighlight.FillColor = BLOCKED_FILL_COLOR
		else
			PlacementController.CurrentHighlight.FillColor = UNBLOCKED_FILL_COLOR
		end
		
		local raycast, vectors = getMouseRaycast(PlacementController.RaycastParams)
		
		vectors.rotation = PlacementController.ModelRotation
		
		local result = placeFunction:InvokeServer(PlacementController.CurrentModel.Name, vectors)
		
		if not result then
			warn("Failed to place model!")
		end
	end
end

function PlacementController:Stop()
	PlacementController.CurrentModel:Destroy()
	PlacementController.CurrentModel = nil
	
	PlacementController.CurrentHighlight:Destroy()
	PlacementController.CurrentHighlight = nil
	
	PlacementController.ModelRotation = 0
	
	PlacementController.RaycastParams = RaycastParams.new()
	
	ContextActionService:UnbindAction(QUIT_INPUT)
	ContextActionService:UnbindAction(PLACE_INPUT)
	ContextActionService:UnbindAction(ROTATE_INPUT)
end

RunService.PreRender:Connect(function()
	if PlacementController.CurrentModel then
		local raycast = getMouseRaycast(PlacementController.RaycastParams)
		
		local parts = checkBoundingBox(PlacementController.CurrentModel)

		if #parts > 0 then
			PlacementController.CurrentHighlight.FillColor = BLOCKED_FILL_COLOR
			
			canPlace = false
		else
			PlacementController.CurrentHighlight.FillColor = UNBLOCKED_FILL_COLOR
			
			canPlace = true
		end
		
		if raycast and raycast.Position then
			local pivot = PlacementController.CurrentModel:GetPivot()
			
			local cf = CFrame.new(raycast.Position.X, pivot.Y, raycast.Position.Z) * CFrame.Angles(0, math.rad(PlacementController.ModelRotation), 0)
			
			PlacementController.CurrentModel:PivotTo(cf)
		end 		
	end
end)

return PlacementController
