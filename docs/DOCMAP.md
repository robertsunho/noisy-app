# DOCMAP — How Noisy's Documentation Fits Together

**Purpose:** This file is the orientation guide for the Noisy documentation set. It exists so that any reader — Robert, Claude in conversation, or Claude Code operating in the repo — can quickly find the right document for a given task and understand how the documents relate. Read this first.

**Last updated:** July 16, 2026

---

## The canonical document set

All canonical documentation lives in the `/docs` root. There are seven documents, organized into three tiers. (Non-canonical investigation artifacts and superseded documents live in subfolders — see **Repository layout** below.)

### Tier 1 — Orientation (read first)

**`DOCMAP.md`** (this file)
Defines the doc set and routing rules. Consult when unsure which document governs a task.

### Tier 2 — The two ground-truth records

**`TECHNICAL_ARCHITECTURE.md`** — *the layer we preserve*
The canonical description of the engine: audio engine, tone service, journey engine, motif engine, mood engine, harmonic matcher, LLM service, the data model, and the audio-behavior knowledge (crossfades, carrier placement, pitch-shifting). This is the source of truth for how the app *works* under the hood. When code and this doc disagree, that is drift to be resolved by a ruling (see Changelog).

**`PRODUCT_DESIGN.md`** — *the layer we are reimagining*
The canonical description of the product: the vision and thesis (elemental, synchronous, ephemeral, anti-streaming), the intended user experience, the interface, and the interaction model. This document is under active redesign; it describes where the product is going, and is explicit about what currently exists versus what is aspirational.

> **Why these are separate:** Noisy's core strategy is "preserve the engine, reimagine the product layer." The two documents are in fundamentally different states — one is stable ground being kept accurate, the other is under active reinvention. Bundling them would invite exactly the confusion the doc set exists to prevent.

### Tier 3 — Working records and guardrails

**`ENGINEERING_PRINCIPLES.md`**
A tight set of Noisy-specific invariants and guardrails — not a general style guide. Protects the specific things that matter here (e.g. don't modify empirically-tuned audio behavior without discussion; engine services must not import from screens). Consult before any code change.

**`CONTENT_PRODUCTION.md`**
The production spec and asset registry: soundscapes, motifs, nature sounds, noise colors — what to produce, to what standard (LUFS, tuning, naming), and what currently exists versus is planned. The home for the content pipeline.

**`DECISIONS_AND_CHANGELOG.md`**
The append-only record of *why* (decisions, including roads not taken) and *what* (changes to code and docs). Every ruling on a discrepancy, every design decision, every implemented change gets an entry. This is the primary defense against future drift and against losing context over time gaps.

**`ROADMAP.md`**
The forward-looking plan: what's done, what's next, what's deferred, in what order and why. Claude Code marks items complete as work lands. Consult to understand current priorities and sequencing.

---

## Repository layout

Only canonical documents live in the `/docs` root; two subfolders hold everything else.

```
docs/
├── DOCMAP.md                     ← Tier 1 (this file)
├── TECHNICAL_ARCHITECTURE.md     ← Tier 2
├── PRODUCT_DESIGN.md             ← Tier 2
├── ENGINEERING_PRINCIPLES.md     ← Tier 3
├── CONTENT_PRODUCTION.md         ← Tier 3
├── DECISIONS_AND_CHANGELOG.md    ← Tier 3
├── ROADMAP.md                    ← Tier 3
├── audits/                       ← investigation & audit artifacts (inputs, not canon)
│   ├── AUDIT_REPORT.md
│   └── noisy_independent_evaluation.md
└── archive/                      ← superseded documents, retained for reference
    └── noisy_design_document.md  ← pre-split design doc (v2.4)
```

- **`docs/` root** — canonical documents only (the seven above).
- **`docs/audits/`** — investigation and audit artifacts. They informed the canonical docs but are not maintained as ground truth.
- **`docs/archive/`** — superseded documents retained for historical reference, such as the pre-split design doc (v2.4) that `TECHNICAL_ARCHITECTURE.md` and `PRODUCT_DESIGN.md` are being split out from.

---

## Routing rules — which document governs a task

| If the task is… | Read / update… |
|---|---|
| Understanding or changing engine behavior | `TECHNICAL_ARCHITECTURE.md` (+ `ENGINEERING_PRINCIPLES.md` first) |
| Reimagining UX, interface, or product identity | `PRODUCT_DESIGN.md` |
| Any code change at all | `ENGINEERING_PRINCIPLES.md` first, then the relevant Tier 2 doc |
| Producing or integrating audio content | `CONTENT_PRODUCTION.md` |
| Recording a decision or a completed change | `DECISIONS_AND_CHANGELOG.md` (always append) |
| Understanding priorities / what's next | `ROADMAP.md` |
| Resolving a doc-vs-code discrepancy | Rule it, record the ruling in `DECISIONS_AND_CHANGELOG.md`, then fix doc or code accordingly |

---

## Operating principles for the doc set

1. **Two ground-truth docs, different states.** `TECHNICAL_ARCHITECTURE.md` is kept *accurate to the code*. `PRODUCT_DESIGN.md` is allowed to describe intended future state, but must label what is aspirational versus shipped.

2. **The Changelog is append-only.** Never rewrite history; add entries. A decision that reverses an earlier one references the earlier entry.

3. **Docs and code stay in sync via rulings.** When drift is found, it is not silently "fixed" — it is ruled on (is the doc wrong, the code wrong, or is this a latent design question?), the ruling is recorded, and only then is the fix applied. This is what prevents the drift from silently recurring.

4. **Claude Code reads before writing.** For any repo task, the relevant doc(s) above are consulted before code is touched. `ENGINEERING_PRINCIPLES.md` is consulted before *every* code change.

5. **The audit artifact (`docs/audits/AUDIT_REPORT.md`) and external review (`docs/audits/noisy_independent_evaluation.md`) are inputs, not canon.** They informed the canonical docs but are not themselves maintained as ground truth. They live in `docs/audits/` as historical record.

---

## Current phase

The project is in **Phase 2: post-hiatus reconciliation and V2 planning.** Immediate sequence:
1. Stand up this documentation infrastructure (in progress).
2. Reconcile the codebase and design doc via the 29 catalogued discrepancies (triaged: doc-fixes, code-comment-fixes, and design-flavored rulings).
3. Synthesize the external evaluation and design refinements into a concrete V2 plan.

See `ROADMAP.md` for detail.
