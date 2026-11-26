# Redfast SDK for Roku

Roku SceneGraph SDK for displaying promotional prompts (modals, video dialogs, inline banners) in BrightScript/Roku channels.

This repo contains two distinct pieces:
- **The SDK** — `components/redfast/` — the distributable Redfast promotion library.
- **The demo app** — everything else (`source/`, `components/MainScene`, `components/libRedflix/`) — a Netflix-like Roku channel that exercises the SDK.

## Language & Framework

- **BrightScript** (.brs) — Roku's scripting language. No semicolons, `sub`/`function`/`end sub`/`end function` blocks, `m` is the component scope (like `this`), `m.top` references the XML component node.
- **SceneGraph XML** (.xml) — Declares Roku components, their interfaces (public fields/functions), child node trees, and script imports. Each `.xml` file pairs with a `.brs` file of the same name.
- Components extend base types like `Group`, `Task`, `Node`, `Rectangle`, `Scene`.
- `<interface>` in XML defines public fields (`<field>`) and callable functions (`<function>`).
- Observer pattern: `observeField("fieldName", "callbackSub")` for async communication between components.

---

## Demo App

### source/main.brs
Entry point. Creates `roSGScreen`, instantiates `MainScene`, runs the main event loop.

### components/MainScene (.brs/.xml)
Root scene (extends `Scene`). Declares `PromotionManager` (id=`promoMgr`) and a `sceneStack` Group as children. On `init`, calls `initPromotion` with appId/userId/fonts, then observes `result` — once the SDK signals initialized, appends `RedflixMain` into `sceneStack`.

This is the **integration point**: the scene owns `PromotionManager` so all child components can find it via `GetScene().findNode("promoMgr")`.

### components/libRedflix/
The active demo UI — a fake streaming service called "Redflix".

- **RedflixMain.brs/.xml** — Main screen (extends `Group`). Three-tab nav (Home / Latest / Genres). On load: fetches movies via `RedflixApi`, calls `showInline` to render a horizontal banner in `hzBannerRoot`, builds a `RowList` of movie shelves. Tab actions demonstrate SDK integrations:
  - *Home* — item select triggers `onButtonClicked` (interstitial) and `purchaseIap` on the first row.
  - *Latest* — calls `getPrompt` by pathId then `showPrompt`.
  - *Genres* — calls `onScreenChanged` then `onButtonClicked` (wizard).
  - Handles `result` field from `PromotionManager` to react to prompt outcomes (including IAP).
- **RowDetailItem.brs/.xml** — Custom RowList item for the movie detail view. Shows either a movie metadata layout (poster + title/description/duration/director) or a full-width poster image.

### components/libContent/
Background `Task` nodes for fetching content (run on separate threads).

- **RedflixApi.brs/.xml** — Fetches movies from the Webflow CMS API (`api.webflow.com`). Used by `RedflixMain`. Returns a flat `ContentNode` tree of movies with portrait/landscape thumbnails.
- **MovieApi.brs/.xml** — Fetches movies from TMDB API (`api.themoviedb.org`). Used by `TemplateMain` (the alternate demo scene, not currently active).

---

## SDK — components/redfast/

### Core

- **PromotionManager.brs/.xml** — Central SDK controller (extends `Group`). Manages the full promotion lifecycle:
  - `initPromotion(params)` — Initializes with appId, userId, anonymousUserId, fonts, deviceType.
  - Ping loop (`updatePing`) — Periodic server pings to fetch promotion paths/configs with ETag caching and exponential backoff.
  - `onScreenChanged(params)` — Trigger-based prompt display on screen navigation.
  - `onButtonClicked(params)` — Trigger-based prompt display on button click events.
  - `getPrompt/getPrompts/getTriggerablePrompts` — Query available prompts by pathId, pathType, zoneId, screenName, clickId.
  - `showPrompt(params)` / `showInline(params)` — Programmatic prompt display.
  - `sendPromptEvent(params)` — Fire analytics events (impression, dismiss, goal, holdout, etc.).
  - IAP integration via `ChannelStore` node: `getIapItems`, `purchaseIap`, `getPuchasedItems`.
  - `customTrack`, `ping`, `setUserId`, `setAnonymousUserId`, `resetGoal`, `getMetas`, `getVersion`.
  - `setPrivacyConsentCategories(params)` / `getPrivacyConsentCategories()` — gates prompt eligibility by `PrivacyConsentCategory` (`consts.brs`); a path only matches once its `consent_categories` are an exact set match to the configured categories. Checked in `getPath`, `getInlines`, and `getPrompts`.
  - Has a `.NOIAP` variant (`PromotionManager.brs.NOIAP` / `.xml.NOIAP`) that strips IAP/billing support.

