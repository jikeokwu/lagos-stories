# Agency System

## Overview

The agency system determines how much computational resources and simulation detail are allocated to each NPC during an instance. Agency is **instance-specific** and **temporary**—the same NPC can have different agency levels in different scenarios.

## Agency Levels (1-5 Scale)

### Level 5 - Maximum Agency

**Typical Roles**: Player character, antagonist

**Simulation Detail**:

- Full AI-driven decision-making for every action
- Complex personality evaluation
- Memory formation and retrieval
- Long-term planning capabilities

**Tool Access**: All available

- Full action set
- Complex social maneuvers
- Strategic planning tools
- Investigation/analysis capabilities

**AI Usage**: Heavy LLM calls for:

- Dialogue generation
- Decision reasoning
- Intent interpretation
- Outcome evaluation

---

### Level 4 - High Agency

**Typical Roles**: Important characters (key allies, major figures, significant NPCs in the instance)

**Simulation Detail**:

- Detailed AI decision-making
- Personality-driven responses
- Memory access
- Tactical thinking

**Tool Access**: Most actions available

- Social interactions
- Professional capabilities
- Basic planning
- Reactions to player

**AI Usage**: Moderate LLM calls

- Key dialogue moments
- Important decisions
- Character-defining actions

---

### Level 3 - Medium Agency

**Typical Roles**: Significant characters (named NPCs with defined roles in the instance)

**Simulation Detail**:

- Moderate AI involvement
- Trait-based responses
- Limited memory context
- Reactive behavior

**Tool Access**: Common actions

- Basic interactions
- Routine professional tasks
- Simple responses

**AI Usage**: Light LLM calls

- Occasional dialogue
- Routine decisions use heuristics

---

### Level 2 - Low Agency

**Typical Roles**: Background characters with speaking parts

**Simulation Detail**:

- Lightweight heuristics
- Simple trait evaluation
- Minimal memory
- Scripted reactions

**Tool Access**: Basic interactions only

- Simple conversation
- Standard responses
- Ambient actions

**AI Usage**: Very light

- Template-based dialogue
- Rule-based behavior

---

### Level 1 - Minimal Agency

**Typical Roles**: Crowd/ambient NPCs, unnamed bystanders

**Simulation Detail**:

- Simple scripted behavior
- No individual decision-making
- Narrative presence only

**Tool Access**: None

- Described in aggregate
- No individual actions

**AI Usage**: None

- Purely descriptive

---

## Assignment Principles

### Instance Framing

During instance setup, AI assigns agency levels based on:

- **Narrative Role**: Who is central to this story?
- **Player Proximity**: Who will the player interact with?
- **Conflict Involvement**: Who drives or opposes the main tension?

**Example Instance: "Confront Your Corrupt Boss"**

- Boss (antagonist): Level 5
- Player character: Level 5
- Boss's secretary (ally/informant): Level 4
- Colleague witnesses: Level 3
- Office workers in background: Level 2
- People in lobby: Level 1

### Dynamic Adjustment

Agency can shift mid-instance:

- Background character becomes important → agency increases
- Main character exits scene → agency decreases (or freezes)

### Resource Budgeting

Instance has a total "agency budget":

- Limit on total Level 5 + Level 4 characters active simultaneously
- Prevents performance collapse
- Forces narrative focus

**Typical Budget** (adjustable by hardware):

- 2 × Level 5
- 3-5 × Level 4
- 10-15 × Level 3
- Unlimited × Level 2-1

## Tag System (Instance-Specific)

Tags are **not permanent NPC attributes**—they're assigned for the duration of an instance.

**Player Knowledge**: Players are **not** told who has which tags. Part of the gameplay (like the game Mafia) is figuring out who is your ally, who is your rival, and who is secretly working against you. Tags are internal system metadata, not UI labels.

### Role Tags

- `player_character`: The character the player controls (Level 5)
- `antagonist`: The primary opposing force (Level 5)
- `ally`: Supporting the player (Level 4)
- `rival`: Competing with player (Level 4)
- `witness`: Important for events (Level 3)
- `bystander`: Present but peripheral (Level 2-1)

### Functional Tags

- `decision_maker`: Can make plot-critical choices
- `information_source`: Knows key facts
- `obstacle`: Blocks player progress
- `narrative_focus`: Currently in spotlight

**Example**:

- NPC*A is "antagonist" in Instance 1 (Level 5) — \_player doesn't know this*
- Same NPC_A is "bystander" in Instance 2 (Level 2)
- Same NPC_A is "player_character" in Instance 3 (Level 5)

**Antagonist Rule**: The antagonist is **always Level 5**, regardless of other factors. This ensures the primary opposition is always fully simulated and capable of complex planning/deception.

## Integration with AI

### Tool Calls by Agency Level

**Level 5**:

```
Available tools: [investigate, persuade, threaten, lie, plan_strategy,
                 analyze_situation, recall_memory, form_alliance, ...]
```

**Level 4**:

```
Available tools: [persuade, inform, react, basic_plan, search, ...]
```

**Level 3**:

```
Available tools: [respond, perform_job, basic_reaction]
```

**Level 2-1**:

```
Available tools: [] (handled by narrative description)
```

### Prompt Structure

Level 5 prompt includes:

- Full personality profile
- Complete relationship context
- Relevant memories
- Strategic objectives
- Current emotional state

Level 2 prompt:

- Basic trait
- Current action
- Simple reaction

## Performance Implications

**High Agency Cost**:

- More LLM calls per NPC
- Deeper context windows
- Complex decision trees
- Memory database queries

**Optimization Strategies**:

- Cache Level 2-3 responses (similar situations → similar responses)
- Batch process low-agency NPCs
- Precompute likely Level 4 reactions
- Focus real-time AI on Level 5 characters
