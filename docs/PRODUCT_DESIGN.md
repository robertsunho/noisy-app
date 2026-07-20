# PRODUCT DESIGN

The canonical description of Noisy as a *product* — the layer we are reimagining. Unlike `TECHNICAL_ARCHITECTURE.md` (kept accurate to code), this document is **vision-first**: it describes where the product is going and is explicit about what is **shipped** versus **aspirational**.

**Last updated:** July 16, 2026
**Status:** Under active reimagining (V2). The current shipped UX is documented in §5 as the baseline being reinvented.

---

## 1. Thesis — What Noisy Is

**Noisy externalizes a person's internal state, synchronously, as sound.**

Music's deepest value is its ephemerality. The streaming model *sells* that ephemerality while packaging it in the least ephemeral containers possible — fixed tracks, fixed lengths, fixed sequences, the identical recording delivered to millions. Streaming monetizes the feeling of the transient while delivering the permanent and universal.

Noisy is the inverse: sound that is *actually* ephemeral and *actually* singular to this listener in this moment. The user brings an interior condition — a mood, an energy, a texture of feeling — and Noisy renders it into sound that exists *because* they are feeling it, now. It is not a catalog to browse or a track to play. It is a reading of the self, made audible, lasting as long as the moment does.

**What Noisy is not:**
- Not an *instrument* — the user isn't expressing outward through skill; they're surfacing something already inside them.
- Not an *intelligence composing for you* — the app is the medium of translation; the user's state is the author.
- Not a *streaming catalog* — there is no fixed library of finished works to consume.

Saveable presets exist as a concession to human attachment (you may wish to return to a state you valued), but the core act is the synchronous externalization, not the collection.

> **Design consequence:** the two most sacred moments in the interface are **the input** (how a person conveys their internal state) and **the output presentation** (how the generated sound is surfaced as *of this moment* rather than as a track playing). These are the frontier of the reimagining.

---

## 2. Positioning

**"Algorithmically arranged, humanly crafted."** Every sound is produced by human hands; the technology selects, layers, tunes, and evolves them.

**Lane:** musical, not medical. Closer to "a generative Brian Eno record that responds to you" than to a wellness utility. The natural audience is the ambient-music listener underserved by apps that sound like laboratories — not the mass-market Calm/Headspace user.

**The differentiator is harmonic coherence** (see `TECHNICAL_ARCHITECTURE.md` §3.5): every pitched element — soundscape bed, solfeggio tone, binaural carrier, generative motifs — tuned to one key and voiced as a musician would voice a drone stack. Competitors layer sounds with no tonal relationship and produce tonal mud. This is implemented, not promised, and it is hard to copy without genuine music expertise.

**Positioning tensions to resolve in V2:**
- **De-emphasize solfeggio/binaural mysticism.** Solfeggio numerology has no scientific basis and binaural entrainment evidence is weak. The *musical* use of these tones (consonant scale degrees in a voiced drone) is legitimate and more honest than the mysticism. Wellness/therapeutic claims invite app-store friction and erode the genuinely defensible claim. Lead with craft and coherence; keep any wellness language carefully non-medical. *(external eval §3, §4)*
- **The differentiator is inaudible-as-named.** Users won't perceive "triad-aware carrier placement"; they'll perceive "this sounds nicer." The marketing challenge is translating inaudible craft into perceivable claims — e.g. A/B demo clips of coherent vs. incoherent layering. *(external eval §4)*
- **The moat is content + taste, not code.** Selection algorithms are replicable in a week; a growing catalog of well-produced, precisely-tuned soundscapes and the judgment behind the voicing rules is not. The content pipeline *is* the business. *(external eval §4)*

---

## 3. The Reimagining — Design Frontiers (aspirational)

These are the open design problems for V2. Nothing here is shipped; this section is the agenda for Phase 3 in `ROADMAP.md`.

### 3.1 The input moment
The current three-slider model (energy / focus / warmth) feels, in Robert's own re-engagement, like "a frustrating middle-ground between technical and intuitive" — too abstract to be intuitive, too vague to be precise. It is an engineer's decomposition of mood, not a human's experience of it. **Open question:** what is the most intuitive, present-tense way for a person to externalize how they feel right now? (The engine still needs an (energy, focus, warmth) vector internally — the reimagining is about the *surface*, not the underlying parameterization.)

### 3.2 The output moment
Generated sound should be presented as a *reading being surfaced*, not a track being played. Implications to explore: no progress bar (implies a fixed-length artifact with an end); no streaming-style track title; perhaps a living visual state that reflects the sound is *of this moment* and dissolves when the moment passes.

### 3.3 Ephemerality at the engine surface
The mood engine is currently deterministic — the same input yields the identical mix (`TECHNICAL_ARCHITECTURE.md` §3.4). This *contradicts the thesis at the engine level*: "never the same twice" is central to synchronous externalization, yet regenerating with unchanged input reproduces the same result. A weighted top-k draw (temperature tunable via the already-wired Remote Config) would deliver freshness cheaply and is a direct expression of the thesis, not merely a variety tweak.

