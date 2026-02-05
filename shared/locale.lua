Locales = {}
CurrentLocale = Config.Language or 'en'

function LoadLocale(lang)
    local locale = LoadResourceFile(GetCurrentResourceName(), 'locales/' .. lang .. '.json')
    if locale then
        return json.decode(locale)
    end
    return {}
end

Locales = LoadLocale(CurrentLocale)

function _(key)
    if Locales[key] then
        return Locales[key]
    end
    return key
end

function GetUILocale()
    return {
        header = Locales.header or {},
        reports = Locales.reports or {}
    }
end
