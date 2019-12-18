/*
  Testing support funcions
*/

-- assert_proto returns testing proto version, it defines format of test messages
CREATE OR REPLACE FUNCTION assert_proto() RETURNS DECIMAL LANGUAGE SQL IMMUTABLE AS $_$
	SELECT coalesce(current_setting('pgmig.assert_proto', true)::DECIMAL, 2.1);
$_$;
SELECT comment('f', 'assert_proto', 'Testing `raise message` format');

CREATE OR REPLACE FUNCTION assert_count(cnt integer) RETURNS TEXT LANGUAGE PLPGSQL AS $_$
BEGIN
	IF pgmig.assert_proto() < 2 THEN
		raise notice using message = jsonb_build_object('code', '01998', 'message', cnt);
	ELSE
		raise notice using errcode = '01998', message = cnt::text, hint = 'test count';
	END IF;
	RETURN format('Tests: %s', cnt);
END;
$_$;
SELECT comment('f', 'assert_count', 'Tests count in current file');

CREATE OR REPLACE FUNCTION assert_eq(test TEXT, got ANYELEMENT, want ANYELEMENT) RETURNS TEXT LANGUAGE PLPGSQL AS $_$
BEGIN
	IF got is NOT DISTINCT FROM want THEN
		IF pgmig.assert_proto() < 2 THEN
			raise notice using message = jsonb_build_object('code', '01999', 'message', test);
		ELSE
		raise notice using errcode = '01999', message = test, hint='test Ok';
		END IF;
		RETURN test;
	END IF;
	IF pgmig.assert_proto() < 2 THEN
		raise notice using message = jsonb_build_object('code', '02999', 'message', test,
			'data', jsonb_build_object('got', got, 'want', want));
	ELSE
		raise notice using errcode = '02999', message = test, hint='test failed'
		, detail = jsonb_pretty(jsonb_build_object('got', got, 'want', want))
		;
	END IF;
  RETURN test;
END;
$_$;
SELECT comment('f', 'assert_eq', 'Test for args equality');
