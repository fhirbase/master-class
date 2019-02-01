# JSONB master class

## Requirements 

Pull postgres image

``` bash
docker pull aidbox/db:11.1.0
```

Install psql or any sql terminal\editor

- ```sudo apt-get install -y postgresql-client``` depend on your OS
- https://www.pgadmin.org/
- https://dbeaver.io/


## Agenda

* What's JSONB?
* Why JSONB?
  * ORM Impedance
  * DDD Aggregates & Document databases
  * Nested Data Structures
  * Recursive Data Structures 
* What are tread-offs?
  * how fast access to jsonb fields
  * how big is jsonb in database
* How to store? Schema?
* How to update?
* How to search in jsonb?
* How to index jsonb?


## Intro

Why do we need JSONb

relational-document database

document database pro and contra

Open World Assumption

Key points:

* flexible open schema (you do not need to add new columns) - variability (validation????)
* nested hierarchiecal document - Aggregate from DDD (compare with relational) - denormalization on steroid


## Getting started

Run container with PostgreSQL 11

```bash
docker-compose up -d
```

Default connection details

```bash
cat .env
```

Connect to PostgreSQL

```bash
source .env
psql
```

## Trade-offs

* - access attributes - 10-30%
* - volume
* - lake of data types (only few)

* + recursive datatypes
* + open schema 
* + nested data structure


### Attribute access speed

* 20-30% slower then column
* about twice faster then jsonb
* (unexpected) faster then composite types

See: ./access-performance.sql

### Volume

pt from https://www.hl7.org/fhir/patient-example.json

size is 3.6 K (fit page)
keys ~ 30 % in bytes

the smaller json and more numbers - the worse

See: ./volume.sql


### Install fhirbase

Using Docker - (Fhirbase getting started)[https://fhirbase.aidbox.app/getting-started-docker-version]

``` sh
$ docker pull fhirbase/fhirbase:latest
$ docker run --rm -p 3000:3000 fhirbase/fhirbase:latest
```

### Load data

curl https://storage.googleapis.com/aidbox-public/fhirbase.sql.tag.zg | gunzip | psql

### CRUD

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

