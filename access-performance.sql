
----

DROP TYPE mytype3 cascade;
DROP TYPE mytype2 cascade;
DROP TYPE mytype1 cascade;
DROP TYPE mytype cascade;

CREATE TYPE mytype3 AS (
just_a_attrib text
);

CREATE TYPE mytype2 AS (
just_a_attrib text,
nested mytype3
);

CREATE TYPE mytype1 AS (
just_a_attrib text,
nested mytype2
);

CREATE TYPE mytype AS (
just_a_attrib text,
nested mytype1
);

----


drop table test_performance;
create table test_performance (
  id serial primary key,
  just_a_column text,
  resource jsonb,
  doc json,
  typed mytype
);

----
truncate test_performance;

insert into test_performance (just_a_column, resource, doc, typed)
select
 a.n::text,
 jsonb_build_object(
   'just_a_attrib', a.n::text,
   'nested', jsonb_build_object(
      'just_a_attrib', a.n::text,
      'nested', jsonb_build_object(
         'just_a_attrib', a.n::text,
         'nested', jsonb_build_object(
         'just_a_attrib', a.n::text
         )
       )
   )
 ),
 json_build_object(
   'just_a_attrib', a.n::text,
   'nested', json_build_object(
      'just_a_attrib', a.n::text,
      'nested', json_build_object(
         'just_a_attrib', a.n::text,
         'nested', json_build_object(
         'just_a_attrib', a.n::text
         )
       )
   )
 ),
 row((a.n::text), row((a.n::text), row((a.n::text), row(a.n::text)::mytype3)::mytype2)::mytype1)::mytype

from generate_series(1, 100000) as a(n);

vacuum analyze test_performance;
----

select ((((t.typed).nested).nested).nested).just_a_attrib
from test_performance t
limit 10;

----

\timing
select avg(just_a_column::numeric)
from test_performance;

-- 25-26 ms
----

\timing
select avg((resource->>'just_a_attrib')::numeric)
from test_performance;

-- 32 ms
----

\timing
select avg((doc->>'just_a_attrib')::numeric)
from test_performance;

-- 60 ms
----

\timing
select avg((resource#>>'{nested, just_a_attrib}')::numeric)
from test_performance;

-- 40 ms

----

\timing
select avg((doc#>>'{nested, just_a_attrib}')::numeric)
from test_performance;

-- 65 ms

----


\timing
select avg((resource#>>'{nested, nested, just_a_attrib}')::numeric)
from test_performance;

-- 40 ms

----

\timing
select avg((doc#>>'{nested, nested, just_a_attrib}')::numeric)
from test_performance;
-- 65ms
----


\timing
select avg((resource#>>'{nested, nested, nested,just_a_attrib}')::numeric)
from test_performance;

-- 40 ms
----



\timing
select avg((doc#>>'{nested, nested, nested,just_a_attrib}')::numeric)
from test_performance;

-- 70 ms
----

\timing

select avg(
  ((((t.typed).nested).nested).nested).just_a_attrib::numeric
) from test_performance t;

-- 48 ms
----

select row_to_json(t.typed)
from test_performance t
limit 10;

-- 48 ms
----
