local Framework = exports['community_bridge']:Framework()
local HasPermission = false

function Bridge.GetPlayerData()
    if Framework and Framework.GetPlayerData then
        return Framework.GetPlayerData()
    end
    return nil
end

function Bridge.IsPlayerLoaded()
    if Framework and Framework.IsPlayerLoaded then
        return Framework.IsPlayerLoaded()
    end
    return true
end

function Bridge.Notify(message, type)
    if Framework and Framework.Notify then
        Framework.Notify(message, type or 'info')
    else
        exports['community_bridge']:Notify(message, type or 'info')
    end
end

function Bridge.GetCharacterName()
    if Framework and Framework.GetPlayerName then
        local name = Framework.GetPlayerName()
        if name then return name end
    end
    return GetPlayerName(PlayerId())
end

function Bridge.HasPermission()
    return HasPermission
end

function Bridge.RequestPermissionCheck()
    TriggerServerEvent('eg_reports:server:request_permission')
end

RegisterNetEvent('eg_reports:client:notify', function(message, type)
    Bridge.Notify(message, type)
end)

RegisterNetEvent('eg_reports:client:permission_updated', function(hasPerm)
    HasPermission = hasPerm
    TriggerEvent('eg_reports:client:onPermissionChanged', hasPerm)
end)

CreateThread(function()
    Wait(1000)
    Bridge.RequestPermissionCheck()
end)
