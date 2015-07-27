require "Helper"
require "AttackCommand"
--type


Actor = class ("Actor", function ()
    local node = cc.Sprite3D:create()
    node:setCascadeColorEnabled(true)
	return node
end)

function Actor:ctor()
    self._action = {}
    --通过拷贝配置来获取自己独立的一套成员变量
    copyTable(ActorDefaultValues,self)
    copyTable(ActorCommonValues, self)
    
    --dropblood
    self._hpCounter = require "HPCounter":create()
    self:addChild(self._hpCounter)
    self._effectNode = cc.Node:create()
    self._monsterHeight = 70
    self._heroHeight = 150
    self._heroMoveSpeed = 0
    self._heroMoveDir = cc.p(0, 0)
    
    if uiLayer~=nil then
        currentLayer:addChild(self._effectNode)
    end
end

--给角色添加特效攻击
function Actor:addEffect(effect)
    effect:setPosition(cc.pAdd(getPosTable(self), getPosTable(effect)))
    if self._racetype ~= EnumRaceType.MONSTER then --如果不是monster
        effect:setPositionZ(self:getPositionZ() + self._heroHeight)
    else                                           --如果是monster
        effect:setPositionZ(self:getPositionZ() + self._monsterHeight + effect:getPositionZ())
    end
    currentLayer:addChild(effect)
end

--角色跑起来的烟尘
function Actor:initPuff()
    local puff = cc.BillboardParticleSystem:create(ParticleManager:getInstance():getPlistData("walkpuff"))
    local puffFrame = cc.SpriteFrameCache:getInstance():getSpriteFrame("walkingPuff.png")
    puff:setTextureWithRect(puffFrame:getTexture(), puffFrame:getRect())
    puff:setScale(1.5)
    puff:setGlobalZOrder(0)
    puff:setPositionZ(10)
    self._puff = puff
    self._effectNode:addChild(puff)
end

function Actor.create()
    local base = Actor.new()	
	return base
end

--角色的影子,角色属性 _circle 决定影子大小，然后用图片和透明度来实现。
function Actor:initShadow()
    self._circle = cc.Sprite:createWithSpriteFrameName("shadow.png")
    --use Shadow size for aesthetic, use radius to see collision size
    self._circle:setScale(self._shadowSize/16)
    --self._circle:setScale(self._radius/8)
	self._circle:setOpacity(255*0.7)
	self:addChild(self._circle)
end

--由继承者在文件中实现
function Actor:playAnimation(name, loop)
    if self._curAnimation ~= name then --当前播放的不是 请求的 动画
        self._sprite3d:stopAllActions()--停止所有动画
        if loop then
            self._curAnimation3d = cc.RepeatForever:create(self._action[name]:clone())
        else
            --值得注意的是为什么在执行一个动作的时候要使用clone()呢? 因为actor中_action的内容会随着子类对象的创建被重新赋值
            self._curAnimation3d = self._action[name]:clone()
        end
        --运行动画，并且设置该动画为当前播放动画
        self._sprite3d:runAction(self._curAnimation3d)
        self._curAnimation = name
    end
end

--getter & setter

-- get hero type
function Actor:getRaceType()
    return self._racetype
end

function Actor:setRaceType(type)
	self._racetype = type
end

function Actor:getStateType()
    return self._statetype
end

function Actor:setStateType(type)
	self._statetype = type
    --add puff particle
    if self._puff then
        if type == EnumStateType.WALKING then
            self._puff:setEmissionRate(5)
        else
            self._puff:setEmissionRate(0)
        end
    end
end

function Actor:setTarget(target)
    if self._target ~= target then
        self._target = target
    end
end

--设置角色的朝向
function Actor:setFacing(degrees)
    self._curFacing = DEGREES_TO_RADIANS(degrees)-- _curFacing：当前朝向，用于攻击的时候提供发射方向
    self._targetFacing = self._curFacing         -- _targetFacing：正对目标的朝向
    self:setRotation(degrees)
end

function Actor:getAIEnabled()
    return self._AIEnabled
end

function Actor:setAIEnabled(enable)
    self._AIEnabled = enable
end

function Actor:hurtSoundEffects()
-- to override
end

