extends RefCounted
## NPC Display - Renders NPC detail panel

const DetailPanel = preload("res://scripts/chronicles/ui/detail_panel.gd")

static func display_npc_details(npc: Dictionary, detail_panel: Control, detail_content: Control) -> void:
	detail_panel.visible = true
	DetailPanel.clear(detail_content)
	
	DetailPanel.add_header("NPC Details: %s" % npc.get("name", "Unknown"), detail_content)
	DetailPanel.add_section("Basic Info", {
		"ID": npc.get("id", ""),
		"Name": npc.get("name", ""),
		"Age": npc.get("definite", {}).get("age", "?"),
		"Gender": npc.get("definite", {}).get("gender", "?"),
		"Alive": "Yes" if npc.get("definite", {}).get("alive", true) else "No"
	}, detail_content)
	
	var identity = npc.get("identity", {})
	if not identity.is_empty():
		DetailPanel.add_section("Identity", identity, detail_content)
	
	var personality = npc.get("personality", {})
	if not personality.is_empty():
		DetailPanel.add_section("Personality", personality, detail_content)
	
	var status = npc.get("status", {})
	if not status.is_empty():
		DetailPanel.add_section("Status", status, detail_content)
	
	# Get relationships
	var relationships = DB.get_relationships_for_npc(npc.get("id", ""))
	if relationships.size() > 0:
		DetailPanel.add_text("\n[RELATIONSHIPS]", detail_content, 16, Color(0.9, 0.85, 0.6, 1))
		for rel in relationships:
			var other_id = rel.get("npc_b_id", "")
			var other_npc = DB.get_npc(other_id)
			var rel_type = rel.get("relationship_type", "unknown")
			DetailPanel.add_text("  → %s: %s" % [rel_type.capitalize(), other_npc.get("name", "Unknown")], detail_content, 14, Color(0.9, 0.9, 0.9, 1))

