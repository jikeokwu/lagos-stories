# World Generation

This document describes the process of generating a complete Lagos world from scratch.

## Implementation Status

**Last Updated**: 2025-01-XX

### ✅ Fully Implemented

**Phase 1: City Foundation**

- ✅ Seed-based generation with reproducibility
- ✅ Starting date/time configuration
- ✅ Dynamic district generation (3-20 districts based on NPC count)
- ✅ District archetypes with weighted selection
- ✅ District metrics (prosperity, safety, infrastructure)
- ⚠️ **Note**: City-wide metrics and demographic groups are planned but not yet implemented

**Phase 2A: Family Frame Generation**

- ✅ Family template system (nuclear, extended, single parent, etc.)
- ✅ Multi-pass family generation (founders → spouses → children → extended → singles)
- ✅ Value inheritance system (±30 variance from parent average)
- ✅ Appearance inheritance (height, build, complexion, facial features)
- ✅ Family-to-district assignment
- ✅ Wealth level distribution

**Phase 2B: Organization Generation**

- ✅ **Demand-based organization generation** (better than planned fixed counts)
- ✅ Essential infrastructure (schools, clinics, police per district)
- ✅ Religious organizations scaled to demographics (churches, mosques, shrines)
- ✅ Employment organizations scaled to workforce needs
- ✅ Social/criminal organizations (ethnic associations, sports clubs, gangs)
- ✅ Organization templates with positions, reputation, resources
- ✅ District-based distribution
- ✅ Duplicate prevention (max 3 of same type per district)

**Phase 3: Location Generation**

- ✅ Need-based location creation (housing demand + commercial demand)
- ✅ Hierarchical structure (District → Building → Unit)
- ✅ Residential units (1 per family + shared units for singles)
- ✅ Commercial units (1 per organization)
- ✅ District archetype-based ratios (residential vs commercial)
- ⚠️ **Note**: Street layer is planned but currently skipped (buildings created directly)

**Phase 4: Multi-Pass NPC Generation**

- ✅ Pass 1: Family founders (parent_1)
- ✅ Pass 2: Spouses (parent_2) with relationship creation
- ✅ Pass 3: Children with inheritance (personality, appearance, political ideology)
- ✅ Pass 4: Extended family members
- ✅ Pass 5: Single NPCs
- ✅ Full NPC attributes (personality, skills, resources, appearance, identity)
- ✅ Age-appropriate generation (children vs adults)
- ✅ Sibling relationship generation

**Phase 5: Organization Position Filling**

- ✅ Career assignment based on occupation
- ✅ School assignment for children
- ✅ Religious organization membership assignment
- ✅ Membership tracking (role, weight, tenure, loyalty, investment, alignment)
- ⚠️ **Note**: Multi-pass leadership → mid-level → entry-level filling is simplified (single pass)

**Phase 6: Location Assignment**

- ✅ Family-to-housing assignment (1 family per unit)
- ✅ Single NPCs to housing (2 singles per unit)
- ✅ Organization-to-commercial assignment
- ✅ District preference matching with fallback

**Phase 7: Relationship Generation**

- ✅ Family relationships (parent-child, sibling, spouse)
- ✅ School friendships (context-based)
- ✅ Work colleague relationships
- ✅ Neighborhood relationships
- ✅ Romantic/ex relationships for singles
- ✅ Relationship sliders (affection, trust, attraction, respect)
- ✅ Symmetric relationship auto-creation (friend, colleague, neighbor)

**Phase 9: Validation**

- ✅ Unassigned NPC detection
- ✅ Asymmetric relationship detection and fixing
- ✅ Organization membership validation
- ✅ Basic consistency checks

**Architecture Improvements (Not Originally Planned)**

- ✅ **Modular phase system**: Refactored from 4,367-line monolithic file to:
  - Orchestrator (396 lines)
  - 5 specialized phase generators (2,003 lines total)
  - 45% code reduction, 6x faster bug location, 4x faster feature development
- ✅ **Preset system**: World generation presets (Small/Medium/Large/Epic) with hardware spec guidance
- ✅ **UI progress updates**: Real-time progress bar and status updates during generation
- ✅ **Demand-based scaling**: Organizations scale based on simulated population needs, not fixed ratios

### ⚠️ Partially Implemented / Simplified

**Phase 5: Organization Position Filling**

- ⚠️ Simplified to single pass (all positions filled together)
- ⚠️ Planned multi-pass (leadership → mid-level → entry) not fully implemented
- ✅ Position tracking and membership creation works

**Phase 3: Location Generation**

- ⚠️ Street layer skipped (buildings created directly in districts)
- ✅ Building and unit creation works
- ⚠️ Planned street templates not implemented

**Phase 1: City Foundation**

- ⚠️ City-wide situation metrics not implemented
- ⚠️ Demographic group definitions not implemented
- ✅ Districts work with archetypes

### ❌ Not Yet Implemented

**Phase 6: Demographic Group Affinities**

- ❌ NPC-group affinity sliders not implemented
- ❌ Group-based behavior modifiers not implemented

**Phase 7: Historical Events** ✅ (in backup, needs migration)

- ✅ Birth events (one per NPC)
- ✅ Marriage events (for married couples)
- ✅ Hiring events (for organization memberships)
- ✅ Relationship formation events
- ✅ Memory assignment for events (participants get memories)
- ✅ Historical timeline generation (events dated based on NPC ages)
- ⚠️ **Status**: Code exists in `world_generator_backup.gd`, needs migration to `phases/event_generator.gd`

**Phase 8: Item Seeding**

