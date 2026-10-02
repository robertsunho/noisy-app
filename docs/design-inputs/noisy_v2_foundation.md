# Noisy V2 — Strategy & Design Foundation

**Purpose of this document:** Handoff from a design/strategy conversation (Claude chat, Oct 2026) to the V2 build cycle. It captures the conclusions, the reasoning behind them, and the key pivots in the order they developed, so the implementing model has both the *what* and the *why*. Correctness work and launch blockers on the V1 codebase are already underway in a separate thread; this document defines what V2 is.

**Context:** Noisy is a Flutter/Dart ambient-sound app built by a two-person team who also run an ambient record label (Noisy Records). The commercial goal is a passive income stream to diversify streaming royalties — explicitly *not* a venture-scale outcome. The team's proven, rare asset: they have previously built streaming audiences of 30K, 50K, and 100K monthly listeners for three artists. The current Noisy project has ~200 monthly listeners whose heavy sleep-looping generates ~$500/month — a tiny but extremely high-intent funnel.

---

## 1. Technical ground truth (from the independent evaluation)

**Preserve and amplify — the crown jewel is the harmonic engine.** `HarmonicMatcher` (pure Dart: Hz↔MIDI, octave folding to ±6 st, consonant-interval best-match), triad-aware binaural carrier placement (root/P5 only, voiced into 80–300 Hz with anti-crowding), and consonance-weighted soundscape selection in `MoodEngine`. No competitor layers sounds with tonal coherence; this is the defensible differentiator and it is *implemented, not aspirational*. The service decomposition (AudioEngine / ToneService / JourneyEngine / MotifEngine / MoodEngine) is sound and carries forward.

**Launch blockers (being fixed in the current correctness cycle):**
1. **Background/lock-screen audio does not exist.** No audio_session/audio_service, no `UIBackgroundModes: audio`, no Android foreground service. Fatal for the product. Critically: journey/motif engines run on Dart `Timer`s, which background execution throttles — the timing model must be validated/reworked under real background conditions *before* content production.
2. **Anthropic API key ships in the binary** (`.env` listed in pubspec assets). Move the LLM call behind a server proxy (Cloud Function); key server-side.
3. **Raw user mood text logged to Firebase Analytics** — privacy issue; log derived values only.
4. **Placeholder `com.example.*` app IDs and debug release signing** — fix before Firebase re-registration gets expensive.

**Next-tier technical priorities:**
- **SoLoud migration before the content pass.** Current `setSpeed()` pitch-shift alters tempo/timbre. True pitch-shift quality determines how much key coverage the catalog needs — the planned 144-soundscape target should be *re-derived after* migration, potentially shrinking months of production work.
- **Mood engine is fully deterministic** (pure argmax): same inputs → identical mix. Add weighted-random top-k selection (temperature via Remote Config). This also underpins the "one-of-one pressing" monetization concept below.
- **Saved mixes are lossy** (assetPath/name/volume only — no pitch ratios, tone params, motif state). V2's Collection requires full engine-state persistence.
- **Unit-test `HarmonicMatcher`** — pure math, zero coverage, and a regression there is a wrong note no code review catches.

---

## 2. Market conclusions (and the reasoning)

