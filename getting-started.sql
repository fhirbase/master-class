---- db: -h localhost -p 7890 -U postgres postgres

-- Create JSONB
--  RFC 7159 https://tools.ietf.org/html/rfc7159

select '1'::jsonb;
select 'false'::jsonb;
select '"value"'::jsonb;
select '{"attribute": "value"}'::jsonb;
----
select
$JSON$
{
"attribute": "value",
"nested": {"nested_attribute": "nested value"}
}
$JSON$::jsonb;
----

----
-- Pretty print
\a
select jsonb_pretty('{
  "attribute": "value",
  "nested": {"nested_attribute": "nested value"}
}'::jsonb);

-- Other constructors (json_build_object and json_build_array) we will review later

----

-- Access operators: -> ->> #> #>>
-- -   get key or index
-- #   get path
-- >   return json value
-- >>  return text

----
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
'record->>''nested'''          as access,
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

-- Read
-- equivalent to #> operator
select jsonb_extract_path(
'{"attr": "value", "nested": {"foo": "bar"}}'::jsonb, 'nested', 'foo'
);

-- equivalent to #>> operator
select jsonb_extract_path_text(
'{"attr": "value", "nested": {"foo": "bar"}}'::jsonb, 'nested', 'foo'
);


----
-- Create table for Github Commits

----
-- Now load last 300 commits ifo of PostgreSQL from github
-- $ ./github.sh
-- link https://api.github.com/repos/postgres/postgres/commits

----
-- NOTE: if github ban your IP, you can use commits_bk table
-- select count(*) from commits_bk;
-----
create table commits (
  id text primary key,
  doc jsonb
);
----

\a
select jsonb_pretty(doc)
from commits_bk
limit 1;

----
select
  doc#>>'{author,login}' login,
  count(*) commits
from commits_bk
group by doc#>>'{author,login}'
order by count(*) desc ;

-----
-- coerce
select
  (doc#>>'{commit,author,date}')::date,
  doc#>>'{commit,author,name}',
  doc#>>'{commit,author,email}',
  count(*)
from commits_bk
group by
  (doc#>>'{commit,author,date}')::date,
  doc#>>'{commit,author,name}',
  doc#>>'{commit,author,email}'

order by count(*) desc
limit 50;
-----

-- Extra task: analyze data - keys usage

select count(*) from commits;

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
