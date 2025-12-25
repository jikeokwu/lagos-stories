# Core Design Decisions

This document tracks locked-in architectural decisions that affect multiple systems.

## 1. Lazy Evaluation (No Continuous World Simulation)

### Decision

The World Layer **NEVER** actively progresses or simulates in real-time. All entity updates happen through three mechanisms:

1. **During Instance**: Entities involved in the active instance are fully simulated with AI-driven behavior.
2. **Catch-Up Phase**: Before starting a new instance, entities NOT affected by the previous instance are fast-forwarded using lightweight rule-based heuristics.
3. **Chronicles Manual Resolution**: Players can manually trigger catch-up for specific entities in Chronicles Mode between sessions.

### Rationale

- Avoids expensive continuous simulation of thousands of NPCs.
- Distributes computational load across gameplay sessions.
- Makes the system more debuggable and predictable.
- Prevents "super long resolution phases" at the end of instances.

### Implications

- **AI Usage**: Heavy LLM calls only during instances; catch-up uses deterministic rules.
- **Antagonists**: No continuous scheming; they progress in discrete chunks during catch-up.
- **Player Experience**: The illusion of a living world is maintained without the performance cost.

## 2. Multi-Entity Ripple Effects (Configurable Depth)

### Decision

At the end of an instance, consequences propagate across connected nodes in the entity graph across ALL entity types:

- NPCs (social graph: friends of friends)
- Organizations (parent/child, partners, competitors)
- City-level values (districts, infrastructure, economy)
- Any entity with relationships to participants

**Player Setting**: Ripple depth (1-5 nodes, default: 2-3)

### Rationale

- Balances realism (actions have consequences) with performance.
- Prevents the entire world from needing updates after every instance.
- Creates a "zone of influence" around player actions.
- Player choice allows hardware/preference trade-offs.

### Implications

- Need a clear graph structure for all entity relationships.
- Resolution phase updates immediate neighbors; catch-up handles the rest.
- UI needs ripple depth configuration with performance warnings.

## 3. Local-First AI Inference

### Decision

The game is designed to work fully offline with **locally-run LLMs** as the primary approach. However, players can **optionally configure API access** (OpenAI, Anthropic, etc.) for any task category.

### Rationale

- **Local-first**: Privacy, autonomy, no recurring costs, forces better simulation design
- **API optional**: Flexibility for players with slower hardware or who prefer cloud model quality
- Hybrid setups possible (local for dialogue, API for complex tasks)

### Implications

- The simulation layer (deterministic code) must carry more load
- LLMs are used for flavor and interpretation; rules are rigid and code-based
- Hardware requirements are clear and documented
- UI needs API configuration options per task category

## 4. No Hand-Holding (Hardcore Simulation)

### Decision

The game prioritizes depth and complexity over accessibility. Like Dwarf Fortress, players must learn systems through exploration and experimentation.

### Rationale

- This is a personal project for players who enjoy deep-cut games.
- Avoids design compromises for commercial appeal.

### Implications

- No intrusive tutorials or quest markers.
- Documentation is wiki-style (reference manual).
- Players can get "lost" as part of the simulation experience.

## 5. Three-Value System (Sliders, Definite, Scale)

### Decision

All attributes across the game use three value types:

1. **Sliders**: Continuous scales (e.g., -100 to +100, or 0 to 100)
2. **Definite**: Fixed categorical values (e.g., gender, alive/dead)
3. **Scale**: Ordered progression values (e.g., skill levels)

### Rationale

- **No hard traits**: Continuous scales (ambition: -100 to +100) allow more nuance than binary flags ("ambitious: true/false")
- **Emergent complexity**: NPCs with mixed values create richer, more believable behavior
- **Extensibility**: Easy to add new sliders without refactoring

### Implications

- **Personality**: All personality traits are sliders (-100 to +100)
- **Skills**: Hierarchical like Dwarf Fortress (categories + specific skills with values)
- **Resources**: Type-based (no single "money" value; instead resource types containing items with values)
- **Status**: 0-100 sliders (health, stress, reputation)
- **Relationships**: Type + universal sliders (affection, trust, attraction, respect)
- **Affiliations**: Type + sliders (loyalty, investment, alignment)

## 6. Extensible-First Design

### Decision

The system is built to expect additions and changes based on user testing. Start with basic values; add more as needed.

### Rationale

- This is a personal project in active development
- User testing will reveal what depth is actually needed vs. over-engineering
- Easier to add complexity than to remove it

### Implications

- Schema should make it trivial to add new personality scales, skill categories, resource types
- No assumptions about "final" set of attributes
- Code should be agnostic to specific attribute names where possible

## 7. Multi-Model Configuration (User Choice)

### Decision

Users can select different AI models for different task categories, allowing them to balance quality, speed, and hardware constraints.

### Task Categories

1. World Generation (once per world, can use best model)
2. Instance Framing (per instance start)
3. Dialogue Generation (high frequency, needs speed)
4. Narrative Description (moderate frequency)
5. Intent Interpretation (high frequency, critical for UX)
6. NPC Decision Making (during instances)
7. Outcome Adjudication (moderate frequency)
8. Resolution & Consequences (per instance end)

### Rationale

