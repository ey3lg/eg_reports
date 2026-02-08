Bridge = {}
local BridgeExport = nil
local HasPermission = false

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
        print('^1[eg_reports] Failed to initialize community_bridge after 10 attempts^7')
        return
    end

    Bridge.RequestPermissionCheck()
end)

function Bridge.GetPlayerData()
    if not BridgeExport then return nil end
    return BridgeExport.Framework.GetPlayerData()
end

function Bridge.Notify(message, type)
    if BridgeExport then
        BridgeExport.Framework.Notify(message, type or 'info', 5000)
    end
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
