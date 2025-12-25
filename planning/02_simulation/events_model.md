# Events Model

## Overview

Events are recorded occurrences in the world that have happened and are remembered. They form the historical memory of Lagos Stories. This is distinct from instances (which are active gameplay) and situations (which are ongoing states).

## Core Attributes

### Identity (Definite Values)

- **Event ID**: Unique identifier
- **Type**: Category (crime, business, political, social, religious, disaster, scandal)
- **Timestamp**: When it occurred (tick, date, time)
- **Duration**: How long it lasted (instantaneous, hours, days)
- **Resolved**: Boolean (is it over, or ongoing consequences?)

### Participants & Location

- **Primary Actors**: NPCs who initiated or drove the event
- **Affected Entities**: NPCs, Organizations, Locations impacted
- **Location**: Where it happened
- **Witnesses**: NPCs who saw it (affects what they know/remember)

### Content

- **Summary**: Brief description (AI-generated or templated)
- **Key Details**: Structured data about what happened
  - For Crime: victim, perpetrator, method, stolen items
  - For Business: parties, transaction value, terms
  - For Political: officials involved, policy changes
  - For Social: participants, occasion, outcomes

### Impact & Consequences

- **Severity**: 0-100 (minor incident to major event)
- **Public Knowledge**: 0-100 (secret to widely known)
- **Ripple Effects**: References to other events or state changes it caused
- **Emotional Weight**: How much NPCs care about this (varies per NPC)

## Event Types

### Crime Events

- Theft, robbery, assault, murder
- Fraud, embezzlement, corruption
- Attributes: victim, perpetrator, evidence, police involvement

### Business Events

- Deals, mergers, bankruptcies
- Hiring, firing, promotions
- Attributes: organizations, monetary values, contracts

### Political Events

- Elections, appointments, scandals
- Policy changes, protests
- Attributes: officials, public approval shifts

### Social Events

- Weddings, funerals, parties
- Fights, reconciliations, betrayals
- Attributes: relationships changed, social dynamics

### Religious Events

- Ceremonies, conversions, conflicts
- Miracles/significant religious moments
- Attributes: religious institutions, attendees

### Disasters

- Accidents, fires, floods
- Power outages, infrastructure failures
- Attributes: location damage, casualties, economic impact

## Event Lifecycle

### 1. Event Occurs

- Generated during instance resolution or catch-up phase
- Assigned unique ID and recorded in world history

### 2. Event Memory

- Participants remember it (stored in their memory array)
- Organizations track events involving them
- Locations may be "marked" by major events

### 3. Event Ripples

- Consequences propagate (2-3 nodes)
- Reputation changes
- Relationship adjustments
- City situation metrics shift

### 4. Event References

- NPCs can reference events in dialogue
- Events can trigger future instances (e.g., "seeking revenge for [event_id]")
- Evidence/items can link back to events

## Event Recording Threshold

Events are recorded based on **impact** - calculated by the number and type of affected entities:

- High impact: Affects multiple NPCs, organizations, or locations → Always recorded
- Medium impact: Affects 1-2 entities significantly → Recorded
- Low impact: Minor interactions → Not recorded as events (may exist in conversation logs)

Examples:

- Casual conversation: Not recorded
- Argument that damages a relationship: Recorded
- Crime with victim: Recorded
- Business deal: Recorded

## Event Persistence

Events are **never forgotten** by the system. They remain in the global event log indefinitely to maintain historical continuity and enable long-term narrative arcs.

For performance optimization, a future system may automatically optimize context (e.g., summarizing old events), but this will be addressed during implementation.

## Event History & Queries

The game maintains a **global event log** that can be queried:

- "What crimes occurred in this district?"
- "What events involve this NPC?"
- "What happened at this location?"

This powers:

- AI narrative generation (referencing past events)
- Investigation instances (piecing together event history)
- NPC knowledge & rumors

## NPC Memory of Events

NPCs don't store complete event data. Instead:

- **Memory Structure**: Reference to event_id + personal nuance
- **Partial Knowledge**: NPCs may not have access to all information in an event
- **Character Perspective**: What they remember is filtered by:
  - What they witnessed directly
  - What they were told (could be incomplete or false)
  - Their emotional state at the time
  - Their relationship to participants

**Example**:

- Global Event: [Theft at market, victim: NPC_A, perpetrator: NPC_B, items: ₦50k]
- NPC_A memory: event_123, "I was robbed, lost everything, saw the thief's face"
- NPC_B memory: event_123, "Successfully took the money, no one saw me" (false belief)
- NPC_C memory: event_123, "Heard my friend was robbed, very upset" (secondhand info)

## Integration with Instances

### Instances → Events

- At instance resolution, significant occurrences become events
- Not everything in an instance becomes a recorded event (only consequential moments)
- Example: A conversation might not be an event, but a confession or betrayal would be

### Events → Instances

- Past events can trigger new instances
- Example: [Event: Theft at Market] → [Instance: Police Investigation]
- Example: [Event: Betrayal] → [Instance: Revenge Plot]
