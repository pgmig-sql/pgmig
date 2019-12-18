/*
  Создание схемы БД
  Используется в 'pgmig init'
*/

-- Создание схемы
CREATE SCHEMA IF NOT EXISTS pgmig;

-- Далее все объекты будут создаваться и искать других в схеме :PKG
SET SEARCH_PATH = pgmig, 'public';

-- Схема для персистентных данных
CREATE SCHEMA IF NOT EXISTS pers;
-- SELECT poma.comment('n', 'pers','Persistent data');
