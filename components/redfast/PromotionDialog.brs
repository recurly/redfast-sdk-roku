' Copyright (C) 2023 Redfast Inc - All Rights Reserved
'
' Must not be copied and/or distributed without the express
' permission of Redfast Inc

sub init()
    m.rf_settings_bg_image = m.top.findNode("rf_settings_bg_image")
    m.rf_retention_title = m.top.findNode("rf_retention_title")
    m.rf_retention_message = m.top.findNode("rf_retention_message")
    m.rf_retention_confirm_button_text = m.top.findNode("rf_retention_confirm_button_text")
    m.rf_retention_cancel_button_text = m.top.findNode("rf_retention_cancel_button_text")
    m.rf_retention_accept2_button_text = m.top.findNode("rf_retention_accept2_button_text")
    m.buttonRoot = m.top.findNode("buttonRoot")
    m.buttonRows = []
    m.currentRow = 0
    m.currentColPerRow = []
    m.countDown = m.top.findNode("countDown")
    m.result = PromotionResult()
    m.initialGrabFocus = false
    m.interacted = false
    m.localStorage = CreateLocalStorage()
end sub

function callApi(params)
    action = createObject("RoSGNode", "PromotionApi")
    action.appId = m.appId
    action.userId = m.userId
    action.deviceType = m.deviceType
    if m.anonymous_user_id <> invalid
        action.anonymous_user_id = m.anonymous_user_id
    end if
    action.callFunc("fireEvent", params)
end function

function Clamp(value, minVal, maxVal)
    if value < minVal
        return minVal
    else if value > maxVal
        return maxVal
    else
        return value
    end if
end function

function NormalizePercentages(percentages)
    adjustedPercentages = []
    total = 0
    for i = 0 to percentages.Count() - 1
        p = percentages[i]
        if p <= 0.2
            adjustedPercentages.Push(0.2)
        else
            newP = p * 0.9
            if newP <= 0.2
                adjustedPercentages.Push(0.2)
            else
                adjustedPercentages.Push(newP)
            end if
        end if
        total = total + adjustedPercentages[i]
    end for
    if total <= 1.0
        return adjustedPercentages
    end if
    return NormalizePercentages(adjustedPercentages)
end function

