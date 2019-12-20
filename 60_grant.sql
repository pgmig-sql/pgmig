
-- setup permissions if test_role given
DO $_$
  DECLARE
    v_role TEXT := pgmig.var('test_role');
  BEGIN
    IF v_role IS NOT NULL THEN
      RAISE NOTICE 'Setup perms for role %',v_role;
      EXECUTE format('grant usage on schema %1$I to %2$I', 'pgmig', v_role);  -- TODO: allow assert* only
    END IF;
  END;
$_$ LANGUAGE plpgsql;
