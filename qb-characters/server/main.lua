local QBCore = exports['qb-core']:GetCoreObject()

local function InsertToMDT(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    if Player then
        MySQL.Async.insert(
            'INSERT INTO mdt_data (cid, fingerprint) VALUES (:cid, :fingerprint) ON DUPLICATE KEY UPDATE cid = :cid, fingerprint = :fingerprint',
            {
                cid = Player.PlayerData.citizenid,
                fingerprint = Player.PlayerData.metadata['fingerprint'],
            })
    end
end

local function GiveStarterItems(source)
    local src = source
    local Player = QBCore.Functions.GetPlayer(src)
    exports['qb-inventory']:AddItem(src, 'id_card', 1)
    exports['qb-inventory']:AddItem(src, 'driver_license', 1)
    exports['qb-inventory']:AddItem(src, 'phone', 1)
    exports['qb-inventory']:AddItem(src, 'lockpick', 2)
end

RegisterNetEvent('qb-characters:sv:AddUrlFace')
AddEventHandler('qb-characters:sv:AddUrlFace', function(faceUrl)
    local src = source
    local player = QBCore.Functions.GetPlayer(src)

    -- Check if the player is valid
    if player then
        -- Store the face URL in the database
        exports.ghmattimysql:execute('UPDATE users SET face_url = @faceUrl WHERE identifier = @identifier', {
            ['@faceUrl'] = faceUrl,
            ['@identifier'] = player.PlayerData.steam,
        }, function(rowsChanged)
            if rowsChanged > 0 then
                print(('Face URL added for player %s'):format(player.PlayerData.steam))
            else
                print(('Failed to add face URL for player %s'):format(player.PlayerData.steam))
            end
        end)
    else
        print(('Invalid player ID %s. Failed to set FaceUrl.'):format(src))
    end
end)



RegisterNetEvent('qb-multicharacter:server:loadUserData', function(cData, custom)
    local src = source
    if cData.citizenid and string.len(cData.citizenid) > 0 then
        if QBCore.Player.Login(src, cData.citizenid) then
            local Player = QBCore.Functions.GetPlayer(src)

            Wait(400)
            print('^2[qb-core]^7 ' ..
                GetPlayerName(src) .. ' (Citizen ID: ' .. cData.citizenid .. ') has successfully loaded!')
            QBCore.Commands.Refresh(src)
            TriggerClientEvent('qb-multicharacter:client:lastlocation', src, cData, custom)
        else
            -- Handle login failure
        end
    else
        -- Handle missing or invalid citizen ID
    end
end)


QBCore.Functions.CreateCallback("qb-multicharacter:server:setupCharacters", function(source, cb)
    local license = QBCore.Functions.GetIdentifier(source, 'license')
    local plyChars = {}
    local models = {}
    local skins = {}
    MySQL.Async.fetchAll('SELECT * FROM players WHERE license = ?', { license }, function(result)
        for k, v in pairs(result) do
            local result = MySQL.Sync.fetchAll('SELECT * FROM playerskins WHERE citizenid = ? AND active = ?',
                { v.citizenid, 1 })
            local res = {}
            if v.citizenid and string.len(v.citizenid) > 0 then
                res.citizenid = tonumber(v.citizenid) -- Convert to number if it's a valid citizen ID
            else
                -- Handle missing or invalid citizen ID
                res.citizenid = nil
            end
            res.metadata = json.decode(v.metadata)
            res.charinfo = json.decode(v.charinfo)
            res.money = json.decode(v.money)
            res.job = json.decode(v.job)
            if result and result[1] then
                if result[1].model then
                    models[#models + 1] = result[1].model
                end
                if result[1].skin then
                    skins[#skins + 1] = result[1].skin
                end
            end
            plyChars[#plyChars + 1] = res
        end
        Wait(400)
        cb(plyChars, models, skins)
    end)

end)


QBCore.Functions.CreateCallback("qb-multicharacter:server:getSkin", function(source, cb, cid)
    if cid and tonumber(cid) then -- Check if the provided CID is not nil and is a valid number
        local result = MySQL.query.await('SELECT * FROM playerskins WHERE citizenid = ? AND active = ?', { tonumber(cid), 0 })
        if result[1] ~= nil then
            cb(json.decode(result[1].skin))
        else
            cb(nil)
        end
    else
        cb(nil) -- If CID is not valid, return nil
    end
end)

QBCore.Functions.CreateCallback("qb-multicharacter:server:GetNumberOfCharacters", function(source, cb)
    local src = source
    local license = QBCore.Functions.GetIdentifier(src, 'license')
    local numOfChars = 0

    if next(Config.PlayersNumberOfCharacters) then
        for _, v in pairs(Config.PlayersNumberOfCharacters) do
            if v.license == license then
                numOfChars = v.numberOfChars
                break
            else
                numOfChars = Config.DefaultNumberOfCharacters
            end
        end
    else
        numOfChars = Config.DefaultNumberOfCharacters
    end
    cb(numOfChars)
end)


RegisterServerEvent('qb-multicharacter:server:createCharacter')
AddEventHandler('qb-multicharacter:server:createCharacter', function(data)
    local src = source
    local newData = {}
    newData.cid = data.cid
    newData.charinfo = data

    if QBCore.Player.Login(src, false, newData) then
        if Config.StartingApartment then
            local randbucket = (GetPlayerPed(src) .. math.random(1, 999))
            SetPlayerRoutingBucket(src, randbucket)
            print('^2[New-Character]^7 ' .. GetPlayerName(src) .. ' has succesfully loaded!')
            QBCore.Commands.Refresh(src)
            TriggerClientEvent("qb-multicharacter:client:closeNUI", src)
            GiveStarterItems(src)
        else
            SetPlayerRoutingBucket(src, tonumber(src))
            print('^2[New-Character]^7 ' .. GetPlayerName(src) .. ' has succesfully loaded!')
            QBCore.Commands.Refresh(src)
            TriggerClientEvent("qb-multicharacter:client:closeNUIdefault", src)
            GiveStarterItems(src)
        end

        QBCore.Functions.CreateLog(
            "loaded",
            "New Character",
            "green",
            "**" .. GetPlayerName(src) .. "** Just Created New Character | " .. newData.cid .. "",
            false
        )
        -- TriggerClientEvent("qb-characters:client:setupSpawns", src)
        InsertToMDT(src)
    end
end)

RegisterServerEvent('qb-multicharacter:server:deleteCharacter')
AddEventHandler('qb-multicharacter:server:deleteCharacter', function(citizenid)
    local src = source
    QBCore.Player.DeleteCharacter(src, citizenid)
    TriggerClientEvent('qb-multicharacter:client:chooseChar', src)
end)

RegisterServerEvent('qb-multicharacter:server:disconnect')
AddEventHandler('qb-multicharacter:server:disconnect', function()
    local src = source
    DropPlayer(src, "You left the city!")
end)

-- // Commands \\ --

QBCore.Commands.Add("char", "Go to the characters menu.", {}, false, function(source, args)
    local Player = QBCore.Functions.GetPlayer(source)
    QBCore.Player.Logout(source)
    Citizen.Wait(550)
    TriggerClientEvent('qb-multicharacter:client:chooseChar', source)
end, { 'god', 'admin', 'operator' })

QBCore.Commands.Add('charp', "Give Player characters menu.", { { name = 'ID', help = 'Player ID' } }, true,
    function(source, args)
        local Player = QBCore.Functions.GetPlayer(tonumber(args[1]))
        if Player then
            QBCore.Player.Logout(Player.PlayerData.source)
            Citizen.Wait(550)
            TriggerClientEvent('qb-multicharacter:client:chooseChar', Player.PlayerData.source)
        else
            TriggerClientEvent('QBCore:Notify', source, 'Player is not online', 'error')
        end
    end, { 'god', 'admin', 'operator' })
