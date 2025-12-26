extends RefCounted
## Phase 2A & 4: Population Generation
## Creates family frames and NPCs across multiple passes

var rng = RandomNumberGenerator.new()

# Template data (passed from orchestrator)
var family_templates = {}
var name_data = {}
var appearance_data = {}
var cultural_data = {}
var skill_trees_data = {}

# Generation storage
var family_frames = []
var singles_pool = []
var target_singles_count = 0

# Stats reference
var stats: Dictionary

func _init(p_stats: Dictionary, p_family_templates: Dictionary, p_name_data: Dictionary, p_appearance_data: Dictionary, p_cultural_data: Dictionary, p_skill_trees_data: Dictionary):
	stats = p_stats
	family_templates = p_family_templates
	name_data = p_name_data
	appearance_data = p_appearance_data
	cultural_data = p_cultural_data
	skill_trees_data = p_skill_trees_data
	rng.randomize()

# =============================================================================
# PHASE 2A: FAMILY FRAMES
# =============================================================================

func generate_family_frames(target_npcs: int, family_composition_ratio: float) -> int:
	"""Generate family frames. Returns target_singles count."""
	var start_time = Time.get_ticks_msec()
	
	var all_districts = DB.get_all_districts()
	var districts = []
	for d in all_districts:
		districts.append(d.id)
	
	if districts.is_empty():
		push_error("❌ No districts found for family generation!")
		districts = ["central"]
	
	var template_names = []
	for key in family_templates.keys():
		if not key.begins_with("_"):
			template_names.append(key)
	
	if template_names.is_empty():
		push_error("❌ No family templates found!")
		return 0
	
	var target_family_npcs = int(target_npcs * (1.0 - family_composition_ratio))
	target_singles_count = target_npcs - target_family_npcs
	
	var potential_npc_count = 0
	var family_id = 0
	
	print("   📦 Generating family frames for ~%d family NPCs (%d singles)..." % [target_family_npcs, target_singles_count])
	
	while potential_npc_count < target_family_npcs:
		family_id += 1
		
		var template_name = template_names[rng.randi() % template_names.size()]
		var template = family_templates[template_name]
		
		var tribe = _random_tribe()
		var last_name = _random_last_name(tribe)
		var district = districts[rng.randi() % districts.size()]
		
		var wealth_dist = template.get("wealth_distribution", {})
		var wealth_options = []
		var wealth_weights = []
		for wl in wealth_dist.keys():
			wealth_options.append(wl)
			wealth_weights.append(wealth_dist[wl])
		
		var wealth_level = "middle_class"
		if wealth_options.size() > 0:
			var idx = Utils.weighted_random(wealth_options, wealth_weights)
			if idx >= 0:
				wealth_level = wealth_options[idx]
		
		var size_range = template.get("size_range", [2, 4])
		var target_size = rng.randi_range(size_range[0], size_range[1])
		
		var frame = {
			"id": "family_%d" % family_id,
			"family_id": family_id,
			"template_name": template_name,
			"template": template,
			"tribe": tribe,
			"last_name": last_name,
			"district": district,
			"wealth_level": wealth_level,
			"target_size": target_size,
			"structure": template.structure,
			"common_values": template.get("common_values", {}),
			"housing_preference": template.get("housing_preference", []),
			"generated_npcs": []
		}
		
		family_frames.append(frame)
		potential_npc_count += target_size
		
		if family_frames.size() % 5 == 0:
			var progress = float(potential_npc_count) / float(target_family_npcs) * 100.0
			print("      [%3.0f%%] %d frames (%d capacity)" % [progress, family_frames.size(), potential_npc_count])
	
	stats.families = family_frames.size()
	print("   ✅ Created %d family frames (%.2fs)" % [family_frames.size(), (Time.get_ticks_msec() - start_time) / 1000.0])
	
	return target_singles_count

# =============================================================================
# PHASE 4: MULTI-PASS NPC GENERATION
# =============================================================================

func pass1_generate_founders():
	"""Pass 1: Generate family founders (parent_1)"""
	var start_time = Time.get_ticks_msec()
	print("   👤 Pass 1: Generating %d family founders..." % family_frames.size())
	var created = 0
	
	for frame in family_frames:
		if not frame.structure.has("parent_1"):
			continue
		
		var p1_def = frame.structure["parent_1"]
		var age = rng.randi_range(p1_def.age_min, p1_def.age_max)
		var gender = "male" if rng.randf() < 0.5 else "female"
		var first_name = _random_first_name(frame.tribe, gender)
		
		var npc_id = "npc_%s" % Utils.generate_uuid()
		_create_npc(npc_id, first_name, frame.last_name, age, gender, frame.tribe, frame.family_id, frame.district)
		
		frame.generated_npcs.append({
			"id": npc_id,
			"role": "parent_1",
			"age": age,
			"gender": gender
		})
		
		singles_pool.append({
			"id": npc_id,
			"family_id": frame.family_id,
			"age": age,
			"gender": gender,
			"tribe": frame.tribe,
			"needs_spouse": true
		})
		
		stats.npcs += 1
		created += 1
	
	print("      ✅ Created %d founders (%.2fs)" % [created, (Time.get_ticks_msec() - start_time) / 1000.0])

