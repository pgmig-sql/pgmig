/*
    Copyright (c) 2010-2018 Tender.Pro team <it@tender.pro>
    Use of this source code is governed by a MIT-style
    license that can be found in the LICENSE file.

    Компиляция и установка пакетов
*/

-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pkg(a_code TEXT) RETURNS SETOF pkg STABLE LANGUAGE 'sql' AS
$_$
  -- a_code:  пакет
  SELECT * FROM pgmig.pkg WHERE code = $1;
$_$;

-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pkg_references(
  a_is_on  BOOL
, a_pkg    name
) RETURNS SETOF TEXT VOLATILE LANGUAGE 'plpgsql' AS
$_$
  -- a_is_on:  флаг активности
  -- a_pkg:    пакет
  DECLARE
    r              RECORD;
    v_sql          TEXT;
    v_self_default TEXT;
  BEGIN
    -- defaults
    FOR r IN SELECT * 
      FROM pgmig.pkg_default_protected
      WHERE pkg = a_pkg
        AND is_active = NOT a_is_on
    LOOP
      v_sql := CASE WHEN a_is_on THEN
        format('ALTER TABLE wsd.%s ALTER COLUMN %s SET DEFAULT %s'
          , quote_ident(r.wsd_rel) 
          , quote_ident(r.wsd_col) 
          , r.func
          )
      ELSE       
        format('ALTER TABLE wsd.%s ALTER COLUMN %s DROP DEFAULT'
        , quote_ident(r.wsd_rel) 
        , quote_ident(r.wsd_col) 
        )
      END;
      IF r.wsd_rel = 'pkg_default_protected' THEN
        v_self_default := v_sql; -- мы внутри цикла по этой же таблице
      ELSE
        EXECUTE v_sql;
      END IF;
      RETURN NEXT v_sql;
    END LOOP;
    IF v_self_default IS NOT NULL THEN
      EXECUTE v_self_default;
    END IF;
    UPDATE pgmig.pkg_default_protected SET is_active = a_is_on
      WHERE pkg = a_pkg
        AND is_active = NOT a_is_on
    ;
    
    -- fkeys
    
        -- Перед удалением пакета - удаление всех присоединенных пакетом зарегистрированных FK
        -- rel in (select rel from wsd.pkg_fkey_required_by where required_by = a_pkg
        -- После создания пакета - создание всех еще несуществующих зарегистрированных FK присоединенных пакетом таблиц 
      --  NOT is_active AND rel not in (select rel from wsd.pkg_fkey_required_by where required_by not in (select code from ws.pkg)
    
    v_self_default := NULL;
    FOR r IN SELECT * 
      FROM pgmig.pkg_fkey_protected
      WHERE is_active = NOT a_is_on
        AND CASE WHEN a_is_on THEN
          rel NOT IN (SELECT rel FROM pgmig.pkg_fkey_required_by WHERE required_by NOT IN (SELECT code FROM pgmig.pkg))
            AND EXISTS (SELECT 1 FROM pgmig.pkg WHERE code = pkg) and EXISTS (SELECT 1 FROM pgmig.pkg where code = pkg_fkey_protected.pkg)
          ELSE
          pkg = a_pkg
          OR rel IN (SELECT rel FROM pgmig.pkg_fkey_required_by WHERE required_by = a_pkg)
        END
    LOOP
      v_sql := CASE WHEN a_is_on THEN
        format('ALTER TABLE wsd.%s ADD CONSTRAINT %s FOREIGN KEY (%s) REFERENCES %s'
          , quote_ident(r.wsd_rel)
          , r.wsd_rel || '_' || replace(regexp_replace(r.wsd_col, E'\\s','','g'), ',', '_') || '_fkey'
          , r.wsd_col -- может быть список колонок через запятую 
          , r.rel
          )
      ELSE       
        format('ALTER TABLE wsd.%s DROP CONSTRAINT %s'
          , quote_ident(r.wsd_rel)
          , r.wsd_rel || '_' || replace(regexp_replace(r.wsd_col, E'\\s','','g'), ',', '_') || '_fkey'
        )
      END;
      IF r.wsd_rel = 'pkg_fkey_protected' THEN
        v_self_default := v_sql; -- мы внутри цикла по этой же таблице
      ELSE
        EXECUTE v_sql;
      END IF;
      RETURN NEXT v_sql;
    END LOOP;
    IF v_self_default IS NOT NULL THEN
      EXECUTE v_self_default;
    END IF;
    UPDATE pgmig.pkg_fkey_protected SET is_active = a_is_on
      WHERE is_active = NOT a_is_on
        AND CASE WHEN a_is_on THEN
          rel NOT IN (SELECT rel FROM pgmig.pkg_fkey_required_by WHERE required_by NOT IN (SELECT code FROM pgmig.pkg))
            AND EXISTS (SELECT 1 FROM pgmig.pkg WHERE code = pkg) and EXISTS (SELECT 1 FROM pgmig.pkg where code = pkg_fkey_protected.pkg)
          ELSE
          (pkg = a_pkg)
          OR rel IN (SELECT rel FROM pgmig.pkg_fkey_required_by WHERE required_by = a_pkg)
        END
    ;
    RETURN;
  END;
$_$;

-- ----------------------------------------------------------------------------
/*
  Подготовка к выполнению операции с пакетом

  1. Проверить наличие (для create) или отсутствие (для build, drop, erase) пакета.
    При успехе: вернуть a_blank (если задан) или ошибку (иначе)
  2. Для drop, erase - вернуть ошибку, если есть зависимости от пакета (pgmig.pkg_required_by) и
    удалить зависимости от пакета
  3. Зарегистрировать операцию в pgmig.pkg и pgmig.pkg_log
*/
CREATE OR REPLACE FUNCTION pkg_op_before(
  a_op      pgmig.t_pkg_op
, a_code    name
, a_version TEXT
, a_repo    TEXT
) RETURNS VOID VOLATILE LANGUAGE 'plpgsql' AS
$_$
  DECLARE
    r_pkg          pgmig.pkg%ROWTYPE;
    r              RECORD;
    v_sql          TEXT;
    v_self_default TEXT;
    v_pkgs         TEXT;
  BEGIN
    SELECT INTO r_pkg * FROM pgmig.pkg(a_code);
    IF NOT FOUND THEN
      -- pkg does not exists
      IF a_op <> 'init' THEN
          RAISE EXCEPTION 'Package % does not exists, only init is possible', a_code;
      END IF;
      INSERT INTO pgmig.pkg (id, code, version, repo, op) VALUES
        (NEXTVAL('pgmig.pkg_id_seq'), a_code, a_version, a_repo, a_op)
        RETURNING * INTO r_pkg
      ;
      INSERT INTO pgmig.pkg_log VALUES (r_pkg.*);
      IF NOT pgmig.schema_exists(a_code) THEN
        EXECUTE format('CREATE SCHEMA IF NOT EXISTS %1$I', a_code);
      END IF;
      PERFORM pgmig.search_path_set(a_code);
      RETURN;
    END IF;

    -- pkg already exists, update on init
    IF a_op = 'init' THEN
      UPDATE pgmig.pkg SET
        id         = NEXTVAL('pgmig.pkg_id_seq') -- runs after rule
      , version    = a_version
      , repo       = a_repo
      , updated_at = now()
      , op         = a_op
      WHERE code = a_code
        RETURNING * INTO r_pkg
      ;
      INSERT INTO pgmig.pkg_log VALUES (r_pkg.*);
      PERFORM pgmig.search_path_set(a_code);
    ELSIF a_op IN ('drop', 'erase') THEN
      IF a_code = 'pgmig' THEN
        SELECT INTO v_pkgs
          array_to_string(array_agg(code::TEXT),', ')
          FROM pgmig.pkg
          WHERE code <> a_code
        ;
      ELSE
        SELECT INTO v_pkgs
          array_to_string(array_agg(required_by::TEXT),', ')
          FROM pgmig.pkg_required_by
          WHERE code = a_code
        ;
      END IF;
      IF v_pkgs IS NOT NULL THEN
        RAISE EXCEPTION 'Package % is required by others (%)', a_code, v_pkgs;
      END IF;
      PERFORM pgmig.pkg_references(FALSE, a_code);
    END IF;
  END;
$_$;

-- ----------------------------------------------------------------------------
/*
  Завершение выполнения операции с пакетом

  1. init pgmig - Зарегистрировать операцию в pgmig.pkg и pgmig.pkg_log
  2. init !pgmig - активировать зависимости
  3. erase - удалить зависимости
*/
CREATE OR REPLACE FUNCTION pkg_op_after(
  a_op         pgmig.t_pkg_op
, a_code       name
, a_version TEXT -- used only after pgmig init
, a_repo    TEXT -- used only after pgmig init
) RETURNS VOID VOLATILE LANGUAGE 'plpgsql' AS
$_$
  -- a_op:           стадия
  -- a_code:         пакет
  DECLARE
    r_pkg          pgmig.pkg%ROWTYPE;
    r              RECORD;
    v_sql          TEXT;
    v_self_default TEXT;
  BEGIN
    r_pkg := pgmig.pkg(a_code);
    CASE a_op
      WHEN 'init' THEN
        IF r_pkg IS NULL THEN
          -- pgmig only
          INSERT INTO pgmig.pkg (id, code, version, repo, op) VALUES 
            (NEXTVAL('pgmig.pkg_id_seq'), a_code, a_version, a_repo, a_op)
            RETURNING * INTO r_pkg
          ;
          INSERT INTO pgmig.pkg_log VALUES (r_pkg.*);
        END IF;
        PERFORM pgmig.pkg_references(TRUE, a_code);
        UPDATE pgmig.pkg SET updated_at = now() WHERE code = a_code;
      WHEN 'drop', 'erase' THEN
        INSERT INTO pgmig.pkg_log (id, code, version, repo, op) VALUES 
            (NEXTVAL('pgmig.pkg_id_seq'), a_code, a_version, a_repo, a_op);
        IF a_op = 'erase' THEN
          DELETE FROM pgmig.pkg_script_protected  WHERE pkg = a_code;
          DELETE FROM pgmig.pkg_default_protected WHERE pkg = a_code;
          DELETE FROM pgmig.pkg_fkey_protected    WHERE pkg = a_code;
          DELETE FROM pgmig.pkg_fkey_required_by  WHERE required_by = a_code;
        END IF;
        DELETE FROM pgmig.pkg_required_by         WHERE required_by = a_code;
        DELETE FROM pgmig.pkg WHERE code = a_code;
        IF pgmig.schema_exists(a_code) THEN
          IF pgmig.function_exists(a_code||'.cleanup(bool)') THEN
            EXECUTE format('SELECT %1$I.cleanup($1)',a_code) USING (a_op = 'erase');
          ELSE
            EXECUTE format('DROP SCHEMA %1$I CASCADE', a_code);
          END IF;
        END IF;
    END CASE;
    RETURN;
  END;
$_$;

-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pkg_version(a_code NAME)
  RETURNS SETOF TEXT LANGUAGE 'sql' AS
$_$
SELECT version FROM pgmig.pkg WHERE code = $1
$_$;

-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION current_version(a_code NAME, a_version DECIMAL)
  RETURNS VOID LANGUAGE 'plpgsql' AS
$_$
DECLARE
  v_ver DECIMAL;
BEGIN
  SELECT INTO v_ver version FROM pgmig.pkg WHERE code = a_code;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Cannot get version of unknown package (%)', a_code;
  ELSIF v_ver > a_version THEN
    RAISE EXCEPTION 'Newest lib version (%) loaded already', v_ver;
  ELSIF v_ver < a_version THEN
    UPDATE pgmig.pkg SET version = a_version WHERE code = a_code;
  END IF;
END
$_$;


-- 1.2 -> 1.02, 1.20 -> 1.2, 1.02 -> 1.02
CREATE OR REPLACE FUNCTION version2decimal(a_version TEXT) RETURNS DECIMAL IMMUTABLE LANGUAGE sql AS
$_$
  SELECT regexp_replace(substring(a_version from '^v(\d+\.\d+)'),'\.(\d)$','.0\1')::decimal;
$_$;

-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION pkg_require(a_require NAME, a_version DECIMAL DEFAULT 0)
  RETURNS VOID LANGUAGE 'plpgsql' AS
$_$
DECLARE
  v_code TEXT := current_schema();
  v_ver DECIMAL;
BEGIN
  SELECT INTO v_ver pgmig.version2decimal(version) FROM pgmig.pkg WHERE code = a_require;
  IF NOT FOUND THEN
    RAISE EXCEPTION 'Required by % package (%) does not exists', v_code, a_require;
  ELSIF v_ver < a_version THEN
    RAISE EXCEPTION 'Package (%) requires v% of %, but there is only v%', v_code, a_version, a_require, v_ver;
  END IF;

  SELECT INTO v_ver version FROM pgmig.pkg_required_by WHERE required_by = v_code AND code = a_require;
  IF NOT FOUND THEN
    INSERT INTO pgmig.pkg_required_by (code, required_by, version)
      VALUES (a_require, v_code, a_version)
    ;
  ELSIF v_ver < a_version THEN
    UPDATE pgmig.pkg_required_by SET version = a_version
      WHERE code = a_required AND required_by = v_code
    ;
  END IF;
END
$_$;

-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION script_protected(
  a_pkg TEXT
, a_file TEXT
) RETURNS SETOF TEXT STABLE LANGUAGE sql AS $_$
  SELECT csum FROM pgmig.pkg_script_protected WHERE pkg = a_pkg AND file = a_file;
$_$;

-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION script_protect(
  a_pkg TEXT
, a_file TEXT
, a_md5 TEXT
) RETURNS VOID VOLATILE LANGUAGE sql AS $_$
    INSERT INTO pgmig.pkg_script_protected (pkg, file, csum) VALUES (a_pkg, a_file, a_md5);
$_$;


-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION raise_on_errors(errors TEXT) RETURNS void LANGUAGE 'plpgsql' AS
$_$
BEGIN
  IF errors <> '' THEN
    RAISE EXCEPTION E'\n%', errors;
  END IF;
END
$_$;
