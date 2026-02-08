Bridge = {}
local BridgeExport = nil
local PlayerPermissions = {}

CreateThread(function()
    local attempts = 0
    while not BridgeExport and attempts < 10 do
        local ok, result = pcall(function()
            return exports['community_bridge']:Bridge()
        end)
        if ok and result then
            BridgeExport = result
        else
            attempts = attempts + 1
            Wait(1000)
        end
    end

    if not BridgeExport then
        print('^1[eg_reports] Failed to initialize community_bridge on server after 10 attempts^7')
    end
end)

function Bridge.GetPlayer(source)
    if not BridgeExport then return nil end
    return BridgeExport.Framework.GetPlayer(source)
end

function Bridge.GetPlayerIdentifier(source)
    if not BridgeExport then return nil end
    return BridgeExport.Framework.GetPlayerIdentifier(source)
end

function Bridge.GetPlayerName(source)
    if not BridgeExport then return GetPlayerName(source) end
    local ok, firstName, lastName = pcall(BridgeExport.Framework.GetPlayerName, source)
    if ok and firstName and lastName then
        return firstName .. ' ' .. lastName
    end
    return GetPlayerName(source)
end

function Bridge.Notify(source, message, type)
    TriggerClientEvent('eg_reports:client:notify', source, message, type or 'info')
end

function Bridge.CheckPermission(source)
    if not BridgeExport then return false end
    local ok, result = pcall(BridgeExport.Framework.GetIsFrameworkAdmin, source)
    if ok then return result or false end
    return false
end

function Bridge.HasPermission(source)
    if PlayerPermissions[source] == nil then
        PlayerPermissions[source] = Bridge.CheckPermission(source)
    end
    return PlayerPermissions[source]
end

function Bridge.RefreshPermission(source)
    local oldPerm = PlayerPermissions[source]
    local newPerm = Bridge.CheckPermission(source)
    PlayerPermissions[source] = newPerm
    if oldPerm ~= newPerm then
        TriggerClientEvent('eg_reports:client:permission_updated', source, newPerm)
    end
    return newPerm
end

function Bridge.GetPlayerCoords(source)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then return vector3(0, 0, 0) end
    return GetEntityCoords(ped)
end

AddEventHandler('playerDropped', function()
    PlayerPermissions[source] = nil
end)

CreateThread(function()
    Wait(5000)
    while true do
        for _, playerId in ipairs(GetPlayers()) do
            Bridge.RefreshPermission(tonumber(playerId))
        end
        Wait(5000)
    end
end)

RegisterNetEvent('eg_reports:server:request_permission', function()
    local src = source
    TriggerClientEvent('eg_reports:client:permission_updated', src, Bridge.RefreshPermission(src))
end)

RegisterNetEvent('community_bridge:Server:OnPlayerJobChange', function(src)
    Bridge.RefreshPermission(src)
end)

AddEventHandler('txAdmin:events:adminAuth', function(data)
    if data and data.netid then
        Bridge.RefreshPermission(data.netid)
    end
end)
