local RSGCore = exports['rsg-core']:GetCoreObject()

-- ============================================================================
-- NOTIFY
-- ============================================================================

local function Notify(message, notifyType, duration)
    local prefix = 'Treasure Hunt'
    if notifyType == 'success' then
        prefix = 'Treasure Found'
    elseif notifyType == 'error' then
        prefix = 'Treasure Hunt'
    elseif notifyType == 'info' then
        prefix = 'Treasure Hunt'
    end

    local finalMessage = string.format('%s: %s', prefix, message)

    pcall(function()
        exports['bln_notify']:tip(finalMessage, duration or 5000, 'bottom-right')
    end)
end

-- ============================================================================
-- STATE
-- ============================================================================

local activeTreasure = {
    active = false,
    mapItem = nil,
    digCoords = nil,
    blip = nil,
    rewardItem = nil,
    targetZone = nil,
    isDigging = false,
}

-- ============================================================================
-- CUSTOM MESSAGES
-- ============================================================================

local MapMessages = {
    ['map_coins'] = {
        start = 'You study the coin map carefully. Somewhere nearby, old money waits beneath the earth.',
        marked = 'A promising search area has been marked on your map.',
    },
    ['map_arrowheads'] = {
        start = 'The arrowhead map points toward ancient ground.',
        marked = 'An old hunting site has been marked on your map.',
    },
    ['map_jewelry'] = {
        start = 'The jewelry map reveals a place where something precious was lost.',
        marked = 'A search area has been marked on your map.',
    },
    ['map_bottles'] = {
        start = 'The bottle map leads toward a forgotten stash.',
        marked = 'A search area has been marked on your map.',
    },
    ['map_fossils'] = {
        start = 'The fossil map points toward old bones buried deep.',
        marked = 'A dig area has been marked on your map.',
    },
    ['map_heirlooms'] = {
        start = 'The heirloom map hints at a family treasure left behind.',
        marked = 'A search area has been marked on your map.',
    },
}

local function GetMapStartMessage(mapItem)
    return (MapMessages[mapItem] and MapMessages[mapItem].start) or (Config.TreasureHunting.mapUsedMessage or 'You study the map carefully...')
end

local function GetMapMarkedMessage(mapItem)
    return (MapMessages[mapItem] and MapMessages[mapItem].marked) or 'A location has been marked on your map.'
end

-- ============================================================================
-- UTILITY
-- ============================================================================

local function DebugPrint(msg)
    if Config.Debug then
        print('[DB-Nazar:Treasure] ' .. tostring(msg))
    end
end

local function GetGroundZ(x, y, z)
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 100.0, false)
    if found then
        return groundZ
    end
    return z
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

local function CleanupTreasure()
    if activeTreasure.blip and DoesBlipExist(activeTreasure.blip) then
        RemoveBlip(activeTreasure.blip)
        activeTreasure.blip = nil
    end

    if activeTreasure.targetZone then
        pcall(function()
            exports.ox_target:removeZone(activeTreasure.targetZone)
        end)
        activeTreasure.targetZone = nil
    end

    activeTreasure.active = false
    activeTreasure.mapItem = nil
    activeTreasure.digCoords = nil
    activeTreasure.rewardItem = nil
    activeTreasure.isDigging = false
end

-- ============================================================================
-- BLIP
-- ============================================================================

local function CreateTreasureBlip(coords)
    if activeTreasure.blip and DoesBlipExist(activeTreasure.blip) then
        RemoveBlip(activeTreasure.blip)
        activeTreasure.blip = nil
    end

    local sprite = (Config.Blip and Config.Blip.sprite) or -1749618580
    local scale = 0.35
    local name = (Config.TreasureHunting and Config.TreasureHunting.blip and Config.TreasureHunting.blip.name) or 'Treasure Location'

    activeTreasure.blip = Citizen.InvokeNative(
        0x554D9D53F696D002,
        1664425300,
        coords.x + 0.0,
        coords.y + 0.0,
        coords.z + 0.0
    )

    if not activeTreasure.blip or activeTreasure.blip == 0 then
        DebugPrint('Failed to create treasure blip')
        return
    end

    SetBlipSprite(activeTreasure.blip, sprite, true)
    SetBlipScale(activeTreasure.blip, scale)

    Citizen.InvokeNative(
        0x9CB1A1623062F402,
        activeTreasure.blip,
        CreateVarString(10, 'LITERAL_STRING', name)
    )

    DebugPrint('Treasure blip created. Handle: ' .. tostring(activeTreasure.blip))
end

-- ============================================================================
-- TARGET ZONE
-- ============================================================================

