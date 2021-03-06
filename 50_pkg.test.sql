/*
    Тесты
*/
SAVEPOINT test_begin;
select pgmig.assert_count(1);
-- ----------------------------------------------------------------------------
SELECT pgmig.pkg_op_before('init', 'test_pgmig', 'v0.0', 'git');
SELECT pgmig.assert_eq('pkg_op_before'
, (SELECT jsonb_build_object('code',code,'version',version) FROM pgmig.pkg where code='test_pgmig')
, '{
        "version": "v0.0",
        "code": "test_pgmig"
   }'::jsonb
);
ROLLBACK TO SAVEPOINT test_begin;

--TODO: RAISE EXCEPTION отработать utils.exception_test из pgm
/*
-- ----------------------------------------------------------------------------
--SELECT pgmig.test('pkg_op_after'); -- BOT
--  Тест pkg_op_after
SELECT pgmig.pkg_op_after('create', 'test_pgmig', 'test_pgmig', '', '', '', 'noskip','blank.sql'); -- EOT
--TODO: RAISE EXCEPTION отработать utils.exception_test из pgm

-- ----------------------------------------------------------------------------
--SELECT pgmig.test('pkg'); -- BOT
--  Тест pkg
SELECT code, schemas, op FROM pgmig.pkg('test_pgmig'); -- EOT

-- ----------------------------------------------------------------------------
--SELECT pgmig.test('pkg_with_non_existent_schema'); -- BOT
--  Тест pkg с несуществующей схемой. Ожидаемый результат: 0 строк.
SELECT count(1) FROM pgmig.pkg('non_existent_schema'); -- EOT

-- ----------------------------------------------------------------------------
--SELECT pgmig.test('patch'); -- BOT
--  Тест patch
SELECT pgmig.patch('pgmig_test','a83084dc0332dbc4d1f7a6c7dc7b4993','sql/pgmig_test/20_xxtest_once.sql','sql/pgmig_test/','.build/empty_test.sql'); -- EOT
SELECT pgmig.patch('pgmig_test','a83084dc0332dbc4d1f7a6c7dc7b4993','sql/pgmig_test/20_xxtest_once.sql','sql/pgmig_test/','.build/empty_test.sql'); -- EOT

-- ----------------------------------------------------------------------------
--SELECT pgmig.test('raise_on_errors'); -- BOT
--  Тест raise_on_errors
SELECT pgmig.raise_on_errors(''); -- EOT
--TODO: после подключения pgm/utils можно отработать тест с исключением,- utils.exception_test

-- ----------------------------------------------------------------------------
*/