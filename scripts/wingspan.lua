--[[
Completed
    Expansion setup buttons
    Setup button
    Reset birdfeeder button
    Refill river button
    Food gain/pay buttons
    Food counter mat
    Gather-O-Mat
    Round end button
    Scoring
    Camera shortcuts
    Player mat spend nectar buttons
Tasks
    Cache buttons
]]

-- import files
require("scripts/guids")
require("scripts/constants")
require("../utils")
require("scripts/eventHandlers")
require("scripts/scorePad")
require("scripts/cameras")

-- global vars
isEuropeAdded = false
isOceaniaAdded = false
hasRiverWaited = {["b3e430"]=true,["89b212"]=true,["4c4ee4"]=true}
hasRoundWaited = true
scores = {{0,0,0,0,0},{0,0,0,0,0},{0,0,0,0,0},{0,0,0,0,0},{0,0,0,0,0}}             

function onLoad()
    -- create setup and expansion buttons
    local tray = getObjectFromGUID(TRAY_GUID)
    local click_functions = {"setup","europeEnable",'oceaniaEnable'}
    local labels = {"Setup",
        "Enable\nEuropean\nExpansion",
        "Enable\nOceania\nExpansion"}
    local scales = {0.3,0.3,0.3}
    local widths = {3000,2000,2000}
    local heights = {1000,1500,1500}
    local positions = {{0,0.15,3},
        {-1,0.15,2},
        { 1,0.15,2}}
    local rotations = {0,0,0}
    local font_sizes = {1000,300,300}
    local font_styles = {""}
    for i = 1,3 do
        local buttonTable = {}
        buttonTable.click_function = click_functions[i]
        buttonTable.label          = labels[i]
        buttonTable.scale          = {scales[i],scales[i],scales[i]}
        buttonTable.width          = widths[i]
        buttonTable.height         = heights[i]
        buttonTable.position       = positions[i]
        buttonTable.font_size      = font_sizes[i]
        tray.createButton(buttonTable)
    end
    -- create reset birdfeeder button
    local birdfeeder=getObjectFromGUID(BIRDFEEDER_GUID)
    birdfeeder.createButton({
        click_function = "resetBirdfeeder",
        label          = "Reset\nBirdfeeder",
        position       = {0,-10,-15},
        rotation       = {0,180,0},
        scale          = {0.4,0.4,0.4},
        width          = 3600,
        height         = 2000,
        font_size      = 800,
        color          = "Brown",
        font_color     = "White"
    })
    -- create resource mat buttons
    for i,matGUID in ipairs(RESOURCEMATS_GUID) do
        local mat = getObjectFromGUID(matGUID)
        for j,_ in ipairs(RESOURCEBAGS_GUID) do
            local buttonTable = {}
            buttonTable.label          = "+/-\n"..RESOURCES[j]
            buttonTable.position       = {0.52,0.15,-1.13+(0.32*j)}
            buttonTable.rotation       = {0,0,0}
            buttonTable.scale          = {0.1,0.1,0.1}
            buttonTable.width          = 2200
            buttonTable.height         = 1200
            buttonTable.font_size      = 600
            buttonTable.color          = Color.fromString(COLORS[i])
            buttonTable.font_color     = Color.fromString(COLORS_BUTTONFONT[i])
            buttonTable.click_function = "click_function"..tostring(i)..tostring(j)
            self.setVar(
                buttonTable.click_function,
                function(o,c,a) resourceChange(o,c,a,i,j) end
            )
            mat.createButton(buttonTable)        
        end
    end
    -- create resource mat counters
    for i,matGUID in ipairs(RESOURCEMATS_GUID) do
        local mat = getObjectFromGUID(matGUID)
        mat.UI.setXmlTable({{
            tag="VerticalLayout",
            attributes={
                height=196,
                width=190,
                position="30 0 -11",
                rotation="0 0 180",
                scale="1 1 1"
            },
            children={
                {
                    tag="Text",
                    attributes={
                        text="0",
                        id="1"
                    },
                },
                {
                    tag="Text",
                    attributes={
                        text="0",
                        id="2"
                    },
                },
                {
                    tag="Text",
                    attributes={
                        text="0",
                        id="3"
                    },
                },
                {
                    tag="Text",
                    attributes={
                        text="0",
                        id="4"
                    },
                },
                {
                    tag="Text",
                    attributes={
                        text="0",
                        id="5"
                    },
                },
                {
                    tag="Text",
                    attributes={
                        text="0",
                        id="6"
                    },
                },
            }
        }})
        Wait.condition(
            function()
                for j=1,6 do
                    mat.UI.setAttribute(tostring(j),"color",COLORS_HEX[j])
                    mat.UI.setAttribute(tostring(j),"fontSize","17")
                    mat.UI.setAttribute(tostring(j),"fontStyle","Bold")
                end
            end,
            function()
                return not mat.UI.loading
            end
        )
    end
    -- activate UI elements
    gatherOmatOn()
    scorePadOff()
