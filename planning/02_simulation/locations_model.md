# Locations Model

## Overview

Locations are physical spaces where instances occur, NPCs exist, and organizations operate. They range from entire districts down to individual rooms within buildings.

## Location Hierarchy

1. **District** (City subdivision)
   - Example: Lekki, Ikeja, Victoria Island
   - Contains: Multiple buildings, streets, public spaces
2. **Building** (Structure)
   - Example: Office tower, house, church, market
   - Contains: Multiple rooms/spaces
3. **Room/Space** (Specific area)
   - Example: Office 302, bedroom, church sanctuary, market stall

## Core Attributes

### Identity (Definite Values)

- **Name**: Official or colloquial name
- **Type**: Building type (residential, commercial, religious, industrial, public, infrastructure)
- **Address**: District + street/landmark
- **Size**: Small, Medium, Large, Massive (scale)
- **Ownership**: Owner entity (NPC, Organization, Government, Public)
- **Legal Status**: Registered, unregistered, disputed, illegal

### Physical Properties

- **Capacity**: Maximum occupants
- **Access Control**: Public, Private, Restricted, Members-only
- **Condition**: 0-100 slider (dilapidated to pristine)
- **Security Level**: 0-100 slider (open/vulnerable to fortified)

### Functional Attributes

- **Purpose**: What happens here (commerce, worship, residence, entertainment, crime)
- **Operating Hours**: If applicable (e.g., shop: 8am-8pm)
- **Connected Locations**: Adjacent spaces, entrances/exits

### Reputation (Slider Category: -100 to +100)

Locations have public perception:

- **Safety**: -100 (dangerous/notorious) to +100 (very safe)
- **Prestige**: -100 (slum/stigmatized) to +100 (elite/exclusive)
- **Activity Level**: 0 (abandoned) to 100 (bustling/overcrowded)

### Resources/Features

Locations can have:

- **Utilities**: Power, water, internet (boolean or quality slider)
- **Amenities**: Air conditioning, security system, parking
- **Special Features**: Hidden room, rooftop access, basement, etc.

## Location Types (Examples)

### Residential

- Single-family house
- Apartment building (with individual units)
- Compound (multiple structures)

### Commercial

- Office building (with individual offices)
- Shop/store
- Market (with stalls)
- Restaurant/bar

### Religious

- Church (with sanctuary, offices, classrooms)
- Mosque (with prayer hall, ablution area)
- Traditional shrine

### Public/Infrastructure

- Street/road
- Park
- Government building
- Police station
- Hospital (with wards, emergency, offices)
- School/University (with classrooms, halls)

### Illegal/Underground

- Gang hideout
- Drug den
- Illegal brothel

## Instance Integration

Locations serve as the "stage" for instances:

- **Instance Framing**: AI selects appropriate location(s) based on scenario needs
- **Bounded Space**: Instances typically occur in 1-3 connected locations (e.g., an office and hallway)
- **Dynamic Generation**: While locations are persistent, their current state (who's present, what's happening) is determined at instance start

## Room-Level Detail

Room descriptions are **AI-generated on-demand**:

- Basic structure defined (room type, size, purpose)
- Detailed descriptions generated when player enters or instance occurs there
- Allows for contextual descriptions that reflect current state

## Dynamic Location Creation

New locations can be added during gameplay:

- **Construction**: NPCs can build new structures (add room to house, open new shop)
- **Discovery**: Previously unknown locations revealed
- **Renovation**: Existing spaces repurposed or subdivided
- Changes are permanent and tracked in world state

## Location Event History

Locations track their own event history:

- Reference to all events that occurred there
- Affects location reputation and significance
- Powers narrative ("a murder happened here 3 years ago")
- Can be queried in **Chronicles Mode** (see below)

**Example**:

```
Location: Balogun Market, Stall 47
Event History:
  - evt-123: Theft (2023-05-12)
  - evt-456: Business deal (2023-08-03)
  - evt-789: Argument (2024-01-15)
```

## Chronicles Mode

Inspired by Dwarf Fortress's Legends mode, Lagos Stories includes **Chronicles Mode**—a browsable historical database of the entire world. See `chronicles_system.md` for full details.
