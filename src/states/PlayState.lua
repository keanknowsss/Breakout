--[[
    GD50
    Breakout Remake

    -- PlayState Class --

    Author: Colton Ogden
    cogden@cs50.harvard.edu

    Represents the state of the game in which we are actively playing;
    player should control the paddle, with the ball actively bouncing between
    the bricks, walls, and the paddle. If the ball goes below the paddle, then
    the player should lose one point of health and be taken either to the Game
    Over screen if at 0 health or the Serve screen otherwise.
]]

PlayState = Class{__includes = BaseState}

--[[
    We initialize what's in our PlayState via a state table that we pass between
    states as we go from playing to serving.
]]
function PlayState:enter(params)
    self.paddle = params.paddle
    self.bricks = params.bricks
    self.health = params.health
    self.score = params.score
    self.highScores = params.highScores
    self.ball1 = params.ball
    self.level = params.level

    self.recoverPoints = 5000

    -- give ball random starting velocity
    self.ball1.dx = math.random(-200, 200)
    self.ball1.dy = math.random(-50, -60)

    -- variables for variable size, and width (for the collisions)
    self.paddle.size = params.paddleSize
    self.paddle.width = 64
    -- variable for self size multiplier
    self.sizeUpgrader = self.score + 1000



    -- initializes the variable for the coordinates of the second ball
    -- since at the start we do not have powerup, they will be initialized first at (0,0)
    self.ball2.x = 0
    self.ball2.y = 0

    -- initializes the variable for the coordinates of the third ball
    self.ball3.x = 0
    self.ball3.y = 0

    -- initialized bricks as locked if there are locked ones
    for k, brick in pairs(self.bricks) do
        brick.lockedOpen = false
    end
end


function PlayState:init()

    -- initializes all variables for the second and third ball
    -- instantiate powerup class
    self.powerup = Powerup()
    self.powerup.y = -16

    -- draws the powerup icon when activated
    self.powerupIcon = Powerup()
    self.powerupIcon.x = VIRTUAL_WIDTH / 2 + 95
    self.powerupIcon.y = 2
    self.powerupIcon.scaleX = 0.75
    self.powerupIcon.scaleY = 0.75

    -- draws the key icon on top of the screen when activated
    self.keyIcon = Key()
    self.keyIcon.x = VIRTUAL_WIDTH / 2 + 95
    self.keyIcon.y = 2
    self.keyIcon.scaleX = 0.75
    self.keyIcon.scaleY = 0.75


    -- has a state checker whether to draw the powerup icon
    self.powerupDraw = false
    self.powerup.powered = false

    -- instantiate the variables for the new balls
    self.ball2 = Ball()
    self.ball3 = Ball()

    self.ball2.skin = math.random(7)
    self.ball3.skin = math.random(7)

    -- the new balls' initialized speed variables
    self.ball2.dx = math.random(-200, 200)
    self.ball3.dx = math.random(-200, 200)

    self.ball2.dy = math.random(-50, -60)
    self.ball3.dy = math.random(-50, -60)


    -- main ball is the variable for the ball that will be left
    -- when every ball fell down, one ball is selected to be the main ball
    -- will be used to activate the powerup even if its a different ball from the original
    self.mainBall = 1

    -- initializes the key block
    self.key = Key()

    -- its x varies, and will be changed in the update function
    self.key.x = math.random(VIRTUAL_WIDTH - 16)            
    self.key.y = -16

    -- set not active at the start
    self.key.keyed = false
    self.keyActive = false
 

end



