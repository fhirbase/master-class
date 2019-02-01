for ((i=0; i<=10; i++)) do
    echo "$i";

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
