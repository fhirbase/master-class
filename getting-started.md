## Getting started

### Prepare environment

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

Load initial dataset

```bash
curl https://storage.googleapis.com/aidbox-public/masterclass_dataset.sql.tar.gz | gunzip | psql
```

### First steps

* JsonB type
* Access operators
  * ->
  * ->>
  * #>
  * ->>

## Work with JSONB

Load commits of PostgreSQL from github

Create table

```sql
-- Create table for Github Commits
create table commits (id text primary key, doc jsonb);
```

Load commits from GitHub `github.sh`

```sh
$ ./github.sh
```

`github.sh` file source code

```sh

for ((i=0; i<=10; i++)) do

    echo "https://api.github.com/repos/postgres/postgres/commits?page=$i"

    echo "
    \set record \`curl  \"https://api.github.com/repos/postgres/postgres/commits?page=$i\"\`

     with _commits as (
        select d->>'sha' as id, d - 'sha' as doc
        from jsonb_array_elements( ( :'record')::jsonb ) d
     )

     insert into commits  (id, doc)
     select *
     from _commits
    " | psql
done

```

### Samples

 - Get user with the most commits
 - Get user with the most commits in one day
 - Analyze keys ussage

---

See: [./getting-started.sql](https://github.com/fhirbase/master-class/blob/master/getting-started.sql)
