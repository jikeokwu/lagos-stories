# Prototype Plan: Core Loop Proof of Concept

## Objective

Validate the AI-first approach and the two-layer loop in a microcosm before scaling up. Test all critical architectural decisions in a controlled environment.

## Scope

- **Setting**: Single neighborhood in Lagos (e.g., Yaba, Surulere)
- **Population**: ~20 NPCs with full personality sliders, relationships, and histories
- **Scenario**: A simple conflict that allows for multiple approaches (e.g., neighborhood business rivalry, missing person investigation, community development dispute)
- **Duration Target**: 15-30 minute playable slice per instance

## Milestones

### 1. Data Foundation & Schemas

**Goal**: Implement core data structures

- SQLite database setup with all entity tables (NPCs, Locations, Items, Events, Organizations)
- Generate 20 NPCs with:
  - Personality sliders (-100 to +100): ambition, compassion, volatility, openness, social conformity
  - Political/ideological values: social conservatism, economic conservatism, authoritarianism, religious devotion
  - Lagos-specific identity: tribe, languages, educational background, religious affiliation
  - Hierarchical skills (categories + specific skills)
  - Type-based resources (liquid assets, property, social capital)
  - Status sliders (health, stress, reputation)
- Relationship network:
  - 3-4 family groups (siblings, parents)
  - 5-7 friendships
  - 2-3 rivalries
  - Each relationship has type + sliders (affection, trust, attraction, respect)
- Seed 5-10 locations (homes, businesses, public spaces) with hierarchy
- Create 1-2 small organizations (e.g., neighborhood association, local business)
- Pre-generate 10-15 historical events to give world history

**Success**: Can query and display all entities with full attributes

### 2. Text-First Instance Runner

**Goal**: Basic UI and game loop infrastructure

- Chat box interface for natural language input
- Text display for narrative output
- Command processing loop
- Tick system within instances
- Basic Godot 4 integration (or CLI for faster iteration)

**Success**: Can type commands and receive text responses (hardcoded initially)

### 3. Character Picker & World State Viewer

**Goal**: Select protagonist and view world

- Display list of 20 NPCs with basic info (name, age, occupation)
- Select protagonist for the instance
- Basic stats display (non-AI, just formatting test)
- Optional: Simple relationship graph visualization

**Success**: Can pick a character and see their profile

### 4. AI Validation Pipeline

**Goal**: Prevent AI hallucinations and maintain world consistency

- Implement 3-layer validation:
  1. **Constrained Premise Generation**: AI proposes action/event within known world state
  2. **Fact-Check Layer**: Validate against database (Does this NPC exist? Are they at this location? Do they have this skill?)
  3. **Convert to JSON**: Structured output for database updates
- Test with simple scenarios ("NPC A gives money to NPC B")
- Error handling for invalid AI outputs

**Success**: AI cannot create fictional entities or impossible actions

### 5. Instance Framing

**Goal**: AI-generated scenario setup