local function CreateDigZone()
    if activeTreasure.targetZone then
        pcall(function()
            exports.ox_target:removeZone(activeTreasure.targetZone)
        end)
        activeTreasure.targetZone = nil
    end

    activeTreasure.targetZone = exports.ox_target:addSphereZone({
        coords = activeTreasure.digCoords,
        radius = Config.TreasureHunting.digRadius,
        debug = Config.Debug,
        options = {
            {
                name = 'db_nazar_dig',
                icon = 'fas fa-shovel',
                label = 'Dig for Treasure',
                distance = Config.TreasureHunting.digRadius + 1.0,
                onSelect = function()
                    DigForTreasure()
                end,
            },
        },
    })

    DebugPrint(('Dig zone created at %.2f, %.2f, %.2f'):format(
        activeTreasure.digCoords.x,
        activeTreasure.digCoords.y,
        activeTreasure.digCoords.z
    ))
end

-- ============================================================================
-- DIG
-- ============================================================================

function DigForTreasure()
    DebugPrint('DigForTreasure() called')

    if not activeTreasure.active then
        DebugPrint('Not active - aborting')
        return
    end

    if activeTreasure.isDigging then
        DebugPrint('Already digging - aborting')
        return
    end

    if not activeTreasure.digCoords then
        DebugPrint('No dig coords - aborting')
        return
    end

    local playerPed = PlayerPedId()
    local playerCoords = GetEntityCoords(playerPed)
    local dist = #(playerCoords - activeTreasure.digCoords)

    DebugPrint('Distance to dig: ' .. dist)

    if dist > Config.TreasureHunting.digRadius + 1.0 then
        Notify('You need to be closer to the dig spot.', 'error', 3000)
        return
    end

    if Config.TreasureHunting.requireShovel and not RSGCore.Functions.HasItem(Config.TreasureHunting.shovelItem) then
        Notify('You need a shovel to dig here.', 'error', 3000)
        return
    end

    activeTreasure.isDigging = true
    DebugPrint('isDigging set to true')

    local heading = GetHeadingFromVector_2d(
        activeTreasure.digCoords.x - playerCoords.x,
        activeTreasure.digCoords.y - playerCoords.y
    )
    SetEntityHeading(playerPed, heading)

    local digConfig = (Config.TreasureHunting and Config.TreasureHunting.dig) or {}
    local shovelModel = digConfig.shovel or 'p_shovel02x'
    local animDict = (digConfig.anim and digConfig.anim[1]) or 'amb_work@world_human_gravedig@working@male_b@idle_a'
    local animName = (digConfig.anim and digConfig.anim[2]) or 'idle_a'
    local shovelBone = digConfig.bone or 'skel_r_hand'
    local shovelPos = digConfig.pos or { 0.06, -0.06, -0.03, 270.0, 165.0, 150.0 }

    local shovelObject = nil

    RequestModel(shovelModel)
    local modelTimeout = 0
    while not HasModelLoaded(shovelModel) and modelTimeout < 5000 do
        Wait(100)
        modelTimeout = modelTimeout + 100
    end

    if HasModelLoaded(shovelModel) then
        local pc = GetEntityCoords(playerPed)
        shovelObject = CreateObject(shovelModel, pc.x, pc.y, pc.z, true, true, true)

        local boneIndex = GetEntityBoneIndexByName(playerPed, shovelBone)
        AttachEntityToEntity(
            shovelObject,
            playerPed,
            boneIndex,
            shovelPos[1], shovelPos[2], shovelPos[3],
            shovelPos[4], shovelPos[5], shovelPos[6],
            false, false, false, false, 2, true
        )

        DebugPrint('Shovel attached successfully')
    else
        DebugPrint('Shovel model failed to load')
    end

    RequestAnimDict(animDict)
    local animTimeout = 0
    while not HasAnimDictLoaded(animDict) and animTimeout < 5000 do
        Wait(100)
        animTimeout = animTimeout + 100
    end

    if HasAnimDictLoaded(animDict) then
        TaskPlayAnim(playerPed, animDict, animName, 1.0, 1.0, -1, 1, 0, false, false, false)
        DebugPrint('Animation playing: ' .. animDict)
    else
        DebugPrint('Animation failed to load: ' .. animDict)
    end

    RSGCore.Functions.Progressbar('nazar_digging', 'Digging for treasure...', Config.TreasureHunting.digDuration, false, true, {
        disableMovement = true,
        disableCarMovement = true,
        disableMouse = false,
        disableCombat = true,
    }, {}, {}, {}, function()
        DebugPrint('Progress bar complete')

        ClearPedTasks(playerPed)

        if shovelObject and DoesEntityExist(shovelObject) then
            DeleteObject(shovelObject)
            SetEntityAsNoLongerNeeded(shovelObject)
            shovelObject = nil
        end

        RemoveAnimDict(animDict)
        SetModelAsNoLongerNeeded(shovelModel)

        DebugPrint('Sending claim to server: ' .. tostring(activeTreasure.mapItem) .. ' / ' .. tostring(activeTreasure.rewardItem))
        TriggerServerEvent('db-nazar:server:claimTreasure', activeTreasure.mapItem, activeTreasure.rewardItem)

        CleanupTreasure()
        DebugPrint('DigForTreasure() complete - SUCCESS')
    end, function()
        DebugPrint('Progress bar cancelled')

        ClearPedTasks(playerPed)

        if shovelObject and DoesEntityExist(shovelObject) then
            DeleteObject(shovelObject)
            SetEntityAsNoLongerNeeded(shovelObject)
            shovelObject = nil
        end

        RemoveAnimDict(animDict)
        SetModelAsNoLongerNeeded(shovelModel)

        activeTreasure.isDigging = false
        Notify('Digging cancelled.', 'error', 3000)
    end)
