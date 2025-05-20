local QBCore = exports['qb-core']:GetCoreObject()
local cam = nil
local charPed = nil
local loadScreenCheckState = false
local cached_player_skins = {}
local created_peds = {}
local RoomPeds = {}
local randommodels = { -- models possible to load when choosing empty slot
    'mp_m_freemode_01',
    'mp_f_freemode_01',
}

-- Main Thread
CreateThread(function()
    while true do
        Wait(0)
        if NetworkIsSessionStarted() then
            TriggerEvent('qb-multicharacter:client:chooseChar')
            return
        end
    end
end)

-- Functions
local function loadModel(model)
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end
end

local function initializePedModel(model, data)
end

local selecting_character = false;
local moveCamera = false;
local currentMovingCamera = 1;
local cameras_position = {
    [1] = vector4(943.45104, 8.0688285, 117.31713, 190.22268),
    [2] = vector4(943.57958, 3.6147379, 116.18592, 186.83711),
    [3] = vector4(949.56951, 3.9425144, 116.27214, 144.31637),
    [4] = vector4(946.62664, 5.5596098, 116.27214, 162.89831),
    [5] = vector4(943.45104, 8.0688285, 117.31713, 190.22268),
}

local previousCam = nil
local function skyCam(bool)
    -- TriggerEvent('qb-weathersync:client:DisableSync')
    if bool then
        DoScreenFadeIn(1000)
        SetTimecycleModifier('hud_def_blur')
        SetTimecycleModifierStrength(1.0)
        FreezeEntityPosition(PlayerPedId(), false)
        -- cam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", Config.CamCoords.x, Config.CamCoords.y, Config.CamCoords.z, 0.0 ,0.0, Config.CamCoords.w, 60.00, false, 0)
        -- SetCamActive(cam, true)
        -- RenderScriptCams(true, false, 1, true, true)
        selecting_character = true;
        moveCamera = true;

        CreateThread(function()
            while selecting_character do
                if (moveCamera) then
                    if (previousCam == nil) then
                        previousCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA",
                            cameras_position[currentMovingCamera].x, cameras_position[currentMovingCamera].y,
                            cameras_position[currentMovingCamera].z, 0.0, 0.0, cameras_position[currentMovingCamera].w,
                            60.00, false, 0)
                    end
                    if (currentMovingCamera + 1 > #cameras_position) then
                        currentMovingCamera = 1
                    else
                        currentMovingCamera = currentMovingCamera + 1
                    end
                    local myNextCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA",
                        cameras_position[currentMovingCamera].x, cameras_position[currentMovingCamera].y,
                        cameras_position[currentMovingCamera].z, 0.0, 0.0, cameras_position[currentMovingCamera].w, 60.00,
                        false, 0)
                    local oldCam = previousCam;

                    SetCamActiveWithInterp(myNextCam, previousCam, 30000, 0, 0)
                    previousCam = myNextCam


                    RenderScriptCams(true, false, 1, true, true)

                    Wait(30010)
                    DestroyCam(oldCam);
                end
                Wait(50)
            end
        end)
    else
        SetTimecycleModifier('default')
        selecting_character = false;
        moveCamera = false;
        SetCamActive(previousCam, false)
        DestroyCam(previousCam, true)
        DestroyAllCams(true);
        RenderScriptCams(false, false, 1, true, true)
        FreezeEntityPosition(PlayerPedId(), false)

        selecting_character = false;
        moveCamera = false;
        currentMovingCamera = 1;

        for k, v in pairs(RoomPeds) do
            DeleteEntity(v)
        end
        RoomPeds = {}
        created_peds = {}
    end
end

local function openCharMenu(bool)
    QBCore.Functions.TriggerCallback("qb-multicharacter:server:GetNumberOfCharacters", function(result)
        local translations = {}
        for k in pairs(Lang.fallback and Lang.fallback.phrases or Lang.phrases) do
            if k:sub(0, ('ui.'):len()) then
                translations[k:sub(('ui.'):len() + 1)] = Lang:t(k)
            end
        end
        SetNuiFocus(bool, bool)
        SendNUIMessage({
            action = "ui",
            toggle = bool,
            -- customNationality = Config.customNationality,
            -- toggle = bool,
            nChar = result,
            -- enableDeleteButton = Config.EnableDeleteButton,
            -- translations = translations
        })
        skyCam(bool)
        if not loadScreenCheckState then
            ShutdownLoadingScreenNui()
            loadScreenCheckState = true
        end
    end)
end