func pass2_generate_spouses():
	"""Pass 2: Generate spouses (parent_2)"""
	var start_time = Time.get_ticks_msec()
	print("   💑 Pass 2: Generating spouses...")
	var created = 0
	
	for frame in family_frames:
		if not frame.structure.has("parent_2"):
			continue
		
		var p2_def = frame.structure["parent_2"]
		if p2_def.get("optional", false) and rng.randf() < 0.3:
			continue
		
		var parent1_data = null
		for npc in frame.generated_npcs:
			if npc.role == "parent_1":
				parent1_data = npc
				break
		
		if parent1_data == null:
			continue
		
		var spouse_gender = "female" if parent1_data.gender == "male" else "male"
		var age = rng.randi_range(p2_def.age_min, p2_def.age_max)
		var first_name = _random_first_name(frame.tribe, spouse_gender)
		
		var npc_id = "npc_%s" % Utils.generate_uuid()
		_create_npc(npc_id, first_name, frame.last_name, age, spouse_gender, frame.tribe, frame.family_id, frame.district)
		
		frame.generated_npcs.append({
			"id": npc_id,
			"role": "parent_2",
			"age": age,
			"gender": spouse_gender
		})
		
		# Create marriage relationship
		var affection = rng.randi_range(40, 90)
		var trust = rng.randi_range(50, 95)
		var respect = rng.randi_range(40, 85)
		var years_married = rng.randi_range(2, 20)
		var marriage_date = "%d-01-01" % (2025 - years_married)
		
		DB.create_relationship(parent1_data.id, npc_id, "spouse", affection, trust, 0, respect, marriage_date)
		DB.create_relationship(npc_id, parent1_data.id, "spouse", affection, trust, 0, respect, marriage_date)
		
		stats.npcs += 1
		created += 1
	
	print("      ✅ Created %d spouses (%.2fs)" % [created, (Time.get_ticks_msec() - start_time) / 1000.0])

func pass3_generate_children():
	"""Pass 3: Generate children with inheritance"""
	var start_time = Time.get_ticks_msec()
	print("   👶 Pass 3: Generating children with inheritance...")
	var created = 0
	
	for frame in family_frames:
		if not frame.structure.has("children"):
			continue
		
		var children_def = frame.structure["children"]
		var child_count = rng.randi_range(children_def.count_min, children_def.count_max)
		
		var parent1_id = null
		var parent2_id = null
		for npc in frame.generated_npcs:
			if npc.role == "parent_1":
				parent1_id = npc.id
			elif npc.role == "parent_2":
				parent2_id = npc.id
		
		if parent1_id == null:
			continue
		
		var parent1_data = DB.get_npc(parent1_id)
		var parent2_data = null
		if parent2_id:
			parent2_data = DB.get_npc(parent2_id)
		
		var youngest_parent_age = parent1_data.definite.age
		if parent2_data and parent2_data.definite.age < youngest_parent_age:
			youngest_parent_age = parent2_data.definite.age
		
		for i in range(child_count):
			const MIN_GAP = 18
			var max_child_age = youngest_parent_age - MIN_GAP
			var child_age_min = children_def.age_min
			var child_age_max = min(children_def.age_max, max(max_child_age, 0))
			
			if child_age_max < child_age_min:
				continue
			
			var age = rng.randi_range(child_age_min, child_age_max)
			var gender = "male" if rng.randf() < 0.5 else "female"
			var first_name = _random_first_name(frame.tribe, gender)
			
			var npc_id = "npc_%s" % Utils.generate_uuid()
			_create_child_npc(npc_id, first_name, frame.last_name, age, gender, frame.tribe, frame.family_id, frame.district, parent1_data, parent2_data)
			
			frame.generated_npcs.append({
				"id": npc_id,
				"role": "child",
				"age": age,
				"gender": gender
			})
			
			# Parent-child relationships
			var child_aff = rng.randi_range(60, 95)
			var child_trust = rng.randi_range(70, 100)
			var child_respect = rng.randi_range(50, 90)
			
			DB.create_relationship(npc_id, parent1_id, "parent", child_aff, child_trust, 0, child_respect)
			DB.create_relationship(parent1_id, npc_id, "child", rng.randi_range(70, 100), rng.randi_range(70, 100), 0, rng.randi_range(60, 90))
			
			if parent2_id:
				DB.create_relationship(npc_id, parent2_id, "parent", child_aff, child_trust, 0, child_respect)
				DB.create_relationship(parent2_id, npc_id, "child", rng.randi_range(70, 100), rng.randi_range(70, 100), 0, rng.randi_range(60, 90))
			
			stats.npcs += 1
			created += 1
	
	# Sibling relationships
	var sibling_count = 0
	for frame in family_frames:
		var children = []
		for npc in frame.generated_npcs:
			if npc.role == "child":
				children.append(npc)
		
		for i in range(children.size()):
			for j in range(i + 1, children.size()):
				var aff = rng.randi_range(20, 80)
				var trust = rng.randi_range(30, 90)
				DB.create_relationship(children[i].id, children[j].id, "sibling", aff, trust, 0, rng.randi_range(30, 70))
				DB.create_relationship(children[j].id, children[i].id, "sibling", aff, trust, 0, rng.randi_range(30, 70))
				sibling_count += 2
	
	print("      ✅ Created %d children + %d sibling rels (%.2fs)" % [created, sibling_count, (Time.get_ticks_msec() - start_time) / 1000.0])

