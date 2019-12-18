/*
    Create comment for database object
    SELECT comment('n|t|v|c|T|D|f|s', name, comment{, column, column_comment})

    It is ok to add comment for column which does not exist - this may be used in future
*/

-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION comment(
  a_type CHAR(1)
, a_code NAME
, a_comment TEXT DEFAULT NULL
, VARIADIC a_columns TEXT[] DEFAULT NULL
) RETURNS VOID LANGUAGE 'plpgsql' AS
$_$
  DECLARE
    v_object TEXT;    -- database object
    v_names TEXT[];   -- schema.name[.column] split
    v_args TEXT;      -- func: signature arguments
    v_sql TEXT;       -- prepared sql
    v_columns JSONB;  -- jsonb from a_columns
    v_comments JSONB; -- for view only: comments from dependensies
    v_column TEXT;    -- for composite only: column name
    v_comment TEXT;   -- for composite only: column comment
    v_skips TEXT[];   -- composite: lost columns
  BEGIN
    v_object := CASE
      WHEN a_type = 'n' THEN 'SCHEMA'
      WHEN a_type = 't' THEN 'TABLE'
      WHEN a_type = 'v' THEN 'VIEW'
      WHEN a_type = 'c' THEN 'COLUMN'
      WHEN a_type = 'T' THEN 'TYPE'
      WHEN a_type = 'E' THEN 'TYPE' -- enum type
      WHEN a_type = 'D' THEN 'DOMAIN'
      WHEN a_type = 'f' THEN 'FUNCTION'
      WHEN a_type = 's' THEN 'SEQUENCE'
      ELSE NULL
    END;
    IF v_object IS NULL THEN
      RAISE EXCEPTION 'Unknown object type: %', a_type;
    END IF;
    IF v_object = 'SCHEMA' THEN
      v_names[1] := COALESCE(a_code, current_schema());
    ELSE
      v_names := parse_ident(a_code);
      IF array_length(v_names, 1) < (CASE WHEN v_object = 'COLUMN' THEN 3 ELSE 2 END) THEN
        -- use current schema if not given
        v_names = array_prepend(current_schema()::TEXT,v_names);
      END IF;
    END IF;
    IF v_names[1] IN ('pg_catalog', 'information_schema') THEN
      RAISE EXCEPTION 'Objects from schema % does not supported', v_names[1];
    END IF;

    IF v_object = 'FUNCTION' THEN
      -- comment all functions with this name in given schema
      FOR v_args IN SELECT pg_catalog.pg_get_function_identity_arguments(p.oid)
        FROM pg_catalog.pg_proc p
        WHERE p.pronamespace = to_regnamespace(v_names[1])
          AND p.proname = v_names[2]
        LOOP
          v_sql := format('COMMENT ON FUNCTION %s.%s(%s) IS %s'
            , v_names[1], v_names[2], v_args, quote_literal(a_comment));
          RAISE DEBUG '%', v_sql;
          EXECUTE v_sql;
      END LOOP;
      IF NOT FOUND THEN
        RAISE EXCEPTION '% %: not found', v_object, a_code;
      END IF;
    ELSIF v_object = 'SCHEMA' THEN
      v_sql := format('COMMENT ON %s %s IS %s', v_object, v_names[1], quote_literal(a_comment));
      RAISE DEBUG '%', v_sql;
      EXECUTE v_sql;
    ELSE
      v_sql := format('COMMENT ON %s %s IS %s', v_object, array_to_string(v_names,'.'), quote_literal(a_comment));
      RAISE DEBUG '%', v_sql;
      EXECUTE v_sql;
    END IF;
    IF v_object NOT IN ('TABLE', 'VIEW', 'TYPE') OR a_type = 'E' THEN -- TODO: foreign table
      RETURN;
    END IF;

    -- composite type
    RAISE DEBUG 'READY TO COMMENT COLUMNS';

    IF v_object = 'VIEW' THEN
      -- fill view column comments from deps
      SELECT INTO v_comments
        jsonb_object_agg(a.attname, comment)
        FROM  pg_depend d
          JOIN pg_catalog.pg_attribute a ON (a.attrelid = d.refobjid AND a.attnum = d.refobjsubid)
        , LATERAL pg_identify_object(classid, objid, 0) AS obj
        , LATERAL pg_identify_object(refclassid, refobjid, 0) AS refobj
        , LATERAL right(obj.identity, -13) as code
        , LATERAL col_description(refobjid,refobjsubid) AS comment
        WHERE classid <> 0
          AND refobjsubid <> 0
          AND obj.type = 'rule'
          AND obj.identity LIKE '"_RETURN" on %'
          AND comment IS NOT NULL
          AND code = array_to_string(v_names,'.')
      ;
    END IF;

    IF a_columns IS NOT NULL THEN
      IF array_length(a_columns, 1) % 2 <> 0 THEN
        RAISE EXCEPTION '% %: column comment list (%) must contain pairs', v_object, a_code, a_columns;
      END IF;
      v_columns := jsonb_object(a_columns);
    END IF;

    FOR v_column IN SELECT attname
      FROM pg_catalog.pg_attribute
     WHERE attrelid = array_to_string(v_names, '.')::regclass
       AND attnum > 0
       AND NOT attisdropped
      LOOP
        IF v_columns IS NOT NULL AND v_columns ? v_column THEN
          v_comment := v_columns ->> v_column;
        ELSIF v_comments IS NOT NULL AND v_comments ? v_column THEN
          v_comment := v_comments ->> v_column;
        ELSE
          v_skips := array_append(v_skips, v_column);
          CONTINUE;
        END IF;
        IF v_comment IS NULL THEN
        RAISE EXCEPTION '% %.%.%: NULL comment is not allowed', v_object, v_names[1], v_names[2], v_column;
        END IF;
        v_sql := format('COMMENT ON COLUMN %s.%s.%s IS %s'
          , v_names[1], v_names[2], v_column, quote_literal(v_comment));
        RAISE DEBUG '%', v_sql;
        EXECUTE v_sql;
    END LOOP;

    -- Check skipped columns
    IF array_length(v_skips, 1) > 0 THEN
      RAISE WARNING '% %: column(s) % still not commented', v_object, a_code, v_skips;
    END IF;
    RETURN;
  END;
$_$;
SELECT comment('f', 'comment', 'Create comment for database object');
