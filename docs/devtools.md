# Dev Tools — Roku

> **INTERNAL — DO NOT PUBLISH.** Engineering-only documentation for the Redflix demo channel. Dev Tools is not part of the distributable SDK (`components/redfast/`) and must never appear on the public docs site.

---

## Overview

Dev Tools is a testing panel built into the **Redflix demo channel** that lets QA and engineering exercise SDK behavior with just the remote:

- Override the SDK config (`appId`, `userId`, environment) at runtime
- Fire any configured prompt on demand (by list selection or raw path id)
- Preview inline prompts by zone id
- Simulate `onScreenChanged` / `onButtonClicked` triggers
- Preview what prompt (if any) targets an arbitrary screen name

The panel itself lives entirely in the demo app (`components/libRedflix/`); it needs a small SDK hook (`applyOverrides`, see [SDK changes](#sdk-changes)). It works identically in the IAP and NOIAP SDK variants.

---

## Accessing the panel

Press the **Options (`*`) key** on the remote while the main channel is showing — `RedflixMain.onKeyEvent` calls `openDevTools()` (ignored if the panel is already open), which:

1. Hides the main view
2. Un-observes `promoMgr.result` (so prompts fired from Dev Tools don't steal focus back to the hidden home RowList)
3. Appends a `DevToolsScreen` node to `sceneStack` and focuses it

**Back** closes the panel: it un-observes `promoMgr.result` and sets the `closed` field, and `onDevToolsClosed` removes the panel, restores the main view, re-observes `promoMgr.result` and returns focus to the inline banner (if present) or the home list. The hint line reads: *BACK to close / UP-DOWN to navigate / OK to activate*.

---

## Panel sections

`DevToolsScreen` is a full-screen `Group` over a `#101418` background — a static list of `CtaButton`s with a status label at the bottom. Navigation is `up`/`down` + OK. The panel has three headers (**SDK Config**, **Prompts**, **Simulate / Preview**); the sections below group its rows by function.

### 1. SDK Config
- **App ID override** / **User ID override** — opens a `KeyboardDialog` for text entry; blank means "use the built-in default" (`DefaultDevAppId()` / `DefaultDevUserId()`)
- **Environment** — OK toggles `production` / `staging`; the SDK picks the API base URL from it (see SDK changes)
- **Save and restart** — persists overrides and calls `applyOverrides` on the SDK
- **Clear overrides** — resets settings to defaults, saves them, and restarts the SDK with the defaults

The first three rows double as live status: their labels show the current override value or `(default: …)`. Text edits and the environment toggle only change the on-screen settings until **Save and restart**.

### 2. Show Prompt
- **Refresh prompt list** (under the *Prompts* header) — queries `promoMgr.getPrompts` with `pathType: -1` (all types) and renders up to **8** rows labeled `[TYPE] name (id)`; excess prompts are counted in the status label. The list also loads when the panel opens
- Activating a prompt row fires it via `promoMgr.showPrompt` into the panel's own render root
- A **HORIZONTAL** prompt with a non-empty `rf_settings_zone_id` opens the inline preview for that zone instead
- **Show prompt by id** — `promoMgr.getPrompt({ pathId })`, then `showPrompt`; unknown ids report in the status label

### 3. Inline Preview
- **Inline preview (zone id)** — `promoMgr.showInline({ root, type: zoneId, scale: "scaleToFill" })`; inline prompts render directly in the view hierarchy, not through triggers, so they are previewed by embedding them into the panel's render root. Reports "No inline prompt found" if the zone has none

### 4. Simulate Trigger
- **Fire screenChanged** — `promoMgr.onScreenChanged({ root, screenName })`
- **Fire buttonClicked** — `promoMgr.onButtonClicked({ root, id })`

Each opens a `KeyboardDialog` for its argument. Empty input is ignored.

### 5. Test Screen
- **Open blank screen** — identical to firing `screenChanged` here: the panel is already its own blank canvas (there is no separate host screen to route around), so this simply fires `onScreenChanged` with the given name

The green **status label** at the bottom reports every action (and mirrors it to the debug console via `print "Rf DevTools: …"`).

**In-panel rendering.** Every fired prompt renders into `promptRenderRoot`, a transparent full-screen `Rectangle` inside the panel, by passing `root:` to `showPrompt` / `onScreenChanged` / `onButtonClicked` / `showInline`; it is cleared before each action. **Focus reclamation:** when `promoMgr.result` reports any code other than 100 (impression), `onPromptResultChanged` moves focus back onto the panel's focused row. Without this, the dialog that removed itself leaves the panel with no focused node and remote input goes dead.

---

## Persistence & restart

**Persistence:** `roRegistrySection("RedflixDevTools")` via `DevSettings.brs` — `LoadDevSettings` / `SaveDevSettings` (with `Flush()`), keys `appIdOverride`, `userIdOverride`, `environment` (default `production`). This section is deliberately **separate from the SDK's own `Redfast` registry section**, so dev-tools state never mixes with suppression/cooldown/holdout data. `EffectiveAppId` / `EffectiveUserId` implement the trim-and-fall-back-to-default logic.

**Applied at launch:** `MainScene.init` loads these settings and passes the effective `appId`, `userId` and `environment` to `initPromotion`, so saved overrides survive a channel relaunch.

**Restart semantics:** **Save and restart** / **Clear overrides** call `promoMgr.applyOverrides({ appId, userId, environment })`. The SDK clears the cached actions, sets `initialPing = true`, and re-pings immediately — a hot SDK restart with the new config. No channel relaunch is needed.

---

## SDK changes

Outside the demo app, the SDK carries the hooks Dev Tools relies on (in both `PromotionManager.brs` and `PromotionManager.brs.NOIAP`, with matching `<function>` entries in both XML variants):

- `applyOverrides(params)` — applies any of `appId` / `userId` / `environment` (empty or missing values are ignored), resets `actions` and `initialPing`, and calls `updatePing()`
- `getEnvironment()` — returns the current environment
- `initPromotion` accepts an optional `environment` param (default `"production"`)
- `PromotionApi` has an `environment` field; `"staging"` selects the staging base URL, otherwise production. The URL lives only in `PromotionApi.brs`

The panel also reuses the SDK's `CtaButton` and `consts.brs` (`PathType`).

---

## File map

| File | Role |
|---|---|
| `components/libRedflix/DevToolsScreen.brs` | The panel: row list, actions, keyboard dialogs, prompt firing |
| `components/libRedflix/DevToolsScreen.xml` | Component tree (rows, headers, status label, `closed` interface field, `promptRenderRoot`) |
| `components/libRedflix/DevSettings.brs` | Registry persistence (`RedflixDevTools` section) + default/effective helpers |
| `components/libRedflix/RedflixMain.brs` | Options-key entry point (`openDevTools` / `onDevToolsClosed`) |
| `components/MainScene.brs` / `.xml` | Loads saved settings at launch and passes them to `initPromotion` |
| `components/redfast/PromotionManager.brs` (+ `.NOIAP`, XML) | `applyOverrides`, `getEnvironment`, `environment` init param |
| `components/redfast/PromotionApi.brs` / `.xml` | `environment` field selects API base URL |

SDK APIs exercised (via `callFunc` on `PromotionManager`): `getPrompts`, `getPrompt`, `showPrompt`, `showInline`, `onScreenChanged`, `onButtonClicked`, `applyOverrides`, `result` field. See [`api.md`](./api.md).

---

## Troubleshooting

- **Options key does nothing** — only handled by `RedflixMain` while the panel isn't already open; focus must be in the main channel.
- **Prompt list is empty** — it comes from `getPrompts`, which needs a completed ping; after changing config, use **Save and restart**, then **Refresh prompt list**.
- **Changes don't take effect** — App ID / User ID / Environment edits apply only after **Save and restart**.
- **Remote goes dead after a prompt** — focus is reclaimed on any non-impression `promoMgr.result`; check the debug console for `Rf DevTools:` lines.
- **Override reverts to default** — blank values fall back to the defaults; **Clear overrides** also resets the environment to `production`.
