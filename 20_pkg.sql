/*
    Copyright (c) 2010-2018 Tender.Pro team <it@tender.pro>
    Use of this source code is governed by a MIT-style
    license that can be found in the LICENSE file.

    Таблицы для компилляции и установки пакетов
*/
-- -----------------------------------------------------------------------------
DO $_$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 't_pkg_op') THEN
    CREATE TYPE t_pkg_op AS ENUM ('init', 'drop', 'erase');
  END IF;
END$_$;

-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pkg_log (
  id          INTEGER PRIMARY KEY
, code        TEXT NOT NULL
, op          t_pkg_op NOT NULL
, version     TEXT NOT NULL
, repo        TEXT NOT NULL
, created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
, updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE SEQUENCE IF NOT EXISTS pkg_id_seq;
ALTER TABLE pkg_log ALTER COLUMN id SET DEFAULT NEXTVAL('pkg_id_seq');
SELECT comment('t', 'pkg_log', 'Package operations history'
, 'id',         'Operation ID'
, 'code',       'Package code'
, 'op',         'Operation code'
, 'version',    'Package version'
, 'repo',       'Package repo'
, 'created_at', 'Operation start timestamp'
, 'updated_at', 'Operation end timestamp'
);

/* ------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS pkg (
  id          INTEGER NOT NULL UNIQUE
, code        TEXT PRIMARY KEY -- для REFERENCES
, op          t_pkg_op
, version     TEXT NOT NULL
, repo        TEXT NOT NULL
, created_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
, updated_at  TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
SELECT comment('t', 'pkg', 'Actual packages'
, 'id',         'Operation ID'
, 'code',       'Package code'
, 'op',         'Operation code'
, 'version',    'Package version'
, 'repo',       'Package repo'
, 'created_at', 'Operation start timestamp'
, 'updated_at', 'Operation end timestamp'
);

/* ------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS pkg_required_by (
  code        name REFERENCES pkg
, required_by name DEFAULT current_schema() 
, version     TEXT
, CONSTRAINT pkg_required_by_pkey PRIMARY KEY (code, required_by)
);
