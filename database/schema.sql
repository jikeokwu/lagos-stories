-- Lagos Stories Database Schema
-- SQLite Database for AI-First Simulation Game
-- Version: 1.0

-- Enable Foreign Key Support
PRAGMA foreign_keys = ON;

-- ============================================================
-- WORLD STATE TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS world_state (
    id INTEGER PRIMARY KEY CHECK (id = 1), -- Single row table
    seed TEXT NOT NULL,
    tick INTEGER NOT NULL DEFAULT 0,
    date TEXT NOT NULL, -- ISO format: YYYY-MM-DD
    time TEXT NOT NULL, -- HH:MM format
    global_signals TEXT NOT NULL, -- JSON: {economy, stability, corruption, public_order}
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);

-- ============================================================
-- DISTRICTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS districts (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    prosperity INTEGER NOT NULL DEFAULT 50 CHECK (prosperity >= 0 AND prosperity <= 100),
    safety INTEGER NOT NULL DEFAULT 50 CHECK (safety >= 0 AND safety <= 100),
    infrastructure INTEGER NOT NULL DEFAULT 50 CHECK (infrastructure >= 0 AND infrastructure <= 100),
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
);

-- ============================================================
-- LOCATIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS locations (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- residential, commercial, public, government, etc.
    district_id TEXT NOT NULL,
    building_id TEXT, -- Optional parent building
    parent_location_id TEXT, -- Optional parent location (e.g., room in building)
    
    -- Address
    address_street TEXT,
    address_building TEXT,
    
    -- Physical Properties (JSON)
    physical_properties TEXT NOT NULL, -- {size, capacity, condition, security_level}
    
    -- Access Control (JSON)
    access TEXT NOT NULL, -- {control_type, operating_hours, owner_id}
    
    -- Reputation (JSON)
    reputation TEXT NOT NULL, -- {safety, prestige, activity_level}
    
    -- Features (JSON)
    features TEXT NOT NULL, -- {utilities: {power, water, internet}, amenities: []}
    
    -- Current State
    current_occupants TEXT NOT NULL DEFAULT '[]', -- JSON array of NPC IDs
    
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    
    FOREIGN KEY (district_id) REFERENCES districts(id) ON DELETE CASCADE,
    FOREIGN KEY (parent_location_id) REFERENCES locations(id) ON DELETE CASCADE
);

-- ============================================================
-- ORGANIZATIONS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS organizations (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- business, government, religious, gang, community, etc.
    founded INTEGER NOT NULL, -- Year founded
    location_id TEXT, -- Primary location
    legal_status TEXT NOT NULL, -- registered, informal, illegal
    
    -- Core Values
    pillars TEXT NOT NULL, -- JSON array of strings
    
    -- Reputation (JSON)
    reputation TEXT NOT NULL, -- {trustworthiness, innovation, morality, conservatism, influence}
    
    -- Resources (JSON)
    resources TEXT NOT NULL, -- {liquid_assets: [], property: []}
    
    -- Computed values (cached, updated at resolution)
    computed_values TEXT, -- JSON: {ambition, compassion, economic_conservatism, ...}
    
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    
    FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE SET NULL
);

-- ============================================================
-- NPCS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS npcs (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    
    -- Definite Properties (JSON)
    definite TEXT NOT NULL, -- {gender, age, alive, orientation: -100 to 100 where -100=purely same-sex, 0=bisexual, 100=purely heterosexual}
    
    -- RPG Attributes (JSON) - Used for attraction calculations and interactions
    attributes TEXT NOT NULL, -- {beauty, strength, intellect, charisma, constitution, agility}
    
    -- Appearance (JSON) - Physical appearance details
    appearance TEXT NOT NULL, -- {height, build, skin_tone, facial_features, hair, facial_hair, eyesight, marks, age_effects}
    
    -- Identity (JSON)
    identity TEXT NOT NULL, -- {tribe, spoken_languages, education: [none/primary/secondary/undergraduate/postgraduate], religious_path, occupation, family_id, district}
    
    -- Personality Sliders (JSON)
    personality TEXT NOT NULL, -- {ambition, compassion, volatility, openness, gender_bias, ethnic_prejudice, class_bias, religious_intolerance, social_conformity}
    
    -- Political Ideology (JSON)
    political_ideology TEXT NOT NULL, -- {social_conservatism, economic_conservatism, authoritarianism, nationalism, religious_devotion, environmentalism}
    
    -- Skills (JSON)
    skills TEXT NOT NULL, -- Hierarchical: {tech: {programming, hardware, ...}, medical: {...}, ...}
    
    -- Resources (JSON)
    resources TEXT NOT NULL, -- {liquid_assets: [], property: [], access: [], annual_income: INTEGER}
    
    -- Status Sliders (JSON)
    status TEXT NOT NULL, -- {health, stress, reputation}
    
    -- Demographic Affinities (JSON)
    demographic_affinities TEXT NOT NULL, -- {religious_community, capitalist_class, working_class, ...}
    
    -- Current Location
    current_location_id TEXT,
    
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    
    FOREIGN KEY (current_location_id) REFERENCES locations(id) ON DELETE SET NULL
);

