-- BagBorder - Simple bag border coloring addon for WoW 3.3.5a

local BagBorder = CreateFrame("Frame")

-- Check if Bagnon is loaded and disable if it is
local usingBagnon = IsAddOnLoaded("Bagnon")
if usingBagnon then
    print("|cFF00FFFF[BagBorder]|r Bagnon detected. BagBorder has been disabled to avoid conflicts.")
    return -- This effectively stops the execution of the rest of the addon
end

-- Colors for item rarities
local colors = {
    [2] = {0, 1, 0},       -- Uncommon (green)
    [3] = {0, 0.5, 1},     -- Rare (blue)
    [4] = {0.8, 0.3, 0.9}, -- Epic (purple)
    [5] = {1, 0.5, 0}      -- Legendary (orange)
}

-- Excluded items
local excludedItems = {
    ["Hearthstone"] = true,
    ["Skinning Knife"] = true,
    ["Mining Pick"] = true,
    ["Symbol of Kings"] = true
}

-- Debug function
local function DebugPrint(...)
    -- Set to true to enable debug output
    local debug = false
    if debug then
        print("|cFF00FFFF[BagBorder]|r", ...)
    end
end

-- Apply border to a specific button
local function ApplyBorder(button)
    -- Return if button doesn't exist
    if not button then return end
    
    -- Clear existing border if any
    if button.borderTexture then
        button.borderTexture:Hide()
    end
    
    -- Get bag and slot from the button
    local bag, slot
    
    -- Get from button attributes directly
    bag = button:GetParent():GetID()
    slot = button:GetID()
    
    DebugPrint("Processing button for bag:", bag, "slot:", slot)
    
    -- Get the item in this slot
    local link = GetContainerItemLink(bag, slot)
    
    -- If no item, we're done - no border needed
    if not link then
        DebugPrint("No item in bag:", bag, "slot:", slot)
        return 
    end
    
    -- Get item info
    local name, _, rarity = GetItemInfo(link)
    
    -- Safety check in case GetItemInfo fails
    if not name or not rarity then
        DebugPrint("GetItemInfo failed for", link)
        return
    end
    
    DebugPrint("Found item:", name, "rarity:", rarity)
    
    -- Skip excluded items
    if excludedItems[name] then
        DebugPrint("Item is excluded:", name)
        return
    end
    
    -- Check if we should color this rarity
    if not colors[rarity] then
        DebugPrint("Rarity not configured:", rarity)
        return
    end
    
    -- Create border texture if needed
    if not button.borderTexture then
        button.borderTexture = button:CreateTexture(nil, "OVERLAY")
        button.borderTexture:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        button.borderTexture:SetBlendMode("ADD")
        button.borderTexture:SetWidth(button:GetWidth() * 1.8)
        button.borderTexture:SetHeight(button:GetHeight() * 1.8)
        button.borderTexture:SetPoint("CENTER", button, "CENTER", 0, 0)
    end
    
    -- Apply color
    local r, g, b = unpack(colors[rarity])
    button.borderTexture:SetVertexColor(r, g, b, 0.8)
    button.borderTexture:Show()
    
    DebugPrint("Applied border color:", r, g, b, "to button for bag:", bag, "slot:", slot)
end

-- Function to update all bag slots
local function UpdateBagSlots()
    DebugPrint("Updating all bag slots")
    
    -- Loop through all container frames
    for bagFrameID = 1, NUM_CONTAINER_FRAMES do
        local bagFrame = _G["ContainerFrame"..bagFrameID]
        
        -- Skip if this frame isn't visible
        if bagFrame and bagFrame:IsVisible() then
            -- Get bag ID
            local bagID = bagFrame:GetID()
            
            -- Calculate size based on container size
            local size = GetContainerNumSlots(bagID)
            
            DebugPrint("Processing bag frame:", bagFrameID, "bag ID:", bagID, "size:", size)
            
            -- Process if we have slots
            if size and size > 0 then
                -- Loop through all slots in this bag
                for slot = 1, size do
                    -- Get the actual slot button
                    local button = _G[bagFrame:GetName().."Item"..slot]
                    
                    if button then
                        ApplyBorder(button)
                    else
                        DebugPrint("Button not found for bag:", bagID, "slot:", slot)
                    end
                end
            end
        end
    end
end

-- Debounce update function to prevent excessive updates
local updateQueued = false
local function QueueBagUpdate(delay)
    if not updateQueued then
        updateQueued = true
        BagBorder.updateTime = delay or 0.1
        BagBorder:SetScript("OnUpdate", function(self, elapsed)
            self.updateTime = self.updateTime - elapsed
            if self.updateTime <= 0 then
                UpdateBagSlots()
                updateQueued = false
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end

-- Register events
BagBorder:RegisterEvent("BAG_UPDATE")
BagBorder:RegisterEvent("PLAYER_LOGIN")
BagBorder:RegisterEvent("ADDON_LOADED")
BagBorder:RegisterEvent("BAG_UPDATE_COOLDOWN")
BagBorder:RegisterEvent("ITEM_LOCK_CHANGED")

-- Event handler
BagBorder:SetScript("OnEvent", function(self, event, ...)
    DebugPrint("Event triggered:", event, ...)
    
    if event == "PLAYER_LOGIN" or event == "ADDON_LOADED" then
        -- On login, update after a longer delay
        QueueBagUpdate(1.0)
    else
        -- For other events, use a smaller delay
        QueueBagUpdate(0.1)
    end
end)

-- Hook the ContainerFrame_Update function
hooksecurefunc("ContainerFrame_Update", function(frame)
    DebugPrint("ContainerFrame_Update hooked for frame:", frame:GetName())
    
    local size = GetContainerNumSlots(frame:GetID())
    
    for slot = 1, size do
        local button = _G[frame:GetName().."Item"..slot]
        if button then
            ApplyBorder(button)
        end
    end
end)

-- Add slash command
SLASH_BAGBORDER1 = "/bb"
SlashCmdList["BAGBORDER"] = function(msg)
    if msg == "debug" then
        -- Toggle debug mode
        local debug = not debug
        print("|cFF00FFFF[BagBorder]|r Debug mode:", debug and "ON" or "OFF")
    else
        print("|cFF00FFFF[BagBorder]|r Updating bag borders...")
        UpdateBagSlots()
    end
end

print("|cFF00FFFF[BagBorder]|r loaded. Type /bb to update borders manually.")