--攻击者，是带有敲打效果的
function Actor:hurt(collider, dirKnockMode)
    --首先自己要活着
    if self._isalive == true then 
        --TODO add sound effect
                    
        local damage = collider.damage
        --calculate the real damage
        local critical = false
        local knock = collider.knock
        --看本次攻击是否暴击
        if math.random() < collider.criticalChance then
            damage = damage * 1.5
            critical = true
            knock = knock * 2
        end
        --计算伤害
        damage = damage + damage * math.random(-1,1) * 0.15        
        damage = damage - self._defense
        damage = math.floor(damage)

        if damage <= 0 then
            damage = 1
        end
        self._hp = self._hp - damage

        if self._hp > 0 then
            if collider.knock and damage ~= 1 then
                self:knockMode(collider, dirKnockMode)--看是否进入knockmode
                self:hurtSoundEffects()
            else
                self:hurtSoundEffects()
            end
        else
            self._hp = 0
            self._isalive = false --角色死亡，进入dyingMode
            self:dyingMode(getPosTable(collider),knock)        
        end
        
        --three param judge if crit
        local blood = self._hpCounter:showBloodLossNum(damage,self,critical)
        self:addEffect(blood)
        return damage        
    end
    return 0
end

function Actor:normalAttackSoundEffects()
-- to override
end

function Actor:specialAttackSoundEffects()
-- to override
end

--======attacking collision check
function Actor:normalAttack()
    BasicCollider.create(self._myPos, self._curFacing, self._normalAttack)
    self:normalAttackSoundEffects()
end

function Actor:specialAttack()
    BasicCollider.create(self._myPos, self._curFacing, self._specialAttack)
    self:specialAttackSoundEffects()
end

--======State Machine switching functions, 各种mode其实就是执行一下对应的动画
function Actor:idleMode() --switch into idle mode
    self:setStateType(EnumStateType.IDLE)
    self:playAnimation("idle", true)
end

function Actor:walkMode() --switch into walk mode
    self:setStateType(EnumStateType.WALKING)
    self:playAnimation("walk", true)
end

function Actor:attackMode() --switch into walk mode
    self:setStateType(EnumStateType.ATTACKING)
    self:playAnimation("idle", true)
    self._attackTimer = self._attackFrequency * 3 / 4
end

--实际上就是做了个位移,位移的距离取决于攻击属性的knock。
function Actor:knockMode(collider, dirKnockMode)
    self:setStateType(EnumStateType.KNOCKING)
    self:playAnimation("knocked")
    
    self._timeKnocked = self._aliveTime
    local p = self._myPos
    local angle 
    if dirKnockMode then
        angle = collider.facing
    else
        angle = cc.pToAngleSelf(cc.pSub(p, getPosTable(collider)))
    end
    
    local newPos = cc.pRotateByAngle(cc.pAdd({x=collider.knock, y=0}, p), p, angle)
    self:runAction(cc.EaseCubicActionOut:create(cc.MoveTo:create(self._action.knocked:getDuration() * 3, newPos)))
--    self:setCascadeColorEnabled(true)--if special attack is interrupted then change the value to true      
end

function Actor:playDyingEffects()
   -- override
end

--死亡模式
function Actor:dyingMode(knockSource, knockAmount)
    --死亡特效
    self:setStateType(EnumStateType.DYING)
    self:playAnimation("dead")
    self:playDyingEffects()
    
    if self._racetype == EnumRaceType.HERO then
        --回收对象
        uiLayer:heroDead(self)
        List.removeObj(HeroManager,self) 
        self:runAction(cc.Sequence:create(cc.DelayTime:create(3),cc.MoveBy:create(1.0,cc.V3(0,0,-50)),cc.RemoveSelf:create()))
        
        self._angry = 0
        local anaryChange = {_name = self._name, _angry = self._angry, _angryMax = self._angryMax}
        MessageDispatchCenter:dispatchMessage(MessageDispatchCenter.MessageType.ANGRY_CHANGE, anaryChange)          
    else --可以看到这里有一个3秒后回收到pool的操作
        List.removeObj(MonsterManager,self) 
        local function recycle()
            self:setVisible(false)
            List.pushlast(getPoolByName(self._name),self)
        end
        self:runAction(cc.Sequence:create(cc.DelayTime:create(3),cc.MoveBy:create(1.0,cc.V3(0,0,-50)),cc.CallFunc:create(recycle)))
    end
    
    if knockAmount then
        local p = self._myPos
        local angle = cc.pToAngleSelf(cc.pSub(p, knockSource))
        local newPos = cc.pRotateByAngle(cc.pAdd({x=knockAmount,y=0}, p),p,angle)
        self:runAction(cc.EaseCubicActionOut:create(cc.MoveTo:create(self._action.knocked:getDuration()*3,newPos)))
    end
    self._AIEnabled = false
end