func pass4_generate_extended():
	"""Pass 4: Generate extended family members (grandparents, aunts, uncles, cousins)"""
	var start_time = Time.get_ticks_msec()
	print("   👴 Pass 4: Generating extended family...")
	var created = 0
	
	# Extended family member types that are NOT core family (parent_1, parent_2, children)
	var extended_types = ["grandparent", "aunt", "uncle", "cousin", "nephew", "niece"]
	
	for frame in family_frames:
		var structure = frame.structure
		if not structure is Dictionary:
			continue
		
		# Check for extended family members directly in structure
		for member_type in extended_types:
			if not structure.has(member_type):
				continue
			
			var member_def = structure[member_type]
			if not member_def is Dictionary:
				continue
			
			# Determine count
			var count = 1
			if member_def.has("count"):
				count = member_def["count"]
			elif member_def.has("count_max"):
				# For grandparent, use count_max (usually 2)
				if member_type == "grandparent":
					count = rng.randi_range(0, member_def.count_max)
				else:
					count = rng.randi_range(1, member_def.count_max)
			elif member_def.has("count_min") and member_def.has("count_max"):
				count = rng.randi_range(member_def.count_min, member_def.count_max)
			
			# Skip if optional and random check fails
			if member_def.get("optional", false) and rng.randf() < 0.5:
				continue
			
			# Generate members
			for i in range(count):
				var age = rng.randi_range(member_def.age_min, member_def.age_max)
				var gender = "male" if rng.randf() < 0.5 else "female"
				
				# Gender-specific types
				if member_type == "aunt":
					gender = "female"
				elif member_type == "uncle":
					gender = "male"
				elif member_type == "niece":
					gender = "female"
				elif member_type == "nephew":
					gender = "male"
				
				var first_name = _random_first_name(frame.tribe, gender)
				var last_name = frame.last_name
				
				# Extended family may have different last names
				if member_type in ["aunt", "uncle", "cousin", "nephew", "niece"] and rng.randf() < 0.4:
					last_name = _random_last_name(frame.tribe)
				
				var npc_id = "npc_%s" % Utils.generate_uuid()
				_create_npc(npc_id, first_name, last_name, age, gender, frame.tribe, frame.family_id, frame.district)
				
				frame.generated_npcs.append({
					"id": npc_id,
					"role": member_type,
					"age": age,
					"gender": gender
				})
				
				stats.npcs += 1
				created += 1
		
		# Create relationships for extended family members
		_create_extended_family_relationships(frame)
	
	print("      ✅ Created %d extended family (%.2fs)" % [created, (Time.get_ticks_msec() - start_time) / 1000.0])

