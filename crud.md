## Crud operations

### Read 

- `jsonb_extract_path` and  `jsonb_extract_path_text`

### Create

- Create as string or explicitly cast string to json/jsonb
- `json_build_object` and `json_build_array`
- Compose
- `row_to_json` 

### Update

- `json_strip_nulls`
- `||` and `-`
- `jsonb_set` / `jsonb_insert`


### Exammples

 * Create `FHIR` patien from `usnpi`
 * Fix code for condition of patient