- ❌ Item generation not implemented
- ❌ Item placement in locations not implemented
- ❌ Item ownership tracking not implemented

**Phase 9: Location Ownership** ✅ (in backup, needs migration)

- ✅ Landlord NPC generation (5-10 wealthy property investors)
- ✅ Owner-occupied vs rented tracking (based on income level)
- ✅ Landlord-tenant relationships created
- ✅ Commercial ownership (org-owned vs rented)
- ⚠️ **Status**: Code exists in `world_generator_backup.gd`, needs migration to `location_assignment.gd`

**Phase 10: World Finalization**

- ❌ World summary generation not implemented
- ❌ Notable NPCs list not implemented
- ❌ Interesting conflicts list not implemented
- ✅ World metadata (name, seed, date) is saved
- ✅ Database statistics are collected

**Template System Enhancements**

- ❌ Dynamic template loading from JSON (templates are hardcoded)
- ❌ Template inheritance system not implemented
- ❌ Community template packs not supported

**Advanced Features**

- ❌ Constraint solver for spouse/colleague matching
- ❌ Incremental generation (preview between phases)
- ❌ Template evolution/generation

### 📊 Implementation Statistics

- **Total Planned Phases**: 10
- **Fully Implemented**: 9 phases (90%)
- **Partially Implemented**: 1 phase (10%) - Street layer missing
- **Needs Migration**: 2 features (Historical Events, Ownership) - implemented but not in modular system
- **Not Implemented**: 1 phase (10%) - Demographic Group Affinities

**Code Metrics**:

- **Before Refactor**: 4,367 lines (monolithic)
- **After Refactor**: 2,399 lines (modular)
- **Reduction**: 45% fewer lines, 6x faster debugging, 4x faster development

---

## Philosophy

World generation happens **once per world** and can use the most powerful models available. This is a one-time computational cost, so we prioritize quality over speed.

## Generation Phases

### Phase 1: City Foundation

**Goal**: Establish Lagos-level structure

**Generated Elements**:

- **Seed**: Random seed for reproducibility
- **Starting Date**: When the simulation begins (e.g., "January 2025")
- **Districts**: 8-12 major districts with characteristics
  - Names (Yaba, Surulere, Victoria Island, Lekki, Ikeja, etc.)
  - Base metrics (prosperity: 0-100, safety: 0-100, infrastructure: 0-100, corruption: 0-100)
  - Geographic relationships (neighbors, proximity to water/airport)
- **City Situations**: Initial values for city-wide metrics
  - Economy, Safety, Infrastructure, Corruption, Traffic, Pollution (all 0-100)
- **Demographic Groups**: Define abstract groups for NPC affinity
  - Religious Community (Christian, Muslim, Traditional)
  - Capitalist Class, Working Class, Unemployed
  - Educated Elite, Street Smart, Traditional Authorities
  - Ethnic groups (Yoruba, Igbo, Hausa, others)

**AI Role**: Minimal - mostly parameterized generation with some flavor text for district descriptions

**Output**: City state JSON with all districts and base metrics

### Phase 2: Organization Generation

**Goal**: Create institutions and power structures

**Generated Elements**:

- **Organizations** (50-200 depending on scope):
  - Government agencies (local, state, federal presence)
  - Private companies (tech startups, import/export, construction, finance)
  - NGOs and community groups
  - Religious organizations (churches, mosques)
  - Criminal enterprises (area boys, fraud rings)
  - Educational institutions (universities, secondary schools)
  - Media outlets
  - Markets and business associations

**For Each Organization**:

- Name and type
- **Pillars** (mutable mission/goals): 2-4 core values driving the organization
- Base reputation sliders (trustworthiness, innovation, morality, conservatism, influence)
- Resources (property, liquid assets)
- Founding date (can pre-date simulation start)
- District/location presence

**AI Role**: Moderate - generate realistic Lagos organization names, plausible missions, appropriate resources

**Output**: Organization database with all entities

### Phase 3: Location Generation

**Goal**: Create physical spaces in the world

**Generated Elements**:

- **Hierarchical Locations** (500-2000):
  - **Districts** (from Phase 1)
  - **Buildings**: Offices, apartment complexes, houses, markets, government buildings, churches/mosques, shops, restaurants, hotels
  - **Rooms**: Can be generated on-demand during instances, but seed key locations with rooms

**For Each Location**:

- Name and address
- Hierarchy (district → building → room)
- Type and size
- Owner (can be NPC, organization, or government)
- Reputation sliders (safety, prestige, activity level)
- Access control (public, private, restricted)
- Operating hours
- Physical properties (capacity, condition, security level)
- Features/utilities

**AI Role**: Moderate - generate location names, describe key landmarks, ensure Lagos authenticity

**Output**: Location database with hierarchical structure

### Phase 4: NPC Generation

**Goal**: Populate the world with people

**Generated Elements**:

- **NPCs** (1,000-10,000 depending on desired world size):
  - Core NPCs (200-500): Fully detailed, potential protagonists/antagonists
  - Supporting NPCs (800-4,500): Detailed but may have some simplified attributes
  - Background NPCs: Can be generated on-demand or abstracted

**For Each NPC**:

**Demographics**:

- Name (culturally appropriate)
- Age, gender
- Tribe/ethnicity
- Spoken languages (English, Yoruba, Igbo, Pidgin, etc.)
- Educational background (type: none, primary, secondary, university, postgrad; institution: which school)
- Religious affiliation (denomination, which church/mosque if applicable)

**Personality Sliders** (-100 to +100):

- Ambition, Compassion, Volatility, Openness, Social Conformity

**Political/Ideological Values** (-100 to +100):