func _create_extended_family_relationships(frame: Dictionary):
	"""Create relationships between extended family members and core family."""
	var parent1_id = null
	var parent2_id = null
	var children = []
	var grandparents = []
	var aunts = []
	var uncles = []
	var cousins = []
	var nephews = []
	var nieces = []
	
	# Organize family members by role
	for npc in frame.generated_npcs:
		match npc.role:
			"parent_1":
				parent1_id = npc.id
			"parent_2":
				parent2_id = npc.id
			"child":
				children.append(npc)
			"grandparent":
				grandparents.append(npc)
			"aunt":
				aunts.append(npc)
			"uncle":
				uncles.append(npc)
			"cousin":
				cousins.append(npc)
			"nephew":
				nephews.append(npc)
			"niece":
				nieces.append(npc)
	
	# Grandparent relationships: randomly assign to one parent (blood), other gets in-law
	for grandparent in grandparents:
		# Randomly choose which parent gets the blood relationship
		var blood_parent_id = parent1_id if (parent2_id == null or rng.randf() < 0.5) else parent2_id
		var in_law_parent_id = parent2_id if blood_parent_id == parent1_id else parent1_id
		
		# Get grandparent gender to determine in-law type
		var grandparent_data = DB.get_npc(grandparent.id)
		var grandparent_gender = grandparent_data.get("definite", {}).get("gender", "male") if grandparent_data else "male"
		
		# Blood relationship: grandparent → parent (parent-child)
		if blood_parent_id:
			var aff = rng.randi_range(60, 90)
			var trust = rng.randi_range(70, 95)
			var respect = rng.randi_range(80, 100)
			DB.create_relationship(grandparent.id, blood_parent_id, "parent", aff, trust, 0, respect)
			DB.create_relationship(blood_parent_id, grandparent.id, "child", rng.randi_range(70, 95), rng.randi_range(80, 100), 0, rng.randi_range(85, 100))
		
		# In-law relationship: grandparent → spouse (mother_in_law/father_in_law)
		if in_law_parent_id:
			var aff = rng.randi_range(40, 75)  # Lower than blood relationship
			var trust = rng.randi_range(50, 80)
			var respect = rng.randi_range(60, 85)
			var in_law_type = "mother_in_law" if grandparent_gender == "female" else "father_in_law"
			# Get in-law parent gender to determine reverse
			var in_law_data = DB.get_npc(in_law_parent_id)
			var in_law_gender = in_law_data.get("definite", {}).get("gender", "male") if in_law_data else "male"
			var reverse_type = "son_in_law" if in_law_gender == "male" else "daughter_in_law"
			DB.create_relationship(grandparent.id, in_law_parent_id, in_law_type, aff, trust, 0, respect)
			DB.create_relationship(in_law_parent_id, grandparent.id, reverse_type, rng.randi_range(50, 80), rng.randi_range(60, 85), 0, rng.randi_range(60, 80))
		
		# Grandparent → grandchildren (grandparent-grandchild relationship)
		# All grandchildren are blood relatives regardless of which parent
		for child in children:
			var aff = rng.randi_range(70, 95)
			var trust = rng.randi_range(75, 95)
			var respect = rng.randi_range(80, 100)
			DB.create_relationship(grandparent.id, child.id, "grandparent", aff, trust, 0, respect)
			DB.create_relationship(child.id, grandparent.id, "grandchild", rng.randi_range(75, 95), rng.randi_range(80, 100), 0, rng.randi_range(85, 100))
	
	# Aunt/Uncle relationships: randomly assign to one parent (sibling), other gets in-law
	for aunt in aunts:
		# Randomly choose which parent gets the blood relationship
		var blood_parent_id = parent1_id if (parent2_id == null or rng.randf() < 0.5) else parent2_id
		var in_law_parent_id = parent2_id if blood_parent_id == parent1_id else parent1_id
		
		# Blood relationship: aunt → parent (sibling)
		if blood_parent_id:
			var aff = rng.randi_range(40, 80)
			var trust = rng.randi_range(50, 85)
			var respect = rng.randi_range(40, 75)
			DB.create_relationship(aunt.id, blood_parent_id, "sibling", aff, trust, 0, respect)
			DB.create_relationship(blood_parent_id, aunt.id, "sibling", aff, trust, 0, respect)
		
		# In-law relationship: aunt → spouse (sister_in_law)
		# Both directions are "sister_in_law" (sister of spouse)
		if in_law_parent_id:
			var aff = rng.randi_range(30, 65)  # Lower than blood relationship
			var trust = rng.randi_range(40, 70)
			var respect = rng.randi_range(30, 60)
			DB.create_relationship(aunt.id, in_law_parent_id, "sister_in_law", aff, trust, 0, respect)
			DB.create_relationship(in_law_parent_id, aunt.id, "sister_in_law", rng.randi_range(30, 65), rng.randi_range(40, 70), 0, rng.randi_range(30, 60))
		
		# Aunt → nieces/nephews (aunt-niece/nephew relationship)
		# All children are blood relatives regardless of which parent
		for child in children:
			var aff = rng.randi_range(50, 85)
			var trust = rng.randi_range(60, 90)
			var respect = rng.randi_range(50, 80)
			DB.create_relationship(aunt.id, child.id, "aunt", aff, trust, 0, respect)
			# Child is niece or nephew depending on gender
			var rel_type = "niece" if child.gender == "female" else "nephew"
			DB.create_relationship(child.id, aunt.id, rel_type, rng.randi_range(60, 85), rng.randi_range(70, 95), 0, rng.randi_range(60, 85))
	
	for uncle in uncles:
		# Randomly choose which parent gets the blood relationship
		var blood_parent_id = parent1_id if (parent2_id == null or rng.randf() < 0.5) else parent2_id
		var in_law_parent_id = parent2_id if blood_parent_id == parent1_id else parent1_id
		
		# Blood relationship: uncle → parent (sibling)
		if blood_parent_id:
			var aff = rng.randi_range(40, 80)
			var trust = rng.randi_range(50, 85)
			var respect = rng.randi_range(40, 75)
			DB.create_relationship(uncle.id, blood_parent_id, "sibling", aff, trust, 0, respect)
			DB.create_relationship(blood_parent_id, uncle.id, "sibling", aff, trust, 0, respect)
		
		# In-law relationship: uncle → spouse (brother_in_law)
		# Both directions are "brother_in_law" (brother of spouse)
		if in_law_parent_id:
			var aff = rng.randi_range(30, 65)  # Lower than blood relationship
			var trust = rng.randi_range(40, 70)
			var respect = rng.randi_range(30, 60)
			DB.create_relationship(uncle.id, in_law_parent_id, "brother_in_law", aff, trust, 0, respect)
			DB.create_relationship(in_law_parent_id, uncle.id, "brother_in_law", rng.randi_range(30, 65), rng.randi_range(40, 70), 0, rng.randi_range(30, 60))
		
		# Uncle → nieces/nephews (uncle-niece/nephew relationship)
		# All children are blood relatives regardless of which parent
		for child in children:
			var aff = rng.randi_range(50, 85)
			var trust = rng.randi_range(60, 90)
			var respect = rng.randi_range(50, 80)
			DB.create_relationship(uncle.id, child.id, "uncle", aff, trust, 0, respect)
			# Child is niece or nephew depending on gender
			var rel_type = "niece" if child.gender == "female" else "nephew"
			DB.create_relationship(child.id, uncle.id, rel_type, rng.randi_range(60, 85), rng.randi_range(70, 95), 0, rng.randi_range(60, 85))
	
	# Cousin relationships: cousin ↔ children (cousin relationship - symmetric)
	for cousin in cousins:
		for child in children:
			var aff = rng.randi_range(30, 70)
			var trust = rng.randi_range(40, 75)
			var respect = rng.randi_range(30, 65)
			DB.create_relationship(cousin.id, child.id, "cousin", aff, trust, 0, respect)
			# "cousin" is symmetric, so DB.create_relationship will create both directions
		
		# Cousin → parents (aunt/uncle relationship, as cousins are children of parent's siblings)
		if parent1_id:
			var aff = rng.randi_range(50, 80)
			var trust = rng.randi_range(60, 85)
			var respect = rng.randi_range(50, 75)
			# Determine if parent is aunt or uncle based on gender
			var parent_data = DB.get_npc(parent1_id)
			var parent_gender = parent_data.get("definite", {}).get("gender", "male") if parent_data else "male"
			var rel_type = "aunt" if parent_gender == "female" else "uncle"
			DB.create_relationship(cousin.id, parent1_id, rel_type, aff, trust, 0, respect)
			DB.create_relationship(parent1_id, cousin.id, "nephew", rng.randi_range(60, 85), rng.randi_range(70, 90), 0, rng.randi_range(60, 80))
	
	# Nephew/Niece relationships: nephew/niece → parent's sibling (aunt/uncle)
	# These are children of the parent's siblings (aunts/uncles)
	for nephew in nephews:
		# Nephew is child of aunt/uncle, so relationship to parents is aunt/uncle
		if parent1_id:
			var aff = rng.randi_range(50, 80)
			var trust = rng.randi_range(60, 85)
			var respect = rng.randi_range(50, 75)
			var parent_data = DB.get_npc(parent1_id)
			var parent_gender = parent_data.get("definite", {}).get("gender", "male") if parent_data else "male"
			var rel_type = "aunt" if parent_gender == "female" else "uncle"
			DB.create_relationship(nephew.id, parent1_id, rel_type, aff, trust, 0, respect)
			DB.create_relationship(parent1_id, nephew.id, "nephew", rng.randi_range(60, 85), rng.randi_range(70, 90), 0, rng.randi_range(60, 80))
		
		# Nephew → children (cousin relationship - symmetric)
		for child in children:
			var aff = rng.randi_range(30, 70)
			var trust = rng.randi_range(40, 75)
			var respect = rng.randi_range(30, 65)
			DB.create_relationship(nephew.id, child.id, "cousin", aff, trust, 0, respect)
			# "cousin" is symmetric, so DB.create_relationship will create both directions
	
	for niece in nieces:
		if parent1_id:
			var aff = rng.randi_range(50, 80)
			var trust = rng.randi_range(60, 85)
			var respect = rng.randi_range(50, 75)
			var parent_data = DB.get_npc(parent1_id)
			var parent_gender = parent_data.get("definite", {}).get("gender", "male") if parent_data else "male"
			var rel_type = "aunt" if parent_gender == "female" else "uncle"
			DB.create_relationship(niece.id, parent1_id, rel_type, aff, trust, 0, respect)
			DB.create_relationship(parent1_id, niece.id, "niece", rng.randi_range(60, 85), rng.randi_range(70, 90), 0, rng.randi_range(60, 80))
		
		# Niece → children (cousin relationship - symmetric)
		for child in children:
			var aff = rng.randi_range(30, 70)
			var trust = rng.randi_range(40, 75)
			var respect = rng.randi_range(30, 65)
			DB.create_relationship(niece.id, child.id, "cousin", aff, trust, 0, respect)
			# "cousin" is symmetric, so DB.create_relationship will create both directions

