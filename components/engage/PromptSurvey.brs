' Copyright (C) 2023 Recurly, Inc - All Rights Reserved
'
' Must not be copied and/or distributed without the express
' permission of Recurly, Inc

sub init()
    m.rf_settings_bg_image = m.top.findNode("rf_settings_bg_image")
    m.rf_retention_title = m.top.findNode("rf_retention_title")
    m.rf_retention_message = m.top.findNode("rf_retention_message")
    m.buttonRoot = m.top.findNode("buttonRoot")
    m.option1 = m.top.findNode("option1")
    m.option2 = m.top.findNode("option2")
    m.option3 = m.top.findNode("option3")
    m.option4 = m.top.findNode("option4")
    m.option5 = m.top.findNode("option5")
    m.currentButton = 0
    m.totalButtons = 1
    m.countDown = m.top.findNode("countDown")
    m.result = PromptResult()
    m.initialGrabFocus = false
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

    pathTypes = PathType()
    if path.path_type = pathTypes.interstitial
        ' interstitial
        m.rf_settings_bg_image.width = 1920
        m.rf_settings_bg_image.height = 1080
        m.rf_settings_bg_image.translation = [0, 0]
    else
        ' popup
        mulitplier = 0.6
        if path.actions.rf_settings_pop_up_size = "large"
            mulitplier = 0.9
        else if path.actions.rf_settings_pop_up_size = "medium"
            mulitplier = 0.75
        end if
        tvOSHeightMultiplier = 0.75

        m.rf_settings_bg_image.width = 1080 * mulitplier
        m.rf_settings_bg_image.height = 1080 * mulitplier * tvOSHeightMultiplier
        m.rf_settings_bg_image.translation = [(1920 - m.rf_settings_bg_image.width) / 2, (1080 - m.rf_settings_bg_image.height) / 2]
        m.countDown.translation = [40, m.rf_settings_bg_image.height - 100]
    end if

    m.rf_settings_bg_image.uri = path.actions.rf_settings_bg_image_roku_os_tv_composite

    totalOptions = path.actions.rf_retention_survey_options_total.toInt()
    m.totalButtons = totalOptions
    fontSize = path.actions.rf_retention_survey_options_font_size.replace("px", "").toInt()
    buttonHeight = fontSize + 20
    buttonWidth = m.rf_settings_bg_image.width - 80
    for i = 1 to totalOptions
        optNode = m["option" + i.toStr()]
        if optNode <> invalid
            optNode.label = path.actions["rf_retention_survey_option_" + i.toStr() + "_label"]
            optNode.width = buttonWidth
            optNode.height = buttonHeight
            optNode.translation = [0, (buttonHeight + 20) * (i - 1)]
            optNode.textColor = path.actions.button1_text_color
            optNode.textHighlightedColor = path.actions.button1_highlight_color
            optNode.bgColor = path.actions.button1_bg_color
            optNode.bgHighlightedColor = path.actions.button1_focus_bg_color
            optNode.font = m.top.fonts.ctaFont
            optNode.ObserveField("buttonSelected", "onAccept")
        end if
    end for
    m.currentButton = 0
    m.option1.setFocus(true)
    m.buttonRoot.width = buttonWidth
    m.buttonRoot.height = (buttonHeight + 20) * totalOptions
    m.buttonRoot.translation = [40, 250]

    if path.actions.rf_settings_close_seconds <> invalid and path.actions.rf_settings_close_seconds <> ""
        m.timerCounter = path.actions.rf_settings_close_seconds.toInt()
        if m.timerCounter > 0
            m.countDown.visible = (path.actions.rf_settings_hide_timer_text <> "true")
            m.countDown.color = path.actions.rf_settings_timer_font_color
            m.countDown.text = m.timerCounter.toStr() + "s"
            m.countDown.font = m.top.fonts.timeoutFont
            m.countDown.translation = [m.rf_settings_bg_image.width - 50, 0]
            m.timer = createObject("RoSGNode", "Timer")
            m.timer.duration = 1
            m.timer.observeField("fire", "onTimer")
            m.timer.repeat = true
            m.timer.control = "start"
        end if
    end if

    callApi({ event: "impression", pathId: path.id, actionGroupId: path.action_group_id })
end sub

sub onTimer()
    m.timerCounter -= 1
    m.countDown.text = m.timerCounter.toStr() + "s"
    if m.initialGrabFocus = false
        m.option1.setFocus(true)
        m.initialGrabFocus = true
    end if
    if m.timerCounter = 0
        m.timer.unobserveField("fire")
        m.timer.control = "stop"
        m.top.result = preparePromptResult({
            code: m.result.timerExpired,
            meta: m.currentPath.actions.rf_metadata
        }, m.currentPath)
        callApi({ event: "dismiss", pathId: m.currentPath.id, actionGroupId: m.currentPath.action_group_id, reason: "timeout" })
        m.localStorage.createNewOverlayKey(m.currentPath.id, m.currentPath.actions.rf_settings_timeout_interval)
    end if
end sub

sub onAccept()
    if (m.timer <> invalid)
        m.timer.unobserveField("fire")
        m.timer.control = "stop"
    end if
    m.countDown.visible = false
    selectedIndex = m.currentButton + 1
    selectedValue = m.currentPath.actions["rf_retention_survey_option_" + selectedIndex.toStr() + "_value"]

    callApi({ event: "goal", pathId: m.currentPath.id, actionGroupId: m.currentPath.action_group_id, surveySelection: selectedValue })
    m.localStorage.createNewOverlayKey(m.currentPath.id, m.currentPath.actions.rf_settings_accept_interval)
    m.top.result = preparePromptResult({
        code: m.result.button1,
        roku: m.currentPath.actions.rf_settings_roku_product_id,
        deeplink: parseKeyValuePair(m.currentPath.actions.rf_settings_deeplink),
        meta: m.currentPath.actions.rf_metadata
    }, m.currentPath)
end sub

function onKeyEvent(key as string, pressed as boolean) as boolean
    if key = "up" and pressed
        if m.currentButton > 0
            m.currentButton = m.currentButton - 1
        end if
    else if key = "down" and pressed
        if m.currentButton + 1 < m.totalButtons
            m.currentButton = m.currentButton + 1
        end if
    else if key = "back" and pressed
        if m.timer <> invalid
            m.timer.control = "stop"
        end if
        callApi({ event: "dismiss", pathId: m.currentPath.id, actionGroupId: m.currentPath.action_group_id, reason: "dismiss" })
        m.localStorage.createNewOverlayKey(m.currentPath.id, m.currentPath.actions.rf_settings_dismiss_interval)
        m.top.result = preparePromptResult({
            code: m.result.dismissed,
            meta: m.currentPath.actions.rf_metadata
        }, m.currentPath)
    end if

    if (key = "up" or key = "down") and pressed
        optNode = m["option" + (m.currentButton + 1).toStr()]
        if optNode <> invalid
            optNode.setFocus(true)
        end if
    end if
    return true
end function
