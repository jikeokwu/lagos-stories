# Organization Model

## Overview

Organizations are formal entities with membership, structure, and goals. Unlike demographic groups (which are informal affinities), organizations have explicit membership lists, leadership hierarchies, and stated missions.

## Organization Types

- **Business**: For-profit enterprises (tech startups, banks, markets, transport companies)
- **Gang/Criminal Network**: Illegal operations (drug trade, protection rackets, theft rings)
- **NGO**: Non-profit organizations (charities, advocacy groups, community organizations)
- **Government Body**: Official institutions (ministries, police, local government)
- **Religious Institution**: Churches, mosques, shrines, temples
- **Social Club**: Informal associations (alumni groups, ethnic associations, sports clubs)
- _(Additional types as needed)_

## Core Attributes

### Identity (Definite Values)

- **Name**: Official name of the organization
- **Type**: One of the organization types above
- **Founded**: Year established
- **Location**: Primary operating district(s)
- **Legal Status**: Registered, unregistered, illegal

### Pillars (Stated Mission/Goals)

Organizations have **pillars**—their stated values and mission. These are aspirational and may not reflect actual behavior.

**Pillars are mutable**: They can change through events, leadership changes, or member pressure.

**Pillars drive instance generation**: When pillars mismatch effective values, this creates dramatic opportunities. For example, an NGO with pillars of "community welfare" but members with high corruption values creates interesting instance scenarios (embezzlement, misuse of donor funds, internal whistleblowing).

- **Example (NGO)**: "Promote community welfare, reduce poverty, empower women"
- **Example (Business)**: "Maximize profit, maintain reputation, provide quality service"
- **Example (Gang)**: "Control territory, generate income, protect members"

### Effective Values (Aggregate of Members)

Organizations don't have fixed value sliders. Instead, their **effective values** are calculated as a **weighted aggregate** of member values:

```
Org Effective Value = Σ (Member Value × Member Weight) / Σ (Member Weight)
```

**Member Weight** is determined by:

- **Leadership Level**: CEO/President (10x), Manager/Elder (5x), Senior Member (2x), Member (1x)
- **Tenure**: Years in organization
- **Influence**: Based on their role and connections

**Example**:

- A business with 10 low-level employees (compassion: +40) and 1 CEO (compassion: -80, weight: 10x)
- Effective compassion = (10×40 + 1×10×(-80)) / (10 + 10) = (400 - 800) / 20 = -20

### Resources (Type-Based System)

Organizations have the same resource structure as NPCs:

- **Liquid Assets**: Cash reserves, bank accounts
- **Property**: Offices, warehouses, vehicles
- **Access**: Government connections, permits, licenses

### Structure (Hierarchy)

- **Members**: Array of NPC IDs with roles
  - Role examples: CEO, Manager, Employee, Member, Leader, Lieutenant, Follower
- **Leadership**: NPCs with decision-making authority (higher weights)

### Reputation (Slider Category: -100 to +100)

Organizations have public perception sliders across multiple dimensions:

- **Trustworthiness**: -100 (widely distrusted) to +100 (highly trusted)
- **Innovation**: -100 (stagnant/outdated) to +100 (cutting-edge/progressive)
- **Morality**: -100 (corrupt/immoral) to +100 (ethical/principled)
- **Conservatism**: -100 (radical/progressive) to +100 (traditional/conservative)
- **Influence**: -100 (powerless) to +100 (powerful/influential)
- _(Additional reputation dimensions as needed)_

These affect recruitment, partnerships, and how NPCs interact with the organization.

## Dynamics

### Member Value Conformity

When an NPC joins or remains in an organization, their values interact with the organization's effective values:

1. **Small Difference** (e.g., NPC compassion: +60, Org effective: +40):
   - Over time, NPC gradually conforms toward org values
   - Rate of conformity depends on loyalty/investment sliders
2. **Large Difference** (e.g., NPC compassion: +80, Org effective: -50):
   - Creates internal tension and dissonance
   - NPC may attempt to change the org (influence other members, challenge leadership)
   - Or NPC may leave the organization
   - Threshold for "too high" is a design parameter (e.g., difference > 80)

### Organizational Change

Since org values are aggregates of members, they change when:

- New members join or existing members leave
- Members' own values shift over time
- Leadership changes (high-weight members replaced)

This creates dynamic organizations that can drift ideologically based on membership composition.
