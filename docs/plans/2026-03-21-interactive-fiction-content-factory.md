# Interactive Fiction Content Factory Implementation Plan

> **For Claude:** Use `${SUPERPOWERS_SKILLS_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Build a scalable content factory that can batch-generate many interactive power-fantasy novels with clear main routes, side routes, hidden routes, and a user-visible walkthrough map.

**Architecture:** Introduce a three-layer content system: `story bible -> story graph -> runtime chapters`. Generate novels from reusable genre packs and route templates instead of freeform prompting. Keep production cost under control with a braided graph: stable trunk, meaningful local divergence, route flags, and planned convergence points.

**Tech Stack:** Existing SwiftUI iOS reader, Codable JSON runtime content, offline content compiler (`Python` or `TypeScript`), LLM-assisted generation, rule-based validators, graph export for walkthrough UI.

---

## 1. Current Product Reading

The current product positioning is already strong:

- The app is not positioned as a traditional branching novel. It is positioned as a "命运操盘" product with strong爽感, clear feedback, and light progression.
- The PRD consistently reinforces "互动不是做题，而是选择爽法".
- The runtime app is currently optimized for a mostly linear chapter-reading flow with inline choices, stat updates, and relationship updates.

This is visible in the current project:

- `交互爽文prd.md` defines the product as "互动选择 + 轻养成 + 关系推进" and emphasizes immediate feedback and long-term attachment.
- `ARCHITECTURE.md` explicitly states the current reading flow is mostly linear and backed by local JSON bundles.
- `StoryNode.swift` and `Choice.swift` model chapters as ordered nodes with inline choices and deltas.
- `ReadingViewModel.swift` applies stat and relationship effects, but it still behaves like a chapter player, not a graph engine.

## 2. Core Gap

The current content format is good for hand-authored sample books, but not for industrialized batch generation.

Missing layers:

- No explicit story graph above chapters
- No artifact for main line / side line / hidden line / reveal line
- No route-level conditions, gates, or convergence rules
- No character agenda system
- No clue registry or payoff registry
- No "攻略图" export for users
- No content QA layer to validate route logic, pacing, and novelty

One concrete signal: `Choice.resultNodeIds` exists, but the reader does not actually resolve a reusable result-graph. It only renders a local dramatic summary. That is fine for MVP samples, but it will collapse under large-scale content generation.

## 3. Product Direction To Preserve

Do not turn this into a full tree-shaped choice game.

The right model is:

- Strong trunk
- Local route flavor
- Persistent route flags
- Character-specific side lines
- Hidden reveals that pay off later
- Periodic convergence at arc milestones

This preserves the current product promise:

- fast pace
- strong hooks
- meaningful choices
- manageable production cost
- visible user agency

## 4. The Right Content Factory Model

Use five content layers.

### Layer 1: Genre Pack

This is the reusable "爽文引擎" for a category.

Each genre pack defines:

- world rules
- power system or status system
- conflict ladder
- face-slap patterns
- reveal patterns
- romance patterns
- antagonist ladder
- ending families
- chapter pacing rules
- monetization hook types

Example packs:

- urban_reversal
- cultivation_upgrade
- business_war
- apocalypse_survival
- school_revenge
- entertainment_comeback

### Layer 2: Story Bible

This is the book-specific long-term truth source.

It should contain:

- premise
- protagonist core identity and hidden identity
- world overview
- faction map
- character roster
- relationship seeds
- secret registry
- forbidden truths
- major arc ladder
- ending catalog
- taboo list
- tonal constraints

This artifact must exist before any chapter writing starts.

### Layer 3: Story Graph

This is the most important new layer.

The graph is not chapter text. It is the machine-readable route plan.

Every graph node should declare:

- arc id
- node id
- node type: `main`, `branch`, `side`, `hidden`, `reveal`, `boss`, `romance`, `settlement`
- summary
- dramatic goal
- required flags
- produced flags
- required stat ranges
- affected characters
- clue writes
- clue payoffs
- convergence target
- expected chapter span

Every graph edge should declare:

- trigger choice
- unlock conditions
- route weight
- payoff delay
- branch duration
- whether user can see this path in the walkthrough map

### Layer 4: Scene Cards

Each graph node expands into scene cards.

A scene card is not prose. It is a structured beat sheet:

- scene objective
- entering state
- conflict
- emotional target
- chosen爽点类型
- must-mention facts
- character tension
- exit state
- next hook

This is the unit the writing skill consumes.

### Layer 5: Runtime Package

This is the final compiled output for the app.

It includes:

- `book.json`
- `chapters/*.json`
- `walkthrough.json`
- `graph_public.json`
- `graph_internal.json`
- `qa_report.json`

The app reads the runtime package. Editors and generators work on the higher layers.

## 5. Skill Stack

Do not build one giant "write me a novel" skill.

Build a chain of focused skills with explicit input and output artifacts.

### Skill 1: Genre Pack Builder

Input:

- target genre
- target audience
- target爽点 families

Output:

- `genre_pack.yaml`

Responsibilities:

- define reusable trope pool
- define pacing envelope
- define allowed route types
- define character archetype pools
- define escalation ladder

### Skill 2: Book Seed Generator

Input:

- chosen genre pack
- campaign constraints

Output:

- `concept.yaml`

Responsibilities:

- generate 10 to 30 high-level book seeds in batch
- enforce category diversity
- score seeds by novelty, hook strength, and route potential

### Skill 3: Story Bible Builder

Input:

- `concept.yaml`
- `genre_pack.yaml`

Output:

- `story_bible.yaml`

Responsibilities:

- build long-term truth
- define protagonist masks and hidden truths
- create 20 to 50 meaningful characters
- assign agendas, loyalties, secrets, and betrayal triggers

### Skill 4: Cast Matrix Builder

Input:

- `story_bible.yaml`

Output:

- `cast_matrix.yaml`

Responsibilities:

- generate role graph
- define character relation axes
- define usable combinations for rivalry, alliance, romance, betrayal, mentor, pawn
- mark who belongs to main line, side line, hidden line

### Skill 5: Route Graph Planner

Input:

- `story_bible.yaml`
- `cast_matrix.yaml`

Output:

- `story_graph.json`

Responsibilities:

- build main line
- attach side lines
- attach hidden routes
- mark convergence and divergence nodes
- mark all route conditions
- emit internal and public walkthrough views

This is the highest-value skill in the whole system.

### Skill 6: Arc Expander

Input:

- `story_graph.json`

Output:

- `arc_cards/*.yaml`

Responsibilities:

- expand route nodes into per-arc beat sheets
- ensure each arc has setup, pressure, reversal, payoff, and next hook
- enforce clue setup before payoff

### Skill 7: Chapter Beat Builder

Input:

- `arc_cards/*.yaml`

Output:

- `chapter_cards/*.yaml`

Responsibilities:

- convert arcs into chapters
- define chapter opening conflict
- define interaction nodes
- define stat and relationship impact
- define chapter-end hook

### Skill 8: Scene Writer

Input:

- `chapter_cards/*.yaml`

Output:

- `scene_drafts/*.json`

Responsibilities:

- write structured scenes
- keep prose style aligned to genre pack
- keep characters on model
- keep node-level interaction clear

### Skill 9: Continuity QA

Input:

- all upstream artifacts

Output:

- `qa_report.json`

Responsibilities:

- dead-end detection
- character consistency checks
- unresolved clue checks
- impossible stat gate checks
- repeated twist detection
- branch distinctness scoring

### Skill 10: Runtime Compiler

Input:

- approved drafts

Output:

- app-ready JSON

Responsibilities:

- transform story graph and scene drafts into app schema
- export user-visible route map
- export editor-only graph
- keep runtime package deterministic

## 6. Recommended Artifact Layout

```text
content-factory/
  schemas/
    story_bible.schema.json
    cast_matrix.schema.json
    story_graph.schema.json
    chapter_card.schema.json
  genre-packs/
    urban_reversal/
      genre_pack.yaml
      choice_styles.yaml
      arc_templates.yaml
      character_archetypes.yaml
    cultivation_upgrade/
      genre_pack.yaml
      choice_styles.yaml
      arc_templates.yaml
      character_archetypes.yaml
  books/
    urban_001/
      concept.yaml
      story_bible.yaml
      cast_matrix.yaml
      story_graph.json
      graph_public.json
      graph_internal.json
      arc_cards/
      chapter_cards/
      scene_drafts/
      runtime/
        book.json
        chapters/
        walkthrough.json
        qa_report.json
```

## 7. Graph Rules That Make Scale Possible

This is where many teams fail. The solution is not "more branching". The solution is better graph economics.

Recommended graph rules:

- One stable main line per book
- 3 to 5 persistent route flavors per book
- 5 to 10 character-specific side lines
- 2 to 4 hidden routes
- 1 to 2 endgame reveal lines
- Branches should usually last `1 to 3 chapters`, not `10+ chapters`
- Major arcs converge at fixed milestones
- Choice impact should be stored as `flags + stat deltas + relationship deltas`
- Different routes should often reuse milestone endpoints but arrive with different state

That gives the user real agency without exploding chapter count.

## 8. How The User Sees A "Walkthrough Game" Path

You should support two maps.

### Public Map

User-facing. Spoiler-controlled.

Shows:

- completed path
- current route tendency
- locked side routes
- silhouette of hidden routes
- required affinities or stats for unlock
- key chapter forks
- collectible clue progress

The user feeling should be:

- "I know there are routes I have not opened yet."
- "I can plan a replay."
- "This behaves like a visual攻略图, not random AI text."

### Internal Map

Editor-facing. Full detail.

Shows:

- all nodes
- all edges
- all conditions
- all clue chains
- all reveal dependencies
- all convergence points
- monetization hooks

The internal map is the operating console for content QA and batch production.

## 9. Data Model Changes Needed In The App

The app does not need to become a full game engine immediately, but the content schema must grow.

Recommended new runtime fields:

- `routeFlags`
- `nodeConditions`
- `chapterEntryConditions`
- `chapterOutcomeTags`
- `clueUnlocks`
- `characterAgendaTags`
- `visiblePathNodes`
- `hiddenPathHints`
- `endingProgress`

Recommended new higher-level models:

- `StoryGraph`
- `StoryArc`
- `StoryEdge`
- `StoryFlag`
- `Clue`
- `WalkthroughNode`
- `WalkthroughEdge`

## 10. Batch Production Loop

The factory should operate in four modes.

### Mode A: Seed Batch

Generate many concepts fast.

Output:

- 20 to 100 candidate book seeds

### Mode B: Structure Batch

Only the strongest seeds move into bible + graph construction.

Output:

- 5 to 20 structurally valid books

### Mode C: Draft Batch

Write chapters only after graph validation passes.

Output:

- app-ready first `10 to 20 chapters`

### Mode D: Live Ops Batch

Expand proven books with new arcs, side routes, romance lines, or hidden revelations.

Output:

- new content packs that preserve continuity

## 11. Quality Gates

Every generated book should pass a hard validation checklist.

- first conflict within `30 seconds`
- first meaningful choice within `2 minutes`
- every chapter has at least `1 hook`
- every `3 to 5 chapters` there is a major status shift
- no hidden clue payoff without setup
- no setup without intended payoff owner
- no character appears as ally and traitor without transition bridge
- no branch may become unreachable by ordinary play unless marked hidden
- public map and internal map must stay consistent

## 12. Metrics To Add

In addition to existing MVP reading metrics, track:

- route divergence rate
- replay rate by route family
- hidden route discovery rate
- route completion heatmap
- character-route correlation
- choice distribution entropy
- branch abandonment points
- guide-map open rate

These metrics will tell you whether the route system is actually legible to users.

## 13. Near-Term Execution Order

Phase 1 should focus on content infrastructure, not prose scale.

### Phase 1

- define `story_bible`, `cast_matrix`, and `story_graph` schemas
- build one genre pack well
- build one book through the full pipeline
- export internal and public path maps

### Phase 2

- compile graph output into current app JSON
- add route flags and walkthrough models to the app
- expose a minimal "命运图谱" view to users

### Phase 3

- add continuity QA and route scoring
- batch-produce 5 to 10 books from multiple genre packs

### Phase 4

- move generation pipeline behind an internal tool or service
- support live extension of successful books

## 14. Practical Recommendation For This Repo

For this repository, the first concrete move should be:

1. Keep the current reading UX and chapter node renderer.
2. Add a new content-factory layer outside the iOS runtime.
3. Treat the current chapter JSON as compiled output, not source of truth.
4. Introduce `story_graph` and `walkthrough` artifacts before writing more books.

If you skip the graph layer and go directly to "AI bulk writes many chapters", you will get:

- repetitive books
- broken continuity
- fake branches
- unusable hidden lines
- impossible攻略图

If you add the graph layer first, you can scale much more safely.
