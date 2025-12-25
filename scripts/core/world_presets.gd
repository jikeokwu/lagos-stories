extends Node
## World Presets - Pre-configured world generation settings based on device specs
## Autoload singleton for accessing world generation presets

## Preset definition structure
class Preset:
	var id: String
	var name: String
	var description: String
	var spec_level: String  # "minimum" or "recommended"
	var spec_description: String
	var config: Dictionary
	
	func _init(preset_id: String, preset_name: String, preset_desc: String, 
	           spec: String, spec_desc: String, preset_config: Dictionary):
		id = preset_id
		name = preset_name
		description = preset_desc
		spec_level = spec
		spec_description = spec_desc
		config = preset_config

## Available presets
func get_presets() -> Array:
	var presets: Array = []
	
	# Small World - Minimum Spec
	presets.append(Preset.new(
		"small_minimum",
		"Small World",
		"A compact world optimized for lower-end hardware. Fast generation, manageable complexity.",
		"minimum",
		"Minimum: 16GB RAM (Apple Silicon) or 8GB GPU (NVIDIA). 7B-class LLM models.",
		{
			"target_npcs": 500,
			"family_composition_ratio": 0.3,
			"district_density_ratio": 0.9,
			"org_density_ratio": 0.8,
			"location_density_ratio": 0.8,
			"start_date": "2025-01-01",
			"start_time": "08:00"
		}
	))
	
	# Medium World - Recommended Spec
	presets.append(Preset.new(
		"medium_recommended",
		"Medium World",
		"A balanced world size with good complexity. Recommended for most players.",
		"recommended",
		"Recommended: 24GB+ RAM (Apple Silicon) or 16GB GPU (NVIDIA). 14B-class LLM models.",
		{
			"target_npcs": 1000,
			"family_composition_ratio": 0.3,
			"district_density_ratio": 1.0,
			"org_density_ratio": 1.0,
			"location_density_ratio": 1.0,
			"start_date": "2025-01-01",
			"start_time": "08:00"
		}
	))
	
	# Large World - Recommended Spec (High End)
	presets.append(Preset.new(
		"large_recommended",
		"Large World",
		"A large, complex world with many NPCs and locations. Requires powerful hardware.",
		"recommended",
		"Recommended: 32GB+ RAM (Apple Silicon) or 24GB GPU (NVIDIA). 14B-class LLM models.",
		{
			"target_npcs": 2000,
			"family_composition_ratio": 0.3,
			"district_density_ratio": 1.1,
			"org_density_ratio": 1.1,
			"location_density_ratio": 1.1,
			"start_date": "2025-01-01",
			"start_time": "08:00"
		}
	))
	
	# Epic World - Premium Spec
	presets.append(Preset.new(
		"epic_premium",
		"Epic World",
		"A massive world with thousands of NPCs. For high-end systems only. Long generation time.",
		"premium",
		"Premium: 48GB+ RAM (Apple Silicon) or 32GB+ GPU (NVIDIA). 30B+ class LLM models.",
		{
			"target_npcs": 5000,
			"family_composition_ratio": 0.3,
			"district_density_ratio": 1.2,
			"org_density_ratio": 1.2,
			"location_density_ratio": 1.2,
			"start_date": "2025-01-01",
			"start_time": "08:00"
		}
	))
	
	return presets

## Get preset by ID
func get_preset(preset_id: String) -> Preset:
	var presets = get_presets()
	for preset in presets:
		if preset.id == preset_id:
			return preset
	return null

## Get preset display name with spec indicator
func get_preset_display_name(preset: Preset) -> String:
	var spec_indicator = ""
	match preset.spec_level:
		"minimum":
			spec_indicator = " (Minimum Spec)"
		"recommended":
			spec_indicator = " (Recommended Spec)"
		"premium":
			spec_indicator = " (Premium Spec)"
	return preset.name + spec_indicator