end

function gatherOmatOff()
    Global.UI.setAttribute("gatherOmat","active",false)
    Global.UI.setAttribute("minigatherOmat","active",true)
    Global.UI.setAttribute("scorePadMini","offsetXY","-160 0")
end

function gatherOmatOn()
    Global.UI.setAttribute("gatherOmat","active",true)
    Global.UI.setAttribute("minigatherOmat","active",false)
    Global.UI.setAttribute("scorePadMini","offsetXY","-200 0")
end

function scorePadOff()
    Global.UI.setAttribute("scorePad","active",false)
    Global.UI.setAttribute("scorePadMini","active",true)
end

function scorePadOn()
    score()
    Global.UI.setAttribute("scorePad","active",true)
    Global.UI.setAttribute("scorePadMini","active",false)
end

function gatherOmatClick(player, value, id)
    local color = player.color
    local i = find(color,COLORS)
    local matObj = getObjectFromGUID(RESOURCEMATS_GUID[i])
    local j = find(Global.UI.getAttribute(id,"item"),RESOURCES)
    local altClick=nil
    if value=="-1" then altClick=false
    elseif value=="-2" then altClick=true
    else altClick=nil end
    resourceChange(matObj,color,altClick,i,j)
end

function resourceChange(matObj,color,altClick,i,j)
    if(color~=COLORS[i]) then
        log(color.." modified "..COLORS[i].."'s resources")
        broadcastToColor("Caution: you're modifying another player's resources",color)
    end
    if altClick then -- subtract
        local zone = getObjectFromGUID(RESOURCEZONES_GUID[i])
        for _,obj in ipairs(zone.getObjects()) do
            if isin(RESOURCES[j],obj.getTags()) then
                local trash = getObjectFromGUID(TRASH_GUID[i])
                local setPos = trash.getPosition()
                if obj.getData().Number==nil then
                    obj.setPositionSmooth({setPos.x,5,setPos.z},false,true)
                else
                    obj.takeObject({
                        position = {setPos.x,5,setPos.z},
                        smooth   = true
                    })
                end
                return
            end
        end
        log("Not enough "..RESOURCES[j].." for "..color.." to subtract 1")
        broadcastToColor("Not enough "..RESOURCES[j].." to subtract 1",color)
    else -- add
        local bag = getObjectFromGUID(RESOURCEBAGS_GUID[j])
        local matPos = matObj.getPosition()
        local matRot = matObj.getRotation()
        local takeTab = {}
        takeTab.rotation = matRot
        takeTab.smooth = true
        local tol = 1
        if matRot.y<0+tol or matRot.y>360-tol then
            takeTab.position = {matPos.x-0.2,3,matPos.z-3.14+(0.9*j)}
        elseif matRot.y>90-tol and matRot.y<90+tol then
            takeTab.position = {matPos.x-3.14+(0.9*j),3,matPos.z+0.3}
        elseif matRot.y>180-tol and matRot.y<180+tol then
            takeTab.position = {matPos.x+0.2,3,matPos.z+3.14+(-0.9*j)}
        else
            takeTab.position = {matPos.x+3.14-(0.9*j),3,matPos.z-0.3}
        end
        bag.takeObject(takeTab)
    end