function PlayState:update(dt)
    if self.paused then
        if love.keyboard.wasPressed('space') then
            self.paused = false
            gSounds['pause']:play()
        else
            return
        end
    elseif love.keyboard.wasPressed('space') then
        self.paused = true
        gSounds['pause']:play()
        return
    end

    self.paddle:update(dt)

    if self.powerupDraw then
        self.powerup:update(dt)
    end
    -- resets the value of the powerup when it fell at the bottom of the screen
    if self.powerup.y >= VIRTUAL_HEIGHT + 16 then
        self.powerup.y = -16
        self.powerup.x = 0
        self.powerupDraw = false
    end

    -- gets the collision of the powerup and the paddle
    -- will activate powerup 
    if self.powerup:collides(self.paddle) then
        self.powerup.y = -16
        self.powerup.x = 0

        -- activates the powerup if it is set to false
        if not self.powerup.powered then
            -- if the original ball is the one left at the screen, spawn additional balls at the paddle
            if self.mainBall == 1 then
                -- changes skin every time its activated
                self.ball2.skin = math.random(7)
                self.ball3.skin = math.random(7)

                -- spawns the additional balls at the current location of the current main ball 
                self.ball2.x, self.ball3.x = self.ball1.x, self.ball1.x
                self.ball2.y, self.ball3.y = self.ball1.y, self.ball1.y
            


            -- if the second ball is the one left at the screen 
            elseif self.mainBall == 2 then
                -- changes skin every time its activated
                self.ball1.skin = math.random(7)
                self.ball3.skin = math.random(7)
                
                -- spawns the additional balls at the current location of the current main ball 
                self.ball1.x, self.ball3.x = self.ball2.x, self.ball2.x
                self.ball1.y, self.ball3.y = self.ball2.y, self.ball2.y
            

            -- if the third ball is the one left at the screen 
            elseif self.mainBall == 3 then
                -- changes skin every time its activated
                self.ball1.skin = math.random(7)
                self.ball2.skin = math.random(7)
                
                -- spawns the additional balls at the current location of the current main ball 
                self.ball1.x, self.ball2.x = self.ball3.x, self.ball3.x
                self.ball1.y, self.ball2.y = self.ball3.y, self.ball3.y

            end
        end
        
        -- sets the powerup, and draw to true
        self.powerupDraw = false
        self.powerup.powered = true
    end

    -- the condition for when the powerup is active
    -- modifies all ball's actios
    -- all of the balls are updated, alonng with paddleCollision, bricksCollision, and gameOver 
    if self.powerup.powered then
        self.ball1:update(dt)
        self.ball2:update(dt)
        self.ball3:update(dt)
        self:paddleCollision()
        self:bricksCollision()
        self:gameOver()
    -- when the game is not in powerup mode 
    -- updates are only done to the current ball remaining on the screen
    else
    -- only update the first ball, along with its event handlers 
        if self.mainBall == 1 then
            self.ball1:update(dt)
            self:paddleCollision()
            self:bricksCollision()
    
        -- if ball goes below bounds, revert to serve state and decrease health
            if self.ball1.y >= VIRTUAL_HEIGHT + 16 then
                self.health = self.health - 1

                -- decreases size, and smallest must be at 1
                self.paddle.size = math.max(1, self.paddle.size - 1)
                gSounds['hurt']:play()
            
                if self.health == 0 then
                    gStateMachine:change('game-over', {
                        score = self.score,
                        highScores = self.highScores
                    })
                else
                    gStateMachine:change('serve', {
                        paddle = self.paddle,
                        paddleSize = self.paddle.size,
                        bricks = self.bricks,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        level = self.level,
                        recoverPoints = self.recoverPoints
                    })
                end
            end

    -- only update the second ball, along with its event handlers 
        elseif self.mainBall == 2 then
            self.ball2:update(dt)
            self:paddleCollision()
            self:bricksCollision()
            -- if ball goes below bounds, revert to serve state and decrease health
            if self.ball2.y >= VIRTUAL_HEIGHT + 16 then
                self.health = self.health - 1

                -- decreases size, and smallest must be at 1
                self.paddle.size = math.max(1, self.paddle.size - 1)
                gSounds['hurt']:play()
            
                if self.health == 0 then
                    gStateMachine:change('game-over', {
                        score = self.score,
                        highScores = self.highScores
                    })
                else
                    gStateMachine:change('serve', {
                        paddle = self.paddle,
                        paddleSize = self.paddle.size,
                        bricks = self.bricks,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        level = self.level,
                        recoverPoints = self.recoverPoints
                    })
                end
            end 

    -- only update the third ball, along with its event handlers 
        elseif self.mainBall == 3 then
            self.ball3:update(dt)
            self:paddleCollision()
            self:bricksCollision()
            -- if ball goes below bounds, revert to serve state and decrease health
            if self.ball3.y >= VIRTUAL_HEIGHT + 16 then
                self.health = self.health - 1

                -- decreases size, and smallest must be at 1
                self.paddle.size = math.max(1, self.paddle.size - 1)
                gSounds['hurt']:play()
            
                if self.health == 0 then
                    gStateMachine:change('game-over', {
                        score = self.score,
                        highScores = self.highScores
                    })
                else
                    gStateMachine:change('serve', {
                        paddle = self.paddle,
                        paddleSize = self.paddle.size,
                        bricks = self.bricks,
                        health = self.health,
                        score = self.score,
                        highScores = self.highScores,
                        level = self.level,
                        recoverPoints = self.recoverPoints
                    })
                end
            end 
        end
    end

    -- sets the current ball's variable using the self.mainBall for the arguments and conditions
    self:countBalls()


    -- argument for the paddle size upgrade and degrade
    -- increases in size per score (the reference also increases overtime) and limits at the size of 4
    if self.score > self.sizeUpgrader then
        self.paddle.size = math.min(4, self.paddle.size + 1)
        self.sizeUpgrader = self.sizeUpgrader + self.sizeUpgrader * 1.25
    end

    if self.paddle.size == 1 then
        self.paddle.width = 32
    elseif self.paddle.size == 2 then
        self.paddle.width = 64 
    elseif self.paddle.size == 3 then
        self.paddle.width = 96
    else
        self.paddle.width = 128
    end

    -- for rendering particle systems
    for k, brick in pairs(self.bricks) do
        brick:update(dt)

        -- check if a locked brick is open
        if brick.locked then
            if brick.lockOpen then
                self.keyed = false
            else
                self.keyed = true
            end
        end

    end

    -- when key is not nil 
    if self.key then

        -- key only updates when the key is not yet activated
        if self.keyed then

            if not self.keyActive then
                self.key:update(dt)
    
                if self.key.y > VIRTUAL_HEIGHT + 16 then
                    self.key:reset()   
                end
            else
                self.key:reset()
            end
        end  
        
        -- the coordinates are reset when key is active
        if self.key:collides(self.paddle) then
            self.keyActive = true
            self.key:reset()
        end
    end

    -- if there is no locked block anymore then key is set to nil
    if not self:checkKey() then
        self.key = nil
    end


    if love.keyboard.wasPressed('escape') then
        love.event.quit()
    end