--=======Base Update Functions
--状态机循环更新，配合Actor:AI()两个函数使用
function Actor:stateMachineUpdate(dt)
    local state = self:getStateType()
    
    --执行相应更新状态的函数
    if state == EnumStateType.WALKING  then
        self:walkUpdate(dt)
    elseif state == EnumStateType.IDLE then
        --do nothing :p
    elseif state == EnumStateType.ATTACKING then
        --I am attacking someone, I probably has a target
        self:attackUpdate(dt)
    elseif state == EnumStateType.DEFENDING then
        --I am trying to defend from an attack, i need to finish my defending animation
        --TODO: update for defending
    elseif state == EnumStateType.KNOCKING then
        --I got knocked from an attack, i need time to recover
        self:knockingUpdate(dt)
    elseif state == EnumStateType.DYING then
        --I am dying.. there is not much i can do right?
    end
end

--这里要修改成，只有怪物着英雄，英雄不找怪物
function Actor:_findEnemy(HeroOrMonster)
    local shortest = self._searchDistance
    local target = nil
    local allDead = true
    local manager = nil
    
    if HeroOrMonster == EnumRaceType.MONSTER then
        manager = HeroManager
    else
        --如果参数传进来的是英雄，直接返回空目标，并且allDead 为true，即关闭英雄的AI
        return nil, true
        --manager = MonsterManager
    end
    
    for val = manager.first, manager.last do
        local temp = manager[val]
        local dis = cc.pGetDistance(self._myPos,temp._myPos)
        if temp._isalive then
            if dis < shortest then
                shortest = dis
                target = temp
            end
            allDead = false
        end
    end
    
    return target, allDead
end

function Actor:_inRange()
    if not self._target then
        return false
    elseif self._target._isalive then
        local attackDistance = self._attackRange + self._target._radius -1
        local p1 = self._myPos
        local p2 = self._target._myPos
        return (cc.pGetDistance(p1,p2) < attackDistance)
    end
end

--AI function does not run every tick
--该函数和stateMachineUpdate共同完成了状态机的正常运转，主要负责根据当前的状态选择下一步行动,并激活状态。
function Actor:AI()
    --如果是英雄，则不执行任何AI, 全部由摇杆控制
    if self._racetype == EnumRaceType.HERO then
        return true
    end
    
    if self._isalive then
        local state = self:getStateType()
        local allDead
        --如果找不到敌人了
        self._target, allDead = self:_findEnemy(self._racetype)
        --if i can find a target
        if self._target then
            local p1 = self._myPos
            local p2 = self._target._myPos
            --改变自己的朝向
            self._targetFacing =  cc.pToAngleSelf(cc.pSub(p2, p1))
            local isInRange = self:_inRange()
            -- if im (not attacking, or not walking) and my target is not in range
            if (not self._cooldown or state ~= EnumStateType.WALKING) and not isInRange then
                self:walkMode()
                return
            --if my target is in range, and im not already attacking
            elseif isInRange and state ~= EnumStateType.ATTACKING then
                self:attackMode()
                return
--            else 
--                --Since im attacking, i cant just switch to another mode immediately
--                --print( self._name, "says : what should i do?", self._statetype)
            end
        elseif self._statetype ~= EnumStateType.WALKING and self._goRight == true then
            self:walkMode()
            return
        --i did not find a target, and im not attacking or not already idle
        elseif not self._cooldown or state ~= EnumStateType.IDLE then
            self:idleMode()
            return
        end
    else
        -- logic when im dead 
    end
end

--baseUpdate负责调用AI()函数，执行频率由GlobalVariables.lua中的 _AIFrequency决定。
--英雄通常在1~1.3秒，NPC 3~5 秒，因为英雄的逻辑行为更丰富一些。
--AI计算的频率高可以减少角色傻掉的时间，但是频繁调用又会影响性能，所以要折中考虑。
function Actor:baseUpdate(dt)
    self._myPos = getPosTable(self)
    self._aliveTime = self._aliveTime + dt
    
    if self._AIEnabled then
        self._AITimer = self._AITimer + dt
        if self._AITimer > self._AIFrequency then
            self._AITimer = self._AITimer - self._AIFrequency
            self:AI()
        end
    end
end

function Actor:knockingUpdate(dt)
    --关闭英雄的AI
    if self._racetype == EnumRaceType.HERO then
        return true
    end
    
    if self._aliveTime - self._timeKnocked > self._recoverTime then
        --i have recovered from a knock
        self._timeKnocked = nil
        if self:_inRange() then
            self:attackMode()
        else
            self:walkMode()
        end
    end
end