RegisterNetEvent('qb-multicharacter:client:closeNUIdefault', function() -- This event is only for no starting apartments
    DeleteEntity(charPed)
    for k, v in pairs(RoomPeds) do
        DeleteEntity(v)
    end
    SetNuiFocus(false, false)
    DoScreenFadeOut(500)
    Wait(2000)
    SetEntityCoordsNoOffset(PlayerPedId(), Config.DefaultSpawn.x, Config.DefaultSpawn.y, Config.DefaultSpawn.z)
    SetEntityHeading(PlayerPedId(), Config.DefaultSpawn.w)
    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')
    Wait(500)
    openCharMenu()
    SetEntityVisible(PlayerPedId(), true)
    Wait(500)
    DoScreenFadeIn(250)
    -- TriggerEvent('qb-weathersync:client:EnableSync')
    LocalPlayer.state.NewPlayer = true
    TriggerEvent('qb-clothes:client:CreateFirstCharacter')
    TriggerEvent('cd_easytime:PauseSync', false)

    RoomPeds = {}
    created_peds = {}
    selecting_character = false;
    moveCamera = false;
    currentMovingCamera = 1;
    SetCamActive(previousCam, false)
    DestroyCam(previousCam, true)
    DestroyAllCams(true);
    previousCam = nil
    RenderScriptCams(false, false, 1, true, true)
    --
end)


RegisterNetEvent("qb-clothes:cl:finish", function()
    local playerped = PlayerPedId()
    local playerCoords = GetEntityCoords(playerped)
    --local pos = vector3(Config.DefaultSpawn.x, Config.DefaultSpawn.y, Config.DefaultSpawn.z)
    --local distance = #(playerCoords - pos)
    if LocalPlayer.state.NewPlayer then
        SetEntityVisible(PlayerPedId(), false)
        FreezeEntityPosition(PlayerPedId(), false)

        SetEntityVisible(PlayerPedId(), true)
        SetNuiFocus(false, false)
    
        DoScreenFadeOut(1500)
        while IsScreenFadingOut() do Wait(10) end
    
        -- TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
        -- TriggerEvent('QBCore:Client:OnPlayerLoaded')

        TriggerServerEvent("qb-hotels:server:createApartment")
    
        -- while QBCore.Functions.GetPlayerData().metadata["apartment"]["bucket"] == 0 do
        --     Wait(10)
        -- end

        print('Player New Apartment Bucket', QBCore.Functions.GetPlayerData().metadata["apartment"]["bucket"])
        
        Wait(5000)
        TriggerEvent('animations:client:EmoteCommandStart', {"lean3"})
        DoScreenFadeIn(1500)
        while IsScreenFadingIn() do Wait(10) end

        LocalPlayer.state.NewPlayer = false
        TriggerServerEvent('qb-spawn:sv:AddUrlFace', exports.MugShotBase64:GetMugShotBase64(PlayerPedId(), false))

    end
end)



RegisterNetEvent('qb-multicharacter:client:closeNUI', function()
    DeleteEntity(charPed)
    for k, v in pairs(RoomPeds) do
        DeleteEntity(v)
    end
    SetNuiFocus(false, false)

    RoomPeds = {}
    created_peds = {}
end)

RegisterNetEvent('qb-multicharacter:client:chooseChar', function(logout)
    TriggerScreenblurFadeIn(300)
    SetNuiFocus(false, false)
    DoScreenFadeOut(10)
    Wait(1000)

    local interior = GetInteriorAtCoords(Config.Interior.x, Config.Interior.y, Config.Interior.z - 18.9)
    LoadInterior(interior)
    while not IsInteriorReady(interior) do
        Wait(1000)
    end

    FreezeEntityPosition(PlayerPedId(), true)
    SetEntityCoordsNoOffset(PlayerPedId(), Config.HiddenCoords.x, Config.HiddenCoords.y, Config.HiddenCoords.z)
    Wait(1500)
    --exports["qb-charesSounds"]:runVoice()
    ShutdownLoadingScreen()
    ShutdownLoadingScreenNui()
    if logout then
        selecting_character = true;
        moveCamera = true;
        SendNUIMessage({
            action = "logout",
        })
    end
    openCharMenu(true)
end)