func pass5_generate_singles(target_count: int):
	"""Pass 5: Generate single NPCs"""
	var start_time = Time.get_ticks_msec()
	
	if target_count <= 0:
		print("   ✅ Pass 5: No singles needed")
		return
	
	var all_districts = DB.get_all_districts()
	var districts = []
	for d in all_districts:
		districts.append(d.id)
	if districts.is_empty():
		districts = ["central"]
	
	print("   🚶 Pass 5: Generating %d singles..." % target_count)
	var created = 0
	
	for i in range(target_count):
		var age = rng.randi_range(18, 65)
		var gender = "male" if rng.randf() < 0.5 else "female"
		var tribe = _random_tribe()
		var first_name = _random_first_name(tribe, gender)
		var last_name = _random_last_name(tribe)
		var district = districts[rng.randi() % districts.size()]
		
		var npc_id = "npc_%s" % Utils.generate_uuid()
		var single_family_id = 999000 + i
		
		_create_npc(npc_id, first_name, last_name, age, gender, tribe, single_family_id, district)
		
		singles_pool.append({
			"id": npc_id,
			"family_id": single_family_id,
			"age": age,
			"gender": gender,
			"tribe": tribe,
			"needs_spouse": false
		})
		
		stats.npcs += 1
		created += 1
		
		if created % 10 == 0:
			print("      [%3.0f%%] %d/%d singles" % [float(created) / target_count * 100.0, created, target_count])
	
	print("   ✅ Pass 5: Created %d singles (%.2fs)" % [created, (Time.get_ticks_msec() - start_time) / 1000.0])

# =============================================================================
# NPC CREATION HELPERS
# =============================================================================

func _create_npc(id: String, first_name: String, last_name: String, age: int, gender: String, tribe: String, family_id: int, district: String):
	var npc_data = {
		"id": id,
		"name": "%s %s" % [first_name, last_name],
		"definite": {
			"gender": gender,
			"age": age,
			"alive": true,
			"orientation": _generate_orientation()
		},
		"attributes": _generate_attributes(age),
		"appearance": _generate_appearance(gender, age, tribe),
		"identity": {
			"tribe": tribe,
			"spoken_languages": ["english", "pidgin"],
			"education": {"level": _random_education(), "institution": null},
			"religious_path": _random_religion(tribe),
			"occupation": "",
			"family_id": "family_%d" % family_id,
			"district": district,  # Keep for backward compatibility
			"district_id": district  # Standardized field - always stores district UUID
		},
		"personality": _generate_personality(tribe),
		"political_ideology": _generate_political_ideology(),
		"skills": {},
		"resources": {"liquid_assets": [], "property": [], "access": [], "annual_income": 0},
		"status": {"health": rng.randi_range(70, 100), "stress": rng.randi_range(10, 50), "reputation": rng.randi_range(30, 70)},
		"demographic_affinities": {}
	}
	
	var education = npc_data.identity.education.level
	var occupation = _random_occupation(education, age)
	npc_data.identity.occupation = occupation
	npc_data.skills = _generate_skills(occupation, age)
	npc_data.resources.annual_income = _generate_salary_for_occupation(occupation, age)
	
	DB.create_npc(npc_data)

