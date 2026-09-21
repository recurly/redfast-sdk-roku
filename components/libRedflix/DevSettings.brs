' Demo-app-only devtools overrides, persisted separately from the SDK's own
' registry section so devtools state never mixes with suppression/holdout data.

function DefaultDevAppId() as string
    return "6b233605-b981-4d6d-8b45-efa7fc402388"
end function

function DefaultDevUserId() as string
    return "123"
end function

function LoadDevSettings() as object
    sec = CreateObject("roRegistrySection", "RedflixDevTools")
    settings = { appIdOverride: "", userIdOverride: "", environment: "production" }
    if sec.Exists("appIdOverride") then settings.appIdOverride = sec.Read("appIdOverride")
    if sec.Exists("userIdOverride") then settings.userIdOverride = sec.Read("userIdOverride")
    if sec.Exists("environment") then settings.environment = sec.Read("environment")
    return settings
end function

sub SaveDevSettings(settings as object)
    sec = CreateObject("roRegistrySection", "RedflixDevTools")
    sec.Write("appIdOverride", settings.appIdOverride)
    sec.Write("userIdOverride", settings.userIdOverride)
    sec.Write("environment", settings.environment)
    sec.Flush()
end sub

function EffectiveAppId(settings as object) as string
    if settings.appIdOverride <> invalid and settings.appIdOverride <> ""
        return settings.appIdOverride
    end if
    return DefaultDevAppId()
end function

function EffectiveUserId(settings as object) as string
    if settings.userIdOverride <> invalid and settings.userIdOverride <> ""
        return settings.userIdOverride
    end if
    return DefaultDevUserId()
end function
