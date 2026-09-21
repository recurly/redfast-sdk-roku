sub init()
    m.promoMgr = m.top.GetScene().findNode("promoMgr")
    print m.promoMgr.callFunc("getVersion")

    ctaF = CreateObject("roSGNode", "Font")
    ctaF.uri = "pkg:/fonts/AllProDisplayC-Bold.ttf"
    ctaF.size = 20
    timeoutF = CreateObject("roSGNode", "Font")
    timeoutF.uri = "pkg:/fonts/AllProDisplayC-Regular.ttf"
    timeoutF.size = 20

    devSettings = LoadDevSettings()
    m.promoMgr.callFunc("initPromotion", {
        appId: EffectiveAppId(devSettings),
        userId: EffectiveUserId(devSettings),
        anonymousUserId: "anon-123-roku",
        environment: devSettings.environment,
        ctaFont: ctaF,
        timeoutFont: timeoutF })
    m.promoMgr.observeField("result", "onInitialized")
end sub

sub onInitialized()
    m.promoMgr.unobserveField("result")
    m.sceneStack = m.top.findNode("sceneStack")
    scene = createObject("RoSGNode", "RedflixMain")
    m.sceneStack.appendChild(scene)
end sub

function onKeyEvent(key as string, press as boolean) as boolean
    return false
end function
