function score()
    scores = {{0,0,0,0,0},{0,0,0,0,0},{0,0,0,0,0},{0,0,0,0,0},{0,0,0,0,0}}             
    -- face-up bird cards, tucked bird cards, eggs, and cached food
    for i,zoneGUID in ipairs(PLAYERMATZONES_GUID) do
        local zone = getObjectFromGUID(zoneGUID)
        for _,obj in ipairs(zone.getObjects()) do
            local data = obj.getData()
            -- point value of played bird cards
            local isFaceUp = data.Transform["rotZ"]<90 or data.Transform["rotZ"]>270
            if data.Name=="Card" and isFaceUp then
                scores[i][1] = scores[i][1] + tonumber(data.Description)
            end
            -- tucked bird cards
            if data.ContainedObjects == nil then
                if data.Name=="Card" and not isFaceUp then
                    scores[i][4] = scores[i][4] + 1
                end
            else
                for _,oData in ipairs(data.ContainedObjects) do
                    if oData.Name=="Card" and not isFaceUp then
                        scores[i][4] = scores[i][4] + 1
                    end
                end
            end
            -- cached food and eggs
            if data.Tags ~= nil then
                if data.Number == nil then
                    scores[i][4] = scores[i][4] + 1
                else
                    scores[i][4] = scores[i][4] + data.Number
                end
            end
        end
    end
    -- points for end of round goals
    for r,row in ipairs(GOALZONES_GUID) do
        for c,zoneGUID in ipairs(row) do
            -- find which colors are in the zone
            local zone = getObjectFromGUID(zoneGUID)
            local isColoriInZone = {0,0,0,0,0}
            for _,obj in ipairs(zone.getObjects()) do
                for i,countersColor in ipairs(COUNTERS_GUID) do
                    if isin(obj.getGUID(),countersColor) then
                        isColoriInZone[i] = 1
                    end
                end
            end
            -- split points and round up if multiple
            if sum(isColoriInZone)>1 and c<=4-sum(isColoriInZone)+1 then
                for i,_ in ipairs(COLORS) do
                    if isColoriInZone[i]==1 then 
                        local avgVals = {}
                        for i=1,sum(isColoriInZone) do
                            avgVals[i] = GOALZONES_VAL[r][c+i-1]
                        end
                        local avgFlr = math.floor(sum(avgVals)/sum(isColoriInZone))
                        scores[i][3] = scores[i][3] + avgFlr
                    end
                end
            -- split remaining points and round up if multiple in later column
            elseif sum(isColoriInZone)>1 then
                for i,_ in ipairs(COLORS) do
                    if isColoriInZone[i]==1 then 
                        local avgVals = {}
                        for i=c,4 do
                            avgVals[i] = GOALZONES_VAL[r][i]
                        end
                        local avgFlr = math.floor(sum(avgVals)/sum(isColoriInZone))
                        scores[i][3] = scores[i][3] + avgFlr
                    end
                end
            -- give points if single
            else
                for i,_ in ipairs(COLORS) do
                    if isColoriInZone[i]==1 then
                        scores[i][3] = scores[i][3] + GOALZONES_VAL[r][c]
                    end
                end
            end
        end
    end
    -- points for bonus cards
    -- nectar ranking
    if isOceaniaAdded then
        -- find rankings
        local nectarWinners = {{{},{}},{{},{}},{{},{}}}
        local nectarCounts =  {{0,0},{0,0},{0,0}}
        for i,_ in ipairs(NECTAR_LOC) do
            for j,loc in ipairs(NECTAR_LOC[i]) do
                local count = 0
                local obj = findObjAt(loc)
                if obj==nil then count = 0
                elseif obj.getData().Number==nil then count = 1
                else count = obj.getData().Number end
                if count>nectarCounts[j][1] then
                    nectarCounts[j][2] = nectarCounts[j][1]
                    nectarWinners[j][2] = {nectarWinners[j][1]}
                    nectarCounts[j][1] = count
                    nectarWinners[j][1] = {i}
                elseif count==nectarCounts[j][1] then
                    nectarWinners[j][1][#nectarWinners[j][1]+1] = i
                    nectarWinners[j][2] = nil
                    nectarWinners[j][2] = {}
                elseif count>nectarCounts[j][2] and #nectarWinners[j][1]<2 then
                    nectarCounts[j][2] = count
                    nectarWinners[j][2] = {i}
                elseif count==nectarCounts[j][2] and #nectarWinners[j][1]<2 then
                    nectarWinners[j][2][#nectarWinners[j][2]+1] = i
                end
            end
        end
        -- give points to winners
        for i,_ in ipairs(scores) do
            for j,_ in ipairs(nectarWinners) do
                if isin(i,nectarWinners[j][1]) then
                    scores[i][5] = scores[i][5] + 5
                elseif isin(i,nectarWinners[j][2]) then
                    scores[i][5] = scores[i][5] + 2
                end
            end
        end
    end
    -- update score pad UI
    local players = Player.getPlayers()
    local playersi = {}
    local p_i = 1
    for _,player in ipairs(players) do
        playersi[p_i] = find(player.color,COLORS)
        p_i = p_i + 1
    end
    playersi = table.sort(playersi)
    for _,i in ipairs(playersi) do
        local id = "ScorepadBirds"..COLORS[i]
        Global.UI.setAttribute(id,"text",tostring(scores[i][1]))
        id = "ScorepadGoals"..COLORS[i]
        Global.UI.setAttribute(id,"text",tostring(scores[i][3]))
        id = "Scorepad4"..COLORS[i]
        Global.UI.setAttribute(id,"text",tostring(scores[i][4]))
        id = "ScorepadNectar"..COLORS[i]
        Global.UI.setAttribute(id,"text",tostring(scores[i][5]))
        id = "ScorepadTotal"..COLORS[i]
        Global.UI.setAttribute(id,"text",tostring(sum(scores[i])))
    end
end

function scoreBonus(_,value,id)
    if value==nil or value=="" then return end
    local color = string.sub(id,14)
    local i = find(color,COLORS)
    scores[i][3] = value
    Global.UI.setAttribute("scorepadTotal"..color,"text",sum(scores[i]))
end
