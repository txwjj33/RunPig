local scheduler = require("framework.scheduler")
if ANDOIRD then
    local scheduler = require("framework.luaj")
end

local MainScene = class("MainScene", function()
    return display.newScene("MainScene")
end)

COLLISION_TYPE_ROLE_LINE = -1
COLLISION_TYPE_BOTTOM_LINE = 0   --������������ж��������
COLLISION_TYPE_ROLE        = 1
COLLISION_TYPE_ROAD        = 2
COLLISION_TYPE_ROAD_TOP  = 3
COLLISION_TYPE_ROAD_LEFT = 4
COLLISION_TYPE_DIAMOND = 5
COLLISION_TYPE_STUCK1 = 10
COLLISION_TYPE_STUCK2 = 11
COLLISION_TYPE_STUCK3 = 12
COLLISION_TYPE_STUCK4 = 13

ROLE_STATE_ROAD = 1                   --��·��
ROLE_STATE_JUMP = 2                   --����
ROLE_STATE_JUMP_FALL = 3              --��Ծ����ߵ�����
ROLE_STATE_FALL = 4                   --�Զ�����
ROLE_STATE_COLLSION_TOP = 5           --ײ������ĸ���

local roleState = ROLE_STATE_JUMP_FALL

local STRING_MAX_SCORE = "MAX_SCORE"
local STRING_MUSIC = "MUSIC"

MAP_COUNT = 1
local rolePosX = 0
local sYunWidth = 0

local wudi = fasle       --���Զ����µ�ʱ�����޵е�

local roleSize = 0
local isGameOver = false
--local jumping = false

local font = "AGENTORANGE.ttf"

local currentLevel = -1
local score = 0
local diamondScore = 0
local maxScore = 0
local yunCount = 0
local caodiCount = 0
--��ʯshape��
local diamondTable = {}

local roleHeight = 0

local MAP_ITEMS = 
{
     road1 = COLLISION_TYPE_ROAD,
     road2 = COLLISION_TYPE_ROAD_TOP,
     diamond = COLLISION_TYPE_DIAMOND,
     stuck1 = COLLISION_TYPE_STUCK1,
     stuck2 = COLLISION_TYPE_STUCK2,
     stuck3 = COLLISION_TYPE_STUCK3,
     stuck4 = COLLISION_TYPE_STUCK4,
}

function restartGame()
    currentLevel = -1
    score = 0
    yunCount = 0
end

function MainScene:addCollisionToRoleScriptListener(collisionType)
    self:addCollisionScriptListener(COLLISION_TYPE_ROLE, collisionType)
end

function MainScene:addCollisionScriptListener(type1, type2)
    self.world:addCollisionScriptListener(handler(self, self.onCollisionListener), type1, type2)
end

function MainScene:ctor()
    self.collisionRoadCount = 0
    self.shapes = {}

    self.mapBodys = {}

    self.world = CCPhysicsWorld:create(0, GRAVITY)
    self:addChild(self.world)

    self:initUI()
    self:addLabel()

    local startPos = 0
	self.m_pOldMapBody = self:addMapBody(0)
    self.m_pOldDiamonds = {}  --��¼��ʯ��shape����ײʱɾ��
    self.m_pOldRoadPosY = {}  --��¼��·��y���꣬�ض�λ��ɫ
	self.m_pOldMap = self:addNewMap(startPos, self.m_pOldMapBody, self.m_pOldDiamonds, self.m_pOldRoadPosY)

	local oldMapWidth = self.m_pOldMap:getContentSize().width + startPos
	print("width :%f, needTime: %f", oldMapWidth, oldMapWidth / MAP_MOVE_SPEED)
	self.m_pNewMapBody = self:addMapBody(oldMapWidth)
    self.m_pNewDiamonds = {}
    self.m_pNewRoadPosY = {}
	self.m_pNewMap = self:addNewMap(oldMapWidth, self.m_pNewMapBody, self.m_pNewDiamonds, self.m_pNewRoadPosY)

    table.insert(self.mapBodys, 1, self.m_pOldMapBody) 
    table.insert(self.mapBodys, 2, self.m_pNewMapBody) 

	self:createRole(ccp(ROLE_POS_X, ROLE_POS_Y))
	self:addBottomLineShape()
	self:addRoleLineShape()   --��ӽ�ɫ����λ�õ����ߣ����ڼ���������ϰ���

    for k, v in pairs(MAP_ITEMS) do
        self:addCollisionToRoleScriptListener(v)
    end
    self:addCollisionToRoleScriptListener(COLLISION_TYPE_ROAD_LEFT)

    -- add debug node
    if DEBUG_COLLSION then
        self.worldDebug = self.world:createDebugNode()
        self:addChild(self.worldDebug)
    end

    local baseLayer = display.newLayer()
	baseLayer:setTouchEnabled(true)
    self:addChild(baseLayer)
    baseLayer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function()
        if (self.collisionRoadCount > 0) then
            self:roleJump()
        end
    end)
    self.baseLayer = baseLayer

    self:calSpeed()
