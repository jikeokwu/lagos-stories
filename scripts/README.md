# Scripts Folder Organization

This folder contains all GDScript code for Lagos Stories, organized into logical subfolders.

## Folder Structure

```
scripts/
├── core/               # Core system scripts (autoloaded singletons)
│   ├── database_manager.gd
│   ├── game_state_manager.gd
│   └── utils.gd
├── generation/         # World generation and procedural content
│   └── world_generator.gd
└── ui/                 # User interface scripts
    ├── chronicles.gd
    ├── home_screen.gd
    ├── world_config.gd
    └── world_selection.gd
```

## Folder Descriptions

### `core/`

**Purpose**: Core system scripts that provide fundamental services

**Contents**:

- Autoloaded singletons (DB, Utils, GameState)
- Database management
- Global utilities
- State machine

**Characteristics**:

- Globally accessible throughout the project
- Framework-level functionality
- Minimal game state storage
- High reusability

**See**: `core/README.md` for details

### `generation/`

**Purpose**: World generation and procedural content creation

**Contents**:

- World generator
- Template-based generation systems
- Multi-pass generation pipeline

**Characteristics**:

- Template-driven (data/templates/)
- Performance-optimized (O(n) complexity)
- Configurable via parameters
- Scene-based or programmatic usage

**See**: `generation/README.md` for details

### `ui/`

**Purpose**: User interface scripts for all game screens

**Contents**:

- Home screen
- World configuration
- World selection
- Chronicles mode
- Future: Instance play, character selection

**Characteristics**:

- State-driven navigation (via GameState)
- Dark theme with gold accents
- Text-first, information-dense
- Dwarf Fortress-inspired design

**See**: `ui/README.md` for details

## Design Principles

### Separation of Concerns

Each folder has a clear, distinct purpose:

- **core/** - System services
- **generation/** - Content creation
- **ui/** - User interaction

### Dependencies

- `ui/` depends on `core/`
- `generation/` depends on `core/`
- `core/` scripts may depend on each other

### Naming Conventions

- Snake_case for file names: `database_manager.gd`
- PascalCase for class names (if using class_name)
- Descriptive names indicating purpose

### File Organization

- Keep files focused on single responsibility
- Group related functionality in same folder
- Create subfolders as complexity grows

## Autoload Configuration

Core scripts are autoloaded in `project.godot`:

```ini
[autoload]
Utils="*res://scripts/core/utils.gd"
DB="*res://scripts/core/database_manager.gd"
GameState="*res://scripts/core/game_state_manager.gd"
```

This makes them globally accessible:

```gdscript
# Anywhere in the project:
var uuid = Utils.generate_uuid()
var npc = DB.get_npc(npc_id)
GameState.transition_to(GameState.GameState.CHRONICLES)
```

## Future Organization

As the project grows, additional subfolders may be added:

### Planned Additions

- `ai/` - AI integration (LLM interface, intent parsing, validation)
- `simulation/` - Entity simulation (NPC agency, time advancement)
- `instance/` - Instance gameplay systems
- `narrative/` - Narrative generation and event framing
- `systems/` - Game systems (economy, politics, reputation)
- `tools/` - Development tools and editors

### When to Create a New Subfolder

Create a new subfolder when:

1. You have 3+ related files
2. The functionality is distinct from existing folders
3. The files have shared dependencies
4. The system is large enough to need its own organization

## Integration with Scene Files

Scene files (`scenes/*.tscn`) reference scripts using:

```
[ext_resource type="Script" path="res://scripts/ui/home_screen.gd" id="1"]
```

When moving files, update all scene references.

## Migration History

**December 24, 2025**: Reorganized flat structure into subfolders

- Moved core systems to `core/`
- Moved world generator to `generation/`
- UI scripts already in `ui/`
- Updated all references in project.godot, scenes, and documentation

## Testing

After reorganization:

1. Launch game (F5) - should work without errors
2. Check console for missing script errors
3. Verify autoloads are accessible
4. Test all UI screens

## Related Documentation

- `docs/GAME_STATE_SYSTEM.md` - State management and UI flow
- `planning/05_tech/stack_decisions.md` - Technology choices
- `PROGRESS.md` - Project status and roadmap
- Individual README files in each subfolder

## Contributing

When adding new scripts:

1. Choose appropriate subfolder based on purpose
2. Follow naming conventions
3. Add inline documentation
4. Update folder README if adding new functionality
5. Update this main README for major additions