function getButtonWidths(label1, label2, label3, modalWidth)
    buttonList = []
    if label1 <> invalid and len(label1) > 0 then buttonList.Push(label1)
    if label2 <> invalid and len(label2) > 0 then buttonList.Push(label2)
    if label3 <> invalid and len(label3) > 0 then buttonList.Push(label3)
    totalWidth = 0
    for each button in buttonList
        totalWidth = totalWidth + len(button)
    end for
    buttonPercentages = []
    for each button in buttonList
        buttonPercentages.Push(len(button) / totalWidth)
    end for

    outputPercentages = []
    numButtons = buttonPercentages.Count()
    if numButtons = 1
        outputPercentages.Push(Clamp(buttonPercentages[0], 0.2, 0.45))
    else if numButtons = 2
        outputPercentages.Push(Clamp(buttonPercentages[0], 0.2, 0.45))
        outputPercentages.Push(Clamp(buttonPercentages[1], 0.2, 0.45))
    else if numButtons = 3
        lessThan20Percent = 0
        greatThan20Percent = 0
        for each percentage in buttonPercentages
            if percentage <= 0.2
                lessThan20Percent = lessThan20Percent + 1
            else
                greatThan20Percent = greatThan20Percent + 1
            end if
        end for
        if lessThan20Percent = 3 or greatThan20Percent = 3 or lessThan20Percent = 2
            ' Case: [<=20%, <=20%, <=20%], [>=20%, >=20%, >=20%], [<=20%, <=20%, >=20%]
            outputPercentages.Push(Clamp(buttonPercentages[0], 0.2, 0.45))
            outputPercentages.Push(Clamp(buttonPercentages[1], 0.2, 0.45))
            outputPercentages.Push(Clamp(buttonPercentages[2], 0.2, 0.45))
        else
            ' Case: [<=20%, >=20%, >=20%]
            normPercentages = NormalizePercentages(buttonPercentages)
            outputPercentages.Push(Clamp(normPercentages[0], 0.2, 0.45))
            outputPercentages.Push(Clamp(normPercentages[1], 0.2, 0.45))
            outputPercentages.Push(Clamp(normPercentages[2], 0.2, 0.45))
        end if
    end if

    'print "Buttons input%: " + FormatJSON(buttonPercentages) + " >> output%: " + FormatJSON(outputPercentages)
    finalWidths = []
    for each percent in outputPercentages
        finalWidths.Push(Int(modalWidth * percent - 10))
    end for
    'print "Buttons width: " + FormatJSON(finalWidths)
    return finalWidths
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
    else if path.actions.rf_widget_height <> invalid and path.actions.rf_widget_width <> invalid
        ' bottom banner
        m.rf_settings_bg_image.width = pxToInteger(path.actions.rf_widget_width) * 1.4
        m.rf_settings_bg_image.height = pxToInteger(path.actions.rf_widget_height) * 1.4

        if path.actions.rf_widget_position <> invalid
            offsetX = 0
            offsetY = 0
            if path.actions.rf_banner_position_offset_x <> invalid
                offsetX = pxToInteger(path.actions.rf_banner_position_offset_x)
            end if
            if path.actions.rf_banner_position_offset_y <> invalid
                offsetY = pxToInteger(path.actions.rf_banner_position_offset_y)
            end if
            if path.actions.rf_widget_position = "top_center"
                offsetX = (1920 - m.rf_settings_bg_image.width) / 2
            else if path.actions.rf_widget_position = "bottom_center"
                offsetX = (1920 - m.rf_settings_bg_image.width) / 2
                offsetY = 1080 - m.rf_settings_bg_image.height - offsetY
            else if path.actions.rf_widget_position = "top_right"
                offsetX = 1920 - m.rf_settings_bg_image.width - offsetX
            else if path.actions.rf_widget_position = "bottom_right"
                offsetX = 1920 - m.rf_settings_bg_image.width - offsetX
                offsetY = 1080 - m.rf_settings_bg_image.height - offsetY
            else if path.actions.rf_widget_position = "bottom_left"
                offsetY = 1080 - m.rf_settings_bg_image.height - offsetY
            end if
            m.rf_settings_bg_image.translation = [offsetX, offsetY]
        end if

        m.rf_retention_confirm_button_text.translation = [m.rf_settings_bg_image.width - 400, 10]
        m.rf_retention_confirm_button_text.height = 55
        m.rf_retention_cancel_button_text.translation = [m.rf_settings_bg_image.width - 400, 70]
        m.rf_retention_cancel_button_text.height = 55
        m.countDown.translation = [30, m.rf_settings_bg_image.height - 35]
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
        m.rf_retention_confirm_button_text.translation = [40, m.rf_settings_bg_image.height - 200]
        m.rf_retention_accept2_button_text.translation = [420, m.rf_settings_bg_image.height - 200]
        m.rf_retention_cancel_button_text.translation = [820, m.rf_settings_bg_image.height - 200]
        m.countDown.translation = [40, m.rf_settings_bg_image.height - 100]
    end if

    m.rf_settings_bg_image.uri = path.actions.rf_settings_bg_image_roku_os_tv_composite
    m.rf_retention_confirm_button_text.label = path.actions.rf_retention_button1_text
    m.rf_retention_confirm_button_text.textColor = path.actions.button1_text_color
    m.rf_retention_confirm_button_text.textHighlightedColor = path.actions.button1_highlight_color
    m.rf_retention_confirm_button_text.bgColor = path.actions.button1_bg_color
    m.rf_retention_confirm_button_text.bgHighlightedColor = path.actions.button1_focus_bg_color
    m.rf_retention_confirm_button_text.font = m.top.fonts.ctaFont
    m.rf_retention_confirm_button_text.ObserveField("buttonSelected", "onAccept")
    if path.actions.rf_retention_button_border_color <> invalid
        m.rf_retention_confirm_button_text.buttonBorderColor = path.actions.rf_retention_button_border_color
    end if
    if path.actions.rf_retention_button_border_thickness <> invalid
        m.rf_retention_confirm_button_text.buttonBorderWidth = pxToFloat(path.actions.rf_retention_button_border_thickness)
    end if

    m.rf_retention_cancel_button_text.label = path.actions.rf_retention_button3_text
    m.rf_retention_cancel_button_text.textColor = path.actions.button3_text_color
    m.rf_retention_cancel_button_text.textHighlightedColor = path.actions.button3_highlight_color
    m.rf_retention_cancel_button_text.bgColor = path.actions.button3_bg_color
    m.rf_retention_cancel_button_text.bgHighlightedColor = path.actions.button3_focus_bg_color
    m.rf_retention_cancel_button_text.font = m.top.fonts.ctaFont
    m.rf_retention_cancel_button_text.ObserveField("buttonSelected", "onDecline")
    if path.actions.rf_settings_cancel_button_enabled <> invalid and path.actions.rf_settings_cancel_button_enabled = "true"
        m.rf_retention_cancel_button_text.visible = true
    end if
    if path.actions.rf_retention_button_border_color <> invalid
        m.rf_retention_cancel_button_text.buttonBorderColor = path.actions.rf_retention_button_border_color
    end if
    if path.actions.rf_retention_button_border_thickness <> invalid
        m.rf_retention_cancel_button_text.buttonBorderWidth = pxToFloat(path.actions.rf_retention_button_border_thickness)
    end if

    m.rf_retention_accept2_button_text.label = path.actions.rf_retention_button2_text
    m.rf_retention_accept2_button_text.textColor = path.actions.button2_text_color
    m.rf_retention_accept2_button_text.textHighlightedColor = path.actions.button2_highlight_color
    m.rf_retention_accept2_button_text.bgColor = path.actions.button2_bg_color
    m.rf_retention_accept2_button_text.bgHighlightedColor = path.actions.button2_focus_bg_color
    m.rf_retention_accept2_button_text.font = m.top.fonts.ctaFont
    if path.actions.rf_settings_confirm_button_2_enabled <> invalid and path.actions.rf_settings_confirm_button_2_enabled = "true"
        m.rf_retention_accept2_button_text.visible = true
    end if
    if path.actions.rf_retention_button_border_color <> invalid
        m.rf_retention_accept2_button_text.buttonBorderColor = path.actions.rf_retention_button_border_color
    end if
    if path.actions.rf_retention_button_border_thickness <> invalid
        m.rf_retention_accept2_button_text.buttonBorderWidth = pxToFloat(path.actions.rf_retention_button_border_thickness)
    end if

    m.rf_retention_accept2_button_text.ObserveField("buttonSelected", "onAccept2")

    if path.actions.button1_width = invalid and path.actions.button1_height = invalid and path.actions.button1_position_x = invalid and path.actions.button1_position_y = invalid
        ' auto button widths
        m.buttonRoot.width = m.rf_settings_bg_image.width
        m.buttonRoot.height = 75
        m.buttonRoot.translation = [0, m.rf_settings_bg_image.height - m.buttonRoot.height]
        widths = getButtonWidths(path.actions.rf_retention_button1_text, path.actions.rf_retention_button2_text, path.actions.rf_retention_button3_text, m.rf_settings_bg_image.width)
        m.rf_retention_confirm_button_text.width = widths[0]
        m.rf_retention_confirm_button_text.translation = [10, 15]
        if path.actions.rf_settings_confirm_button_2_enabled <> invalid and path.actions.rf_settings_confirm_button_2_enabled = "true"
            m.rf_retention_accept2_button_text.width = widths[1]
            m.rf_retention_accept2_button_text.translation = [20 + widths[0], 15]
        end if
        if path.actions.rf_settings_cancel_button_enabled <> invalid and path.actions.rf_settings_cancel_button_enabled = "true"
            if m.totalButtons = 2
                m.rf_retention_cancel_button_text.width = widths[1]
                m.rf_retention_cancel_button_text.translation = [20 + widths[0], 15]
            else
                m.rf_retention_cancel_button_text.width = widths[2]
                m.rf_retention_cancel_button_text.translation = [30 + widths[0] + widths[1], 15]
            end if
        end if
    else
        ' fixed button widths
        if path.actions.button1_width <> invalid and path.actions.button1_height <> invalid and path.actions.button1_position_x <> invalid and path.actions.button1_position_y <> invalid
            m.rf_retention_confirm_button_text.width = pxToInteger(path.actions.button1_width)
            m.rf_retention_confirm_button_text.height = pxToInteger(path.actions.button1_height)
            m.rf_retention_confirm_button_text.translation = [pxToInteger(path.actions.button1_position_x), m.rf_settings_bg_image.height - pxToInteger(path.actions.button1_position_y)]
        end if
        if path.actions.button2_width <> invalid and path.actions.button2_height <> invalid and path.actions.button2_position_x <> invalid and path.actions.button2_position_y <> invalid
            m.rf_retention_accept2_button_text.width = pxToInteger(path.actions.button2_width)
            m.rf_retention_accept2_button_text.height = pxToInteger(path.actions.button2_height)
            m.rf_retention_accept2_button_text.translation = [pxToInteger(path.actions.button2_position_x), m.rf_settings_bg_image.height - pxToInteger(path.actions.button2_position_y)]
        end if
        if path.actions.button3_width <> invalid and path.actions.button3_height <> invalid and path.actions.button3_position_x <> invalid and path.actions.button3_position_y <> invalid
            m.rf_retention_cancel_button_text.width = pxToInteger(path.actions.button3_width)
            m.rf_retention_cancel_button_text.height = pxToInteger(path.actions.button3_height)
            m.rf_retention_cancel_button_text.translation = [pxToInteger(path.actions.button3_position_x), m.rf_settings_bg_image.height - pxToInteger(path.actions.button3_position_y)]
        end if
    end if

    buildButtonRows()
    if m.buttonRows.count() > 0 and m.buttonRows[0].count() > 0
        focusButton(m.buttonRows[0][0])
    end if

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
        m.rf_retention_confirm_button_text.setFocus(true)
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

