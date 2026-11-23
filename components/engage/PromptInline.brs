' Copyright (C) 2023 Recurly, Inc - All Rights Reserved
'
' Must not be copied and/or distributed without the express
' permission of Recurly, Inc

sub init()
    m.backgroundColor = m.top.findNode("background")
    m.poster = m.top.findNode("poster")
    m.root = m.top.findNode("root")
    m.accessibility = m.top.findNode("accessibility")
    m.top.focusable = true
    m.top.observeField("focusedChild", "focusChanged")
end sub

function callApi(params)
    action = createObject("RoSGNode", "PromptApi")
    action.appId = m.appId
    action.userId = m.userId
    action.deviceType = m.deviceType
    if m.anonymous_user_id <> invalid
        action.anonymous_user_id = m.anonymous_user_id
    end if
    action.callFunc("fireEvent", params)
end function

sub showInline(params as object)
    m.appId = params.appId
    m.userId = params.userId
    m.deviceType = params.deviceType
    m.anonymous_user_id = params.anonymous_user_id
    m.currentPath = params.path
    m.parent = params.parent

    m.backgroundColor.width = m.parent.width
    m.backgroundColor.height = m.parent.height
    m.root.width = m.parent.width - 20
    m.root.height = m.parent.height - 20
    m.poster.width = m.root.width
    m.poster.height = m.root.height
    m.poster.loadDisplayMode = params.scale
    m.poster.uri = params.path.actions.rf_settings_bg_image_roku_os_tv_composite
    m.accessibility.text = params.path.actions.accessibility_label
end sub

sub focusChanged()
    if m.top.hasFocus() and m.currentPath.actions.button1_bg_color <> invalid
        m.backgroundColor.color = m.currentPath.actions.button1_bg_color
    else
        m.backgroundColor.color = "#00000000"
    end if
end sub

function onKeyEvent(key as string, pressed as boolean) as boolean
    if key = "OK" and pressed
        if m.currentPath.actions.rf_settings_tile_interaction <> "none"
            track = callApi({ event: "goal", pathId: m.currentPath.id, actionGroupId: m.currentPath.action_group_id })
            allResults = PromptResult()
            m.top.result = preparePromptResult({
                code: allResults.button1,
                meta: m.currentPath.actions.rf_metadata,
                deeplink: m.currentPath.actions.rf_settings_deeplink
            }, m.currentPath)
        end if
        return true
    end if
    return false
end function