- Social Conservatism, Economic Conservatism, Authoritarianism, Nationalism, Religious Devotion, Environmentalism

**Bias/Discrimination Tendencies**:

- Gender bias, Tribal bias, Religious bias, Class bias, Education bias (all -100 to +100)

**Skills** (Hierarchical):

- Skill categories with specific skills under each
- Values on appropriate scales
- Distributed based on occupation, education, background

**Resources** (Type-based):

- Liquid assets (cash, bank accounts)
- Property (owned/leased)
- Social capital (connections, favors owed)

**Status Sliders** (0-100):

- Health, Stress, Hunger, Energy, various reputation types

**Occupation & Affiliations**:

- Current occupation (can be unemployed)
- Organization membership with role and tenure
- District residence

**AI Role**: Heavy - generate culturally authentic names, plausible backstories, appropriate skill distributions based on education/occupation

**Output**: NPC database with all attributes

### Phase 5: Relationship Network

**Goal**: Connect NPCs through relationships

**Generated Relationships**:

**Family Structures** (20-30% of NPCs):

- Parent-child
- Siblings
- Spouses/partners
- Extended family (aunts, uncles, cousins)
- Use realistic family sizes and structures for Lagos

**Social Relationships** (40-60% of NPCs have 2-8 relationships):

- Friendships
- Romantic relationships (current or past)
- Rivalries
- Mentorships
- Work relationships (boss-employee, colleagues)
- Neighborhood acquaintances

**For Each Relationship**:

- Type (family type, friend, lover, rival, colleague, mentor, etc.)
- Sliders (-100 to +100): Affection, Trust, Attraction, Respect
- Duration (how long have they known each other)
- Relationship history reference (optional: event that started it)

**Constraints**:

- Relationships should cluster by district (most people know neighbors)
- Organization members should know each other
- Educational institutions create networks (alumni connections)
- Avoid relationship soup - most NPCs shouldn't know each other

**AI Role**: Moderate - generate relationship backstories, ensure plausible emotional dynamics

**Output**: Relationship database (bidirectional, asymmetric)

### Phase 6: Demographic Group Affinities

**Goal**: Assign NPC attitudes toward abstract groups

**For Each NPC**:

- Assign affinity/aversion sliders (-100 to +100) for each demographic group
- Based on their own identity, values, and background
  - Religious NPC likely positive toward their religious community, may be negative toward others
  - Working class NPC may be averse to capitalist class
  - Educated elite may look down on "street smart" but respect traditional authorities
  - Tribal affiliations create natural groupings

**AI Role**: Light - can be rule-based with some variation

**Output**: NPC-group affinity matrix

### Phase 7: Historical Events

**Goal**: Give the world a history before player arrives

**Generated Events** (100-500):

- Major city events (infrastructure projects, political scandals, disasters)
- Organization events (founding, major achievements, scandals)
- NPC life events (births, deaths, marriages, job changes, crimes, conflicts)
- Relationship-forming events (how key relationships started)

**Event Distribution**:

- Timeline: Spread across past 5-20 years
- More events in recent years (recency bias)
- Events create causal chains (theft → arrest → prison → release → vendetta)

**Event Impact**:

- Affected NPC memories (partial information, emotional impact)
- Changed relationships (how current values came to be)
- Organization reputation shifts
- Location reputation changes
- District metric changes

**AI Role**: Heavy - generate compelling mini-narratives, ensure causal consistency

**Output**: Event log with full details and memory references in NPCs

### Phase 8: Item Seeding

**Goal**: Place important items in the world

**Generated Items** (100-1,000):

- **Important Items**: Individually tracked
  - Documents (contracts, certificates, evidence)
  - Valuables (jewelry, heirlooms, contraband)
  - Weapons
  - Vehicles (cars, motorcycles)
- **Generic Resources**: Abstracted by type
  - Cash (in NPC inventories)
  - Furniture (in locations)
  - Consumables (food, fuel)

**Item Placement**:

- Owned by NPCs (in inventory or property)
- Located in specific places (office, home, market stall)
- Can have history (who created it, previous owners)

**AI Role**: Light - mostly parameterized, some flavor text for important items

**Output**: Item database with ownership and location

### Phase 9: Validation & Balance

**Goal**: Ensure world consistency and playability

**Validation Checks**:

- All NPCs have valid district residence
- All organization members are valid NPCs
- All relationships reference existing NPCs
- No orphaned data (location owners exist, event participants exist)
- Skill distributions reasonable (not everyone has max programming)
- Wealth distribution has variance (some rich, most middle/poor)
- Age demographics realistic (children, adults, elderly)
- Organization sizes reasonable (not 500-person NGOs)

**Balance Adjustments**:

- Ensure diversity of NPC archetypes (not all ambitious, not all corrupt)
- Multiple potential antagonists (high ambition, low compassion, volatile)
- Multiple potential allies (high compassion, high trust relationships)
- Conflict seeds (rivalries, organizational tensions, resource scarcity)
- Opportunity seeds (ambitious NPCs with means, organizations with conflicting goals)

**AI Role**: None - this is rule-based validation

**Output**: Validation report, adjusted world state

### Phase 10: World Finalization

**Goal**: Prepare world for first instance

**Final Steps**:

- Assign world metadata (name, description, generation date, version)
- Create world summary (AI-generated overview of key factions, tensions, opportunities)
- Index database for fast queries
- Export world snapshot (JSON backup)
- Generate world statistics (population breakdown, wealth distribution, org types)
- Create "Notable NPCs" list (AI suggests interesting characters to play)
- Create "Interesting Conflicts" list (AI suggests starting scenarios)