- **PromotionApi.brs/.xml** — Network layer (extends `Task` for background threading). `fireEvent(params)` sends HTTP requests to `conduit.redfast.com` for events: ping, impression, dismiss, goal, click, customTrack, resetGoal, holdout. Returns parsed JSON via `content` field.

- **consts.brs** — Shared constants and utilities:
  - `PromotionResult()` — Result/interaction codes (ok, error, button1-3, dismissed, timerExpired, holdout, etc.).
  - `PathType()` — Prompt types (invisible, modal, horizontal, video, interstitial, bottomBanner).
  - `ZoneType()` — Inline zone types (billboard, featured, roku-horizontal).
  - `DeviceType()` — Platform identifiers.
  - `parseKeyValuePair()`, `pxToInteger()`, `pxToFloat()` — Utility functions.
  - `preparePromptResult()` — Enriches result objects with prompt metadata.

- **LocalStorage.brs** — Suppression/cooldown persistence using `roRegistrySection("Redfast")`. Tracks overlay display intervals (time-based, visit-based, infinite) and holdout keys.

### UI Components

- **PromotionDialog.brs/.xml** — Modal/interstitial/bottom-banner prompt (extends `Group`). Renders a background image poster with up to 3 CTA buttons, a countdown timer, and handles accept/decline/dismiss/timeout interactions. Supports popup sizes (small/medium/large), banner positioning, auto or fixed button widths.

- **PromotionVideoDialog.brs/.xml** — Video prompt (extends `Group`). Plays a video with poster fallback, accept/decline buttons. Supports loop, controls, mute, and preload settings.

- **PromotionInline.brs/.xml** — Inline/horizontal banner (extends `Group`). Renders a poster image within a parent container, supports focus highlight and tile interaction (goal tracking on OK press).

- **CtaButton.brs/.xml** — Reusable call-to-action button (extends `Rectangle`). Supports label, colors, focus highlight, border styling, and fires `buttonSelected` on OK key press.

- **DebugView.brs/.xml** — Dev-only debug component (extends `Node`). Options key opens a keyboard dialog to change userId or reset goals.

---

## Build

- `build-sdk.sh [iap|noiap]` — Packages `components/redfast/` into `roku-sdk.zip`. Picks IAP or NOIAP variant of PromotionManager. It copies an explicit file list, so a new SDK component must be added there; `scripts/verify-sdk-zip.sh <zip>` fails if a component is missing.
- `build-demo.sh [output.zip]` — Packages the full demo app as a sideload zip (default `out/roku-demo.zip`).
- `npx brighterscript --project bsconfig.ci.json` — Compile check (syntax errors, missing component scripts, unresolved callbacks). Run by CI.

### CI (`.github/workflows/roku.yml`)

On every PR to `master`, push to `master` and manual dispatch: compile check, then builds the demo zip and both SDK zips and uploads them as artifacts (`redflix-demo-roku`, `redfast-sdk-roku-iap`, `redfast-sdk-roku-noiap`). To install the demo, enable developer mode on the Roku, open `http://<roku-ip>` and upload `roku-demo.zip` (artifacts download wrapped in an extra .zip).

---

## Key Patterns

- All SDK components include `consts.brs` and `LocalStorage.brs` via `<script>` tags (BrightScript has no module imports — scripts are concatenated per component scope).
- Async HTTP via `Task` nodes: create a `PromotionApi` node, call `fireEvent()`, observe `state` or `content` for results.
- Prompt display flow: `PromotionManager` creates a dialog node, appends it to a root Group, observes `result` field for dismiss/accept callbacks, then removes the child.
- Demo components reach the SDK via `m.top.GetScene().findNode("promoMgr")` — the `PromotionManager` lives on `MainScene` and is found by id.
- Version is hardcoded in `PromotionManager.brs:getVersion()` (currently `"1.0.44"`).
