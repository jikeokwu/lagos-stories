# Core Scripts

This folder contains the core system scripts that form the foundation of Lagos Stories.

## Files

### `database_manager.gd`

- **Purpose**: SQLite database interface and API
- **Type**: Autoload singleton (`DB`)
- **Key Features**:
  - Database initialization
  - CRUD operations for all entities (NPCs, locations, organizations, etc.)
  - Query helpers and relationship management
  - Generic `_insert()` helper for all tables
- **Usage**: `DB.create_npc(data)`, `DB.get_all_npcs()`, etc.

### `utils.gd`

- **Purpose**: Global utility functions
- **Type**: Autoload singleton (`Utils`)
- **Key Features**:
  - UUID generation
  - JSON file loading
  - Weighted random selection
  - String manipulation
  - Data conversion helpers
- **Usage**: `Utils.generate_uuid()`, `Utils.weighted_random()`, etc.

### `game_state_manager.gd`

- **Purpose**: Game state machine and UI flow management
- **Type**: Autoload singleton (`GameState`)
- **Key Features**:
  - State management (HOME, WORLD_CONFIG, WORLD_SELECTION, CHRONICLES, INSTANCE_PLAY)
  - World metadata persistence
  - State transition methods
  - Signals for state changes
- **Usage**: `GameState.transition_to(state)`, `GameState.get_generated_worlds()`, etc.

## Autoload Configuration

All scripts in this folder are autoloaded in `project.godot`:

```ini
[autoload]
Utils="*res://scripts/core/utils.gd"
DB="*res://scripts/core/database_manager.gd"
GameState="*res://scripts/core/game_state_manager.gd"
```

## Dependencies

- `database_manager.gd` depends on `utils.gd`
- `game_state_manager.gd` depends on `utils.gd` and `database_manager.gd`

## Design Philosophy

Core scripts are:

- **Globally accessible** - Available throughout the project via singletons
- **Framework-level** - Provide fundamental services to all other systems
- **Stateless or minimal state** - Focus on providing services, not storing game state
- **Well-documented** - Comprehensive inline documentation and API references

## Related Documentation

- `database/README.md` - Database schema and design
- `database/QUICK_REFERENCE.md` - Database API quick reference
- `docs/GAME_STATE_SYSTEM.md` - Game state system documentation