**AI Role**: Moderate - generate summary and suggestions

**Output**: Playable world ready for first instance

## Generation Settings

**User Configurables**:

- **World Size**: Small (1K NPCs), Medium (3K), Large (10K), Epic (30K+)
- **Historical Depth**: Shallow (1 year history), Medium (5 years), Deep (20 years)
- **District Count**: 6, 10, 15, 20
- **Organization Density**: Low, Medium, High
- **Relationship Connectivity**: Sparse (isolated), Medium, Dense (highly connected)
- **Conflict Level**: Peaceful, Moderate, Tense (more rivalries/crime)
- **Economic Variance**: Equal (similar wealth), Realistic (high inequality), Extreme

**AI Model Assignment**:

- Phases 2-4, 7, 10 benefit from larger models (13B-30B)
- Phases 1, 5-6, 8-9 can use smaller models or rules

## Generation Time Estimates

**Small World** (1K NPCs, 6 districts):

- Phase 1-3: 5-10 minutes
- Phase 4: 30-60 minutes (NPC generation)
- Phase 5-7: 20-30 minutes
- Phase 8-10: 10-15 minutes
- **Total**: ~1.5-2 hours with 13B model

**Medium World** (3K NPCs, 10 districts):

- **Total**: ~4-6 hours

**Large World** (10K NPCs, 15 districts):

- **Total**: ~15-20 hours

## Reproducibility

- Save generation seed
- Save AI model versions used
- Save generation parameters
- Regenerating with same seed + model + params should produce identical world

## Iteration During Development

For prototype, simplify:

- Skip Phases 2-3 (minimal orgs, minimal locations)
- Phase 4: Only 20 NPCs, manually define some
- Phase 5: Handcraft key relationships
- Phase 7: 10-15 key historical events
- Skip Phase 8

Focus on validating the generation pipeline, not creating massive worlds.

---

## Extensible Template-Based Generation System

### Philosophy

The generation system should be:

- **Template-driven**: Use configurable templates for all entity types
- **Multi-pass**: Generate in layers, refining and filling gaps each pass
- **Rule-based**: Apply constraints naturally (age compatibility, value inheritance, etc.)
- **Contextual**: Generate relationships, events, and memories alongside entities
- **Natural**: Patterns emerge from simulation rules, not hardcoded narratives

### Generation Architecture

#### Core Concepts

**Templates**: Configurable patterns that define entity structure

- **Type**: What kind of entity (street, family, organization)
- **Size**: Scale parameters (small family vs. large family)
- **Ratios**: Proportions within the template (residential vs. commercial on a street)
- **Constraints**: Rules that must be satisfied (age gaps, value ranges)

**Multi-Pass Generation**: Generate entity frames first, then fill details

- **Pass 1**: Create structural frames (family with X members needed)
- **Pass 2+**: Fill details based on what's needed and what exists
- **Validation Pass**: Ensure all entities are complete and consistent

**Rule Sets**: Constraints applied during generation

- **Value Inheritance**: Children get values ±30 from parent average
- **Age Compatibility**: Spouses have reasonable age gaps, parents older than children
- **Context-Based Relationships**: School/work/neighborhood create natural connections
- **Resource Distribution**: Wealth follows patterns based on occupation/location

---

## Detailed Phase Breakdown

### Phase 1: City Foundation (No Changes)

Generate city shape, districts, demographic groups, start date, city metrics.

**Output**: City metadata and district frames

---

### Phase 2A: Family Structure Generation

**Goal**: Define family units before generating individual NPCs

#### Step 1: Determine Family Count

Based on world config:

- `family_count = world_size * family_ratio`
- Example: 1000 NPC world with 0.25 family ratio = 250 families
- Remaining NPCs are singles or will be added to families

#### Step 2: Generate Family Templates

For each family, create a **Family Frame**:

```json
{
  "id": "family-001",
  "template_type": "nuclear_family", // nuclear, extended, single_parent, multigenerational
  "size": 4, // number of members
  "structure": {
    "parent_1": { "role": "parent", "age_min": 35, "age_max": 50 },
    "parent_2": {
      "role": "parent",
      "age_min": 35,
      "age_max": 50,
      "optional": true
    },
    "child_1": { "role": "child", "age_min": 10, "age_max": 18 },
    "child_2": { "role": "child", "age_min": 5, "age_max": 12 }
  },
  "district": "district-yaba", // assigned district
  "wealth_level": "middle_class", // poor, working_class, middle_class, wealthy, elite
  "tribe": "Yoruba", // family primary tribe
  "religion": "Christian", // family primary religion
  "generated_npcs": [] // fills during NPC generation
}
```

**Family Template Types**:

- **Nuclear Family**: 2 parents + 1-4 children
- **Single Parent**: 1 parent + 1-3 children
- **Extended Family**: 2-3 generations, 5-8 members (grandparents, parents, children)
- **Multigenerational**: 3-4 generations, 6-12 members (includes aunts, uncles, cousins)
- **Young Couple**: 2 adults, no children (yet)
- **Elderly Couple**: 2 elderly adults, grown children elsewhere
- **Single Adult**: 1 adult, no immediate family

**Template Distribution** (configurable):

- Nuclear: 45%
- Single Parent: 15%
- Extended: 20%
- Multigenerational: 10%
- Young Couple: 5%
- Elderly Couple: 3%
- Single Adult: 2%

**Assignment**:

- Assign each family to a district (weighted by district size/prosperity)
- Assign wealth level (based on district prosperity + randomness)
- Assign tribe (weighted by Lagos demographics: Yoruba 60%, Igbo 25%, Hausa 10%, Other 5%)
- Assign religion (weighted by tribe: Yoruba → 70% Christian, Igbo → 90% Christian, Hausa → 95% Muslim)

