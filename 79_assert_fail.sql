select assert_count(1);

SAVEPOINT test_begin;

--this test will fail
-- select assert_eq('failed test', 3, 4);

ROLLBACK TO SAVEPOINT test_begin;