-- ============================================================
-- RELATIONSHIPS TABLE (Directional)
-- ============================================================
-- Relationship Types:
--   Family: sibling, parent, child, spouse, aunt, uncle, cousin, grandparent, grandchild
--   Social: friend, acquaintance, rival, neighbor
--   Work: colleague, mentor, boss, subordinate
--   Authority: teacher, elder, leader (power dynamic relationships)
--   Romantic: lover, ex_lover, affair, crush
--   Conflict: threat, enemy
CREATE TABLE IF NOT EXISTS relationships (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source_npc_id TEXT NOT NULL, -- NPC who has this feeling
    target_npc_id TEXT NOT NULL, -- NPC they feel this way about
    
    type TEXT NOT NULL, -- See relationship types above
    
    -- Relationship Sliders (all -100 to +100)
    affection INTEGER NOT NULL DEFAULT 0 CHECK (affection >= -100 AND affection <= 100),
    trust INTEGER NOT NULL DEFAULT 0 CHECK (trust >= -100 AND trust <= 100),
    attraction INTEGER NOT NULL DEFAULT 0 CHECK (attraction >= -100 AND attraction <= 100), -- CALCULATED: based on orientation, gender, attributes, status
    respect INTEGER NOT NULL DEFAULT 0 CHECK (respect >= -100 AND respect <= 100),
    
    -- Relationship History
    formed_date TEXT, -- ISO date (YYYY-MM-DD) or game date when relationship was formed
    
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    
    FOREIGN KEY (source_npc_id) REFERENCES npcs(id) ON DELETE CASCADE,
    FOREIGN KEY (target_npc_id) REFERENCES npcs(id) ON DELETE CASCADE,
    
    UNIQUE (source_npc_id, target_npc_id) -- Each pair can only have one relationship per direction
);

-- ============================================================
-- ORGANIZATION MEMBERSHIPS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS organization_memberships (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    npc_id TEXT NOT NULL,
    org_id TEXT NOT NULL,
    
    role TEXT NOT NULL, -- CEO, employee, member, volunteer, etc.
    weight INTEGER NOT NULL DEFAULT 1, -- Influence weight for computed org values
    tenure_years INTEGER NOT NULL DEFAULT 0,
    
    -- Affiliation Sliders
    loyalty INTEGER NOT NULL DEFAULT 50 CHECK (loyalty >= 0 AND loyalty <= 100),
    investment INTEGER NOT NULL DEFAULT 50 CHECK (investment >= 0 AND investment <= 100),
    alignment INTEGER NOT NULL DEFAULT 50 CHECK (alignment >= 0 AND alignment <= 100),
    
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    
    FOREIGN KEY (npc_id) REFERENCES npcs(id) ON DELETE CASCADE,
    FOREIGN KEY (org_id) REFERENCES organizations(id) ON DELETE CASCADE,
    
    UNIQUE (npc_id, org_id)
);

-- ============================================================
-- ITEMS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS items (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    type TEXT NOT NULL, -- document, weapon, currency, vehicle, consumable, etc.
    
    owner_id TEXT, -- Current owner NPC
    location_type TEXT NOT NULL, -- npc_inventory, location_storage, destroyed
    location_entity_id TEXT, -- ID of the NPC or Location
    
    -- Physical Properties (JSON)
    physical TEXT NOT NULL, -- {condition, size, transferable}
    
    -- Value (JSON)
    value TEXT NOT NULL, -- {monetary, sentimental, legal_status}
    
    -- Metadata (JSON)
    metadata TEXT NOT NULL, -- {created_date, created_by, created_in_event}
    
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    
    FOREIGN KEY (owner_id) REFERENCES npcs(id) ON DELETE SET NULL
);