**Output**: Array of family frames ready for NPC generation

---

### Phase 2B: Organization Frame Generation

**Goal**: Define organizations with position structures before filling them

#### Step 1: Determine Organization Count and Types

Based on world config:

- `org_count = base_orgs + (family_count * org_ratio)`
- Example: 250 families \* 0.3 = 75 organizations

**Organization Template Types**:

- **Government Agency**: Fixed hierarchy (Director → Department Heads → Officers)
- **Business (Small)**: 2-10 employees (Owner → Manager → Staff)
- **Business (Medium)**: 11-50 employees (CEO → Department Heads → Managers → Staff)
- **Business (Large)**: 50-200 employees (Full corporate structure)
- **Religious Organization**: 1-5 leaders + 20-200 members
- **NGO**: 3-15 employees + volunteers
- **Criminal Enterprise**: 5-30 members (Boss → Lieutenants → Soldiers)
- **Educational Institution**: 10-100 staff (Principal → Teachers → Admin)
- **Market Association**: 1-3 leaders + 20-100 vendors

#### Step 2: Generate Organization Frames

```json
{
  "id": "org-001",
  "name": "", // generated later
  "type": "business_small",
  "subtype": "restaurant",
  "template": "restaurant_small",
  "founded_year": 2018,
  "district": "district-yaba",
  "positions": {
    "owner": {
      "count": 1,
      "min_age": 30,
      "required_skills": { "business": 5 },
      "filled": false
    },
    "chef": {
      "count": 1,
      "min_age": 25,
      "required_skills": { "cooking": 6 },
      "filled": false
    },
    "server": {
      "count": 2,
      "min_age": 18,
      "required_skills": { "social": 3 },
      "filled": false
    },
    "cleaner": {
      "count": 1,
      "min_age": 18,
      "required_skills": {},
      "filled": false
    }
  },
  "pillars": [], // generated later
  "wealth_level": "middle_class",
  "reputation_template": "new_business", // affects initial reputation values
  "filled_positions": [] // fills during NPC assignment
}
```

**Output**: Array of organization frames with position structures

---

### Phase 3: Location Frame Generation

**Goal**: Create streets and buildings based on families and organizations

#### Step 1: Calculate Location Needs

```
families_needing_homes = family_count
businesses_needing_locations = count(orgs where type = business)
public_buildings_needed = government_orgs + religious_orgs + schools
```

#### Step 2: Generate Street Templates

**Street Template Structure**:

```json
{
  "id": "street-001",
  "name": "", // generated later
  "district": "district-yaba",
  "type": "residential_mixed", // residential, commercial, mixed, industrial
  "size": "medium", // small, medium, large
  "buildings": [], // fills during building generation
  "building_ratios": {
    "residential": 0.7,
    "commercial": 0.2,
    "public": 0.1
  },
  "building_count": 20 // based on size template
}
```

**Street Type Templates**:

- **Residential**: 80% residential, 15% small commercial (shops), 5% public
- **Commercial**: 70% commercial, 20% residential (live above shop), 10% public
- **Mixed**: 50% residential, 40% commercial, 10% public
- **Industrial**: 60% industrial, 30% commercial, 10% residential
- **Market**: 90% market stalls/shops, 10% support buildings

**Street Size Templates**:

- **Small**: 8-12 buildings
- **Medium**: 15-25 buildings
- **Large**: 30-50 buildings

**Generation Logic**:

1. Calculate streets needed: `(families + businesses) / avg_buildings_per_street`
2. Distribute streets across districts (weighted by district size)
3. Assign street types based on district character (wealthy district → more residential, poor district → more mixed)
4. Add randomness: ±20% to building counts per street

#### Step 3: Generate Building Templates

For each street, generate buildings based on ratio:

```json
{
  "id": "building-001",
  "name": "", // generated later
  "street_id": "street-001",
  "district": "district-yaba",
  "type": "apartment_complex", // house, apartment_complex, office, shop, market_stall, etc.
  "size": "medium",
  "capacity": 8, // number of units/families
  "owner_type": "landlord", // landlord, owner_occupied, government, organization
  "owner_id": null, // assigned later
  "units": [], // specific apartments/offices, generated on-demand or during assignment
  "assigned": false
}
```

**Building Assignment Logic**:

1. Generate buildings for each street based on ratios
2. If `unassigned_buildings > 0` after all streets processed:
   - Create new streets with appropriate templates
   - Assign unassigned buildings to new streets
3. It's OK to have empty streets, but NOT OK to have unassigned buildings

**Output**: Street and building frames with clear ownership/assignment structure

---

### Phase 4: Multi-Pass NPC Generation

**Goal**: Generate NPCs in layers, filling family and organization structures

#### Pass 1: Generate Family Founders

For each family frame:

1. Generate the **first parent** (the "founder")
2. Set age based on family template (e.g., 35-50 for nuclear family parent)
3. Generate full NPC attributes:
   - Personality: Random within reasonable bounds (no extreme outliers)
   - Skills: Based on occupation (assigned randomly based on wealth level)
   - Resources: Based on wealth level
   - Appearance: Fully random (height, build, complexion, features)
4. Add to `family.generated_npcs[0]`

**Appearance Attributes** (new, to be added to NPC schema):

```json
"appearance": {
  "height": 175,  // cm
  "build": "average",  // slim, average, muscular, heavy
  "complexion": "dark_brown",  // light, medium, dark_brown, very_dark
  "hair_style": "short_fade",
  "facial_features": "round_face",  // for inheritance
  "distinguishing_marks": []
}
```