end



function PlayState:render()
    -- render bricks
    for k, brick in pairs(self.bricks) do
        brick:render()
    end

    if self.keyed and self.key then
        self.key:render()
    end

    -- render all particle systems
    for k, brick in pairs(self.bricks) do
        brick:renderParticles()
    end

    self.paddle:render()

    renderScore(self.score)
    renderHealth(self.health)

    -- only draws when the powerup condition was met
    if self.powerupDraw then
        self.powerup:render()
    end

    -- draws the powerup icon when powered 
    if self.powerup.powered then
        love.graphics.setColor(0, 1, 0, 1)
        self.powerupIcon.x = VIRTUAL_WIDTH / 2 + 95
        self.powerupIcon:render()

        -- draw key icon alongside the powerup icon when active
        if self.keyActive then
            self.keyIcon.x = VIRTUAL_WIDTH / 2 + 78
            self.keyIcon:render()
        end

        love.graphics.setColor(1,1,1,1)

    -- draws the key icon when active
    elseif self.keyActive then
        love.graphics.setColor(0, 1, 0, 1)
        self.keyIcon.x = VIRTUAL_WIDTH / 2 + 95
        self.keyIcon:render()

        -- draw powerup icon alongside the key icon when active
        if self.powerup.powered then
            self.powerupIcon.x = VIRTUAL_WIDTH / 2 + 78
            self.powerupIcon:render()
        end

        love.graphics.setColor(1,1,1,1)

    end
    -- renders the current ball only when not powered up
    -- if powered then render the other balls
    if self.mainBall == 1 then
        self.ball1:render()
        if self.powerup.powered then
            self.ball2:render()
            self.ball3:render()
        end
    elseif self.mainBall == 2 then
        self.ball2:render()
        if self.powerup.powered then
            self.ball1:render()
            self.ball3:render()
        end     
    elseif self.mainBall == 3 then 
        self.ball3:render()
        if self.powerup.powered then
            self.ball1:render()
            self.ball2:render()
        end   
    end


    -- pause text, if paused
    if self.paused then
        love.graphics.setFont(gFonts['large'])
        love.graphics.printf("PAUSED", 0, VIRTUAL_HEIGHT / 2 - 16, VIRTUAL_WIDTH, 'center')
    end
