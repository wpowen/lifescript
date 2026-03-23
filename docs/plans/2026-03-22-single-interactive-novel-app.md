# Single Interactive Novel App Implementation Plan

> **For Claude:** Use `${SUPERPOWERS_SKILLS_ROOT}/skills/collaboration/executing-plans/SKILL.md` to implement this plan task-by-task.

**Goal:** Reposition `LifeScript` from a multi-title interactive fiction shelf into a single immersive interactive novel app with stronger narrative identity, clearer emotional pacing, and higher user immersion.

**Architecture:** Keep the existing node-based reading runtime, stats, relationship state, and local content pipeline, but strip out the bookstore-style shell. Let content lead the product: define the novel's emotional contract, story bible, route graph, and first-arc chapter package first; then build a story-specific app shell around that material.

**Tech Stack:** Existing SwiftUI iOS app, `@Observable`, SwiftData persistence, bundled JSON content, `story-factory` content compiler, targeted story-specific UI layer in a separate app directory.

---

## 1. Core Decision

The better near-term product is not a "platform for many novels". It is a "single premium interactive novel experience".

Reasons:

- A platform has a cold-start problem: content supply, recommendation, discovery, and quality control all need to work at once.
- A single novel only needs one thing to be true: the user is pulled into one world and wants to keep going.
- The current codebase already proves the runtime can support choices, stats, relationships, and chapter settlement. What is mismatched is the information architecture around it.
- For this category, immersion beats catalog size. One memorable story is a stronger proof of demand than a weak shelf of many stories.

## 2. Story-First, But Not "Write the Whole Novel First"

The right order is content-led, not content-only.

Do not fully write a 100-chapter novel before product work starts. That is too slow and will produce the wrong app assumptions.

Do not build a generic shell first and "drop any story into it" either. That will turn the app back into a platform.

Use this sequence instead:

1. Lock the novel concept and reader fantasy.
2. Build the `reader_desire_map`, `story_bible`, `route_graph`, and first arc.
3. Write a vertical slice of `6-10` chapters with real choices and delayed consequences.
4. Use that vertical slice to define the app's custom surfaces, pacing, and visual language.
5. Only then expand the rest of the season or full novel.

In short: the novel should define the app, but only after the novel is concrete enough to reveal what kind of app it actually needs.

## 3. Product Positioning

### 3.1 Product Definition

This should feel like:

- entering one dangerous or alluring world
- living through one protagonist's fate
- shaping the route through choices with visible tradeoffs
- carrying persistent consequences across chapters
- feeling that the app itself belongs to this story

This should not feel like:

- browsing a content marketplace
- choosing from interchangeable books
- jumping between genres
- managing a bookshelf

### 3.2 User Promise

The user promise is:

"You are not opening a reading app. You are entering one story that remembers what you did."

That means the app must optimize for:

- fast immersion within the first `30-90` seconds
- immediate clarity about the current dramatic problem
- visible aftereffects from choices
- strong end-of-chapter hooks
- low interface noise

### 3.3 Success Metrics

For the single-novel version, track:

- prologue completion rate
- chapter `1-3` completion rate
- choice click-through rate
- post-choice continuation rate
- next-session return rate
- replay or route revisit rate
- character/dossier views per active reader

Do not optimize early for:

- book discovery
- catalog conversion
- genre browse depth
- bookshelf retention

## 4. User Experience Blueprint

### 4.1 New Information Architecture

Replace the current multi-book shell with a single-story shell:

- `Entry / Continue`
- `Reading`
- `Dossier`
- `Route Map`
- `Chapter Settlement`
- `Profile / Settings`

The current `Home`, `Bookshelf`, and multi-book `BookDetail` flows should not define the new app.

### 4.2 Recommended Screens

#### Entry / Continue

Purpose:

- drop the user into the world immediately
- show one strong promise, not many options
- support `Start`, `Continue`, `Recap`

What it should contain:

- title treatment
- one emotionally loaded story statement
- current chapter / progress
- one dominant CTA
- optional short recap from the last chapter

#### Reading

Purpose:

- keep friction low
- make choice consequences legible
- preserve scene rhythm

What it should contain:

- immersive typography and background language tied to the novel
- inline consequence feedback
- minimal top chrome
- easy access to dossier and relationship state without leaving the story mentally

#### Dossier

Purpose:

- help the user retain the story state
- deepen investment in people, factions, clues, or systems

What it should contain depends on genre:

- suspense: evidence board, suspect notes, countdown state
- romance: intimacy stages, private moments, message archive
- cultivation: realm progress, sect map, techniques, enemies
- business war: leverage map, allies, liabilities, exposed secrets

#### Route Map

Purpose:

- prove the story remembers choices
- create replay desire
- let the user see what kind of route they are building

What it should show:

- visible route milestones
- locked but hinted branches
- chapter decisions already taken
- current route identity labels

#### Chapter Settlement

Purpose:

- convert reading into felt progression
- summarize what changed
- seed the next hook

This is already aligned with the current product and should be preserved.

