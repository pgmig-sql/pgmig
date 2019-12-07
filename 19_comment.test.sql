/*
    Тесты comment
*/

-- ----------------------------------------------------------------------------
select assert_count(1);

/*
  Test comment schema
*/
SELECT pgmig.comment('n','pgmig','Postgresql projects Makefile');
SELECT assert_eq('t1'
, (CASE WHEN (select obj_description(to_regnamespace('pgmig'))) = 'Postgresql projects Makefile' THEN TRUE ELSE FALSE END)
, true
);
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
/*
  Тест comment table

SELECT pgmig.comment('t','pgmig.pkg', 'Информация о пакетах и схемах',
    'id','идентификатор'
  , 'code','код пакета'
  , 'schemas','наименование схемы'
  , 'op','стадия'
  , 'version','версия'
  , 'log_name','наименования пользователя'
  , 'user_name','имя пользователя'
  , 'ssh_client','ключ'
  , 'usr','пользователь'
  , 'ip','ip-адрес'
  , 'stamp','дата/время создания/изменения'
); --EOT
SELECT nspname, relname, attname, format_type(atttypid, atttypmod), obj_description(c.oid), col_description(c.oid, a.attnum) 
FROM pg_class c 
JOIN pg_attribute a ON (a.attrelid = c.oid) 
JOIN pg_namespace n ON (n.oid = c.relnamespace)
WHERE nspname='pgmig' AND relname='pkg'
AND attnum > 0
ORDER BY attname ASC; --EOT
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW pgmig.test_view_pkg AS 
 SELECT id, code, schemas FROM pgmig.pkg;
--  Тест comment view
SELECT pgmig.comment('v','pgmig.test_view_pkg'
  ,'Представление с краткой информацией о пакетах и схемах'
  , VARIADIC ARRAY[
      'id','идентификатор view'
    , 'code','код пакета view'
    , 'schemas','наименование схемы view'
  ]); --EOT
SELECT nspname, relname, attname, format_type(atttypid, atttypmod), obj_description(c.oid), col_description(c.oid, a.attnum) 
FROM pg_class c 
JOIN pg_attribute a ON (a.attrelid = c.oid) 
JOIN pg_namespace n ON (n.oid = c.relnamespace)
WHERE nspname='pgmig' AND relname='test_view_pkg'
ORDER BY attname ASC; --EOT
-- ----------------------------------------------------------------------------
SELECT pgmig.test('comment_view2'); -- BOT
create table pgmig.vctable1(
id integer primary key
, anno text
); -- EOT
select pgmig.comment('t','pgmig.vctable1', 'test table'
, 'anno', 'row anno'
, 'id', 'row id'
); --EOT

create view pgmig.vcview1 AS
  select *
  , current_date AS date
  from pgmig.vctable1
; --EOT
select pgmig.comment('v','pgmig.vcview1', 'test view1'
, 'id', 'row id1'
, 'date', 'cur date'
); -- EOT
SELECT nspname, relname, attname, format_type(atttypid, atttypmod), obj_description(c.oid), col_description(c.oid, a.attnum)
FROM pg_class c 
JOIN pg_attribute a ON (a.attrelid = c.oid) 
JOIN pg_namespace n ON (n.oid = c.relnamespace)
WHERE nspname='pgmig' AND relname IN('vctable1', 'vcview1')
AND attnum > 0
ORDER BY relname, attname ASC; --EOT
-- ----------------------------------------------------------------------------
SELECT pgmig.test('comment_view3'); -- BOT
CREATE VIEW pgmig.vcview2 AS
  SELECT v.id, v.date, t.anno
  , 1 AS ok
  FROM pgmig.vcview1 v
  JOIN pgmig.vctable1 t using(id)
; -- EOT
SELECT pgmig.comment('v','pgmig.vcview2', 'test view2'
, 'ok', 'new filed'
); -- EOT

SELECT nspname, relname, attname, format_type(atttypid, atttypmod), obj_description(c.oid), col_description(c.oid, a.attnum)
  FROM pg_class c
  JOIN pg_attribute a ON (a.attrelid = c.oid)
  JOIN pg_namespace n ON (n.oid = c.relnamespace)
 WHERE nspname='pgmig' AND relname = 'vcview2'
 ORDER BY attname ASC; --EOT
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
SELECT pgmig.test('comment_column'); -- BOT
--  Тест comment column
SELECT pgmig.comment('c', 'pgmig.pkg.id', 'Тест. Изменение наименования column id'); --EOT
SELECT nspname, relname, attname, format_type(atttypid, atttypmod), obj_description(c.oid), col_description(c.oid, a.attnum)
FROM pg_class c
JOIN pg_attribute a ON (a.attrelid = c.oid)
JOIN pg_namespace n ON (n.oid = c.relnamespace)
WHERE nspname='pgmig' AND relname='pkg' AND attname='id'
ORDER BY attname ASC; --EOT
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
SELECT pgmig.test('comment_type_enum'); -- BOT
--  Тест comment type enum
CREATE TYPE pgmig.tmp_event_class AS ENUM (
  'create'
, 'update'
, 'delete'
); --EOT
SELECT pgmig.comment('E','pgmig.tmp_event_class','Комментирование типа enum'); --EOT
SELECT obj_description(to_regtype('pgmig.tmp_event_class')); --EOT

-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
SELECT pgmig.test('comment_type'); -- BOT
--  Тест comment type
CREATE TYPE pgmig.tmp_errordef AS (
  field_code TEXT
, err_code   TEXT
, err_data   TEXT
); --EOT

SELECT pgmig.comment('T', 'pgmig.tmp_errordef', 'Тестовый тип'
 , 'field_code', 'Код поля с ошибкой'
 , 'err_code', 'Код ошибки'
 , 'err_data', 'Данные ошибки'
); --EOT

SELECT nspname, relname, attname, format_type(atttypid, atttypmod)
  , obj_description(to_regtype(nspname||'.'||c.relname))
  , col_description(c.oid, a.attnum) 
FROM pg_class c
JOIN pg_attribute a ON (a.attrelid = c.oid) 
JOIN pg_namespace n ON (n.oid = c.relnamespace)
WHERE nspname='pgmig' AND relname='tmp_errordef'
ORDER BY attname ASC; --EOT
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
SELECT pgmig.test('comment_domain'); -- BOT
--  Тест comment domain
CREATE DOMAIN test_domain AS INTEGER; --EOT
SELECT pgmig.comment('D', 'test_domain', 'Тест комментария DOMAIN'); --EOT
SELECT obj_description(to_regtype('test_domain')); --EOT
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
SELECT pgmig.test('comment_function'); -- BOT

create or replace function pgmig.test_arg() returns void language sql as
$_$ 
 SET CLIENT_MIN_MESSAGES = 'DEBUG';
$_$;
create or replace function pgmig.test_arg(a TEXT) returns void language sql as
$_$ 
 SET CLIENT_MIN_MESSAGES = a; --'INFO';
$_$;
--  Test comment function
-- вызов коментирования функций
SELECT pgmig.comment('f','pgmig.comment',E'te''st'); --EOT
SELECT pgmig.comment('f','pgmig.test_arg','all test_arg'); --EOT

SELECT p.proname
  , pg_catalog.pg_get_function_identity_arguments(p.oid)
  , obj_description(p.oid, 'pg_proc')
FROM pg_catalog.pg_proc p
WHERE p.proname IN ('comment','test_arg')
ORDER BY proname, pg_get_function_identity_arguments ASC; -- EOT
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
--  Тест comment sequence
SELECT pgmig.comment('s', 'pgmig.pkg_id_seq', 'Тест комментария последовательности pkg_id_seq'); --EOT
SELECT obj_description('pgmig.pkg_id_seq'::regclass); --EOT
-- ----------------------------------------------------------------------------
*/
