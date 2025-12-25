# Balance & Control: AI vs. System

## The Core Tension

Balancing the infinite freedom of AI with the need for a coherent, playable game.

## Key Design Challenges & Open Questions

### 1. NPC Autonomy & Agency Levels

NPCs have **full autonomy within instances**, but with varying levels of agency (1-5 scale).

#### Agency Scale (Instance-Specific)

**Level 5 - Maximum Agency**:

- **Roles**: Player character, antagonist
- **Simulation**: Full AI-driven decision-making
- **Tool Access**: All available actions and tools
- **Detail**: Highest simulation fidelity

**Level 4 - High Agency**:

- **Roles**: Important characters (key allies, major figures)
- **Simulation**: Detailed AI decision-making
- **Tool Access**: Most actions available

**Level 3 - Medium Agency**:

- **Roles**: Significant characters (named NPCs with roles)
- **Simulation**: Moderate AI involvement
- **Tool Access**: Common actions

**Level 2 - Low Agency**:

- **Roles**: Background characters with lines
- **Simulation**: Lightweight heuristics
- **Tool Access**: Basic interactions

**Level 1 - Minimal Agency**:

- **Roles**: Crowd/ambient NPCs
- **Simulation**: Simple scripted behavior
- **Tool Access**: None (narrative presence only)

#### Key Principles

- **Instance-Specific Tags**: "Antagonist," "player character," etc. are assigned per instance, not permanent NPC attributes
- **Variable Agency**: Same NPC can have different agency levels in different instances (Level 5 as protagonist in one instance, Level 2 as bystander in another)
- **Resource Allocation**: Higher agency = more AI calls and computation focused on that NPC

### 2. Antagonists and Off-Screen Activity

- **Decision**: The world uses **lazy evaluation**—entities don't progress in real-time when off-screen.
- **Antagonist Handling**:
  - During an instance, the antagonist is actively simulated.
  - Between instances, antagonists (like all entities) are "frozen" until the next catch-up phase.
  - When a new instance begins, unaffected entities (including antagonists) are resolved to the current time using abstract simulation.
- **Implication**: No "continuous scheming" that burns resources. Antagonist progress happens in discrete chunks, making it more manageable and debuggable.

### 3. Lazy Evaluation vs. Event-Driven AI

**Decision**: The World Layer never runs continuous simulation. Entities only update at specific trigger points:

1. **During an instance**: NPCs in the active instance are simulated in real-time (event-driven AI for dialogue, decisions).
2. **Catch-up phase**: When starting a new instance, entities NOT affected by the previous resolution are abstractly "fast-forwarded" to the current time.
3. **Chronicles Mode resolution**: When player manually resolves an entity in Chronicles/Legends mode, that entity and connected nodes are updated using the same catch-up system.

**AI Usage**: Heavy AI (LLM calls) reserved for in-instance events (dialogue, major decisions). Catch-up uses lightweight heuristics/rules.

#### Ripple Configuration (Player Setting)

Players can configure **ripple depth** - how many nodes away from affected entities get resolved:

- **Setting range**: 1-5 nodes (default: 2-3)
- **1 node**: Only direct participants updated (fastest, least coherent)
- **2-3 nodes**: Recommended balance (friends of friends, connected orgs)
- **4-5 nodes**: Deep simulation (extended networks, city-wide effects, slower)

**Impact**:

- Higher ripple depth = more coherent world, slower resolution
- Lower ripple depth = faster gameplay, potential inconsistencies
- Chronicles Mode manual resolution respects this setting

### 4. World Coherence and Narrative Control

- **Question**: How do we prevent AI from breaking the world logic (e.g., spawning aliens)?
- **Solution**: An "adjudication layer" or "Director" that vets events against world facts.

### 5. Player Freedom vs. Guidance

- **Question**: How do we handle "left-field" player actions (e.g., "I burn down the city")?
- **Approach**: Don't say "no," but implement realistic consequences and barriers. The simulation pushes back naturally.
- **Philosophy**: No "rails." If a player gets lost, that is part of the simulation. Provide diegetic tools (news, gossip) for them to find their way, but do not guide them explicitly.
