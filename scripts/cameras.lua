function onScriptingButtonDown(index, color)
    -- player mat
    if index == 1 then
        log(color)
        local i = find(color,COLORS)
        log(i)
        local mat = getObjectFromGUID(PLAYERMATZONES_GUID[i])
        log(mat)
        Player[color].lookAt({
            position = mat.getPosition(),
            pitch    = 90,
            yaw      = mat.getRotation().y-180,
            distance = 15,
        })
    end
    -- card tray
    if index == 2 then
        local tray = getObjectFromGUID(TRAY_GUID)
        Player[color].lookAt({
            position = tray.getPosition(),
            pitch    = 90,
            yaw      = 0,
            distance = 20,
        })
    end
    -- card tray
    if index == 3 then
        local tray = getObjectFromGUID(TRAY_GUID)
        local pos = tray.getPosition()
        Player[color].lookAt({
            position = {pos.x-4,pos.y,pos.z},
            pitch    = 90,
            yaw      = 0,
            distance = 10,
        })
    end
    -- round-end card
    if index == 4 then
        local card = getObjectFromGUID(ROUNDGOALSCARD_GUID)
        Player[color].lookAt({
            position = card.getPosition(),
            pitch    = 90,
            yaw      = 0,
            distance = 10,
        })
    end
    -- birdfeeder
    local birdfeeder = getObjectFromGUID(BIRDFEEDER_GUID)
    local pos = birdfeeder.getPosition()
    if index == 5 then
        Player[color].lookAt({
            position = {pos.x+6,pos.y,pos.z},
            pitch    = 90,
            yaw      = 270,
            distance = 10,
        })
    end
    -- maxwell
    if index == 6 then
        Player[color].lookAt({
            position = {-22.54, 11.96, -19.14},
            pitch    = 25,
            yaw      = 215,
            distance = 15,
        })
    end
end
