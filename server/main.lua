CreateThread(function()
    while true do
        Wait(3600000)
        Database.CleanupOldReports()
    end
end)
