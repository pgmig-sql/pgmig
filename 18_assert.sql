
create or replace function assert_proto() returns decimal language sql immutable as $_$
	select coalesce(current_setting('variables.pgmig_proto_version', true)::decimal, 2.1);
$_$;

create or replace function assert_count(cnt integer) returns text language plpgsql as $_$
begin
	if assert_proto() < 2 then
		raise warning using message = jsonb_build_object('code', '01998', 'message', cnt);
	else
		raise warning using errcode = '01998', message = cnt::text, hint = 'test count';
	end if;
	return format('Tests: %s', cnt);
end;
$_$;

create or replace function assert_eq(test text, got anyelement, want anyelement) returns text language plpgsql as $_$
begin
	if got is not distinct from want then
		if assert_proto() < 2 then
			raise warning using message = jsonb_build_object('code', '01999', 'message', test);
		else
		raise warning using errcode = '01999', message = test, hint='test Ok';
		end if;
		return test;
	end if;
	if assert_proto() < 2 then
		raise warning using message = jsonb_build_object('code', '02999', 'message', test,
			'data', jsonb_build_object('got', got, 'want', want));
	else
		raise warning using errcode = '02999', message = test, hint='test failed'
		, detail = jsonb_pretty(jsonb_build_object('got', got, 'want', want))
		;
	end if;
  return test;
end;
$_$;
