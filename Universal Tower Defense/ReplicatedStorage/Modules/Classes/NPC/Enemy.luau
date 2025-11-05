local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(name: string)
	local enemy = {}
	
	enemy.Name = name
	enemy.Enemy = (function()
		if script:FindFirstChild(name) then
			return require(script:FindFirstChild(name))
		else
			return {}
		end
	end)()
	
	return setmetatable(enemy, Enemy)
end

function Enemy:Destroy(...): any
	if self.Enemy and typeof(self.Enemy) == "table" then
		if self.Enemy.Destroy then
			return self.Enemy:Destroy(...)
		end
	end
end 

return Enemy
