# JSONB master class
---

## Requirements 

1) [Docker](https://docs.docker.com/install) and [Docker-Compose](https://docs.docker.com/compose/install)

2) Pull PostgreSQL 11 image for master class with JsQuery extensions

``` bash
docker pull aidbox/db:11.1.0-3-g7a1dab6
```

3) Install `psql` or any sql terminal\editor

- ```sudo apt-get install -y postgresql-client``` - depend on your OS
- [pgAdmin](https://www.pgadmin.org)
- [DBeaver](https://dbeaver.io)


## Agenda

* What's JSONB?
* Why JSONB?
  * ORM Impedance
  * DDD Aggregates & Document databases
  * Nested Data Structures
  * Recursive Data Structures 
  * Denormalization on steroids 
* What are tread-offs?
  * how fast access to jsonb fields
  * how big is jsonb in database
* How to store? Schema?
* How to update? * How to search in jsonb?
* How to index jsonb?


## Intro

* Why do we need JSONb
* Relational-document database
* Document database pro and contra
* Open World Assumption

Key points:

* Flexible open schema (you do not need to add new columns) - variability (validation????)
* Nested hierarchiecal document - Aggregate from DDD (compare with relational) - denormalization on steroid

## Getting Started

* Install PostgreSQL11
* Load initial dataset
* JSONB basic operators
* Get data from Github
* Work with jsonb data

See: [./getting-started.md](https://github.com/fhirbase/master-class/blob/master/getting-started.md)


## Trade-offs

Disadvantages

* Access attributes - 10-30%
* Volume
* Lake of data types (only few)

Advantages

* Recursive datatypes
* Open schema 
* Nested data structure


### Attribute access speed

* 20-30% slower then column
* About twice faster then jsonb
* (unexpected) faster then composite types

See: [./tradeoffs/access.sql](https://github.com/fhirbase/master-class/blob/master/tradeoffs/access.sql)

### Volume

Patient from https://www.hl7.org/fhir/patient-example.json

Size is 3.6 K (fit page)
keys ~ 30 % in bytes

The smaller json and more numbers - the worse

See: [./tradeoffs/volume.sql](https://github.com/fhirbase/master-class/blob/master/tradeoffs/volume.sql)



### JSONB CRUD

 * `jsonb_extract_path` and  `jsonb_extract_path_text`
 * Constructors `jsonb_build_object` `jsonb_build_array`
 * `jsonb_strip_nulls`
 * `row_to_json`
 * `||` and `-`
 *  `jsonb_set` / `jsonb_insert`

See: [./crud.md](https://github.com/fhirbase/master-class/blob/master/crud.md)


### Search

#### json-knife

#### fhirpath



### Indexing

#### Functional idx

``` sql
create index if not exists valueset_resource_url   on valueset ((resource#>>'{url}')) ;
```

#### JSONB idx

```
create index if not exists concept_resource__gin_tgrm  
on concept using gin ((resource::text) gin_trgm_ops) ;
```

#### jsquery idx


### Modify JSONB

``` sql
update codesystem set resource = resource || jsonb_build_object('deprecated', true) 
where resource->>'module' = 'fhir-3.3.0';
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

