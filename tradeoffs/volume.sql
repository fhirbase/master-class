----
\set prefix 'somereasonabletext-'

----


drop table test_vol_jsonb;
create table test_vol_jsonb (
id serial primary key,
  resource jsonb
);

drop table test_vol_rel;
create table test_vol_rel (
  id serial primary key,
  just_a_attrib text,
  nested_just_a_attrib text,
  nested_nested_just_a_attrib text,
  nested_nested_nested_just_a_attrib text
);

drop table test_vol_tp;
create table test_vol_tp (
  id serial primary key,
  typed mytype
);

----

\set prefix 'somereasonabletext-'

truncate test_vol_jsonb;
insert into test_vol_jsonb (resource)
select
jsonb_build_object(
  'just_a_attrib', ':prefix' || a.n::text,
  'nested', jsonb_build_object(
    'just_a_attrib', ':prefix' || a.n::text,
    'nested', jsonb_build_object(
      'just_a_attrib', ':prefix' || a.n::text,
        'nested', jsonb_build_object(
        'just_a_attrib', ':prefix' || a.n::text
    )
   )
  )
)
from generate_series(1, 100000) as a(n);

vacuum analyze test_vol_jsonb;
----

\set prefix 'somereasonabletext-'
truncate test_vol_rel;

insert into test_vol_rel (
  just_a_attrib,
  nested_just_a_attrib,
  nested_nested_just_a_attrib,
  nested_nested_nested_just_a_attrib
  )
select
':prefix' || a.n::text,
':prefix' || a.n::text,
':prefix' || a.n::text,
':prefix' || a.n::text
from generate_series(1, 100000) as a(n);

vacuum analyze test_vol_rel;

----

\set prefix 'somereasonabletext-'

truncate test_vol_tp;

insert into test_vol_tp (typed)
select

row((':prefix' || a.n::text),
  row((':prefix' || a.n::text),
    row((':prefix' || a.n::text),
      row(':prefix' || a.n::text)::mytype3)::mytype2)::mytype1)::mytype
from generate_series(1, 100000) as a(n);

vacuum analyze test_vol_tp;

----
create or replace function table_size (nm text) returns table(result  jsonb)
as $$
begin
RETURN QUERY

SELECT jsonb_build_object('total', pg_size_pretty(total_bytes)
, 'index', pg_size_pretty(index_bytes)
, 'toast', pg_size_pretty(toast_bytes)
, 'table', pg_size_pretty(table_bytes)) as result
FROM (
SELECT *, total_bytes-index_bytes-COALESCE(toast_bytes,0) AS table_bytes FROM (
SELECT c.oid,nspname AS table_schema, relname AS TABLE_NAME
, c.reltuples AS row_estimate
, pg_total_relation_size(c.oid) AS total_bytes
, pg_indexes_size(c.oid) AS index_bytes
, pg_total_relation_size(reltoastrelid) AS toast_bytes
FROM pg_class c
LEFT JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE relname = nm
) a
) a;

END;
$$ LANGUAGE plpgsql;

----

select
  jsonb_pretty(table_size('test_vol_jsonb')) as jsonb,
  jsonb_pretty(table_size('test_vol_rel')) as rel,
  jsonb_pretty(table_size('test_vol_tp')) as tp


----

pt from https://www.hl7.org/fhir/patient-example.json

keys is 30 %
size is 3.6 K

----
