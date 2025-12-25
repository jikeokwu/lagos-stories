# Instance State & Gameplay Systems

This document describes game state tracking during instance play and core gameplay features.

## Instance State

When an instance begins, a separate state layer is created that tracks the active scenario.

### Instance Metadata

```json
{
  "instance_id": "inst-uuid",
  "world_id": "world-uuid",
  "start_timestamp": 1704067200,
  "start_date": "2024-01-01",
  "start_time": "09:00",
  
  "player_character_id": "npc-uuid",
  "antagonist_id": "npc-uuid",
  
  "type": "investigation",
  "title": "The Missing Generator",
  "premise": "A valuable generator has gone missing from the community center...",
  
  "status": "active",
  "turn_count": 0,
  "elapsed_time_minutes": 0
}
```

### Player Character Context

The **player character** is an existing NPC from the world. During the instance, this NPC is controlled by the player.

**Player Character State**:
- All NPC attributes (personality, skills, resources, relationships)
- Current location
- Inventory (items currently carrying)
- Active status effects (injured, exhausted, stressed)
- Known information (what they remember, what they've discovered)
- Current goals (player-defined or emergent)

**Player Actions Are Constrained**:
- Cannot act outside character capabilities
  - Cannot hack a computer without programming skill
  - Cannot bribe without sufficient money
  - Cannot threaten effectively with low intimidation skill
- Skill checks determine success probability
- Relationships affect NPC reactions (friend vs stranger vs enemy)

### Cast & Agency Assignments

**Cast List**: 5-12 NPCs involved in the instance

For each cast member:
```json
{
  "npc_id": "uuid",
  "role": "antagonist",
  "agency_level": 5,
  "initial_location": "loc-uuid",
  "goals": ["Prevent discovery", "Maintain reputation"],
  "threat_level": 65
}
```

**Agency Level Implications**:
- **Level 5** (Player, Antagonist):
  - Full AI reasoning every turn
  - Access to all action tools
  - Can form complex plans
  - Memory updates are detailed
  
- **Level 4** (Important NPCs):
  - AI reasoning every 2-3 turns
  - Most action tools available
  - Can adapt to changing situation
  - Moderate memory detail
  
- **Level 3** (Supporting NPCs):
  - AI reasoning when directly interacted with
  - Common actions only
  - React to immediate situation
  - Basic memory updates
  
- **Level 2** (Background NPCs):
  - Lightweight heuristics
  - Scripted responses
  - Minimal memory (just that they were present)
  
- **Level 1** (Crowd):
  - Narrative only (no individual tracking)

### Location Tracking

**Active Locations**: Subset of world locations relevant to instance

Each location tracks:
- Who is currently present
- What items are here
- Recent events at this location (within instance)
- Access restrictions (locked doors, private areas)

**Location State**:
```json
{
  "location_id": "loc-uuid",
  "current_occupants": ["npc-uuid-1", "npc-uuid-2"],
  "items_present": ["item-uuid-1"],
  "doors_locked": false,
  "lights_on": true,
  "last_event_here": "evt-uuid"
}
```

**Travel System**:
- Time cost to move between locations (5 minutes walking, 20 minutes driving across city)
- Some locations only accessible with transport
- Time of day affects location state (closed at night, etc.)

### Time Tracking

**Two Time Scales**:

1. **Real Time**: How long the player has been playing (wall clock)
2. **Simulation Time**: In-game time passage

**Time Progression**:
- Each action takes simulated time (talk: 5-10 min, travel: 10-60 min, investigation: 20-30 min)
- Time affects:
  - NPC schedules (where they are)
  - Location availability (businesses close)
  - Urgency (antagonist progresses their plan)
  - Status (hunger, energy decay)

**Time of Day Effects**:
- Morning (6am-12pm): Work hours, offices open
- Afternoon (12pm-6pm): Peak activity
- Evening (6pm-10pm): Social time, restaurants busy
- Night (10pm-6am): Most places closed, different crowd

### Turn Structure

**Player Turn**:
1. **Input**: Player types natural language action
2. **Intent Interpretation**: AI parses what player wants to do
3. **Validation**: Check if action is possible (location, skills, resources)
4. **Skill Check**: If applicable, roll against skill + modifiers
5. **Action Resolution**: Determine outcome
6. **World Update**: Change state (location, inventory, knowledge)
7. **Event Recording**: Log significant actions
8. **Narration**: AI describes what happened
9. **Time Advance**: Progress simulation time

**NPC Turn** (Agency-based):
- **Level 5 NPCs**: Act every turn (can pursue goals, react to player)
- **Level 4 NPCs**: Act every 2-3 turns or when interacted with
- **Level 3 NPCs**: Act only when player in same location
- **Level 2 NPCs**: Scripted reactions only
- **Level 1 NPCs**: No individual turns (part of narrative)

### Conversation System

**Dialogue States**:
- **Not in conversation**: Player can move freely
- **In conversation**: Talking with specific NPC

**Conversation Tracking**:
```json
{
  "active": true,
  "npc_id": "uuid",
  "location": "loc-uuid",
  "turn_count": 3,
  "topics_discussed": ["generator", "suspicious_activity"],
  "npc_mood": "guarded",
  "trust_shift": -5,
  "information_gained": ["Generator last seen at 8pm", "NPC X was nearby"]
}
```

**Conversation Mechanics**:
- NPC responses based on:
  - Relationship with player character (affection, trust, respect)
  - Personality (openness, social conformity)
  - What they know (knowledge level of events)
  - Their goals (may lie if antagonist)
  - Social context (public vs private)
- Skill checks:
  - Persuasion: Convince NPC to help
  - Intimidation: Threaten information out
  - Deception: Lie convincingly
  - Empathy: Read emotional state
- Conversation can change relationship values
- Information acquisition gates progress

### Investigation & Knowledge

**Player Knowledge Base**:
What the player character knows (not what the player knows as a human).

```json
{
  "facts": [
    {
      "fact": "Generator missing from community center",
      "source": "direct_observation",
      "reliability": 100,
      "learned_at": "turn_1"
    },
    {
      "fact": "John was seen near community center at 8pm",
      "source": "testimony_from_mary",
      "reliability": 70,
      "learned_at": "turn_5"
    }
  ],
  "suspicions": [
    {
      "suspect_id": "npc-john",
      "confidence": 60,
      "reasoning": "Was near scene, has history of theft"
    }
  ],
  "discovered_locations": ["loc-1", "loc-2", "loc-3"],
  "known_npcs": ["npc-1", "npc-2"]
}
```

**Investigation Actions**:
- Examine location (perception check)
- Search for clues (investigation skill)
- Interview witnesses (social skills)
- Follow suspect (stealth vs perception)
- Research (using resources, internet, documents)

### Inventory & Items

**Player Inventory**:
- Abstracted capacity (no hard limits, but reasonable)
- Track important items individually
- Generic items (cash, phone) just quantities

**Item Interactions**:
- Pick up / drop
- Give to NPC / trade
- Use item (consume, equip, show as evidence)
- Examine item (learn information)
- Combine items (craft, assemble)

**Important Items**:
- **Evidence**: Can be shown to NPCs, proves facts
- **Keys**: Grant location access
- **Weapons**: Enable combat actions (increase intimidation)
- **Documents**: Contain information, can be forged
- **Valuables**: Can be sold, traded, stolen

### Skill Checks & Success

**Skill Check System**:
```
Roll = Random(0-100)
Threshold = Base_Difficulty - (Skill_Value / 2) - Modifiers

Success if Roll < Threshold
```

**Modifiers**:
- Relationship bonus (+20 if friend, -20 if enemy)
- Circumstance (time pressure: -10, ideal conditions: +10)
- Resources (using right tool: +15)
- Status (injured: -10, stressed: -5)

**Degrees of Success**:
- **Critical Success** (Roll < Threshold - 20): Exceptional outcome
- **Success**: Achieve goal
- **Partial Success**: Achieve goal with complication
- **Failure**: Don't achieve goal
- **Critical Failure** (Roll > 90): Actively bad outcome

### Consequences & Stakes

**Instance Outcomes**:
- **Immediate**: Did player achieve stated goal?
- **Relationships**: Which NPCs like/dislike player more?
- **Reputation**: How do organizations/community view player?
- **Resources**: Money gained/lost, items acquired/lost
- **Knowledge**: What did player learn?
- **World Impact**: Did city metrics change? Organizations affected?

**Stakes Types**:
- **Personal**: Player's safety, reputation, relationships
- **Social**: Help friend, resolve community issue
- **Economic**: Financial gain/loss, job opportunities
- **Political**: Power dynamics, organizational influence
- **Moral**: Right vs easy, justice vs expedience

### Instance Termination

**Instance Ends When**:
- Player explicitly exits ("I'm done for now")
- Goal achieved (investigation solved, conflict resolved)
- Goal failed (player arrested, killed, antagonist succeeds)
- Time limit reached (if applicable)
- Player leaves active area (returns to world layer)

**On Instance End**:
1. Trigger resolution phase
2. Finalize all state changes
3. Create event records
4. Update NPC memories
5. Apply ripple effects
6. Save to database
7. Return to world layer

## Gameplay Features

### Action Categories

**Social Actions**:
- Talk / interview
- Persuade / negotiate
- Threaten / intimidate
- Deceive / lie
- Befriend / flirt
- Insult / provoke

**Investigation Actions**:
- Examine / search
- Follow / tail
- Stake out / observe
- Research / look up
- Ask around / gather rumors

**Movement Actions**:
- Go to [location]
- Enter / exit
- Hide / sneak
- Wait / pass time

**Item Actions**:
- Take / pick up
- Give / trade
- Use / activate
- Examine / read
- Steal / pocket

**Confrontation Actions**:
- Fight / attack
- Grab / restrain
- Threaten with weapon
- Run / flee
- Defend / block

**Economic Actions**:
- Buy / sell
- Bribe / pay off
- Invest / gamble
- Work / earn money

**Creative Actions**:
- Create / craft
- Repair / fix
- Destroy / break
- Modify / alter

**Organizational Actions**:
- Join organization
- Recruit member
- Assign task
- Call in favor

### Feedback Systems

**Player Receives**:
- **Narrative**: What happened and how
- **Mechanical**: Relationship changes, item acquired, skill check result
- **Hints**: AI subtly suggests possible actions ("You notice John looks nervous")
- **Status Updates**: Time passed, current location, inventory changes

**Player Does NOT See**:
- NPC internal sliders (personality, exact relationship values)
- Agency levels
- Antagonist threat level
- Future consequences
- Success probabilities

Mystery is maintained even though simulation is complex underneath.

### Command Examples

Natural language input, AI interprets:

- "I want to talk to John about the missing generator"
- "Search the community center for clues"
- "Follow Mary without her noticing"
- "Bribe the security guard to let me into the office"
- "Call my friend at the police for help"
- "Examine the contract document"
- "Go to Victoria Island and look for the pawn shop"
- "Wait until nighttime, then sneak into the warehouse"

AI figures out which action type, validates possibility, performs skill checks, generates outcome.

### Death & Failure

**Character Death**:
- Player character can die (violence, accident, illness)
- NOT game over - just end of this character's story
- Can switch to another character in the world
- Death creates event, affects relationships, becomes part of world history

**Failure States**:
- Arrested (might be temporary - can get released)
- Bankrupted (can recover)
- Exiled from area (social consequences)
- Goal failed (antagonist wins this round)

Failure is interesting and creates new stories.

### Save System

**Autosave**:
- Every turn
- On instance end
- On player exit

**Manual Save**:
- Player can save at any time
- Creates snapshot of current instance state
- Can load to retry different approach

**World Snapshots**:
- Before first instance in a play session
- Player can "rewind" world to any snapshot
- Supports experimentation

## Open Questions

None - this system integrates with all design decisions.

