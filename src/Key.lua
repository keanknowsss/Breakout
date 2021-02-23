
Key = Class{}



function Key:init()
    self.x = 0
    self.y = 0

    self.scaleX = 1
    self.scaleY = 1

    self.keyed = false

    self.dy = 100

    self.width = 16
    self.height = 16

    -- variables for the timers
    self.currentSecond = 0
    self.timer = math.random(15,20)
end



function Key:update(dt)
    self.currentSecond = self.currentSecond + dt
    
    -- updates the y position when timer is reached
    -- only moves when is above the VIRTUAL_HEIGHT
    if self.currentSecond > self.timer then
        if self.y < VIRTUAL_HEIGHT + 16 then
            self.y = self.y + self.dy * dt
        end        
    end
end


function Key:collides(target)
    -- first, check to see if the left edge of either is farther to the right
    -- than the right edge of the other
    if self.x > target.x + target.width or target.x > self.x + self.width then
        return false
    end

    -- then check to see if the bottom edge of either is higher than the top
    -- edge of the other
    if self.y > target.y + target.height or target.y > self.y + self.height then
        return false
    end 

    -- if the above aren't true, they're overlapping
    return true
end



function Key:render()
    love.graphics.draw(gTextures['main'], gFrames['locked-key'], self.x, self.y, 0, self.scaleX, self.scaleY)              
end

-- resets the position of the key icon
function Key:reset()
    self.x = math.random(VIRTUAL_WIDTH - 16)
    self.y = -16
    self.currentSecond = 0
end