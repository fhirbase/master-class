---- db: -h localhost -p 7890 -U postgres postgres


-- Create from flat table-
--  usnpi
-- Задание
-- -> npi to fhri practitioner

-- Create

insert into patient (id, txid, status,  resource)
values ('test-pt', 1 ,'created',
'{"gender": "male",
  "birthDate": "1990.11.07"}');

----

insert into patient (id, txid, status,  resource)
values ('test-pt-cast', 1 ,'created',
$JSONB$
  {
    "gender": "male",
    "birthDate": "1982.10.12"
  }
$JSONB$::jsonb);

----
insert into patient (id, txid, status,  resource)
values ('test-pt-build', 1 ,'created',
 json_build_object('gender', 'female', 'birthDate', '1982.10.12'));

----
insert into patient (id, txid, status,  resource)
values ('test-pt-nested', 1 ,'created',
json_build_object(
'gender', 'male',
'birthDate', '1982.10.12',
'name', json_build_array(json_build_object('family', 'Petrov'))));

----

-- Read

\x
select id, jsonb_pretty(resource)
from patient
where id ilike 'test-pt-%'
----

-- Different ways for read

select
'resource->''gender''' as access,
resource->'gender' as  "value",
pg_typeof(resource->'gender') as  "result_type"
from patient where id ilike 'test-pt-%' limit 1 ;

select
'resource->>''gender''' as access,
resource->>'gender' as  "value",
pg_typeof(resource->>'gender') as  "result_type"
from patient where id ilike 'test-pt-%' limit 1 ;


select
'resource#>''{name}''' as nested_access,
resource#>'{name}' as  "value",
pg_typeof(resource#>'{name}') as  "result_type"
from patient where id = 'test-pt-nested' limit 1 ;


select
'resource#>''{name, 0, family}''' as nested_access,
resource#>'{name, 0, family}' as  "value",
pg_typeof(resource#>'{name, 0, family}') as  "result_type"
from patient where id = 'test-pt-nested' limit 1 ;

select
'resource#>>''{name, 0, family}''' as nested_access,
resource#>>'{name, 0, family}' as  "value",
pg_typeof(resource#>>'{name, 0, family}') as  "result_type"
from patient where id = 'test-pt-nested' limit 1 ;
----

-- Update operation

select jsonb_pretty(resource)
from condition
where id = '00558851-32c7-4457-833a-13fa0e484683';

----
update condition
set resource = resource || '{"clinicalStatus": "inactive"}'
where id = '00558851-32c7-4457-833a-13fa0e484683';
----
update condition
set resource = resource - 'assertedDate'
where id = '00558851-32c7-4457-833a-13fa0e484683';
----

update condition
set resource = resource || jsonb_build_object('id_copy', id)
where id = '00558851-32c7-4457-833a-13fa0e484683'
returning jsonb_pretty(resource);

----

update condition
set resource =  jsonb_set(resource, '{status}', '"created"')
where id = '00558851-32c7-4457-833a-13fa0e484683'
returning jsonb_pretty(resource);

----

select ('{"attribute": "value"}'::jsonb || '{"missingattribute":  null }');
select jsonb_strip_nulls('{"attribute": "value"}'::jsonb || '{"missingattribute":  null }');

----
update condition
set resource =
jsonb_strip_nulls(resource || '{"missingattribute":  null }')
where id = '00558851-32c7-4457-833a-13fa0e484683'
returning jsonb_pretty(resource);

----
-- Examples
-- add condition code

update condition
set resource = jsonb_set(resource, '{code,coding}', (resource#>'{code, coding}' ||  '{"code": "J32.9", "system": "https://icd10", "display": "Sinusitis (chronic) NOS"}'))

where resource#>'{code,coding}' @> '[{"code": "40055000", "system": "http://snomed.info/sct"}]'
and  not (resource#>'{code,coding}'  @> '[{"code": "J32.9", "system": "https://icd10"}]')

----

select jsonb_pretty(resource#>'{code, coding}')
from condition
where resource#>'{code,coding}' @> '[{"code": "40055000", "system": "http://snomed.info/sct"}]'
limit 10;

----
update (select jsonb_array_elements('[
{"code": "40055000",
"system": "http://snomed.info/sct",
"display": "Chronic sinusitis (disorder)"
}, {
"code": "J32.9",
"system": "https://icd10",
"display": "Sinusitis (chronic) NOS"}]'::jsonb) as r)
set r = r || '{"code": "foo"}':jsonb

----

update condition
set resource = jsonb_set(resource, '{code,coding}',

(resource#>'{code, coding}' ||  '{"code": "J32.9", "system": "https://icd10", "display": "Sinusitis (chronic) NOS"}')

)

where (resource#>'{code,coding}'  @> '[{"code": "J32.9", "system": "https://icd10"}]')

----

select '["a", "b"]'::jsonb || '["c", "d"]'::jsonb;

----

select '{"a": "b"}'::jsonb || '{"c": "d"}'::jsonb;

----

select '{"a": "b"}'::jsonb || '["c", "d"]'::jsonb;

----

select '["a", "b"]'::jsonb || '{"c": "d"}'::jsonb;

----

select '["a", "b"]'::jsonb || '"c"'::jsonb;

----
select to_jsonb(current_timestamp)
----

---select '{"a": "b"}'::jsonb || '"c"'::jsonb;


----
