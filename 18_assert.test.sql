select pgmig.assert_count(3);

SAVEPOINT test_begin;

select pgmig.assert_eq('first', 1, 1);

ROLLBACK TO SAVEPOINT test_begin;

select pgmig.assert_eq('second', 2, 2);

ROLLBACK TO SAVEPOINT test_begin;

--this test will fail
-- select assert_eq('failed test', 3, 4);

ROLLBACK TO SAVEPOINT test_begin;

select pgmig.assert_eq('third'
, 'Devops'::text
, 'Devops'
);

ROLLBACK TO SAVEPOINT test_begin;
