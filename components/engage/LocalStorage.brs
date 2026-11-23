function CreateLocalStorage() as Object
    m = {}
    m.sec = CreateObject("roRegistrySection", "RecurlyEngage")
    MigrateLegacyRegistry(m.sec)
    m.createNewOverlayKey = createNewOverlayKey
    m.deleteOverylayKey = deleteOverylayKey
    m.isOverlayEnabled = isOverlayEnabled
    m.reset = reset
    m.hasHoldOutPresented = hasHoldOutPresented
    m.createHoldOutKey = createHoldOutKey
    return m
end function

' SDK 1.x stored suppression/holdout state in a legacy registry section.
' Copy any pending keys over to the current section so merchant users keep
' their prompt state across the SDK upgrade, then clear the legacy section.
sub MigrateLegacyRegistry(newSec as Object)
    legacySec = CreateObject("roRegistrySection", "Redfast")
    legacyKeys = legacySec.GetKeyList()
    if legacyKeys.Count() = 0
        return
    end if
    for each key in legacyKeys
        newSec.Write(key, legacySec.Read(key))
    end for
    newSec.Flush()
    for each key in legacyKeys
        legacySec.Delete(key)
    end for
    legacySec.Flush()
    print "Re: migrated " + legacyKeys.Count().toStr() + " registry keys from legacy section"
end sub

sub createNewOverlayKey(overlayPathId as String, disabledInterval as String)
    date = CreateObject("roDateTime")
    value = date.AsSeconds().ToStr() + ","
    if disabledInterval = "INF"
        value += "-1"
    else if disabledInterval = "VISIT"
        value += "-2"
    else
        value += Str(Val(disabledInterval, 10) * 60) 'minutes to seconds
    end if
    print "Re: promos " + overlayPathId + " is disabled for " + value.toStr() + " seconds"
    m.sec.Write(overlayPathId, value)
    m.sec.Flush()
end sub

sub deleteOverylayKey(overlayPathId as String)
    print "Re: promos " + overlayPathId + " is deleted"
    m.sec.Delete(overlayPathId)
    m.sec.Flush()
end sub

function isOverlayEnabled(overlayPathId as String) as Boolean
    if m.sec.Exists(overlayPathId)
        value = m.sec.Read(overlayPathId)
        components = value.Split(",")
        if components.Count() = 2
            start = Val(components[0], 10)
            interval = Val(components[1], 10)
            date = CreateObject("roDateTime")
            now = date.AsSeconds()
            if interval = -1 or interval = -2 or (start + interval > now)
                print "Re: promos " + overlayPathId + " is blocked due to " +  value + " and now " + now.toStr()
                return false
            end if
        end if
        m.deleteOverylayKey(overlayPathId)
    end if
    return true
end function

sub reset(visitOnly as boolean)
    keys = m.sec.GetKeyList()
    keyCount = keys.count()
    visitCount = 0
    for ii = 0 to keys.count() - 1 step 1
        key = keys[ii]
        if visitOnly
            value = m.sec.Read(key)
            components = value.Split(",")
            if components.Count() = 2
                interval = Val(components[1], 10)
                if interval = -2
                    m.sec.Delete(key)
                    visitCount += 1
                end if
            end if
        else
            m.sec.Delete(key)
        end if
    end for
    m.sec.Flush()
    if visitOnly
        print "Re: reset VISIT promos, total " + visitCount.toStr()
    else
        print "Re: reset all promos, total " + keyCount.toStr()
    end if
end sub

sub createHoldOutKey(holdoutPathId as String)
    print "Re: holdout key created for " + holdoutPathId
    m.sec.Write(holdoutPathId + "_holdout", "true")
    m.sec.Flush()
end sub

function hasHoldOutPresented(holdoutPathId as String) as boolean
    if m.sec.Exists(holdoutPathId + "_holdout")
        print "Re: holdout disabled for " + holdoutPathId
        return true
    end if
    return false
end function