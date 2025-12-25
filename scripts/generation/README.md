# Generation Scripts

This folder contains scripts related to world generation and procedural content creation.

## Files

### `world_generator.gd`
- **Purpose**: Complete world generation system
- **Type**: Scene script (attached to world generator nodes)
- **Key Features**:
  - Template-based multi-pass generation
  - NPC creation with families, relationships, attributes
  - District and location generation
  - Organization creation with positions
  - Historical event generation
  - Relationship network building
- **Usage**: Attach to a Node and run, or instantiate programmatically
- **Scenes**: `scenes/world_gen.tscn`, `scenes/world_generator.tscn`

## Generation Process

The world generator uses a **multi-pass system**:

1. **Pass 0: World State & Districts**
   - Create world metadata
   - Generate districts with archetypes

2. **Pass 1: Family Frames**
   - Create family structures
   - Define roles (parents, children)

3. **Pass 2: NPCs**
   - Generate NPCs from family frames
   - Assign attributes, skills, personality
   - Create family relationships (parent-child, spouse)

4. **Pass 3: Locations**
   - Generate locations per district
   - Assign ownership and features

5. **Pass 4: Organizations**
   - Create organizations (businesses, churches, etc.)
   - Generate positions and memberships

6. **Pass 5: Extended Relationships**
   - School relationships (friends, rivals)
   - Work relationships (colleagues)
   - Neighborhood relationships
   - Romantic relationships (exes, affairs)

7. **Pass 6: Events & Memories**
   - Generate historical events
   - Create personalized memories
   - Build timeline for each NPC

## Template System

All generation is template-driven, loading from `data/templates/`:

- `name_catalog.json` - Names by tribe, gender, type
- `family_templates.json` - Family structures
- `district_templates.json` - District types and features
- `location_templates.json` - Location types
- `organization_templates.json` - Organization types and positions
- `skill_trees.json` - Occupations and skill requirements
- `appearance_templates.json` - Physical appearance generation
- `relationship_templates.json` - Relationship types and rules
- `event_templates.json` - Event types and memory templates

## Configuration

World generation is configured via `GameState.current_world_config`:

```gdscript
{
    "world_name": "Lagos 2025",
    "population": 20,        # Number of NPCs
    "districts": 1,          # Number of districts
    "family_density": 70,    # % of NPCs in families
    "organizations": 2,      # Number of organizations
    "locations_per_district": 8,
    "seed": 12345           # Random seed
}
```

## Performance

Generation is **O(n)** linear with NPC count:
- 100 NPCs: ~0.3-0.5 seconds
- 1,000 NPCs: ~3-5 seconds
- 10,000 NPCs: ~30-50 seconds

Context-based relationship generation avoids O(n²) complexity.

## Integration with UI

The world generator is called from `scripts/ui/world_config.gd` after user configuration. Future enhancements will include:
- Progress UI during generation
- Async generation with yields
- Error handling and recovery
- Generation cancellation

## Related Documentation

- `planning/02_simulation/world_generation.md` - Design philosophy
- `PROGRESS.md` - Implementation status and roadmap
- `TEMPLATE_QUICK_REFERENCE.md` - Template structure reference
- `docs/GAME_STATE_SYSTEM.md` - UI integration

## Future Additions

This folder will grow to include:
- `event_generator.gd` - Specialized event generation
- `relationship_builder.gd` - Advanced relationship algorithms
- `appearance_generator.gd` - Appearance generation with inheritance
- `skill_assigner.gd` - Skill and occupation assignment
- `timeline_builder.gd` - Historical event timeline creation

