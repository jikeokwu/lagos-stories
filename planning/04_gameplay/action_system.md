# Action System

## Overview

The action system is the primary mechanism for time passage within instances. Actions function as **tool calls**—structured operations that characters can perform, each with defined categories, costs, effects, and time requirements.

## Core Concept

### Time-Based Scheduling

Instead of turn-by-turn gameplay, instances operate on a **time-scheduled action system**:

1. **Player Input**: Player describes what they want to accomplish and specifies how much time should pass (e.g., "I want to investigate the missing generator for the next 2 hours")
2. **AI Scheduling**: The AI agent automatically creates a schedule of action calls (tool calls) that will fill the specified time period
3. **Parallel Execution**: Action schedules are created for:
   - The player character
   - All NPCs in the instance (based on their agency levels and goals)
4. **Time Passage**: All scheduled actions execute, advancing simulation time until the target duration is reached
5. **Feedback**: Player receives flavor text and outcomes as actions complete

### Key Characteristics

- **Player Visibility**: Players can see and edit their own scheduled action calls before time passes
- **NPC Opacity**: Players cannot see NPC schedules—NPCs just "have them" and execute them
- **Flavor Text**: Each action generates narrative description as it executes
- **Flexible Duration**: Player chooses how much time to advance (minutes, hours, or even days)

## Action Structure

### Action Definition

Each action is a structured tool call with the following components:

```json
{
  "action_id": "uuid",
  "action_type": "investigate_location",
  "category": "investigation",
  "actor_id": "npc-uuid",
  "target_id": "loc-uuid",
  "parameters": {
    "focus": "search_for_clues",
    "thoroughness": "detailed"
  },
  "time_cost_minutes": 30,
  "resource_costs": {
    "energy": -10,
    "money": 0
  },
  "prerequisites": {
    "skills": ["investigation"],
    "location": "loc-uuid",
    "items": []
  },
  "effects": {
    "knowledge_gain": ["clue_1", "clue_2"],
    "relationship_changes": {},
    "status_changes": { "stress": +5 }
  },
  "success_probability": 0.75,
  "flavor_text_template": "You carefully examine {location_name}, searching for any signs of {focus}..."
}
```

### Action Categories

Actions are organized into categories that determine their behavior and availability:

**Social Actions**:

- `talk_to_npc`: Conversation with specific NPC
- `persuade`: Attempt to convince NPC
- `intimidate`: Threaten or coerce NPC
- `deceive`: Lie or mislead NPC
- `befriend`: Build positive relationship
- `gather_rumors`: Collect information from multiple sources

**Investigation Actions**:

- `investigate_location`: Search location for clues
- `examine_item`: Study an object in detail
- `follow_npc`: Track an NPC's movements
- `stake_out`: Observe location/NPC over time
- `research`: Look up information (documents, internet, records)
- `interview_witness`: Formal questioning

**Movement Actions**:

- `travel_to_location`: Move between locations
- `enter_location`: Access a specific area
- `wait`: Pass time without action
- `sneak`: Move stealthily

**Item Actions**:

- `pick_up_item`: Acquire an object
- `drop_item`: Leave an object
- `use_item`: Activate/consume an item
- `give_item`: Transfer item to NPC
- `steal_item`: Take item without permission

**Confrontation Actions**:

- `attack`: Physical violence
- `threaten`: Verbal intimidation with implied violence
- `restrain`: Physically control NPC
- `flee`: Escape from situation
- `defend`: Protect self or others

**Economic Actions**:

- `buy`: Purchase goods/services
- `sell`: Sell items
- `bribe`: Pay for illegal cooperation
- `work`: Perform job for money
- `invest`: Financial investment

**Organizational Actions**:

- `call_favor`: Request help from organization
- `assign_task`: Delegate to subordinate
- `recruit`: Add member to organization
- `report_to`: Inform superior

**Creative Actions**:

- `craft`: Create new item
- `repair`: Fix broken item
- `forge`: Create fake document/item
- `modify`: Alter existing item

### Action Costs

**Time Cost**:

- Each action consumes simulated time (measured in minutes)
- Time costs vary by action type and parameters
- Examples:
  - Quick conversation: 5-10 minutes
  - Detailed investigation: 30-60 minutes
  - Travel across city: 20-40 minutes
  - Full work shift: 8 hours (480 minutes)

**Resource Costs**:

- **Energy**: Physical/mental exertion
- **Money**: Financial expenditure
- **Social Capital**: Reputation, favors
- **Items**: Consumable resources

