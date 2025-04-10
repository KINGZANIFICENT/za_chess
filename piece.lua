local Piece = {}
Piece.__index = Piece

function Piece:new(type, x, y)
    local self = setmetatable({}, Piece)
    self.type = type
    self.x = x
    self.y = y
    self.image = love.graphics.newImage("assets/" .. type .. ".png")
    return self
end

function Piece:draw(tilesize)
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(self.image, (self.x - 1) * tilesize, (self.y - 1) * tilesize)
end

return Piece

function Piece:new(type, x, y)
    local self = setmetatable({}, Piece)
    self.type = type
    self.x = x
    self.y = y
    self.color = type:sub(1,1) -- 'w' or 'b'
    self.image = love.graphics.newImage("assets/" .. type .. ".png")
    return self
end

