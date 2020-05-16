# sql-pgmig - SQL part of pgmig project

## Usage

```sql
-- set tests count
select assert_count(1);

-- do some test init
-- ...

-- point without test changes
savepoint test_begin;

select assert_eq('test name'
, your_function()
, 'result_wanted'
);

-- clear test changes
rollback to savepoint test_begin;
```
