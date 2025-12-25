# Technology Stack

## Core Engine

- **Godot 4**: Selected for its open-source nature, flexibility with 2D/UI, and ease of integration with external libraries (Python/C++)
- **Scripting**: GDScript or C# for simulation logic
- **Primary Interface**: Text-based chat box for natural language interaction

## AI Integration

### Local Inference (Primary)

- **Runtime**: `llama.cpp` or similar libraries for efficient local model inference
- **Models**: Open-source models (Mistral, Llama 2/3 derivatives)
- **Quantization**: 4-bit quantization (Q4) to fit models in consumer RAM
- **Server**: Local Python server/API to handle LLM requests from game engine

### API Integration (Optional)

- **Configuration**: Users can optionally configure API endpoints (OpenAI, Anthropic, etc.) for any task category
- **Use Cases**: Larger cloud models for world gen, fallback for slow local inference, hybrid setups
- **Design Philosophy**: Local-first, but with API flexibility for user choice

### Multi-Model System

- Users assign different models (local or API) to different task categories:
  - World Generation
  - Instance Framing
  - Dialogue Generation
  - Narrative Description
  - Intent Interpretation
  - NPC Decision Making
  - Outcome Adjudication
  - Resolution & Consequences

## Data Persistence

### Database

- **Choice**: **SQLite** (relational database)
- **Rationale**:
  - Built-in to most systems, no server needed
  - Strong ACID guarantees and referential integrity
  - Excellent for complex queries (Chronicles mode needs joins across NPCs ↔ Organizations ↔ Events)
  - Good for relationship-heavy data

### Alternative Considered

- **MongoDB** (NoSQL): Flexible schema, fast document retrieval, but weaker cross-collection queries and requires server installation

### Schema Migrations

- **Not needed**: We'll constantly generate new worlds
- Old worlds are snapshots—no need to migrate them to new formats
- Each world is self-contained

### World Export/Import

- Worlds can be exported to JSON for sharing
- Players can import pre-generated worlds
- Supports community world-sharing

## Development Tools

### Development Feedback Mode

- AI provides suggestions for new tools/actions during play
- Identifies gaps in the action system
- Helps iteratively build action vocabulary
- Accelerates development through play-driven design

### Performance Testing

- Cache derived values (updated at resolution phase)
- Test query optimization for large worlds (10,000+ NPCs, 100,000+ events)
- Profile LLM call frequency vs. performance

## Extensibility Strategy

### Data-Driven Design

- Event types defined in data files (JSON/YAML)
- NPC traits, skills, and resources extensible via configuration
- Location types and item categories modular
- AI prompts templated for easy modification

### Modding Support (Future)

- Clear separation between engine and content
- Documented schema for entities (NPCs, locations, items, events)
- JSON export format serves as modding format
- Custom event templates
- Additional action verbs via configuration

## Modularity

### Separation of Concerns

- **Simulation Layer**: Pure logic, no rendering dependencies
  - World state management
  - Entity updates
  - Event resolution
  - Catch-up system
- **AI Layer**: Independent service
  - Local LLM server
  - Validation pipeline
  - Multi-model routing
- **Presentation Layer**: Godot UI
  - Chat interface
  - Chronicles browser
  - Optional visualizations

**Goal**: Simulation engine can run headless (useful for testing, server-side world generation, and potential CLI mode).