- Different tasks have different speed/quality requirements
- Users have varying hardware capabilities
- A 30B model for world gen + 7B for dialogue is more practical than 30B for everything

### Implications

- UI needs model selection/configuration for each category
- System must support loading/switching between multiple models
- Performance profiling needed to guide user choices

## 8. Chronicles Mode (Complete Historical Database)

### Decision

Include a "Chronicles Mode" inspired by Dwarf Fortress Legends—a browsable database of the entire world's history.

### Features

- Browse all NPCs, organizations, locations, events, and items
- Interconnected navigation (click through relationships)
- Timeline views and search/filter capabilities
- Export world data to JSON
- **Limited in-game access**: Players can only see their own character's memories and public knowledge
- **Full access between sessions**: Complete world history visible, including under-the-hood values (personality sliders, relationship values, threat levels)
- **Manual resolution**: Trigger catch-up for specific entities

### Rationale

- Emergent narratives deserve to be preserved and explored
- Players want to understand long-term consequences of their actions
- Enables investigation/research gameplay (but maintains mystery during play)
- Supports community storytelling and world-sharing
- Celebrates the depth of the simulation

### Implications

- All entities must track complete history (never forgotten)
- Database must be optimized for complex queries
- UI design for browsing thousands of interconnected records
- Export format must be well-structured and documented
- Access control needed to limit in-game queries

## 9. Agency System (Variable NPC Simulation Depth)

### Decision

NPCs have **variable agency levels (1-5)** within instances, determining computational resources allocated to each character.

### Agency Levels

- **Level 5**: Player character, antagonist (full AI, all tools)
- **Level 4**: Important characters (detailed AI, most tools)
- **Level 3**: Significant characters (moderate AI, common actions)
- **Level 2**: Background characters (lightweight heuristics, basic interactions)
- **Level 1**: Crowd NPCs (scripted, narrative only)

### Rationale

- Not all NPCs need equal simulation depth
- Focus computational resources on narratively important characters
- Allows larger casts without performance collapse
- Same NPC can have different agency in different instances (instance-specific, not permanent attribute)

### Implications

- Instance framing assigns agency levels
- Resource budgeting per instance (limit on Level 5/4 characters)
- Tags like "antagonist" are instance-specific, not permanent
- Players don't see agency levels (maintain immersion)

## 10. No Win/Fail States (Player-Defined Goals)

### Decision

There are **no defined win or fail states**. Lagos Stories is a sandbox where players define their own success criteria.

### Rationale

- Not a consumer product with preset objectives
- Players who enjoy deep simulations prefer setting their own goals
- Dwarf Fortress-style philosophy: "Losing is fun"
- Supports diverse play styles (wealth, power, survival, family, stories)

### Implications

- Game never tells player they've "won" or "lost"
- No achievement system or victory screens
- Chronicles Mode allows players to review their impact
- Character death is not "game over"—switch to another character

## 11. SQLite as Primary Database

### Decision

Use **SQLite** (relational database) for world state persistence, with JSON export/import for sharing.

### Rationale

- Built-in to most systems, no server needed
- Strong ACID guarantees and referential integrity
- Excellent for complex queries (Chronicles needs joins across entities)
- Good for relationship-heavy data
- **No schema migrations needed**: Constantly generating new worlds; old worlds are snapshots

### Implications

- Design database schema with normalized relationships
- Optimize queries for Chronicles browsing
- Export to JSON for world sharing
- Each world is self-contained file

## 12. Development Feedback Mode

### Decision

Include a **Development Feedback Mode** where AI suggests missing tools/actions during play.

### Features

- AI identifies gaps in action system
- Proposes new tool categories based on unfulfilled player intent
- Helps iteratively build action vocabulary
- Accelerates development through play-driven design

### Rationale

- Don't define all action verbs upfront
- Let gameplay reveal what's needed
- AI can assist in its own development
- Natural evolution based on actual use cases

### Implications

- AI needs meta-awareness of available tools
- Feedback logged for developer review
- Action system designed for easy extension

## 13. Antagonist Threat System

### Decision

Antagonists operate on a dynamic **Perceived Threat slider (0-100)** that determines both frequency and severity of their actions against the player.

### Threat Levels

- **Low (0-30)**: Passive observation, gathering information
- **Medium (31-60)**: Active interference, social maneuvering, resource competition
- **High (61-85)**: Direct confrontation, recruiting allies, risky gambits
- **Critical (86-100)**: Desperate measures, all-out attack, scorched earth

### Threat Calculation

Based on:

- Player's reputation/influence
- Resources player has acquired
- Antagonist's goals being threatened
- Recent player actions against antagonist
- Antagonist's personality (volatility, ambition)

### Rationale

- Creates dynamic, escalating opposition
- Antagonists respond meaningfully to player actions
- Avoids predictable "boss fight at level 10" structure
- Same NPC can be dormant or aggressive depending on context
- Player doesn't know threat level (maintains mystery)

### Implications

- Threat slider is **instance-specific**, not permanent attribute
- Antagonist tag assigned per instance
- Player never sees threat values during gameplay
- Antagonists can de-escalate if player becomes less threatening
- Multiple NPCs can be antagonists simultaneously with different threat levels
