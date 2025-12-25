# Data Schema (Draft)

## Concepts

This is a preliminary look at how we might structure the data based on the three value types: **Sliders**, **Definite**, and **Scale**.

## Key Design Decisions

### Sexual Orientation as Slider

Sexual orientation is represented as a continuous slider from -100 to +100:

- **-100**: Purely attracted to same gender
- **0**: Bisexual (equal attraction to all genders)
- **+100**: Purely attracted to opposite gender

This allows for nuanced representation and is used in attraction calculations.

### RPG Attributes

NPCs have six core attributes (0-100) that affect gameplay, interactions, and attraction:

- **Beauty**: Physical attractiveness
- **Strength**: Physical power (declines with age)
- **Intellect**: Mental capacity
- **Charisma**: Social charm and persuasion
- **Constitution**: Health and endurance
- **Agility**: Speed and reflexes (declines with age)

### Calculated Attraction

The `attraction` value in relationships is **calculated dynamically**, not stored statically:

- **50%** Sexual orientation compatibility (based on gender match and orientation slider)
- **35%** Target's attributes (beauty 60%, charisma 40%)
- **15%** Target's reputation/status
- Plus random variance (-10 to +10)

This allows for asymmetric attraction where NPC A is attracted to NPC B, but B is not attracted to A.

### NPC Schema

```json
{
  "id": "uuid-string",
  "name": "String",

  "definite": {
    "gender": "male|female|non-binary",
    "age": 32,
    "alive": true,
    "orientation": 75
  },

  "attributes": {
    "beauty": 68,
    "strength": 72,
    "intellect": 85,
    "charisma": 74,
    "constitution": 80,
    "agility": 65
  },

  "identity": {
    "tribe": "Yoruba",
    "spoken_languages": ["English", "Yoruba", "Pidgin"],
    "education": {
      "kindergarten": { "institution": "Little Stars", "years": "2000-2005" },
      "primary": { "institution": "St. Gregory's", "years": "2005-2011" },
      "secondary": { "institution": "King's College", "years": "2011-2017" },
      "undergraduate": {
        "institution": "University of Lagos",
        "years": "2017-2021"
      }
    },
    "religious_path": {
      "path": "Christian",
      "institution": "Redeemed Christian Church of God",
      "role": "member",
      "active": true
    }
  },

  "personality": {
    "ambition": 65,
    "compassion": -20,
    "volatility": 40,
    "openness": 30,
    "gender_bias": -15,
    "ethnic_prejudice": -40,
    "class_bias": 55,
    "religious_intolerance": -60,
    "social_conformity": 45
  },

  "political_ideology": {
    "social_conservatism": -40,
    "economic_conservatism": 55,
    "authoritarianism": -15,
    "nationalism": 20,
    "religious_devotion": 45,
    "environmentalism": -30
  },

  "skills": {
    "tech": {
      "programming": 7,
      "hardware": 3,
      "networking": 5
    },
    "medical": {
      "surgery": 0,
      "diagnosis": 2,
      "pharmacology": 1
    },
    "social": {
      "persuasion": 8,
      "intimidation": 4,
      "deception": 6
    }
  },

  "resources": {
    "liquid_assets": [
      { "type": "cash", "amount": 50000, "currency": "NGN" },
      {
        "type": "bank_account",
        "bank": "First Bank",
        "amount": 2000000,
        "currency": "NGN"
      },
      {
        "type": "mobile_money",
        "provider": "OPay",
        "amount": 15000,
        "currency": "NGN"
      }
    ],
    "property": [
      {
        "type": "apartment",
        "location": "Lekki",
        "ownership": "owned",
        "value": 30000000
      },
      {
        "type": "vehicle",
        "make": "Toyota Corolla",
        "year": 2018,
        "value": 5000000
      }
    ],
    "access": [
      { "type": "vip_membership", "entity": "Quilox Club", "status": "active" },
      {
        "type": "government_access",
        "department": "Ministry of Works",
        "level": 3
      }
    ]
  },

  "status": {
    "health": 85,
    "stress": 45,
    "reputation": 60
  },

  "demographic_affinities": {
    "religious_community": 80,
    "capitalist_class": 50,
    "working_class": -20,
    "youth_movement": 60,
    "traditional_authorities": 30,
    "ethnic_solidarity": 70
  },

  "relationships": [
    {
      "target_id": "uuid-other",
      "type": "sibling",
      "affection": -80,
      "trust": -40,
      "attraction": 60, // CALCULATED: orientation (50%) + target attributes (35%) + reputation (15%)
      "respect": 20
    },
    {
      "target_id": "uuid-rival",
      "type": "work_rival",
      "affection": -20,
      "trust": 50,
      "attraction": 0, // Can be asymmetric - they may not be attracted back
      "respect": 70
    }
  ],

  "affiliations": [
    {
      "org_id": "org-uuid-123",
      "type": "employee",
      "loyalty": 45,
      "investment": 60,
      "alignment": 30
    }
  ],

  "memory": [
    {
      "event_id": "evt-123",
      "personal_summary": "I was robbed at Balogun Market, lost everything, saw the thief's face",
      "knowledge_level": "direct_witness",
      "emotional_impact": 90,
      "belief_accuracy": 100,
      "timestamp": 1704067200,
      "date": "2024-01-01"
    },
    {
      "event_id": "evt-456",
      "personal_summary": "Heard my friend was robbed, very upset for them",
      "knowledge_level": "secondhand",
      "emotional_impact": 40,
      "belief_accuracy": 70,
      "timestamp": 1704153600,
      "date": "2024-01-02"
    }
  ]
}
```

