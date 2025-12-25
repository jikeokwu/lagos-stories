# Lagos Stories

**An AI-First Simulation Game Set in Modern Lagos**

![Status](https://img.shields.io/badge/status-in_development-yellow)
![Engine](https://img.shields.io/badge/engine-Godot_4.5-blue)
![Database](https://img.shields.io/badge/database-SQLite-green)
![AI](https://img.shields.io/badge/AI-local_LLM-orange)

## 🎮 What is Lagos Stories?

Lagos Stories is a text-based AI-first simulation game that pushes the boundaries of emergent narrative and gameplay. Drawing inspiration from Dwarf Fortress and The Sims, it creates a living, breathing Lagos city where:

- **AI acts as game master**, interpreting player intent and generating events dynamically
- **Real-world Lagos setting** - No fantasy, just urban life, politics, economy, and relationships
- **Total player agency** - Do anything plausible, the world reacts systemically
- **Privacy-first** - Strictly local-only LLM inference, no cloud dependencies
- **Deep simulation** - Complex systems prioritized over accessibility

## 🚀 Current Status

### ✅ Completed: Database Layer (Milestone 0)

The complete database infrastructure is implemented:

- **12 SQL tables** with full relationships and indexing
- **Database Manager** singleton with comprehensive API
- **Test suite** with 11 passing tests
- **Full documentation** and quick reference guides

**Location**: `database/`, `scripts/core/database_manager.gd`

### ✅ Completed: World Generation (Milestone 1)

Template-based, multi-pass world generation system:

- **20 NPCs** with inherited values and relationships
- **4 family structures** (nuclear families, young couple)
- **8 locations** in Yaba district
- **2 organizations** with employees
- **70+ relationships** (family, friends, colleagues)
- **12+ historical events** with memories

**Location**: `scripts/world_generation/`, `data/templates/`

### ⏳ Next: Text-First UI & Character Picker (Milestone 2-3)

Build player interface:

- Chat box UI for natural language input
- Character selection screen
- Display NPC stats and relationships
- Basic command processing

## 📁 Project Structure

```
lagos stories/
├── database/                    # Database schema and documentation
│   ├── schema.sql              # Complete SQLite schema
│   ├── README.md               # Full database documentation
│   └── QUICK_REFERENCE.md      # API quick reference
├── scripts/
│   └── database_manager.gd     # Database API (autoloaded as 'DB')
├── tests/
│   ├── test_database.gd        # Test suite
│   └── test_database.tscn      # Test scene
├── planning/                    # Design documents
│   ├── 01_concept/             # Vision and core loop
│   ├── 02_simulation/          # NPC, world, event models
│   ├── 03_ai/                  # AI architecture and strategy
│   ├── 04_gameplay/            # Mechanics and UI/UX
│   ├── 05_tech/                # Stack and schema decisions
│   └── 06_roadmap/             # Prototype plan
├── docs/                        # Project briefs
├── addons/godot-sqlite/        # SQLite addon
├── DATABASE_IMPLEMENTATION.md  # Implementation status
├── GETTING_STARTED.md          # Development guide
└── README.md                   # This file
```

## 🛠️ Tech Stack

- **Engine**: Godot 4.5 (open-source, flexible 2D/UI)
- **Database**: SQLite (relational, ACID-compliant)
- **AI**: Local LLM inference (llama.cpp, Mistral/Llama models)
- **Scripting**: GDScript
- **Interface**: Text-based chat box

## 🎯 Core Features

### Simulation Layer

- **NPCs**: Full personality sliders, skills, resources, Lagos-specific identity
- **Relationships**: Directional 4D space (affection, trust, attraction, respect)
- **Organizations**: Businesses, government, gangs with computed member values
- **Events**: Global event log with ripple effects
- **Memories**: NPCs remember events from their perspective (can be wrong!)
- **Locations**: Hierarchical places with features and reputation

### AI Layer

- **Intent Interpretation**: Natural language → game actions
- **Instance Framing**: AI generates scenarios from player intent
- **Validation Pipeline**: 3-layer system prevents hallucinations
- **Agency System**: NPCs have different AI complexity levels (2-5)
- **Narrative Generation**: AI describes outcomes dynamically

### Gameplay

- **Two-Layer Loop**:
  1. **Instance Mode**: Focused 15-30 minute scenarios
  2. **Chronicles Mode**: Browse world history and state
- **No Fixed Win Conditions**: Choose your own goals
- **Persistence**: All changes saved to database
- **Catch-Up System**: Fast-forward uninvolved entities

## 📚 Documentation

### For Developers

- **[GETTING_STARTED.md](GETTING_STARTED.md)** - Development roadmap and next steps
- **[DATABASE_IMPLEMENTATION.md](DATABASE_IMPLEMENTATION.md)** - Database status and features
- **[database/README.md](database/README.md)** - Complete database documentation
- **[database/QUICK_REFERENCE.md](database/QUICK_REFERENCE.md)** - API quick reference

### Design Documents

- **[Vision](planning/01_concept/vision.md)** - Core philosophy and goals
- **[Core Loop](planning/01_concept/core_loop.md)** - Two-layer gameplay loop
- **[Prototype Plan](planning/06_roadmap/prototype_plan.md)** - 11 milestone roadmap
- **[Stack Decisions](planning/05_tech/stack_decisions.md)** - Technology choices

## 🚦 Quick Start

### 1. Open Project

```bash
# Open Godot 4.5
# File > Open Project
# Navigate to project folder
```

### 2. Run Database Tests

```
1. Open scene: res://tests/test_database.tscn
2. Press F5 (Run Scene)
3. Check console - all 11 tests should pass ✅
```

### 3. Start Developing

```gdscript
extends Node

func _ready():
    # Database is auto-loaded as global 'DB'
    DB.initialize()

    # Create an NPC
    var npc = {
        "id": DB.generate_uuid(),
        "name": "Adebayo Okonkwo",
        "definite": {"gender": "male", "age": 32, "alive": true},
        "identity": {"tribe": "Yoruba", "spoken_languages": ["English", "Yoruba"]},
        "personality": {"ambition": 65, "compassion": -20},
        "political_ideology": {},
        "skills": {"tech": {"programming": 7}},
        "resources": {"liquid_assets": []},
        "status": {"health": 85, "stress": 45, "reputation": 60},
        "demographic_affinities": {}
    }

    DB.create_npc(npc)
    print("Created: ", DB.get_npc(npc["id"])["name"])
```

## 🗺️ Development Roadmap

### Phase 1: Foundation (Weeks 1-2) ✅ 50% Complete

- [x] Database schema implementation
- [x] Database manager with full API
- [x] Test suite
- [ ] Data generation (20 NPCs, locations, orgs)
- [ ] Text-first UI
- [ ] Character picker

### Phase 2: AI Integration (Weeks 3-4)

- [ ] Python LLM server setup
- [ ] AI validation pipeline
- [ ] Instance framing
- [ ] Intent interpretation

### Phase 3: Core Loop (Weeks 5-6)

- [ ] Gameplay loop implementation
- [ ] NPC simulation (agency-based)
- [ ] Event creation and memory updates
- [ ] Resolution and persistence

### Phase 4: Polish (Weeks 7-8)

- [ ] Catch-up system
- [ ] Multi-instance continuity
- [ ] Chronicles mode
- [ ] Multi-model configuration

## 🎨 Design Philosophy

### AI-First

The game is built with AI at the core. AI interprets intent, generates scenarios, simulates NPCs, and creates narrative.

### Coherence Under Freedom

Players can do anything plausible, but actions are bounded by:

- **Ontology**: What exists in the world (validated against database)
- **Capabilities**: What the player/NPCs can do (skills, resources)
- **Costs**: Actions have consequences (relationships, reputation, resources)

### Emergent Narrative

Stories unfold through simulation, not pre-written scripts. The world is indifferent to the player.

### Privacy & Autonomy

Strictly local-only LLM inference. No cloud dependencies, no telemetry, no compromises.

## 🔧 Database API Examples

```gdscript
# NPCs
DB.create_npc(npc_data)
var npc = DB.get_npc("npc-id")
var all_npcs = DB.get_all_npcs(true)  # alive only

# Relationships (directional)
DB.create_relationship(source_id, target_id, "colleague", 40, 60, 20, 70)
var rels = DB.get_npc_relationships("npc-id")

# Events
DB.create_event(event_data)
var recent = DB.get_recent_events(50)

# Memories
DB.create_memory(memory_data)
var memories = DB.get_npc_memories("npc-id", 100)

# Organizations
DB.create_organization(org_data)
DB.create_membership(npc_id, org_id, role, weight, tenure, loyalty, investment, alignment)

# Statistics
DB.print_statistics()
```

## 📊 Database Schema Highlights

### NPCs

- **Definite**: gender, age, alive
- **Identity**: tribe, languages, education, religion
- **Personality**: 9 sliders (-100 to +100)
- **Skills**: Hierarchical (0-10 scale)
- **Resources**: liquid assets, property, access
- **Status**: health, stress, reputation

### Relationships (Directional)

- **Affection**: -100 (hate) ↔ +100 (love)
- **Trust**: -100 (distrust) ↔ +100 (trust)
- **Attraction**: -100 (repulsion) ↔ +100 (attraction)
- **Respect**: -100 (contempt) ↔ +100 (respect)

### Events

- Global event log with participants
- Impact metrics (severity, public knowledge, emotional weight)
- Consequences (relationship changes, reputation changes)
- Ripple effects (2-3 nodes deep)

### Memories

- NPCs remember events from their perspective
- Knowledge levels: direct_witness, participant, secondhand, rumor
- Belief accuracy: 0-100 (can be wrong!)
- Emotional impact: 0-100

## 🤝 Contributing

This is a personal passion project, but feedback and suggestions are welcome!

## 📝 License

To be determined.

## 🙏 Acknowledgments

Inspired by:

- **Dwarf Fortress** - Deep systemic simulation
- **The Sims** - Life simulation and emergent stories
- **AI Dungeon** - AI-driven narrative

Built with:

- **Godot Engine** - Open-source game engine
- **godot-sqlite** - SQLite integration
- **llama.cpp** - Local LLM inference

---

**Status**: In active development  
**Version**: 0.1.0-alpha  
**Last Updated**: 2025-01-01

**Next Milestone**: Data Generation - Create 20 NPCs and populate Lagos world 🇳🇬