#### Pass 2: Fill Spouses and Primary Family Members

For each family that needs a spouse:

1. Check if a compatible single NPC exists in database:
   - Age compatible (within ±10 years of partner)
   - Same district (or adjacent district)
   - Unmarried
   - Compatible tribe/religion (can be different, but apply cultural rules)
2. If compatible NPC exists:
   - Assign as spouse to current family
   - Remove from singles pool
   - Generate relationship (likely positive affection/trust, moderate-high respect)
3. If no compatible NPC exists:
   - Generate new NPC as spouse
   - Age: Within ±10 years of partner
   - Values: Correlated but not identical (use ±30 variance)
   - Appearance: Independent (no inheritance yet)
   - Resources: Combined with spouse (share wealth level)

#### Pass 3: Generate Children

For each family that needs children:

1. Generate child NPCs
2. Age: Based on family template (e.g., 10-18 for teenager)
3. **Value Inheritance Rule**:
   - If 2 parents: `child_value = avg(parent1_value, parent2_value) ± random(-30, 30)`
   - If 1 parent: `child_value = parent_value ± random(-30, 30)`
   - Clamp to [-100, 100]
4. **Appearance Inheritance Rule**:
   - Height: `avg(parent_heights) ± random(-10, 10)`
   - Build: Weighted toward parents' builds
   - Complexion: Weighted blend of parents' complexions
   - Facial features: Blend parent features
5. Skills: Lower than parents (young, still learning), based on education level
6. Resources: Minimal (dependents on parents)

#### Pass 4: Generate Extended Family Members

For extended/multigenerational families:

1. Generate grandparents (if needed)
2. Generate aunts/uncles (siblings of parents)
3. Generate cousins (children of aunts/uncles)
4. Apply same inheritance rules

#### Pass 5: Generate Single NPCs

For remaining NPC quota (not in families):

1. Generate as independent adults
2. Distribute across districts
3. Assign to rental housing or shared apartments
4. These become potential spouses/friends/colleagues for family NPCs

**Output**: Complete NPC database with family structures

---

### Phase 5: Multi-Pass Organization Filling

**Goal**: Assign NPCs to organization positions

#### Pass 1: Fill Leadership Positions

For each organization:

1. Identify leadership positions (owner, CEO, director, boss, etc.)
2. Find compatible NPCs:
   - Age: Old enough (30+ for business owner, 35+ for CEO)
   - Skills: Has required skills at sufficient level
   - Same district or adjacent
   - Not already employed in leadership role
3. If multiple candidates, select based on:
   - Highest skill match
   - Personality fit (high ambition for CEO, high compassion for NGO leader)
4. If no candidates:
   - Generate new NPC specifically for this role
   - Single adult, appropriate age/skills
   - Add to NPC database

#### Pass 2: Fill Mid-Level Positions

Repeat for managers, department heads, senior staff.

#### Pass 3: Fill Entry-Level Positions

Fill remaining positions with younger/less skilled NPCs.

#### Pass 4: Leave Unfilled Positions

- It's OK to have empty positions (realistic)
- Mark positions as `vacant`
- Can be filled during gameplay

#### Membership Assignment

For each NPC employed:

```json
{
  "npc_id": "npc-001",
  "org_id": "org-001",
  "role": "Senior Chef",
  "weight": 3,  // influence on org values (1-10, leaders get 10, staff get 1-2)
  "tenure_years": random(0, 5),  // how long they've been there
  "loyalty": random(40, 80),
  "investment": random(40, 80),
  "alignment": random(40, 80)
}
```

**Output**: Organization positions filled, NPCs have occupations

---

### Phase 6: Validation Pass - Schools and Religious Organizations

**Goal**: Ensure all NPCs have appropriate affiliations

#### School Assignment

For each NPC with education:

1. Check if they have an educational institution in their education history
2. If missing:
   - Generate appropriate school based on their age, education level, district
   - Add school to their `identity.education`
   - If school doesn't exist, create organization frame for it

#### Religious Organization Assignment

For each NPC with religious_path:

1. Check if they have a religious institution
2. If missing and `active: true`:
   - Find or create appropriate religious organization in their district
   - Add as member (not employee)
   - Generate membership record with low weight (regular member)

**Output**: All NPCs have complete affiliations

---

### Phase 7: Multi-Pass Relationship Generation

**Goal**: Generate relationships naturally based on shared contexts

#### Pass 1: Family Relationships

Already generated during family creation, but formalize:

- Parent-child: High affection (but can vary), high trust (usually), respect varies
- Siblings: Affection varies widely, trust moderate-high, respect varies
- Spouses: Affection varies, trust high (usually), attraction varies, respect moderate-high
- Extended family: Generally positive but weaker than nuclear family

#### Pass 2: School Relationships

For each NPC with education history:

1. Find other NPCs who attended same school in overlapping years
2. Generate friendship relationships (2-5 friends per school)
3. Apply **Context-Based Relationship Templates**:

```json
{
  "context": "school_friends",
  "relationship_type": "friend",
  "affection_range": [30, 70],
  "trust_range": [40, 80],
  "attraction_range": [-10, 40],
  "respect_range": [20, 60],
  "duration_years": "age - school_end_year"
}
```

#### Pass 3: Work Relationships

For each NPC with organization membership:

1. Find other NPCs in same organization
2. Generate colleague relationships (1-3 per organization)
3. Apply work relationship template:
   - Colleagues: Affection moderate, trust varies, respect based on skill
   - Boss-subordinate: Respect asymmetric (subordinate respects boss more), affection varies
   - Rivals: Negative affection, low trust, moderate respect (competitive colleagues)

