# Chronicles System

## Overview

Chronicles Mode is Lagos Stories' equivalent of Dwarf Fortress's Legends mode—a comprehensive, browsable database of the entire world's history. It allows players to explore the interconnected stories of NPCs, organizations, locations, events, and items outside of active gameplay.

## Inspiration: Dwarf Fortress Legends Mode

Dwarf Fortress's Legends mode provides:

- **Complete Historical Records**: Every event, figure, site, and artifact
- **Interconnected Browsing**: Click through relationships (person → battle → site → civilization)
- **Multiple Views**: By person, by place, by event, by timeline
- **Exportable Data**: XML export for external tools
- **Search & Filter**: Find specific information across thousands of entries

## Lagos Stories Adaptation

### Core Entities in Chronicles

1. **NPCs**: Full biography, relationships, affiliations, events participated in
2. **Organizations**: Founding, membership changes, major events, reputation shifts
3. **Locations**: Construction history, events that occurred there, ownership changes
4. **Events**: Chronological list with all participants, consequences, and ripple effects
5. **Items**: Creation, ownership history, significant moments (used in crime, transferred)

### Browsing Interface

#### By Entity Type

- **People**: List all NPCs, filter by tribe, district, organization, alive/dead
- **Organizations**: List all orgs, filter by type, district, active/dissolved
- **Locations**: Browse by district, type, ownership
- **Events**: Timeline view, filter by type, district, date range
- **Items**: List by type, owner, location

#### Interconnected Navigation

Clicking on any entity shows:

- **Related Entities**: All connections
- **Event Timeline**: Events involving this entity
- **Relationship Map**: Visual graph of connections

**Example Flow**:

1. Browse Events → Find "Theft at Balogun Market"
2. Click perpetrator → See NPC_B's full history
3. Click their gang affiliation → See gang's complete history
4. See all events involving the gang
5. Click on a location → See all crimes at that location

### Timeline View

**Global Timeline**: Chronological list of all events

- Filter by: Type, district, participants, severity
- Zoom levels: Daily, monthly, yearly views
- Highlight significant historical moments

**Personal Timeline**: Filter to specific NPC or organization

- Shows their complete story arc
- Relationship changes marked
- Major life events highlighted

### Search & Queries

Players can search for:

- "All crimes in Ikeja"
- "Events involving [NPC_NAME]"
- "What organizations was [NPC] part of?"
- "History of [LOCATION]"
- "Who owns [ITEM]?"

### Export Functionality

**Data Export**: Export world state to JSON for:

- External analysis/visualization
- Sharing worlds with other players
- Creating "canon" worlds for community stories
- Modding and custom tools

## When Chronicles is Accessible

### During Gameplay

- **Limited Access**: Players can only access:
  - Their own character's memories (what they directly experienced or were told)
  - General knowledge (public events, widely known information)
  - Cannot access: Other NPCs' private memories, hidden events they weren't present for, secret information
- Powers: Investigations, research, NPC knowledge checks
- This maintains mystery and discovery gameplay (like figuring out who the antagonist is)

### Between Sessions

- **Full Access**: Browse entire database freely
- Review what happened during play
- Plan future actions based on discovered information
- Appreciate emergent narratives
- **Manual Resolution**: Trigger catch-up for specific entities
  - Select an NPC/organization → "Resolve to current time"
  - Uses same catch-up system as instance transitions
  - Respects player's ripple depth setting (1-5 nodes)
  - Useful for advancing non-player storylines between sessions

### Post-Game

- **Complete Archive**: After character death or world retirement
- Review the full story of your world
- See consequences of your actions across the simulation
- Discover hidden connections you never knew existed

## Integration with AI

Chronicles Mode enhances AI generation:

- AI can query Chronicles to maintain consistency
- Generate contextual dialogue referencing past events
- Create instances based on historical tensions
- NPCs "remember" differently than Chronicles shows (incomplete/biased info)

## User Experience

### Presentation

- **Text-based primary interface**: Scrollable lists, detailed text entries
- **Optional visualizations**: Relationship graphs, timelines, maps
- **Cross-references**: Everything links to everything (like a wiki)

### Performance Considerations

- Chronicles queries the persistent database
- No live simulation running during Chronicles browsing
- Search/filter operations optimized for quick response

## Examples of Chronicles Use

### Investigation Instance

Player needs to know who committed a crime. Chronicles Mode (in-game limited version) allows:

- Query events at crime scene location
- Check relationships between suspects
- Review alibis based on recorded events

### Post-Session Review

After 50 hours of play, player opens full Chronicles:

- Discovers the gang they defeated had a hidden leader
- Sees how their business rival was connected to a politician
- Finds events they never knew about (happened off-screen)
- Realizes their early actions had long-term consequences

### Community Storytelling

Player exports world to JSON:

- Shares "The Tale of Lagos 2025" with community
- Others can browse the world's history
- Becomes reference for fanfiction or derivative works

## Implementation Notes

### Visual Complexity

Visual elements (graphs, maps, timelines) will evolve based on need during development. Start with pure text browsing and add visualizations where they meaningfully enhance understanding.

### Performance Optimization

For large worlds (10,000+ NPCs, 100,000+ events), indexing and query optimization strategies will be determined during implementation based on actual performance testing.