## 5. Narrative Design Framework

### 5.1 Required Narrative Artifacts Before UI Lock

Before committing to the single-story app, produce these content artifacts:

- `reader_desire_map`
- `story_bible`
- `route_graph`
- `walkthrough`
- first-arc `chapter cards`
- first-arc real `chapters`

These are the minimum source of truth for product design.

### 5.2 What The Novel Must Define

The novel needs to answer these product-shaping questions:

- What fantasy is being sold to the reader?
- What kind of power or vulnerability cycle defines the story?
- What type of choices matter most: attitude, alliance, sacrifice, exposure, deception, desire?
- What systems must persist between chapters: relationships, clues, reputation, resources, corruption, affection, suspicion?
- What kind of route identity should the user feel they are building?

If these are not clear, the app will drift back into generic interactions.

### 5.3 Vertical Slice Standard

The first usable content slice should include:

- one clear premise
- one protagonist identity with a strong lack or wound
- `3-5` core supporting characters
- `1` strong central conflict
- `6-10` chapters
- `2-3` meaningful choices per chapter
- at least `2` delayed callbacks
- at least `1` route identity split

That slice is enough to tune:

- pacing
- UI density
- consequence visibility
- recap needs
- dossier structure
- monetization seams

## 6. Development Design

### 6.1 Separate App Directory

Create a new app directory for the single-story product and keep the current aggregator intact.

Recommended name:

- `LifeScript-Solo`

Why:

- avoids polluting the current multi-book shell
- makes it easier to remove platform assumptions cleanly
- preserves shared runtime pieces for later extraction

### 6.2 What To Reuse

These existing parts are valuable and should be reused or extracted:

- node-based chapter model
- `Choice`, `StoryNode`, `Chapter`, relationship and stat models
- reading progression logic in `ReadingViewModel`
- local content loading
- chapter settlement pattern
- `story-factory` compile pipeline

### 6.3 What To Replace

These parts are platform-oriented and should not define the solo app:

- multi-book `HomeView`
- `BookshelfView`
- book discovery and genre browse patterns
- tab structure centered on library behavior
- any UI copy framed around "books" as a collection

### 6.4 Suggested Solo App Modules

- `App/SingleStoryApp.swift`
- `Features/Entry`
- `Features/Reading`
- `Features/Dossier`
- `Features/RouteMap`
- `Features/Settlement`
- `Core/StoryRuntime`
- `Core/Persistence`
- `Resources/StoryPackage`

If shared code becomes stable, extract it later into a shared package. Do not start with an abstracted shared package now.

## 7. Product Design Principles

### 7.1 Design Principles

- Story first, system second, platform last
- Every screen should reinforce one world, not a generic reader
- The UI should feel like a story instrument panel, not a content storefront
- Choices should read as strategies or attitudes, not quiz answers
- Every important interaction should create a visible memory

### 7.2 Customization Rule

The novel's genre should directly shape product surfaces.

Examples:

- If the story is suspense-driven, build clue memory and threat visualization.
- If the story is romance-heavy, build relationship tension and message history.
- If the story is cultivation-driven, build power thresholds and breakthrough anticipation.
- If the story is business-war driven, build evidence chains and leverage dashboards.

This is the main reason the novel must be defined first.

## 8. Phased Roadmap

### Phase 0: Pick The Novel

Output:

- premise
- target reader fantasy
- genre
- emotional contract
- monetization assumption

Decision gate:

- can this premise sustain `30+` chapters of escalating payoff?

### Phase 1: Build The Story Operating System

Output:

- `reader_desire_map`
- `story_bible`
- `route_graph`
- `walkthrough`
- state system definition

Decision gate:

- do we know exactly what persistent systems the app must visualize?

### Phase 2: Write The Vertical Slice

Output:

- first `6-10` chapters
- real choices
- route memory
- delayed callbacks
- settlement summaries

Decision gate:

- do readers feel immersion and consequence without needing a big catalog?

### Phase 3: Build The Solo App Shell

Output:

- entry/continue screen
- customized reader
- dossier
- route map
- save/resume loop

Decision gate:

- does the app now feel like this story's native container?

### Phase 4: Test And Expand

Output:

- playtest notes
- drop-off analysis
- pacing fixes
- content expansion plan

Decision gate:

- should we scale this story into a full season or rewrite the premise?

## 9. Non-Goals For The Solo Version

Do not spend early cycles on:

- author tools for external creators
- UGC pipeline
- multi-title recommendation
- advanced social features
- broad genre coverage
- generalized marketplace monetization

## 10. Immediate Recommendation

The next correct move is:

1. Choose one novel concept, not one app concept.
2. Build its `reader_desire_map`, `story_bible`, and `route_graph`.
3. Write a first-arc vertical slice.
4. Use that slice to define the new app's IA, visual language, and system surfaces.
5. Only after that start implementation in `LifeScript-Solo`.

That is the healthiest order because the novel is the soul, but the app is the staging mechanism. The soul should lead. The staging should follow.
