-- CashVision PostgreSQL initial schema
CREATE TABLE IF NOT EXISTS banknotes (
    id TEXT PRIMARY KEY,
    currency TEXT NOT NULL,
    denomination_value INTEGER NOT NULL,
    issue_year INTEGER NOT NULL,
    series TEXT NOT NULL,
    official_description TEXT,
    official_source_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS feature_flags (
    name TEXT PRIMARY KEY,
    value BOOLEAN NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS model_versions (
    name TEXT PRIMARY KEY,
    version TEXT NOT NULL,
    min_ios_version TEXT NOT NULL,
    download_url TEXT,
    checksum TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_banknotes_denomination
    ON banknotes(currency, denomination_value);

INSERT INTO feature_flags (name, value) VALUES
    ('counting_enabled', TRUE),
    ('serial_verification_available', FALSE),
    ('remote_model_enabled', FALSE)
ON CONFLICT (name) DO NOTHING;
