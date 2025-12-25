# Local LLM Strategy

## Goal

To run the game primarily on local hardware to ensure privacy, autonomy, and zero ongoing API costs.

## Hardware Tiers

1.  **Minimum Playable**: 7B-class models, 4-bit quantization (Q4). Capable of dialogue and basic event narration. (Target: Apple Silicon 16GB, NVIDIA 8GB).
2.  **Recommended**: 14B-class models. Better nuance, stronger framing, and antagonist planning. (Target: Apple Silicon 24GB+).
3.  **Premium**: 30B+ models. Deep planning, high narrative consistency. (Target: High-end builds).

## Design Implication

Since we cannot rely on a massive cloud model to "fix" coherence, the game's simulation layer (deterministic code) must carry more load. The LLM should be used for _flavor_ and _interpretation_, but the _rules_ should be rigid and handled by code where possible.

## Strategy

- **Models**: Focus on efficient open-source models (Mistral, Llama 2/3 derivatives).
- **Optimization**: Use quantization (llama.cpp) to fit models in consumer RAM.
- **Local-First Design**: The game is designed to work fully offline with local models. However, players can optionally configure API access (OpenAI, Anthropic, etc.) for any task category if they prefer.
- **API Configuration (Optional)**: Players can set API endpoints and keys for specific task categories, allowing:
  - Use of larger cloud models for expensive tasks (world gen)
  - Fallback to API if local inference is too slow
  - Hybrid setups (local for dialogue, API for complex reasoning)
- **Prompting**: Use structured templates (JSON/Schema) to ensure AI outputs are machine-readable by the game engine.
- **Multi-Model Configuration**: Users can assign different models (local or API) to different task categories (see `ai_architecture.md`). This allows optimal resource allocation—e.g., 30B for world gen (once), 7B for dialogue (constant).

## Example Multi-Model Setup

**Budget Build (16GB RAM)**:

- World Gen: 14B Q4 (slow, but only once)
- Instance Framing: 7B Q4
- Dialogue: 7B Q4
- All other tasks: 7B Q4

**Enthusiast Build (32GB+ RAM)**:

- World Gen: 30B Q4
- Instance Framing: 14B Q4
- Dialogue: 7B Q4 (speed priority)
- Resolution: 14B Q4
- Other tasks: 7B Q4

**High-End Build (64GB+ RAM)**:

- World Gen: 70B Q4
- Instance Framing: 30B Q4
- Dialogue: 14B Q4
- All complex tasks: 30B Q4

## Workarounds for Low-Spec

- **Pre-generated Worlds**: Downloadable content to skip expensive initial generation.
- **Instance Templates**: Shareable episode frames to reduce runtime generation load.