- Player types intent ("I want to investigate the missing generator")
- AI generates instance framing:
  - Scenario summary and stakes
  - Relevant locations
  - Cast list (5-8 NPCs from the 20)
  - **Assign antagonist** (if applicable)
  - **Calculate antagonist threat level** (based on player's reputation + antagonist personality)
  - **Assign agency levels**:
    - Player: Level 5
    - Antagonist: Level 5
    - 2-3 important NPCs: Level 4
    - 2-3 supporting NPCs: Level 3
    - Rest: Level 2
- Validate framing against world state

**Success**: Coherent scenario with appropriate cast and agency assignments

### 6. Gameplay Loop

**Goal**: Core interaction and simulation

- **Player Input**: Natural language commands
- **Intent Interpretation**: AI understands what player wants to do
- **Validation**: Check if action is possible (skills, resources, location)
- **NPC Actions**: Agency-based simulation
  - Level 5: Full AI reasoning, access to all tools
  - Level 4: Detailed AI, most tools
  - Level 3: Moderate AI, common actions
  - Level 2: Lightweight heuristics, basic interactions
- **Narrative Generation**: AI describes outcomes
- **Event Creation**: Record significant actions to global event log
  - Type, participants, location, timestamp, details
  - Impact calculation (severity, public knowledge)
- **Memory Updates**: NPCs remember events from their perspective
  - Reference to event ID
  - Personal summary (what they witnessed/felt)
  - Knowledge level (direct_witness, participant, secondhand)
  - Emotional impact
  - Belief accuracy (can be wrong)
- Basic turn structure

**Success**: Can perform 5-10 actions with NPCs responding appropriately based on agency level

### 7. Resolution & Persistence

**Goal**: Instance completion and world state updates

- Trigger instance end (player leaves, conflict resolved, time limit, etc.)
- **Resolution Phase**:
  - Finalize all pending state changes
  - Update NPC relationships (affection, trust, etc. deltas)
  - Update reputations (NPCs, organizations, locations)
  - Update resources (money, items transferred/created/destroyed)
  - Update city/district metrics if applicable
- **Create Event Log Entries**: Major instance events recorded with full details
- **Ripple Effects** (configurable depth: 2-3 nodes):
  - Identify entities connected to participants
  - Apply secondary effects to friends, family, org members
  - Update their memories (secondhand knowledge)
  - Update their relationships (friend-of-friend dynamics)
- **Save to SQLite**: Commit all changes
- **Update Antagonist Threat**: If antagonist involved, recalculate threat level

**Success**: Changes persist to database, ripple effects visible in connected entities

### 8. Catch-Up System (Lazy Evaluation)

**Goal**: Fast-forward uninvolved entities efficiently

- Before starting second instance, identify entities NOT in ripple effect zone
- Fast-forward using lightweight rules:
  - Age increments
  - Skill drift (practice or decay)
  - Relationship decay over time
  - Status changes (stress recovery, health changes)
  - Organization membership changes
- Profile performance: catch-up should be faster than resolution
- Verify no "super-long resolution phases"

**Success**: Uninvolved NPCs update appropriately without heavy computation

### 9. Multi-Instance Continuity

**Goal**: Validate persistence across sessions

- Start second instance with same or different protagonist
- Verify:
  - Relationship changes from first instance persist
  - Memories reference correct events
  - Reputation changes affect NPC attitudes
  - Items created/transferred correctly
  - Antagonist threat level persists (or updates appropriately)
- Test antagonist escalation:
  - If player succeeded in first instance, threat should increase
  - Antagonist should take more drastic actions in second instance
- Verify ripple effects applied correctly (friends of affected NPCs remember events)

**Success**: World feels continuous and reactive to past events

### 10. Basic Chronicles Mode

**Goal**: Prototype historical database browser

- **Event Log View**: List all events chronologically
- **NPC Browser**: View all NPCs with current stats
- **Relationship View**: Display relationships between NPCs
- **Location History**: Show events at each location
- **Search/Filter**: Basic filtering by type, participant, date
- Test data retrieval patterns for performance

**Success**: Can browse complete world history and understand what happened

### 11. Multi-Model Configuration

**Goal**: Test performance with different models

- Set up model routing for task categories:
  - **Instance Framing**: Test with 7B and 13B models
  - **Dialogue Generation**: Test with fast 7B model
  - **Resolution & Consequences**: Test with 13B model for quality
- Profile each configuration:
  - Latency per task
  - Quality of outputs
  - RAM usage
- Document recommended configurations for different hardware

**Success**: Can switch models per task and measure performance differences

## Success Criteria

- **Playability**: Achieve a playable 15-30 minute instance with natural flow
- **Coherence**: AI produces consistent responses that respect world state
- **Persistence**: State changes persist correctly across instances
- **Agency**: NPCs behave differently based on agency levels (noticeable depth difference)
- **Memory**: NPCs reference past events in dialogue/actions
- **Antagonism**: Antagonist escalates appropriately based on threat level
- **Performance**: Catch-up system faster than resolution; total cycle < 10 seconds for 20 NPCs
- **Chronicles**: Can browse and understand complete world history

## Next Steps

1. **Environment Setup**:
   - Godot 4 project initialized (or CLI prototype)
   - SQLite database integration
   - Python LLM server (llama.cpp or similar)
2. **LLM Testing**:
   - Test local model latency with simple prompts
   - Test validation pipeline with various inputs
   - Identify minimal viable model sizes
3. **Iteration Plan**:
   - Complete Milestones 1-3 without AI (pure data + UI)
   - Add AI layer (Milestones 4-6)
   - Add persistence (Milestones 7-9)
   - Polish with Chronicles and multi-model (Milestones 10-11)

## Non-Goals (For Prototype)

- Full Lagos city generation (just one neighborhood)
- Complex political/economic systems (test with simplified metrics)
- Visual rendering (text-only is fine)
- Complete action verb library (start with 10-15 core actions)
- Performance optimization (focus on architecture validation)
- Organization pillar mutation (use static org values)
- Full Chronicles features (limited to browsing)