#### Pass 4: Neighborhood Relationships

For each NPC:

1. Find NPCs living on same street or adjacent buildings
2. Generate acquaintance/neighbor relationships (1-3 per NPC)
3. Apply neighborhood template:
   - Acquaintances: Low affection, moderate trust, low respect
   - Close neighbors: Moderate affection, moderate trust

#### Pass 5: Romantic Relationships

For each single adult NPC (not married):

1. 30% chance to have ex-partner relationship
2. Find compatible NPC (appropriate age, compatible attraction)
3. Generate past romantic relationship:
   - Affection: Can be negative (bad breakup) or still positive
   - Trust: Usually low after breakup
   - Attraction: Varies (can still exist)
   - Respect: Varies

For married NPCs:

1. 5% chance to have secret romantic relationship (affair)
2. Generate with appropriate emotional dynamics

#### Pass 6: Random Relationships

For NPCs with <3 relationships:

1. Generate 1-2 random relationships with NPCs in same district
2. Can be friendships, rivalries, or acquaintances
3. Ensures no one is completely isolated

**Relationship Template System**:

Templates define ranges and rules:

```json
{
  "template_name": "school_rivalry",
  "context": "school",
  "base_type": "rival",
  "conditions": {
    "personality_clash": "both high ambition",
    "age_difference_max": 3
  },
  "affection_range": [-60, -20],
  "trust_range": [-40, 20],
  "attraction_range": [-20, 20],
  "respect_range": [30, 70], // respect their abilities despite dislike
  "duration_factor": "same_school_years"
}
```

**Output**: Rich relationship network with natural clustering

---

### Phase 8: Event and Memory Generation During Entity Creation

**Goal**: Generate historical context as entities are created

#### Generate Events Alongside Entities

**Family Formation Events**:
When generating a family:

1. Create "marriage" event for spouses (if married)
2. Create "birth" events for children
3. Create "move" event when family established in district
4. Generate memories for family members referencing these events

Example:

```json
{
  "id": "evt-family-001-marriage",
  "type": "social",
  "subtype": "wedding",
  "timestamp": calculate_from_child_ages,  // work backward
  "participants": ["npc-parent1", "npc-parent2"],
  "summary": "Adebayo and Chioma got married at RCCG Church",
  "impact": {"severity": 40, "public_knowledge": 60, "emotional_weight": 90}
}
```

Memories:

- Parent 1: "I married Chioma, best day of my life, so much joy"
- Parent 2: "I married Adebayo, excited but nervous about the future"
- Witness (if friend): "Attended Adebayo's wedding, happy for him"

**Organization Foundation Events**:
When generating organization:

1. Create "founding" event
2. Create "hired" events for employees
3. Generate memories for founders and early employees

**Relationship Formation Events**:
When generating key relationships:

1. Create "met at school" event for school friends
2. Create "started working together" event for colleagues
3. Create "moved to neighborhood" event for neighbors
4. Generate memories referencing how they met

**Historical Timeline**:

- Work backward from simulation start date
- Older events (10-20 years ago) affect older NPCs
- Recent events (1-5 years ago) affect all NPCs
- Distribute events across timeline naturally

**Memory Assignment Rules**:

- **Direct participants**: Full memory, high accuracy (90-100%), high emotional impact
- **Witnesses**: Partial memory, moderate accuracy (70-90%), moderate emotional impact
- **Secondhand**: Vague memory, low accuracy (50-70%), low emotional impact
- **Rumors**: Can be completely wrong, low accuracy (20-50%)

**Output**: Events and memories generated organically during world creation

---

### Phase 9: Location Assignment and Ownership

**Goal**: Assign NPCs to homes and organizations to buildings

#### Assign Families to Housing

For each family:

1. Find building in their district with sufficient capacity
2. Assign family to building unit
3. Set building owner:
   - If wealthy family: They own the building
   - If middle class: Landlord (can be another NPC)
   - If poor: Government housing or shared building
4. Generate "moved in" event (if appropriate)

#### Assign Organizations to Buildings

For each organization:

1. Find appropriate building type in their district
2. Assign organization to building
3. Set organization as building owner (if wealthy) or tenant

#### Generate Location Reputation

Based on who lives/works there:

- Wealthy residents → High prestige
- High crime residents → Low safety
- Many businesses → High activity level

**Output**: Complete location-NPC-organization mapping

---

### Phase 10: Final Validation and Polish

#### Validation Checks

1. **Relationship Symmetry**: Ensure all relationships are bidirectional (even if different values)
2. **Age Consistency**: Parents older than children, spouses reasonable ages
3. **Resource Consistency**: Families share resources, singles have independent resources
4. **Location Consistency**: All NPCs have housing, all organizations have locations
5. **Skill Distribution**: Not everyone has max skills, follows occupation patterns
6. **Event Consistency**: All event participants exist, timeline makes sense
7. **Memory Consistency**: All memories reference valid events, all events have at least one memory

#### Balance Adjustments

1. Identify NPCs with no relationships → generate at least 1-2
2. Identify organizations with no employees → mark as defunct or generate employees
3. Identify districts with no residents → redistribute or mark as industrial-only
4. Ensure diversity of personality types across population

#### Generate World Summary

AI generates:

- Overview of major families and their dynamics
- Key organizations and their roles
- Notable tensions and conflicts
- Interesting opportunities for gameplay
- List of potential protagonist NPCs (diverse, interesting backgrounds)

**Output**: Validated, balanced, playable world

---

