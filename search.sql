----

-- @> operator
select '{"a":1, "b":2}'::jsonb @> '{"b":2}'::jsonb;

select '{"a":1, "b":2}'::jsonb <@ '{"b":2}'::jsonb;

-- matches part of document
select '[{"system":"phone", "value": "123"}]'::jsonb @> '[{"system":"phone"}]'::jsonb;

-- can be nested
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