### 3.4 Navigation & information architecture
Robert's re-engagement: the landing screen feels static, cluttered, and un-dynamic; the four-tab structure imposes a conventional app-shape. The instinct to keep 3–4 navigable modes is retained; the division, organization, and presentation are open for reinvention. Constraint: **preserve all existing functionality** — this is a presentation/IA reinvention, not a feature cut.

### 3.5 Sonic cohesion ("glue")
The disparate layers currently sum without binding into one space. A candidate *new* engine capability — shared reverb send, master-bus compression/limiting, gentle ducking — could make the mix feel like one crafted space rather than assembled parts. This is close to the heart of "humanly crafted." *(Robert, re-engagement — tracked as an engine-capability candidate.)*

### 3.6 First-impression integrity
The five curated Journeys still use legacy `SampleSource` MP3s and **bypass the harmonic system entirely** *(audit #29 / external eval §3b)* — so a first-time user sampling "Journeys" hears the *old* product, not the differentiated one. Resolving this is both a correctness item and a product-first-impression priority.

### 3.7 The LP / Radio axis (emerging)
> **Status: emerging — a direction, not a settled design.** Surfaced in an external design conversation; recorded here so it can steer V2 framing without yet committing to it.

The organizing distinction for the product's forms is **bounded vs. infinite**:

- **LP** — a piece that *ends*. Composed, personal, lean-in; it has an arc and a final resolution. You put it on and it takes you somewhere and then it's over.
- **Radio** — continuous. Live, shared, lean-back; it's *already playing* when you tune in, and it keeps going after you leave.

Why this may be the right spine:
- **A generated LP is a journey wearing its true clothes.** `JourneyEngine`'s timed phases and interpolated transitions (`TECHNICAL_ARCHITECTURE.md` §3.3) are effectively *album structure* already — waypoints are movements, the weight/curve interpolation is the segue between them. The LP form doesn't require a new engine; it renames and re-presents one we have.
- **Knowing how to end is a differentiator.** Generative competitors produce endless streams; a piece that resolves and stops is a *musical statement* they don't make. A bounded object is also **nameable, saveable, and shareable** in a way an infinite stream is not — it can be an artifact a person keeps and passes on.
- **The sleep timer is subsumed by the LP form.** An ending is built into the object itself, so "fade the mix out after N minutes" stops being a bolted-on utility and becomes a property of the piece. (A gradual fade-out on **Radio** remains possible — Radio can still be brought down gently; it simply isn't *defined* by an ending the way an LP is.)

This axis is compatible with, and may reframe, the input/output frontiers above (§3.1–3.2): choosing "an LP" vs. "the Radio" is itself a present-tense, human-legible way to say what you want right now.

---

## 4. Core Experience (current intended flow, engine-level)

Independent of the UX surface being reimagined, the underlying generative flow is:

1. User conveys internal state → resolves to an (energy, focus, warmth) vector (via sliders today, or natural-language text parsed by the LLM service).
2. The mood engine infers a category and generates a 5-layer mix — soundscape bed, nature texture, noise color, solfeggio tone, binaural beat — all harmonically matched to one key.
3. Generative motifs (bowls, bells, chimes) drift in over time, pitch-shifted to the same key.
4. The journey engine interpolates the mix across waypoints over a chosen duration.

This flow is sound and preserved. The reimagining (§3) concerns how it is *presented and invoked*, and the ephemerality/cohesion refinements.

---

## 5. Current Shipped UX (baseline being reinvented)

Documented so the reinvention has a clear "from" state. This describes what exists in the current build, not what should endure.

- **Four-tab bottom navigation:** Home, Mixer, Library, Journey. `IndexedStack` preserves state across tabs. Dark theme (#1C1C1C surface, #D4A017 amber accent).
- **Home:** three mood sliders under "How do you want to feel?", a duration quick-pick, a natural-language text field ("Or tell us how you want to feel…"), and a generate action. *(The "how do you want to feel" framing is future-tense/aspirational; the thesis is present-tense — a tension to resolve.)*
- **Mixer:** manual layer control; tapping a catalog sound adds a layer (silently no-ops when the 5-layer cap is hit — no user feedback, external eval §3a); save-mix action.
- **Library:** saved mixes ("My Mixes") + browse-by-intention. *(Note: soundscapes are currently not shown in the Browse-All category list — audit #17/#18 area; verify during correctness pass.)*
- **Journey:** five curated journeys with duration pickers and a sleep timer. *(These bypass the harmonic system — §3.6.)*
- **Hidden:** long-press the "Noisy" title → Tone Test screen (developer harmonic-matching tool).

**Elements that specifically contradict the thesis** (priority reinvention targets): the duration picker (presupposes a fixed-length artifact), the curated Journey tab (pre-authored fixed artifacts — the most streaming-like element), the "how do you want to feel" future-tense framing, and Library/collection elevated to primary navigation.

---

## 6. Tier 2 / Post-Launch (product-level)

**Plant Radio** — a curated live broadcast ("Noisy Plant Radio, live from the studio") where a plant bioelectricity sensor drives sound design on a separate device, streamed into the app as a `StreamSource` "Live" layer. Best as brand theater / event presence rather than a user-facing hardware feature. Architecturally compatible; see `TECHNICAL_ARCHITECTURE.md` data model. Not on the critical path.
