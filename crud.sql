---- db: -h localhost -p 7890 -U postgres postgres

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
-- Cast from string
select '{"gender": "male", "birthDate": "1990.11.07" }'::jsonb;


---- JSONB constructors
----

-- json_build_object
select jsonb_pretty(
jsonb_build_object(
  'gender', 'female',
  'birthDate', '1982.10.12'
));

----
-- json_build_array

select jsonb_pretty(
  jsonb_build_array('one', 'two', 3, false, null)
);

---- Compose

select jsonb_pretty(
  jsonb_build_object(
    'gender', 'male',
    'birthDate', '1982.10.12',
    'address', '[{"city": "SPB"}]'::jsonb,
    'name', jsonb_build_array(jsonb_build_object('family', 'Petrov'))
));

----
\a
-- jsonb_strip_nulls
select jsonb_pretty(
jsonb_strip_nulls(
  jsonb_build_object(
    'gender', null,
    'birthDate', '1982.10.12',
    'address', '[{"city": null}]'::jsonb
  )));
----

-- row_to_jsonb
-- ~ 330 columns in usnpi table
\a
\d+ usnpi
----
\a
\timing
select jsonb_pretty(
  jsonb_strip_nulls(
    row_to_json(u.*)::jsonb
  )
)

from usnpi u
order by random()
limit 1;
----

-- Update
-- || - set insert

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
select '{"a": "b"}'::jsonb || '"c"'::jsonb;
----
-- single
select '{"a": "b", "nested": {"attr": "val"}}'::jsonb - 'a';
-- multiple
select '{"a": "b", "nested": {"attr": "val", "b": "c"}}'::jsonb - '{nested, a}'::text[];
-- by path
select '{"a": "b", "nested": {"attr": "val", "b": "c"}}'::jsonb #- '{nested,attr}'::text[];




----

set insert






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

----

--truncate usnpi;
--\copy usnpi FROM '/tmp/npi.csv' with null '' CSV HEADER;
--select healthcare_provider_taxonomy_group_15 from usnpi
--where healthcare_provider_taxonomy_group_15 is null limit 10;
--select healthcare_provider_taxonomy_group_15 from usnpi limit 10;
----