end

function setup()
    log("Setup button clicked")
    -- remove setup buttons
    local tray = getObjectFromGUID(TRAY_GUID)
    local indices = {}
    for i=1,#tray.getButtons() do
        indices[i]=tray.getButtons()[i].index
    end
    for _,i in ipairs(reverse(indices)) do
        tray.removeButton(i)
    end
    -- shuffle and deal decks
    local birdDeck = getObjectFromGUID(BIRDDECK_GUID)
    local bonusDeck = getObjectFromGUID(BONUSDECK_GUID)
    birdDeck.shuffle()
    bonusDeck.shuffle()
    birdDeck.deal(5)
    bonusDeck.deal(2)
    log("Bird and bonus cards dealt")
    -- select round objectives
    local roundGoals = getObjectFromGUID(ROUNDGOALS_GUID)
    roundGoals.shuffle()
    for i=1,4 do
        roundGoals.takeObject({
            position = ROUNDGOALS_LOC[i],
            rotation = ROUNDGOALS_ROT,
            smooth   = true,
            flip     = math.random(0,1)==1
        })
    end
    log("Round goals selected")
    -- create fill river and round end buttons
    tray.createButton({
        click_function = "roundEnd",
        label          = "Round End",
        position       = {1.9,0.15,1.5},
        rotation       = {0,0,0},
        scale          = {0.2,0.2,0.2},
        width          = 4000,
        height         = 1000,
        font_size      = 1000
    })
    tray.createButton({
        click_function = "refillRiver",
        label          = "Refill",
        position       = {-1.9,0.15,1.5},
        rotation       = {0,0,0},
        scale          = {0.2,0.2,0.2},
        width          = 3000,
        height         = 1000,
        font_size      = 1000
    })
    refillRiver()
    -- reset birdfeeder
    resetBirdfeeder()
    -- select first player 
    local players = Player.getPlayers()
    local firstPlayer = players[math.random(#players)]
    local firstPlayeri = find(firstPlayer.color,COLORS)
    broadcastToAll(
        firstPlayer.steam_name.." selected as first player",
        Color.fromString(COLORS[firstPlayeri])
    )
    local token = getObjectFromGUID(FIRSTPLAYER_GUID)
    token.setPositionSmooth(FIRSTPLAYER_LOC[firstPlayeri])
    token.setRotationSmooth(FIRSTPLAYER_ROT[firstPlayeri])
    -- give nectar token to each player
    if isOceaniaAdded then
        for _,player in ipairs(players) do
            local playeri = find(player.color,COLORS)
            local resourceMat = getObjectFromGUID(RESOURCEMATS_GUID[playeri])
            resourceChange(resourceMat,player.color,false,playeri,6)
        end
    end
    -- setup player-based UI elements
    for _,player in ipairs(players) do
        Global.UI.setAttribute("Name"..player.color,"text",player.steam_name)
    end  
    -- end
    log("Setup complete")
end

function europeEnable()
    log("Enable European Expansion button clicked")
    -- remove button
    local tray = getObjectFromGUID(TRAY_GUID)
    tray.removeButton(1)
    log("Expansion button removed")
    -- add bird deck, bonus deck, and round end tokens
    local bag = getObjectFromGUID(EUROPEANBAG_GUID)
    local baseGUIDs = {BIRDDECK_GUID,BONUSDECK_GUID,ROUNDGOALS_GUID}
    local addGUIDs = {BIRDDECK_EUROPE_GUID,BONUSDECK_EUROPE_GUID,ROUNDGOALS_EUROPE_GUID}
    local add
    local baseCounts = {}
    for i,baseGUID in ipairs(baseGUIDs) do
        local baseObj = getObjectFromGUID(baseGUID)
        local basePos = baseObj.getPosition()
        local baseData = baseObj.getData()
        baseCounts[i] = #baseData["DeckIDs"]
        bag.takeObject({
            position = Vector(basePos.x,5,basePos.z),
            rotation = Vector(0,180,180),
            smooth   = true,
            guid     = addGUIDs[i]
        })
    end
    log("Bird deck, bonus deck, and round end tokens added")
    -- shuffle decks
    Wait.condition(
        function() -- execute
            for _,baseGUID in ipairs(baseGUIDs) do
                local baseObj = getObjectFromGUID(baseGUID)
                baseObj.shuffle()
            end
        end,
        function() -- condition
            local conditions = {false,false,false}
            for i,baseGUID in ipairs(baseGUIDs) do
                local baseObj = getObjectFromGUID(baseGUID)
                local baseData = baseObj.getData()
                if #baseData["DeckIDs"]>baseCounts[i] then conditions[i]=true end
            end
            return conditions[1] and conditions[2] and conditions[3]
        end
    )
    -- change global definition
    isEuropeAdded = true
    log("European expansion setup complete")
end

function oceaniaEnable()
    log("Enable Oceania Expansion button clicked")
    -- remove button
    local tray = getObjectFromGUID(TRAY_GUID)
    if isEuropeAdded then tray.removeButton(1)
    else tray.removeButton(2) end
    -- add bird deck, bonus deck, and round end tokens
    local bag = getObjectFromGUID(OCEANIANBAG_GUID)
    local baseGUIDs = {BIRDDECK_GUID,BONUSDECK_GUID,ROUNDGOALS_GUID}
    local addGUIDs = {BIRDDECK_OCEANIA_GUID,BONUSDECK_OCEANIA_GUID,ROUNDGOALS_OCEANIA_GUID}
    local add
    local baseCounts = {}
    for i,baseGUID in ipairs(baseGUIDs) do
        local baseObj = getObjectFromGUID(baseGUID)
        local basePos = baseObj.getPosition()
        local baseData = baseObj.getData()
        baseCounts[i] = #baseData["DeckIDs"]
        bag.takeObject({
            position = Vector(basePos.x,5,basePos.z),
            rotation = Vector(0,180,180),
            smooth   = true,
            guid     = addGUIDs[i]
        })
    end
    -- shuffle decks
    Wait.condition(
        function() -- execute
            for _,baseGUID in ipairs(baseGUIDs) do
                local baseObj = getObjectFromGUID(baseGUID)
                baseObj.shuffle()
            end
        end,
        function() -- condition
            local conditions = {false,false,false}
            for i,baseGUID in ipairs(baseGUIDs) do
                local baseObj = getObjectFromGUID(baseGUID)
                local baseData = baseObj.getData()
                if #baseData["DeckIDs"]>baseCounts[i] then conditions[i]=true end
            end
            return conditions[1] and conditions[2] and conditions[3]
        end
    )
    -- replace dice
    for i,dieGUID in ipairs(DICE_GUID) do
        local die = getObjectFromGUID(dieGUID)
        local setPos = getObjectFromGUID(INSTRUCTIONSBAG_GUID).getPosition()
        die.setPositionSmooth({setPos.x,2+i,setPos.z},false,true)
        bag.takeObject({
            position = DICE_LOC[i],
            smooth = true,
            guid = DICE_OCEANIA_GUID[i]
        })
    end
    DICE_GUID = DICE_OCEANIA_GUID
    -- flip player mats
    for i,matGUID in ipairs(PLAYERMATS_GUID) do
        local mat = getObjectFromGUID(matGUID)
        mat.setLock(false)
        mat.flip()
    end
    Wait.condition(
        function()
            for i,matGUID in ipairs(PLAYERMATS_GUID) do
                local mat = getObjectFromGUID(matGUID)
                mat.setLock(true) 
                for j=1,3 do
                    local buttonTable = {}
                    buttonTable.label          = "Spend\nNectar"
                    buttonTable.position       = {1.365,-0.01,-1.19+(0.63*j)}
                    buttonTable.rotation       = {0,0,180}
                    buttonTable.scale          = {0.1,0.1,0.1}
                    buttonTable.width          = 700
                    buttonTable.height         = 500
                    buttonTable.font_size      = 200
                    buttonTable.color          = RESOURCE_COLORS[6]
                    buttonTable.font_color     = "White"
                    buttonTable.click_function = "cf_spendNectar"..tostring(i)..tostring(j)
                    self.setVar(
                        buttonTable.click_function,
                        function(o,c,a) spendNectar(o,c,a,i,j) end
                    )
                    mat.createButton(buttonTable)
                end
            end
        end,
        function()
            local allResting = {}
            for i,matGUID in ipairs(PLAYERMATS_GUID) do
                local mat = getObjectFromGUID(matGUID)
                allResting[i] = mat.resting and mat.getPosition().y<1.1
            end
            return all(allResting)
        end
    )
    -- update score pad UI
    Global.UI.setAttribute("Oceania","active",true)
    Global.UI.setAttribute("Nectar","active",true)
    -- change global definition
    isOceaniaAdded = true
    log("Oceania expansion setup complete")
end

function spendNectar(obj,color,altClick,i,j)
    if(color~=COLORS[i]) then
        log(color.." spent "..COLORS[i].."'s nectar")
        broadcastToColor("Caution: you're spending another player's nectar",color)
    end
    if altClick then -- remove 1
    else -- add 1
        -- local bag = getObjectFromGUID(RESOURCEBAGS_GUID[6])
        -- bag.takeObject({position=NECTAR_LOC[i][j],smooth=true})
        -- resourceChange(getObjectFromGUID(RESOURCEMATS_GUID[i]),color,true,i,6)
        local zone = getObjectFromGUID(RESOURCEZONES_GUID[i])
        for _,obj in ipairs(zone.getObjects()) do
            if isin("Nectar",obj.getTags()) then
                local setPos = {NECTAR_LOC[i][j][1],2,NECTAR_LOC[i][j][3]}
                if obj.getData().Number==nil then
                    obj.setPositionSmooth(setPos,false,true)
                    return
                else
                    obj.takeObject({position=setPos,smooth=true})
                    return
                end
            end
        end
        broadcastToColor("Not enough nectar to spend 1",color)
    end
end

function resetBirdfeeder()
    for i,dieGUID in ipairs(DICE_GUID) do
        local die = getObjectFromGUID(dieGUID)
        die.setPositionSmooth(DICE_LOC[i],false,true)
    end
    Wait.condition(
        function()
            for _,dieGUID in ipairs(DICE_GUID) do
                local die = getObjectFromGUID(dieGUID)
                die.shuffle()
            end
            Wait.condition(
                function()
                    for i,dieGUID in ipairs(DICE_GUID) do
                        local die = getObjectFromGUID(dieGUID)
                        local rotVal = die.getRotationValue()
                        die.setPositionSmooth(DICE_LOC[i],false,true)
                        die.setRotationSmooth(DICE_ROT[rotVal],false,true)
                    end
                    log("Birdfeeder reset complete")
                end,
                function()
                    local isResting = {}
                    for i,dieGUID in ipairs(DICE_GUID) do
                        local die = getObjectFromGUID(dieGUID)
                        isResting[i] = die.resting
                    end
                    return all(isResting)
                end
            )
        end,
        function()
            local isResting = {}
            local isInPos = {}
            for i,dieGUID in ipairs(DICE_GUID) do
                local die = getObjectFromGUID(dieGUID)
                isResting[i] = die.resting
                local pos = die.getPosition()
                local condX = math.abs(pos.x-DICE_LOC[i][1])<.1
                local condZ = math.abs(pos.z-DICE_LOC[i][3])<.1
                isInPos[i] = condX and condZ
            end
            return all(isResting) and all(isInPos)
        end
    )
end

function refillRiver()
    for _,zoneGUID in ipairs(RIVERZONES_GUID) do
        local zone = getObjectFromGUID(zoneGUID)
        if #zone.getObjects()==0 and hasRiverWaited[zoneGUID] then
            local birdDeck = getObjectFromGUID(BIRDDECK_GUID)
            birdDeck.takeObject({
                position = zone.getPosition(),
                smooth   = true,
                flip     = true,
            })
            hasRiverWaited[zoneGUID] = false
            Wait.time(function() hasRiverWaited[zoneGUID]=true end,1)
        end
    end
    log("River refilled")
end

function roundEnd()
    if hasRoundWaited then
        hasRoundWaited = false
        log("Round ending")
        broadcastToAll("Round ending")
        Wait.time(function() hasRoundWaited=true end,2)
        -- reset river
        for _,zoneGUID in ipairs(RIVERZONES_GUID) do
            local zone = getObjectFromGUID(zoneGUID)
            for _,obj in ipairs(zone.getObjects()) do
                obj.setPositionSmooth({BIRDDISCARD_LOC[1],4,BIRDDISCARD_LOC[3]},false,true)
            end
        end
        Wait.condition(
            function()
                refillRiver()
            end,
            function()
                local isEmpty = {false,false,false}
                for i,zoneGUID in ipairs(RIVERZONES_GUID) do
                    local zone = getObjectFromGUID(zoneGUID)
                    if #zone.getObjects()==0 then isEmpty[i] = true end
                end    
                return all(isEmpty)
            end
        )
        -- rotate first player
        local players = Player.getPlayers()
        local playersi = {}
        local p_i = 1
        for _,player in ipairs(players) do
            playersi[p_i] = find(player.color,COLORS)
            p_i = p_i + 1
        end
        playersi = table.sort(playersi)
        for i,loc in ipairs(FIRSTPLAYER_LOC) do
            local obj = findObjAt(loc)
            if obj~=nil then
                local j = find(i,playersi)
                if j==#playersi then j=playersi[1]
                else j = playersi[j+1] end
                obj.setPositionSmooth(FIRSTPLAYER_LOC[j],false,true)
                obj.setRotationSmooth(FIRSTPLAYER_ROT[j],false,true)
                break
            end
        end
        -- discard nectar
        for i,zoneGUID in ipairs(RESOURCEZONES_GUID) do
            local zone = getObjectFromGUID(zoneGUID)
            for _,obj in ipairs(zone.getObjects()) do
                if isin("Nectar",obj.getTags()) then
                    log(obj.getData())
                    local trash = getObjectFromGUID(TRASH_GUID[i])
                    local setPos = trash.getPosition()
                    obj.setPositionSmooth({setPos.x,4,setPos.z},false,true)
                end
            end
        end
        -- recover counters
        for i,row in ipairs(COUNTERS_GUID) do
            for j,guid in ipairs(row) do
                local counter = getObjectFromGUID(guid)
                if counter.getZones()[1]~=nil then
                    local condR = isin(counter.getZones()[1].getGUID(),PLAYERMATZONES_GUID)
                    local condL = isin(counter.getZones()[1].getGUID(),PLAYERMATLEFTZONES_GUID)
                    if condR or condL then
                        local setPos = COUNTERS_LOC[i][j]
                        counter.setPositionSmooth({setPos[1],2,setPos[3]},false,true)
                        counter.setRotationSmooth({0,0,0},false,true)
                    end
                end
            end
        end
    end
end
