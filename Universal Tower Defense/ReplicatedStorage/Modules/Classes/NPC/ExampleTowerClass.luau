local ExampleTower = {}
ExampleTower.__index = ExampleTower

function ExampleTower.new(id: string, skin: string, level: number, cf: CFrame, config: {}?)
    local tower = {}

    setmetatable(tower,ExampleTower)

    -- define some class members

    return tower
end

function ExampleTower:Init(...: ...any)
    -- your init method logic here, like custom abillities bindings, mechanics, etc
end

function ExampleTower:Attack(enemy: {Enemy: {}, CFrame: CFrame})
    -- your attack logic here
end

-- other class methods

return ExampleTower