- **The category can't be won, and doesn't need to be.** Calm (~$210M revenue 2025) and Endel own the paid-UA game. Realistic success: a craft-led niche business — ~800–1,500 paying users, $3–5K MRR at 18–24 months. myNoise is the existence proof for this "middle path between hobby and Endel."
- **Paid acquisition math is underwater at our price point.** CPI ~$4–5; realistic CAC per paying subscriber $100–300 against ~$42/yr net revenue. Use only small ($500) measurement experiments until organic conversion is known. **VC was considered and rejected** — incompatible with the passive-income goal, and the category (wellness revenue declined 6.2% in 2025) no longer attracts it without a science/AI story.
- **Marketing = audience-building, which the team already knows how to do.** Growing Noisy Records' own streaming presence is simultaneously revenue and app funnel. Release cadence is the marketing calendar: each production cycle ships as streaming release + app content drop + long-form YouTube render (permanent ad + AdSense) + short-form clips. One effort, four channels.
- **Brand is a multiplier, not a reach engine.** The planned 8/16mm NYC film shoot is a good investment *as an asset factory* (App Store preview video, cutdowns, stills, BTS — shooting on film is itself content proving "humanly crafted"), not as a paid-placement commercial. Craft/the making should be the subject, not just the over-used chaos-vs-calm trope. Sequence the film *after* the app can cash the check it writes.
- **AI-generated music scaling up manufactures our positioning:** as functional audio becomes infinite commodity, provenance becomes the scarce good. The analog/handmade identity rides the same cultural current as vinyl and Bandcamp.

---

## 3. The core repositioning: music product, not wellness utility

The pivotal reframe of the whole conversation. "A sensitive backdrop for all of daily life" turned out to be Endel's own positioning — broadening use-cases walks into the incumbent's lane. The escape axis is different: **Noisy is a music project — a record label whose music is infinite and responsive.** Guiding phrase: ***"a living ambient album, handmade, that responds to you."***

- Framed as a utility, we compete with Calm for sleep-optimizers. Framed as music, we compete for *listeners* — the ambient/Eno/Bandcamp audience: large, culturally engaged, streaming-fatigued, allergic to AI slop, and a group that would never download a meditation app. Endel structurally cannot take this position (their brand *is* algorithmic generation).
- **Hybrid rule:** brand lives in music culture (interface language, film, press); functional keywords (sleep, focus, rain) live in App Store metadata only. Never in the UI, never abandoned in ASO.
- The harmonic engine matters *more* under this frame: tonal coherence is a musical virtue, legible to this audience. Solfeggio/binaural features get de-emphasized as wellness claims and reframed as musical/aesthetic choices (also reduces claims risk).

---

## 4. V2 app architecture: three rooms

Evolution of the idea: V1's Mixer/Library/Journeys (conventional, feature-named) → a four-room draft (LP / Radio / Studio / Collection, named in music-culture vocabulary) → final: **Studio cut from navigation**. Three bottom-nav rooms, minimal friction:

**Radio — infinite, ephemeral, communal.** You tune in; it's already playing; everyone hears the *same* broadcast (this shared-ness is the point — it's what made lofi girl a community, and something neither Endel nor Calm structurally offers). One flagship station free forever (simulcast to YouTube = top of funnel). Full dial behind subscription. **Plant Radio** is a station: one plant in the team's own studio, biodata→MIDI feeding a motif layer, "broadcasting live from a monstera" — brand theater and press hook. (The original ship-electrodes-to-users idea was rejected: noisy biodata, hardware support burden, near-zero audience. No user hardware, ever.)
> ⚠️ *Open architecture question for V2 planning:* a genuinely shared broadcast requires server-side coordination (synchronized engine state/seed, or an actual stream) — new infrastructure not present in V1. Needs design.

**LP — finite, composed, owned.** The sharpening insight: *an LP ends.* Side A/Side B, an arc, a final resolve — which the existing **JourneyEngine already implements** (timed phases, interpolated transitions = album structure wearing different clothes). Commissioned via "describe what you want to hear" — the record-store-owner ritual, vs. Radio's DJ. Boundedness solves the sleep timer natively, makes generations nameable/saveable/shareable, and is itself a differentiator: every generative competitor makes endless soup; *a piece that knows how to end is a musical statement.*

**Collection — what you've kept.** Saved LPs are first-class "pressings": generated artwork, a name, **full engine state** (key, tuning, layer voicing, motif seeds — fixes V1's lossy save at the object level). **Liner notes** on every LP/station ("Recorded in F♯ minor · tuned to 528 Hz · rain recorded in Queens · motifs: tape piano") — this is how the invisible harmonic craft becomes visible; credits are how music culture communicates quality. Radio snippets can be captured — *taping off the radio* (technically: a snapshot of engine parameter state). Optional aesthetic: unsaved generations drift away like a live set — if explored, err strongly toward generosity; "evocative" vs "the app deleted my thing" is a thin line.