end



function PlayState:checkVictory()
    for k, brick in pairs(self.bricks) do
        if brick.inPlay then
            return false
        end 
    end

    return true
end


-- handles all condition for all the ball's collision to the paddles
function PlayState:paddleCollision()

    -- collision detection for the first ball
    if self.ball1:collides(self.paddle) then
        -- raise ball1 above paddle in case it goes below it, then reverse dy
        self.ball1.y = self.paddle.y - 8
        self.ball1.dy = -self.ball1.dy

        -- tweak angle of bounce based on where it hits the paddle

        -- if we hit the paddle on its left side while moving left...
        if self.ball1.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
            self.ball1.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.ball1.x))
        
        -- else if we hit the paddle on its right side while moving right...
        elseif self.ball1.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
            self.ball1.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.ball1.x))
        end

        gSounds['paddle-hit']:play()
    end

    -- similar to the collision detection for the original ball
    -- collision detection for the second ball
    if self.ball2:collides(self.paddle) then
        -- raise ball1 above paddle in case it goes below it, then reverse dy
        self.ball2.y = self.paddle.y - 8
        self.ball2.dy = -self.ball2.dy

        -- tweak angle of bounce based on where it hits the paddle

        -- if we hit the paddle on its left side while moving left...
        if self.ball2.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
            self.ball2.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.ball2.x))
        
        -- else if we hit the paddle on its right side while moving right...
        elseif self.ball2.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
            self.ball2.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.ball2.x))
        end

        gSounds['paddle-hit']:play()
    end

    -- similar to the collision detection for the original ball
    -- collision detection for the third ball
    if self.ball3:collides(self.paddle) then
        -- raise ball3 above paddle in case it goes below it, then reverse dy
        self.ball3.y = self.paddle.y - 8
        self.ball3.dy = -self.ball3.dy

        -- tweak angle of bounce based on where it hits the paddle

        -- if we hit the paddle on its left side while moving left...
        if self.ball3.x < self.paddle.x + (self.paddle.width / 2) and self.paddle.dx < 0 then
            self.ball3.dx = -50 + -(8 * (self.paddle.x + self.paddle.width / 2 - self.ball3.x))
        
        -- else if we hit the paddle on its right side while moving right...
        elseif self.ball3.x > self.paddle.x + (self.paddle.width / 2) and self.paddle.dx > 0 then
            self.ball3.dx = 50 + (8 * math.abs(self.paddle.x + self.paddle.width / 2 - self.ball3.x))
        end

        gSounds['paddle-hit']:play()
    end
end


