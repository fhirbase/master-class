----

\a
select
 jsonb_pretty(
  -- row to json
  row_to_json(t)::jsonb
 )
table_name
from information_schema.tables t
limit 10

----
\a
select
jsonb_pretty(
  -- same for jsonb
  to_jsonb(t)
)
table_name
from information_schema.tables t
limit 10


----
\a
select
  jsonb_pretty(
    -- we can strip nulls
    jsonb_strip_nulls(
     to_jsonb(t)
    )
  )
table_name
from information_schema.tables t
limit 10
----
\a

select
jsonb_pretty(
  -- aggregate into jsonb array
  jsonb_agg(
    jsonb_strip_nulls(to_jsonb(t))
  )
)
from information_schema.columns t
group by t.table_name
limit 1

----
\a

select
jsonb_pretty(
  -- agg in object
  jsonb_object_agg(
    t.column_name,
    jsonb_strip_nulls(to_jsonb(t) - 'column_name')
  )
)
from information_schema.columns t
group by t.table_name
limit 1

----

\timing
\a

WITH tables AS (
  select 
    jsonb_strip_nulls(to_jsonb(t)) as doc,
    table_name
  from information_schema.tables t
  where t.table_name ilike 'pg_%'

), columns AS (
  select jsonb_object_agg(
    t.column_name,
    jsonb_strip_nulls(to_jsonb(t))
    - '{table_catalog,table_schema, identity_cycle, is_identity, column_name, table_name, udt_name, udt_catalog, udt_schema, dtd_identifier, is_self_referencing, is_generated }'::text[]
  ) as doc, t.table_name
  from information_schema.columns t
  join tables tt on t.table_name = tt.table_name
  group by t.table_name
), stats AS (
 SELECT
  jsonb_build_object('pages', relpages, 'tuples', reltuples) as doc,
  c.relname as table_name FROM pg_class c
  join tables tt on tt.table_name = c.relname
)

select jsonb_pretty(jsonb_object_agg(x.table_name, doc)) from (
  select
    t.table_name,
    t.doc || jsonb_build_object(
    'columns', c.doc,
    'stats', jsonb_strip_nulls(
      ns.doc || table_size(c.table_name)
     )
    ) as doc
  from  tables t, columns c, stats s
  where t.table_name = c.table_name
  and t.table_name = s.table_name
) x

----