' Hide every CTA (and the timer) once any button is clicked, matching web behavior
sub hideCtaButtons()
    m.interacted = true
    m.countDown.visible = false
    btnNodes = [m.rf_retention_confirm_button_text, m.rf_retention_accept2_button_text, m.rf_retention_cancel_button_text]
    for each btn in btnNodes
        btn.visible = false
        btn.enabled = false
    end for
    m.top.setFocus(true)
end sub

sub onAccept()
    if (m.timer <> invalid)
        m.timer.unobserveField("fire")
        m.timer.control = "stop"
    end if
    hideCtaButtons()

    callApi({ event: "goal", pathId: m.currentPath.id, actionGroupId: m.currentPath.action_group_id })
    m.localStorage.createNewOverlayKey(m.currentPath.id, m.currentPath.actions.rf_settings_accept_interval)
    m.top.result = preparePromptResult({
        code: m.result.button1,
        roku: m.currentPath.actions.rf_settings_roku_product_id,
        deeplink: parseKeyValuePair(m.currentPath.actions.rf_settings_deeplink),
        meta: m.currentPath.actions.rf_metadata
    }, m.currentPath)
end sub

sub onAccept2()
    if (m.timer <> invalid)
        m.timer.unobserveField("fire")
        m.timer.control = "stop"
    end if
    hideCtaButtons()
    callApi({ event: "goal", pathId: m.currentPath.id, actionGroupId: m.currentPath.action_group_id, accept_type: "accept2" })
    m.localStorage.createNewOverlayKey(m.currentPath.id, m.currentPath.actions.rf_settings_accept_interval)
    m.top.result = preparePromptResult({
        code: m.result.button2,
        roku: m.currentPath.actions.rf_settings_roku_product_id,
        deeplink: parseKeyValuePair(m.currentPath.actions.rf_settings_deeplink),
        meta: m.currentPath.actions.rf_metadata
    }, m.currentPath)
