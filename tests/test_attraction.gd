extends Node
## Test attraction calculation

func _ready():
	print("\n============================================================")
	print("TESTING ATTRACTION CALCULATION")
	print("============================================================\n")
	
	# Initialize database (will use existing if already exists)
	if not DB.is_initialized:
		if not DB.initialize():
			push_error("Failed to initialize database")
			return
	
	# Get first 5 NPCs
	var npcs = DB.fetch_query("SELECT id, name, definite, attributes FROM npcs LIMIT 5;")
	
	if npcs.is_empty():
		print("No NPCs found in database")
		return
	
	print("Found %d NPCs\n" % npcs.size())
	
	# Display NPC info
	for npc in npcs:
		var definite = JSON.parse_string(npc["definite"])
		var attributes = JSON.parse_string(npc["attributes"])
		print("📋 %s (%s, age %d, orientation: %d)" % [
			npc["name"],
			definite["gender"],
			definite["age"],
			definite["orientation"]
		])
		print("   Stats: Beauty=%d, Charisma=%d, Strength=%d, Intellect=%d" % [
			attributes["beauty"],
			attributes["charisma"],
			attributes["strength"],
			attributes["intellect"]
		])
	
	print("\n" + "=".repeat(60))
	print("ATTRACTION MATRIX (Source → Target)")
	print("=".repeat(60) + "\n")
	
	# Test attraction between all pairs
	for source in npcs:
		var source_definite = JSON.parse_string(source["definite"])
		print("\n%s (%s, orientation: %d) is attracted to:" % [
			source["name"],
			source_definite["gender"],
			source_definite["orientation"]
		])
		
		for target in npcs:
			if source["id"] == target["id"]:
				continue
			
			var target_definite = JSON.parse_string(target["definite"])
			var attraction = DB.calculate_attraction(source["id"], target["id"])
			
			var emoji = ""
			if attraction > 70:
				emoji = "💖"
			elif attraction > 40:
				emoji = "💛"
			elif attraction > 0:
				emoji = "🤝"
			else:
				emoji = "🚫"
			
			print("  %s → %s (%s): %d %s" % [
				source["name"],
				target["name"],
				target_definite["gender"],
				attraction,
				emoji
			])
	
	print("\n" + "=".repeat(60))
	print("TEST COMPLETE")
	print("=".repeat(60))
	
	get_tree().quit()

