ServerConfig = {}

ServerConfig.Screenshot = {
    UploadURL = 'https://discord.com/api/webhooks/1359995866391380030/B2XpZETygZpItf35dcZAf3vXXyHPrgZ4wy_XUu170VxuIzvlcSfsdxmzR8X6gRx_QhZ0',
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
