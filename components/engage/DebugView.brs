sub init()
end sub

sub onKeyDetection(params as object)
    if params.key = "options"
        m.screen = params.screen
        m.promoMgr = m.screen.GetScene().findNode("promoMgr")

        dialog = createObject("roSGNode", "KeyboardDialog")
        dialog.title = "Enter a new user id"
        dialog.text = m.promoMgr.callFunc("getUserId", {})
        dialog.buttons=["Set new user", "Reset the user", "Set consent categories", "CANCEL"]
        dialog.observeField("buttonSelected", "onKeyboardDialog")
        m.screen.GetScene().dialog = dialog
    end if
end sub

sub onKeyboardDialog()
    dialog = m.screen.GetScene().dialog
    if dialog.buttonSelected = 0
        m.promoMgr.callFunc("setUserId", {userId: dialog.text})
        m.top.needRefresh = true
    else if dialog.buttonSelected = 1
        m.promoMgr.callFunc("resetGoal", {})
        m.top.needRefresh = true
    else if dialog.buttonSelected = 2
        dialog.close = true
        showConsentCategoriesDialog()
        return
    end if
    dialog.close = true
end sub

sub showConsentCategoriesDialog()
    current = m.promoMgr.callFunc("getPrivacyConsentCategories", {})
    text = ""
    if current <> invalid
        for ii = 0 to current.count() - 1
            if ii > 0 then text += ","
            text += current[ii]
        end for
    end if

    dialog = createObject("roSGNode", "KeyboardDialog")
    dialog.title = "Consent categories (comma-separated, blank = disable filtering)"
    dialog.message = ["Valid values: strictly_necessary, performance, funcional, targeting"]
    dialog.text = text
    dialog.buttons = ["Apply", "CANCEL"]
    dialog.observeField("buttonSelected", "onConsentCategoriesDialog")
    m.screen.GetScene().dialog = dialog
end sub

sub onConsentCategoriesDialog()
    dialog = m.screen.GetScene().dialog
    if dialog.buttonSelected = 0
        text = dialog.text.Trim()
        if text = ""
            m.promoMgr.callFunc("setPrivacyConsentCategories", {categories: invalid})
        else
            rawCategories = text.Split(",")
            categories = []
            for each rawCategory in rawCategories
                categories.push(rawCategory.Trim())
            end for
            m.promoMgr.callFunc("setPrivacyConsentCategories", {categories: categories})
        end if
        m.top.needRefresh = true
    end if
    dialog.close = true
end sub