**Cross-cutting decisions:**
- First launch opens onto Radio *already playing*. No onboarding wizard, no account wall. Sound before interface.
- The Studio (manual layer mixing) survives as a hidden dev mode for tuning content, and as a possible future update ("open this LP in the Studio"); it is not in V2 nav.
- Kitsch guard: the radio/LP metaphor lives in language, structure, and behavior — not skeuomorphic wooden dials and fake VU meters.

---

## 5. Monetization: Bandcamp economics

Two revenue streams, mapped by nature of the thing sold. **Recurring service → subscription; owned objects → purchases.** No double-gating.

- **LP purchases (the key idea, evolved from a rejected "soundpack" model).** Soundpacks gate unheard content — paying for *potential*, which feels like a money grab. Inverted: you purchase an LP *you've already heard and love* — a zero-risk purchase, identical to how people already buy records. With top-k randomness, each generation is unrepeatable, so a purchased LP is a genuine one-of-one pressing. **DRM-free audio download that outlives the subscription** is the strongest possible proof of the music-not-utility claim; treat sharing as marketing at this scale. *Requires an offline render pipeline (mix stems+params to file) — spec early; purchases via Apple/Google IAP (15–30% cut).*
- **Subscription = the service:** full radio dial, unlimited commissioning, large collection, sync. Do **not** token-meter subscribers — metering the core creative act creates hesitation, which suppresses the engagement that leads to purchases. Meter the *free* tier instead (a few commissions/month — scarce enough to feel like an occasion), plus flagship station and a small collection.
- **No pay-per-station** — rejected because it breaks Radio's communal meaning (nobody buys a radio station). Ticketed one-off *event broadcasts* are a possible later experiment.
- **Pricing anchors** (category: Calm/Headspace ~$70/yr, BetterSleep ~$60/yr): monthly $6–8 (exists to make annual look good), **annual-first $49–59**, 7-day trial. **Lifetime $99–129**: expected annual-subscriber LTV ≈ $90 (44% 12-mo retention → ~1.8yr lifetime), so ~$99+ is at/above expected value, paid upfront — good for a bootstrap; use as launch accelerator. Rate-limit or gate the LLM feature for lifetime users (perpetual API cost). Avoid low pricing ($1/mo): price signals quality, store fees eat it, and it makes all acquisition math impossible.
- **Spec the entitlement model into the design doc early** — free-tier limits, subscription scope, IAP catalog, render pipeline. It touches the engine, storage model, and every screen; far cheaper as architecture than retrofit.

---

## 6. Sequencing

1. **Now (underway):** V1 correctness + launch blockers — background audio (+ validate timer model under throttling), API key proxy, analytics privacy, app IDs/signing.
2. **SoLoud migration** — then re-derive catalog size from measured pitch-shift quality.
3. **V2 build:** three rooms, entitlement model, full-state Collection, render pipeline, top-k mood engine, shared-broadcast design for Radio.
4. **Content pass** (sized per #2), produced as the four-channel release flywheel.
5. **Stacked launch moment:** finished app + film + first drop + press, together — not dribbled out.

## 7. Open questions / to validate
- Shared-broadcast architecture for Radio (server-synced state vs. stream).
- SoLoud pitch-shift quality threshold → actual catalog size needed.
- Soft-launch price test against the warm streaming audience before committing pricing.
- Current Spotify "functional audio" royalty policy (bears on the $500/mo baseline).
- Snippet-capture UX and the ephemerality aesthetic (generosity line).
- Trial-to-paid and free-to-paid conversion from the warm funnel — the number that decides whether paid UA ever makes sense.
