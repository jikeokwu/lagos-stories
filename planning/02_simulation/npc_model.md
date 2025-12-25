# NPC Model

## Character Profile

Every NPC is a distinct agent with a persistent identity in the world database.

## Value Types

The game uses three kinds of values across all systems:

1. **Sliders**: Continuous scales with min/max (e.g., -100 to +100, or 0 to 100)
2. **Definite**: Fixed categorical values (e.g., male/female/non-binary, alive/dead)
3. **Scale**: Ordered progression values (e.g., skill levels: novice → competent → expert)

## Core Attributes

### Definite Properties

Unchanging or slowly-changing core traits:

- **Gender**: Male, Female, Non-binary
- **Age**: Integer (years)
- **Alive**: Boolean
- **Sexual Orientation** (Slider: -100 to +100):
  - **-100**: Purely same-sex attracted
  - **0**: Bisexual (equal attraction to all genders)
  - **+100**: Purely heterosexual
  - This slider is used in attraction calculations alongside other factors

### RPG Attributes (0-100)

Core stats that affect interactions, attraction, and gameplay mechanics:

- **Beauty**: Physical attractiveness (20-95) - Major factor in attraction calculations
- **Strength**: Physical power (30-90) - Declines with age after 50
- **Intellect**: Mental capacity (30-95) - Used in problem-solving, learning
- **Charisma**: Social charm and persuasion (20-95) - Affects interactions and attraction
- **Constitution**: Health and endurance (40-95) - Resistance to illness/stress
- **Agility**: Speed and reflexes (30-90) - Declines with age after 50

These attributes are generated at creation and modified by age, events, and training.

### Identity (Lagos-Specific Definite Values)

These fixed attributes determine social positioning and natural allegiances:

- **Tribe/Ethnicity**: Yoruba, Igbo, Hausa, Edo, Ijaw, etc.
- **Spoken Languages**: Array of languages (English, Yoruba, Igbo, Hausa, Pidgin, etc.)
- **Educational Background** (Object of objects by level):
  - Kindergarten: { institution: "Little Stars", years: "2000-2005" }
  - Primary: { institution: "St. Gregory's", years: "2005-2011" }
  - Secondary: { institution: "King's College", years: "2011-2017" }
  - Undergraduate: { institution: "University of Lagos", years: "2017-2021" }
  - Masters: { institution: "Covenant University", years: "2022-2024" }
  - _(Only populated levels are stored; creates alumni networks by institution + year)_
- **Religious Path** (Definite value + institution):
  - Path: Christian | Muslim | Traditional | None
  - If Christian and Religious Devotion > 40:
    - Institution: Which church (e.g., RCCG, Mountain of Fire)
    - Role: Member, deacon, elder, etc.
  - If Muslim and Religious Devotion > 40:
    - Institution: Which mosque (e.g., Central Mosque Lagos)
    - Role: Member, imam, etc.
  - If Traditional and Religious Devotion > 40:
    - Institution: Which shrine/traditional practice
    - Role: Initiate, priest, etc.

### Personality (Sliders: -100 to +100)

No hard traits like "ambitious" or "compassionate." Instead, continuous scales:

- **Ambition**: -100 (very unambitious) to +100 (extremely ambitious)
- **Compassion**: -100 (ruthless) to +100 (empathetic)
- **Volatility**: -100 (calm) to +100 (explosive)
- **Openness**: -100 (closed-minded) to +100 (open to new experiences)
- **Gender Bias**: -100 (strong bias against women) to 0 (neutral) to +100 (strong bias against men)
- **Ethnic Prejudice**: -100 (strongly prejudiced) to +100 (completely egalitarian)
- **Class Bias**: -100 (disdain for lower classes) to +100 (disdain for upper classes)
- **Religious Intolerance**: -100 (intolerant of other religions) to +100 (embraces religious diversity)
- **Social Conformity**: -100 (actively violates social norms) to +100 (strictly adheres to social norms)
  - Affects likelihood of actions like stealing, violence, sexual misconduct, public disruption, etc.
- _(Additional scales to be determined through prototyping)_

### Political & Ideological Values (Sliders: -100 to +100)

Inspired by Democracy game series—these determine how NPCs view policy, governance, and society:

- **Social Conservatism**: -100 (socially progressive) to +100 (socially conservative)
- **Economic Conservatism**: -100 (socialist/interventionist) to +100 (free market/capitalist)
- **Authoritarianism**: -100 (libertarian) to +100 (authoritarian)
- **Nationalism**: -100 (globalist) to +100 (nationalist)
- **Religious Devotion**: -100 (secular) to +100 (deeply religious)
- **Environmentalism**: -100 (anti-environment) to +100 (pro-environment)
- _(Additional ideological dimensions as needed)_

