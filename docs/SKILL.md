# Recurly Engage Roku SDK — Integration Skill

This document teaches AI assistants how to help developers integrate the Recurly Engage SDK into a Roku SceneGraph channel. It is grounded in the live demo integration in `components/libRedflix/` and the API reference in `docs/api.md`.

---

## Architecture in one sentence

`PromptManager` lives on the root `Scene` node. Every screen in the app finds it by id (`GetScene().findNode("promoMgr")`), observes its `result` field for callbacks, and calls its functions via `callFunc`.

---

## Step 1 — Place PromptManager in the root Scene XML

`PromptManager` must be a direct child of the root `Scene` component so that any descendant screen can locate it with `GetScene().findNode("promoMgr")`.

```xml
<!-- components/MainScene.xml -->
<component name="MainScene" extends="Scene">
    <script type="text/brightscript" uri="pkg:/components/MainScene.brs" />
    <children>
        <PromptManager id="promoMgr" />
        <Group id="sceneStack" />
    </children>
</component>
```

> See: [components/MainScene.xml](components/MainScene.xml)

---

## Step 2 — Initialize the SDK in the root Scene BRS

In the scene's `init()`, find the manager, call `initPrompts`, and observe `result` to know when the SDK is ready. Only load your first screen **after** the SDK signals initialized — this ensures prompts are available on the very first screen.

```brightscript
' components/MainScene.brs
sub init()
    m.promoMgr = m.top.GetScene().findNode("promoMgr")
    print m.promoMgr.callFunc("getVersion")   ' optional: log SDK version

    ' Optional: custom fonts for CTA buttons and countdown timers
    ctaF = CreateObject("roSGNode", "Font")
    ctaF.uri = "pkg:/fonts/Roboto-Regular.ttf"
    ctaF.size = 20
    timeoutF = CreateObject("roSGNode", "Font")
    timeoutF.uri = "pkg:/fonts/Roboto-Regular.ttf"
    timeoutF.size = 20

    m.promoMgr.observeField("result", "onInitialized")
    m.promoMgr.callFunc("initPrompts", {
        appId: "YOUR-APP-ID",
        userId: "user-123",
        anonymousUserId: "anon-uuid",
        ctaFont: ctaF,
        timeoutFont: timeoutF
    })
end sub

sub onInitialized()
    m.promoMgr.unobserveField("result")   ' stop listening for init signal
    m.sceneStack = m.top.findNode("sceneStack")
    scene = createObject("RoSGNode", "YourFirstScreen")
    m.sceneStack.appendChild(scene)
end sub
```

> See: [components/MainScene.brs](components/MainScene.brs)

Key points:
- `unobserveField("result")` in `onInitialized` is essential — it prevents the scene-level handler from firing on every subsequent prompt interaction.
- `appId` is the only required argument to `initPrompts`; all others are optional.

---

## Step 3 — Find the manager in child screens

Every screen that uses the SDK should resolve `promoMgr` in its own `init()`:

```brightscript
sub init()
    m.promoMgr = m.top.GetScene().findNode("promoMgr")
    m.promoMgr.observeField("result", "onPromptResult")
    ' ... rest of screen init
end sub
```

Register `observeField` **before** calling any SDK function so you never miss a result.