func _create_child_npc(id: String, first_name: String, last_name: String, age: int, gender: String, tribe: String, family_id: int, district: String, parent1_data: Dictionary, parent2_data):
	var p1_personality = parent1_data.get("personality", {})
	var p1_political = parent1_data.get("political_ideology", {})
	var p1_appearance = parent1_data.get("appearance", {})
	
	var p2_personality = {}
	var p2_political = {}
	var p2_appearance = {}
	
	if parent2_data != null and parent2_data is Dictionary:
		p2_personality = parent2_data.get("personality", {})
		p2_political = parent2_data.get("political_ideology", {})
		p2_appearance = parent2_data.get("appearance", {})
	
	# Inherit personality
	var child_personality = {}
	for trait_name in p1_personality.keys():
		if p2_personality.has(trait_name):
			child_personality[trait_name] = Utils.inherit_value(p1_personality[trait_name], p2_personality[trait_name])
		else:
			child_personality[trait_name] = Utils.inherit_value(p1_personality[trait_name], p1_personality[trait_name])
	
	# Apply cultural modifiers
	if cultural_data.has("tribes") and cultural_data.tribes.has(tribe):
		var tribe_data = cultural_data.tribes[tribe]
		if tribe_data.has("personality_modifiers"):
			for trait_name in tribe_data.personality_modifiers.keys():
				if child_personality.has(trait_name):
					child_personality[trait_name] = clamp(child_personality[trait_name] + tribe_data.personality_modifiers[trait_name], -100, 100)
	
	# Inherit political ideology
	var child_political = {}
	for ideology in p1_political.keys():
		if p2_political.has(ideology):
			child_political[ideology] = Utils.inherit_value(p1_political[ideology], p2_political[ideology])
		else:
			child_political[ideology] = Utils.inherit_value(p1_political[ideology], p1_political[ideology])
	
	# Inherit appearance
	var child_appearance = {}
	if p2_appearance.size() > 0:
		child_appearance = Utils.inherit_appearance(p1_appearance, p2_appearance, gender)
	else:
		child_appearance = Utils.inherit_appearance(p1_appearance, p1_appearance, gender)
	
	child_appearance = _complete_child_appearance(child_appearance, gender, age)
	
	var npc_data = {
		"id": id,
		"name": "%s %s" % [first_name, last_name],
		"definite": {"gender": gender, "age": age, "alive": true, "orientation": _generate_orientation()},
		"attributes": _generate_attributes(age),
		"appearance": child_appearance,
		"identity": {
			"tribe": tribe,
			"spoken_languages": ["english", "pidgin"],
			"education": {"level": _random_education(), "institution": null},
			"religious_path": _random_religion(tribe),
			"occupation": "",
			"family_id": "family_%d" % family_id,
			"district": district,  # Keep for backward compatibility
			"district_id": district  # Standardized field - always stores district UUID
		},
		"personality": child_personality,
		"political_ideology": child_political,
		"skills": {},
		"resources": {"liquid_assets": [], "property": [], "access": [], "annual_income": 0},
		"status": {"health": rng.randi_range(70, 100), "stress": rng.randi_range(10, 50), "reputation": rng.randi_range(30, 70)},
		"demographic_affinities": {}
	}
	
	var education = npc_data.identity.education.level
	var occupation = _random_occupation(education, age)
	npc_data.identity.occupation = occupation
	npc_data.skills = _generate_skills(occupation, age)
	npc_data.resources.annual_income = _generate_salary_for_occupation(occupation, age)
	
	DB.create_npc(npc_data)

func _complete_child_appearance(inherited: Dictionary, gender: String, age: int) -> Dictionary:
	var appearance = inherited.duplicate(true)
	
	if age < 10:
		if appearance.has("hair"):
			appearance["hair"]["style"] = "short" if gender == "male" else ["short", "ponytail", "braids"][rng.randi() % 3]
	
	if gender == "male" and age >= 16:
		appearance["facial_hair"] = "stubble" if rng.randf() < 0.3 else "none"
	else:
		appearance["facial_hair"] = "none"
	
	appearance["age_effects"] = []
	return appearance

# =============================================================================
# RANDOM DATA HELPERS
# =============================================================================

func _random_tribe() -> String:
	if not cultural_data.has("tribes"):
		return "yoruba"
	
	var tribes = []
	var weights = []
	for key in cultural_data.tribes.keys():
		var td = cultural_data.tribes[key]
		if td.has("population_percentage"):
			tribes.append(key)
			weights.append(td.population_percentage)
	
	if tribes.is_empty():
		return "yoruba"
	
	var idx = Utils.weighted_random(tribes, weights)
	return tribes[idx] if idx >= 0 else tribes[0]

func _random_first_name(_tribe: String, gender: String) -> String:
	if not name_data.has("people"):
		return "John" if gender == "male" else "Jane"
	
	var key = "given_names_male" if gender == "male" else "given_names_female"
	var names = name_data.people.get(key, [])
	if names.is_empty():
		return "John" if gender == "male" else "Jane"
	
	return names[rng.randi() % names.size()]

func _random_last_name(_tribe: String) -> String:
	if not name_data.has("people") or not name_data.people.has("surnames"):
		return "Smith"
	
	var surnames = name_data.people.surnames
	if surnames.is_empty():
		return "Smith"
	
	return surnames[rng.randi() % surnames.size()]

func _random_education() -> String:
	var options = ["none", "primary", "secondary", "undergraduate", "postgraduate"]
	var weights = [0.10, 0.20, 0.35, 0.25, 0.10]
	var roll = rng.randf()
	var cumulative = 0.0
	for i in range(options.size()):
		cumulative += weights[i]
		if roll <= cumulative:
			return options[i]
	return "secondary"

