-- Database initialization script for Knotty DSL pattern storage
-- Creates tables for storing knitting patterns, symbols, and user data

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create schema for pattern data
CREATE SCHEMA IF NOT EXISTS patterns;
CREATE SCHEMA IF NOT EXISTS symbols;
CREATE SCHEMA IF NOT EXISTS users;

-- Users table
CREATE TABLE users.profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username VARCHAR(50) UNIQUE NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    preferences JSONB DEFAULT '{}'
);

-- Pattern definitions
CREATE TABLE patterns.definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    author_id UUID REFERENCES users.profiles(id),
    pattern_type VARCHAR(50) NOT NULL, -- 'cable', 'lace', 'colorwork', etc.
    difficulty_level INTEGER CHECK (difficulty_level BETWEEN 1 AND 5),
    gauge_stitches INTEGER,
    gauge_rows INTEGER,
    needle_size VARCHAR(20),
    yarn_weight VARCHAR(20),
    pattern_data JSONB NOT NULL, -- The actual pattern structure
    tags TEXT[],
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    version INTEGER DEFAULT 1
);

-- Pattern revisions for version control
CREATE TABLE patterns.revisions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pattern_id UUID REFERENCES patterns.definitions(id) ON DELETE CASCADE,
    version INTEGER NOT NULL,
    pattern_data JSONB NOT NULL,
    changelog TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_by UUID REFERENCES users.profiles(id),
    UNIQUE(pattern_id, version)
);

-- Symbol definitions
CREATE TABLE symbols.definitions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    symbol_code VARCHAR(50) UNIQUE NOT NULL,
    symbol_name VARCHAR(255) NOT NULL,
    description TEXT,
    category VARCHAR(100), -- 'basic', 'cable', 'lace', 'colorwork'
    unicode_char VARCHAR(10),
    svg_data TEXT,
    font_glyph VARCHAR(10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_standard BOOLEAN DEFAULT false
);

-- Pattern collections
CREATE TABLE patterns.collections (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    owner_id UUID REFERENCES users.profiles(id),
    is_public BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Many-to-many relationship between patterns and collections
CREATE TABLE patterns.collection_patterns (
    collection_id UUID REFERENCES patterns.collections(id) ON DELETE CASCADE,
    pattern_id UUID REFERENCES patterns.definitions(id) ON DELETE CASCADE,
    added_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    PRIMARY KEY (collection_id, pattern_id)
);

-- Pattern sharing and permissions
CREATE TABLE patterns.shares (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pattern_id UUID REFERENCES patterns.definitions(id) ON DELETE CASCADE,
    shared_with UUID REFERENCES users.profiles(id) ON DELETE CASCADE,
    permission_level VARCHAR(20) DEFAULT 'read', -- 'read', 'write', 'admin'
    shared_by UUID REFERENCES users.profiles(id),
    shared_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    expires_at TIMESTAMP WITH TIME ZONE,
    UNIQUE(pattern_id, shared_with)
);

-- Pattern usage analytics
CREATE TABLE patterns.usage_stats (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    pattern_id UUID REFERENCES patterns.definitions(id) ON DELETE CASCADE,
    user_id UUID REFERENCES users.profiles(id),
    action VARCHAR(50), -- 'view', 'download', 'generate_chart', 'fork'
    session_id VARCHAR(255),
    ip_address INET,
    user_agent TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for performance
CREATE INDEX idx_patterns_author ON patterns.definitions(author_id);
CREATE INDEX idx_patterns_type ON patterns.definitions(pattern_type);
CREATE INDEX idx_patterns_public ON patterns.definitions(is_public);
CREATE INDEX idx_patterns_tags ON patterns.definitions USING gin(tags);
CREATE INDEX idx_patterns_created ON patterns.definitions(created_at);

CREATE INDEX idx_revisions_pattern ON patterns.revisions(pattern_id, version);
CREATE INDEX idx_symbols_code ON symbols.definitions(symbol_code);
CREATE INDEX idx_symbols_category ON symbols.definitions(category);
CREATE INDEX idx_collections_owner ON patterns.collections(owner_id);
CREATE INDEX idx_usage_pattern ON patterns.usage_stats(pattern_id, created_at);
CREATE INDEX idx_usage_user ON patterns.usage_stats(user_id, created_at);

-- Create updated_at trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Add updated_at triggers
CREATE TRIGGER update_users_profiles_updated_at
    BEFORE UPDATE ON users.profiles
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_patterns_definitions_updated_at
    BEFORE UPDATE ON patterns.definitions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_patterns_collections_updated_at
    BEFORE UPDATE ON patterns.collections
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert default symbols
INSERT INTO symbols.definitions (symbol_code, symbol_name, description, category, unicode_char, is_standard) VALUES
('k', 'Knit', 'Basic knit stitch', 'basic', '·', true),
('p', 'Purl', 'Basic purl stitch', 'basic', '−', true),
('yo', 'Yarn Over', 'Yarn over increase', 'basic', '○', true),
('k2tog', 'Knit 2 Together', 'Right-leaning decrease', 'basic', '⧸', true),
('ssk', 'Slip Slip Knit', 'Left-leaning decrease', 'basic', '⧹', true),
('c4f', 'Cable 4 Front', '4-stitch cable crossing to front', 'cable', '⟋', true),
('c4b', 'Cable 4 Back', '4-stitch cable crossing to back', 'cable', '⟍', true),
('no-stitch', 'No Stitch', 'Placeholder for missing stitches', 'basic', ' ', true);

-- Create a sample user for development
INSERT INTO users.profiles (username, email, preferences) VALUES
('knotty-dev', 'dev@knotty-dsl.local', '{"theme": "dark", "default_gauge": {"stitches": 20, "rows": 28}}');

-- Create a sample pattern
INSERT INTO patterns.definitions (
    name,
    description,
    author_id,
    pattern_type,
    difficulty_level,
    gauge_stitches,
    gauge_rows,
    needle_size,
    yarn_weight,
    pattern_data,
    tags,
    is_public
) VALUES (
    'Basic Stockinette',
    'Simple stockinette stitch pattern for beginners',
    (SELECT id FROM users.profiles WHERE username = 'knotty-dev'),
    'basic',
    1,
    20,
    28,
    'US 8 (5.0mm)',
    'worsted',
    '{"rows": [{"stitches": ["k", "k", "k", "k", "k"]}, {"stitches": ["p", "p", "p", "p", "p"]}], "repeat": 2}',
    ARRAY['beginner', 'stockinette', 'basic'],
    true
);

-- Grant appropriate permissions
GRANT USAGE ON SCHEMA patterns TO knotty;
GRANT USAGE ON SCHEMA symbols TO knotty;
GRANT USAGE ON SCHEMA users TO knotty;

GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA patterns TO knotty;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA symbols TO knotty;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA users TO knotty;

GRANT USAGE ON ALL SEQUENCES IN SCHEMA patterns TO knotty;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA symbols TO knotty;
GRANT USAGE ON ALL SEQUENCES IN SCHEMA users TO knotty;