> See: [components/libRedflix/RedflixMain.brs:2-3](components/libRedflix/RedflixMain.brs#L2-L3)

---

## Step 4 — Track screen navigation

Call `onScreenChanged` whenever the user enters a screen. Pass `root` (the visible root node of the current screen) and a `screenName` string that matches trigger configuration in the Recurly Engage console.

```brightscript
m.promoMgr.callFunc("onScreenChanged", {root: m.viewRoot, screenName: "home"})
```

> See: [components/libRedflix/RedflixMain.brs:116](components/libRedflix/RedflixMain.brs#L116)

The `root` node is used as the mounting point when the SDK needs to render a modal over the current screen. It is typically the top-level `Group` or `Rectangle` node of the screen component — find it with `m.top.findNode("root")` or just pass `m.top` directly.

---

## Step 5 — Track button clicks

Call `onButtonClicked` when the user presses a significant button. If a prompt is configured to trigger on that click, the SDK will display it automatically.

```brightscript
sub onSomeButtonPressed()
    m.promoMgr.callFunc("onButtonClicked", {root: m.viewRoot, id: "interstitial"})
end sub
```

> See: [components/libRedflix/RedflixMain.brs:151](components/libRedflix/RedflixMain.brs#L151)

`id` is an optional button identifier that maps to trigger rules in the Recurly Engage console. Omit it if you only need screen-level triggers.

Note: a prior `onScreenChanged` call is required if the prompt trigger is scoped to both a screen name **and** a button click.

---

## Step 6 — Show an inline banner

Inline prompts render inside a node you provide (typically a `Rectangle` or `Group` sized for the banner).

```xml
<!-- In your screen XML -->
<Rectangle id="hzBannerRoot" width="1920" height="130" />
```

```brightscript
' In your screen BRS
m.bannerRoot = m.top.findNode("hzBannerRoot")
zoneIds = ZoneType()   ' from consts.brs
m.inline = m.promoMgr.callFunc("showInline", {
    root: m.bannerRoot,
    type: zoneIds.rokuHorizontal,   ' or a zone id string from the console
    scale: "scaleToFill"            ' "scaleToFit" | "scaleToFill" | "scaleToZoom" | "noScale"
})
if m.inline <> invalid
    m.inline.observeField("result", "onInlineResult")
    m.inline.setFocus(true)
end if
```

> See: [components/libRedflix/RedflixMain.brs:51-57](components/libRedflix/RedflixMain.brs#L51-L57)

`showInline` returns the created `PromptInline` node, or `invalid` if no eligible prompt exists. Always null-check before calling methods on it or setting focus.

---

## Step 7 — Show a prompt manually (by pathId)

Use `getPrompt` + `showPrompt` when you want to trigger a specific prompt without relying on screen/click triggers.

```brightscript
prompt = m.promoMgr.callFunc("getPrompt", {pathId: "your-path-id-uuid"})
m.promoMgr.callFunc("showPrompt", {root: m.viewRoot, prompt: prompt})
```

> See: [components/libRedflix/RedflixMain.brs:130-134](components/libRedflix/RedflixMain.brs#L130-L134)

To query multiple prompts without a specific pathId:
```brightscript
' All prompts of any type
prompts = m.promoMgr.callFunc("getPrompts", {pzType: -1})

' Only prompts triggerable on a given screen + button
prompts = m.promoMgr.callFunc("getTriggerablePrompts", {
    pzType: -1,
    screenName: "home",
    clickId: "interstitial"
})
```

---

## Step 8 — Handle prompt results

All prompt interactions (impression, button clicks, dismiss, timeout) are delivered via the `result` field on `promoMgr`. Use `observeField("result", "yourCallback")` to receive them.

```brightscript
sub onPromptResult()
    result = m.promoMgr.result
    print "code = " + result.code.toStr()

    ' Send to your analytics pipeline
    sendAnalytics(result)

    ' Trigger Roku Pay IAP if the prompt specifies a SKU
    if result.roku <> invalid and result.roku <> ""
        m.promoMgr.observeField("iapResult", "onIapComplete")
        m.promoMgr.callFunc("purchaseIap", {sku: result.roku, qty: 1})
    else
        ' Return focus to the appropriate node
        if m.modal.visible
            m.detail.setFocus(true)
        else
            m.home.setFocus(true)
        end if
    end if
end sub

sub onIapComplete()
    m.promoMgr.unobserveField("iapResult")
    print m.promoMgr.iapResult
    m.home.setFocus(true)
end sub
```

> See: [components/libRedflix/RedflixMain.brs:296-316](components/libRedflix/RedflixMain.brs#L296-L316)

### Result codes (from `consts.brs`)

| Code | Meaning |
|------|---------|
| 1 | ok / initialized |
| 100 | impression |
| 101 | button1 clicked |
| 102 | button2 clicked |
| 103 | button3 clicked |
| 110 | dismissed |
| 111 | timer expired |
| 120 | holdout |
| -100 | error |
| -101 | notApplicable |
| -102 | disabled |
| -103 | suppressed |

### PromptResult fields

```
result.code          ' interaction code (integer)
result.roku          ' IAP SKU string, if configured (may be invalid)
result.promptMeta    ' object: promptName, promptID, promptType,
                     '         promptVariationName, promptVariationID,
                     '         promptExperimentName, promptExperimentID,
                     '         buttonLabel
result.extra.meta    ' device metadata key-value pairs from the console
result.extra.deeplink ' deeplink object if configured
```

### Extracting analytics metadata

```brightscript
sub sendAnalytics(promptResult as object)
    if promptResult.promptMeta <> invalid
        experiment = promptResult.promptMeta
        ' experiment.promptName, experiment.promptID, etc.
        ' sendData(experiment)
    end if
end sub
```

> See: [components/libRedflix/RedflixMain.brs:318-326](components/libRedflix/RedflixMain.brs#L318-L326)

---

## Step 9 — Send custom tracking events

```brightscript
m.promoMgr.callFunc("customTrack", {customFieldId: "home"})
```

> See: [components/libRedflix/RedflixMain.brs:117](components/libRedflix/RedflixMain.brs#L117)

The `customFieldId` must match a tracker configured in the Recurly Engage console.

---

## Step 10 — Update userId / anonymousUserId at runtime

```brightscript
m.promoMgr.callFunc("setUserId", {userId: "new-user-id"})
m.promoMgr.callFunc("setAnonymousUserId", {userId: "new-anon-id"})
```

Prompts for the updated user become available within a few seconds after this call.

---

## Step 11 — Enable / disable the SDK

```brightscript
m.promoMgr.callFunc("enablePrompts", {enabled: false})  ' pause
m.promoMgr.callFunc("enablePrompts", {enabled: true})   ' resume
```

---

## Step 12 — Add the debug view (development only)

Add to your screen XML:
```xml
<DebugView id="debugView" />
```

Wire it up in BRS:
```brightscript
m.debugView = m.top.findNode("debugView")

function onKeyEvent(key as string, pressed as boolean) as boolean
    m.debugView.callFunc("onKeyDetection", {key: key, screen: m.top})
    ' ... rest of key handling
end function
```

Press `*` on the remote to open the debug overlay (set userId, reset goals).

---

## Common mistakes to avoid

1. **Observing `result` before `unobserveField` in `onInitialized`** — the scene-level handler fires on every prompt interaction, not just initialization. Always `unobserveField` after the SDK is ready.

2. **Not null-checking `showInline` return value** — `showInline` returns `invalid` when no eligible prompt exists. Calling `setFocus(invalid)` will crash.

3. **Calling `onButtonClicked` without a prior `onScreenChanged`** — if the trigger rule is scoped to a screen, the button click alone won't fire it.

4. **Setting focus before `showInline` result is checked** — the demo conditionally sets focus to either `m.inline` or `m.home` depending on whether inline is `invalid`:
   ```brightscript
   if m.inline = invalid
       m.home.setFocus(true)
   else
       m.inline.setFocus(true)
   end if
   ```
   > See: [components/libRedflix/RedflixMain.brs:110-114](components/libRedflix/RedflixMain.brs#L110-L114)

5. **Multiple `observeField` registrations on the same field** — in BrightScript, calling `observeField` twice on the same field/callback pair registers duplicate listeners. Register once per screen lifecycle, or `unobserveField` first.

---

## Supported prompt types

| Prompt type | `PathType()` constant | pzType value |
|---|---|---|
| Modal | `pathType.modal` | 2 |
| Horizontal (inline) | `pathType.horizontal` | 5 |
| Video | `pathType.video` | 6 |
| Interstitial | `pathType.interstitial` | 10 |
| Bottom banner | `pathType.bottomBanner` | 13 |

---

## Key files reference

| File | Purpose |
|---|---|
| [components/MainScene.xml](components/MainScene.xml) | Root scene — where `PromptManager` is declared |
| [components/MainScene.brs](components/MainScene.brs) | SDK initialization and first-screen bootstrap |
| [components/libRedflix/RedflixMain.brs](components/libRedflix/RedflixMain.brs) | Full integration example: inline, modal, interstitial, IAP |
| [components/engage/consts.brs](components/engage/consts.brs) | Result codes, path types, zone types, utilities |
| [components/engage/PromptManager.brs](components/engage/PromptManager.brs) | SDK core — all callable functions |
| [docs/api.md](docs/api.md) | Official API reference |