-- ============================================================
-- EVENTS TABLE (Global Event Log)
-- ============================================================
CREATE TABLE IF NOT EXISTS events (
    id TEXT PRIMARY KEY,
    type TEXT NOT NULL, -- crime, business, social, political, etc.
    subtype TEXT, -- theft, meeting, wedding, election, etc.
    
    timestamp INTEGER NOT NULL, -- Unix timestamp
    date TEXT NOT NULL, -- YYYY-MM-DD
    time TEXT NOT NULL, -- HH:MM
    duration_minutes INTEGER NOT NULL DEFAULT 0,
    
    location_id TEXT,
    district_id TEXT,
    
    -- Summary
    summary TEXT NOT NULL,
    
    -- Details (JSON) - Event-specific data
    details TEXT NOT NULL,
    
    -- Impact (JSON)
    impact TEXT NOT NULL, -- {severity, public_knowledge, emotional_weight}
    
    -- Consequences (JSON)
    consequences TEXT NOT NULL, -- {relationship_changes, reputation_changes, city_situation_changes}
    
    -- Ripple Effect
    ripple_depth INTEGER NOT NULL DEFAULT 0,
    affected_nodes TEXT NOT NULL DEFAULT '[]', -- JSON array of entity IDs
    
    resolved BOOLEAN NOT NULL DEFAULT 0,
    
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    
    FOREIGN KEY (location_id) REFERENCES locations(id) ON DELETE SET NULL,
    FOREIGN KEY (district_id) REFERENCES districts(id) ON DELETE SET NULL
);

-- ============================================================
-- EVENT PARTICIPANTS TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS event_participants (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_id TEXT NOT NULL,
    entity_id TEXT NOT NULL, -- NPC or Organization ID
    entity_type TEXT NOT NULL, -- npc, organization
    role TEXT NOT NULL, -- primary_actor, affected_entity, witness
    
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
);

-- ============================================================
-- NPC MEMORIES TABLE
-- ============================================================
CREATE TABLE IF NOT EXISTS npc_memories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    npc_id TEXT NOT NULL,
    event_id TEXT NOT NULL,
    
    personal_summary TEXT NOT NULL, -- What the NPC remembers
    knowledge_level TEXT NOT NULL, -- direct_witness, participant, secondhand, rumor
    emotional_impact INTEGER NOT NULL CHECK (emotional_impact >= 0 AND emotional_impact <= 100),
    belief_accuracy INTEGER NOT NULL CHECK (belief_accuracy >= 0 AND belief_accuracy <= 100),
    
    timestamp INTEGER NOT NULL,
    date TEXT NOT NULL,
    
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    
    FOREIGN KEY (npc_id) REFERENCES npcs(id) ON DELETE CASCADE,
    FOREIGN KEY (event_id) REFERENCES events(id) ON DELETE CASCADE
);

-- ============================================================
-- INSTANCES TABLE (Player Sessions)
-- ============================================================
CREATE TABLE IF NOT EXISTS instances (
    id TEXT PRIMARY KEY,
    protagonist_id TEXT NOT NULL,
    
    framing TEXT NOT NULL, -- JSON: {scenario_summary, stakes, relevant_locations, cast}
    agency_assignments TEXT NOT NULL, -- JSON: {npc_id: agency_level}
    antagonist_id TEXT,
    threat_level INTEGER,
    
    start_timestamp INTEGER NOT NULL,
    end_timestamp INTEGER,
    duration_minutes INTEGER,
    
    status TEXT NOT NULL DEFAULT 'active', -- active, completed, abandoned
    
    created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    updated_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now')),
    
    FOREIGN KEY (protagonist_id) REFERENCES npcs(id) ON DELETE CASCADE,
    FOREIGN KEY (antagonist_id) REFERENCES npcs(id) ON DELETE SET NULL
);

-- ============================================================
-- INDEXES FOR PERFORMANCE
-- ============================================================

