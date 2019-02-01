----

-- @> operator
select '{"a":1, "b":2}'::jsonb @> '{"b":2}'::jsonb;

----
select '{"a":1, "b":2}'::jsonb <@ '{"b":2}'::jsonb;

----
-- matches part of document
select '[{"system":"phone", "value": "123"}]'::jsonb @> '[{"system":"phone"}]'::jsonb;

----
---match nested objects and arrays

select $JSON$
  [
    {"prop": {"system":"email", "value": "123"}},
    {"prop": {"system":"phone", "value": "123"}}
  ]
$JSON$::jsonb @> '[{"prop": {"system":"phone"}}]'::jsonb;


----

select
  '{"a":1, "b":2}'::jsonb ? 'b' as b_in,
  '{"a":1, "b":2}'::jsonb ? 'c' as c_in
;
----

select '{"name": "Nikolai", "address": "spb.ru"}'::jsonb ?& array['name', 'address'] 
;

----

select '{"name": "Nikolai", "address": "spb.ru"}'::jsonb ?& array['name', 'birthDate'] 
;

----
\a

select jsonb_pretty(resource)
from patient
limit 10;

----

-- find pt from city

select
 id,
 resource#>>'{name,0,given,0}',
 resource#>>'{name,0,family}',
 resource#>>'{address,0,city}',
 resource#>>'{address,0,line,0}',
 resource#>>'{birthDate}'
from patient
where resource @> '{"address":[{"city": "Brockton"}]}'
limit 10;

----

-- see all keys
select distinct jsonb_object_keys(resource)
from patient
limit 100;

----

select
  p.resource#>>'{name,0,given}',
  a->>'line',
  a->>'city'
from patient p,
jsonb_array_elements(p.resource->'address') a
limit 10;

----

select
  resource#>>'{name,0,given,0}',
  resource#>>'{address,0,city}',
  resource#>>'{address,0,line,0}'
from patient
where
exists (
  select true
  from jsonb_array_elements(resource->'address') a
  where a->>'city' = 'Brockton'
)
limit 10;

----


select attr.key, attr.value
from patient p,
jsonb_each(resource) attr
limit 20

----

-- find all key paths in table


with recursive r AS (

  select attr.key as path, attr.value as val
  from patient p,
  jsonb_each(resource) attr

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

----

select
distinct
resource#>>'{code,coding,0,code}',
resource#>>'{code,coding,0,display}'

from observation

----

select
p.resource#>>'{name,0,family}',
o.resource#>>'{category,0,coding,0,code}',
o.resource#>>'{code,coding,0,code}' as code,
o.resource#>>'{code,coding,0,display}' as disp,
o.resource#>>'{value,Quantity,value}' as val 

from observation o
join patient p
on p.id = o.resource#>>'{subject,id}'

where o.resource#>>'{code,coding,0,code}' = '2339-0'
order by (o.resource#>>'{value,Quantity,value}')::numeric desc


limit 10


----

\timing

 -- explain analyze
select
 resource#>>'{subject,id}',
 resource#>>'{value,Quantity,value}',
 resource#>>'{value,Quantity,unit}'
from observation
where
 resource @> '{"code": {"coding": [{"code": "2339-0"}]}, "subject": {"id": "32fe33e0-296f-486a-856d-3053fd0db8ab"}}'
limit 10;

----

\timing

-- explain analyze
select
  resource#>>'{subject,id}',
  resource#>>'{value,Quantity,value}',
  resource#>>'{value,Quantity,unit}'
from observation
where
resource#>>'{code,coding,0,code}' = '2339-0'
and
resource#>>'{subject,id}' = '32fe33e0-296f-486a-856d-3053fd0db8ab'

limit 10;

----

\timing
-- explain analyze
select
  resource#>>'{code,coding,0,display}',
  resource#>>'{value,Quantity,value}',
  resource#>>'{value,Quantity,unit}',
  now() - (resource#>>'{effective,dateTime}')::timestamp
from observation
where
-- resource#>>'{code,coding,0,code}' = '2339-0'
-- and
resource#>>'{subject,id}' = '32fe33e0-296f-486a-856d-3053fd0db8ab'
order by (resource#>>'{effective,dateTime}') desc
limit 100


----


DROP INDEX obs_idxgin;
DROP INDEX obs_idxginp;
DROP INDEX obs_pt_idx;

----

CREATE INDEX obs_idxgin ON observation USING GIN (resource);
CREATE INDEX obs_idxginp ON observation USING GIN (resource jsonb_path_ops);
CREATE INDEX obs_pt_idx ON observation (
  (resource#>>'{code,coding,0,code}'), (resource#>>'{subject,id}')
);

vacuum analyze observation;
----

select jsonb_pretty(table_size('obs_idxgin'));
select jsonb_pretty(table_size('obs_idxginp'));
select jsonb_pretty(table_size('obs_pt_idx'));

----


create extension jsquery;

----

\timing

explain analyze
select
resource#>>'{subject,id}',
resource#>>'{value,Quantity,value}',
resource#>>'{value,Quantity,unit}'
from observation
where
resource @@  $JSQ$
  code.coding.#.code = "2339-0"
  and subject.id /*-- index */ = "32fe33e0-296f-486a-856d-3053fd0db8ab"
  and value.Quantity.value > 80.0
 $JSQ$
limit 10;

----
SELECT gin_debug_query_path_value(
 $JSQ$
  code.coding.#.code = "2339-0"
  and subject.id /*-- index */ = "32fe33e0-296f-486a-856d-3053fd0db8ab"
  and value.Quantity.value > 80.0
$JSQ$
)

----

SELECT gin_debug_query_value_path(
$JSQ$
code.coding.#.code = "2339-0"
and subject.id /*-- index */ = "32fe33e0-296f-486a-856d-3053fd0db8ab"
and value.Quantity.value > 80.0
$JSQ$
)

----
drop index obs_jsq_idxgin;

----

CREATE INDEX obs_jsq_idxgin ON observation USING GIN (resource jsonb_path_value_ops);
vacuum analyze observation;

----

drop index obs_jsq_idxginp;

----

CREATE INDEX obs_jsq_idxginp ON observation USING GIN (resource jsonb_value_path_ops);
vacuum analyze observation;

----

\timing

-- explain analyze
select
resource#>>'{subject,id}',
resource#>>'{code,coding,0,code}',
resource#>>'{value,Quantity,value}',
resource#>>'{value,Quantity,unit}'
from observation
where
resource @@  $JSQ$
*.code = "2339-0"
$JSQ$
limit 10;

----
