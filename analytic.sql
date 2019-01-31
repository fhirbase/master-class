----

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

\timing


-- explain analyze
select * from view_pts
where address ilike '%Spur%'
limit 10

----

REFRESH MATERIALIZED VIEW view_pts;

----
insert into patient (id,txid,status, resource)
select gen_random_uuid(),0, 'created', resource from patient;

----
-- create extension pg_trgm;

create index view_pt_line_idx on view_pts using gin (address gin_trgm_ops);

vacuum analyze view_pts;

----
