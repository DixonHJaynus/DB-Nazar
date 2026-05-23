local RSGCore = exports['rsg-core']:GetCoreObject()

-- ============================================================================
-- SERVER STATE
-- ============================================================================

local currentLocationIndex = nil
local lastRelocationTime = 0
local isInitialized = false

-- ============================================================================
-- UTILITY
-- ============================================================================

local function DebugPrint(msg)
    if Config.Debug then
        print('[DB-Nazar:Server] ' .. tostring(msg))
    end
end

local function SelectRandomLocation(excludeIndex)
    local validLocations = {}
    for i = 1, #Config.Locations do
        if i ~= excludeIndex then
            table.insert(validLocations, i)
        end
    end
    if #validLocations == 0 then return 1 end
    return validLocations[math.random(#validLocations)]
end

-- ============================================================================
-- SAVE LOCATION STATE
-- ============================================================================

local function SaveLocationState()
    lastRelocationTime = os.time()
    MySQL.Async.execute([[
        INSERT INTO db_nazar_state (id, location_index, last_relocation)
        VALUES (1, @idx, @time)
        ON DUPLICATE KEY UPDATE location_index = @idx, last_relocation = @time
    ]], {
        ['@idx'] = currentLocationIndex,
        ['@time'] = lastRelocationTime,
    }, function(rowsChanged)
        DebugPrint('Location state saved. Rows affected: ' .. tostring(rowsChanged))
    end)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

local function InitializeLocation()
    MySQL.Async.fetchAll('SELECT * FROM db_nazar_state WHERE id = 1 LIMIT 1', {}, function(result)
        -- Check if we got a valid result
        if result and type(result) == 'table' and #result > 0 and result[1] then
            local savedData = result[1]
            local savedIndex = savedData.location_index
            local savedTime = savedData.last_relocation or 0

            -- Validate savedIndex
            if savedIndex and savedIndex >= 1 and savedIndex <= #Config.Locations then
                local currentTime = os.time()
                local intervalSeconds = Config.RelocationInterval * 60

                if (currentTime - savedTime) >= intervalSeconds then
                    -- Time to relocate
                    currentLocationIndex = SelectRandomLocation(savedIndex)
                    DebugPrint('Time elapsed, relocating to location ' .. currentLocationIndex .. ' (' .. Config.Locations[currentLocationIndex].label .. ')')
                else
                    -- Use saved location
                    currentLocationIndex = savedIndex
                    DebugPrint('Using saved location ' .. currentLocationIndex .. ' (' .. Config.Locations[currentLocationIndex].label .. ')')
                end
            else
                -- Invalid saved index, pick random
                currentLocationIndex = math.random(#Config.Locations)
                DebugPrint('Invalid saved index, picking random location ' .. currentLocationIndex)
            end
        else
            -- No saved data, first time setup
            currentLocationIndex = math.random(#Config.Locations)
            DebugPrint('No saved data, first run - selected location ' .. currentLocationIndex .. ' (' .. Config.Locations[currentLocationIndex].label .. ')')
        end

        -- Save the current state
        SaveLocationState()

        -- Mark as initialized
        isInitialized = true

        -- Notify all connected players
        TriggerClientEvent('db-nazar:client:updateLocation', -1, currentLocationIndex)
        DebugPrint('Initialization complete. Nazar at: ' .. Config.Locations[currentLocationIndex].label)
    end)
end

-- ============================================================================
-- STARTUP
-- ============================================================================

CreateThread(function()
    -- Wait for database and other resources to be ready
    Wait(5000)
    InitializeLocation()
end)

-- ============================================================================
-- RELOCATION TIMER
-- ============================================================================

CreateThread(function()
    -- Wait for initialization
    while not isInitialized do
        Wait(1000)
    end

    while true do
        local intervalMs = Config.RelocationInterval * 60 * 1000
        Wait(intervalMs)

        local oldIndex = currentLocationIndex
        currentLocationIndex = SelectRandomLocation(oldIndex)
        SaveLocationState()

        local locationLabel = Config.Locations[currentLocationIndex].label
        DebugPrint('Nazar relocated to: ' .. locationLabel)

        -- Notify all players
        TriggerClientEvent('db-nazar:client:updateLocation', -1, currentLocationIndex)
        TriggerClientEvent('db-nazar:client:notifyRelocation', -1, locationLabel)
    end
end)

-- ============================================================================
-- CALLBACK - GET LOCATION
-- ============================================================================

RSGCore.Functions.CreateCallback('db-nazar:server:getLocation', function(source, cb)
    -- Wait for initialization if needed
    local waitTime = 0
    while not isInitialized and waitTime < 10000 do
        Wait(500)
        waitTime = waitTime + 500
    end

    if currentLocationIndex then
        cb(currentLocationIndex)
    else
        cb(1) -- Fallback to first location
    end
end)

-- ============================================================================
-- PLAYER JOINED - SEND LOCATION
-- ============================================================================

RegisterNetEvent('RSGCore:Client:OnPlayerLoaded', function()
    local src = source
    if isInitialized and currentLocationIndex then
        Wait(2000) -- Give client time to load
        TriggerClientEvent('db-nazar:client:updateLocation', src, currentLocationIndex)
    end
end)

AddEventHandler('playerJoining', function()
    local src = source
    if isInitialized and currentLocationIndex then
        Wait(3000)
        TriggerClientEvent('db-nazar:client:updateLocation', src, currentLocationIndex)
    end
end)

-- ============================================================================
-- PURCHASE ITEM
-- ============================================================================

RegisterNetEvent('db-nazar:server:purchaseItem', function(itemName, clientPrice, clientRequiredItem)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Validate item exists in config and get server-side values
    local validItem = false
    local price = 0
    local itemLabel = itemName
    local requiredItem = nil

    for _, category in pairs(Config.ShopCategories) do
        for _, item in pairs(category.items) do
            if item.item == itemName then
                validItem = true
                price = item.price
                itemLabel = item.label
                requiredItem = item.requiredItem
                break
            end
        end
        if validItem then break end
    end

    if not validItem then
        DebugPrint('Invalid item purchase attempt: ' .. tostring(itemName) .. ' by player ' .. src)
        TriggerClientEvent('db-nazar:client:purchaseResult', src, false, 'Invalid item.')
        return
    end

    -- Check required item
    if requiredItem then
        local hasRequired = Player.Functions.GetItemByName(requiredItem)
        if not hasRequired then
            TriggerClientEvent('db-nazar:client:purchaseResult', src, false, "You need a Collector's Bag first.")
            return
        end
    end

    -- Check money
    local cash = Player.PlayerData.money['cash'] or 0
    if cash < price then
        TriggerClientEvent('db-nazar:client:purchaseResult', src, false, 'Not enough money. You need $' .. string.format('%.2f', price))
        return
    end

    -- Process purchase
    Player.Functions.RemoveMoney('cash', price, 'nazar-purchase-' .. itemName)
    Player.Functions.AddItem(itemName, 1)

    -- Trigger inventory update if available
    if RSGCore.Shared.Items[itemName] then
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[itemName], 'add')
    end

    -- Log transaction
    MySQL.Async.execute([[
        INSERT INTO db_nazar_transactions (citizenid, transaction_type, item, amount, price)
        VALUES (@cid, @type, @item, @amount, @price)
    ]], {
        ['@cid'] = Player.PlayerData.citizenid,
        ['@type'] = 'purchase',
        ['@item'] = itemName,
        ['@amount'] = 1,
        ['@price'] = price,
    })

    DebugPrint('Player ' .. src .. ' purchased ' .. itemLabel .. ' for $' .. price)
    TriggerClientEvent('db-nazar:client:purchaseResult', src, true, nil, itemLabel)
end)

-- ============================================================================
-- PURCHASE COLLECTOR'S BAG
-- ============================================================================

RegisterNetEvent('db-nazar:server:purchaseCollectorBag', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Check if already has bag
    local hasBag = Player.Functions.GetItemByName(Config.CollectorBag.item)
    if hasBag then
        TriggerClientEvent('db-nazar:client:purchaseResult', src, false, "You already own a Collector's Bag.")
        return
    end

    local price = Config.CollectorBag.price
    local cash = Player.PlayerData.money['cash'] or 0

    if cash < price then
        TriggerClientEvent('db-nazar:client:purchaseResult', src, false, 'Not enough money. You need $' .. string.format('%.2f', price))
        return
    end

    -- Process purchase
    Player.Functions.RemoveMoney('cash', price, 'nazar-purchase-collectors-bag')
    Player.Functions.AddItem(Config.CollectorBag.item, 1)

    if RSGCore.Shared.Items[Config.CollectorBag.item] then
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[Config.CollectorBag.item], 'add')
    end

    -- Log transaction
    MySQL.Async.execute([[
        INSERT INTO db_nazar_transactions (citizenid, transaction_type, item, amount, price)
        VALUES (@cid, @type, @item, @amount, @price)
    ]], {
        ['@cid'] = Player.PlayerData.citizenid,
        ['@type'] = 'purchase',
        ['@item'] = Config.CollectorBag.item,
        ['@amount'] = 1,
        ['@price'] = price,
    })

    DebugPrint('Player ' .. src .. ' purchased Collector\'s Bag')
    TriggerClientEvent('db-nazar:client:purchaseResult', src, true, nil, Config.CollectorBag.label)
end)

-- ============================================================================
-- SELL INDIVIDUAL ITEM
-- ============================================================================

RegisterNetEvent('db-nazar:server:sellItem', function(itemName, clientSellPrice)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Validate item and get server-side price
    local validItem = false
    local serverPrice = 0

    -- Check individual collectibles
    for _, item in pairs(Config.Collectibles.individual) do
        if item.item == itemName then
            validItem = true
            serverPrice = item.sellPrice
            break
        end
    end

    -- Check collection items
    if not validItem then
        for _, collection in pairs(Config.Collectibles.collections) do
            for _, item in pairs(collection.items) do
                if item.item == itemName then
                    validItem = true
                    serverPrice = item.sellPrice
                    break
                end
            end
            if validItem then break end
        end
    end

    if not validItem then
        DebugPrint('Invalid sell attempt: ' .. tostring(itemName) .. ' by player ' .. src)
        TriggerClientEvent('db-nazar:client:sellResult', src, false, "I don't buy that kind of thing.")
        return
    end

    -- Check if player has the item
    local hasItem = Player.Functions.GetItemByName(itemName)
    if not hasItem then
        TriggerClientEvent('db-nazar:client:sellResult', src, false, "You don't have that item.")
        return
    end

    -- Process sale
    Player.Functions.RemoveItem(itemName, 1)
    Player.Functions.AddMoney('cash', serverPrice, 'nazar-sell-' .. itemName)

    if RSGCore.Shared.Items[itemName] then
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[itemName], 'remove')
    end

    -- Log transaction
    MySQL.Async.execute([[
        INSERT INTO db_nazar_transactions (citizenid, transaction_type, item, amount, price)
        VALUES (@cid, @type, @item, @amount, @price)
    ]], {
        ['@cid'] = Player.PlayerData.citizenid,
        ['@type'] = 'sell',
        ['@item'] = itemName,
        ['@amount'] = 1,
        ['@price'] = serverPrice,
    })

    DebugPrint('Player ' .. src .. ' sold ' .. itemName .. ' for $' .. serverPrice)
    TriggerClientEvent('db-nazar:client:sellResult', src, true, nil, serverPrice)
end)

-- ============================================================================
-- SELL COMPLETE COLLECTION
-- ============================================================================

RegisterNetEvent('db-nazar:server:sellCollection', function(collectionId, clientItems, clientPrice)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Find the collection in config
    local collection = nil
    for _, col in pairs(Config.Collectibles.collections) do
        if col.id == collectionId then
            collection = col
            break
        end
    end

    if not collection then
        TriggerClientEvent('db-nazar:client:sellCollectionResult', src, false, 'Unknown collection.')
        return
    end

    -- Verify player has ALL items in the collection
    for _, item in pairs(collection.items) do
        local hasItem = Player.Functions.GetItemByName(item.item)
        if not hasItem then
            TriggerClientEvent('db-nazar:client:sellCollectionResult', src, false, "You're missing items from this collection.")
            return
        end
    end

    -- Calculate total with bonus (server-side)
    local baseTotal = 0
    for _, item in pairs(collection.items) do
        baseTotal = baseTotal + item.sellPrice
    end
    local bonusTotal = baseTotal * (collection.setBonus or 1.0)

    -- Remove all items
    for _, item in pairs(collection.items) do
        Player.Functions.RemoveItem(item.item, 1)
        if RSGCore.Shared.Items[item.item] then
            TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[item.item], 'remove')
        end
    end

    -- Pay the player
    Player.Functions.AddMoney('cash', bonusTotal, 'nazar-sell-collection-' .. collectionId)

    -- Log transaction
    MySQL.Async.execute([[
        INSERT INTO db_nazar_transactions (citizenid, transaction_type, item, amount, price)
        VALUES (@cid, @type, @item, @amount, @price)
    ]], {
        ['@cid'] = Player.PlayerData.citizenid,
        ['@type'] = 'sell_collection',
        ['@item'] = collectionId,
        ['@amount'] = #collection.items,
        ['@price'] = bonusTotal,
    })

    DebugPrint('Player ' .. src .. ' sold collection ' .. collectionId .. ' for $' .. string.format('%.2f', bonusTotal))
    TriggerClientEvent('db-nazar:client:sellCollectionResult', src, true, nil, bonusTotal)
end)

