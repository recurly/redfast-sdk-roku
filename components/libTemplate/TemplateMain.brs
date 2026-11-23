' Copyright (C) 2020 Recurly, Inc - All Rights Reserved
'
' Must not be copied and/or distributed without the express
' permission of Recurly, Inc
 
sub init()
    m.viewRoot = m.top.findNode("root")
    m.task = createObject("RoSGNode", "MovieApi")
    m.task.observeField("state", "onThreadComplete")
    m.task.callFunc("getMovies", {})
    
    m.overlayButton = m.top.findNode("accessibility-123")
    m.overlayButton.ObserveField("buttonSelected", "showOverlay")

    m.promoMgr = m.top.GetScene().findNode("promoMgr")
    m.promoMgr.observeField("result", "onModalDismissed")
    m.promoMgr.callFunc("onScreenChanged", {root: m.viewRoot, screenName: "ViewController" })
     
    m.detail = m.top.findNode("detail")
    m.currentFocus = 1
    setupBillboard()
    m.billboards.setFocus(true)
end sub

sub setupBillboard()
    billboards = m.promoMgr.callFunc("getInlines", {type: "billboard"})

    height = 450
    m.billboards = m.top.findNode("billboards")
    m.billboards.showRowLabel = [false]
    m.billboards.showRowCounter = [false]
    m.billboards.numRows = 1
    m.billboards.itemSize = [(1920 * billboards.getChildCount()), height]
    m.billboards.rowItemSize = [[1920, height]]
    m.billboards.rowFocusAnimationStyle = "fixedFocus"    
    m.billboards.content = createObject("RoSGNode", "ContentNode")
    m.billboards.content.appendChild(billboards)
    ' Trigger episode detail screen
    m.billboards.observeField("rowItemSelected", "onBillboardselected")
end sub

sub setupMovies(movies as Object)
    inlineWidth = 200
    inlineHeight = 300
    movieWidth = 160
    movieHeight = 250
    vertSpacing = 70
    movieRows = movies.getChildCount()
    m.movies = m.top.findNode("movies")
    m.movies.showRowLabel = [true]
    m.movies.showRowCounter = [false]
    m.movies.numRows = 1 + movieRows
    m.movies.rowHeights = [inlineHeight, movieHeight]
    m.movies.rowItemSize = [[inlineWidth, inlineHeight], [movieWidth, movieHeight]]
    m.movies.rowItemSpacing = [[20, 0]]
    m.movies.rowSpacings = [vertSpacing]

    featured = m.promoMgr.callFunc("getInlines", {type: "featured"})
    featured.title = "STREAM FOR FREE"
    movies.insertChild(featured, 0)
    
    m.movies.itemSize = [1920, inlineHeight + movieRows * (movieHeight + vertSpacing)]
    m.movies.content = movies
    m.movies.observeField("rowItemSelected", "onMovieSelected")
end sub

sub onThreadComplete()
    if m.task.state = "stop"
        m.task.unobserveField("state")
        if m.task.content <> invalid
            setupMovies(m.task.content)
        end if
    end if
end sub

sub showOverlay()
    m.promoMgr.callFunc("onButtonClicked", {root: m.viewRoot, id: m.overlayButton.id})
end sub

sub onBillboardselected()
    dialog = createObject("roSGNode", "ProgressDialog")
    dialog.message = "Prepare in-app purchase"
    m.top.GetScene().dialog = dialog

    m.promoMgr.observeField("iapResult", "getCatalog")
    m.promoMgr.callFunc("getIapItems", {})
end sub

sub getCatalog()
    m.promoMgr.unobserveField("iapResult")
    m.catalog = m.promoMgr.iapResult
    
    m.promoMgr.observeField("iapResult", "getPurchased")
    m.promoMgr.callFunc("getPuchasedItems", {})
end sub

sub getpurchased()
    m.promoMgr.unobserveField("iapResult")
    m.purchased = m.promoMgr.iapResult

    for ii = 0 to m.catalog.getChildCount() - 1
        item = m.catalog.getChild(ii)
        found = false
        for jj = 0 to m.purchased.getChildCount() - 1
            purchase = m.purchased.getChild(jj)
            if item.id = purchase.id
                item.description = item.description + " (purchased)"
                found = true
                exit for
            end if
        end for
        if found = false and m.purchased.getChildCount() > 0
            if item.id = "platinum"
                item.description = item.description + " (downgrade)"
            else
                item.description = item.description + " (upgrade)"
            end if
        end if
    end for
    purchaseStep1()
end sub

sub purchaseStep1()
    if m.promoMgr.iapResult.getChildCount() > 0
        dialog = createObject("roSGNode", "Dialog")
        dialog.message = "Choose an inapp item"
        items = []
        for ii = 0 to m.catalog.getChildCount() - 1
            items.push(m.catalog.getChild(ii).description)
        end for
        dialog.buttons = items
        dialog.observeField("buttonSelected", "purchaseStep2")
        m.top.GetScene().dialog = dialog
    end if
end sub

sub purchaseStep2()
    index = m.top.GetScene().dialog.buttonSelected
    item = m.catalog.getChild(index)
    m.promoMgr.observeField("iapResult", "purchaseStep3")
    m.promoMgr.callFunc("purchaseIap", {sku: item.id, qty: 1})
end sub

sub purchaseStep3()
    m.promoMgr.unobserveField("iapResult")
    print m.promoMgr.iapResult
    onMovieSelected()
end sub

sub onMovieSelected()
    m.viewRoot.visible = false
    m.detail.visible = true
    ' Example deeplink invocation code
    ' deeplink = m.promoMgr.getChildNode(0)
    ' deeplink.callFunc("performDeepLink", {mediaType: "movie", contentId: "12345"})
end sub

sub onModalDismissed()
    ' print "modal result = " + m.promoMgr.result.toStr()
    if m.promoMgr.result.value = 0 'accepted
        dialog = createObject("roSGNode", "Dialog")
        dialog.title = "Thank you"
        dialog.optionsDialog = true
        dialog.message = "You have successfully accept the offer"
        m.top.dialog = dialog

        onMovieSelected()
    end if
    m.overlayButton.setFocus(true)
end sub

function onKeyEvent(key as string, pressed as boolean) as boolean
    print key
    if pressed
        if m.viewRoot.visible = true
            if key = "up"
                if m.currentFocus > 0
                    m.currentFocus = m.currentFocus - 1
                end if
                if m.currentFocus = 0
                    m.overlayButton.setFocus(true)
                else if m.currentFocus = 1
                    m.billboards.setFocus(true)
                end if
            else if key = "down" 
                if m.currentFocus < 2
                    m.currentFocus = m.currentFocus + 1
                end if
                if m.currentFocus = 1
                    m.billboards.setFocus(true)
                else if m.currentFocus = 2
                    m.movies.setFocus(true)
                end if
            end if
        else if key = "back"
            m.viewRoot.visible = true
            m.detail.visible = false
        end if       
    end if
    return true
end function