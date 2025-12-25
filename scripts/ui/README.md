# UI Scripts

This folder contains all user interface scripts for Lagos Stories.

## Files

### `home_screen.gd`

- **Purpose**: Main menu / home screen
- **Scene**: `scenes/home_screen.tscn`
- **Features**:
  - New World button → World Config
  - Load World button → World Selection
  - Exit button
  - Shows available world count
- **State**: HOME

### `world_config.gd`

- **Purpose**: World generation configuration screen
- **Scene**: `scenes/world_config.tscn`
- **Features**:
  - World name input
  - Population slider (10-200)
  - Districts slider (1-10)
  - Family density slider (0-100%)
  - Organizations slider (1-20)
  - Locations per district slider (5-30)
  - Random seed control
  - Generate World button
  - Cancel button
- **State**: WORLD_CONFIG

### `world_selection.gd`

- **Purpose**: World selection and management screen
- **Scene**: `scenes/world_selection.tscn`
- **Features**:
  - Scrollable list of saved worlds
  - World info display (name, pop, districts, date)
  - Click to select world
  - Enter World button
  - Delete button
  - Back button
- **State**: WORLD_SELECTION

### `chronicles.gd`

- **Purpose**: World exploration / Chronicles mode (Dwarf Fortress Legends-style)
- **Scene**: `scenes/chronicles.tscn`
- **Features**:
  - Tab-based navigation:
    - NPCs tab - Browse all characters
    - Locations tab - Browse all places
    - Organizations tab - Browse all groups
    - Events tab - Browse historical events
    - Statistics tab - World overview
  - Detail panel showing entity information
  - Database integration
  - Relationship browsing
  - Exit button
  - Refresh button
- **State**: CHRONICLES

## UI Architecture

### State-Driven Navigation

All UI screens are managed by `GameState` singleton:

```gdscript
# Transition to a new screen
GameState.transition_to(GameState.GameState.WORLD_CONFIG)

# React to state changes
func _ready():
    GameState.state_changed.connect(_on_state_changed)
```

### Scene Loading

Scenes are automatically loaded when state transitions occur:

```gdscript
# In game_state_manager.gd
const SCENES = {
    GameState.HOME: "res://scenes/home_screen.tscn",
    GameState.WORLD_CONFIG: "res://scenes/world_config.tscn",
    GameState.WORLD_SELECTION: "res://scenes/world_selection.tscn",
    GameState.CHRONICLES: "res://scenes/chronicles.tscn"
}
```

### Data Flow

```
User Input → UI Script → GameState Methods → State Change → Scene Transition
                ↓
         Database Operations (via DB singleton)
```

## UI Design Philosophy

- **Text-First**: Information density over graphics
- **Dark Theme**: Dark background (#1A1A1E) with gold accents (#E6D999)
- **Minimal Graphics**: Focus on data and information
- **No Hand-Holding**: Power user tools, no excessive tutorials
- **Dwarf Fortress Inspired**: Chronicles mode follows DF Legends design

## Common Patterns

### Button Connections

```gdscript
func _ready():
    button_name.pressed.connect(_on_button_pressed)

func _on_button_pressed():
    GameState.some_action()
```

### List Population

```gdscript
func _load_data():
    _clear_list(container)
    var items = DB.get_all_items()
    for item in items:
        var widget = _create_item_widget(item)
        container.add_child(widget)
```

### Detail Panel Display

```gdscript
func _display_details(entity: Dictionary):
    detail_panel.visible = true
    _clear_detail()
    _add_detail_header(entity.get("name", "Unknown"))
    _add_detail_section("Info", entity)
```

## Responsive Design

- Minimum window size: 1024x768
- Scales with window resize
- Scrollable containers for long lists
- Split panels for list + detail views

## Future UI Screens

Planned additions to this folder:

- `instance_setup.gd` - Character and scenario selection
- `instance_play.gd` - Active gameplay instance UI
- `chat_interface.gd` - Natural language interaction
- `relationship_graph.gd` - Visual relationship network
- `timeline_view.gd` - Historical event timeline
- `search_filter.gd` - Advanced search and filtering

## Integration Points

### Database Access

All UI screens can directly access the database:

```gdscript
var npcs = DB.get_all_npcs()
var npc = DB.get_npc(npc_id)
```

### World Management

World metadata is managed via GameState:

```gdscript
var worlds = GameState.get_generated_worlds()
GameState.add_generated_world(world_data)
```

### Signals

UI screens can react to game state signals:

```gdscript
GameState.world_selected.connect(_on_world_selected)
GameState.state_changed.connect(_on_state_changed)
```

## Testing

See `TESTING_GAME_STATE.md` for comprehensive UI testing guide.

## Related Documentation

- `docs/GAME_STATE_SYSTEM.md` - Complete system documentation
- `GAME_STATE_SUMMARY.md` - Quick visual reference
- `planning/04_gameplay/ui_ux.md` - UI/UX design philosophy
- `planning/04_gameplay/chronicles_system.md` - Chronicles mode design
