' Full-screen devtools panel for the Redflix demo channel, mirroring the
' debug menus already added to the Apple and React Native Redfast SDKs:
'   - SDK config (appId/userId/environment overrides, save & restart)
'   - list + fire configured prompts
'   - inline zone preview
'   - simulate a screen/button trigger
'   - "blank screen" preview (identical to simulating a screen trigger here,
'     since this panel is already its own blank canvas - unlike the iOS/RN
'     demo apps, there's no separate host screen to route around)
' Opened from RedflixMain via the remote's Options key; closed with Back.

sub init()
    m.promoMgr = m.top.GetScene().findNode("promoMgr")
    m.statusLabel = m.top.findNode("status")
    m.promptListRoot = m.top.findNode("promptListRoot")
    m.promptRenderRoot = m.top.findNode("promptRenderRoot")

    m.devAppId = m.top.findNode("devAppId")
    m.devUserId = m.top.findNode("devUserId")
    m.devEnv = m.top.findNode("devEnv")
    m.devSave = m.top.findNode("devSave")
    m.devClear = m.top.findNode("devClear")
    m.devRefresh = m.top.findNode("devRefresh")
    m.devShowById = m.top.findNode("devShowById")
    m.devInlinePreview = m.top.findNode("devInlinePreview")
    m.devFireScreen = m.top.findNode("devFireScreen")
    m.devFireButton = m.top.findNode("devFireButton")
    m.devBlankScreen = m.top.findNode("devBlankScreen")

    m.settings = LoadDevSettings()

    m.devSave.label = "Save and restart"
    m.devClear.label = "Clear overrides"
    m.devRefresh.label = "Refresh prompt list"
    m.devShowById.label = "Show prompt by id"
    m.devInlinePreview.label = "Inline preview (zone id)"
    m.devFireScreen.label = "Fire screenChanged"
    m.devFireButton.label = "Fire buttonClicked"
    m.devBlankScreen.label = "Open blank screen"

    m.staticRowsTop = [m.devAppId, m.devUserId, m.devEnv, m.devSave, m.devClear, m.devRefresh]
    m.staticRowsBottom = [m.devShowById, m.devInlinePreview, m.devFireScreen, m.devFireButton, m.devBlankScreen]
    m.promptRows = []
    m.promptData = []
    m.rows = []
    m.focusedIndex = 0
    m.pendingAction = ""

    for each row in m.staticRowsTop
        row.observeField("buttonSelected", "onRowActivated")
    end for
    for each row in m.staticRowsBottom
        row.observeField("buttonSelected", "onRowActivated")
    end for

    ' Whenever a prompt we fired reports a terminal result (button/dismiss/
    ' timeout/holdout/suppressed/etc.), reclaim focus onto our own row list -
    ' otherwise the panel is left with no focused node once the dialog
    ' removes itself, and remote input stops being delivered anywhere.
    m.promoMgr.observeField("result", "onPromptResultChanged")

    updateLabels()
    refreshPrompts()
end sub

sub onPromptResultChanged()
    result = m.promoMgr.result
    if result = invalid then return
    if result.code = 100 then return ' impression - the dialog is still opening
    if m.rows.count() > 0
        m.rows[m.focusedIndex].setFocus(true)
    end if
end sub

function onKeyEvent(key as string, pressed as boolean) as boolean
    if pressed
        if key = "up"
            moveFocus(-1)
            return true
        else if key = "down"
            moveFocus(1)
            return true
        else if key = "back"
            m.promoMgr.unobserveField("result")
            m.top.closed = true
            return true
        end if
    end if
    return false
end function

sub moveFocus(delta as integer)
    if m.rows.count() = 0 then return
    m.focusedIndex = m.focusedIndex + delta
    if m.focusedIndex < 0 then m.focusedIndex = 0
    if m.focusedIndex >= m.rows.count() then m.focusedIndex = m.rows.count() - 1
    m.rows[m.focusedIndex].setFocus(true)
end sub

sub rebuildRowIndex()
    m.rows = []
    m.rows.Append(m.staticRowsTop)
    m.rows.Append(m.promptRows)
    m.rows.Append(m.staticRowsBottom)
    if m.focusedIndex >= m.rows.count() then m.focusedIndex = m.rows.count() - 1
    if m.focusedIndex < 0 then m.focusedIndex = 0
    if m.rows.count() > 0 then m.rows[m.focusedIndex].setFocus(true)