end

function MainScene:roleJump()
    --jumping = true
    roleState = ROLE_STATE_JUMP

    --ROLE_JUMP_SPEED = 200
    --self.roleBody:setVelocity(ccp(0, ROLE_JUMP_SPEED))
    self.pigAnimation:setAnimation(0, "jump", true)

    local time = (JUMP_GE_ZI_VER * TILE_WIDTH) / ROLE_JUMP_SPEED
    print("time: " .. time)
    print("speed: " .. ROLE_JUMP_SPEED)
    local posY = self.roleBody:getPositionY()
    self.jumpSchedule = scheduler.performWithDelayGlobal(function(dt)
        print("performWithDelayGlobal: " .. time)
        --self.roleBody:setVelocity(ccp(0, -ROLE_JUMP_SPEED))
        roleState = ROLE_STATE_JUMP_FALL
        local posY2 = self.roleBody:getPositionY()
        print("true speed: ", (posY2 - posY) / time)
    end, time)
end

function MainScene:initUI()
    cc.ui.UIImage.new("interface_background.png")
        :align(display.LEFT_BOTTOM)
        :addTo(self)
    self:addYun()
    self:addSun()
    self:addCaodi()
    
    --self:addButtons()
end

function MainScene:addCaodi()
    self.caodiBody = self:addMapBody(0)
    table.insert(self.mapBodys, self.caodiBody) 
    self.caodiNode = display.newNode()
    self:addChild(self.caodiNode)
    self.caodiBody:bind(self.caodiNode)

    self.caodiTable = {}
    --self.caodiBatchNode = CCSpriteBatchNode:create("interface_caodi.png", 50)
    --    :addTo(self.caodiNode)

    local caodi = cc.ui.UIImage.new("interface_caodi.png")
        :align(display.LEFT_BOTTOM, 0, 0)
        :addTo(self.caodiNode)

    table.insert(self.caodiTable, caodi)

    local caodi2 = cc.ui.UIImage.new("interface_caodi.png")
        :align(display.LEFT_BOTTOM, WIN_WIDTH, 0)
        :addTo(self.caodiNode)

    table.insert(self.caodiTable, caodi2)
end

function MainScene:addYun()
    self.yunBody = self:addMapBody(0)
    table.insert(self.mapBodys, self.yunBody) 
    self.yunNode = display.newNode()
    self:addChild(self.yunNode)
    self.yunBody:bind(self.yunNode)

    self.yunsTable = {}
    self.yunBatchNode = CCSpriteBatchNode:create("interface_yun_02.png", 100)
        :addTo(self.yunNode)
    sYunWidth = self.yunBatchNode:getTexture():getContentSize().width - 3
    local yunCount = math.floor(CONFIG_SCREEN_WIDTH / sYunWidth) + 2
    local posX = 0

    for k = 1, yunCount do
        self:addAYun(posX)
        posX = posX + sYunWidth - 3
    end
end

function MainScene:addAYun(posX)
    local yun = cc.ui.UIImage.new(self.yunBatchNode:getTexture())
        :align(display.LEFT_BOTTOM, posX, 39)
        :addTo(self.yunNode)

    local randPosX = math.random(8, sYunWidth - 8)
    local randPosY = math.random(-8, 7)
    cc.ui.UIImage.new("interface_hua.png")
        :align(display.LEFT_BOTTOM, randPosX, randPosY)
        :addTo(yun)

    table.insert(self.yunsTable, yun)
