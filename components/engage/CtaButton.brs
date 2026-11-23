' Copyright (C) 2023 Recurly, Inc - All Rights Reserved
'
' Must not be copied and/or distributed without the express
' permission of Recurly, Inc

sub init()
    m.buttonLabel = m.top.findNode("buttonLabel")
    m.buttonContainer = m.top.findNode("buttonContainer")
    m.buttonBorder = m.top.findNode("buttonBorder")
    m.top.observeField("width", "sizeChanged")
    m.top.observeField("height", "sizeChanged")
    m.top.observeField("focusedChild", "focusChanged")
    m.top.observeField("renderTracking", "renderStatus")
    m.top.enableRenderTracking = true
    m.top.focusable = true
    m.buttonContainer.color = m.top.bgColor
    m.buttonBorder.color = m.top.buttonBorderColor
end sub

sub renderStatus()
    if m.top.renderTracking = "full"
        m.top.unobserveField("renderTracking")
        m.buttonLabel.width = m.top.width - 20
        m.buttonLabel.height = m.top.height
    end if
end sub

sub labelChanged()
    m.buttonLabel.text = m.top.label
end sub

sub textColorChanged()
    m.buttonLabel.color = m.top.textColor
end sub

sub bgColorChanged()
    m.buttonContainer.color = m.top.bgColor
end sub

sub borderColorChanged()
    m.buttonBorder.color = m.top.buttonBorderColor
end sub

sub focusChanged()
    if m.top.hasFocus() or m.top.forceHighlighted
        m.buttonLabel.color = m.top.textHighlightedColor
        if m.top.bgHighlightedColor <> ""
            m.buttonContainer.color = m.top.bgHighlightedColor
        end if
    else
        m.buttonLabel.color = m.top.textColor
        m.buttonContainer.color = m.top.bgColor
    end if
end sub

sub fontChanged()
    m.buttonLabel.font = m.top.font
end sub

sub sizeChanged()
    border = m.top.buttonBorderWidth
    m.buttonBorder.width = m.top.width
    m.buttonBorder.height = m.top.height
    m.buttonContainer.width = m.top.width - border * 2
    m.buttonContainer.height = m.top.height - border * 2
    m.buttonContainer.translation = [border, border]
end sub

function onKeyEvent(key as string, pressed as boolean) as boolean
    if key = "OK" and pressed and m.top.enabled
        m.top.buttonSelected = true
        return true
    end if
    return false
end function