**Skill Requirements**:

- Actions may require minimum skill levels
- Missing skills reduce success probability or prevent action entirely

### Action Effects

Actions produce various effects when executed:

**Knowledge Effects**:

- Discover facts
- Learn NPC information
- Uncover clues
- Gain insights

**Relationship Effects**:

- Modify relationship sliders (affection, trust, respect)
- Change NPC attitudes
- Create/enhance/damage relationships

**Status Effects**:

- Change health, stress, energy
- Apply temporary conditions (injured, exhausted, suspicious)
- Modify reputation

**World State Effects**:

- Move items between locations
- Change location state (doors locked, lights on/off)
- Trigger events
- Modify city metrics

**Resource Effects**:

- Gain/lose money
- Acquire/lose items
- Consume resources

## Scheduling System

### Player Schedule Creation

When player requests time passage:

1. **Intent Parsing**: AI interprets player's goal ("investigate generator", "talk to suspects", "gather information")
2. **Action Selection**: AI selects appropriate actions to achieve goal
3. **Time Filling**: Actions are chained until target duration is reached
4. **Schedule Preview**: Player sees proposed action sequence
5. **Editing**: Player can:
   - Remove actions
   - Reorder actions
   - Add actions manually
   - Adjust action parameters
   - Change time duration
6. **Confirmation**: Player approves schedule, time passes

**Example Schedule**:

```
09:00 - Travel to Community Center (15 min)
09:15 - Investigate location: search for clues (45 min)
10:00 - Talk to security guard about generator (10 min)
10:10 - Research generator specifications online (20 min)
10:30 - Travel to suspect's location (20 min)
10:50 - Stake out suspect's house (30 min)
11:20 - [Schedule complete - 2 hours 20 minutes elapsed]
```

### NPC Schedule Creation

NPCs receive automatic schedules based on:

**Agency Level**:

- **Level 5**: Complex multi-action plans pursuing goals
- **Level 4**: Detailed action sequences with adaptation
- **Level 3**: Simple action chains, reactive behavior
- **Level 2**: Basic routine actions
- **Level 1**: No individual schedule (narrative only)

**NPC Goals**:

- Antagonist: Pursue opposition to player
- Ally: Support player or pursue shared goals
- Neutral: Follow routine or personal objectives

**NPC Personality**:

- Traits influence action selection (aggressive NPCs choose confrontational actions)
- Values determine priorities (money-focused NPCs prioritize economic actions)

**NPC Knowledge**:

- NPCs act on what they know
- Limited information leads to less effective actions

**NPC Resources**:

- Actions constrained by available resources
- NPCs may need to acquire resources before acting

### Schedule Execution

**Parallel Processing**:

- All character schedules execute simultaneously
- Actions resolve in chronological order
- Conflicts resolved by:
  - Time priority (earlier actions first)
  - Actor priority (Level 5 > Level 4 > Level 3)
  - Random tiebreaker

**Action Resolution**:

1. Check prerequisites (location, skills, resources)
2. Roll success probability
3. Apply effects
4. Generate flavor text
5. Update world state
6. Advance time

**Interruptions**:

- Actions can be interrupted by:
  - Other characters' actions (NPC arrives, conflict occurs)
  - External events (police raid, weather change)
  - Player intervention (if player edits schedule mid-execution)
- Interrupted actions may:
  - Complete partially (partial effects)
  - Fail entirely
  - Resume later

## Player Interface

### Schedule View

**Visualization**:

- Timeline showing scheduled actions
- Color coding by category
- Time markers showing duration
- Success probability indicators

**Editing Capabilities**:

- Drag-and-drop reordering
- Click to edit parameters
- Add/remove actions
- Adjust time duration
- Preview effects before execution

**Information Display**:

- Current location
- Available actions (filtered by prerequisites)
- Resource status
- Known NPCs and their locations
- Time of day effects

### Execution View

**Flavor Text Display**:

- Narrative description of each action as it executes
- Highlighted key outcomes
- Relationship changes shown subtly
- Knowledge discoveries emphasized

**Status Updates**:

- Time progression
- Location changes
- Resource changes
- Status effect notifications

**NPC Activity Hints**:

- Vague descriptions ("You notice John seems busy")
- Indirect effects ("The office feels tense")
- No explicit schedule visibility

## Integration with Existing Systems

### Agency System

Action availability and complexity varies by agency level:

