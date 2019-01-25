## JSONB master class

### Intro:

Why do we need JSONb

relational-document database

document database pro and contra

Open World Assumption

Key points:

* flexible open schema (you do not need to add new columns) - variability (validation????)
* nested hierarchiecal document - Aggregate from DDD (compare with relational) - denormalization on steroid


Trade-offs

* volume
* ....


### Install fhirbase

Using Docker - (Fhirbase getting started)[https://fhirbase.aidbox.app/getting-started-docker-version]

``` sh
$ docker pull fhirbase/fhirbase:latest
$ docker run --rm -p 3000:3000 fhirbase/fhirbase:latest
```

### CRUD

```sql

drop table jsonbtable;

-- Create table
create table IF NOT EXISTS jsonbtable (
  id serial,
  resource jsonb
);

\d+ jsonbtable

-- Create row 
insert into jsonbtable (resource)
values ('{"attribute": "value", "nested" : {"attribute": "nested value"}}');

-- Read
select resource from jsonbtable;

----
-- Different ways for read
select
'resource->''attribute''' as access,
resource->'attribute' as  "value",
pg_typeof(resource->'attribute') as  "result_type"
from jsonbtable;

select
'resource->>''attribute''' as access,
resource->>'attribute' as  "value",
pg_typeof(resource->>'attribute') as  "result_type"
from jsonbtable;


select
'resource#>''{nested, attribute}''' as nested_access,
resource#>'{nested,attribute}' as  "value",
pg_typeof(resource#>'{nested,attribute}') as  "result_type"
from jsonbtable;

select
'resource#>>''{nested, attribute}''' as nested_access,
resource#>>'{nested,attribute}' as  "value",
pg_typeof(resource#>>'{nested,attribute}') as  "result_type"
from jsonbtable;

```


### Search

#### jsquery

#### json-knife

#### fhirpath



### Indexing

#### Functional idx

#### JSONB idx

#### jsquery idx


### Modify JSONB

* Constraints

### Advanced Queries


* JSONB aggregate
* JSON as compositional


### Programm with data

You do not need ORM!



### Links

* https://martinfowler.com/books/nosql.html
* https://martinfowler.com/bliki/DDD_Aggregate.html
* https://en.wikipedia.org/wiki/Object-relational_impedance_mismatch
* http://johnatten.com/2015/04/22/use-postgres-json-type-and-aggregate-functions-to-map-relational-data-to-json/
* https://blog.2ndquadrant.com/inserting-jsonb-data-in-postgresql-9-6/