end sub

sub onDecline()
    if (m.timer <> invalid)
        m.timer.unobserveField("fire")
        m.timer.control = "stop"
    end if
    hideCtaButtons()
    callApi({ event: "dismiss", pathId: m.currentPath.id, actionGroupId: m.currentPath.action_group_id, reason: "decline" })
    m.localStorage.createNewOverlayKey(m.currentPath.id, m.currentPath.actions.rf_settings_decline_interval)
    m.top.result = preparePromptResult({
        code: m.result.button3,
        roku: m.currentPath.actions.rf_settings_roku_product_id,
        meta: m.currentPath.actions.rf_metadata
    }, m.currentPath)
end sub

sub buildButtonRows()
    ROW_TOLERANCE = 30
    btnNodes = [m.rf_retention_confirm_button_text, m.rf_retention_accept2_button_text, m.rf_retention_cancel_button_text]

    visible = []
    for i = 0 to 2
        if btnNodes[i].visible
            visible.push({ idx: i, x: btnNodes[i].translation[0], y: btnNodes[i].translation[1] })
        end if
    end for

    rowYValues = []
    for each btn in visible
        isNew = true
        for each ry in rowYValues
            if Abs(ry - btn.y) < ROW_TOLERANCE
                isNew = false
                exit for
            end if
        end for
        if isNew
            rowYValues.push(btn.y)
        end if
    end for

    rn = rowYValues.count()
    for i = 0 to rn - 2
        for j = 0 to rn - 2 - i
            if rowYValues[j] > rowYValues[j + 1]
                tmp = rowYValues[j]
                rowYValues[j] = rowYValues[j + 1]
                rowYValues[j + 1] = tmp
            end if
        end for
    end for

    m.buttonRows = []
    for each ry in rowYValues
        rowBtns = []
        for each btn in visible
            if Abs(btn.y - ry) < ROW_TOLERANCE
                rowBtns.push(btn)
            end if
        end for

        rb = rowBtns.count()
        for i = 0 to rb - 2
            for j = 0 to rb - 2 - i
                if rowBtns[j].x > rowBtns[j + 1].x
                    tmp = rowBtns[j]
                    rowBtns[j] = rowBtns[j + 1]
                    rowBtns[j + 1] = tmp
                end if
            end for
        end for

        row = []
        for each btn in rowBtns
            row.push(btn.idx)
        end for
        m.buttonRows.push(row)
    end for

    m.currentRow = 0
    m.currentColPerRow = []
    for each row in m.buttonRows
        m.currentColPerRow.push(0)
    end for