end sub

sub setStatus(text as string)
    m.statusLabel.text = text
    print "Rf DevTools: " + text
end sub

sub updateLabels()
    appIdText = m.settings.appIdOverride
    if appIdText = invalid or appIdText = ""
        appIdText = "(default: " + DefaultDevAppId() + ")"
    end if
    m.devAppId.label = "App ID override: " + appIdText

    userIdText = m.settings.userIdOverride
    if userIdText = invalid or userIdText = ""
        userIdText = "(default: " + DefaultDevUserId() + ")"
    end if
    m.devUserId.label = "User ID override: " + userIdText

    m.devEnv.label = "Environment: " + m.settings.environment + "  (OK to toggle)"
end sub

function pathTypeLabel(t as integer) as string
    pt = PathType()
    if t = pt.modal then return "MODAL"
    if t = pt.interstitial then return "INTERSTITIAL"
    if t = pt.bottomBanner then return "BOTTOM_BANNER"
    if t = pt.horizontal then return "HORIZONTAL"
    if t = pt.video then return "VIDEO"
    return "TYPE " + t.toStr()
end function

sub refreshPrompts()
    m.promptListRoot.removeChildren(m.promptListRoot.getChildren(-1, 0))
    m.promptRows = []
    m.promptData = []

    prompts = m.promoMgr.callFunc("getPrompts", { pathType: -1 })
    maxRows = 8
    count = prompts.count()
    if count > maxRows then count = maxRows

    for ii = 0 to count - 1
        p = prompts[ii]
        row = createObject("roSGNode", "CtaButton")
        row.width = 900
        row.height = 36
        row.translation = [0, ii * 40]
        row.textColor = "#c0c0c0"
        row.textHighlightedColor = "#ffffff"
        row.bgColor = "#101418"
        row.bgHighlightedColor = "#333333"
        row.label = "[" + pathTypeLabel(p.type) + "] " + p.pathItem.name + "  (" + p.id + ")"
        row.observeField("buttonSelected", "onRowActivated")
        m.promptListRoot.appendChild(row)
        m.promptRows.push(row)
        m.promptData.push(p)
    end for

    if prompts.count() > maxRows
        setStatus("Loaded " + count.toStr() + " of " + prompts.count().toStr() + " prompts (showing first " + maxRows.toStr() + ")")
    else
        setStatus("Loaded " + count.toStr() + " prompts")
    end if

    rebuildRowIndex()
end sub

sub onRowActivated()
    idx = m.focusedIndex
    topCount = m.staticRowsTop.count()
    promptCount = m.promptRows.count()
    if idx < topCount
        onTopRowActivated(idx)
    else if idx < topCount + promptCount
        onPromptRowActivated(idx - topCount)
    else
        onBottomRowActivated(idx - topCount - promptCount)
    end if
end sub

sub onTopRowActivated(idx as integer)
    if idx = 0
        openTextDialog("Override App ID (blank = default)", m.settings.appIdOverride, "appId")
    else if idx = 1
        openTextDialog("Override User ID (blank = default)", m.settings.userIdOverride, "userId")
    else if idx = 2
        toggleEnvironment()
    else if idx = 3
        saveAndRestart()
    else if idx = 4
        clearOverrides()
    else if idx = 5
        refreshPrompts()
    end if
end sub

sub onPromptRowActivated(idx as integer)
    prompt = m.promptData[idx]
    pt = PathType()
    zoneId = prompt.actions.rf_settings_zone_id
    if prompt.type = pt.horizontal and zoneId <> invalid and zoneId <> ""
        showInlinePreview(zoneId)
    else
        m.promptRenderRoot.removeChildren(m.promptRenderRoot.getChildren(-1, 0))
        m.promoMgr.callFunc("showPrompt", { root: m.promptRenderRoot, prompt: prompt })
        setStatus("Firing prompt: " + prompt.pathItem.name)
    end if
end sub

sub onBottomRowActivated(idx as integer)
    if idx = 0
        openTextDialog("Show prompt by id", "", "showById")
    else if idx = 1
        openTextDialog("Inline preview: zone id", "", "inlinePreview")
    else if idx = 2
        openTextDialog("Fire screenChanged: screen name", "", "fireScreen")
    else if idx = 3
        openTextDialog("Fire buttonClicked: button/click id", "", "fireButton")
    else if idx = 4
        openTextDialog("Open blank screen: screen name", "", "blankScreen")
    end if
