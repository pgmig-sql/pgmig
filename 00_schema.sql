/*
  Создание схемы БД
  Используется в 'make create'
*/

-- Создание схемы
CREATE SCHEMA IF NOT EXISTS pgmig;

-- Далее все объекты будут создаваться и искать других в схеме :PKG
SET SEARCH_PATH = pgmig, 'public';