end

function MainScene:addSun()
end

function MainScene:addLabel()
    local height = 685
    local fontSize = 40

    self.scoreLabel = CCLabelTTF:create("0", font, fontSize)
    self.scoreLabel:setColor(ccc3(255,254,219))
    self.scoreLabel:setPosition(CONFIG_SCREEN_WIDTH / 2, height)
    self:addChild(self.scoreLabel)

    maxScore = CCUserDefault:sharedUserDefault():getIntegerForKey(STRING_MAX_SCORE, 0)
    self.maxScoreLabel = CCLabelTTF:create(maxScore, font, fontSize)
    self.maxScoreLabel:setColor(ccc3(255,232,111))
    self.maxScoreLabel:setPosition(1177, height)
    self.maxScoreLabel:setAnchorPoint(ccp(0, 0.5))
    self:addChild(self.maxScoreLabel)

    local bestLabel = CCLabelTTF:create("Best", font, fontSize)
    bestLabel:setColor(ccc3(255,232,111))
    bestLabel:setPosition(1019, height)
    bestLabel:setAnchorPoint(ccp(0, 0.5))
    self:addChild(bestLabel)
end

function MainScene:addButtons()
    cc.ui.UIPushButton.new("button_try-again_02.png")
        :onButtonPressed(function(event)
            event.target:setScale(1.2)
        end)
        :onButtonRelease(function(event)
            event.target:setScale(1.0)
        end)
        :onButtonClicked(function(event)
            if CHEATING_MODE then
                self:fuhuo()
            else
                package.loaded["scenes.MainScene"] = nil
                display.replaceScene(require("scenes.MainScene").new())
            end
        end)
        :align(display.CENTER, WIN_WIDTH / 2, WIN_HEIGHT / 2)
        :addTo(self)
end

function MainScene:fuhuo()
    isGameOver = false
    wudi = true
    self:onEnter()

    self.pigAnimation:setAnimation(0, "run", true)
    self.baseLayer:setTouchEnabled(true)
end