end sub

sub openTextDialog(title as string, initialText as string, action as string)
    m.pendingAction = action
    dialog = createObject("roSGNode", "KeyboardDialog")
    dialog.title = title
    dialog.text = initialText
    dialog.buttons = ["OK", "CANCEL"]
    dialog.observeField("buttonSelected", "onTextDialogResult")
    m.top.GetScene().dialog = dialog
end sub

sub onTextDialogResult()
    dialog = m.top.GetScene().dialog
    if dialog.buttonSelected = 0
        text = dialog.text
        action = m.pendingAction
        dialog.close = true
        if action = "appId"
            m.settings.appIdOverride = text.Trim()
            updateLabels()
            setStatus("App ID override set (Save and restart to apply)")
        else if action = "userId"
            m.settings.userIdOverride = text.Trim()
            updateLabels()
            setStatus("User ID override set (Save and restart to apply)")
        else if action = "showById"
            showPromptById(text)
        else if action = "inlinePreview"
            showInlinePreview(text)
        else if action = "fireScreen"
            fireScreenChanged(text)
        else if action = "fireButton"
            fireButtonClicked(text)
        else if action = "blankScreen"
            fireScreenChanged(text)
        end if
    else
        dialog.close = true
    end if
end sub

sub toggleEnvironment()
    if m.settings.environment = "production"
        m.settings.environment = "staging"
    else
        m.settings.environment = "production"
    end if
    updateLabels()
    setStatus("Environment set to " + m.settings.environment + " (Save and restart to apply)")
end sub

sub saveAndRestart()
    SaveDevSettings(m.settings)
    appId = EffectiveAppId(m.settings)
    userId = EffectiveUserId(m.settings)
    m.promoMgr.callFunc("applyOverrides", {
        appId: appId,
        userId: userId,
        environment: m.settings.environment
    })
    setStatus("Restarted SDK with appId=" + appId + ", userId=" + userId + ", env=" + m.settings.environment)
end sub

sub clearOverrides()
    m.settings = { appIdOverride: "", userIdOverride: "", environment: "production" }
    SaveDevSettings(m.settings)
    updateLabels()
    m.promoMgr.callFunc("applyOverrides", {
        appId: DefaultDevAppId(),
        userId: DefaultDevUserId(),
        environment: "production"
    })
    setStatus("Overrides cleared, restarted with defaults")
end sub

sub showPromptById(id as string)
    id = id.Trim()
    if id = "" then return
    prompt = m.promoMgr.callFunc("getPrompt", { pathId: id })
    if prompt = invalid
        setStatus("No prompt found with id " + id)
        return
    end if
    m.promptRenderRoot.removeChildren(m.promptRenderRoot.getChildren(-1, 0))
    m.promoMgr.callFunc("showPrompt", { root: m.promptRenderRoot, prompt: prompt })
    setStatus("Showing prompt " + id)
end sub

sub showInlinePreview(zoneId as string)
    zoneId = zoneId.Trim()
    if zoneId = "" then return
    m.promptRenderRoot.removeChildren(m.promptRenderRoot.getChildren(-1, 0))
    inline = m.promoMgr.callFunc("showInline", { root: m.promptRenderRoot, type: zoneId, scale: "scaleToFill" })
    if inline = invalid
        setStatus("No inline prompt found for zone " + zoneId)
    else
        setStatus("Showing inline zone " + zoneId)
    end if
end sub

sub fireScreenChanged(screenName as string)
    screenName = screenName.Trim()
    if screenName = "" then return
    m.promptRenderRoot.removeChildren(m.promptRenderRoot.getChildren(-1, 0))
    m.promoMgr.callFunc("onScreenChanged", { root: m.promptRenderRoot, screenName: screenName })
    setStatus("Fired onScreenChanged(" + screenName + ")")
end sub

sub fireButtonClicked(buttonId as string)
    buttonId = buttonId.Trim()
    if buttonId = "" then return
    m.promptRenderRoot.removeChildren(m.promptRenderRoot.getChildren(-1, 0))
    m.promoMgr.callFunc("onButtonClicked", { root: m.promptRenderRoot, id: buttonId })
    setStatus("Fired onButtonClicked(" + buttonId + ")")
end sub