func _random_religion(tribe: String) -> String:
	if not cultural_data.has("tribes") or not cultural_data.tribes.has(tribe):
		return "christian"
	
	var dist = cultural_data.tribes[tribe].get("religion_distribution", {})
	var options = []
	var weights = []
	for r in dist.keys():
		options.append(r)
		weights.append(dist[r])
	
	if options.is_empty():
		return "christian"
	
	var idx = Utils.weighted_random(options, weights)
	return options[idx] if idx >= 0 else "christian"

func _random_occupation(education: String, age: int) -> String:
	if not skill_trees_data.has("occupations"):
		return "student" if age < 25 else "unemployed"
	
	var occs = skill_trees_data.occupations.values()
	var filtered = Utils.filter_by_education(occs, education)
	
	if filtered.is_empty():
		return "student" if age < 25 else "unemployed"
	
	var occ_opts = []
	var weights = []
	for occ in filtered:
		occ_opts.append(occ)
		var w = 1.0
		if occ.has("typical_salary_range") and occ.typical_salary_range is Array:
			w = max(1.0, (occ.typical_salary_range[0] + occ.typical_salary_range[1]) / 2.0 / 1000000.0)
		weights.append(w)
	
	var idx = Utils.weighted_random(occ_opts, weights)
	if idx < 0 or idx >= occ_opts.size():
		idx = 0
	
	return occ_opts[idx].get("display_name", "unemployed")

# =============================================================================
# GENERATION HELPERS
# =============================================================================

func _generate_orientation() -> int:
	var roll = rng.randf()
	if roll < 0.85:
		return rng.randi_range(50, 100)
	elif roll < 0.90:
		return rng.randi_range(-30, 30)
	else:
		return rng.randi_range(-100, -50)

func _generate_attributes(_age: int) -> Dictionary:
	return {
		"strength": rng.randi_range(30, 70),
		"agility": rng.randi_range(30, 70),
		"intelligence": rng.randi_range(40, 80),
		"charisma": rng.randi_range(30, 70),
		"endurance": rng.randi_range(40, 70)
	}

func _generate_personality(tribe: String) -> Dictionary:
	var personality = {
		"ambition": rng.randi_range(30, 90),
		"compassion": rng.randi_range(30, 90),
		"volatility": rng.randi_range(20, 70),
		"openness": rng.randi_range(30, 80),
		"gender_bias": rng.randi_range(0, 50),
		"ethnic_prejudice": rng.randi_range(0, 40),
		"class_bias": rng.randi_range(0, 60),
		"religious_intolerance": rng.randi_range(0, 50),
		"social_conformity": rng.randi_range(30, 80)
	}
	
	if cultural_data.has("tribes") and cultural_data.tribes.has(tribe):
		var td = cultural_data.tribes[tribe]
		if td.has("cultural_values"):
			var vals = td.cultural_values
			if vals.has("individualism"):
				personality.ambition = clampi(personality.ambition + int((vals.individualism - 50) * 0.3), 0, 100)
			if vals.has("collectivism"):
				personality.social_conformity = clampi(personality.social_conformity + int((vals.collectivism - 50) * 0.3), 0, 100)
	
	return personality

func _generate_political_ideology() -> Dictionary:
	return {
		"social_conservatism": rng.randi_range(20, 80),
		"economic_conservatism": rng.randi_range(20, 80),
		"authoritarianism": rng.randi_range(10, 60),
		"nationalism": rng.randi_range(30, 80),
		"religious_devotion": rng.randi_range(30, 90),
		"environmentalism": rng.randi_range(20, 70)
	}

func _generate_appearance(gender: String, age: int, _tribe: String) -> Dictionary:
	var appearance = {}
	
	# Height
	if gender == "male":
		appearance["height"] = rng.randi_range(165, 185)
	else:
		appearance["height"] = rng.randi_range(155, 175)
	
	# Build
	var builds = ["slim", "average", "athletic", "heavy"]
	var build_weights = [0.25, 0.40, 0.20, 0.15]
	if age < 18:
		build_weights = [0.50, 0.35, 0.10, 0.05]
	elif age > 60:
		build_weights = [0.15, 0.40, 0.10, 0.35]
	var build_idx = Utils.weighted_random(builds, build_weights)
	appearance["build"] = builds[build_idx] if build_idx >= 0 else "average"
	
	# Skin tone
	var skin_tones = ["light", "medium", "dark", "very_dark"]
	appearance["skin_tone"] = skin_tones[rng.randi() % skin_tones.size()]
	
	# Facial features
	appearance["facial_features"] = {
		"nose": ["narrow", "average", "broad"][rng.randi() % 3],
		"eyes": ["small", "average", "large"][rng.randi() % 3],
		"lips": ["thin", "medium", "full"][rng.randi() % 3],
		"face_shape": ["oval", "round", "square", "heart"][rng.randi() % 4]
	}
	
	# Hair
	appearance["hair"] = {
		"texture": ["straight", "wavy", "curly", "coily"][rng.randi() % 4],
		"style": "short" if gender == "male" else ["short", "medium", "long"][rng.randi() % 3]
	}
	
	# Facial hair
	if gender == "male" and age >= 18:
		appearance["facial_hair"] = ["none", "stubble", "beard", "mustache", "goatee"][rng.randi() % 5]
	else:
		appearance["facial_hair"] = "none"
	
	# Eyesight
	appearance["eyesight"] = "normal" if rng.randf() < 0.75 else "short_sighted"
	
	# Marks
	appearance["marks"] = {"has_marks": rng.randf() < 0.35}
	
	# Age effects
	appearance["age_effects"] = {
		"gray_hair": age >= 40 and rng.randf() < (age - 40) * 0.05,
		"wrinkles": age >= 45 and rng.randf() < (age - 45) * 0.04,
		"posture_change": age >= 60
	}
	
	return appearance