--
function Actor:attackUpdate(dt)
    --关闭英雄的AI
    --[[if self._racetype == EnumRaceType.HERO then
        return true
    end
     --]]
    
    self._attackTimer = self._attackTimer + dt
    if self._attackTimer > self._attackFrequency then
        
        self._attackTimer = self._attackTimer - self._attackFrequency
        local function playIdle()
            self:setStateType(EnumStateType.IDLE)--打完一下之后，设置成idle状态，免得一直在攻击
            self:playAnimation("idle", true)
            self._cooldown = false
        end
    
        local random_special = math.random() --根据概率，选择是否需要special attack
        --如果是normal attack
        if random_special > self._specialAttackChance then
            local function createCol()
                self:normalAttack()
            end
            --攻击动画播放的快慢，在每个角色自己的lua文件中被初始化
            local attackAction = cc.Sequence:create(self._action.attack1:clone(),cc.CallFunc:create(createCol),self._action.attack2:clone(),cc.CallFunc:create(playIdle))
            
            self._sprite3d:stopAction(self._curAnimation3d)
            self._sprite3d:runAction(attackAction)
            self._curAnimation = attackAction
            self._cooldown = true
            
        else--如果是special attack
            self:setCascadeColorEnabled(false)--special attack does not change color affected by its parent node    
            local function createCol()        
                self:specialAttack()
            end
            
            local messageParam = {speed = 0.2, pos = self._myPos, dur= self._specialSlowTime , target=self}
            --cclog("calf speed:%.2f", messageParam.speed)
            MessageDispatchCenter:dispatchMessage(MessageDispatchCenter.MessageType.SPECIAL_PERSPECTIVE, messageParam)                    	
            
            local attackAction = cc.Sequence:create(self._action.specialattack1:clone(),cc.CallFunc:create(createCol),self._action.specialattack2:clone(),cc.CallFunc:create(playIdle))
            self._sprite3d:stopAction(self._curAnimation3d)
            self._sprite3d:runAction(attackAction)
            self._curAnimation = attackAction
            self._cooldown = true
        end
    end
end

function Actor:walkUpdate(dt)
    --如果是英雄行走，直接根据摇杆的方向控制英雄路线
    if self._racetype == EnumRaceType.HERO then
        --if self:getStateType() == EnumStateType.ATTACKING then
          --  self:attackMode()
        --end
        return true
    end
    
    --如果有目标并且目标是活着的
    if self._target and self._target._isalive then
        local attackDistance = self._attackRange + self._target._radius -1
        local p1 = self._myPos
        local p2 = self._target._myPos
        self._targetFacing = cc.pToAngleSelf(cc.pSub(p2, p1))
        --距离小于攻击距离
        if cc.pGetDistance(p1,p2) < attackDistance then
            self:attackMode()
        end
    else
        --没有目标的话，向右走活着idle
        --self._target = self:_findEnemy(self._raceType)
        local curx,cury = self:getPosition()
        if self._goRight then
            self._targetFacing = 0
        else
            self:idleMode()
        end
    end
end

--该函数在每一帧调用，因为需要频繁调整角色的朝向。
function Actor:movementUpdate(dt)
    --关闭英雄的AI
    if self._racetype == EnumRaceType.HERO then
        return true
    end
    
    --如下这么代码也就是为了判断向左还是向右转：
    if self._curFacing ~= self._targetFacing then --如果还没有转到目标朝向
        local angleDt = self._curFacing - self._targetFacing
--            if angleDt >= math.pi then angleDt = angleDt-2*math.pi
--            elseif angleDt <=-math.pi then angleDt = angleDt+2*math.pi end
        angleDt = angleDt % (math.pi * 2)
        local turnleft = (angleDt - math.pi) < 0  --检测向左转还是向右转
        local turnby = self._turnSpeed * dt
        
        --right
        if turnby > angleDt then
            self._curFacing = self._targetFacing
        elseif turnleft then
            self._curFacing = self._curFacing - turnby
        else
        --left
            self._curFacing = self._curFacing + turnby
        end
        --更新朝向
        self:setRotation(-RADIANS_TO_DEGREES(self._curFacing))
    end
    
    --更新位置，角色属性 _speed 决定最大速度， _acceleration 决定了加速度；
    --滑行距离也可通过公式计算： S = Vt^2  - Vo^2 / 2a，如果想更精确一点避免“撞上”的话，可以略微调整攻击距离
    if self:getStateType() ~= EnumStateType.WALKING then
        --if I am not walking, i need to slow down
        self._curSpeed = cc.clampf(self._curSpeed - self._decceleration * dt, 0, self._speed)
    elseif self._curSpeed < self._speed then
        --I am in walk mode, if i can speed up, then speed up
        self._curSpeed = cc.clampf(self._curSpeed + self._acceleration*dt, 0, self._speed)
    end
    
    if self._curSpeed > 0 then
        local p1 = self._myPos
        local targetPosition = cc.pRotateByAngle(cc.pAdd({x = self._curSpeed * dt,y = 0}, p1), p1, self._curFacing)
        self:setPosition(targetPosition) --更新位置
    end
end

return Actor