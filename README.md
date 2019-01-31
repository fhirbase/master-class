## JSONB master class

### Intro:

Why do we need JSONb

relational-document database

document database pro and contra

Open World Assumption

Key points:

* flexible open schema (you do not need to add new columns) - variability (validation????)
* nested hierarchiecal document - Aggregate from DDD (compare with relational) - denormalization on steroid


### Trade-offs

* - access attributes - 10-30%
* - volume
* - data types (only few)

* + recursive datatypes
* + open schema 
* + nested data structure


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


### Search

#### jsquery

```sql
create extension jsquery;
```

#### json-knife

#### fhirpath



### Indexing

#### Functional idx

``` sql
create index if not exists valueset_resource_url   on valueset ((resource#>>'{url}')) ;
```

#### JSONB idx

```
create index if not exists concept_resource__gin_tgrm  on concept using gin ((resource::text) gin_trgm_ops) ;
```

#### jsquery idx


### Modify JSONB

``` sql

update codesystem set resource = resource || jsonb_build_object('deprecated', true) where resource->>'module' = 'fhir-3.3.0';

```

* Constraints

### Advanced Queries


* JSONB aggregate
* JSON as compositional


### Programm with data

You do not need ORM!



### Links

####  Practical hints

* http://erthalion.info/2017/12/21/advanced-json-benchmarks/
* https://blog.2ndquadrant.com/inserting-jsonb-data-in-postgresql-9-6/
* http://johnatten.com/2015/04/22/use-postgres-json-type-and-aggregate-functions-to-map-relational-data-to-json/

#### Theory

* https://martinfowler.com/books/nosql.html
* https://martinfowler.com/bliki/DDD_Aggregate.html
* https://en.wikipedia.org/wiki/Object-relational_impedance_mismatch

