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