-- ============================================================================
-- FORTUNE TELLING
-- ============================================================================

RegisterNetEvent('db-nazar:server:requestFortune', function()
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    if not Config.FortuneTelling.enabled then
        TriggerClientEvent('db-nazar:client:fortuneResult', src, false, 'Fortune telling is not available.')
        return
    end

    local cost = Config.FortuneTelling.cost
    local cash = Player.PlayerData.money['cash'] or 0

    if cash < cost then
        TriggerClientEvent('db-nazar:client:fortuneResult', src, false, 'Not enough money for a reading. ($' .. string.format('%.2f', cost) .. ' required)')
        return
    end

    -- Charge the player
    Player.Functions.RemoveMoney('cash', cost, 'nazar-fortune-telling')

    -- Select random fortune
    local fortunes = Config.FortuneTelling.fortunes
    if not fortunes or #fortunes == 0 then
        TriggerClientEvent('db-nazar:client:fortuneResult', src, false, 'The spirits are silent...')
        return
    end

    local fortune = fortunes[math.random(#fortunes)]

    -- Handle rewards
    if fortune.reward then
        if fortune.reward.type == 'money' and fortune.reward.amount then
            Player.Functions.AddMoney('cash', fortune.reward.amount, 'nazar-fortune-reward')
            DebugPrint('Player ' .. src .. ' received fortune money reward: $' .. fortune.reward.amount)
        elseif fortune.reward.type == 'item' and fortune.reward.item then
            Player.Functions.AddItem(fortune.reward.item, fortune.reward.amount or 1)
            if RSGCore.Shared.Items[fortune.reward.item] then
                TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[fortune.reward.item], 'add')
            end
            DebugPrint('Player ' .. src .. ' received fortune item reward: ' .. fortune.reward.item)
        end
    end

    -- Log transaction
    MySQL.Async.execute([[
        INSERT INTO db_nazar_transactions (citizenid, transaction_type, item, amount, price)
        VALUES (@cid, @type, @item, @amount, @price)
    ]], {
        ['@cid'] = Player.PlayerData.citizenid,
        ['@type'] = 'fortune',
        ['@item'] = fortune.type or 'generic',
        ['@amount'] = 1,
        ['@price'] = cost,
    })

    DebugPrint('Player ' .. src .. ' received fortune: ' .. (fortune.type or 'generic'))
    TriggerClientEvent('db-nazar:client:fortuneResult', src, true, fortune)
end)

-- ============================================================================
-- ADMIN COMMANDS
-- ============================================================================

RSGCore.Commands.Add('nazarteleport', 'Teleport to Madam Nazar', {}, false, function(source)
    local src = source
    if not currentLocationIndex then
        RSGCore.Functions.Notify(src, 'Nazar hasn\'t been placed yet.', 'error')
        return
    end
    local loc = Config.Locations[currentLocationIndex]
    if not loc then
        RSGCore.Functions.Notify(src, 'Invalid location.', 'error')
        return
    end
    local coords = loc.coords
    TriggerClientEvent('db-nazar:client:teleportToNazar', src, vector3(coords.x, coords.y, coords.z))
    RSGCore.Functions.Notify(src, 'Teleporting to Madam Nazar at ' .. loc.label, 'success')
end, 'admin')

RSGCore.Commands.Add('nazarrelocate', 'Force Nazar to relocate', {}, false, function(source)
    local src = source
    local oldIndex = currentLocationIndex
    currentLocationIndex = SelectRandomLocation(oldIndex)
    SaveLocationState()

    local locationLabel = Config.Locations[currentLocationIndex].label
    TriggerClientEvent('db-nazar:client:updateLocation', -1, currentLocationIndex)
    TriggerClientEvent('db-nazar:client:notifyRelocation', -1, locationLabel)

    RSGCore.Functions.Notify(src, 'Nazar relocated to ' .. locationLabel, 'success')
    DebugPrint('Admin ' .. src .. ' forced relocation to ' .. locationLabel)
end, 'admin')

RSGCore.Commands.Add('nazarlocation', 'Show Nazar\'s current location', {}, false, function(source)
    local src = source
    if currentLocationIndex and Config.Locations[currentLocationIndex] then
        local loc = Config.Locations[currentLocationIndex]
        RSGCore.Functions.Notify(src, 'Nazar is at: ' .. loc.label, 'primary')
    else
        RSGCore.Functions.Notify(src, 'Nazar location unknown.', 'error')
    end
end, 'admin')

-- ============================================================================
-- TREASURE MAP USAGE
-- ============================================================================

local registeredMaps = {}

CreateThread(function()
    -- Wait for core to be ready
    Wait(3000)

    for mapItem, mapData in pairs(Config.MapRewards) do
        if not registeredMaps[mapItem] then
            registeredMaps[mapItem] = true

            RSGCore.Functions.CreateUseableItem(mapItem, function(source, item)
                local src = source
                TriggerEvent('db-nazar:server:useMap', src, mapItem)
            end)

            DebugPrint('Registered useable map: ' .. mapItem)
        end
    end

    DebugPrint('All treasure maps registered.')
end)

AddEventHandler('db-nazar:server:useMap', function(src, mapItem)
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Check if player has the map
    local hasMap = Player.Functions.GetItemByName(mapItem)
    if not hasMap then
        DebugPrint('Player ' .. src .. ' tried to use ' .. mapItem .. ' but does not have it')
        return
    end

    -- Check if player has collector's bag
    local hasBag = Player.Functions.GetItemByName(Config.CollectorBag.item)
    if not hasBag then
        RSGCore.Functions.Notify(src, "You need a Collector's Bag to read this map.", 'error')
        return
    end

    -- Get map reward data
    local mapData = Config.MapRewards[mapItem]
    if not mapData or not mapData.possibleRewards or #mapData.possibleRewards == 0 then
        RSGCore.Functions.Notify(src, 'This map seems to be blank...', 'error')
        return
    end

    -- Pick a random reward item
    local rewardItem = mapData.possibleRewards[math.random(#mapData.possibleRewards)]

    -- Pick a random dig location
    if not Config.DigLocations or #Config.DigLocations == 0 then
        RSGCore.Functions.Notify(src, 'No dig locations available.', 'error')
        return
    end
    local digCoords = Config.DigLocations[math.random(#Config.DigLocations)]

    -- Remove the map from inventory
    Player.Functions.RemoveItem(mapItem, 1)
    if RSGCore.Shared.Items[mapItem] then
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[mapItem], 'remove')
    end

    -- Send dig location and reward to client
    TriggerClientEvent('db-nazar:client:activateMap', src, mapItem, {
        x = digCoords.x,
        y = digCoords.y,
        z = digCoords.z,
    }, rewardItem)

    DebugPrint('Player ' .. src .. ' used ' .. mapItem .. ' -> dig at ' .. tostring(digCoords) .. ' -> reward: ' .. rewardItem)
end)

-- ============================================================================
-- TREASURE CLAIM
-- ============================================================================

RegisterNetEvent('db-nazar:server:claimTreasure', function(mapItem, rewardItem)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then
        DebugPrint('TreasureClaim: Player not found for source ' .. src)
        return
    end

    DebugPrint('==========================================')
    DebugPrint('TreasureClaim called by player ' .. src)
    DebugPrint('Map: ' .. tostring(mapItem))
    DebugPrint('Reward: ' .. tostring(rewardItem))

    -- Validate reward item exists in config
    local validReward = false
    local rewardLabel = rewardItem

    if Config.MapRewards[mapItem] then
        for _, possibleReward in pairs(Config.MapRewards[mapItem].possibleRewards) do
            if possibleReward == rewardItem then
                validReward = true
                break
            end
        end
    end

    if not validReward then
        DebugPrint('Invalid treasure claim: ' .. tostring(rewardItem) .. ' from map ' .. tostring(mapItem))
        TriggerClientEvent('db-nazar:client:treasureResult', src, false, 'Invalid treasure.')
        return
    end

    -- Get reward label from collectibles config
    for _, collection in pairs(Config.Collectibles.collections) do
        for _, item in pairs(collection.items) do
            if item.item == rewardItem then
                rewardLabel = item.label
                break
            end
        end
    end

    DebugPrint('Reward label: ' .. tostring(rewardLabel))

    -- CHECK IF ITEM EXISTS IN RSG SHARED ITEMS
    if not RSGCore.Shared.Items[rewardItem] then
        DebugPrint('ERROR: Item "' .. rewardItem .. '" does not exist in RSGCore.Shared.Items!')
        DebugPrint('You need to add this item to your rsg-core/shared/items.lua')
        TriggerClientEvent('db-nazar:client:treasureResult', src, false,
            'Item "' .. rewardItem .. '" is not registered in the server. Contact an admin.')
        return
    end

    -- Give item to player
    local success = Player.Functions.AddItem(rewardItem, 1)

    if not success then
        DebugPrint('ERROR: AddItem returned false for ' .. rewardItem .. ' - inventory may be full')
        TriggerClientEvent('db-nazar:client:treasureResult', src, false,
            'Could not add item to inventory. It may be full.')
        return
    end

    TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[rewardItem], 'add')

    -- Log transaction
    MySQL.Async.execute([[
        INSERT INTO db_nazar_transactions (citizenid, transaction_type, item, amount, price)
        VALUES (@cid, @type, @item, @amount, @price)
    ]], {
        ['@cid'] = Player.PlayerData.citizenid,
        ['@type'] = 'treasure_found',
        ['@item'] = rewardItem,
        ['@amount'] = 1,
        ['@price'] = 0,
    })

    DebugPrint('SUCCESS: Player ' .. src .. ' found treasure: ' .. rewardLabel)
    DebugPrint('==========================================')
    TriggerClientEvent('db-nazar:client:treasureResult', src, true, nil, rewardLabel)
end)

-- ============================================================================
-- DEBUG: Test map usage manually
-- ============================================================================

RSGCore.Commands.Add('testmap', 'Test treasure map usage', {{ name = 'mapname', help = 'Map item name (e.g. map_coins)' }}, true, function(source, args)
    local src = source
    local Player = RSGCore.Functions.GetPlayer(src)
    if not Player then return end

    local mapItem = args[1]

    if not mapItem then
        RSGCore.Functions.Notify(src, 'Usage: /testmap map_coins', 'error')
        return
    end

    if not Config.MapRewards or not Config.MapRewards[mapItem] then
        RSGCore.Functions.Notify(src, 'Invalid map: ' .. mapItem, 'error')
        return
    end

    if not Config.DigLocations or #Config.DigLocations == 0 then
        RSGCore.Functions.Notify(src, 'No dig locations configured.', 'error')
        return
    end

    -- Check if player has the map
    local hasMap = Player.Functions.GetItemByName(mapItem)
    if not hasMap then
        RSGCore.Functions.Notify(src, 'You do not have a ' .. mapItem .. ' in your inventory.', 'error')
        return
    end

    local mapData = Config.MapRewards[mapItem]
    local rewardItem = mapData.possibleRewards[math.random(#mapData.possibleRewards)]
    local digCoords = Config.DigLocations[math.random(#Config.DigLocations)]

    -- REMOVE THE MAP FROM INVENTORY
    Player.Functions.RemoveItem(mapItem, 1)
    if RSGCore.Shared.Items[mapItem] then
        TriggerClientEvent('inventory:client:ItemBox', src, RSGCore.Shared.Items[mapItem], 'remove')
    end

    TriggerClientEvent('db-nazar:client:activateMap', src, mapItem, {
        x = digCoords.x,
        y = digCoords.y,
        z = digCoords.z,
    }, rewardItem)

    RSGCore.Functions.Notify(src, 'Test map activated: ' .. mapItem, 'success')
    DebugPrint('TEST: Player ' .. src .. ' test activated ' .. mapItem .. ' (map removed)')
end)