-- NPCs
CREATE INDEX IF NOT EXISTS idx_npcs_location ON npcs(current_location_id);
CREATE INDEX IF NOT EXISTS idx_npcs_alive ON npcs((json_extract(definite, '$.alive')));

-- Relationships
CREATE INDEX IF NOT EXISTS idx_relationships_source ON relationships(source_npc_id);
CREATE INDEX IF NOT EXISTS idx_relationships_target ON relationships(target_npc_id);
CREATE INDEX IF NOT EXISTS idx_relationships_type ON relationships(type);

-- Organization Memberships
CREATE INDEX IF NOT EXISTS idx_org_memberships_npc ON organization_memberships(npc_id);
CREATE INDEX IF NOT EXISTS idx_org_memberships_org ON organization_memberships(org_id);

-- Locations
CREATE INDEX IF NOT EXISTS idx_locations_district ON locations(district_id);
CREATE INDEX IF NOT EXISTS idx_locations_type ON locations(type);

-- Events
CREATE INDEX IF NOT EXISTS idx_events_timestamp ON events(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(type);
CREATE INDEX IF NOT EXISTS idx_events_location ON events(location_id);
CREATE INDEX IF NOT EXISTS idx_events_district ON events(district_id);
CREATE INDEX IF NOT EXISTS idx_events_date ON events(date);

-- Event Participants
CREATE INDEX IF NOT EXISTS idx_event_participants_event ON event_participants(event_id);
CREATE INDEX IF NOT EXISTS idx_event_participants_entity ON event_participants(entity_id);

-- NPC Memories
CREATE INDEX IF NOT EXISTS idx_npc_memories_npc ON npc_memories(npc_id);
CREATE INDEX IF NOT EXISTS idx_npc_memories_event ON npc_memories(event_id);
CREATE INDEX IF NOT EXISTS idx_npc_memories_timestamp ON npc_memories(timestamp DESC);

-- Items
CREATE INDEX IF NOT EXISTS idx_items_owner ON items(owner_id);
CREATE INDEX IF NOT EXISTS idx_items_type ON items(type);
CREATE INDEX IF NOT EXISTS idx_items_location ON items(location_entity_id);

-- Instances
CREATE INDEX IF NOT EXISTS idx_instances_protagonist ON instances(protagonist_id);
CREATE INDEX IF NOT EXISTS idx_instances_status ON instances(status);
CREATE INDEX IF NOT EXISTS idx_instances_timestamp ON instances(start_timestamp DESC);

-- ============================================================
-- TRIGGERS FOR UPDATED_AT
-- ============================================================

CREATE TRIGGER IF NOT EXISTS update_world_state_timestamp 
AFTER UPDATE ON world_state 
BEGIN 
    UPDATE world_state SET updated_at = strftime('%s', 'now') WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_districts_timestamp 
AFTER UPDATE ON districts 
BEGIN 
    UPDATE districts SET updated_at = strftime('%s', 'now') WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_locations_timestamp 
AFTER UPDATE ON locations 
BEGIN 
    UPDATE locations SET updated_at = strftime('%s', 'now') WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_organizations_timestamp 
AFTER UPDATE ON organizations 
BEGIN 
    UPDATE organizations SET updated_at = strftime('%s', 'now') WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_npcs_timestamp 
AFTER UPDATE ON npcs 
BEGIN 
    UPDATE npcs SET updated_at = strftime('%s', 'now') WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_relationships_timestamp 
AFTER UPDATE ON relationships 
BEGIN 
    UPDATE relationships SET updated_at = strftime('%s', 'now') WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_org_memberships_timestamp 
AFTER UPDATE ON organization_memberships 
BEGIN 
    UPDATE organization_memberships SET updated_at = strftime('%s', 'now') WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_items_timestamp 
AFTER UPDATE ON items 
BEGIN 
    UPDATE items SET updated_at = strftime('%s', 'now') WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_events_timestamp 
AFTER UPDATE ON events 
BEGIN 
    UPDATE events SET updated_at = strftime('%s', 'now') WHERE id = NEW.id;
END;

CREATE TRIGGER IF NOT EXISTS update_instances_timestamp 
AFTER UPDATE ON instances 
BEGIN 
    UPDATE instances SET updated_at = strftime('%s', 'now') WHERE id = NEW.id;
END;

