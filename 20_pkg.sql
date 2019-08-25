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
    CREATE TYPE t_pkg_op AS ENUM ('create', 'build', 'drop', 'erase', 'done'); 
  END IF;
END$_$;

-- -----------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS pkg_log (
  id          INTEGER PRIMARY KEY
, code        TEXT NOT NULL
, schemas     name[] NOT NULL
, op          t_pkg_op
, version     DECIMAL NOT NULL DEFAULT 0
, log_name    TEXT
, user_name   TEXT
, ssh_client  TEXT
, usr         TEXT DEFAULT current_user
, ip          INET DEFAULT inet_client_addr()
, stamp       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
CREATE SEQUENCE IF NOT EXISTS pkg_id_seq;
ALTER TABLE pkg_log ALTER COLUMN id SET DEFAULT NEXTVAL('pkg_id_seq');
SELECT comment('t', 'pkg_log', 'Package operations history'
, 'id',         'Order number'
, 'code',       'Package code'
, 'schemas',    'List of schemes created by the package'
, 'op',         'Code for the last operation (create, build, drop, erase, done)'
, 'version',    'Package version'
, 'log_name',   '$LOGNAME from the users session in the OS'
, 'user_name',  '$USERNAME from the users session in the OS'
, 'ssh_client', '$SSH_CLIENT from the users session in the OS'
, 'usr',        'User name from database connection'
, 'ip',         'User IP from database connection'
, 'stamp',      'The timing of the change'
);

/* ------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS pkg (
  id          INTEGER NOT NULL UNIQUE
, code        TEXT PRIMARY KEY -- для REFERENCES
, schemas     name[]
, op          t_pkg_op
, version     DECIMAL NOT NULL DEFAULT 0
, log_name    TEXT
, user_name   TEXT
, ssh_client  TEXT
, usr         TEXT DEFAULT current_user
, ip          INET DEFAULT inet_client_addr()
, stamp       TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

/* ------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS pkg_required_by (
  code        name REFERENCES pkg
, required_by name DEFAULT current_schema() 
, version     DECIMAL NOT NULL DEFAULT 0
, CONSTRAINT pkg_required_by_pkey PRIMARY KEY (code, required_by)
);
