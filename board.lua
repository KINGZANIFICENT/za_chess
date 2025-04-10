local Board = {}
Board.__index = Board

function Board:loadBoard()
    -- Load pawns
    for i = 1, 8 do
        table.insert(self.pieces, {
            type = "wp",
            x = i,
            y = 2,
            color = "w",
            draw = function(self, size)
                love.graphics.setColor(1, 1, 1)
                local img = love.graphics.newImage("assets/" .. self.type .. ".png")
                love.graphics.draw(img, (self.x - 1) * size, (self.y - 1) * size)
            end
        })

        table.insert(self.pieces, {
            type = "bp",
            x = i,
            y = 7,
            color = "b",
            draw = function(self, size)
                love.graphics.setColor(1, 1, 1)
                local img = love.graphics.newImage("assets/" .. self.type .. ".png")
                love.graphics.draw(img, (self.x - 1) * size, (self.y - 1) * size)
            end
        })
    end
end

function Board:new()
    local self = setmetatable({}, Board)
    self.tilesize = 80
    self.pieces = {}
    self.selectedPiece = nil
    self.turn = "w"
    self.validMoves = {}
    self:loadBoard()
    return self
end

function Board:getSquareFromMouse(x, y)
    local col = math.floor(x / self.tilesize) + 1
    local row = math.floor(y / self.tilesize) + 1
    return col, row
end

function Board:getPieceAt(col, row)
    for _, piece in ipairs(self.pieces) do
        if piece.x == col and piece.y == row then
            return piece
        end
    end
    return nil
end

function Board:handleClick(x, y, button)
    local col, row = self:getSquareFromMouse(x, y)
    local clickedPiece = self:getPieceAt(col, row)

    if self.selectedPiece then
        if self:isValidMove(self.selectedPiece, col, row) then
            local originalX, originalY = self.selectedPiece.x, self.selectedPiece.y
            local captured = self:getPieceAt(col, row)

            if captured and captured.color ~= self.selectedPiece.color then
                self:removePiece(captured)
            end

            self.selectedPiece.x, self.selectedPiece.y = col, row

            if self:isInCheck(self.selectedPiece.color) then
                self.selectedPiece.x, self.selectedPiece.y = originalX, originalY
                if captured then table.insert(self.pieces, captured) end
                return
            end

            self.turn = (self.turn == "w") and "b" or "w"
        end

        self.selectedPiece = nil
        self.validMoves = {}
    elseif clickedPiece and clickedPiece.color == self.turn then
        self.selectedPiece = clickedPiece
        self.validMoves = self:getValidMoves(clickedPiece)
    end
end

function Board:removePiece(target)
    for i, piece in ipairs(self.pieces) do
        if piece == target then
            table.remove(self.pieces, i)
            break
        end
    end
end

function Board:isInCheck(color)
    local king
    for _, piece in ipairs(self.pieces) do
        if piece.color == color and piece.type:sub(2) == "k" then
            king = piece
            break
        end
    end

    for _, piece in ipairs(self.pieces) do
        if piece.color ~= color then
            if self:isValidMove(piece, king.x, king.y) then
                return true
            end
        end
    end

    return false
end

function Board:draw()
    -- Draw the board
    for row = 1, 8 do
        for col = 1, 8 do
            local color = ((row + col) % 2 == 0) and {1, 1, 1} or {0.2, 0.2, 0.2}
            love.graphics.setColor(color)
            love.graphics.rectangle("fill", (col - 1) * self.tilesize, (row - 1) * self.tilesize, self.tilesize, self.tilesize)
        end
    end

    -- Draw valid moves
    for _, move in ipairs(self.validMoves) do
        love.graphics.setColor(0, 1, 0, 0.4)
        love.graphics.rectangle("fill", (move.x - 1) * self.tilesize, (move.y - 1) * self.tilesize, self.tilesize, self.tilesize)
    end

    -- Highlight selected piece
    if self.selectedPiece then
        love.graphics.setColor(1, 1, 0, 0.5)
        love.graphics.rectangle("fill", (self.selectedPiece.x - 1) * self.tilesize, (self.selectedPiece.y - 1) * self.tilesize, self.tilesize, self.tilesize)
    end

    -- Draw all pieces
    for _, piece in ipairs(self.pieces) do
        piece:draw(self.tilesize)
    end
