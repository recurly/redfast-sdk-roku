' Copyright (C) 2023 Recurly, Inc - All Rights Reserved
'
' Must not be copied and/or distributed without the express
' permission of Recurly, Inc

sub init()
    m.rf_settings_bg_image = m.top.findNode("rf_settings_bg_image")
    m.rf_settings_video = m.top.findNode("rf_settings_video")
    m.rf_retention_confirm_button_text = m.top.findNode("rf_retention_confirm_button_text")
    m.rf_retention_cancel_button_text = m.top.findNode("rf_retention_cancel_button_text")
    m.result = PromptResult()
    m.localStorage = CreateLocalStorage()
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

sub showModal(params as object)
    m.appId = params.appId
    m.userId = params.userId
    m.deviceType = params.deviceType
    m.anonymous_user_id = params.anonymous_user_id
    path = params.path
    m.currentPath = path

    m.rf_retention_confirm_button_text.label = path.actions.rf_retention_button1_text
    m.rf_retention_confirm_button_text.textColor = path.actions.button1_text_color
    m.rf_retention_confirm_button_text.textHighlightedColor = path.actions.button1_highlight_color
    m.rf_retention_confirm_button_text.bgColor = path.actions.button1_bg_color
    m.rf_retention_confirm_button_text.font = m.top.fonts.ctaFont
    m.rf_retention_confirm_button_text.ObserveField("buttonSelected", "onAccept")
    m.rf_retention_cancel_button_text.label = path.actions.rf_retention_button3_text
    m.rf_retention_cancel_button_text.textColor = path.actions.button3_text_color
    m.rf_retention_cancel_button_text.textHighlightedColor = path.actions.button3_highlight_color
    m.rf_retention_cancel_button_text.bgColor = path.actions.button3_bg_color
    m.rf_retention_cancel_button_text.font = m.top.fonts.ctaFont
    m.rf_retention_cancel_button_text.ObserveField("buttonSelected", "onDecline")

    m.rf_settings_video_loop = false
    if path.actions.rf_settings_video_loop = "true"
        m.rf_settings_video_loop = true
    end if
    m.rf_settings_video_controls = false
    if path.actions.rf_settings_video_controls = "true"
        m.rf_settings_video_controls = true
    end if
    m.rf_settings_video_preload = path.actions.rf_settings_video_preload
    m.rf_settings_video_is_url = false
    if path.actions.rf_settings_video_is_url = "true"
        m.rf_settings_video_is_url = true
    end if
    callApi({ event: "impression", pathId: path.id, actionGroupId: path.action_group_id })

    prompt_width_percent = 70 / 100
    m.rf_settings_video.width = 1920 * prompt_width_percent
    m.rf_settings_video.height = 1080 * prompt_width_percent
    m.rf_settings_bg_image.width = m.rf_settings_video.width
    m.rf_settings_bg_image.height = m.rf_settings_video.height
    m.rf_settings_bg_image.uri = path.actions.rf_settings_video_poster
    m.rf_settings_video.translation = [(1920 - m.rf_settings_video.width) / 2, (1080 - m.rf_settings_video.height) / 2]
    m.rf_retention_confirm_button_text.translation = [50, m.rf_settings_video.height - 120]
    m.rf_retention_cancel_button_text.translation = [450, m.rf_settings_video.height - 120]
    m.rf_retention_confirm_button_text.setFocus(true)

    videoContent = createObject("RoSGNode", "ContentNode")
    videoContent.url = path.actions.rf_settings_video_src
    videoContent.streamformat = path.actions.rf_settings_video_media_type
    m.rf_settings_video.observeField("state", "onState")
    m.rf_settings_video.content = videoContent
    m.rf_settings_video.enableUI = false
    m.rf_settings_video.enableTrickPlay = false
    if path.actions.rf_settings_video_muted = "true"
        m.rf_settings_video.mute = true
    else
        m.rf_settings_video.mute = false
    end if
    m.rf_settings_video.control = "play"
    m.localStorage.createNewOverlayKey(m.currentPath.id, m.currentPath.actions.rf_settings_decline_interval)
end sub

sub onState()
    if m.rf_settings_video.state = "playing"
        m.rf_settings_bg_image.visible = false
        m.rf_retention_confirm_button_text.setFocus(true)
    else
        m.rf_settings_bg_image.visible = true
    end if
end sub

sub onAccept()
    m.rf_settings_video.control = "stop"
    callApi({ event: "goal", pathId: m.currentPath.id, actionGroupId: m.currentPath.action_group_id })
    m.localStorage.createNewOverlayKey(m.currentPath.id, m.currentPath.actions.rf_settings_accept_interval)
    m.top.result = preparePromptResult({
        code: m.result.button1,
        roku: m.currentPath.actions.rf_settings_roku_product_id,
        deeplink: parseKeyValuePair(m.currentPath.actions.rf_settings_deeplink),
        meta: m.currentPath.actions.rf_metadata
    }, m.currentPath)
end sub

sub onDecline()
    m.rf_settings_video.control = "stop"
    callApi({ event: "decline", pathId: m.currentPath.id, actionGroupId: m.currentPath.action_group_id, reason: "decline" })
    m.localStorage.createNewOverlayKey(m.currentPath.id, m.currentPath.actions.rf_settings_decline_interval)
    m.top.result = preparePromptResult({
        code: m.result.button3,
        roku: m.currentPath.actions.rf_settings_roku_product_id,
        meta: m.currentPath.actions.rf_metadata
    }, m.currentPath)
end sub

function onKeyEvent(key as string, pressed as boolean) as boolean
    if key = "left" and pressed
        m.rf_retention_confirm_button_text.setFocus(true)
    else if key = "right" and pressed
        m.rf_retention_cancel_button_text.setFocus(true)
    else if key = "back" and pressed
        m.rf_settings_video.control = "stop"
        callApi({ event: "dismiss", pathId: m.currentPath.id, actionGroupId: m.currentPath.action_group_id, reason: "dismiss" })
        m.localStorage.createNewOverlayKey(m.currentPath.id, m.currentPath.actions.rf_settings_dismiss_interval)
        m.top.result = preparePromptResult({
            code: m.result.dismissed,
            meta: m.currentPath.actions.rf_metadata
        }, m.currentPath)
    end if
    return true
end function