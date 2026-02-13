ServerConfig = {}

ServerConfig.AdminGroups = { 'group.admin', 'group.moderator', 'group.trial_mod', 'group.developer', 'group.management', 'group.owner' }

ServerConfig.Screenshot = {
    UploadURL = 'https://discord.com/api/webhooks/1471826881094488146/UCy3vuX9jHEzPXDB8gwl3RY_Xto0efbEV3QYsYG8rep19CgsLIR0VifKWeaPX7h4n9If',
    FieldName = 'files[]',
}

ServerConfig.Webhooks = {
    Enabled = true,
    URLs = {
        NewReport = '',
        Claimed = '',
        Closed = '',
        Escalated = '',
        StaffReport = '',
        Deleted = '',
    }
}

return ServerConfig