func _generate_skills(occupation: String, age: int) -> Dictionary:
	if not skill_trees_data.has("occupations"):
		return {}
	
	var occ_data = null
	for key in skill_trees_data.occupations.keys():
		var occ = skill_trees_data.occupations[key]
		if occ.get("display_name", "") == occupation:
			occ_data = occ
			break
	
	if occ_data == null:
		return {}
	
	var skill_to_cat = {}
	if skill_trees_data.has("skill_categories"):
		for cat_key in skill_trees_data.skill_categories.keys():
			var cat = skill_trees_data.skill_categories[cat_key]
			if cat.has("specific_skills"):
				for skill_name in cat.specific_skills.keys():
					skill_to_cat[skill_name] = cat_key.replace("_skills", "")
	
	var occupation_skills = {}
	if occ_data.has("primary_skills"):
		for skill_name in occ_data.primary_skills.keys():
			var cat = skill_to_cat.get(skill_name, "street")
			if not occupation_skills.has(cat):
				occupation_skills[cat] = {}
			occupation_skills[cat][skill_name] = occ_data.primary_skills[skill_name]
	
	if occ_data.has("secondary_skills"):
		for skill_name in occ_data.secondary_skills.keys():
			var cat = skill_to_cat.get(skill_name, "street")
			if not occupation_skills.has(cat):
				occupation_skills[cat] = {}
			occupation_skills[cat][skill_name] = occ_data.secondary_skills[skill_name]
	
	return Utils.map_template_skills_to_npc(occupation_skills, age)

func _generate_salary_for_occupation(occupation: String, age: int) -> int:
	if not skill_trees_data.has("occupations"):
		return 0
	
	var occ_data = null
	for key in skill_trees_data.occupations.keys():
		var occ = skill_trees_data.occupations[key]
		if occ.get("display_name", "") == occupation:
			occ_data = occ
			break
	
	if occ_data == null or not occ_data.has("typical_salary_range"):
		return 0
	
	var salary_range = occ_data.typical_salary_range
	if not salary_range is Array or salary_range.size() != 2:
		return 0
	
	var min_sal = float(salary_range[0])
	var max_sal = float(salary_range[1])
	
	var exp_factor = 0.5
	if age >= 45:
		exp_factor = 1.0
	elif age >= 30:
		exp_factor = 0.7 + float(age - 30) * 0.02
	else:
		exp_factor = 0.5 + float(age - 18) * 0.016
	
	return int(min_sal + (max_sal - min_sal) * exp_factor)

# =============================================================================
# PUBLIC API: LANDLORD CREATION
# =============================================================================

func create_landlord_npc(district_id: String, age: int = -1) -> String:
	"""Create a landlord NPC with Property Investor occupation."""
	# Generate age if not provided
	if age == -1:
		age = rng.randi_range(45, 70)
	
	# Generate gender (60% male, 40% female)
	var gender = "male" if rng.randf() < 0.6 else "female"
	
	# Generate tribe, names, religion using existing functions
	var tribe = _random_tribe()
	var first_name = _random_first_name(tribe, gender)
	var last_name = _random_last_name(tribe)
	
	# Generate NPC ID
	var landlord_id = "npc_%s" % Utils.generate_uuid()
	
	# Force education to undergraduate or postgraduate (70% postgraduate, 30% undergraduate)
	var education_level = "postgraduate" if rng.randf() < 0.7 else "undergraduate"
	
	# Create NPC data structure similar to _create_npc but with landlord-specific values
	var npc_data = {
		"id": landlord_id,
		"name": "%s %s" % [first_name, last_name],
		"definite": {
			"gender": gender,
			"age": age,
			"alive": true,
			"orientation": _generate_orientation()
		},
		"attributes": _generate_attributes(age),
		"appearance": _generate_appearance(gender, age, tribe),
		"identity": {
			"tribe": tribe,
			"spoken_languages": ["english", "pidgin"],
			"education": {"level": education_level, "institution": null},
			"religious_path": _random_religion(tribe),
			"occupation": "Property Investor",
			"family_id": null,  # Landlords are singles
			"district": district_id,  # Keep for backward compatibility
			"district_id": district_id  # Standardized field
		},
		"personality": _generate_personality(tribe),
		"political_ideology": _generate_political_ideology(),
		"skills": {},
		"resources": {
			"liquid_assets": [{"type": "bank_account", "amount": rng.randi_range(50000000, 200000000)}],
			"property": [],
			"access": [],
			"annual_income": rng.randi_range(20000000, 80000000)
		},
		"status": {"health": rng.randi_range(70, 100), "stress": rng.randi_range(10, 50), "reputation": rng.randi_range(30, 70)},
		"demographic_affinities": {"capitalist_class": 80}
	}
	
	# Generate skills for Property Investor occupation
	npc_data.skills = _generate_skills("Property Investor", age)
	
	# Override annual income with Property Investor salary if available
	var property_investor_salary = _generate_salary_for_occupation("Property Investor", age)
	if property_investor_salary > 0:
		npc_data.resources.annual_income = property_investor_salary
	
	# Create NPC in database
	DB.create_npc(npc_data)
	
	# Update stats
	stats.npcs = stats.get("npcs", 0) + 1
	
	return landlord_id

# Getters
func get_family_frames() -> Array:
	return family_frames

func get_singles_pool() -> Array:
	return singles_pool

