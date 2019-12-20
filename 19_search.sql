
CREATE OR REPLACE FUNCTION search_path_set(a_path TEXT) RETURNS VOID LANGUAGE 'plpgsql' AS
$_$
  -- a_path: путь поиска
  BEGIN
    EXECUTE FORMAT('SET LOCAL search_path = %1$I,public', a_path);
  END;
$_$;
SELECT pgmig.comment('f', 'search_path_set', 'Установить переменную search_path');

