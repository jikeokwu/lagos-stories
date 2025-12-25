# World Simulation Model

## Simulation Philosophy

The world uses **lazy evaluation**: entities only update when involved in an instance or during catch-up phases between instances. This avoids expensive continuous simulation while maintaining the illusion of a living city.

## City-Level Systems

Lagos is modeled as a complex environment with interconnected systems that provide context and consequences for player actions.

### City Situations (Metrics: 0-100 Sliders)

Measurable state of the city that changes based on events and NPC actions:

- **Economy**: Overall economic health (GDP, business activity)
- **Safety**: Crime levels and public security
- **Infrastructure**: Quality of roads, power, water, transportation
- **Corruption**: Pervasiveness of corruption in government and institutions
- **Public Order**: Stability vs. unrest
- **Healthcare**: Quality and accessibility of medical services
- **Education**: Quality and accessibility of schools/universities
- **Traffic**: Congestion and transportation efficiency
- **Pollution**: Air quality and environmental health
- _(Additional metrics as needed)_

### Districts

Lagos is divided into districts, each with its own local situation values:

- **Example**: Lekki might have high economy (75), high infrastructure (70), but moderate traffic (50)
- **Example**: A lower-income district might have lower safety (30), lower infrastructure (40), but tight community bonds

## Entity Types

1. **The City**: Tracks macro signals (aggregate of all districts)
2. **Districts**: Sub-regions with local metric variations
3. **Organizations**: Businesses, gangs, NGOs, government bodies, religious groups (formal entities with membership). See `organization_model.md` for details.
4. **Demographic Groups**: Informal groupings based on identity (see below)
5. **Social Networks**: The web of connections between NPCs and organizations

## Demographic Groups (Identity-Based, Not Organizations)

NPCs don't "belong" to these groups in a formal sense. Instead, they have **relationship sliders** with each group representing affinity/aversion. These are "default allegiances" that naturally form social dynamics.

### Lagos-Specific Identity Markers

**Tribe/Ethnicity** (Definite value for NPC, relationship slider with each group):

- Yoruba
- Igbo
- Hausa
- Edo
- Ijaw
- _(Other Nigerian ethnic groups)_

**Spoken Languages** (Definite values: which languages NPC speaks):

- English
- Yoruba
- Igbo
- Hausa
- Pidgin
- _(Other languages)_

**Educational Background** (Definite values):

- Which school/university attended (e.g., University of Lagos, Covenant University)
- Year of attendance (creates cohorts and alumni networks)
- Level achieved (secondary, undergraduate, postgraduate)

**Religious Affiliation** (If Religious Devotion slider is high):

- Which church/mosque/temple (e.g., Redeemed Christian Church of God, Central Mosque)
- Role in congregation (member, deacon, etc.)

### Demographic/Political Factions (Relationship Sliders)

NPCs have affinity/aversion relationships with these groups (-100 to +100):

- **Religious Community**: How aligned with religious groups
- **Capitalist Class**: Affinity for business/wealth interests
- **Working Class**: Alignment with labor/worker interests
- **Youth Movement**: Alignment with young progressive activists
- **Traditional Authorities**: Respect for traditional rulers and customs
- **Ethnic Solidarity Groups**: Affinity for ethnic-based identity politics
- _(Additional factions as needed)_

**Example NPC**:

- Tribe: Igbo (definite)
- Speaks: English, Igbo, Pidgin (definite)
- Attended: University of Lagos, 2015 (definite)
- Church: Mountain of Fire (definite, because Religious Devotion: +70)
- Relationship with Religious Community: +80
- Relationship with Capitalist Class: +50
- Relationship with Working Class: -20
- Relationship with Youth Movement: +60

## Value Systems

Different entities optimize for different values:

- **City**: Stability, legitimacy, economic throughput
- **District**: Local prosperity, safety, community cohesion
- **Organization**: Organizations don't have fixed values. They have **pillars** (stated goals/mission), and their effective values are an **aggregate of member values** (with higher-level members weighted more heavily). See `organization_model.md`.
- **Individual**: (See NPC Model)

### Multi-Tier Value Interactions

AI agents evaluate value mismatches to create tensions. When an NPC's values conflict with their organization's aggregate values, this creates drama and decision points.

### Value Conformity Mechanic

- **Small Difference**: If the difference between an NPC's values and their organization's aggregate isn't too high, the NPC gradually conforms toward org values over time
- **Large Difference**: If the difference is too high, the NPC may take action:
  - Attempt to change the organization (influence other members, challenge leadership)
  - Leave the organization entirely

### Demographic Group Effects

NPCs' affinity/aversion scores with demographic groups affect their behavior in instances. Example: An NPC with high affinity for Ethnic Solidarity (+80) is more likely to help someone from their tribe, hire them, or show favoritism.
