# Gameplay Mechanics

## Player Agency

- **Text-First Interaction**: Players interact via natural language. The AI parses intent into game actions.
- **Freedom**: "If you can describe it, the game will try to do it." (Within physical/logic limits).
- **Perspective**: Players can control one character through a life arc, or switch characters (e.g., to an heir or relative) to experience different angles of the city.

## Dynamic Gameplay Examples

- **Crime Networks**: Ignoring crime allows gangs to grow, leading to specific events (drug incidents, undercover cops).
- **Social Reputation**: Rumors spread based on player actions, affecting how NPCs treat you.
- **Adaptive Challenge**: If the player becomes too powerful, the AI generates coalitions to oppose them.

## Rules & Constraints

- **Capability-Bound**: Characters can only do what their skills and resources allow.
- **Costed Actions**: Everything takes time, money, or social capital.

## Win/Fail Philosophy

There are **no defined win or fail states**. Lagos Stories is a sandbox where players define their own goals and success criteria. This is not a consumer product with preset objectives—it's a simulation to explore.

Players might consider "winning" as:

- Achieving personal wealth/power
- Destroying an enemy
- Simply surviving
- Building a family legacy
- Changing the city
- Or just experiencing interesting stories

The game never tells you if you've "won" or "lost"—that judgment is yours alone.

## Instance Generation

### Situation-Based Triggers

City situations (metrics like Safety, Economy, Corruption) can trigger instance opportunities:

- **Low Safety** (< 30): Crime-related instances (robbery, gang conflict, police raids)
- **High Corruption** (> 70): Bribery opportunities, government scandals
- **Low Economy** (< 30): Unemployment stories, business bankruptcies
- **High Traffic** (> 80): Road rage incidents, transportation challenges

The AI uses these thresholds to suggest contextually appropriate instances when the player requests a new scenario.

## Action Verb System

The set of available action verbs will **evolve during development** through playtesting. Rather than defining all verbs upfront, we'll discover what's needed organically.

### Development Feedback Mode

When enabled, the AI provides developer feedback during play:

- Suggests new tools/actions that would be useful
- Identifies gaps in the action system
- Proposes verb categories based on player intent that couldn't be fulfilled
- Helps iteratively build the action vocabulary

This allows the game's capability to grow naturally based on actual play needs.

## Antagonist Behavior

Antagonists operate on a **Perceived Threat slider** (0-100).

**Note**: This is an **instance-specific** value, not a permanent NPC attribute. The same NPC acting as an antagonist in different instances (or toward different player characters) will have different threat perceptions.

### Threat Calculation

Based on:

- Player's reputation/influence
- Resources player has acquired
- Antagonist's goals threatened
- Recent player actions against antagonist
- Antagonist's personality (volatility, ambition)

### Escalation Based on Threat

**Low Threat (0-30)**:

- Passive observation
- Occasional minor obstacles
- Gathering information

**Medium Threat (31-60)**:

- Active interference
- Social maneuvering against player
- Resource competition
- Indirect attacks

**High Threat (61-85)**:

- Direct confrontation
- Aggressive moves
- Recruiting allies against player
- Risky gambits

**Critical Threat (86-100)**:

- Desperate measures
- All-out attack
- Scorched earth tactics
- May sacrifice own position to stop player

The threat level determines both **frequency** and **severity** of antagonist actions within instances.