### Skills (Hierarchical, Dwarf Fortress-style)

- **Structure**: Overall categories + specific hard stats
  - **Category**: e.g., "Tech Skills" (derived value based on component skills)
  - **Specific Skills**: e.g., Programming: 5, Hardware: 3, Networking: 7
- **Boost Mechanic**: Specific skills give a boost to their parent category, making it easier to improve related skills in that category
- **Examples**:
  - Tech Skills → Programming, Hardware, Networking
  - Medical Skills → Surgery, Diagnosis, Pharmacology
  - Social Skills → Persuasion, Intimidation, Deception

### Resources (Type-Based System)

No single "money" value. Instead, resource types containing actual items with values:

- **Liquid Assets**:
  - Cash: ₦50,000
  - Bank Account (First Bank): ₦2,000,000
  - Mobile Money (OPay): ₦15,000
- **Property**:
  - Apartment (Lekki): Owned, valued at ₦30M
  - Car (Toyota Corolla 2018): Owned, valued at ₦5M
- **Access**:
  - VIP Club Membership: Active
  - Government Office Access: Level 3
- _(Resource types are extensible)_

### Status (Sims-style: 0-100 Sliders)

- **Health**: 0 (dying) to 100 (perfect health)
- **Stress**: 0 (relaxed) to 100 (breaking point)
- **Reputation**: 0 (unknown/despised) to 100 (renowned/loved)
- _(Additional status values as needed)_

## Social Context

### Demographic Group Affinities (Sliders: -100 to +100)

These represent "default allegiances" and natural groupings—NOT formal membership. NPCs have affinity/aversion relationships with demographic and political factions:

- **Religious Community**: -100 (hostile to religious groups) to +100 (deeply aligned)
- **Capitalist Class**: -100 (anti-business) to +100 (pro-business elite)
- **Working Class**: -100 (disdain for workers) to +100 (strong labor solidarity)
- **Youth Movement**: -100 (opposed to youth activism) to +100 (aligned with progressive youth)
- **Traditional Authorities**: -100 (reject traditional power) to +100 (respect traditional rulers)
- **Ethnic Solidarity Groups**: -100 (reject ethnic politics) to +100 (strong ethnic identity politics)
- _(Additional faction affinities as needed)_

**These interact with Identity markers**: An Igbo NPC with high Ethnic Solidarity (+80) is more likely to help other Igbo NPCs or favor Igbo-owned businesses.

### Relationships (Type + Universal Sliders)

Each relationship has:

- **Type**: Sibling, Parent, Child, Lover, Friend, Colleague, Rival, Enemy, etc.
- **Universal Sliders** (apply to ALL relationship types):
  - **Affection**: -100 (hate) to +100 (love)
  - **Trust**: -100 (complete distrust) to +100 (absolute trust)
  - **Attraction**: -100 (repulsion) to +100 (strong attraction)
    - **Note**: This is CALCULATED dynamically, not stored statically
    - Formula considers: Sexual orientation compatibility (50%), target's beauty/charisma (35%), target's reputation (15%)
    - Allows for asymmetric attraction (NPC A attracted to NPC B, but not vice versa)
  - **Respect**: -100 (contempt) to +100 (admiration)

**This allows complex dynamics**:

- A sibling you're attracted to (+60) but hate (-80) and don't trust (-40)
- A work rival you respect (+70) and trust (+50) but don't like (-20)
- Asymmetric attraction: You're very attracted to them (+80) but they're not attracted to you (-20) due to orientation mismatch

### Affiliations (Type + Sliders)

Each affiliation has:

- **Type**: Employee, Member, Leader, Contractor, Informant, etc.
- **Organization ID**: Reference to the organization entity
- **Sliders**:
  - **Loyalty**: -100 (actively undermining) to +100 (die-hard devotion)
  - **Investment**: 0 (detached) to 100 (deeply committed)
  - **Alignment**: -100 (opposed to org values) to +100 (perfectly aligned)

## Simulation Logic

- **Agency**: NPCs have goals and pursue them actively **during instances** and via abstract resolution **during catch-up phases**. They are not continuously simulated off-screen.
  - When involved in an instance: Full AI-driven behavior (dialogue, decisions, reactions).
  - When not involved: "Frozen" until the next catch-up, where lightweight rules determine what they've been doing.
- **Memory**: NPCs remember past interactions and world events, influencing future dialogue and decisions.

## Design Philosophy

- **Start Simple, Build Extensible**: Begin with core sliders and add more based on user testing.
- **System Expects Additions**: The architecture should make it easy to add new personality scales, skill categories, resource types, and relationship dimensions without refactoring.
- **No Hard Categories**: Prefer continuous scales over binary traits to allow nuance and emergent behavior.