RegisterNetEvent("qb-multicharacter:client:lastlocation", function(cData, custom)
    local ped = PlayerPedId()
    local PlayerData = QBCore.Functions.GetPlayerData()


    QBCore.Functions.GetPlayerData(function(PlayerData)
        SetEntityCoords(PlayerPedId(), PlayerData.position.x, PlayerData.position.y, PlayerData.position.z)
        SetEntityHeading(PlayerPedId(), PlayerData.position.h)
        FreezeEntityPosition(PlayerPedId(), false)
    end)

    TriggerServerEvent('QBCore:Server:OnPlayerLoaded')
    TriggerEvent('QBCore:Client:OnPlayerLoaded')

    openCharMenu(false)
    SetEntityVisible(ped, true)
    FreezeEntityPosition(PlayerPedId(), false)
    DeleteEntity(charPed)
    for k, v in pairs(RoomPeds) do
        DeleteEntity(v)
    end

    DoScreenFadeIn(1500)
    while IsScreenFadingIn() do Wait(10) end

    RoomPeds = {}
    created_peds = {}
    selecting_character = false;
    moveCamera = false;
    currentMovingCamera = 1;
    SetCamActive(previousCam, false)
    DestroyCam(previousCam, true)
    DestroyAllCams(true);
    previousCam = nil
    RenderScriptCams(false, false, 1, true, true)
    --
    TriggerServerEvent("qb-hotels:server:createApartment")

    QBCore.Functions.Notify("Welcome To ".. Config.ServerName .. "</br>Hope You Enjoy")


    SetTimeout(5000, function()
    --    TriggerServerEvent('qb-characters:sv:AddUrlFace', exports['MugShotBase64']:GetMugShotBase64(cache.ped, false))
        if custom then
            TriggerServerEvent('qb-characters:server:SetInsideMeta')
        end
    end)
end)

-- NUI Callbacks
RegisterNUICallback('Notify', function(data, cb)
    QBCore.Functions.Notify(data.text, "error")
end)

RegisterNUICallback('disconnectButton', function(_, cb)
    SetEntityAsMissionEntity(charPed, true, true)
    DeleteEntity(charPed)
    for k, v in pairs(RoomPeds) do
        DeleteEntity(v)
    end
    RoomPeds = {}
    TriggerServerEvent('qb-multicharacter:server:disconnect')
    cb("ok")
end)

RegisterNUICallback('selectCharacter', function(data, cb)
    DoScreenFadeOut(2)
    local cData = data.cData
    local custom = false

    -- DoScreenFadeOut(10)
    TriggerServerEvent('qb-multicharacter:server:loadUserData', cData, custom)
    openCharMenu(false)
    SetEntityAsMissionEntity(charPed, true, true)
    DeleteEntity(charPed)
    for k, v in pairs(RoomPeds) do
        DeleteEntity(v)
    end
    RoomPeds = {}
    cb("ok")
end)

RegisterNUICallback('cDataPed', function(nData, cb)
    local cData = nData.cData
    SetEntityAsMissionEntity(charPed, true, true)
    DeleteEntity(charPed)
    for k, v in pairs(RoomPeds) do
        DeleteEntity(v)
    end

    RoomPeds = {}
    selecting_character = false;
    moveCamera = false;
    currentMovingCamera = 1;
    SetCamActive(previousCam, false)
    DestroyCam(previousCam, true)
    DestroyAllCams(true);
    previousCam = nil
    RenderScriptCams(false, false, 1, true, true)
    --

    if cData ~= nil then
        if not cached_player_skins[cData.citizenid] then
            local temp_model = promise.new()
            local temp_data = promise.new()

            QBCore.Functions.TriggerCallback('qb-multicharacter:server:getSkin', function(model, data)
                temp_model:resolve(model)
                temp_data:resolve(data)
            end, cData.citizenid)

            local resolved_model = Citizen.Await(temp_model)
            local resolved_data = Citizen.Await(temp_data)

            cached_player_skins[cData.citizenid] = { model = resolved_model, data = resolved_data }
        end

        local model = cached_player_skins[cData.citizenid].model
        local data = cached_player_skins[cData.citizenid].data

        model = model ~= nil and tonumber(model) or false

        if model ~= nil then
            initializePedModel(model, json.decode(data))
        else
            initializePedModel()
        end
        cb("ok")
    else
        initializePedModel()
        cb("ok")
    end
end)


RegisterNUICallback('HoverCharacter', function(data, cb)
    if (selecting_character) then
        moveCamera = false;
        local pData = created_peds[tonumber(data.character)]

        if pData ~= nil then
            local position = GetEntityCoords(pData.ped) + GetEntityForwardVector(pData.ped) * 1.0
            local heading = GetEntityHeading(pData.ped) + 180.0
            local myNextCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", position.x, position.y, position.z, 0.0, 0.0,
                heading, 60.00, false, 0)
            local oldCam = previousCam;
            SetCamActiveWithInterp(myNextCam, previousCam, 1500, 0, 0)
            previousCam = myNextCam

            -- SetCamActive(myNextCam, true)
            RenderScriptCams(true, false, 0, true, true)

            SetEntityAlpha(pData.ped, 255)
            Wait(1500)
            DestroyCam(oldCam)
        end
    end
