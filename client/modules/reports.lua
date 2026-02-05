
Reports = {}

function Reports.OpenMyReports()
    UI.Open('myReports', nil)
end

function Reports.OpenCreateReport()
    UI.Open('createReport', nil)
end

function Reports.OpenAdminPanel()
    UI.Open('adminPanel', nil)
end

function Reports.GetPlayerCoords()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    return json.encode({
        x = math.floor(coords.x * 100) / 100,
        y = math.floor(coords.y * 100) / 100,
        z = math.floor(coords.z * 100) / 100
    })
end

RegisterCommand('reports', function()
    Reports.OpenMyReports()
end, false)

return Reports
