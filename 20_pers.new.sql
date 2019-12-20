/*
  Создание схемы БД
  Используется в 'pgmig init'
*/

-- create schema without notice if it exists
DO $_$
  BEGIN
    IF NOT pgmig.schema_exists('pers') THEN
      CREATE SCHEMA pers;
    END IF;
  END;
$_$;


-- Схема для персистентных данных
SELECT pgmig.comment('n', 'pers','Persistent data');

SELECT pgmig.comment('n', 'pgmig','PgMig core functions');
