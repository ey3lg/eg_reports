
UI = {
    isOpen = false,
    firstTime = true,
    currentPage = nil
}

function UI.Open(page, pageData)
    if UI.isOpen then return end

    UI.isOpen = true
    UI.currentPage = page

    SetNuiFocus(true, true)

    if UI.firstTime then
        SendNUIMessage({
            type = "loadLocale",
            data = GetUILocale()
        })

        SendNUIMessage({
            type = "loadConfig",
            data = {
                categories = Config.Categories,
                priorities = Config.Priorities,
                statuses = Config.Statuses
            }
        })

        local permData = lib.callback.await('eg_reports:server:has_permission', false)
        SendNUIMessage({
            type = "setPermission",
            hasPermission = permData.hasPermission,
            playerIdentifier = permData.identifier
        })

        UI.firstTime = false
    end

    SendNUIMessage({
        type = "visible",
        value = true
    })

    SendNUIMessage({
        type = "open",
        page = page,
        pageData = pageData
    })
end

function UI.Close()
    if not UI.isOpen then return end

    UI.isOpen = false
    UI.currentPage = nil

    SetNuiFocus(false, false)

    SendNUIMessage({
        type = "visible",
        value = false
    })
end

function UI.Toggle(page, pageData)
    if UI.isOpen then
        UI.Close()
    else
        UI.Open(page, pageData)
    end
end

function UI.UpdatePermission(hasPermission)
    SendNUIMessage({
        type = "setPermission",
        hasPermission = hasPermission
    })
end

AddEventHandler('eg_reports:client:onPermissionChanged', function(hasPermission)
    UI.UpdatePermission(hasPermission)
end)

return UI
