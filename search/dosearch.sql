----
-- Arrow functions

select
  substring(resource#>>'{subject,id}' from 0 for 10),
  resource#>>'{type,0,text}',
  (resource#>>'{period,start}')::date,
  (resource#>>'{period,end}')::date
from encounter
limit 10

----

drop index enc_subj_id_idx;

----
-- Arrows and functional indexes

\timing

select
  resource#>>'{type,0,text}',
  (resource#>>'{period,start}')::date,
  (resource#>>'{period,end}')::date
from encounter
where
resource#>>'{subject,id}' = '32fe33e0-296f-486a-856d-3053fd0db8ab'

----

drop index enc_subj_id_idx;

----
create index enc_subj_id_idx on encounter (
  (resource#>>'{subject,id}')
);

analyze encounter;

----
explain (costs off)
select
  resource#>>'{type,0,text}',
  (resource#>>'{period,start}')::date,
  (resource#>>'{period,end}')::date
from encounter
where
resource#>>'{subject,id}' = '32fe33e0-296f-486a-856d-3053fd0db8ab'

----

-- u can cast json data to pg types

\a
\timing
explain analyze
select
  (resource#>>'{period,start}')::date,
  resource#>>'{type,0,text}'
from encounter
where (resource#>>'{period,start}')::date
between '2011-04-01'::date and '2011-04-10'::date
limit 30
----

CREATE OR REPLACE FUNCTION imm_date(text) RETURNS date
  AS 'select $1::date;'
LANGUAGE SQL IMMUTABLE RETURNS NULL ON NULL INPUT;

create index enc_start_idx on encounter
(
  imm_date(resource#>>'{period,start}')
);

vacuum analyze encounter;

----
\timing
explain (costs off)
select
  (resource#>>'{period,start}')::date,
  resource#>>'{type,0,text}'
from encounter
where imm_date(resource#>>'{period,start}')
between '2011-04-01'::date and '2011-04-10'::date
limit 30

----

-- FIND all observations with code.coding.code =  '72166-2'

----
\a

select
  resource#>>'{code,coding,0,code}',
  resource#>>'{code,coding,0,system}',
  resource#>>'{code,coding,0,display}'
from observation
where
  resource#>>'{code,coding,0,code}' = '72166-2'
  or
  resource#>>'{code,coding,1,code}' = '72166-2'

limit 100

----

-- inclusion operator

-- @> operator
select '{"a":1, "b":2}'::jsonb @> '{"b":3}'::jsonb;

----
select '{"a":1, "b":2}'::jsonb @> '{"b":2}'::jsonb;

----
-- matches part of document
select
   '[{"system":"phone", "value": "123"}]'::jsonb
    @> '[{"system":"phone"}]'::jsonb;

----
---match nested objects and arrays

select $JSON$
[
  {"prop": {"system":"email", "value": "123"}},
  {"prop": {"system":"phone", "value": "123"}}
]
$JSON$::jsonb @> '[{"prop": {"system":"phone"}}]'::jsonb;


----

-- has key

select
'{"a":1, "b":2}'::jsonb ? 'b' as b_in,
'{"a":1, "b":2}'::jsonb ? 'c' as c_in
;

----

-- all of keys

select
  '{"name": "Nikolai", "address": "spb.ru"}'::jsonb
   ?& array['name', 'address'] 
;

----

select '{"name": "Nikolai", "address": "spb.ru"}'::jsonb
   ?& array['name', 'birthDate']
;

----
\timing
explain (costs off)
select
  resource#>>'{code,coding,0,code}',
  resource#>>'{code,coding,0,system}',
  resource#>>'{code,coding,0,display}'
from observation
where resource @> '{"code":{"coding":[{"code": "72166-2", "system": "http://loinc.org"}]}}'::jsonb

limit 100
----

DROP INDEX obs_idxginp;
DROP INDEX obs_idxgin;
DROP index obs_jsq_idxgin;

----

-- default operator

CREATE INDEX obs_idxgin
   ON observation
     USING GIN (resource);

analyze observation;

----

CREATE INDEX obs_idxginp
 ON observation
   USING GIN (resource jsonb_path_ops);

analyze observation;
----

select
  table_size('observation')->'total' as table_size,
  table_size('obs_idxgin')->'total' as jsonb_ops,
  table_size('obs_idxginp')->'total' as jsonb_path_ops;

----
\timing
explain (costs off)
select
  resource#>>'{code,coding,0,code}',
  resource#>>'{code,coding,0,system}',
  resource#>>'{code,coding,0,display}'
from observation
where resource @> '{"code":{"coding":[{"code": "72166-2", "system": "http://loinc.org"}]}}'::jsonb

limit 100
----

---
-- jsquery
----

create extension if not exists jsquery;

----

\timing

-- explain analyze
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

--sepecil opclass

CREATE INDEX obs_jsq_idxgin
  ON observation
    USING GIN (resource jsonb_path_value_ops);

ANALYZE observation;

----

select
  table_size('observation')->'total' as table_size,
  table_size('obs_idxgin')->'total' as jsonb_ops,
  table_size('obs_idxginp')->'total' as jsonb_path_ops,
  table_size('obs_jsq_idxgin')->'total' as jsquery_ops

----


\timing

explain (costs off)
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
  and subject.id  = "32fe33e0-296f-486a-856d-3053fd0db8ab"
  and value.Quantity.value > 80.0
$JSQ$
);

----

SELECT gin_debug_query_path_value(
$JSQ$
  code.coding.#.code /*-- noindex */ = "2339-0"
  and subject.id /*-- index */ = "32fe33e0-296f-486a-856d-3053fd0db8ab"
  and value.Quantity.value > 80.0
$JSQ$
);

----


-- json knife

create extension if not exists jsonknife;
----

SELECT
  knife_extract_min_timestamptz(resource, '[["period", "start"], ["period","end"]]'),
  knife_extract_max_timestamptz(resource, '[["period", "start"], ["period","end"]]')
from encounter
limit 10;

----

SELECT
knife_extract_text(resource, '[["name", "given"], ["name","family"]]')
from patient
limit 10;
----

SELECT
knife_extract_text(resource,
  '[["name", {"use":"official"}, "given"], ["name", {"use": "official"}, "family"]]'
)
from patient
limit 10;

----
-- see more samples
-- at - https://github.com/niquola/jsonknife/blob/master/sql/test.sql
---

----

-- Analytics
---

DROP materialized VIEW view_pts cascade;

CREATE MATERIALIZED VIEW view_pts AS

select
  id,
  resource#>>'{name,0,given,0}' as fist_name,
  resource#>>'{name,0,family}' as last_name,
  resource#>>'{address,0,city}' as city,
  resource#>>'{address,0,line,0}' as address,
  resource#>>'{birthDate}' as bod
from patient

----
-- create extension pg_trgm;

create index view_pt_line_idx on view_pts using gin (address gin_trgm_ops);

vacuum analyze view_pts;

----

\timing

-- explain analyze
select * from view_pts
where address ilike '%Spur%'
limit 10

----
insert into patient (id,txid,status, resource)
select gen_random_uuid(),0, 'created', resource from patient;

----

REFRESH MATERIALIZED VIEW view_pts;

----
