function onObjectLeaveContainer(container,object)
    -- food
    if isin(container.getGUID(),RESOURCEBAGS_GUID) then
        local tag = RESOURCES[find(container.getGUID(),RESOURCEBAGS_GUID)]
        object.addTag(tag)
    end
    -- egg
    if isin(container.getGUID(),EGGBAGS_GUID) then
        object.addTag("Egg")
    end
end

function onObjectEnterScriptingZone(zone,_)
    if isin(zone.getGUID(),RESOURCEZONES_GUID) then
        local count = {0,0,0,0,0,0}
        for _,obj in ipairs(zone.getObjects()) do
            for j,resource in ipairs(RESOURCES) do
                if isin(resource,obj.getTags()) then
                    if obj.getData().Number==nil then
                        count[j] = count[j]+1
                    else
                        count[j] = count[j]+obj.getData().Number
                    end
                end
            end
        end
        local i = find(zone.getGUID(),RESOURCEZONES_GUID)
        local mat = getObjectFromGUID(RESOURCEMATS_GUID[i])
        for j=1,6 do
            mat.UI.setAttribute(tostring(j),"text",count[j])
            local id = COLORS[i]..RESOURCES[j].."Text"
            Global.UI.setAttribute(id,"text",count[j])
        end
    end
end

function onObjectLeaveScriptingZone(zone,_)
    if isin(zone.getGUID(),RESOURCEZONES_GUID) then
        local count = {0,0,0,0,0,0}
        for _,obj in ipairs(zone.getObjects()) do
            for j,resource in ipairs(RESOURCES) do
                if isin(resource,obj.getTags()) then
                    if obj.getData().Number==nil then
                        count[j] = count[j]+1
                    else
                        count[j] = count[j]+obj.getData().Number
                    end
                end
            end
        end
        local i = find(zone.getGUID(),RESOURCEZONES_GUID)
        local mat = getObjectFromGUID(RESOURCEMATS_GUID[i])
        for j=1,6 do
            mat.UI.setAttribute(tostring(j),"text",count[j])
            local id = COLORS[i]..RESOURCES[j].."Text"
            Global.UI.setAttribute(id,"text",count[j])
        end
    end
end
