local Board = require("board")

function love.load()
    board = Board:new()
end

function love.draw()
    board:draw()
end

function love.mousepressed(x, y, button)
    board:handleClick(x, y, button)
end