function MainScene:addNewMap(posX, body, diamondTable, roadPosYTable)
    currentLevel = currentLevel + 1
    local levelID = nil
    if currentLevel <= LEVEL_RECYCLE_MIN then
        levelID = currentLevel
    else
        levelID = math.random(LEVEL_RECYCLE_MIN, LEVEL_RECYCLE_MAX)
    end

    local mapID = math.random(1, LEVEL_NUM_CONF[levelID])
    local mapPath = string.format("levels/%d.%d.tmx", levelID, mapID)
	print("create new map: " .. mapPath)

	local map = CCTMXTiledMap:create(mapPath)
	map:setPosition(posX, 0)
    self:addChild(map)

    body:bind(map)

    --���road��Ӧ����״
    --height�߶εĺ��
    local function addRoadShape(collisionType, pos1, pos2, height)
        local height_1 = height or 1
        local shape = body:addSegmentShape(pos1, pos2, height_1)
        shape:setCollisionType(collisionType)
        return shape
    end

	for layerName, v in pairs(MAP_ITEMS) do
		local layer = map:layerNamed(layerName)
        if not layer then
            --do nothing
        else
		    local mapSize = map:getMapSize()
		    for x = 0, mapSize.width - 1 do
			    for y = 0, mapSize.height - 1 do
				    local tile = layer:tileAt(ccp(x, y))
				    if tile then
                        local tileSize = tile:getContentSize()
					    local pos = ccpAdd(ccp(tile:getPosition()), ccp(tileSize.width / 2, tileSize.height / 2))

                        --����ǲ�������ߵ�road
                        local function checkLeftRoad()
                            if (x == 0) or ( not layer:tileAt(ccp(x - 1, y)) ) then
                                addRoadShape(COLLISION_TYPE_ROAD_LEFT,
								    ccp(pos.x - tileSize.width / 2, pos.y - tileSize.height / 2 + 5), 
								    ccp(pos.x - tileSize.width / 2, pos.y + tileSize.height / 2 - 5))
                            end
                        end

                        if v == COLLISION_TYPE_ROAD_TOP then
                            addRoadShape(COLLISION_TYPE_ROAD_TOP,
								        ccp(pos.x - tileSize.width / 2, pos.y - tileSize.height / 2), 
								        ccp(pos.x + tileSize.width / 2, pos.y - tileSize.height / 2))

                            addRoadShape(COLLISION_TYPE_ROAD,
								    ccp(pos.x - tileSize.width / 2, pos.y + tileSize.height / 2), 
								    ccp(pos.x + tileSize.width / 2, pos.y + tileSize.height / 2), 1)

                            checkLeftRoad()
                        elseif v == COLLISION_TYPE_ROAD then
                            local shape = addRoadShape(COLLISION_TYPE_ROAD,
								    ccp(pos.x - tileSize.width / 2, pos.y + tileSize.height / 2), 
								    ccp(pos.x + tileSize.width / 2, pos.y + tileSize.height / 2), 1)

                            checkLeftRoad()
                            roadPosYTable[shape] = pos.y + tileSize.height / 2
                        elseif v == COLLISION_TYPE_STUCK1 then
                            local vertexes = CCPointArray:create(3)
                            vertexes:add(cc.p(pos.x - tileSize.width / 2, pos.y - tileSize.height / 2))
					        vertexes:add(cc.p(pos.x, pos.y + tileSize.height / 2 - STUCK_TOP_JULI))
					        vertexes:add(cc.p(pos.x + tileSize.width / 2, pos.y - tileSize.height / 2))
					        local shape = body:addPolygonShape(vertexes)
                            shape:setCollisionType(v)
                        else
                            local vertexes = CCPointArray:create(4)
					        --vertexes:add(cc.p(pos.x - tileSize.width / 2, pos.y - tileSize.height / 2))
					        --vertexes:add(cc.p(pos.x - tileSize.width / 2, pos.y + tileSize.height / 2)) 
					        --vertexes:add(cc.p(pos.x + tileSize.width / 2, pos.y + tileSize.height / 2))
					        --vertexes:add(cc.p(pos.x + tileSize.width / 2, pos.y - tileSize.height / 2))


                            vertexes:add(cc.p(pos.x, pos.y - tileSize.height / 2))
					        vertexes:add(cc.p(pos.x - tileSize.width / 2, pos.y))
					        vertexes:add(cc.p(pos.x, pos.y + tileSize.height / 2))
					        vertexes:add(cc.p(pos.x + tileSize.width / 2, pos.y))
					        local shape = body:addPolygonShape(vertexes)
                            shape:setCollisionType(v)

                            if v == COLLISION_TYPE_DIAMOND then
                                diamondTable[shape] = tile
                            end
                        end
                    end
                end
            end
        end
    end

	return map
end

function MainScene:update(dt)
	local oldMapWidth = self.m_pOldMap:getContentSize().width
	local oldBodyPos = self.m_pOldMap:getPosition()
	--��ͼ�ѳ��磬ɾ���ɵ�ͼ������µ�ͼ
	if (oldBodyPos <= - oldMapWidth) then
		self:removeOldMapAddNewMap()
    end

    if (self.yunNode:getPositionX() < - sYunWidth * (yunCount + 1)) then
        self:removeOldYun()
    end

    if (self.caodiNode:getPositionX() < - WIN_WIDTH * (caodiCount + 1)) then
        self:removeOldCaodi()
    end
end

function MainScene:removeOldMapAddNewMap()
	print("start remove old")

	--�Ƴ��ɵ�ͼ
	self.m_pOldMap:removeFromParent()
    self.m_pOldMapBody:removeSelf()

	--��֮ǰ���µ�ͼ��ֵ���ɵ�ͼ
	self.m_pOldMap = self.m_pNewMap
	self.m_pOldMapBody = self.m_pNewMapBody
    self.m_pOldDiamonds = self.m_pNewDiamonds
    self.m_pOldRoadPosY = self.m_pNewRoadPosY
    self.mapBodys[1] = self.m_pOldMapBody

	--�����µ�ͼ
    local odMapPosX = self.m_pOldMap:getPosition()
	local newMapPosX = odMapPosX + self.m_pOldMap:getContentSize().width
	self.m_pNewMapBody = self:addMapBody(newMapPosX)
    self.m_pNewDiamonds = {}
    self.m_pNewRoadPosY = {}
	self.m_pNewMap = self:addNewMap(newMapPosX, self.m_pNewMapBody, self.m_pNewDiamonds, self.m_pNewRoadPosY)
    self.mapBodys[2] = self.m_pNewMapBody

	print("end create new map")
