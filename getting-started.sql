-----

create table commits (id text primary key, doc jsonb);

-----

\set record `cat ./commits.json`
\a

with commits as (
  select d as doc
  from jsonb_array_elements( ( :'record')::jsonb ) d
)

select jsonb_pretty(doc #> '{author,login}')
from commits


-----

select doc#>>'{author,login}', count(*)
from commits
group by doc#>>'{author,login}'
order by count(*) desc
;

-----

-- \a

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
;

-----



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
