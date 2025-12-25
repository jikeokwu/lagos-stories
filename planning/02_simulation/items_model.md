# Items Model

## Overview

Items are physical objects that NPCs can own, use, trade, or interact with. They exist within the resource system but have additional properties for gameplay.

## Core Attributes

### Identity (Definite Values)

- **Name**: Item name
- **Type**: Category (document, electronic, tool, weapon, vehicle, valuables, consumable)
- **Owner**: NPC or Organization ID (can be null for unowned items)
- **Location**: Where the item currently is (NPC inventory, organization storage, physical location)
- **Unique ID**: For tracking specific items (e.g., "this specific phone")

### Physical Properties

- **Condition**: 0-100 slider (broken to pristine)
- **Size**: Pocket, Hand-held, Carry, Vehicle, Immobile (scale)
- **Weight**: Affects portability
- **Transferable**: Boolean (can it be given/sold/stolen?)

### Functional Attributes

- **Use Cases**: What can be done with this item
  - Documents: Read, forge, destroy, show as evidence
  - Electronics: Call, record, hack, track
  - Weapons: Threaten, attack
  - Vehicles: Transport, status symbol
  - Tools: Enable certain actions (lockpick, medical kit)

### Value (Economic & Social)

- **Monetary Value**: ₦ amount (market price)
- **Sentimental Value**: 0-100 (for owner, affects willingness to part with it)
- **Legal Status**: Legal, Restricted, Illegal
- **Rarity**: Common, Uncommon, Rare, Unique (scale)

## Item Categories

### Documents

- IDs, passports, licenses
- Contracts, deeds
- Letters, notes
- Evidence, photographs
- Religious texts

### Electronics

- Phones, laptops
- Recording devices
- USB drives (can contain data/evidence)

### Tools & Equipment

- Medical supplies
- Lockpicks, tools
- Work equipment

### Weapons

- Knives
- Guns (illegal in Nigeria for most civilians)
- Improvised weapons

### Vehicles

- Cars, motorcycles
- Commercial vehicles (danfo buses, keke napep)

### Valuables

- Jewelry
- Art
- Cash (physical)
- Collectibles

### Consumables

- Food, drinks
- Drugs (legal medicine, illegal substances)

## Item Interactions

### Ownership Transfer

- **Purchase**: Legal exchange for money
- **Gift**: Voluntary transfer
- **Theft**: Illegal taking
- **Inheritance**: Transfer on death
- **Confiscation**: Taken by authority

### Item States

- **In Possession**: NPC carries/owns it
- **Stored**: At a location or in organization storage
- **Lost**: Whereabouts unknown
- **Destroyed**: No longer exists

### Evidence & Investigation

Items can serve as evidence in crime/investigation instances:

- Phone records reveal relationships
- Documents expose corruption
- Weapons link to crimes
- Photos prove events

## Item Lifecycle

Items are **fully persistent** and can be:

### Created

- During world generation (initial items distributed)
- During gameplay:
  - Crafted/manufactured (e.g., forge a document, cook food)
  - Purchased from shops
  - Generated as loot/rewards
  - Born from events (e.g., evidence created during a crime)

### Modified

- Condition degrades over time or through use
- Ownership transfers
- Value changes (market fluctuations, sentimental attachment)
- Items can be repaired, upgraded, or customized

### Destroyed

- Intentionally (burn evidence, demolish property)
- Accidentally (fire, theft gone wrong)
- Through decay (condition → 0)
- Items can be permanently removed from the world

## Item Persistence Strategy

Not all items are tracked with equal detail:

### Tracked Individually (Unique Items)

- **Story-relevant items**: Evidence, important documents, heirlooms
- **High-value items**: Vehicles, property deeds, expensive jewelry
- **Unique items**: One-of-a-kind objects with history
- Each has a unique ID and full attribute set

### Abstracted (Generic Items)

- **Bulk goods**: Generic furniture, common household items, disposable items
- **Consumables**: Food, common medicines (unless plot-relevant)
- Represented as quantities or categories rather than individual instances
- Example: "NPC has generic furniture" vs. tracking each chair

**Threshold**: Items become individually tracked when they:

- Appear in events (become evidence, stolen goods)
- Gain sentimental value
- Are referenced by NPCs or needed for instances

## Inventory System

NPCs use an **abstracted inventory** system:

- No hard carrying capacity limits (within reason)
- Items stored as lists/arrays
- Location tracking (on person, at home, in vehicle, in storage)
- Physical constraints handled narratively (can't hide a car in pocket, but can carry reasonable items)

Details of inventory constraints (weight, slots, etc.) will be specified during implementation based on gameplay needs.

## Integration with Other Systems

### Resources (NPC/Organization)

Items are the concrete manifestation of resource types:

- Liquid Assets → Cash, bank cards
- Property → Deed documents, keys
- Access → ID badges, membership cards

### Instances

Items enable or constrain actions:

- Can't hack without a laptop
- Can't bribe without money
- Can't prove something without evidence