end

function MainScene:removeOldCaodi()
    caodiCount = caodiCount + 1

    local caodi = self.caodiTable[1]
    caodi:removeFromParentAndCleanup(true)
    table.remove(self.caodiTable, 1)

    local lastCaodi = self.caodiTable[#self.caodiTable]
    local pos = lastCaodi:getPositionX() + WIN_WIDTH - 3

    local caodi2 = cc.ui.UIImage.new("interface_caodi.png")
        :align(display.LEFT_BOTTOM, pos, 0)
        :addTo(self.caodiNode)

    table.insert(self.caodiTable, caodi2)
end

function MainScene:removeOldYun()
    yunCount = yunCount + 1

    local yun = self.yunsTable[1]
    yun:removeFromParentAndCleanup(true)
    table.remove(self.yunsTable, 1)

    local lastYun = self.yunsTable[#self.yunsTable]
    local pos = lastYun:getPositionX() + sYunWidth - 3
    self:addAYun(pos)
end

function MainScene:addMapBody(posX)
	local body = CCPhysicsBody:create(self.world, 1, 1)
    self.world:addBody(body)
	body:setPosition(ccp(posX, 0))
	--body:setVelocity(-MAP_MOVE_SPEED, 0)
	--body:setForce(0, -GRAVITY)

    body:setBodyPostionHandle(handler(self, self.onBodyPostionListener))

	return body
end

function MainScene:onBodyPostionListener(body, dt)
    body:setPosition(ccp(body:getPositionX() - dt * MAP_MOVE_SPEED, 0))
end

function MainScene:createRole(pos)
	local layer = self.m_pOldMap:layerNamed("road1")
	local tilePos = layer:positionAt(pos)
    rolePosX = tilePos.x

	local role = display.newSprite("zhuti_zhu.png")
    self:addChild(role)
    
    self.pigAnimation = SkeletonAnimation:createWithFile("pig/skeleton.json", "pig/skeleton.atlas", 1)
    self.pigAnimation:setAnimation(0, "run", true)
    self:addChild(self.pigAnimation)

	--roleSize = role:getContentSize()
	roleSize = self.m_pOldMap:getTileSize()
    roleHeight = roleSize.height
	local rolePos = ccpAdd(tilePos, ccp(roleSize.width / 2, roleSize.height / 2))

    self.pigAnimation:setAnchorPoint(ccp(0, 0.5))
    self.pigAnimation:setContentSize(roleSize)

	local vexArray = CCPointArray:create(4)
	vexArray:add(ccp(- roleSize.width / 2, - roleSize.height / 2))
	vexArray:add(ccp(- roleSize.width / 2,   roleSize.height / 2))
	vexArray:add(ccp(  roleSize.width / 2,   roleSize.height / 2))
	vexArray:add(ccp(  roleSize.width / 2, - roleSize.height / 2))

 --   local vexArray = CCPointArray:create(8)
 --   vexArray:add(ccp(- roleSize.width / 2, - roleSize.height / 4))
	--vexArray:add(ccp(- roleSize.width / 2,   roleSize.height / 4))
	--vexArray:add(ccp(- roleSize.width / 4,   roleSize.height / 2))
	--vexArray:add(ccp(  roleSize.width / 4,   roleSize.height / 2))
 --   vexArray:add(ccp(  roleSize.width / 2,   roleSize.height / 4))
	--vexArray:add(ccp(  roleSize.width / 2, - roleSize.height / 4))
	--vexArray:add(ccp(  roleSize.width / 4, - roleSize.height / 2))
	--vexArray:add(ccp( -roleSize.width / 4, - roleSize.height / 2))

	local roleBody = self.world:createPolygonBody(1, vexArray)
    roleBody:setCollisionType(COLLISION_TYPE_ROLE)
    roleBody:setPosition(rolePos)
    --roleBody:setVelocity(0, -MAP_MOVE_SPEED)
    --roleBody:setVelocity(0, -200)
    roleBody:bind(self.pigAnimation)

    roleBody:setBodyPostionHandle(handler(self, self.onRolePostionListener))

    self.roleBody = roleBody
end

function MainScene:onRolePostionListener(body, dt)
    if roleState == ROLE_STATE_ROAD then
        --nothing to do
    elseif roleState == ROLE_STATE_JUMP then
        local x, y = body:getPosition()
        --print("y, dt," .. y .. "  " .. dt)
        --print("speed," .. ROLE_JUMP_SPEED)
        body:setPosition(ccp(x, y + dt * ROLE_JUMP_SPEED))
    elseif roleState == ROLE_STATE_JUMP_FALL or roleState == ROLE_STATE_COLLSION_TOP then
        local x, y = body:getPosition()
        body:setPosition(ccp(x, y - dt * ROLE_JUMP_SPEED))
    elseif roleState == ROLE_STATE_FALL then
        local x, y = body:getPosition()
        body:setPosition(ccp(x, y - dt * ROLE_FALL_SPEED))
    end
end

function MainScene:addBottomLineShape()
    local bottomWallBody = self.world:createBoxBody(0, WIN_WIDTH, 1)
    bottomWallBody:setPosition(0, 0)
    bottomWallBody:setCollisionType(COLLISION_TYPE_BOTTOM_LINE)
    self:addCollisionToRoleScriptListener(COLLISION_TYPE_BOTTOM_LINE)
end

function MainScene:addRoleLineShape()
    local roleWallBody = self.world:createBoxBody(0, 1, WIN_HEIGHT)
    roleWallBody:setPosition(rolePosX - 2, WIN_HEIGHT / 2)
    roleWallBody:setCollisionType(COLLISION_TYPE_ROLE_LINE)

    for k, v in pairs(MAP_ITEMS) do
        self:addCollisionScriptListener(COLLISION_TYPE_ROLE_LINE, v)
    end
    self:addCollisionScriptListener(COLLISION_TYPE_ROLE_LINE, COLLISION_TYPE_ROAD_LEFT)
end

function MainScene:onCollisionListener(phase, event)
    if phase == "begin" then
        return self:onCollisionBegin(event)
    elseif phase == "preSolve" then
        return false
    elseif phase == "postSolve" then
        return false
    elseif phase == "separate" then
        return self:onSeparate(event)
    end
end

function MainScene:onCollisionBegin(event)
    if isGameOver then return false end

    local body1 = event:getBody1()   --��ɫbody
    local body2 = event:getBody2()   --��ͼbody

    local shape1 = event:getShape1()   --��ɫshape
    local shape2 = event:getShape2()   --��ͼshape
    if shape1:getCollisionType() == COLLISION_TYPE_ROLE_LINE then
        local collisionType = shape2:getCollisionType()
        if collisionType == COLLISION_TYPE_STUCK1 
            or collisionType == COLLISION_TYPE_STUCK2
            or collisionType == COLLISION_TYPE_STUCK3
            or collisionType == COLLISION_TYPE_STUCK4
            then
            score  = score + 1
            self.scoreLabel:setString(score)
        end

        return false
    end

    local collisionType = shape2:getCollisionType()
	--print("begin collision collision_type: " .. collisionType)
	if (collisionType == COLLISION_TYPE_ROAD) then
        --jumping = false
        wudi = false
		self.collisionRoadCount = self.collisionRoadCount + 1
		--��roleһ������������
        --body1:setForce(ccp(0, -GRAVITY))
        --body1:setVelocity(ccp(0, 0))

        local roadPosY = 0
        if self.m_pOldRoadPosY[shape2] then
            roadPosY = self.m_pOldRoadPosY[shape2]
        else
            roadPosY = self.m_pNewRoadPosY[shape2]
        end
        local x, y = body1:getPosition()
        body1:setPosition(ccp(x, roadPosY + roleHeight / 2))


        if roleState == ROLE_STATE_JUMP_FALL then
            self.pigAnimation:setAnimation(0, "run", true)
        end
        roleState = ROLE_STATE_ROAD
    elseif collisionType == COLLISION_TYPE_ROAD_TOP then
        --local vx, vy = body1:getVelocity()
        --print(vx .. vy)
        --if vy > 0 then
        --    body1:setVelocity(vx, -vy)
        --end
        roleState = ROLE_STATE_COLLSION_TOP
    elseif collisionType == COLLISION_TYPE_DIAMOND then
        diamondScore = diamondScore + DIAMOND_SCORE
        if self.m_pOldDiamonds[shape2] then
            self.m_pOldDiamonds[shape2]:removeFromParent()
            body2:removeShape(shape2)
            print("remove diamond")
        elseif self.m_pNewDiamonds[shape2] then
            self.m_pNewDiamonds[shape2]:removeFromParent()
            body2:removeShape(shape2)
            print("remove diamond")
        end
    elseif collisionType == COLLISION_TYPE_BOTTOM_LINE 
        or collisionType == COLLISION_TYPE_ROAD_LEFT then
        self:gameOver()
    else
        if not wudi then
            self:gameOver()
        end
    end

    return false
end

function MainScene:onSeparate(event)
    if isGameOver then return false end

    local body1 = event:getBody1()   --��ɫbody
    local body2 = event:getBody2()   --��ͼbody

    local shape1 = event:getShape1()   --��ɫshape
    local shape2 = event:getShape2()   --��ͼshape

    if shape1:getCollisionType() == COLLISION_TYPE_ROLE_LINE then
        return false
    end

    --local collisionType = event:getShape2():getCollisionType()
	--print("onSeparate collision_type: " .. collisionType)
	if shape2 and (event:getShape2():getCollisionType() == COLLISION_TYPE_ROAD) then
		self.collisionRoadCount = self.collisionRoadCount - 1
		
		--�뿪���еĵ�·���ָ�����Ч��
		if (self.collisionRoadCount == 0) then
			--body1:setForce(ccp(0, 0))
   --         if not jumping then
   --             body1:setVelocity(0, -ROLE_FALL_SPEED)
   --         end
            if roleState ~= ROLE_STATE_JUMP then
                roleState = ROLE_STATE_FALL
                wudi = true
            end
        end
    end

    return false
end

function MainScene:gameOver()
    isGameOver = true

    scheduler.unscheduleGlobal(self.updateSchedule)
    scheduler.unscheduleGlobal(self.updateSpeedSchedule)
    if self.jumpSchedule then
        scheduler.unscheduleGlobal(self.jumpSchedule)
        self.jumpSchedule = true
    end

    self.pigAnimation:setAnimation(0, "dead", true)
    self.world:stop()
    self.baseLayer:setTouchEnabled(false)

    if score > maxScore then
        maxScore = score
        self.maxScoreLabel:setString(maxScore)
        CCUserDefault:sharedUserDefault():setIntegerForKey(STRING_MAX_SCORE, maxScore)
    end

    self:addButtons()
    if ANDOIRD then
        luaj.callStaticMethod("com/xwtan/run/Run", "showSpotAd")
        luaj.callStaticMethod("com/xwtan/run/Run", "vibrate")
    end
end

function MainScene:onEnter()
    self.world:start()
    
    self.updateSchedule = scheduler.scheduleUpdateGlobal(function(dt)
        self:update(dt)
    end)

    self.updateSpeedSchedule = scheduler.scheduleGlobal(function(dt)
        MAP_MOVE_SPEED = MAP_MOVE_SPEED + SPEED_CHANGE_NUM
        self:calSpeed()
        --for _, body in ipairs(self.mapBodys) do 
        --    body:setVelocity(-MAP_MOVE_SPEED, 0)
        --end
    end, SPEED_CHANGE_TIME)
end

function MainScene:onExit()
    self.world:removeAllCollisionListeners()
end

function MainScene:calSpeed()
    local time = (JUMP_GE_ZI_HOR * TILE_WIDTH) / MAP_MOVE_SPEED
    ROLE_JUMP_SPEED = (2 * JUMP_GE_ZI_VER * TILE_WIDTH) / time

    ROLE_FALL_SPEED = MAP_MOVE_SPEED
end

return MainScene
