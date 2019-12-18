/*
  Postgresql variables
*/

CREATE FUNCTION var_prefix() RETURNS TEXT STABLE LANGUAGE 'sql' AS
$_$
  SELECT COALESCE(
    current_setting('pgmig.prefix', true)
  , 'pgmig.var.' -- default value in pgmig.go
  )
$_$;

CREATE FUNCTION var(a_code TEXT) RETURNS TEXT STABLE LANGUAGE 'sql' AS
$_$
  SELECT current_setting(pgmig.var_prefix()||a_code, true)
$_$;


