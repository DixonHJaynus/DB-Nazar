local RSGCore = exports['rsg-core']:GetCoreObject()

-- ============================================================================
-- NOTIFY
-- ============================================================================

local function Notify(message, notifyType, duration)
    local prefix = 'Madam Nazar'
    if notifyType == 'error' then
        prefix = 'Madam Nazar'
    elseif notifyType == 'success' then
        prefix = 'Madam Nazar'
    elseif notifyType == 'info' then
        prefix = 'Madam Nazar'
    end

    local finalMessage = string.format('%s: %s', prefix, message)

    pcall(function()
        exports['bln_notify']:tip(finalMessage, duration or 5000, 'bottom-right')
    end)
end

-- ============================================================================
-- STATE
-- ============================================================================

DBNazar = DBNazar or {
    ped = nil,
    blip = nil,
    locationIndex = nil,
    isShopOpen = false,
    lastFortuneCooldown = 0,
    spawnedProps = {},
}

-- ============================================================================
-- LOCATION FLAVOR
-- ============================================================================

local LocationGreetings = {
    ['Benedict Point'] = 'The desert keeps its secrets well, but not from me.',
    ["Hennigan's Stead"] = 'The dust out here carries omens, stranger.',
    ['Tall Trees'] = 'These woods are old... and full of whispers.',
    ['Heartlands'] = 'The open plains reveal much to those who know how to look.',
    ['Roanoke Ridge'] = 'The hills here are uneasy. Even the spirits tread lightly.',
    ['Bayou Nwa'] = 'The swamp remembers every footstep, every sin.',
    ['Big Valley'] = 'A beautiful land... though beauty often hides danger.',
    ['Scarlett Meadows'] = 'The earth here is rich with memory and blood.',
    ['Lemoyne - Rhodes Area'] = 'Old families leave behind old curses.',
    ['Great Plains'] = 'The wind is clearer here. The spirits speak plainly.',
    ['Cumberland Forest'] = 'The trees watch more than they let on.',
    ['Grizzlies East'] = 'Cold country. Hard country. Honest country.',
}

local LocationRelocationMessages = {
    ['Benedict Point'] = 'Madam Nazar has moved her caravan near Benedict Point.',
    ["Hennigan's Stead"] = 'Madam Nazar now camps somewhere in Hennigan\'s Stead.',
    ['Tall Trees'] = 'Madam Nazar has vanished into the Tall Trees.',
    ['Heartlands'] = 'Madam Nazar has set her camp in the Heartlands.',
    ['Roanoke Ridge'] = 'Madam Nazar now lingers in Roanoke Ridge.',
    ['Bayou Nwa'] = 'Madam Nazar has moved into the mist of Bayou Nwa.',
    ['Big Valley'] = 'Madam Nazar has pitched her camp in Big Valley.',
    ['Scarlett Meadows'] = 'Madam Nazar has been seen in Scarlett Meadows.',
    ['Lemoyne - Rhodes Area'] = 'Madam Nazar has settled near Rhodes.',
    ['Great Plains'] = 'Madam Nazar has moved across the Great Plains.',
    ['Cumberland Forest'] = 'Madam Nazar now roams Cumberland Forest.',
    ['Grizzlies East'] = 'Madam Nazar has braved the cold of Grizzlies East.',
}

-- ============================================================================
-- UTILITY
-- ============================================================================

local function DebugPrint(msg)
    if Config.Debug then
        print('[DB-Nazar:Client] ' .. tostring(msg))
    end
end

local function LoadModel(model)
    local hash = type(model) == 'string' and joaat(model) or model
    if not IsModelInCdimage(hash) then
        DebugPrint('Model not in cdimage: ' .. tostring(model))
        return false, nil
    end

    RequestModel(hash)

    local timeout = 0
    while not HasModelLoaded(hash) do
        Wait(100)
        timeout = timeout + 100
        if timeout > 10000 then
            DebugPrint('Timeout loading model: ' .. tostring(model))
            return false, nil
        end
    end

    return true, hash
end

