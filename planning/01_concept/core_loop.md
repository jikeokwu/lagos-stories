# Core Gameplay Loop

## The Two-Layer System

The game architecture balances a persistent world state with focused scenario gameplay.

### 1. World Layer (Persistent City Simulation)

- **Scope**: Represents the entire city (districts, organizations, thousands of NPCs).
- **Simulation**: Does NOT actively progress. Uses lazy evaluation—entities are only updated when a new instance begins (for those not affected by the previous instance) or when directly involved in an instance.
- **Persistence**: Maintains the "truth" of the world. Changes (e.g., a mayor dying) are permanent and remembered.
- **Generation**: The world is generated upfront based on configurable parameters (population, economy, etc.).

### 2. Instance Layer (Scenario Instances)

- **Scope**: A focused "episode" involving a subset of the world (10-30 NPCs).
- **Gameplay**: High-fidelity, real-time (or fine-tick) interaction.
- **Structure**: Player controls a primary character; an antagonist or opposing force is usually present.
- **Nature**: Not standalone levels, but "slices" of the world.

## The Loop Cycle

1.  **World Catch-Up (Lazy Evaluation)**:
    - Before a new instance begins, entities _not_ affected by the previous resolution phase are "resolved" (abstract simulation) to bring them up to the current time.
    - **Goal**: This distributes computational load and avoids super long resolution phases at the end of a session.
2.  **Generation Phase**:
    - AI sets the stage, pulling relevant NPCs and context from the World Layer.
    - Objectives and tensions are established.
3.  **Gameplay Phase (Instance)**:
    - Player interacts via text.
    - AI interprets intent and drives NPC behavior.
    - Events occur in real-time/fine ticks.
4.  **Resolution Phase**:
    - Outcomes are assessed.
    - AI summarizes events and determines consequences.
5.  **Integration (World Update)**:
    - State changes are serialized back to the World Layer.
    - **Ripple Effects**: Consequences propagate **2-3 nodes away** across ALL entity types involved in the instance:
      - NPCs in social graphs (friends of friends)
      - Organizations (parent/child relationships, business partners)
      - City-level values (districts, infrastructure, economy)
      - Any other entity directly or indirectly connected to participants
    - Immediate network updates happen here; the rest of the world waits for the next "Catch-Up" phase.

## Open Questions