end sub

sub focusButton(idx as integer)
    if idx = 0
        m.rf_retention_confirm_button_text.setFocus(true)
    else if idx = 1
        m.rf_retention_accept2_button_text.setFocus(true)
    else
        m.rf_retention_cancel_button_text.setFocus(true)
    end if
end sub

function onKeyEvent(key as string, pressed as boolean) as boolean
    if not pressed
        return false
    end if

    ' After a CTA click the prompt is closing - swallow the keys the prompt
    ' owns so hidden buttons can't regain focus and back can't fire a second
    ' dismiss; any other key keeps bubbling to the app as before
    if m.interacted
        return key = "left" or key = "right" or key = "up" or key = "down" or key = "back" or key = "OK"
    end if

    if key = "left" or key = "right" or key = "up" or key = "down"
        row = m.buttonRows[m.currentRow]
        col = m.currentColPerRow[m.currentRow]

        if key = "left"
            if col > 0
                col = col - 1
                m.currentColPerRow[m.currentRow] = col
                focusButton(row[col])
            end if
        else if key = "right"
            if col < row.count() - 1
                col = col + 1
                m.currentColPerRow[m.currentRow] = col
                focusButton(row[col])
            end if
        else if key = "up"
            if m.currentRow > 0
                m.currentRow = m.currentRow - 1
                newRow = m.buttonRows[m.currentRow]
                newCol = m.currentColPerRow[m.currentRow]
                if newCol >= newRow.count()
                    newCol = newRow.count() - 1
                end if
                m.currentColPerRow[m.currentRow] = newCol
                focusButton(newRow[newCol])
            end if
        else if key = "down"
            if m.currentRow < m.buttonRows.count() - 1
                m.currentRow = m.currentRow + 1
                newRow = m.buttonRows[m.currentRow]
                newCol = m.currentColPerRow[m.currentRow]
                if newCol >= newRow.count()
                    newCol = newRow.count() - 1
                end if
                m.currentColPerRow[m.currentRow] = newCol
                focusButton(newRow[newCol])
            end if
        end if
        return true
    else if key = "back"
        if m.timer <> invalid
            m.timer.control = "stop"
        end if
        callApi({ event: "dismiss", pathId: m.currentPath.id, actionGroupId: m.currentPath.action_group_id, reason: "dismiss" })
        m.localStorage.createNewOverlayKey(m.currentPath.id, m.currentPath.actions.rf_settings_dismiss_interval)
        m.top.result = preparePromptResult({
            code: m.result.dismissed,
            meta: m.currentPath.actions.rf_metadata
        }, m.currentPath)
        return true
    end if
    return false
end function
