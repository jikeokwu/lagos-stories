extends Node
## Central Utilities - Generic helper functions used across the game

## Load and parse a JSON file
static func load_json_file(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("[Utils] Cannot open file: %s" % path)
		return null
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.parse_string(content)
	if json == null:
		push_error("[Utils] Invalid JSON in file: %s" % path)
		return null
	
	return json

## Save data as JSON to a file
static func save_json_file(path: String, data) -> bool:
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("[Utils] Cannot create file: %s" % path)
		return false
	
	var json_string = JSON.stringify(data, "\t")  # Pretty print with tabs
	file.store_string(json_string)
	file.close()
	
	return true

## Generate a unique ID with prefix
static func generate_id(prefix: String = "id") -> String:
	return "%s_%d_%d" % [prefix, Time.get_ticks_msec(), randi() % 10000]

## Generate UUID (simple implementation, format: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx)
static func generate_uuid() -> String:
	return "%08x-%04x-%04x-%04x-%012x" % [
		randi(),
		randi() & 0xFFFF,
		randi() & 0xFFFF,
		randi() & 0xFFFF,
		(randi() << 16) | (randi() & 0xFFFF)
	]

## Clamp value between min and max
static func clamp_value(value: float, min_val: float, max_val: float) -> float:
	return clampf(value, min_val, max_val)

## Weighted random selection from array
static func weighted_random(options: Array, weights: Array) -> int:
	if options.size() != weights.size():
		push_error("[Utils] Options and weights arrays must be same size")
		return -1
	
	var total = 0.0
	for w in weights:
		total += w
	
	var roll = randf() * total
	var cumulative = 0.0
	
	for i in options.size():
		cumulative += weights[i]
		if roll <= cumulative:
			return i
	
	return 0

## Parse template string and replace {key} with values from dictionary
static func parse_template(template_string: String, variables: Dictionary) -> String:
	var result = template_string
	
	# Find all {key} patterns
	var regex = RegEx.new()
	regex.compile("\\{([^}]+)\\}")
	
	var matches = regex.search_all(result)
	for match_obj in matches:
		var full_match = match_obj.get_string(0)  # {key}
		var key = match_obj.get_string(1)  # key
		
		# Check if key exists in variables
		if variables.has(key):
			var value = variables[key]
			# Convert value to string
			var value_str = str(value) if value != null else ""
			result = result.replace(full_match, value_str)
		else:
			# Missing key - replace with placeholder
			result = result.replace(full_match, "[MISSING:%s]" % key)
	
	return result

## Parse position range [min, max] and scale by organization size
static func parse_position_range(range_array: Array, org_size: String) -> int:
	if range_array.size() != 2:
		push_error("[Utils] Range array must have exactly 2 elements [min, max]")
		return 1
	
	var min_val = range_array[0]
	var max_val = range_array[1]
	
	# Scale by organization size
	var scale_factor = 1.0
	match org_size.to_lower():
		"small":
			scale_factor = 0.5
		"medium":
			scale_factor = 1.0
		"large":
			scale_factor = 1.5
		"very_large":
			scale_factor = 2.0
		_:
			scale_factor = 1.0  # Default to medium
	
	# Apply scaling
	var scaled_min = int(ceil(min_val * scale_factor))
	var scaled_max = int(ceil(max_val * scale_factor))
	
	# Ensure at least 1
	scaled_min = max(1, scaled_min)
	scaled_max = max(1, scaled_max)
	
	# Return random value in scaled range
	return randi() % (scaled_max - scaled_min + 1) + scaled_min

## Weighted random selection of multiple items without replacement
static func weighted_random_multiple(options: Array, weights: Array, count: int) -> Array:
	if options.size() != weights.size():
		push_error("[Utils] Options and weights arrays must be same size")
		return []
	
	if count <= 0:
		return []
	
	if count >= options.size():
		# Return all options
		return options.duplicate()
	
	var result = []
	var available_options = options.duplicate()
	var available_weights = weights.duplicate()
	
	for i in range(count):
		if available_options.is_empty():
			break
		
		# Calculate total weight
		var total = 0.0
		for w in available_weights:
			total += w
		
		# Select one
		var roll = randf() * total
		var cumulative = 0.0
		var selected_index = 0
		
		for j in available_options.size():
			cumulative += available_weights[j]
			if roll <= cumulative:
				selected_index = j
				break
		
		# Add to result
		result.append(available_options[selected_index])
		
		# Remove from available
		available_options.remove_at(selected_index)
		available_weights.remove_at(selected_index)
	
	return result

## Generate value from normal (Gaussian) distribution
static func generate_normal(mean: float, std_dev: float, min_val: float, max_val: float) -> float:
	# Box-Muller transform for generating normal distribution
	var u1 = randf()
	var u2 = randf()
	
	# Avoid log(0)
	u1 = max(0.0001, u1)
	
	var z0 = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
	
	# Scale and shift to desired mean and std_dev
	var value = mean + z0 * std_dev
	
	# Clamp to [min, max]
	value = clampf(value, min_val, max_val)
	
	return value

## Filter items by education requirement
static func filter_by_education(items: Array, npc_education: String) -> Array:
	# Education hierarchy: none < primary < secondary < undergraduate < postgraduate
	var education_levels = ["none", "primary", "secondary", "undergraduate", "postgraduate"]
	var npc_level = education_levels.find(npc_education)
	
	if npc_level == -1:
		push_error("[Utils] Invalid education level: %s" % npc_education)
		return items  # Return all if invalid
	
	var filtered = []
	for item in items:
		if not item is Dictionary:
			continue
		
		# Check if item has required_education field
		if not item.has("required_education"):
			# No requirement, anyone can have it
			filtered.append(item)
			continue
		
		var required = item["required_education"]
		
		# Handle single string requirement
		if required is String:
			var required_level = education_levels.find(required)
			if required_level == -1 or npc_level >= required_level:
				filtered.append(item)
		# Handle array of acceptable education levels
		elif required is Array:
			for req in required:
				if req in education_levels:
					var required_level = education_levels.find(req)
					if npc_level >= required_level:
						filtered.append(item)
						break
	
	return filtered

## Map template skills to NPC skill structure with age factoring
static func map_template_skills_to_npc(occupation_skills: Dictionary, age: int) -> Dictionary:
	# Age factor: younger NPCs have lower skills, older have higher skills
	var age_factor = 1.0
	if age < 26:
		# Young: 18-25, use lower end of ranges (0.6-0.8)
		age_factor = 0.6 + (age - 18) * 0.025  # 18→0.6, 25→0.775
	elif age > 45:
		# Senior: 46+, use upper end but decline physical (0.9-1.0 for mental, 0.7-0.9 for physical)
		age_factor = min(1.0, 0.9 + (age - 45) * 0.01)  # Caps at 1.0
	else:
		# Prime: 26-45, full range (0.8-1.0)
		age_factor = 0.8 + (age - 26) * 0.01
	
	# Initialize NPC skill structure (template has 10 categories, we'll map to simplified structure)
	var skills = {
		"tech": {},
		"business": {},
		"communication": {},
		"physical": {},
		"creative": {},
		"domestic": {},
		"medical": {},
		"academic": {},
		"civic": {},
		"street": {}
	}
	
	# Map template skills to NPC structure
	# Template uses skill ranges like [7, 10] on 0-10 scale, convert to 0-100
	for category in occupation_skills.keys():
		if skills.has(category):
			var category_skills = occupation_skills[category]
			for skill_name in category_skills.keys():
				var skill_range = category_skills[skill_name]
				if skill_range is Array and skill_range.size() == 2:
					var min_val = skill_range[0] * 10.0  # Convert to 0-100
					var max_val = skill_range[1] * 10.0
					
					# Apply age factor
					var range_width = max_val - min_val
					var adjusted_min = min_val + range_width * (1.0 - age_factor) * 0.5
					var adjusted_max = min_val + range_width * age_factor
					
					# Physical skills decline more with age for seniors
					if category == "physical" and age > 45:
						var decline = (age - 45) * 0.02
						adjusted_max = adjusted_max * (1.0 - decline)
						adjusted_min = adjusted_min * (1.0 - decline)
					
					# Generate skill value in adjusted range
					var skill_value = int(randf() * (adjusted_max - adjusted_min) + adjusted_min)
					skill_value = clampi(skill_value, 0, 100)
					
					skills[category][skill_name] = skill_value
	
	return skills

## Inherit a personality/political value from parents
## Rule: child_value = avg(parent1, parent2) ± random(-30, 30)
## Values are typically on -100 to 100 scale
static func inherit_value(parent1_value: int, parent2_value: int) -> int:
	var avg = (parent1_value + parent2_value) / 2.0
	var deviation = randi_range(-30, 30)
	return int(clamp(avg + deviation, -100, 100))

## Inherit appearance traits from parents
## Returns a blended appearance dictionary based on parent genetics
static func inherit_appearance(parent1_appearance: Dictionary, parent2_appearance: Dictionary, child_gender: String) -> Dictionary:
	var inherited = {}
	
	# HEIGHT: Average of parents ± 5cm, gender-adjusted
	var p1_height = parent1_appearance.get("height", 170)
	var p2_height = parent2_appearance.get("height", 170)
	var avg_height = (p1_height + p2_height) / 2.0
	var height_deviation = randf_range(-5.0, 5.0)
	
	# Gender adjustment: males slightly taller
	var gender_adjustment = 0.0
	if child_gender == "male":
		gender_adjustment = 5.0
	elif child_gender == "female":
		gender_adjustment = -5.0
	
	inherited["height"] = avg_height + height_deviation + gender_adjustment
	
	# BUILD: Randomly pick from either parent (genetics)
	var builds = []
	if parent1_appearance.has("build"):
		builds.append(parent1_appearance["build"])
	if parent2_appearance.has("build"):
		builds.append(parent2_appearance["build"])
	inherited["build"] = builds[randi() % builds.size()] if builds.size() > 0 else "average"
	
	# SKIN TONE: Blend between parents
	var p1_skin = parent1_appearance.get("skin_tone", "medium brown")
	var p2_skin = parent2_appearance.get("skin_tone", "medium brown")
	# For simplicity, randomly pick one parent's skin or a middle tone
	# (Realistic genetics would be more complex, but this is sufficient for game)
	var skin_options = [p1_skin, p2_skin]
	inherited["skin_tone"] = skin_options[randi() % skin_options.size()]
	
	# FACIAL FEATURES: Blend from parents
	var p1_features = parent1_appearance.get("facial_features", "rounded")
	var p2_features = parent2_appearance.get("facial_features", "rounded")
	var feature_options = [p1_features, p2_features]
	inherited["facial_features"] = feature_options[randi() % feature_options.size()]
	
	# HAIR TEXTURE: Pick from either parent
	var p1_hair_texture = "coily"
	var p2_hair_texture = "coily"
	if parent1_appearance.has("hair") and parent1_appearance["hair"] is Dictionary:
		p1_hair_texture = parent1_appearance["hair"].get("texture", "coily")
	if parent2_appearance.has("hair") and parent2_appearance["hair"] is Dictionary:
		p2_hair_texture = parent2_appearance["hair"].get("texture", "coily")
	
	var hair_textures = [p1_hair_texture, p2_hair_texture]
	var child_hair_texture = hair_textures[randi() % hair_textures.size()]
	
	# Hair style will be assigned separately based on age/gender
	inherited["hair"] = {
		"texture": child_hair_texture,
		"style": "short"  # Placeholder, will be overridden
	}
	
	# MARKS: Tribal marks inherited (50% chance if either parent has them)
	var has_tribal_marks = false
	var tribal_mark_type = ""
	
	if parent1_appearance.has("marks") and parent1_appearance["marks"].has("tribal"):
		has_tribal_marks = true
		tribal_mark_type = parent1_appearance["marks"]["tribal"]
	elif parent2_appearance.has("marks") and parent2_appearance["marks"].has("tribal"):
		has_tribal_marks = true
		tribal_mark_type = parent2_appearance["marks"]["tribal"]
	
	if has_tribal_marks and randf() < 0.5:  # 50% inheritance chance
		inherited["marks"] = {
			"tribal": tribal_mark_type,
			"scars": [],
			"birthmarks": []
		}
	else:
		inherited["marks"] = {
			"scars": [],
			"birthmarks": []
		}
	
	# Other appearance features NOT inherited (generated fresh):
	# - facial_hair (age/gender dependent)
	# - eyesight (random)
	# - age_effects (age dependent)
	# - distinguishing_marks (random)
	
	return inherited