local function GetRandomDialogue(category)
    local lines = Config.Dialogue[category]
    if not lines or #lines == 0 then
        return ''
    end
    return lines[math.random(#lines)]
end

local function GetCurrentLocation()
    if not DBNazar.locationIndex then return nil end
    return Config.Locations[DBNazar.locationIndex]
end

local function GetLocationGreeting()
    local location = GetCurrentLocation()
    if not location then
        return GetRandomDialogue('greeting')
    end
    return LocationGreetings[location.label] or GetRandomDialogue('greeting')
end

local function GetRelocationMessage(locationLabel)
    return LocationRelocationMessages[locationLabel] or ('Madam Nazar has moved her camp to ' .. tostring(locationLabel) .. '.')
end

local function FaceEntity(playerPed, targetPed)
    local playerCoords = GetEntityCoords(playerPed)
    local targetCoords = GetEntityCoords(targetPed)
    local heading = GetHeadingFromVector_2d(targetCoords.x - playerCoords.x, targetCoords.y - playerCoords.y)
    SetEntityHeading(playerPed, heading)
end

local function RemoveNazarTarget()
    if DBNazar.ped and DoesEntityExist(DBNazar.ped) then
        pcall(function()
            exports.ox_target:removeLocalEntity(DBNazar.ped, { 'db_nazar_talk' })
        end)
    end
end

local function PlayNazarIdle()
    if not DBNazar.ped or not DoesEntityExist(DBNazar.ped) then return end

    local animDict = 'amb_misc@world_human_stand_impatient@female@idle_a'
    local animName = 'idle_a'

    RequestAnimDict(animDict)

    local timeout = 0
    while not HasAnimDictLoaded(animDict) do
        Wait(100)
        timeout = timeout + 100
        if timeout > 5000 then
            DebugPrint('Failed to load Nazar idle anim: ' .. animDict)
            return
        end
    end

    TaskPlayAnim(DBNazar.ped, animDict, animName, 1.0, 1.0, -1, 1, 0.0, false, false, false)
end

-- ============================================================================
-- BLIP
-- ============================================================================

local function CreateNazarBlip(coords)
    if DBNazar.blip and DoesBlipExist(DBNazar.blip) then
        RemoveBlip(DBNazar.blip)
        DBNazar.blip = nil
    end

    if not Config.Blip.enabled then return end

    DBNazar.blip = Citizen.InvokeNative(
        0x554D9D53F696D002,
        1664425300,
        coords.x + 0.0,
        coords.y + 0.0,
        coords.z + 0.0
    )

    if not DBNazar.blip or DBNazar.blip == 0 then
        DebugPrint('Failed to create Nazar blip')
        return
    end

    SetBlipSprite(DBNazar.blip, Config.Blip.sprite, true)
    SetBlipScale(DBNazar.blip, Config.Blip.scale + 0.0)

    Citizen.InvokeNative(
        0x9CB1A1623062F402,
        DBNazar.blip,
        CreateVarString(10, 'LITERAL_STRING', Config.Blip.name)
    )

    DebugPrint('Nazar blip created. Handle: ' .. tostring(DBNazar.blip))
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

local function CleanupNazar()
    RemoveNazarTarget()

    if DBNazar.ped and DoesEntityExist(DBNazar.ped) then
        DeleteEntity(DBNazar.ped)
        DBNazar.ped = nil
    end

    for _, prop in pairs(DBNazar.spawnedProps) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    DBNazar.spawnedProps = {}

    if DBNazar.blip and DoesBlipExist(DBNazar.blip) then
        RemoveBlip(DBNazar.blip)
        DBNazar.blip = nil
    end
end

local function DespawnNazarPed()
    RemoveNazarTarget()

    if DBNazar.ped and DoesEntityExist(DBNazar.ped) then
        DeleteEntity(DBNazar.ped)
        DBNazar.ped = nil
    end

    for _, prop in pairs(DBNazar.spawnedProps) do
        if DoesEntityExist(prop) then
            DeleteEntity(prop)
        end
    end
    DBNazar.spawnedProps = {}
end

-- ============================================================================
-- SPAWN
-- ============================================================================

local function SpawnNazar(locationIndex)
    if not locationIndex or not Config.Locations[locationIndex] then
        DebugPrint('Invalid locationIndex: ' .. tostring(locationIndex))
        return
    end

    if DBNazar.locationIndex == locationIndex and DBNazar.ped and DoesEntityExist(DBNazar.ped) then
        DebugPrint('Nazar already spawned at this location, skipping.')
        return
    end

    CleanupNazar()

    DBNazar.locationIndex = locationIndex
    local location = Config.Locations[locationIndex]
    local coords = location.coords
    local x, y, z, heading = coords.x, coords.y, coords.z, coords.w

    DebugPrint('Spawning Nazar at: ' .. location.label)

    local loaded, modelHash = LoadModel(Config.NazarModel)
    if not loaded then
        DebugPrint('Failed to load NPC model: ' .. tostring(Config.NazarModel))
        return
    end

    DBNazar.ped = CreatePed(modelHash, x, y, z, heading, false, false, false, false)

    if not DBNazar.ped or not DoesEntityExist(DBNazar.ped) then
        DebugPrint('Failed to create ped')
        SetModelAsNoLongerNeeded(modelHash)
        return
    end

    Citizen.InvokeNative(0x283978A15512B2FE, DBNazar.ped, true)
    SetEntityInvincible(DBNazar.ped, true)
    SetBlockingOfNonTemporaryEvents(DBNazar.ped, true)
    FreezeEntityPosition(DBNazar.ped, true)
    SetEntityAsMissionEntity(DBNazar.ped, true, true)
    SetModelAsNoLongerNeeded(modelHash)

    PlayNazarIdle()

    if location.props and #location.props > 0 then
        for _, propData in pairs(location.props) do
            local propLoaded, propHash = LoadModel(propData.model)
            if propLoaded then
                local px = x + propData.offset.x
                local py = y + propData.offset.y
                local pz = z + propData.offset.z

                local prop = CreateObject(propHash, px, py, pz, false, false, false)
                if prop and DoesEntityExist(prop) then
                    SetEntityHeading(prop, heading + (propData.heading or 0.0))
                    FreezeEntityPosition(prop, true)
                    PlaceObjectOnGroundProperly(prop)
                    table.insert(DBNazar.spawnedProps, prop)
                end

                SetModelAsNoLongerNeeded(propHash)
            end
        end

        DebugPrint('Spawned ' .. #location.props .. ' props at ' .. location.label)
    end

    CreateNazarBlip(vector3(x, y, z))

    exports.ox_target:addLocalEntity(DBNazar.ped, {
        {
            name = 'db_nazar_talk',
            icon = 'fas fa-crystal-ball',
            label = 'Speak with Madam Nazar',
            distance = 2.5,
            onSelect = function()
                InteractWithNazar()
            end,
        },
    })

    DebugPrint('Nazar fully spawned at ' .. location.label)
end

-- ============================================================================
-- INTERACTION
-- ============================================================================

function InteractWithNazar()
    if not DBNazar.ped or not DoesEntityExist(DBNazar.ped) then return end

    local playerPed = PlayerPedId()
    FaceEntity(playerPed, DBNazar.ped)

    Wait(500)
    OpenShop()
end

-- ============================================================================
-- SHOP UI
-- ============================================================================

function OpenShop()
    if DBNazar.isShopOpen then return end
    DBNazar.isShopOpen = true

    local playerCollectibles = {}

    for _, item in pairs(Config.Collectibles.individual) do
        if RSGCore.Functions.HasItem(item.item) then
            playerCollectibles[item.item] = 1
        end
    end

    for _, collection in pairs(Config.Collectibles.collections) do
        for _, item in pairs(collection.items) do
            if RSGCore.Functions.HasItem(item.item) then
                playerCollectibles[item.item] = 1
            end
        end
    end

    local hasCollectorBag = RSGCore.Functions.HasItem(Config.CollectorBag.item)

    SendNUIMessage({
        action = 'openShop',
        data = {
            nuiSettings = Config.NUI,
            categories = Config.ShopCategories,
            collectorBag = Config.CollectorBag,
            collectibles = Config.Collectibles,
            playerCollectibles = playerCollectibles,
            hasCollectorBag = hasCollectorBag,
            fortuneTelling = Config.FortuneTelling,
            greeting = GetLocationGreeting(),
        },
    })

    SetNuiFocus(true, true)
end

local function CloseShop()
    if not DBNazar.isShopOpen then return end

    DBNazar.isShopOpen = false
    SendNUIMessage({ action = 'closeShop' })
    SetNuiFocus(false, false)
end

-- ============================================================================
-- NUI CALLBACKS
-- ============================================================================

RegisterNUICallback('closeUI', function(_, cb)
    CloseShop()
    cb('ok')
end)

RegisterNUICallback('purchaseItem', function(data, cb)
    TriggerServerEvent('db-nazar:server:purchaseItem', data.item, data.price, data.requiredItem)
    cb('ok')
end)

RegisterNUICallback('purchaseCollectorBag', function(_, cb)
    TriggerServerEvent('db-nazar:server:purchaseCollectorBag')
    cb('ok')
end)

RegisterNUICallback('sellItem', function(data, cb)
    TriggerServerEvent('db-nazar:server:sellItem', data.item, data.sellPrice)
    cb('ok')
end)

RegisterNUICallback('sellCollection', function(data, cb)
    TriggerServerEvent('db-nazar:server:sellCollection', data.collectionId, data.items, data.totalPrice)
    cb('ok')
end)

RegisterNUICallback('requestFortune', function(_, cb)
    local currentTime = GetGameTimer()
    local cooldownMs = Config.FortuneTelling.cooldown * 60 * 1000

    if currentTime - DBNazar.lastFortuneCooldown < cooldownMs then
        local remaining = math.ceil((cooldownMs - (currentTime - DBNazar.lastFortuneCooldown)) / 60000)
        Notify('The spirits need time to recover. Try again in ' .. remaining .. ' minute(s).', 'error', Config.Notifications.duration)
        cb('cooldown')
        return
    end

    TriggerServerEvent('db-nazar:server:requestFortune')
    cb('ok')
end)

-- ============================================================================
-- SERVER EVENTS
-- ============================================================================

RegisterNetEvent('db-nazar:client:updateLocation', function(locationIndex)
    DebugPrint('Location update received: ' .. tostring(locationIndex))
    SpawnNazar(locationIndex)
end)

RegisterNetEvent('db-nazar:client:notifyRelocation', function(locationLabel)
    Notify(GetRelocationMessage(locationLabel), 'info', Config.Notifications.duration)
end)

RegisterNetEvent('db-nazar:client:purchaseResult', function(success, message, itemLabel)
    if success then
        Notify('A wise purchase. ' .. (itemLabel or 'Your item') .. ' is now yours.', 'success', Config.Notifications.duration)
        if DBNazar.isShopOpen then
            CloseShop()
            Wait(300)
            OpenShop()
        end
    else
        Notify(message or GetRandomDialogue('noMoney'), 'error', Config.Notifications.duration)
    end
end)

RegisterNetEvent('db-nazar:client:sellResult', function(success, message, amount)
    if success then
        Notify('Sold successfully for $' .. string.format('%.2f', amount or 0) .. '.', 'success', Config.Notifications.duration)
        if DBNazar.isShopOpen then
            CloseShop()
            Wait(300)
            OpenShop()
        end
    else
        Notify(message or 'Unable to sell that item.', 'error', Config.Notifications.duration)
    end
end)

RegisterNetEvent('db-nazar:client:sellCollectionResult', function(success, message, amount)
    if success then
        Notify('A complete collection! You received $' .. string.format('%.2f', amount or 0) .. '.', 'success', Config.Notifications.duration)
        if DBNazar.isShopOpen then
            CloseShop()
            Wait(300)
            OpenShop()
        end
    else
        Notify(message or "You don't have all the items for this collection.", 'error', Config.Notifications.duration)
    end
end)

RegisterNetEvent('db-nazar:client:fortuneResult', function(success, fortune)
    if success and fortune then
        DBNazar.lastFortuneCooldown = GetGameTimer()

        Notify('"' .. tostring(fortune.text) .. '"', 'primary', 10000)

        if fortune.reward then
            Wait(1500)
            if fortune.reward.type == 'money' then
                Notify('The spirits granted you $' .. string.format('%.2f', fortune.reward.amount), 'success', Config.Notifications.duration)
            elseif fortune.reward.type == 'item' then
                Notify('The spirits granted you a mysterious gift.', 'success', Config.Notifications.duration)
            end
        end

        if DBNazar.isShopOpen then
            SendNUIMessage({
                action = 'showFortune',
                data = {
                    text = fortune.text,
                    type = fortune.type,
                },
            })
        end
    else
        Notify(type(fortune) == 'string' and fortune or 'The spirits are silent...', 'error', Config.Notifications.duration)
    end
end)

RegisterNetEvent('db-nazar:client:teleportToNazar', function(coords)
    SetEntityCoords(PlayerPedId(), coords.x, coords.y, coords.z, false, false, false, false)
    Notify('You have been guided to Madam Nazar.', 'success', Config.Notifications.duration)
end)

-- ============================================================================
-- THREADS
-- ============================================================================

CreateThread(function()
    while true do
        Wait(5000)

        if DBNazar.locationIndex then
            local location = Config.Locations[DBNazar.locationIndex]
            if location then
                local playerCoords = GetEntityCoords(PlayerPedId())
                local nazarCoords = vector3(location.coords.x, location.coords.y, location.coords.z)
                local dist = #(playerCoords - nazarCoords)

                if dist > 200.0 then
                    if DBNazar.ped and DoesEntityExist(DBNazar.ped) then
                        DebugPrint('Player too far, despawning ped')
                        DespawnNazarPed()
                    end
                else
                    if not DBNazar.ped or not DoesEntityExist(DBNazar.ped) then
                        DebugPrint('Player nearby, respawning ped')
                        SpawnNazar(DBNazar.locationIndex)
                    end
                end
            end
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        if DBNazar.isShopOpen and IsControlJustPressed(0, 0x156F7119) then
            CloseShop()
        end
    end
end)

-- ============================================================================
-- CLEANUP
-- ============================================================================

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        CleanupNazar()
        if DBNazar.isShopOpen then
            CloseShop()
        end
    end
end)