end

-- ============================================================================
-- EVENTS
-- ============================================================================

RegisterNetEvent('db-nazar:client:activateMap', function(mapItem, digCoords, rewardItem)
    if activeTreasure.active then
        Notify('You already have an active treasure hunt. Finish that one first.', 'error', 5000)
        return
    end

    local groundZ = GetGroundZ(digCoords.x, digCoords.y, digCoords.z)

    DebugPrint('Map activated: ' .. tostring(mapItem))
    DebugPrint(('Coords: %.2f, %.2f, %.2f'):format(digCoords.x, digCoords.y, groundZ))
    DebugPrint('Reward: ' .. tostring(rewardItem))

    activeTreasure.active = true
    activeTreasure.mapItem = mapItem
    activeTreasure.digCoords = vector3(digCoords.x, digCoords.y, groundZ)
    activeTreasure.rewardItem = rewardItem

    CreateTreasureBlip(activeTreasure.digCoords)
    CreateDigZone()

    Notify(GetMapStartMessage(mapItem), 'primary', 5000)
    Wait(1500)
    Notify(GetMapMarkedMessage(mapItem), 'info', 5000)
end)

RegisterNetEvent('db-nazar:client:treasureResult', function(success, message, itemLabel)
    DebugPrint('treasureResult received - success: ' .. tostring(success) .. ', label: ' .. tostring(itemLabel))

    if success then
        Notify('You unearthed: ' .. tostring(itemLabel or 'a treasure') .. '!', 'success', 7000)
    else
        Notify(message or 'Something went wrong.', 'error', 5000)
    end
end)

-- ============================================================================
-- MARKER THREAD
-- ============================================================================

CreateThread(function()
    while true do
        local sleep = 1000

        if activeTreasure.active and activeTreasure.digCoords then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - activeTreasure.digCoords)

            if dist <= 50.0 then
                sleep = 0

                Citizen.InvokeNative(
                    0x2A32FAA57B937173,
                    0x94FDAE17,
                    activeTreasure.digCoords.x,
                    activeTreasure.digCoords.y,
                    activeTreasure.digCoords.z - 0.95,
                    0.0, 0.0, 0.0,
                    0.0, 0.0, 0.0,
                    2.0, 2.0, 1.5,
                    255, 215, 0, 150,
                    false, false, 2,
                    false, nil, nil, false
                )
            else
                sleep = 2000
            end
        else
            sleep = 3000
        end

        Wait(sleep)
    end
end)

-- ============================================================================
-- E TO DIG BACKUP
-- ============================================================================

CreateThread(function()
    while true do
        local sleep = 1000

        if activeTreasure.active and activeTreasure.digCoords and not activeTreasure.isDigging then
            local playerCoords = GetEntityCoords(PlayerPedId())
            local dist = #(playerCoords - activeTreasure.digCoords)

            if dist <= Config.TreasureHunting.digRadius then
                sleep = 0

                if IsControlJustPressed(0, 0x760A9C6F) then
                    DigForTreasure()
                end
            end
        end

        Wait(sleep)
    end
end)

-- ============================================================================
-- CLEANUP
-- ============================================================================

AddEventHandler('onResourceStop', function(resource)
    if resource == GetCurrentResourceName() then
        CleanupTreasure()
    end
end)

RegisterCommand('cleartreasure', function()
    if activeTreasure.active then
        CleanupTreasure()
        Notify('Your active treasure hunt has been cleared.', 'success', 3000)
    else
        Notify('There is no active treasure hunt to clear.', 'error', 3000)
    end
end, false)