### Organization Schema

```json
{
  "id": "org-uuid",
  "name": "TechCorp Nigeria Ltd",
  "type": "business",
  "founded": 2018,
  "location": "Victoria Island",
  "legal_status": "registered",

  "pillars": [
    "Maximize profit",
    "Maintain market reputation",
    "Provide quality tech services"
  ],

  "reputation": {
    "trustworthiness": 60,
    "innovation": 75,
    "morality": 40,
    "conservatism": -20,
    "influence": 55
  },

  "resources": {
    "liquid_assets": [
      {
        "type": "business_account",
        "bank": "GTBank",
        "amount": 50000000,
        "currency": "NGN"
      }
    ],
    "property": [
      {
        "type": "office",
        "location": "Victoria Island",
        "ownership": "leased",
        "monthly_cost": 2000000
      }
    ]
  },

  "members": [
    { "npc_id": "uuid-1", "role": "CEO", "weight": 10, "tenure_years": 6 },
    {
      "npc_id": "uuid-2",
      "role": "Senior Engineer",
      "weight": 2,
      "tenure_years": 3
    },
    { "npc_id": "uuid-3", "role": "Engineer", "weight": 1, "tenure_years": 1 }
  ],

  "_computed": {
    "effective_values": {
      "note": "Calculated at runtime as weighted aggregate of member values",
      "ambition": 72,
      "compassion": -15,
      "economic_conservatism": 65
    }
  }
}
```

### World State Schema

```json
{
  "seed": "random-seed-12345",
  "tick": 100,
  "date": "2025-05-01",
  "time": "14:30",

  "districts": [
    {
      "id": "district-lekki",
      "name": "Lekki",
      "prosperity": 75,
      "safety": 60,
      "infrastructure": 70
    }
  ],

  "global_signals": {
    "economy": 55,
    "stability": 70,
    "corruption": 45,
    "public_order": 65
  },

  "history_log": [
    {
      "id": "evt-123",
      "tick": 95,
      "type": "crime",
      "description": "Armed robbery at Balogun Market",
      "participants": ["uuid-1", "uuid-2"],
      "affected_entities": ["uuid-3", "uuid-4", "org-123"],
      "ripple_depth": 2
    }
  ]
}
```

## Design Notes

### Extensibility

- **Adding new personality scales**: Simply add a new key to the `personality` object
- **Adding new skill categories**: Add a new category object under `skills`
- **Adding new resource types**: Add a new array under `resources`
- **Adding new relationship dimensions**: Add a new slider field to relationship objects

### Skill Category Calculation

The "category score" (e.g., overall "tech skills") is **derived** at runtime:

```
category_score = average(specific_skills_in_category) + bonus_from_high_skills
```

Example: If someone has Programming: 7, Hardware: 3, Networking: 5

- Average = (7 + 3 + 5) / 3 = 5
- Bonus for having a 7 = +1
- Tech Skills = 6

### Resource Aggregation

When the game needs to know "how much money does this NPC have?", it sums all `liquid_assets`:

```
total_liquid = sum(cash + bank_accounts + mobile_money + ...)
```

### Memory Structure

NPC memories are **references to events** with personal nuance, not complete event data:

- **event_id**: Links to the global event log
- **personal_summary**: What this NPC remembers (their perspective)
- **knowledge_level**: direct_witness | participant | secondhand | rumor
- **emotional_impact**: How much they care (0-100)
- **belief_accuracy**: How accurate their memory is (0-100, can be wrong)

NPCs may not have access to all information in an event. Their memory is filtered by what they witnessed, were told, and their emotional state at the time.

### Relationship Complexity

The system allows complex emotional states:

- **Sibling rivalry**: `type: "sibling", affection: -60, respect: 70, trust: 20`
- **Forbidden attraction**: `type: "colleague", affection: -10, attraction: 80, trust: 50`
- **Begrudging alliance**: `type: "ally", affection: -30, trust: 40, respect: 60`

### Relationship Directionality

Relationships are **directional** and **not symmetric**. If NPC A trusts NPC B at +70, NPC B's trust of NPC A is stored separately and can be completely different (e.g., -20). This allows for unrequited feelings, one-sided rivalries, and asymmetric power dynamics.

## Storage Format Decision

### SQL vs NoSQL Tradeoffs

