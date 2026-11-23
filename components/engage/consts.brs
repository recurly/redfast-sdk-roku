' Copyright (C) 2023 Recurly, Inc - All Rights Reserved
'
' Must not be copied and/or distributed without the express
' permission of Recurly, Inc

function PromptResult() as object
    m = {}
    ' Success codes
    m.ok = 1

    ' Error codes
    m.error = -100
    m.notApplicable = -101
    m.disabled = -102
    m.suppressed = -103

    ' Interactions
    m.impression = 100
    m.button1 = 101
    m.button2 = 102
    m.button3 = 103
    m.dismissed = 110
    m.timerExpired = 111
    m.holdout = 120
    return m
end function

function PathType() as object
    m = {}
    m.all = -1
    m.invisible = 1
    m.modal = 2
    m.horizontal = 5
    m.video = 6
    m.interstitial = 10
    m.bottomBanner = 13
    m.unknown = 0
    return m
end function

function ZoneType() as object
    m = {}
    m.billboard = "billboard"
    m.featured = "featured"
    m.rokuHorizontal = "roku-horizontal"
    return m
end function

function DeviceType() as object
    m = {}
    m.ios = "ios"
    m.android_os = "android_os"
    m.roku_os = "roku_os"
    m.unknown = "unknown"
    return m
end function

function ErrorMessage() as object
    m = {}
    m.invalid_action = "no action data available"
    return m
end function

function PrivacyConsentCategory() as object
    m = {}
    m.strictlyNecessary = "strictly_necessary"
    m.performance = "performance"
    m.functional = "functional"
    m.targeting = "targeting"
    return m
end function

function copyArray(arr as object) as object
    copy = []
    if arr <> invalid
        for each item in arr
            copy.push(item)
        end for
    end if
    return copy
end function

function getKeyValuePair(components as string) as object
    keyValue = components
    remain = ""
    index = Instr(1, components, "&")
    if index <> 0
        keyValue = Left(components, index - 1)
        remain = Right(components, Len(components) - index)
    end if
    index = Instr(1, keyValue, "=")
    if index = 0
        return invalid
    end if
    return { key: Left(keyValue, index - 1), value: Right(keyValue, Len(keyValue) - index), remain: remain }
end function

function parseKeyValuePair(components as string) as object
    result = {}
    continue = true
    while continue
        if components <> "" or components <> invalid
            keyValue = getKeyValuePair(components)
            if keyValue = invalid
                continue = false
            else
                result.AddReplace(keyValue.key, keyValue.value)
                components = keyValue.remain
            end if
        else
            continue = false
        end if
    end while
    return result
end function

function pxToInteger(pxString as string) as integer
    if pxString.Instr("px") > 0
        left = pxString.Left(pxString.Len() - 2)
        return left.toInt()
    end if
    return 0
end function

function pxToFloat(pxString as string) as float
    if pxString.Instr("px") > 0
        left = pxString.Left(pxString.Len() - 2)
        return left.toFloat()
    else
        return pxString.toFloat()
    end if
end function

function preparePromptResult(resultObj as object, path as object) as object
    if path <> invalid
        resultObj.promptMeta = {}
        resultObj.promptMeta.promptName = path.name
        resultObj.promptMeta.promptID = path.id
        resultObj.promptMeta.promptVariationName = path.action_group_name
        resultObj.promptMeta.promptVariationID = path.action_group_id
        resultObj.promptMeta.promptExperimentName = path.experiment_name
        resultObj.promptMeta.promptExperimentID = path.experiment_id
        resultObj.promptMeta.promptType = path.path_type

        allCodes = PromptResult()
        if resultObj.code = allCodes.button1
            resultObj.promptMeta.buttonLabel = path.actions.rf_retention_button1_text
        else if resultObj.code = allCodes.button2
            resultObj.promptMeta.buttonLabel = path.actions.rf_retention_button2_text
        else if resultObj.code = allCodes.button3
            resultObj.promptMeta.buttonLabel = path.actions.rf_retention_button3_text
        end if
    end if

    return resultObj
end function