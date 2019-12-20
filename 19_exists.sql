CREATE OR REPLACE FUNCTION schema_exists(name) RETURNS BOOL LANGUAGE 'sql' AS
$_$
  SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = $1)
$_$;
SELECT pgmig.comment('f', 'schema_exists', 'Check if db schema exists');

CREATE OR REPLACE FUNCTION function_exists(a_signature TEXT) RETURNS BOOL LANGUAGE 'plpgsql' AS
$_$
	BEGIN
	  PERFORM a_signature::regprocedure;
	  RETURN TRUE;
	EXCEPTION WHEN undefined_function THEN
	   RETURN FALSE;
	END
$_$;
SELECT pgmig.comment('f', 'function_exists', 'Check if db function with given signature exists');
