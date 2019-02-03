---- db: -h localhost -p 7890 -U postgres postgres

-- Create JSONB

select '1'::jsonb;
select 'false'::jsonb;
select '"value"'::jsonb;
select '{"attribute": "value"}'::jsonb;

select
$JSON$
{
"attribute": "value",
"nested": {"nested_attribute": "nested value"}
}
$JSON$::jsonb;

-- Pretty print
select jsonb_pretty('{
"attribute": "value",
"nested": {"nested_attribute": "nested value"}
}'::jsonb);

-- Other constructors (json_build_object and json_build_array) we will review later

----

-- Access operators: -> ->> #> #>>
-- ->

\set record '{"key": "value", "nested": {"key": "nested value"}}'
\echo 'Operator -> Get JSON object field by key or index'

select jsonb_pretty((:'record')::jsonb) record;
select
'record->''key''' as access,
(:'record')::jsonb->'key' as value,
pg_typeof((:'record')::jsonb->'key');

select
'record->''nested''' as access,
(:'record')::jsonb->'nested'  as value,
pg_typeof((:'record')::jsonb->'nested');

----
-- ->>

\set record '{"key": "value", "nested": {"key": "nested value"}}'
\echo 'Operator ->> Get JSON object field or array element as text'
select jsonb_pretty((:'record')::jsonb) record;

select
'record->>''key''' as access,
(:'record')::jsonb->>'key' as value,
pg_typeof((:'record')::jsonb->>'key');

select
'record->>''nested''' as access,
(:'record')::jsonb->>'nested'  as value,
pg_typeof((:'record')::jsonb->>'nested');

----
-- #>
\set record '{"key": "value", "nested": {"key": "nested value"}}'
\echo 'Operator #> Get JSON object at specified path'
select jsonb_pretty((:'record')::jsonb) record;

select
'record#>''{nested,key}''' as access,
(:'record')::jsonb#>'{nested,key}' as value,
pg_typeof((:'record')::jsonb#>'{nested,key}');
----
-- #>>

\set record '{"key": "value", "nested": {"key": "nested value"}}'
\echo 'Operator #>> Get JSON object at specified path as text'
select jsonb_pretty((:'record')::jsonb) record;

select
'record#>>''{nested,key}''' as access,
(:'record')::jsonb#>>'{nested,key}' as value,
pg_typeof((:'record')::jsonb#>>'{nested,key}');
----

----
-- Create table for Github Commits
create table commits (
  id text primary key,
  doc jsonb
);
----
-- Now load last 300 commits ifo of PostgreSQL from github
-- $ ./github.sh
-- link https://api.github.com/repos/postgres/postgres/commits

----
-- NOTE: if github ban your IP, you can use commits_bk table
-- select count(*) from commits_bk;
-----

\a
select jsonb_pretty(doc)
from commits_bk
limit 1;

-----
select doc#>>'{author,login}' login, count(*) commits
from commits
group by doc#>>'{author,login}'
order by count(*) desc ;

-----
-- coerce
select
  (doc#>>'{commit,author,date}')::date,
  doc#>>'{commit,author,name}',
  doc#>>'{commit,author,email}',
  count(*)
from commits
group by
  (doc#>>'{commit,author,date}')::date,
  doc#>>'{commit,author,name}',
  doc#>>'{commit,author,email}'

order by count(*) desc
limit 50;
-----

-- analyze data - keys usage

with recursive r AS (

  select attr.key as path, attr.value as val
  from commits p,
  jsonb_each(doc) attr

  UNION

  (
    WITH prev AS (
      select * from r
    ), obj AS (
      select path || '.' || attr.key as path, attr.value as val
      from prev, jsonb_each(val) attr
      where jsonb_typeof(val) = 'object'
    ), arr AS (
      select path as path, attr as val
      from prev, jsonb_array_elements(val) attr
      where jsonb_typeof(val) = 'array'
    )
      select * from obj union select * from arr
    )
)

select  path, count(*)
from r
group by path
order by count(*) desc;

-----