end)

RegisterNUICallback('NoHoverCharacter', function(data, cb)
    if (selecting_character) then
        local myNextCam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", cameras_position[currentMovingCamera].x,
            cameras_position[currentMovingCamera].y, cameras_position[currentMovingCamera].z, 0.0, 0.0,
            cameras_position[currentMovingCamera].w, 60.00, false, 0)
        local oldCam = previousCam;
        SetCamActiveWithInterp(myNextCam, previousCam, 30000, 0, 0)
        previousCam = myNextCam
        -- SetCamActive(myNextCam, true)
        RenderScriptCams(true, false, 0, true, true)
        moveCamera = true;
        Wait(30000)
        DestroyCam(oldCam);
    end
end)

local function SpawnCharacters(Players, models, skins)  
    RequestAnimDict("timetable@ron@ig_3_couch")
    while not HasAnimDictLoaded("timetable@ron@ig_3_couch") do
        Wait(50)
    end

    for i = 1, #Players, 1 do

        if Config.PedPos[i] then
            if not models[i] then
                models[i] = joaat(randommodels[math.random(#randommodels)])
            end

            loadModel(models[i])
            RoomPeds[i] = CreatePed(2, models[i], Config.PedPos[i].x, Config.PedPos[i].y, Config.PedPos[i].z - 1.0, Config.PedPos[i].w, false, true)

            created_peds[Players[i].citizenid] = Players[i]
            created_peds[Players[i].citizenid].ped = RoomPeds[i]
            created_peds[Players[i].citizenid].posid = i

            if i <= 1 then
                TaskPlayAnim(RoomPeds[i], "timetable@ron@ig_3_couch", "base", 8.0, 0, -1, 1, 0, 0, 0)
            else
                TaskPlayAnim(RoomPeds[i], "timetable@ron@ig_3_couch", "base", 8.0, 0, -1, 1, 0, 0, 0)
            end
            SetPedComponentVariation(RoomPeds[k], 0, 0, 0, 2)
            FreezeEntityPosition(RoomPeds[k], false)
            SetEntityInvincible(RoomPeds[k], true)
            PlaceObjectOnGroundProperly(RoomPeds[k])
            SetBlockingOfNonTemporaryEvents(RoomPeds[k], true)

            if skins[i] then
                exports['illenium-appearance']:setPedAppearance(RoomPeds[i], json.decode(skins[i]))
            end
        end
    end
end

AddEventHandler('onResourceStop', function(resourceName)
    if GetCurrentResourceName() == resourceName then
        for k, v in pairs(RoomPeds) do
            DeleteEntity(v)
        end
        RoomPeds = {}
    end
end)

RegisterNUICallback('setupCharacters', function(data, cb)
    local Done = false
    local Players = {}
    local models = {}
    local skins = {}
    QBCore.Functions.TriggerCallback("qb-multicharacter:server:setupCharacters", function(result, model, skin)
        cached_player_skins = {}
        Done = true
        Players = result
        models = model
        skins = skin
        SendNUIMessage({
            action = "setupCharacters",
            characters = result,
        })
        cb("ok")
    end, data.setBucket)

    while Done == false do
        Wait(10)
    end
    SpawnCharacters(Players, models, skins)
end)

RegisterNUICallback('removeBlur', function(_, cb)
    TriggerScreenblurFadeOut(1000)
    SetTimecycleModifier('default')
    cb("ok")
end)

RegisterNUICallback('createNewCharacter', function(data, cb)
    local cData = data
    DoScreenFadeOut(150)
    if cData.gender == "Male" then
        cData.gender = 0
    elseif cData.gender == "Female" then
        cData.gender = 1
    end
    created_peds = {}
    TriggerServerEvent('qb-multicharacter:server:createCharacter', cData)
    Wait(500)
    cb("ok")
end)

RegisterNUICallback('removeCharacter', function(data, cb)
    TriggerServerEvent('qb-multicharacter:server:deleteCharacter', data.citizenid)
    DeletePed(charPed)
    TriggerEvent('qb-multicharacter:client:chooseChar')
    created_peds = {}
    cb("ok")
end)
