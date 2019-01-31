----

\timing
\a

WITH tables AS (
  select 
    jsonb_strip_nulls(row_to_json(t.*)::jsonb) as doc,
    table_name
  from information_schema.tables t

), columns AS (
  select jsonb_object_agg(
    t.column_name,
    jsonb_strip_nulls(row_to_json(t.*)::jsonb)
    - '{table_catalog,table_schema, table_name, udt_name, udt_catalog, udt_schema, dtd_identifier, is_self_referencing, is_generated }'::text[]
  ) as doc, table_name
  from information_schema.columns t
  group by table_name
), stats AS (
 SELECT
  jsonb_build_object('pages', relpages, 'tuples', reltuples) as doc,
  relname as table_name FROM pg_class c
)

select jsonb_pretty(jsonb_object_agg(x.table_name, doc)) from (
  select
    t.table_name,
    t.doc || jsonb_build_object(
    'columns', c.doc,
    'stats', s.doc || table_size(c.table_name)
    ) as doc
  from  tables t, columns c, stats s
  where t.table_name = c.table_name
  and t.table_name = s.table_name
) x

----
select *
from pg_stat_user_tables
----
