# AI Architecture & Integration

## Core Roles of AI

AI is not just for dialogue; it is the engine of the game's depth.

1.  **Interpreter of Intent**: Parses natural language input to understand player goals (e.g., "organize a block party") and translates them into game actions.
2.  **Content Generator**: Creates dialogue, location descriptions, backstories, and procedural quest-lines on the fly, bounded by world state.
3.  **Simulated Character Agency**: Drives NPC decision-making, giving them autonomy to pursue goals independent of the player.
4.  **Game Master / Director**: Orchestrates narrative pacing, introduces twists, and ensures the story remains engaging (e.g., introducing an antagonist when things get too quiet).
5.  **Outcome Adjudicator**: Determines the results of complex actions based on context and simulation rules.

## Integration Philosophy

- **Structured Generation**: AI output is constrained by the "ground truth" of the world model to prevent hallucinations and incoherence.
- **Collaborative**: AI acts as a partner, allowing players to improvise ("If you can describe it, the game will try to do it").

## Validation Pipeline (Multi-Layer)

To prevent AI hallucinations and ensure world consistency, we use a three-layer validation pipeline:

### 1. Constrained Premise Generation

- AI generates narrative premises/ideas within explicit constraints
- Constraints include: world facts, character states, available resources, physical laws
- Example prompt: "Generate a conflict involving [NPC_NAME] who has trust=-60 toward player, in [DISTRICT] where safety=30. No magic. No new characters."

### 2. Premise Fact-Check Layer

- Validate AI-generated premise against world state database
- Verify:
  - All referenced NPCs/entities exist
  - Attribute values match ground truth (e.g., if AI says "NPC trusts you," check trust value)
  - Location/resource availability is accurate
  - No violations of established world rules (no fantasy in Lagos)
- **Action**: If check fails, reject premise and regenerate OR flag specific violations for AI to revise

### 3. Convert Validated Premise to JSON

- Once premise passes fact-check, convert to structured JSON schema
- JSON contains actionable game data (entity IDs, attribute changes, event triggers)
- Game engine consumes JSON to execute the narrative
- Example output:

```json
{
  "event_type": "confrontation",
  "participants": ["npc_uuid_123", "player"],
  "location": "district_ikeja",
  "trigger_conditions": ["npc_uuid_123.trust < -50"],
  "narrative": "..."
}
```

This pipeline ensures AI creativity is bounded by simulation integrity.

## Task Categories for Model Selection

Users should be able to choose different AI models for different task types, allowing trade-offs between speed, quality, and hardware requirements:

1. **World Generation**: Creating the initial Lagos city (districts, NPCs, organizations, history)
   - Most expensive, only runs once per world
   - Can use largest/best model available
2. **Instance Framing**: Setting up a new scenario (selecting NPCs, establishing tensions, defining objectives)
   - Moderate cost, runs at the start of each instance
3. **Dialogue Generation**: NPC conversations and verbal interactions
   - High frequency, needs to be responsive
   - Trade-off: quality of conversation vs. speed
4. **Narrative Description**: Describing locations, events, atmosphere
   - Moderate frequency
5. **Intent Interpretation**: Parsing player text input into game actions
   - High frequency, critical for UX
   - Needs to be fast and accurate
6. **NPC Decision Making**: What does an NPC do in response to situations?
   - Moderate frequency (during instances)
7. **Outcome Adjudication**: Determining results of complex/ambiguous player actions
   - Moderate frequency
8. **Resolution & Consequences**: End-of-instance summary and ripple effects
   - Once per instance

**Example Configuration**:

- World Gen: 30B model (slow, but only runs once)
- Dialogue: 7B model (fast, runs constantly)
- Instance Framing: 14B model (balance)
