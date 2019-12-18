/*
  Enum for pgmig operations

*/

CREATE TYPE t_pkg_op AS ENUM ('init', 'drop', 'erase');