**SQLite (Relational)**:

- ✅ Built-in to most systems, no server needed
- ✅ Strong ACID guarantees, referential integrity
- ✅ Excellent for complex queries (joins, aggregations)
- ✅ Good for relationship-heavy data (NPCs ↔ Organizations ↔ Events)
- ❌ Rigid schema (but we don't need migrations—always generating new worlds)
- ❌ Joins can be slow for deeply nested queries

**MongoDB (NoSQL Document)**:

- ✅ Flexible schema, store nested objects directly (JSON-like)
- ✅ Fast for document retrieval (get entire NPC with all data)
- ✅ Easy to evolve structure (no migrations needed)
- ✅ Natural fit for our entity-based model
- ❌ Weaker query capabilities across collections
- ❌ No built-in referential integrity
- ❌ Requires MongoDB server installation

**Recommendation**: Start with **SQLite** for simplicity and strong relationship queries (Chronicles mode will need complex joins). If performance becomes an issue, we can export/import worlds as JSON anyway.

**Schema Migrations**: Not needed—we'll constantly generate new worlds. Old worlds are snapshots.

### Derived Values

**Caching Strategy**: Cache derived values (category scores, organization effective values) and **update at resolution phase**. Requires testing to confirm performance benefit.

## Complete Schema Examples

### Location Schema

```json
{
  "id": "loc-uuid",
  "name": "Balogun Market, Stall 47",
  "type": "commercial",
  "address": {
    "district": "Lagos Island",
    "street": "Balogun Street",
    "building": "Market Complex"
  },

  "hierarchy": {
    "district_id": "district-lagos-island",
    "building_id": "building-uuid",
    "parent_location_id": "loc-market-complex"
  },

  "physical_properties": {
    "size": "small",
    "capacity": 10,
    "condition": 65,
    "security_level": 30
  },

  "access": {
    "control_type": "public",
    "operating_hours": "8:00-20:00",
    "owner_id": "npc-uuid"
  },

  "reputation": {
    "safety": 40,
    "prestige": -10,
    "activity_level": 85
  },

  "features": {
    "utilities": {
      "power": true,
      "water": false,
      "internet": false
    },
    "amenities": ["awning", "storage_space"]
  },

  "event_history": ["evt-123", "evt-456", "evt-789"],

  "current_occupants": ["npc-owner", "npc-customer-1"]
}
```

### Item Schema

```json
{
  "id": "item-uuid",
  "name": "Forged Business License",
  "type": "document",

  "owner_id": "npc-uuid",
  "location": {
    "type": "npc_inventory",
    "entity_id": "npc-uuid"
  },

  "physical": {
    "condition": 85,
    "size": "pocket",
    "transferable": true
  },

  "value": {
    "monetary": 500000,
    "sentimental": 20,
    "legal_status": "illegal"
  },

  "metadata": {
    "created_date": "2024-03-15",
    "created_by": "npc-forger-uuid",
    "created_in_event": "evt-234"
  },

  "history": [
    {
      "event_id": "evt-234",
      "action": "forged",
      "timestamp": 1710489600,
      "parties": ["npc-forger-uuid"]
    },
    {
      "event_id": "evt-456",
      "action": "purchased",
      "timestamp": 1710576000,
      "parties": ["npc-forger-uuid", "npc-uuid"]
    }
  ]
}
```

### Event Schema

```json
{
  "id": "evt-123",
  "type": "crime",
  "subtype": "theft",

  "timestamp": 1704067200,
  "date": "2024-01-01",
  "time": "14:30",
  "duration_minutes": 5,

  "location_id": "loc-uuid",
  "district_id": "district-lagos-island",

  "participants": {
    "primary_actors": ["npc-thief-uuid"],
    "affected_entities": ["npc-victim-uuid"],
    "witnesses": ["npc-witness-1", "npc-witness-2"],
    "organizations": []
  },

  "summary": "Armed robbery at Balogun Market stall",

  "details": {
    "perpetrator_id": "npc-thief-uuid",
    "victim_id": "npc-victim-uuid",
    "stolen_items": ["item-cash-uuid"],
    "stolen_value": 50000,
    "violence_used": false,
    "police_involved": false
  },

  "impact": {
    "severity": 65,
    "public_knowledge": 45,
    "emotional_weight": 80
  },

  "consequences": {
    "relationship_changes": [
      {
        "npc_a": "npc-victim-uuid",
        "npc_b": "npc-thief-uuid",
        "affection_delta": -90,
        "trust_delta": -100
      }
    ],
    "reputation_changes": [
      {
        "entity_id": "loc-uuid",
        "reputation_type": "safety",
        "delta": -5
      }
    ],
    "city_situation_changes": [
      {
        "district_id": "district-lagos-island",
        "metric": "safety",
        "delta": -2
      }
    ]
  },

  "ripple_depth": 2,
  "affected_nodes": ["npc-friend-uuid", "org-market-association"],

  "resolved": true
}
```