- **Level 5**: Full action set, complex multi-step plans
- **Level 4**: Most actions, moderate planning
- **Level 3**: Common actions, simple sequences
- **Level 2**: Basic actions only
- **Level 1**: No individual actions

### Instance State

Actions modify instance state:

- Location occupancy
- Item locations
- NPC knowledge
- Relationship values
- Event history

### Skill System

Actions require and test skills:

- Prerequisites check minimum skill levels
- Success probability modified by skill values
- Skill checks determine action outcomes
- Skills improve through use

### Time System

Actions drive time progression:

- Each action consumes time
- Time affects:
  - NPC schedules (where they are)
  - Location availability
  - Status decay (hunger, energy)
  - Urgency (antagonist progress)

## Known Issues & Refinements Needed

### Current Limitations

**Janky Aspects**:

1. **Schedule Preview Complexity**: Showing all actions upfront may overwhelm players
2. **Editing Overhead**: Manual schedule editing might feel like work rather than play
3. **NPC Opacity**: Players may feel frustrated not knowing what NPCs are doing
4. **Time Estimation**: AI may struggle to accurately estimate action durations
5. **Interruption Handling**: How to handle conflicts between parallel schedules
6. **Action Granularity**: Some actions too broad, others too narrow
7. **Flavor Text Quality**: Ensuring narrative descriptions feel meaningful

### Refinement Directions

**Potential Improvements**:

1. **Adaptive Scheduling**:

   - AI learns from player edits to improve future schedules
   - Player can set preferences ("I prefer detailed investigation over quick checks")

2. **Partial Visibility**:

   - Show NPC actions that player character would notice
   - Perception checks determine what player sees
   - Maintain mystery while reducing frustration

3. **Action Templates**:

   - Pre-defined action sequences for common goals
   - "Investigation Routine": Search → Interview → Research → Follow-up
   - Players can customize templates

4. **Progressive Disclosure**:

   - Show high-level schedule first ("Investigate for 2 hours")
   - Allow drilling down to see specific actions
   - Default to summary view, expand on demand

5. **Smart Interruptions**:

   - System detects when NPC actions conflict with player schedule
   - Pause execution to show interruption
   - Allow player to react before continuing

6. **Action Validation**:

   - Better prerequisite checking before scheduling
   - Warn about impossible actions
   - Suggest alternatives when actions fail validation

7. **Time Compression**:

   - For long durations, allow "fast-forward" mode
   - Show only significant events
   - Skip routine actions automatically

8. **Schedule Templates**:

   - Common patterns: "Morning Routine", "Investigation Session", "Social Gathering"
   - Players can save and reuse schedules
   - NPCs can have routine schedules

9. **Action Feedback Loop**:

   - After execution, show what worked/didn't work
   - Suggest improvements for next schedule
   - Learn player preferences over time

10. **Hybrid Mode**:
    - Option to switch between scheduled and turn-based
    - Some players prefer more control
    - Scheduled mode for efficiency, turn-based for precision

## Open Questions

1. **Schedule Length**: What's the optimal maximum duration? (Hours? Days? Weeks?)
2. **Action Granularity**: Should "investigate location" be one action or broken into sub-actions?
3. **NPC Schedule Visibility**: Should players ever see NPC schedules? (Maybe in Chronicles mode after instance ends?)
4. **Failure Handling**: What happens when scheduled actions fail? Do subsequent actions adjust?
5. **Resource Management**: How do NPCs handle resource constraints in schedules? Do they automatically acquire resources first?
6. **Multi-Character Control**: If player controls multiple characters, how do schedules interact?
7. **Action Discovery**: How do players learn about available actions? Tutorial? Discovery? Documentation?
8. **Schedule Persistence**: Can schedules be saved and reused? Should NPCs remember successful schedules?
9. **Time Compression**: Should very long schedules (days/weeks) be compressed differently than short ones (hours)?
10. **Action Dependencies**: How to handle actions that depend on previous action outcomes? Dynamic rescheduling?
11. **Player Agency**: Is editing schedules enough control, or do players need more direct action-by-action control?
12. **Flavor Text Generation**: Should flavor text be generated during scheduling (preview) or during execution (dynamic)?
13. **Action Costs**: Are current cost structures balanced? Should some actions be cheaper/more expensive?
14. **Schedule Conflicts**: How to resolve when multiple characters want to use same resource/location simultaneously?
15. **Action Effectiveness**: Should actions have diminishing returns? (First investigation finds clues, second finds less)
