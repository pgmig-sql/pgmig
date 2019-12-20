/*
  Postgresql variables
*/

CREATE OR REPLACE FUNCTION var_prefix(a_code TEXT DEFAULT '') RETURNS TEXT STABLE LANGUAGE 'sql' AS
$_$
  SELECT COALESCE(
    current_setting('pgmig.prefix', true)
  , 'pgmig.var.' -- default value in pgmig.go
  ) || a_code
$_$;

CREATE OR REPLACE FUNCTION var(a_code TEXT) RETURNS TEXT STABLE LANGUAGE 'sql' AS
$_$
  SELECT current_setting(pgmig.var_prefix()||a_code, true)
$_$;


