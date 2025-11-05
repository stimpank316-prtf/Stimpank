-- [CLIENT] CUSTOM TOWER MECHANICS 

local Tower = {}
Tower.__index = Tower

function Tower.new(name: string)
	local tower = {}
	
	setmetatable(tower, Tower)
	
	tower.Name = name
	tower.Tower = (function()
		local towerModule = script:FindFirstChild(tower.Name)
		
		if towerModule then
			return require(towerModule)
		else
			return {}
		end
	end)()
	
	return tower
end

function Tower:Destroy(...): any
	if self.Tower and typeof(self.Tower) == "table" then
		local main = self.Destroy
		
		if main then
			setmetatable(self, nil)
			
			return main(...)
		end
	end
	
	setmetatable(self, nil)
end

return Tower
