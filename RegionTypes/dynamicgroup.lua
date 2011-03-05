﻿local SharedMedia = LibStub("LibSharedMedia-3.0");
    
local default = {
    controlledChildren = {},
    grow = "DOWN",
    align = "CENTER",
    space = 2,
    stagger = 0,
    animate = false,
    anchorPoint = "CENTER",
    xOffset = 0,
    yOffset = 0
};

local function create(parent)
    local region = CreateFrame("FRAME", nil, parent);
    region:SetMovable(true);
    
    region.trays = {};
    
    return region;
end

local function modify(parent, region, data)
    local selfPoint;
    local actualSelfPoint;
    if(data.grow == "RIGHT") then
        selfPoint = "LEFT";
        if(data.align == "LEFT") then
            selfPoint = "TOP"..selfPoint;
        elseif(data.align == "RIGHT") then
            selfPoint = "BOTTOM"..selfPoint;
        end
        actualSelfPoint = selfPoint;
    elseif(data.grow == "LEFT") then
        selfPoint = "RIGHT";
        if(data.align == "LEFT") then
            selfPoint = "TOP"..selfPoint;
        elseif(data.align == "RIGHT") then
            selfPoint = "BOTTOM"..selfPoint;
        end
        actualSelfPoint = selfPoint;
    elseif(data.grow == "UP") then
        selfPoint = "BOTTOM";
        if(data.align == "LEFT") then
            selfPoint = selfPoint.."LEFT";
        elseif(data.align == "RIGHT") then
            selfPoint = selfPoint.."RIGHT";
        end
        actualSelfPoint = selfPoint;
    elseif(data.grow == "DOWN" ) then
        selfPoint = "TOP";
        if(data.align == "LEFT") then
            selfPoint = selfPoint.."LEFT";
        elseif(data.align == "RIGHT") then
            selfPoint = selfPoint.."RIGHT";
        end
        actualSelfPoint = selfPoint;
    elseif(data.grow == "HORIZONTAL") then
        selfPoint = "LEFT";
        actualSelfPoint = "CENTER";
        if(data.align == "LEFT") then
            selfPoint = "TOP"..selfPoint;
            actualSelfPoint = "TOP";
        elseif(data.align == "RIGHT") then
            selfPoint = "BOTTOM"..selfPoint;
            actualSelfPoint = "BOTTOM";
        end
    elseif(data.grow == "VERTICAL") then
        selfPoint = "TOP";
        actualSelfPoint = "CENTER";
        if(data.align == "LEFT") then
            selfPoint = selfPoint.."LEFT";
            actualSelfPoint = "LEFT";
        elseif(data.align == "RIGHT") then
            selfPoint = selfPoint.."RIGHT";
            actualSelfPoint = "RIGHT";
        end
    end
    data.selfPoint = actualSelfPoint;
        
    region:ClearAllPoints();
    region:SetPoint(actualSelfPoint, parent, data.anchorPoint, data.xOffset, data.yOffset);
    
    region.controlledRegions = {};
    
    function region:EnsureControlledRegions()
        local dataIndex = 1;
        local regionIndex = 1;
        while(dataIndex <= #data.controlledChildren) do
            if not(region.controlledRegions[regionIndex]) then
                region.controlledRegions[regionIndex] = {};
            end
            local childId = data.controlledChildren[dataIndex];
            local childData = WeakAuras.GetData(childId);
            region.controlledRegions[regionIndex].id = childId;
            region.controlledRegions[regionIndex].data = childData;
            region.controlledRegions[regionIndex].num = nil;
            region.controlledRegions[regionIndex].region = WeakAuras.regions[childId] and WeakAuras.regions[childId].region;
            dataIndex = dataIndex + 1;
            regionIndex = regionIndex + 1;
            if(childData and WeakAuras.clones[childId]) then
                for cloneNum, cloneRegion in pairs(WeakAuras.clones[childId]) do
                    if not(region.controlledRegions[regionIndex]) then
                        region.controlledRegions[regionIndex] = {};
                    end
                    region.controlledRegions[regionIndex].id = childId;
                    region.controlledRegions[regionIndex].data = childData;
                    region.controlledRegions[regionIndex].num = cloneNum;
                    region.controlledRegions[regionIndex].region = cloneRegion;
                    regionIndex = regionIndex + 1;
                end
            end
        end
    end
    
    function region:EnsureTrays()
        region:EnsureControlledRegions();
        for index, regionData in ipairs(region.controlledRegions) do
            if not(region.trays[index]) then
                region.trays[index] = CreateFrame("Frame", nil, region);
            end
            if(regionData.data and regionData.region) then
                region.trays[index]:SetWidth(regionData.data.width);
                region.trays[index]:SetHeight(regionData.data.height);
                regionData.region:ClearAllPoints();
                regionData.region:SetPoint(selfPoint, region.trays[index], selfPoint);
            end
        end
    end
    
    region:EnsureTrays();
    
    function region:PositionChildren()
        region:EnsureTrays();
        local childId, childData, childRegion;
        local xOffset, yOffset = 0, 0;
        if(data.grow == "RIGHT" or data.grow == "LEFT" or data.grow == "HORIZONTAL") then
            if(data.align == "LEFT" and data.stagger > 0) then
                yOffset = yOffset - (data.stagger * (#region.controlledRegions - 1));
            elseif(data.align == "RIGHT" and data.stagger < 0) then
                yOffset = yOffset - (data.stagger * (#region.controlledRegions - 1));
            elseif(data.align == "CENTER") then
                if(data.stagger < 0) then
                    yOffset = yOffset - (data.stagger * (#region.controlledRegions - 1) / 2);
                else
                    yOffset = yOffset - (data.stagger * (#region.controlledRegions - 1) / 2);
                end
            end
        else
            if(data.align == "LEFT" and data.stagger < 0) then
                xOffset = xOffset - (data.stagger * (#region.controlledRegions - 1));
            elseif(data.align == "RIGHT" and data.stagger > 0) then
                xOffset = xOffset - (data.stagger * (#region.controlledRegions - 1));
            elseif(data.align == "CENTER") then
                if(data.stagger < 0) then
                    xOffset = xOffset - (data.stagger * (#region.controlledRegions - 1) / 2);
                else
                    xOffset = xOffset - (data.stagger * (#region.controlledRegions - 1) / 2);
                end
            end
        end
        
        local centerXOffset, centerYOffset = 0, 0;
        if(data.grow == "HORIZONTAL" or data.grow == "VERTICAL") then
            local currentWidth, currentHeight = 0, 0;
            local num = 0;
            for index, regionData in pairs(region.controlledRegions) do
                childId = regionData.id;
                childData = regionData.data;
                childRegion = regionData.region;
                if(childData and childRegion) then
                    if(((childRegion:IsVisible() and not (childRegion.toHide or childRegion.groupHiding)) or childRegion.toShow) and not (WeakAuras.IsAnimating(regionData.num and "clone"..regionData.num or "display", childId) == "finish")) then
                        if(data.grow == "HORIZONTAL") then
                            currentWidth = currentWidth + childData.width;
                            num = num + 1;
                        elseif(data.grow == "VERTICAL") then
                            currentHeight = currentHeight + childData.height;
                            num = num + 1;
                        end
                    end
                end
            end
            
            if(data.grow == "HORIZONTAL") then
                currentWidth = currentWidth + (data.space * max(num - 1, 0));
                centerXOffset = ((data.width - currentWidth) / 2);
                centerYOffset = 0;
            elseif(data.grow == "VERTICAL") then
                currentHeight = currentHeight + (data.space * max(num - 1, 0));
                centerYOffset = ((data.height - currentHeight) / 2);
                centerXOffset = 0;
            end
        end
        xOffset = xOffset + centerXOffset;
        yOffset = yOffset - centerYOffset;
        
        for index, regionData in pairs(region.controlledRegions) do
            childId = regionData.id;
            childData = regionData.data;
            childRegion = regionData.region;
            if(childData and childRegion) then
                if(childRegion.toShow) then
                    childRegion.toHide = nil;
                    childRegion.groupHiding = nil;
                end
                
                if((childRegion:IsVisible() or childRegion.toShow) and not (childRegion.toHide or childRegion.groupHiding or WeakAuras.IsAnimating(regionData.num and "clone"..regionData.num or "display", childId) == "finish")) then
                    if not(region.trays[index]) then
                        print(data.id, index, childId);
                    end
                    region.trays[index]:ClearAllPoints();
                    region.trays[index]:SetPoint(selfPoint, region, selfPoint, xOffset, yOffset);
                    childRegion:ClearAllPoints();
                    childRegion:SetPoint(selfPoint, region.trays[index], selfPoint);
                    if(data.grow == "RIGHT" or data.grow == "HORIZONTAL") then
                        xOffset = xOffset + (childData.width + data.space);
                        yOffset = yOffset + data.stagger;
                    elseif(data.grow == "LEFT") then
                        xOffset = xOffset - (childData.width + data.space);
                        yOffset = yOffset + data.stagger;
                    elseif(data.grow == "UP") then
                        yOffset = yOffset + (childData.height + data.space);
                        xOffset = xOffset + data.stagger;
                    elseif(data.grow == "DOWN" or data.grow == "VERTICAL") then
                        yOffset = yOffset - (childData.height + data.space);
                        xOffset = xOffset + data.stagger;
                    end
                else
                    local hiddenXOffset, hiddenYOffset;
                    if(data.grow == "RIGHT") then
                        hiddenXOffset = xOffset - (childData.width + data.space);
                        hiddenYOffset = yOffset - data.stagger;
                    elseif(data.grow == "LEFT") then
                        hiddenXOffset = xOffset + (childData.width + data.space);
                        hiddenYOffset = yOffset - data.stagger;
                    elseif(data.grow == "UP") then
                        hiddenYOffset = yOffset - (childData.height + data.space);
                        hiddenXOffset = xOffset - data.stagger;
                    elseif(data.grow == "DOWN") then
                        hiddenYOffset = yOffset + (childData.height + data.space);
                        hiddenXOffset = xOffset - data.stagger;
                    elseif(data.grow == "HORIZONTAL") then
                        hiddenXOffset = xOffset - ((childData.width + data.space) * (xOffset / data.width));
                        hiddenYOffset = yOffset - data.stagger;
                    elseif(data.grow == "VERTICAL") then
                        hiddenYOffset = yOffset - ((childData.height + data.space) * (yOffset / data.height));
                        hiddenXOffset = xOffset - data.stagger;
                    end
                    
                    region.trays[index]:ClearAllPoints();
                    region.trays[index]:SetPoint(selfPoint, region, selfPoint, hiddenXOffset, hiddenYOffset);
                    childRegion:ClearAllPoints();
                    childRegion:SetPoint(selfPoint, region.trays[index], selfPoint);
                end
            end
        end
    end
    
    function region:ControlChildren()
        if(data.animate) then
            WeakAuras.pending_controls[data.id] = region;
        else
            region:DoControlChildren();
        end
    end
    
    function region:DoControlChildren()
        local previous = {};
        for index, regionData in pairs(region.controlledRegions) do
            local _, _, _, previousX, previousY = region.trays[index]:GetPoint(1);
            previousX = previousX or 0;
            previousY = previousY or 0;
            previous[regionData.id] = {x = previousX, y = previousY};
        end
        
        region:PositionChildren();
        
        
        for index, regionData in pairs(region.controlledRegions) do
            childId = regionData.id;
            childData = regionData.data;
            childRegion = regionData.region;
            if(childData and childRegion) then
                if(childRegion.toShow) then
                    childRegion:Show();
                    childRegion.toShow = nil;
                end
                
                local _, _, _, xOffset, yOffset = region.trays[index]:GetPoint(1);
                local previousX, previousY = previous[childId].x, previous[childId].y;
                if(childRegion:IsVisible() and data.animate) then
                    local anim = {
                        type = "custom",
                        duration = 0.2,
                        use_translate = true,
                        x = previousX - xOffset,
                        y = previousY - yOffset
                    };
                    if(childRegion.toHide) then
                        childRegion.toHide = nil;
                        if(WeakAuras.IsAnimating("display", childId) == "finish") then
                            --childRegion will be hidden by its own animation, so the tray animation does not need to hide it
                        else
                            childRegion.groupHiding = true;
                        end
                    end
                    WeakAuras.CancelAnimation(index.."tray", data.id);
                    WeakAuras.Animate(index.."tray", data.id, "tray", anim, region.trays[index], true, function()
                        if(childRegion.groupHiding) then
                            childRegion.groupHiding = nil;
                            childRegion:Hide();
                        end
                    end);
                elseif(childRegion.toHide) then
                    childRegion.toHide = nil;
                    if(WeakAuras.IsAnimating("display", childId) == "finish") then
                        --childRegion will be hidden by its own animation, so it does not need to be hidden immediately
                    else
                        childRegion:Hide();
                    end
                end
            end
        end
    end    
    
    for index, childId in pairs(data.controlledChildren) do
        local childData = WeakAuras.GetData(childId);
        if(childData) then
            WeakAuras.Add(childData);
        end
    end
    
    region:PositionChildren();
    
    local lowestRegion = WeakAuras.regions[data.controlledChildren[#data.controlledChildren]] and WeakAuras.regions[data.controlledChildren[#data.controlledChildren]].region;
    if(lowestRegion) then    
        local frameLevel = lowestRegion:GetFrameLevel();
        for i=#region.controlledRegions-1,1,-1 do
            local childRegion = region.controlledRegions[i].region;
            if(childRegion) then
                frameLevel = frameLevel + 1;
                childRegion:SetFrameLevel(frameLevel);
            end
        end
    end
    
    local maxWidth, maxHeight = 0, 0;
    for index, regionData in pairs(region.controlledRegions) do
        childId = regionData.id;
        childData = regionData.data;
        if(childData) then
            if(data.grow == "LEFT" or data.grow == "RIGHT" or data.grow == "HORIZONTAL") then
                maxWidth = maxWidth + childData.width;
                maxWidth = maxWidth + (index > 1 and data.space or 0);
                maxHeight = math.max(maxHeight, childData.height);
            else
                maxHeight = maxHeight + childData.height;
                maxHeight = maxHeight + (index > 1 and data.space or 0);
                maxWidth = math.max(maxWidth, childData.width);
            end
        end
    end
    if(data.grow == "LEFT" or data.grow == "RIGHT") then
        maxHeight = maxHeight + (math.abs(data.stagger) * (#data.controlledChildren - 1));
    else
        maxWidth = maxWidth + (math.abs(data.stagger) * (#data.controlledChildren - 1));
    end
    
    maxWidth = (maxWidth and maxWidth > 16 and maxWidth) or 16;
    maxHeight = (maxHeight and maxHeight > 16 and maxHeight) or 16;
    
    data.width, data.height = maxWidth, maxHeight;
    region:SetWidth(data.width);
    region:SetHeight(data.height);
end

WeakAuras.RegisterRegionType("dynamicgroup", create, modify, default);