end

function Board:isValidMove(piece, destX, destY)
    local target = self:getPieceAt(destX, destY)
    if target and target.color == piece.color then return false end

    local dx = destX - piece.x
    local dy = destY - piece.y

    if piece.type == "wp" then
        return self:isValidPawnMove(piece, destX, destY, 1)
    elseif piece.type == "bp" then
        return self:isValidPawnMove(piece, destX, destY, -1)
    elseif piece.type:sub(2) == "r" then
        return self:isValidRookMove(piece, destX, destY)
    elseif piece.type:sub(2) == "b" then
        return self:isValidBishopMove(piece, destX, destY)
    elseif piece.type:sub(2) == "n" then
        return self:isValidKnightMove(piece, destX, destY)
    elseif piece.type:sub(2) == "q" then
        return self:isValidQueenMove(piece, destX, destY)
    elseif piece.type:sub(2) == "k" then
        return self:isValidKingMove(piece, destX, destY)
    end

    return false
end

function Board:isValidKnightMove(piece, destX, destY)
    local dx = math.abs(destX - piece.x)
    local dy = math.abs(destY - piece.y)
    return (dx == 2 and dy == 1) or (dx == 1 and dy == 2)
end

function Board:isValidRookMove(piece, destX, destY)
    if piece.x ~= destX and piece.y ~= destY then return false end
    return not self:isBlockedStraight(piece.x, piece.y, destX, destY)
end

function Board:isValidBishopMove(piece, destX, destY)
    if math.abs(destX - piece.x) ~= math.abs(destY - piece.y) then return false end
    return not self:isBlockedDiagonal(piece.x, piece.y, destX, destY)
end

function Board:isValidQueenMove(piece, destX, destY)
    return self:isValidRookMove(piece, destX, destY) or self:isValidBishopMove(piece, destX, destY)
end

function Board:isValidKingMove(piece, destX, destY)
    local dx = math.abs(destX - piece.x)
    local dy = math.abs(destY - piece.y)
    return dx <= 1 and dy <= 1
end

function Board:isBlockedStraight(x1, y1, x2, y2)
    local dx = (x2 > x1) and 1 or (x2 < x1 and -1 or 0)
    local dy = (y2 > y1) and 1 or (y2 < y1 and -1 or 0)
    local x, y = x1 + dx, y1 + dy

    while x ~= x2 or y ~= y2 do
        if self:getPieceAt(x, y) then return true end
        x = x + dx
        y = y + dy
    end

    return false
end

function Board:isBlockedDiagonal(x1, y1, x2, y2)
    local dx = (x2 > x1) and 1 or -1
    local dy = (y2 > y1) and 1 or -1
    local x, y = x1 + dx, y1 + dy

    while x ~= x2 and y ~= y2 do
        if self:getPieceAt(x, y) then return true end
        x = x + dx
        y = y + dy
    end

    return false
end

function Board:isValidPawnMove(piece, destX, destY, direction)
    local dx = destX - piece.x
    local dy = destY - piece.y

    local target = self:getPieceAt(destX, destY)

    if dx == 0 then
        if dy == direction and not target then
            return true
        end

        local startRow = (direction == 1) and 2 or 7
        if piece.y == startRow and dy == direction * 2 and not target and not self:getPieceAt(destX, piece.y + direction) then
            return true
        end
    end

    if math.abs(dx) == 1 and dy == direction and target and target.color ~= piece.color then
        return true
    end

    return false
end

function Board:getValidMoves(piece)
    local moves = {}
    for x = 1, 8 do
        for y = 1, 8 do
            if self:isValidMove(piece, x, y) then
                table.insert(moves, {x = x, y = y})
            end
        end
    end
    return moves
end

return Board