-- handles all condition for all the ball's collision to the bricks
function PlayState:bricksCollision()
    
    -- detect collision across all bricks with the ball
    -- collision of bricks to the ball
    for k, brick in pairs(self.bricks) do

        -- only check collision if we're in play
        -- CONDITION FOR THE FIRST BALL'S COLLISION
        if brick.inPlay and self.ball1:collides(brick) then


            -- whenever the ball hit a high color or a tier from 2 to 5, or reaches a score divisible by 2000, or by chance function
            if (not self.score == 0 and self.score % 2000 == 0) or brick.color == math.random(4,5) or brick.tier == math.random(2,5) or self:chance() and (not brick.locked or self.keyActive) then
                if not self.powerup.powered then
                    self.powerupDraw = true
                    self.powerup.x = brick.x + math.random(brick.width/2, brick.width) - 16
                    self.powerup.y = brick.y + brick.height                    
                end
            end
        
            -- unlocks the locked block
            if self.keyActive then
                brick.lockedOpen = true
            end
            -- add to score
            -- scoring is different to a locked block
            if brick.locked then
                if brick.lockedOpen then
                    self.score = self.score + 1000
                    self.keyActive = false
                end

            else
                self.score = self.score + (brick.tier * 200 + brick.color * 25)
            end
        
            -- trigger the brick's hit function, which removes it from play
            brick:hit()
        
            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)
        
                -- multiply recover points by 2
                self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)
        
                -- play recover sound effect
                gSounds['recover']:play()
            end
        
            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()
        
                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    paddleSize = self.paddle.size,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball1,
                    recoverPoints = self.recoverPoints
                })
            end
        
            -- collision code for bricks
            --
            -- we check to see if the opposite side of our velocity is outside of the brick;
            -- if it is, we trigger a collision on that side. else we're within the X + width of
            -- the brick and should check to see if the top or bottom edge is outside of the brick,
            -- colliding on the top or bottom accordingly 
        
            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            if self.ball1.x + 2 < brick.x and self.ball1.dx > 0 then
                
                -- flip x velocity and reset position outside of brick
                self.ball1.dx = -self.ball1.dx
                self.ball1.x = brick.x - 8
            
            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            elseif self.ball1.x + 6 > brick.x + brick.width and self.ball1.dx < 0 then
                
                -- flip x velocity and reset position outside of brick
                self.ball1.dx = -self.ball1.dx
                self.ball1.x = brick.x + 32
            
            -- top edge if no X collisions, always check
            elseif self.ball1.y < brick.y then
                
                -- flip y velocity and reset position outside of brick
                self.ball1.dy = -self.ball1.dy
                self.ball1.y = brick.y - 8
            
            -- bottom edge if no X collisions or top collision, last possibility
            else
                
                -- flip y velocity and reset position outside of brick
                self.ball1.dy = -self.ball1.dy
                self.ball1.y = brick.y + 16
            end
        
            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(self.ball1.dy) < 150 then
                self.ball1.dy = self.ball1.dy * 1.02
            end
        
            -- only allow colliding with one brick, for corners
            break
        end

        -- CONDITION FOR THE SECOND BALL'S COLLISION
        -- only check collision if we're in play
        if brick.inPlay and self.ball2:collides(brick) then

            -- whenever the ball hit a high color or a tier from 2 to 5, or reaches a score divisible by 2000, or by chance function
            if (not self.score == 0 and self.score % 2000 == 0) or brick.color == 5 or brick.tier == math.random(2,5) or self:chance() and (not brick.locked or self.keyActive) then
                if not self.powerup.powered then
                    self.powerupDraw = true
                    self.powerup.x = brick.x + math.random(brick.width/2, brick.width) - 16
                    self.powerup.y = brick.y + brick.height                    
                end
            end
            -- unlocks the locked block
            if self.keyActive then
                brick.lockedOpen = true
            end
            -- add to score    
            -- scoring is different to a locked block
            if brick.locked then
                if brick.lockedOpen then
                    self.score = self.score + 1000
                    self.keyActive = false
                end

            else
                self.score = self.score + (brick.tier * 200 + brick.color * 25)
            end

            -- trigger the brick's hit function, which removes it from play
            brick:hit()

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)

                -- multiply recover points by 2
                self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                -- play recover sound effect
                gSounds['recover']:play()
            end

            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()

                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    paddleSize = self.paddle.size,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball2,
                    recoverPoints = self.recoverPoints
                })
            end

            --
            -- collision code for bricks
            --
            -- we check to see if the opposite side of our velocity is outside of the brick;
            -- if it is, we trigger a collision on that side. else we're within the X + width of
            -- the brick and should check to see if the top or bottom edge is outside of the brick,
            -- colliding on the top or bottom accordingly 
            --

            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            if self.ball2.x + 2 < brick.x and self.ball2.dx > 0 then
                
                -- flip x velocity and reset position outside of brick
                self.ball2.dx = -self.ball2.dx
                self.ball2.x = brick.x - 8
            
            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            elseif self.ball2.x + 6 > brick.x + brick.width and self.ball2.dx < 0 then
                
                -- flip x velocity and reset position outside of brick
                self.ball2.dx = -self.ball2.dx
                self.ball2.x = brick.x + 32
            
            -- top edge if no X collisions, always check
            elseif self.ball2.y < brick.y then
                
                -- flip y velocity and reset position outside of brick
                self.ball2.dy = -self.ball2.dy
                self.ball2.y = brick.y - 8
            
            -- bottom edge if no X collisions or top collision, last possibility
            else
                
                -- flip y velocity and reset position outside of brick
                self.ball2.dy = -self.ball2.dy
                self.ball2.y = brick.y + 16
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(self.ball2.dy) < 150 then
                self.ball2.dy = self.ball2.dy * 1.02
            end

            -- only allow colliding with one brick, for corners
            break
        end
        

        -- CONDITION FOR THE THIRD BALL'S COLLISION
        -- only check collision if we're in play
        if brick.inPlay and self.ball3:collides(brick) then

            -- whenever the ball hit a high color or a tier from 2 to 5, or reaches a score divisible by 2000, or by chance function
            if (not self.score == 0 and self.score % 2000 == 0) or brick.color == 5 or brick.tier == math.random(2,5) or self:chance() and (not brick.locked or self.keyActive) then
                if not self.powerup.powered then
                    self.powerupDraw = true
                    self.powerup.x = brick.x + math.random(brick.width/2, brick.width) - 16
                    self.powerup.y = brick.y + brick.height                    
                end
            end
            -- unlocks the locked block
            if self.keyActive then
                brick.lockedOpen = true
            end
            -- add to score
            -- scoring is different to a locked block
            if brick.locked then
                if brick.lockedOpen then
                    self.score = self.score + 1000
                    self.keyActive = false
                end

            else
                self.score = self.score + (brick.tier * 200 + brick.color * 25)
            end

            -- trigger the brick's hit function, which removes it from play
            brick:hit()

            -- if we have enough points, recover a point of health
            if self.score > self.recoverPoints then
                -- can't go above 3 health
                self.health = math.min(3, self.health + 1)

                -- multiply recover points by 2
                self.recoverPoints = self.recoverPoints + math.min(100000, self.recoverPoints * 2)

                -- play recover sound effect
                gSounds['recover']:play()
            end

            -- go to our victory screen if there are no more bricks left
            if self:checkVictory() then
                gSounds['victory']:play()

                gStateMachine:change('victory', {
                    level = self.level,
                    paddle = self.paddle,
                    paddleSize = self.paddle.size,
                    health = self.health,
                    score = self.score,
                    highScores = self.highScores,
                    ball = self.ball3,
                    recoverPoints = self.recoverPoints
                })
            end

            -- collision code for bricks
            --
            -- we check to see if the opposite side of our velocity is outside of the brick;
            -- if it is, we trigger a collision on that side. else we're within the X + width of
            -- the brick and should check to see if the top or bottom edge is outside of the brick,
            -- colliding on the top or bottom accordingly 

            -- left edge; only check if we're moving right, and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            if self.ball3.x + 2 < brick.x and self.ball3.dx > 0 then
                
                -- flip x velocity and reset position outside of brick
                self.ball3.dx = -self.ball3.dx
                self.ball3.x = brick.x - 8
            
            -- right edge; only check if we're moving left, , and offset the check by a couple of pixels
            -- so that flush corner hits register as Y flips, not X flips
            elseif self.ball3.x + 6 > brick.x + brick.width and self.ball3.dx < 0 then
                
                -- flip x velocity and reset position outside of brick
                self.ball3.dx = -self.ball3.dx
                self.ball3.x = brick.x + 32
            
            -- top edge if no X collisions, always check
            elseif self.ball3.y < brick.y then
                
                -- flip y velocity and reset position outside of brick
                self.ball3.dy = -self.ball3.dy
                self.ball3.y = brick.y - 8
            
            -- bottom edge if no X collisions or top collision, last possibility
            else
                
                -- flip y velocity and reset position outside of brick
                self.ball3.dy = -self.ball3.dy
                self.ball3.y = brick.y + 16
            end

            -- slightly scale the y velocity to speed up the game, capping at +- 150
            if math.abs(self.ball3.dy) < 150 then
                self.ball3.dy = self.ball3.dy * 1.02
            end

            -- only allow colliding with one brick, for corners
            break
        end        
    end