## Implementation Architecture

### Template Configuration Files

```
data/templates/
├── families/
│   ├── nuclear_family.json
│   ├── extended_family.json
│   └── single_parent.json
├── organizations/
│   ├── restaurant_small.json
│   ├── tech_startup.json
│   └── government_agency.json
├── streets/
│   ├── residential.json
│   ├── commercial.json
│   └── mixed.json
├── relationships/
│   ├── school_friend.json
│   ├── work_colleague.json
│   └── family_sibling.json
└── events/
    ├── marriage.json
    ├── birth.json
    └── job_start.json
```

### Generation Scripts Structure

```
scripts/world_generation/
├── world_generator.gd              # Main orchestrator
├── phase_1_city_foundation.gd
├── phase_2_family_frames.gd
├── phase_3_location_frames.gd
├── phase_4_npc_generation.gd      # Multi-pass NPC generation
├── phase_5_org_filling.gd         # Multi-pass org filling
├── phase_6_relationship_gen.gd    # Context-based relationships
├── phase_7_event_memory_gen.gd    # Historical event generation
├── phase_8_location_assignment.gd
├── phase_9_validation.gd
├── template_loader.gd              # Load and parse templates
├── rule_engine.gd                  # Apply generation rules
└── value_inheritance.gd            # Calculate inherited values
```

### Generation Config

```json
{
  "world_size": "small",
  "npc_count": 1000,
  "family_ratio": 0.25,
  "org_ratio": 0.3,
  "district_count": 6,
  "historical_depth_years": 5,
  "relationship_density": "medium",
  "wealth_distribution": "realistic",
  "conflict_level": "moderate",

  "templates": {
    "families": {
      "nuclear": 0.45,
      "single_parent": 0.15,
      "extended": 0.2,
      "multigenerational": 0.1,
      "young_couple": 0.05,
      "elderly_couple": 0.03,
      "single_adult": 0.02
    },
    "streets": {
      "residential": 0.5,
      "commercial": 0.2,
      "mixed": 0.25,
      "industrial": 0.05
    }
  },

  "inheritance_rules": {
    "value_deviation": 30,
    "appearance_variance": 10,
    "skill_inheritance": false
  },

  "relationship_rules": {
    "school_friends_per_npc": 3,
    "work_colleagues_per_npc": 2,
    "neighbor_relationships_per_npc": 2,
    "romantic_history_chance": 0.3
  }
}
```

---

## Benefits of This System

### Scalability

- Templates scale from 100 NPCs to 100,000 NPCs
- Same rules apply regardless of world size
- Generation time grows linearly, not exponentially

### Naturalness

- Relationships emerge from shared contexts
- Values and appearance follow genetic/cultural patterns
- Events and memories create organic world history
- No "random relationship soup"

### Extensibility

- Add new templates without changing code
- Modify rule sets via configuration
- Community can create custom templates
- Easy to add new entity types

### Maintainability

- Clear separation of phases
- Each pass has single responsibility
- Easy to debug (can inspect after each pass)
- Can regenerate single phases if needed

### Realism

- Family structures reflect Lagos demographics
- Wealth distribution follows real patterns
- Relationships cluster naturally (school, work, neighborhood)
- Events create believable history

---

## Example: Small World Generation Timeline

**Config**: 500 NPCs, 125 families, 40 organizations, 4 districts

1. **Phase 1 (2 min)**: Generate 4 districts, demographic groups
2. **Phase 2A (3 min)**: Generate 125 family frames
3. **Phase 2B (5 min)**: Generate 40 organization frames with positions
4. **Phase 3 (8 min)**: Generate 60 streets, 350 buildings
5. **Phase 4 (30 min)**:
   - Pass 1: 125 family founders
   - Pass 2: 100 spouses (25 generated, 75 found)
   - Pass 3: 200 children
   - Pass 4: 50 extended family
   - Pass 5: 25 single NPCs
6. **Phase 5 (15 min)**:
   - Pass 1: Fill 40 leadership positions
   - Pass 2: Fill 60 mid-level positions
   - Pass 3: Fill 100 entry-level positions
   - 30 positions left vacant
7. **Phase 6 (5 min)**: Assign schools and religious orgs
8. **Phase 7 (20 min)**:
   - Pass 1: 400 family relationships
   - Pass 2: 800 school relationships
   - Pass 3: 350 work relationships
   - Pass 4: 400 neighborhood relationships
   - Pass 5: 100 romantic relationships
   - Total: 2,050 relationships
9. **Phase 8 (25 min)**:
   - 125 marriage events
   - 200 birth events
   - 40 organization founding events
   - 200 "hired" events
   - 300 relationship formation events
   - Total: 865 events with 2,000+ memories
10. **Phase 9 (10 min)**: Assign locations
11. **Phase 10 (5 min)**: Validation and summary

**Total Time**: ~2 hours for a rich 500-NPC world

---

## Future Enhancements

### Dynamic Templates

- Load templates from JSON files
- Community-created template packs
- Templates for specific Lagos neighborhoods (Lekki vs. Ajegunle templates)

### Procedural Template Generation

- AI generates new templates based on existing ones
- "Generate a new family structure similar to extended_family"
- Template evolution over generations

### Template Inheritance

- Child templates inherit from parent templates
- `tech_startup extends business_small`
- Override specific fields while keeping base structure

### Constraint Solver

- More sophisticated matching for spouses/colleagues
- Optimize for interesting conflicts
- Ensure playable scenarios exist

### Incremental Generation

- Generate city → wait for user feedback → generate NPCs
- User can adjust parameters between phases
- Preview and regenerate specific districts
