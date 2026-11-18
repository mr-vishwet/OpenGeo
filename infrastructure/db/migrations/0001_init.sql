-- OpenGeo initial schema.
--
-- PostGIS is the served authority (ADR-0003). The invariant this file enforces
-- that application code cannot: at most one active dataset version per region,
-- switched in a single transaction.

BEGIN;

CREATE SCHEMA IF NOT EXISTS opengeo;

-- ── data governance ─────────────────────────────────────────────────────────

CREATE TABLE opengeo.source (
    source_id                  text PRIMARY KEY,
    name                       text NOT NULL,
    provider                   text,
    license                    text NOT NULL,
    attribution                text NOT NULL,
    allowed_uses               text[] NOT NULL DEFAULT '{}',
    redistribution_conditions  text,
    url                        text,
    checked_at                 date NOT NULL
);

CREATE TABLE opengeo.import_run (
    run_id             text PRIMARY KEY,
    region             text NOT NULL,
    source_id          text NOT NULL REFERENCES opengeo.source (source_id),
    source_file        text NOT NULL,
    source_sha256      char(64) NOT NULL,
    source_timestamp   timestamptz,
    parser_version     text NOT NULL,
    transform_version  text NOT NULL,
    started_at         timestamptz NOT NULL,
    finished_at        timestamptz,
    status             text NOT NULL
                       CHECK (status IN ('staged', 'published', 'failed', 'rolled_back')),
    parsed_count       bigint NOT NULL DEFAULT 0 CHECK (parsed_count >= 0),
    accepted_count     bigint NOT NULL DEFAULT 0 CHECK (accepted_count >= 0),
    rejected_count     bigint NOT NULL DEFAULT 0 CHECK (rejected_count >= 0),
    quality            jsonb NOT NULL DEFAULT '{}'::jsonb
);

CREATE TABLE opengeo.dataset_version (
    dataset_version  text PRIMARY KEY,
    region           text NOT NULL,
    run_id           text NOT NULL REFERENCES opengeo.import_run (run_id),
    published_at     timestamptz NOT NULL DEFAULT now(),
    feature_count    bigint NOT NULL CHECK (feature_count >= 0),
    is_active        boolean NOT NULL DEFAULT false
);

-- One served version per region, enforced by the database rather than by a
-- convention in the application.
CREATE UNIQUE INDEX dataset_version_one_active_per_region
    ON opengeo.dataset_version (region)
    WHERE is_active;

-- ── canonical places ────────────────────────────────────────────────────────

CREATE TABLE opengeo.place (
    place_id         text PRIMARY KEY,
    dataset_version  text NOT NULL REFERENCES opengeo.dataset_version (dataset_version),
    category         text,
    names            jsonb NOT NULL DEFAULT '[]'::jsonb,
    address          jsonb NOT NULL DEFAULT '{}'::jsonb,
    properties       jsonb NOT NULL DEFAULT '{}'::jsonb,
    source_ids       jsonb NOT NULL DEFAULT '[]'::jsonb,
    completeness     jsonb NOT NULL DEFAULT '{}'::jsonb,
    geom             geometry(Geometry, 4326) NOT NULL,
    created_at       timestamptz NOT NULL DEFAULT now(),
    -- A malformed ring must never reach a query. The cost is paid at ingest.
    CONSTRAINT place_geom_valid CHECK (ST_IsValid(geom)),
    CONSTRAINT place_geom_not_empty CHECK (NOT ST_IsEmpty(geom))
);

CREATE INDEX place_geom_gix       ON opengeo.place USING GIST (geom);
CREATE INDEX place_dataset_idx    ON opengeo.place (dataset_version);
CREATE INDEX place_category_idx   ON opengeo.place (category);

-- ── regions and boundaries ──────────────────────────────────────────────────

CREATE TABLE opengeo.region (
    region_id        text PRIMARY KEY,
    name             text NOT NULL,
    level            text,
    dataset_version  text REFERENCES opengeo.dataset_version (dataset_version),
    geom             geometry(MultiPolygon, 4326) NOT NULL,
    CONSTRAINT region_geom_valid CHECK (ST_IsValid(geom))
);

CREATE INDEX region_geom_gix ON opengeo.region USING GIST (geom);

-- ── atomic publication ──────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION opengeo.publish_dataset_version(p_dataset_version text)
RETURNS void
LANGUAGE plpgsql
AS $$
DECLARE
    v_region text;
BEGIN
    SELECT region INTO v_region
    FROM opengeo.dataset_version
    WHERE dataset_version = p_dataset_version;

    IF v_region IS NULL THEN
        RAISE EXCEPTION 'unknown dataset version %', p_dataset_version;
    END IF;

    UPDATE opengeo.dataset_version
       SET is_active = false
     WHERE region = v_region
       AND is_active
       AND dataset_version <> p_dataset_version;

    UPDATE opengeo.dataset_version
       SET is_active = true
     WHERE dataset_version = p_dataset_version;
END;
$$;

COMMIT;