end


function PlayState:gameOver()
    -- if ball goes below bounds, revert to serve state and decrease health
    -- when all balls fall
    if self.ball1.y >= VIRTUAL_HEIGHT and self.ball2.y >= VIRTUAL_HEIGHT and self.ball3.y >= VIRTUAL_HEIGHT then
        self.health = self.health - 1
        self.paddle.size = math.max(1, self.paddle.size - 1)
        gSounds['hurt']:play()

        if self.health == 0 then
            gStateMachine:change('game-over', {
                score = self.score,
                highScores = self.highScores
            })
        else
            gStateMachine:change('serve', {
                paddle = self.paddle,
                bricks = self.bricks,
                health = self.health,
                score = self.score,
                highScores = self.highScores,
                level = self.level,
                recoverPoints = self.recoverPoints
            })
        end
    end    
end


-- swaps the number of balls left on the screen
function PlayState:countBalls()
    -- sets the current ball as the remaining ball left on the screen
    -- then the powerup is set to false
    if self.ball2.y > VIRTUAL_HEIGHT + 16 and self.ball3.y > VIRTUAL_HEIGHT + 16 then
        self.mainBall = 1
        self.powerup.powered = false
    elseif self.ball1.y > VIRTUAL_HEIGHT + 16 and self.ball3.y > VIRTUAL_HEIGHT + 16 then
        self.mainBall = 2
        self.powerup.powered = false
    elseif self.ball1.y > VIRTUAL_HEIGHT + 16 and self.ball2.y > VIRTUAL_HEIGHT + 16 then
        self.mainBall = 3
        self.powerup.powered = false
    end
end



function PlayState:chance()
    -- self made chance for a decision making 
    local in1 = math.random(2) == 1 and true or false
    local in2 = math.random(2) ==  1 and true or false
    local in3 = math.random(2) == 1 and true or false
    local in4 = math.random(2) == 1 and true or false

    if in1 then
        if in2 then
            if in3 then
                if in4 then
                    return true
                end
            end
        end
    end

    return false
end


-- checks if there are locked bricks remaining
function PlayState:checkKey()
    for k, brick in pairs(self.bricks) do
        if brick.locked and brick.inPlay then
            return true
        end
    end

    return false
end